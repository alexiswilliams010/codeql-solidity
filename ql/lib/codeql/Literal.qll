private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Ast
private import Locations
private import Token

/* Derivations of the Literal and YulLiteral classes are defined here */

class BooleanLiteral extends TBooleanLiteral, Literal, AstNodeImpl {
  private Solidity::BooleanLiteral node;

  BooleanLiteral() { this = TBooleanLiteral(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild()
  }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class NumberLiteral extends TNumberLiteral, Literal, AstNodeImpl {
  private Solidity::NumberLiteral node;

  NumberLiteral() { this = TNumberLiteral(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class StringLiteral extends TStringLiteral, Literal, AstNodeImpl {
  private Solidity::StringLiteral node;

  StringLiteral() { this = TStringLiteral(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class YulStringLiteral extends TYulStringLiteral, TYulLiteral, AstNodeImpl {
  private Solidity::YulStringLiteral node;

  YulStringLiteral() { this = TYulStringLiteral(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}
