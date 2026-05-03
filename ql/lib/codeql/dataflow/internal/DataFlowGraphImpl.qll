/**
 * Implements the shared `codeql.dataflow.DataFlow` library's `InputSig`
 * for Solidity, then instantiates `DataFlowMake` to produce a usable
 * `Global<Config>` / `GlobalWithState<Config>` API.
 *
 * The public `Node` hierarchy lives in `DataFlowPublic.qll`; this file is
 * the language-specific glue (call graph, local flow, content flow, type
 * system, etc.).
 */

private import codeql.Solidity
private import codeql.Locations
private import codeql.dataflow.DataFlow
private import codeql.Cfg as Cfg
private import DataFlowPublic as DataFlowPublic
private import SsaImpl as Ssa

// ============================================================================
// File-level helpers (referenced from inside the SolidityDataFlow module)
// ============================================================================

/** Gets the closest CFG-scope-typed ancestor of an AST node. */
Cfg::CfgScope astEnclosingCallable(AstNode n) {
  result = n.getParent*() and
  not exists(Cfg::CfgScope closer |
    closer = n.getParent+() and
    result = closer.getParent+() and
    closer != result
  )
}

/**
 * Gets the textual name being called by `ce`. For `foo(x)` this is `"foo"`;
 * for `obj.foo(x)` this is also `"foo"` (the property name).
 */
private string calledFunctionName(CallExpression ce) {
  result = ce.getFunction().(IdentifierExpression).getIdentifier().getValue()
  or
  result = ce.getFunction().(MemberExpression).getProperty().getValue()
}

/** Gets the enclosing `ContractDeclaration` of an AST node, if any. */
private ContractDeclaration enclosingContract(AstNode n) {
  result = n.getParent*()
}

/** Gets a directly-inherited parent contract of `cd`, by name match. */
private ContractDeclaration directParentContract(ContractDeclaration cd) {
  exists(InheritanceSpecifier is, Identifier ancestorName |
    is.getParent*() = cd and
    ancestorName = is.getAncestor() and
    result.getName().(Identifier).getValue() = ancestorName.getValue() and
    result != cd
  )
}

/** Gets a (transitive) ancestor contract of `cd`, including `cd` itself. */
private ContractDeclaration ancestorOrSelf(ContractDeclaration cd) {
  result = cd
  or
  result = directParentContract(ancestorOrSelf(cd))
}

/** Gets the receiver expression of a member access, when it is itself an Expression. */
private Expression memberObjectExpr(MemberExpression me) {
  result = me.getObject()
}

/** Holds if a `StateVariableDeclaration` named `name` exists in the database. */
private predicate stateVariableExists(string name) {
  exists(StateVariableDeclaration sv | sv.getName().(Identifier).getValue() = name)
}

/** Gets an `IdentifierExpression` that references a state variable named `name`. */
private IdentifierExpression stateVarReadExpr(string name) {
  result.getIdentifier().getValue() = name and
  stateVariableExists(name)
}

/** Gets the `pos`-th `Parameter` of a function-like callable, in source order. */
private Parameter parameterAt(Cfg::CfgScope c, int pos) {
  result =
    rank[pos + 1](Parameter p, int line, int col |
      p.getParent() = c and
      line = p.getLocation().getStartLine() and
      col = p.getLocation().getStartColumn()
    |
      p order by line, col
    )
}

// ============================================================================
// SolidityDataFlow — the InputSig instantiation
// ============================================================================

module SolidityDataFlow implements InputSig<Location> {
  // ---- Re-export public Node hierarchy ------------------------------------

  class Node = DataFlowPublic::Node;

  class ParameterNode = DataFlowPublic::ParameterNode;

  class ArgumentNode = DataFlowPublic::ArgumentNode;

  class OutNode = DataFlowPublic::OutNode;

  class PostUpdateNode = DataFlowPublic::PostUpdateNode;

  class CastNode = DataFlowPublic::CastNode;

  /**
   * The InputSig requires `ReturnNode` to expose `getKind()`. Wrap the public
   * class to add the (singleton) return-kind accessor.
   */
  class ReturnNode extends DataFlowPublic::ReturnNode {
    ReturnKind getKind() { exists(this) and result = TNormalReturn() }
  }

  // ---- Wrapper types ------------------------------------------------------

  /**
   * A callable: a `FunctionDefinition`, `ModifierDefinition`,
   * `ConstructorDefinition`, `FallbackReceiveDefinition`, or `ContractDeclaration`.
   */
  class DataFlowCallable extends Cfg::CfgScope {
    DataFlowCallable() { any() }
  }

  /** A call: a `CallExpression`. */
  class DataFlowCall extends CallExpression {
    DataFlowCallable getEnclosingCallable() { result = astEnclosingCallable(this) }
  }

  /** A positional parameter index. */
  class ParameterPosition extends int {
    ParameterPosition() { this in [0 .. 99] }

    bindingset[this]
    string toString() { result = this.(int).toString() }
  }

  /** A positional argument index. */
  class ArgumentPosition extends int {
    ArgumentPosition() { this in [0 .. 99] }

    bindingset[this]
    string toString() { result = this.(int).toString() }
  }

  private newtype TReturnKind = TNormalReturn()

  class ReturnKind extends TReturnKind {
    string toString() { result = "return" }
  }

  private newtype TDataFlowType = TSingletonDataFlowType()

  class DataFlowType extends TDataFlowType {
    string toString() { result = "T" }
  }

  // ---- Content / ContentSet / ContentApprox ------------------------------

  private newtype TContent =
    TFieldContent(string name) { name = any(MemberExpression me).getProperty().getValue() } or
    TArrayElement() or
    TMapValue()

  class Content extends TContent {
    string toString() {
      exists(string n | this = TFieldContent(n) | result = "field " + n)
      or
      this = TArrayElement() and result = "[]"
      or
      this = TMapValue() and result = "[mapping]"
    }
  }

  additional class FieldContent extends Content, TFieldContent {
    private string name;

    FieldContent() { this = TFieldContent(name) }

    string getName() { result = name }
  }

  additional class ArrayElement extends Content, TArrayElement { }

  additional class MapValue extends Content, TMapValue { }

  class ContentSet instanceof Content {
    string toString() { result = super.toString() }

    Content getAStoreContent() { result = this }

    Content getAReadContent() { result = this }
  }

  private newtype TContentApprox = TSingletonContentApprox()

  class ContentApprox extends TContentApprox {
    string toString() { result = "approx" }
  }

  // ---- Empty wrapper types (Solidity has no analogue) --------------------

  private newtype TLambdaCallKind = TNoLambda() { none() }

  class LambdaCallKind extends TLambdaCallKind {
    string toString() { none() }
  }

  private newtype TDataFlowSecondLevelScope = TNoSecondLevelScope() { none() }

  class DataFlowSecondLevelScope extends TDataFlowSecondLevelScope {
    string toString() { none() }
  }

  private newtype TNodeRegion = TNoNodeRegion() { none() }

  class NodeRegion extends TNodeRegion {
    string toString() { none() }

    predicate contains(Node n) { none() }
  }

  // ---- DataFlowExpr / exprNode bridge ------------------------------------

  class DataFlowExpr = Expression;

  Node exprNode(DataFlowExpr e) { result = DataFlowPublic::exprNode(e) }

  // ---- Type system (singleton) -------------------------------------------

  DataFlowType getNodeType(Node node) {
    exists(node) and result = TSingletonDataFlowType()
  }

  predicate compatibleTypes(DataFlowType t1, DataFlowType t2) { any() }

  predicate typeStrongerThan(DataFlowType t1, DataFlowType t2) { none() }

  // ---- Visibility --------------------------------------------------------

  predicate nodeIsHidden(Node node) { none() }

  predicate neverSkipInPathGraph(Node n) { none() }

  // ---- Content approximation ---------------------------------------------

  ContentApprox getContentApprox(Content c) {
    exists(c) and result = TSingletonContentApprox()
  }

  predicate forceHighPrecision(Content c) { none() }

  // ---- Parameter / argument matching ------------------------------------

  predicate parameterMatch(ParameterPosition p, ArgumentPosition a) { p = a }

  predicate isParameterNode(ParameterNode n, DataFlowCallable c, ParameterPosition pos) {
    n = DataFlowPublic::parameterNode(parameterAt(c, pos))
  }

  predicate isArgumentNode(ArgumentNode n, DataFlowCall call, ArgumentPosition pos) {
    exists(CallArgument ca |
      call.getArgument(pos) = ca and ca.getAChild() = n.getExpr()
    )
  }

  // ---- Call graph --------------------------------------------------------

  DataFlowCallable nodeGetEnclosingCallable(Node node) {
    exists(AstNode n |
      n = node.asExpr() or
      n = node.asParameter() or
      n = node.asPostUpdateExpr()
    |
      result = astEnclosingCallable(n)
    )
  }

  DataFlowCallable viableCallable(DataFlowCall c) {
    exists(string name, ContractDeclaration callerContract, ContractDeclaration calleeContract |
      name = calledFunctionName(c) and
      callerContract = enclosingContract(c) and
      calleeContract = ancestorOrSelf(callerContract) and
      result.(FunctionDefinition).getName().getValue() = name and
      enclosingContract(result) = calleeContract
    )
  }

  predicate mayBenefitFromCallContext(DataFlowCall call) { none() }

  DataFlowCallable viableImplInCallContext(DataFlowCall call, DataFlowCall ctx) { none() }

  OutNode getAnOutNode(DataFlowCall call, ReturnKind kind) {
    exists(kind) and result = DataFlowPublic::exprNode(call)
  }

  // ---- Local flow --------------------------------------------------------

  predicate simpleLocalFlowStep(Node node1, Node node2, string model) {
    model = "" and
    (
      // SSA def→use: from value being assigned to each read.
      exists(Ssa::WriteDefinition def, Identifier readId, IdentifierExpression readExpr |
        readId = Ssa::getARead(def) and
        readId = readExpr.getIdentifier() and
        node2 = DataFlowPublic::exprNode(readExpr)
      |
        // Parameter init: the parameter node flows to identifier reads of it.
        exists(Parameter p |
          Ssa::parameterInit(def, p) and node1 = DataFlowPublic::parameterNode(p)
        )
        or
        // Explicit assignment: the RHS expression flows to reads.
        node1 = DataFlowPublic::exprNode(Ssa::getWriteValue(def))
      )
      or
      // Pass-through expressions.
      exists(ParenthesizedExpression pe |
        node1 = DataFlowPublic::exprNode(pe.getChild()) and
        node2 = DataFlowPublic::exprNode(pe)
      )
      or
      exists(TernaryExpression te |
        (
          node1 = DataFlowPublic::exprNode(te.getThen()) or
          node1 = DataFlowPublic::exprNode(te.getElse())
        ) and
        node2 = DataFlowPublic::exprNode(te)
      )
      or
      exists(TypeCastExpression ce, CallArgument value, Expression inner |
        ce.getValue() = value and
        value.getAChild() = inner and
        node1 = DataFlowPublic::exprNode(inner) and
        node2 = DataFlowPublic::exprNode(ce)
      )
      or
      // Assignment expression: RHS flows to the assignment expression itself
      // (the assignment evaluates to the assigned value).
      exists(AssignmentExpression ae |
        node1 = DataFlowPublic::exprNode(ae.getRight()) and
        node2 = DataFlowPublic::exprNode(ae)
      )
    )
  }

  predicate localMustFlowStep(Node node1, Node node2) { none() }

  // ---- Jump steps (state-variable cross-function flow) ------------------

  predicate jumpStep(Node node1, Node node2) {
    exists(StateVariableDeclaration sv, string name, Expression init |
      name = sv.getName().(Identifier).getValue() and
      init = sv.getValue() and
      node1 = DataFlowPublic::exprNode(init) and
      node2 = DataFlowPublic::exprNode(stateVarReadExpr(name))
    )
    or
    exists(AssignmentExpression ae, IdentifierExpression lhs, string name |
      ae.getLeft() = lhs and
      name = lhs.getIdentifier().getValue() and
      stateVariableExists(name) and
      not exists(Ssa::sourceVariableForIdentifier(lhs.getIdentifier())) and
      node1 = DataFlowPublic::exprNode(ae.getRight()) and
      node2 = DataFlowPublic::exprNode(stateVarReadExpr(name))
    )
  }

  // ---- Content (field / array / mapping) flow ----------------------------

  predicate readStep(Node node1, ContentSet c, Node node2) {
    // obj.field read.
    exists(MemberExpression me |
      node1 = DataFlowPublic::exprNode(memberObjectExpr(me)) and
      node2 = DataFlowPublic::exprNode(me) and
      c = any(FieldContent fc | fc.getName() = me.getProperty().getValue())
    )
    or
    // arr[i] / mapping[k] read.
    exists(ArrayAccess aa |
      node1 = DataFlowPublic::exprNode(aa.getBase()) and
      node2 = DataFlowPublic::exprNode(aa) and
      c instanceof ArrayElement
    )
  }

  predicate storeStep(Node node1, ContentSet c, Node node2) {
    // obj.field = value
    exists(AssignmentExpression ae, MemberExpression me, Expression obj |
      ae.getLeft() = me and
      obj = memberObjectExpr(me) and
      node1 = DataFlowPublic::exprNode(ae.getRight()) and
      node2 = DataFlowPublic::MkPostUpdateNode(obj) and
      c = any(FieldContent fc | fc.getName() = me.getProperty().getValue())
    )
    or
    // arr[i] = value
    exists(AssignmentExpression ae, ArrayAccess aa |
      ae.getLeft() = aa and
      node1 = DataFlowPublic::exprNode(ae.getRight()) and
      node2 = DataFlowPublic::MkPostUpdateNode(aa.getBase()) and
      c instanceof ArrayElement
    )
  }

  predicate clearsContent(Node n, ContentSet c) {
    exists(AssignmentExpression ae, MemberExpression me |
      ae.getLeft() = me and
      n = DataFlowPublic::MkPostUpdateNode(memberObjectExpr(me)) and
      c = any(FieldContent fc | fc.getName() = me.getProperty().getValue())
    )
  }

  predicate expectsContent(Node n, ContentSet c) { none() }

  // ---- Reachability pruning (disabled) -----------------------------------

  predicate isUnreachableInCall(NodeRegion nr, DataFlowCall call) { none() }

  // ---- Lambdas (Solidity has no first-class functions) -------------------

  predicate lambdaCreation(Node creation, LambdaCallKind kind, DataFlowCallable c) { none() }

  predicate lambdaCall(DataFlowCall call, LambdaCallKind kind, Node receiver) { none() }

  predicate additionalLambdaFlowStep(Node nodeFrom, Node nodeTo, boolean preservesValue) { none() }

  // ---- Source/sink models (no externally-modeled flow library yet) -------

  predicate knownSourceModel(Node source, string model) { none() }

  predicate knownSinkModel(Node sink, string model) { none() }

  // ---- Misc --------------------------------------------------------------

  predicate allowParameterReturnInSelf(ParameterNode p) { none() }
}

// ============================================================================
// DataFlowMake instantiation
// ============================================================================

module DataFlow = DataFlowMake<Location, SolidityDataFlow>;
