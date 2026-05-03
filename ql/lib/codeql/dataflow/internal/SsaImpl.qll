/**
 * Provides an instantiation of the shared SSA library for Solidity.
 *
 * Source variables are local variables (declared via `VariableDeclarationStatement`)
 * and parameters of functions, modifiers, constructors, and the fallback/receive
 * definition. State variables are *not* SSA-tracked here — their cross-function
 * flow is handled by `jumpStep` in `DataFlowImpl.qll`.
 */

private import codeql.ssa.Ssa as SsaImpl
private import codeql.controlflow.BasicBlock as BB
private import codeql.controlflow.BasicBlocks as LocalBasicBlocks
private import codeql.Cfg as LocalCfg
private import codeql.Locations
private import codeql.Solidity

/**
 * A `CfgSig` adapter that wraps the existing local CFG / BasicBlock types so
 * the shared SSA library can be instantiated against them.
 */
private module Cfg implements BB::CfgSig<Location> {
  class ControlFlowNode = LocalCfg::Node;

  class BasicBlock = LocalBasicBlocks::BasicBlock;

  class EntryBasicBlock = LocalBasicBlocks::EntryBasicBlock;

  predicate dominatingEdge(BasicBlock bb1, BasicBlock bb2) {
    bb1.getASuccessor() = bb2 and
    bb1.dominates(bb2) and
    forall(BasicBlock pred | pred = bb2.getAPredecessor() and pred != bb1 | bb2.dominates(pred))
  }
}

/** Gets the enclosing function-like scope of the given AST node, if any. */
private AstNode enclosingFunctionScope(AstNode n) {
  result = n.getParent*() and
  (
    result instanceof FunctionDefinition or
    result instanceof ModifierDefinition or
    result instanceof ConstructorDefinition or
    result instanceof FallbackReceiveDefinition
  )
}

/**
 * Resolves an `Identifier` in expression context to the `VariableDeclaration`
 * or `Parameter` it refers to, by name within the enclosing function scope.
 */
private AstNode resolveIdentifier(Identifier id) {
  exists(string name, AstNode scope |
    name = id.getValue() and
    scope = enclosingFunctionScope(id) and
    (
      result.(VariableDeclaration).getName().getValue() = name and
      enclosingFunctionScope(result) = scope
      or
      result.(Parameter).getName().getValue() = name and
      result.getParent*() = scope
    )
  )
}

/** A variable that participates in SSA: a local variable or a parameter. */
private newtype TSourceVariable =
  TLocalVariable(VariableDeclaration v) {
    // Restrict to declarations inside a function-like scope (excludes state vars,
    // which are storage and are tracked via `jumpStep` instead).
    exists(enclosingFunctionScope(v))
  } or
  TParameter(Parameter p) { exists(enclosingFunctionScope(p)) }

class SourceVariable extends TSourceVariable {
  string toString() {
    exists(VariableDeclaration v | this = TLocalVariable(v) |
      result = "local " + v.getName().getValue()
    )
    or
    exists(Parameter p | this = TParameter(p) | result = "param " + p.getName().getValue())
  }

  Location getLocation() {
    exists(VariableDeclaration v | this = TLocalVariable(v) | result = v.getLocation())
    or
    exists(Parameter p | this = TParameter(p) | result = p.getLocation())
  }

  /** Gets the textual name of this source variable. */
  string getName() {
    exists(VariableDeclaration v | this = TLocalVariable(v) | result = v.getName().getValue())
    or
    exists(Parameter p | this = TParameter(p) | result = p.getName().getValue())
  }

  /** Gets the AST node where this variable is declared. */
  AstNode getDeclaration() {
    this = TLocalVariable(result) or this = TParameter(result)
  }
}

/** Gets the `SourceVariable` that an `Identifier` use refers to, if any. */
SourceVariable sourceVariableForIdentifier(Identifier id) {
  exists(AstNode decl | decl = resolveIdentifier(id) |
    result = TLocalVariable(decl) or result = TParameter(decl)
  )
}

/**
 * Holds if `writeNode` is the AST node representing a write whose target
 * (after navigating through `IdentifierExpression` wrappers and tuple
 * destructuring) is the source variable `v`.
 */
private predicate writeTargetAt(AstNode writeNode, SourceVariable v) {
  exists(AssignmentExpression ae, IdentifierExpression lhs |
    writeNode = ae and ae.getLeft() = lhs and v = sourceVariableForIdentifier(lhs.getIdentifier())
  )
  or
  exists(AugmentedAssignmentExpression ae, IdentifierExpression lhs |
    writeNode = ae and ae.getLeft() = lhs and v = sourceVariableForIdentifier(lhs.getIdentifier())
  )
  or
  exists(UpdateExpression ue, IdentifierExpression arg |
    writeNode = ue and ue.getArgument() = arg and v = sourceVariableForIdentifier(arg.getIdentifier())
  )
  or
  // Tuple destructuring: (a, b, c) = ...
  exists(AssignmentExpression ae, TupleExpression tup, IdentifierExpression elem |
    writeNode = ae and
    ae.getLeft().getAChild() = tup and
    tup.getChild(_) = elem and
    v = sourceVariableForIdentifier(elem.getIdentifier())
  )
}

/** Holds if `id` appears as the LHS of a write rather than as a value-context read. */
private predicate isWriteContext(Identifier id) {
  exists(AssignmentExpression ae, IdentifierExpression lhs |
    ae.getLeft() = lhs and lhs.getIdentifier() = id
  )
  or
  exists(AugmentedAssignmentExpression ae, IdentifierExpression lhs |
    ae.getLeft() = lhs and lhs.getIdentifier() = id
  )
  or
  exists(UpdateExpression ue, IdentifierExpression arg |
    ue.getArgument() = arg and arg.getIdentifier() = id
  )
  or
  exists(VariableDeclaration vd | vd.getName() = id)
  or
  exists(Parameter p | p.getName() = id)
  or
  // Inside a tuple LHS of an assignment.
  exists(AssignmentExpression ae, TupleExpression tup, IdentifierExpression elem |
    ae.getLeft().getAChild() = tup and tup.getChild(_) = elem and elem.getIdentifier() = id
  )
}

/** Gets the AST node represented by the CFG node at index `i` of basic block `bb`. */
private predicate cfgNodeAt(Cfg::BasicBlock bb, int i, AstNode n) {
  bb.getNode(i).getAstNode() = n
}

private class SsaImpl_SourceVariable = SourceVariable;

private module SsaInput implements SsaImpl::InputSig<Location, Cfg::BasicBlock> {
  class SourceVariable = SsaImpl_SourceVariable;

  predicate variableWrite(Cfg::BasicBlock bb, int i, SourceVariable v, boolean certain) {
    certain = true and
    (
      // Parameter entry: write at index -1 of the enclosing function's entry block.
      exists(Parameter p, AstNode scope |
        v = TParameter(p) and
        scope = enclosingFunctionScope(p) and
        bb.(LocalBasicBlocks::EntryBasicBlock).getScope() = scope and
        i = -1
      )
      or
      // Variable declarations with an initializer.
      // NOTE: `for (uint i = 0; ...)` produces a VariableDeclarationStatement in the
      // for-init slot, which is covered by this case. `for (i = 0; ...)` produces
      // an ExpressionStatement wrapping an AssignmentExpression, covered below.
      exists(VariableDeclarationStatement vds, VariableDeclaration vd |
        cfgNodeAt(bb, i, vds) and
        vd = vds.getAChild() and
        v = TLocalVariable(vd)
      )
      or
      // Plain assignments, augmented assignments, update expressions, and
      // tuple-destructuring writes. The for-update slot (`i++`, `i += 1`) is
      // handled by these cases via the ForExpressionTree CFG ordering.
      exists(AstNode writeNode |
        cfgNodeAt(bb, i, writeNode) and
        writeTargetAt(writeNode, v)
      )
    )
  }

  predicate variableRead(Cfg::BasicBlock bb, int i, SourceVariable v, boolean certain) {
    certain = true and
    exists(Identifier id |
      cfgNodeAt(bb, i, id) and
      v = sourceVariableForIdentifier(id) and
      not isWriteContext(id)
    )
  }
}

private module Impl = SsaImpl::Make<Location, Cfg, SsaInput>;

class Definition = Impl::Definition;

class WriteDefinition = Impl::WriteDefinition;

class PhiNode = Impl::PhiNode;

class UncertainWriteDefinition = Impl::UncertainWriteDefinition;
