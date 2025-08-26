private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Locations
private import Ast

/* Derivations of the Literal and YulLiteral classes are defined here */

class BooleanLiteral extends TBooleanLiteral, TLiteral, AstNodeImpl {
  private Solidity::BooleanLiteral node;

  BooleanLiteral() { this = TBooleanLiteral(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild()
  }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class HexStringLiteral extends THexStringLiteral, TLiteral, TYulLiteral, AstNodeImpl {
  private Solidity::HexStringLiteral node;

  HexStringLiteral() { this = THexStringLiteral(node) }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class NumberLiteral extends TNumberLiteral, Literal {
  private Solidity::NumberLiteral node;

  NumberLiteral() { this = TNumberLiteral(node) }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class StringLiteral extends TStringLiteral, TLiteral, AstNodeImpl {
  private Solidity::StringLiteral node;

  StringLiteral() { this = TStringLiteral(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class UnicodeStringLiteral extends TUnicodeStringLiteral, TLiteral, AstNodeImpl {
  private Solidity::UnicodeStringLiteral node;

  UnicodeStringLiteral() { this = TUnicodeStringLiteral(node) }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class YulDecimalNumber extends TYulDecimalNumber, TYulLiteral, AstNodeImpl {
  private Solidity::YulDecimalNumber node;

  YulDecimalNumber() { this = TYulDecimalNumber(node) }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class YulStringLiteral extends TYulStringLiteral, TYulLiteral, AstNodeImpl {
  private Solidity::YulStringLiteral node;

  YulStringLiteral() { this = TYulStringLiteral(node) }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class YulHexNumber extends TYulHexNumber, TYulLiteral, AstNodeImpl {
  private Solidity::YulHexNumber node;

  YulHexNumber() { this = TYulHexNumber(node) }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class YulBoolean extends TYulBoolean, TYulLiteral, AstNodeImpl {
  private Solidity::YulBoolean node;

  YulBoolean() { this = TYulBoolean(node) }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}
