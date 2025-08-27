private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Ast
private import Locations
private import Token

/* Derivations of the Statement and YulStatement classes are defined here */

class BlockStatement extends TBlockStatement, Statement, AstNodeImpl {
  private Solidity::BlockStatement node;

  BlockStatement() { this = TBlockStatement(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class DoWhileStatement extends TDoWhileStatement, Statement, AstNodeImpl {
  private Solidity::DoWhileStatement node;

  DoWhileStatement() { this = TDoWhileStatement(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getCondition()
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  AstNode getCondition() { toTreeSitter(result) = node.getCondition() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class EmitStatement extends TEmitStatement, Statement, AstNodeImpl {
  private Solidity::EmitStatement node;

  EmitStatement() { this = TEmitStatement(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getChild(_)
  }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ExpressionStatement extends TExpressionStatement, Statement, AstNodeImpl {
  private Solidity::ExpressionStatement node;

  ExpressionStatement() { this = TExpressionStatement(node) }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ForStatement extends TForStatement, Statement, AstNodeImpl {
  private Solidity::ForStatement node;

  ForStatement() { this = TForStatement(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getCondition() or toTreeSitter(result) = node.getInitial() or toTreeSitter(result) = node.getUpdate()
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  AstNode getCondition() { toTreeSitter(result) = node.getCondition() }

  AstNode getInitial() { toTreeSitter(result) = node.getInitial() }

  AstNode getUpdate() { toTreeSitter(result) = node.getUpdate() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class IfStatement extends TIfStatement, Statement, AstNodeImpl {
  private Solidity::IfStatement node;

  IfStatement() { this = TIfStatement(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody(_) or toTreeSitter(result) = node.getCondition() or toTreeSitter(result) = node.getElse()
  }

  AstNode getCondition() { toTreeSitter(result) = node.getCondition() }

  AstNode getElse() { toTreeSitter(result) = node.getElse() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ReturnStatement extends TReturnStatement, Statement, AstNodeImpl {
  private Solidity::ReturnStatement node;

  ReturnStatement() { this = TReturnStatement(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild()
  }

  AstNode getChild() { toTreeSitter(result) = node.getChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class RevertStatement extends TRevertStatement, Statement, AstNodeImpl {
  private Solidity::RevertStatement node;

  RevertStatement() { this = TRevertStatement(node) }

  Expression getError() { toTreeSitter(result) = node.getError() }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class TryStatement extends TTryStatement, Statement, AstNodeImpl {
  private Solidity::TryStatement node;

  TryStatement() { this = TTryStatement(node) }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class WhileStatement extends TWhileStatement, Statement, AstNodeImpl {
  private Solidity::WhileStatement node;

  WhileStatement() { this = TWhileStatement(node) }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}