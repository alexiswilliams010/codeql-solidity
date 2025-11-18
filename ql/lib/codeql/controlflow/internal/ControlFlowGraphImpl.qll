private import codeql.Ast
private import codeql.Solidity
private import codeql.controlflow.Cfg as CfgShared
private import codeql.Locations

module Completion {
  private newtype TCompletion =
    TSimpleCompletion() or
    TBooleanCompletion(boolean b) { b in [false, true] } or
    TReturnCompletion() or
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

  class RevertCompletion extends Completion, TRevertCompletion {
    override string toString() { result = "ExceptionCompletion" }

    override predicate isValidForSpecific(AstNode e) { none() }

    override RevertSuccessor getAMatchingSuccessorType() { any() }
  }

  cached
  private newtype TSuccessorType =
    TNormalSuccessor() or
    TBooleanSuccessor(boolean b) { b in [false, true] } or
    TReturnSuccessor() or
    TRevertSuccessor()

  class SuccessorType extends TSuccessorType {
    string toString() { none() }
  }

  class NormalSuccessor extends SuccessorType, TNormalSuccessor {
    override string toString() { result = "successor" }
  }

  class BooleanSuccessor extends SuccessorType, TBooleanSuccessor {
    boolean value;

    BooleanSuccessor() { this = TBooleanSuccessor(value) }

    override string toString() { result = value.toString() }

    boolean getValue() { result = value }
  }

  class ReturnSuccessor extends SuccessorType, TReturnSuccessor {
    override string toString() { result = "return" }
  }

  class RevertSuccessor extends SuccessorType, TRevertSuccessor {
    override string toString() { result = "revert" }
  }
}

module CfgScope {
  abstract class CfgScope extends AstNode { }

  private class FunctionScope extends CfgScope, FunctionDefinition { }

  // TODO: Add other scopes including modules, contracts, etc.
}

private module Implementation implements CfgShared::InputSig<Location> {
  import codeql.Ast
  import Completion
  import CfgScope

  predicate completionIsNormal(Completion c) { not c instanceof ReturnCompletion }

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
    first(scope.(FunctionDefinition).getBody(), e)
    // TODO: Add other scopes including modules, contracts, etc.
  }

  predicate scopeLast(CfgScope scope, AstNode e, Completion c) {
    last(scope.(FunctionDefinition).getBody(), e, c)
    // TODO: Add other scopes including modules, contracts, etc.
  }

  predicate successorTypeIsSimple(SuccessorType t) { t instanceof NormalSuccessor }

  predicate successorTypeIsCondition(SuccessorType t) { t instanceof BooleanSuccessor }

  SuccessorType getAMatchingSuccessorType(Completion c) { result = c.getAMatchingSuccessorType() }

  predicate isAbnormalExitType(SuccessorType t) { none() }
}

module CfgImpl = CfgShared::Make<Location, Implementation>;

private import CfgImpl
private import Completion
private import CfgScope

private class FunctionDefinitionTree extends LeafTree instanceof FunctionDefinition { }

private class FunctionCallExpressionTree extends StandardPostOrderTree instanceof CallExpression
{
  // TODO: CallExpression is not that straightforward, needs to pull out the expression and then the arguments
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
      // TODO: IfStatement does not directly expose 'if-then' path, needs to be pulled out
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
  // TODO: This may need to be adjusted since the kaleidoscope version is more of a do-while construct
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

private class InitializerTree extends StandardPostOrderTree instanceof Initializer {
  override ControlFlowTree getChildNode(int i) { result = super.getExpression() and i = 0 }
}

private class NumberTree extends LeafTree instanceof Number { }

private class ParenExpressionTree extends StandardPostOrderTree instanceof ParenExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getExpression() and i = 0 }
}

private class UnaryOpExpressionTree extends StandardPostOrderTree instanceof UnaryOpExpression {
  override ControlFlowTree getChildNode(int i) { result = super.getOperand() and i = 0 }
}

private class VarInExpressionTree extends StandardPostOrderTree instanceof VarInExpression {
  override ControlFlowTree getChildNode(int i) {
    result = super.getInitializer(i)
    or
    result = super.getBody() and i = count(super.getInitializer(_))
  }
}

private class VariableExpressionTree extends LeafTree instanceof VariableExpression { }