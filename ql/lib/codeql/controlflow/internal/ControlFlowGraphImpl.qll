private import codeql.Ast
private import codeql.Solidity
private import codeql.controlflow.Cfg as CfgShared
private import codeql.controlflow.SuccessorType
private import codeql.Locations

module Completion {
  private newtype TCompletion =
    TSimpleCompletion() or
    TBooleanCompletion(boolean b) { b in [false, true] } or
    TReturnCompletion() or
    TBreakCompletion() or
    TContinueCompletion() or
    TRevertCompletion() // revert, assert, require - even though assert technically causes a panic

  abstract class Completion extends TCompletion {
    abstract string toString();

    predicate isValidForSpecific(AstNode e) { none() }

    predicate isValidFor(AstNode e) { this.isValidForSpecific(e) }

    abstract SuccessorType getAMatchingSuccessorType();
  }

  abstract class NormalCompletion extends Completion { }

  class SimpleCompletion extends NormalCompletion, TSimpleCompletion {
    override string toString() { result = "SimpleCompletion" }

    override predicate isValidFor(AstNode e) { not any(Completion c).isValidForSpecific(e) }

    override NormalSuccessor getAMatchingSuccessorType() { any() }
  }

  class BooleanCompletion extends NormalCompletion, TBooleanCompletion {
    boolean value;

    BooleanCompletion() { this = TBooleanCompletion(value) }

    override string toString() { result = "BooleanCompletion(" + value + ")" }

    override predicate isValidForSpecific(AstNode e) {
      e = any(IfStatement c).getCondition() or
      e = any(ForStatement c).getCondition() or
      e = any(WhileStatement c).getCondition() or
      e = any(DoWhileStatement c).getCondition() or
      e = any(TernaryExpression c).getCondition()
    }

    override BooleanSuccessor getAMatchingSuccessorType() { result.getValue() = value }

    final boolean getValue() { result = value }
  }

  class ReturnCompletion extends Completion, TReturnCompletion {
    override string toString() { result = "ReturnCompletion" }

    override predicate isValidForSpecific(AstNode e) { e instanceof ReturnStatement }

    override ReturnSuccessor getAMatchingSuccessorType() { any() }
  }

  class BreakCompletion extends Completion, TBreakCompletion {
    override string toString() { result = "BreakCompletion" }

    override predicate isValidForSpecific(AstNode e) { e instanceof BreakStatement }

    override BreakSuccessor getAMatchingSuccessorType() { any() }
  }

  class ContinueCompletion extends Completion, TContinueCompletion {
    override string toString() { result = "ContinueCompletion" }

    override predicate isValidForSpecific(AstNode e) { e instanceof ContinueStatement }

    override ContinueSuccessor getAMatchingSuccessorType() { any() }
  }

  class RevertCompletion extends Completion, TRevertCompletion {
    override string toString() { result = "RevertCompletion" }

    override predicate isValidForSpecific(AstNode e) { 
      e instanceof RevertStatement
      // TODO: Require and assert are not separate statements in TreeSitter, needs to be abstracted in the AST
    }

    override ExceptionSuccessor getAMatchingSuccessorType() { any() }
  }
}

module CfgScope {
  abstract class CfgScope extends AstNode { }

  private class FunctionScope extends CfgScope, FunctionDefinition { }
  private class ModifierScope extends CfgScope, ModifierDefinition { }
  private class ConstructorScope extends CfgScope, ConstructorDefinition { }
  private class FallbackReceiveDefinitionScope extends CfgScope, FallbackReceiveDefinition { }
  private class ContractScope extends CfgScope, ContractDeclaration { }
}

private module Implementation implements CfgShared::InputSig<Location> {
  private import codeql.solidity.ast.internal.Ast
  private import codeql.solidity.ast.internal.TreeSitter
  import codeql.Ast
  import Completion
  import CfgScope

  private predicate id(Solidity::AstNode node1, Solidity::AstNode node2) { node1 = node2 }

  private predicate idOf(Solidity::AstNode node, int id) = equivalenceRelation(id/2)(node, id)

  int idOfAstNode(AstNode node) { idOf(toTreeSitter(node), result) }

  int idOfCfgScope(CfgScope node) { result = idOfAstNode(node) }

  predicate completionIsNormal(Completion c) { 
    not c instanceof ReturnCompletion and
    not c instanceof RevertCompletion
  }

  // Not using CFG splitting, so the following are just dummy types.
  private newtype TUnit = Unit()

  additional class SplitKindBase = TUnit;

  additional class Split extends TUnit {
    abstract string toString();
  }

  predicate completionIsSimple(Completion c) { c instanceof SimpleCompletion }

  predicate completionIsValidFor(Completion c, AstNode e) { c.isValidFor(e) }

  CfgScope getCfgScope(AstNode e) {
    exists(AstNode p | p = e.getParent() |
      result = p
      or
      not p instanceof CfgScope and result = getCfgScope(p)
    )
  }

  additional int maxSplits() { result = 0 }

  predicate scopeFirst(CfgScope scope, AstNode e) {
    first(scope.(FunctionDefinition).getBody(), e) or
    first(scope.(ModifierDefinition).getBody(), e) or
    first(scope.(ConstructorDefinition).getBody(), e) or
    first(scope.(FallbackReceiveDefinition).getBody(), e) or
    first(scope.(ContractDeclaration).getBody(), e)
  }

  predicate scopeLast(CfgScope scope, AstNode e, Completion c) {
    last(scope.(FunctionDefinition).getBody(), e, c) or
    last(scope.(ModifierDefinition).getBody(), e, c) or
    last(scope.(ConstructorDefinition).getBody(), e, c) or
    last(scope.(FallbackReceiveDefinition).getBody(), e, c) or
    last(scope.(ContractDeclaration).getBody(), e, c)
  }

  additional predicate successorTypeIsSimple(SuccessorType t) { t instanceof DirectSuccessor }

  predicate successorTypeIsCondition(SuccessorType t) { t instanceof BooleanSuccessor }

  SuccessorType getAMatchingSuccessorType(Completion c) { result = c.getAMatchingSuccessorType() }

  additional predicate isAbnormalExitType(SuccessorType t) { t instanceof ExceptionSuccessor }
}

module CfgImpl = CfgShared::Make<Location, Implementation>;

private import CfgImpl
private import Completion
private import CfgScope

private class ConditionalExpressionTree extends PostOrderTree instanceof IfStatement {
  override predicate propagatesAbnormal(AstNode child) { none() }

  override predicate first(AstNode first) { first(super.getCondition(), first) }

  override predicate succ(AstNode pred, AstNode succ, Completion c) {
    last(super.getCondition(), pred, c) and
    (
      first(super.getThen(), succ) and c.(BooleanCompletion).getValue() = true
      or
      first(super.getElse(), succ) and c.(BooleanCompletion).getValue() = false
    )
    or
    last(super.getThen(), pred, c) and
    succ = this and
    c instanceof SimpleCompletion
    or
    last(super.getElse(), pred, c) and
    succ = this and
    c instanceof SimpleCompletion
  }
}

private class TernaryExpressionTree extends PostOrderTree instanceof TernaryExpression {
  override predicate propagatesAbnormal(AstNode child) { none() }

  override predicate first(AstNode first) { first(super.getCondition(), first) }

  override predicate succ(AstNode pred, AstNode succ, Completion c) {
    last(super.getCondition(), pred, c) and
    (
      first(super.getThen(), succ) and c.(BooleanCompletion).getValue() = true
      or
      first(super.getElse(), succ) and c.(BooleanCompletion).getValue() = false
    )
    or
    last(super.getThen(), pred, c) and
    succ = this and
    c instanceof SimpleCompletion
    or
    last(super.getElse(), pred, c) and
    succ = this and
    c instanceof SimpleCompletion
  }
}

private class ForExpressionTree extends PostOrderTree instanceof ForStatement {
  override predicate propagatesAbnormal(AstNode child) { none() }

  override predicate first(AstNode first) { first(super.getInitial(), first) }

  override predicate succ(AstNode pred, AstNode succ, Completion c) {
    last(super.getInitial(), pred, c) and
    first(super.getCondition(), succ) and
    c instanceof SimpleCompletion
    or
    last(super.getCondition(), pred, c) and
    (
      first(super.getBody(), succ) and c.(BooleanCompletion).getValue() = true
      or
      succ = this and c.(BooleanCompletion).getValue() = false
    )
    or
    last(super.getBody(), pred, c) and
    first(super.getUpdate(), succ) and
    c instanceof SimpleCompletion
    or
    last(super.getUpdate(), pred, c) and
    first(super.getCondition(), succ) and
    c instanceof SimpleCompletion
  }
}

private class WhileStatementTree extends PostOrderTree instanceof WhileStatement {
  override predicate propagatesAbnormal(AstNode child) { none() }

  override predicate first(AstNode first) { first(super.getCondition(), first) }

  override predicate succ(AstNode pred, AstNode succ, Completion c) {
    last(super.getCondition(), pred, c) and
    (
      first(super.getBody(), succ) and c.(BooleanCompletion).getValue() = true
      or
      succ = this and c.(BooleanCompletion).getValue() = false
    )
    or
    last(super.getBody(), pred, c) and
    first(super.getCondition(), succ) and
    c instanceof SimpleCompletion
  }
}

private class DoWhileStatementTree extends PostOrderTree instanceof DoWhileStatement {
  override predicate propagatesAbnormal(AstNode child) { none() }

  override predicate first(AstNode first) { first(super.getBody(), first) }

  override predicate succ(AstNode pred, AstNode succ, Completion c) {
    last(super.getBody(), pred, c) and
    first(super.getCondition(), succ) and
    c instanceof SimpleCompletion
    or
    last(super.getCondition(), pred, c) and
    (
      first(super.getBody(), succ) and c.(BooleanCompletion).getValue() = true
      or
      succ = this and c.(BooleanCompletion).getValue() = false
    )
  }
}

private class TryStatementTree extends PostOrderTree instanceof TryStatement {
  override predicate propagatesAbnormal(AstNode child) { none() }

  override predicate first(AstNode first) { first(super.getAttempt(), first) }

  override predicate succ(AstNode pred, AstNode succ, Completion c) {
    // If attempt succeeds, go to success body
    last(super.getAttempt(), pred, c) and
    first(super.getBody(), succ) and
    c instanceof SimpleCompletion
    or
    // If attempt throws, go to first catch clause (simplified - assume catch clauses are children)
    last(super.getAttempt(), pred, c) and
    first(super.getChild(0), succ) and
    c instanceof RevertCompletion
    or
    // Success body completes normally
    last(super.getBody(), pred, c) and
    succ = this and
    c instanceof SimpleCompletion
    or
    // Catch clause completes normally
    last(super.getChild(_), pred, c) and
    succ = this and
    c instanceof SimpleCompletion
  }
}

private class BlockStatementTree extends StandardPostOrderTree instanceof BlockStatement {
  override ControlFlowTree getChildNode(int i) { result = super.getChild(i) }
}

private class ExpressionStatementTree extends StandardPostOrderTree instanceof ExpressionStatement {
  override ControlFlowTree getChildNode(int i) { result = super.getAChild() and i = 0 }
}

private class ReturnStatementTree extends StandardPostOrderTree instanceof ReturnStatement {
  override ControlFlowTree getChildNode(int i) { result = super.getChild() and i = 0 }
}

private class RevertStatementTree extends StandardPostOrderTree instanceof RevertStatement {
  override ControlFlowTree getChildNode(int i) { result = super.getError() and i = 0 }
}

private class EmitStatementTree extends StandardPostOrderTree instanceof EmitStatement {
  override ControlFlowTree getChildNode(int i) { result = super.getChild(i) }
}

private class VariableDeclarationStatementTree extends StandardPostOrderTree instanceof VariableDeclarationStatement {
  // Only evaluate the initializer value if present; the declaration itself is not evaluated
  override ControlFlowTree getChildNode(int i) { result = super.getValue() and i = 0 }
}

private class BreakStatementTree extends LeafTree instanceof BreakStatement { }

private class ContinueStatementTree extends LeafTree instanceof ContinueStatement { }

private class FunctionDefinitionTree extends LeafTree instanceof FunctionDefinition { }

private class FunctionBodyTree extends StandardPostOrderTree instanceof FunctionBody {
  override ControlFlowTree getChildNode(int i) {
    // Unwrap the generic Statement wrapper to get the actual specific statement type
    result = super.getChild(i).getAChild()
  }
}

private class ContractBodyTree extends StandardPostOrderTree instanceof ContractBody {
  override ControlFlowTree getChildNode(int i) { result = super.getChild(i) }
}

private class BooleanLiteralTree extends LeafTree instanceof BooleanLiteral { }

// Identifier tokens used in value-producing positions (e.g. the receiver of
// `target.call(data)` or the base of `arr[0]`) — the Solidity grammar emits
// these as bare `Identifier` tokens rather than wrapping them in an
// `Expression`, but they still need to participate in control flow so SSA and
// dataflow can track their values.
private class IdentifierTree extends LeafTree instanceof Identifier {
  IdentifierTree() {
    exists(MemberExpression me | me.getObject() = this) or
    exists(ArrayAccess aa | aa.getBase() = this) or
    exists(CallArgument ca | ca.getAChild() = this) or
    exists(AssignmentExpression ae | ae.getLeft() = this)
  }
}

// The Solidity grammar wraps inline expression contents in an unnamed
// `expression` node (TSolExpression). Specific subclasses like `IdentifierExpression`
// handle some cases, but for any other content (CallExpression, MemberExpression,
// etc.) the wrapper has no specific tree class. Without this pass-through tree
// the CFG would stop at every wrapper boundary.
private class GenericExpressionWrapperTree extends StandardPostOrderTree instanceof Expression {
  GenericExpressionWrapperTree() {
    this.(Expression).getAPrimaryQlClass() = "Expression" and
    not this instanceof IdentifierExpression
  }

  override ControlFlowTree getChildNode(int i) { result = super.getAChild() and i = 0 }
}

// `IdentifierExpression` (the wrapper around a bare `Identifier`) needs to
// participate in the CFG too. Treat it as a leaf — the only meaningful
// CFG event is "evaluate this identifier reference".
private class IdentifierExpressionTree extends LeafTree instanceof IdentifierExpression { }

private class NumberTree extends LeafTree instanceof NumberLiteral { }

private class StringLiteralTree extends LeafTree instanceof StringLiteral { }

private class HexLiteralTree extends LeafTree instanceof HexStringLiteral { }

private class UnicodeLiteralTree extends LeafTree instanceof UnicodeStringLiteral { }

private class ParenExpressionTree extends StandardPostOrderTree instanceof ParenthesizedExpression {
  // The internal expression is handled by a separate expression parsing CFG class, we just need to parse the child node
  override ControlFlowTree getChildNode(int i) { result = super.getChild() and i = 0 }
}

private class UnaryOpExpressionTree extends StandardPostOrderTree instanceof UnaryExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getArgument() and i = 0 }
}

private class BinaryOpExpressionTree extends StandardPostOrderTree instanceof BinaryExpression {
  override ControlFlowTree getChildNode(int i) {
    result = super.getLeft() and i = 0
    or
    result = super.getRight() and i = 1
  }
}

private class TupleOpExpressionTree extends StandardPostOrderTree instanceof TupleExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getChild(i) }
}

private class NewExpressionTree extends StandardPostOrderTree instanceof NewExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getArgument(i) }
}

private class ArrayAccessTree extends StandardPostOrderTree instanceof ArrayAccess {
  override ControlFlowTree getChildNode(int i) {
    result = super.getBase() and i = 0
    or
    result = super.getIndex() and i = 1
  }
}

private class InlineArrayExpressionTree extends StandardPostOrderTree instanceof InlineArrayExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getChild(i) }
}

private class AssignmentExpressionTree extends StandardPostOrderTree instanceof AssignmentExpression {
  override ControlFlowTree getChildNode(int i) {
    result = super.getLeft() and i = 0
    or
    result = super.getRight() and i = 1
  }
}

private class AugmentedAssignmentExpressionTree extends StandardPostOrderTree instanceof AugmentedAssignmentExpression {
  override ControlFlowTree getChildNode(int i) {
    result = super.getLeft() and i = 0
    or
    result = super.getRight() and i = 1
  }
}

private class FunctionCallExpressionTree extends StandardPostOrderTree instanceof CallExpression
{
  override ControlFlowTree getChildNode(int i) {
    i = 0 and result = super.getFunction()
    or
    exists(int argIdx | argIdx >= 0 | i = argIdx + 1 and result = super.getArgument(argIdx))
  }
}

private class CallArgumentTree extends StandardPostOrderTree instanceof CallArgument {
  override ControlFlowTree getChildNode(int i) { result = super.getAChild() and i = 0 }
}

private class MemberExpressionTree extends StandardPostOrderTree instanceof MemberExpression {
  // The property identifier in a MemberExpression is not a node, so just need to get the object
  override ControlFlowTree getChildNode(int i) { result = super.getObject() and i = 0 }
}

private class PayableConversionExpressionTree extends StandardPostOrderTree instanceof PayableConversionExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getChild(i) }
}

private class SliceAccessTree extends StandardPostOrderTree instanceof SliceAccess {
  override ControlFlowTree getChildNode(int i) {
    result = super.getBase() and i = 0
    or
    result = super.getFrom() and i = 1
    or
    result = super.getTo() and i = 2
  }
}

private class StructExpressionTree extends StandardPostOrderTree instanceof StructExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getChild(i) }
}

private class TypeCastExpressionTree extends StandardPostOrderTree instanceof TypeCastExpression {
  // Only evaluate the value being cast (child 1), not the type (child 0) which is static
  override ControlFlowTree getChildNode(int i) { result = super.getValue() and i = 0 }
}

private class UpdateExpressionTree extends StandardPostOrderTree instanceof UpdateExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getArgument() and i = 0 }
}

// TODO: Leaving Yul nodes out for now, to implement later

// ============================================================================
// Interprocedural CFG (additive, opt-in)
// ============================================================================
//
// The shared `CfgImpl` is intra-procedural: per-tree `succ` predicates never
// cross a `CfgScope`. Extending those would corrupt the basic-block / dominator
// computations. Instead, we expose two SEPARATE additive predicates that
// detectors can OR into their successor walks when they want interprocedural
// reasoning. The intra-procedural CFG itself is unchanged, so existing
// detectors are unaffected.
//
// Edges are anchored at the resolved callee (via `NameResolution::resolveCallTarget`),
// which inherits the cross-file resolution from Phase 3.

private import codeql.NameResolution

/**
 * Holds if there is an interprocedural CFG edge from `pred` to `succ`:
 *   - `pred` is the CFG node of the last AST node evaluated in the call's
 *     argument chain (or the function expression if the call has no args).
 *   - `succ` is the CFG node at the entry of the resolved callee's body.
 */
predicate interproceduralCallEdge(Node pred, Node succ) {
  exists(CallExpression call, AstNode callee, AstNode predAst, AstNode succAst |
    callee = NameResolution::resolveCallTarget(call) and
    pred.getAstNode() = predAst and
    succ.getAstNode() = succAst and
    callPredAst(call, predAst) and
    calleeBodyFirst(callee, succAst)
  )
}

/**
 * Holds if there is an interprocedural CFG return edge from `pred` (the last
 * AST node executed in the callee body — typically a `ReturnStatement` or
 * fall-off-end) to `succ` (the CallExpression node, which dataflow already
 * treats as the result of the call).
 */
predicate interproceduralReturnEdge(Node pred, Node succ) {
  exists(CallExpression call, AstNode callee, AstNode predAst |
    callee = NameResolution::resolveCallTarget(call) and
    calleeBodyExit(callee, predAst) and
    pred.getAstNode() = predAst and
    succ.getAstNode() = call
  )
}

/**
 * Gets the AST node that the call's predecessor edge starts from: the last
 * AST node of the highest-indexed argument's CFG, or the function expression's
 * last node if the call has no arguments.
 */
private predicate callPredAst(CallExpression call, AstNode predAst) {
  exists(int n |
    n = max(int i | exists(call.getArgument(i))) and
    last(call.getArgument(n), predAst, _)
  )
  or
  not exists(call.getArgument(_)) and
  last(call.getFunction(), predAst, _)
}

/** Holds if `entry` is the first AST node executed in the body of `callee`. */
private predicate calleeBodyFirst(AstNode callee, AstNode entry) {
  first(callee.(FunctionDefinition).getBody(), entry)
  or
  first(callee.(ModifierDefinition).getBody(), entry)
  or
  first(callee.(ConstructorDefinition).getBody(), entry)
  or
  first(callee.(FallbackReceiveDefinition).getBody(), entry)
}

/**
 * Holds if `exitAst` is a possible last AST node executed in the body of
 * `callee` — covers both explicit `return` statements and falling off the end.
 */
private predicate calleeBodyExit(AstNode callee, AstNode exitAst) {
  last(callee.(FunctionDefinition).getBody(), exitAst, _)
  or
  last(callee.(ModifierDefinition).getBody(), exitAst, _)
  or
  last(callee.(ConstructorDefinition).getBody(), exitAst, _)
  or
  last(callee.(FallbackReceiveDefinition).getBody(), exitAst, _)
}

/**
 * Augmented successor relation: an OR of the intra-procedural CFG and the
 * interprocedural call/return edges. Detectors that want cross-function
 * reachability can use this in place of `Node.getASuccessor`.
 *
 * Recursion / cycles: CodeQL transitive closures handle cycles natively,
 * so direct or indirect recursion is just a fixpoint over this relation.
 * Detectors doing path-sensitive walks should bound depth themselves.
 */
predicate interproceduralSuccessor(Node pred, Node succ) {
  succ = pred.getASuccessor()
  or
  interproceduralCallEdge(pred, succ)
  or
  interproceduralReturnEdge(pred, succ)
}
