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
      e = any(DoWhileStatement c).getCondition()
    }

    override BooleanSuccessor getAMatchingSuccessorType() { result.getValue() = value }

    final boolean getValue() { result = value }
  }

  class ReturnCompletion extends Completion, TReturnCompletion {
    override string toString() { result = "ReturnCompletion" }

    override predicate isValidForSpecific(AstNode e) { none() }

    override ReturnSuccessor getAMatchingSuccessorType() { any() }
  }

  class BreakCompletion extends Completion, TBreakCompletion {
    override string toString() { result = "BreakCompletion" }

    override predicate isValidForSpecific(AstNode e) { e instanceof BreakStatement }

    override BreakSuccessor getAMatchingSuccessorType() { any() }
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

  class SplitKindBase = TUnit;

  class Split extends TUnit {
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

  int maxSplits() { result = 0 }

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

  predicate successorTypeIsSimple(SuccessorType t) { t instanceof DirectSuccessor }

  predicate successorTypeIsCondition(SuccessorType t) { t instanceof BooleanSuccessor }

  SuccessorType getAMatchingSuccessorType(Completion c) { result = c.getAMatchingSuccessorType() }

  predicate isAbnormalExitType(SuccessorType t) { t instanceof ExceptionSuccessor }
}

module CfgImpl = CfgShared::Make<Location, Implementation>;

private import CfgImpl
private import Completion
private import CfgScope

private class FunctionDefinitionTree extends LeafTree instanceof FunctionDefinition { }

private class FunctionCallExpressionTree extends StandardPostOrderTree instanceof CallExpression
{
  override ControlFlowTree getChildNode(int i) { result = super.getArgument(i) }
}

private class BinaryOpExpressionTree extends StandardPostOrderTree instanceof BinaryExpression {
  override ControlFlowTree getChildNode(int i) {
    result = super.getLeft() and i = 0
    or
    result = super.getRight() and i = 1
  }
}

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

/**
 * From https://llvm.org/docs/tutorial/MyFirstLanguageFrontend/LangImpl05.html#code-generation-for-the-for-loop in the LLVM tutorial it appears that
 * for loop conditions are checked at the end of the body, not the start. So for loops are roughly translated as follows:
 * ```
 * for VAR = INIT, CONDITION, STEP in
 *   BODY
 * ```
 * -->
 * ```
 * VAR = INIT
 * do {
 *   BODY
 *   VAR = VAR + STEP
 * } while (CONDITION)
 * ```
 */
private class ForExpressionTree extends PostOrderTree instanceof ForStatement {
  // TODO: This may need to be adjusted since the kaleidoscope version is more of a do-while construct i.e. post-order
  override predicate propagatesAbnormal(AstNode child) { none() }

  override predicate first(AstNode first) { first(super.getInitial(), first) }

  override predicate succ(AstNode pred, AstNode succ, Completion c) {
    last(super.getInitial(), pred, c) and
    first(super.getBody(), succ) and
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

private class NumberTree extends LeafTree instanceof NumberLiteral { }

private class ParenExpressionTree extends StandardPostOrderTree instanceof ParenthesizedExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getChild() and i = 0 }
}

private class UnaryOpExpressionTree extends StandardPostOrderTree instanceof UnaryExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getArgument() and i = 0 }
}

// TODO: The rest of the statement and expression trees need to be implemented
