/* This library wraps values from the internal AST library into higher-level language abstractions */
private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Locations

// A node in the AST. This is the base class for all classes in this library
class AstNode extends TAstNode {
  // TAstNode is an algebraic data type that cannot be used to generate a characteristic predicate
  // So each time we need to get an underlying value, we need to convert from TAstNode to Solidity::AstNode and call the method on that
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  AstNode getParent() { toTreeSitter(result) = toTreeSitter(this).getParent() }

  int getParentIndex() { result = toTreeSitter(this).getParentIndex() }

  string toString() { result = "AstNode" }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  Location getLocation() { result = toTreeSitter(this).getLocation() }

  File getFile() { result = toTreeSitter(this).getLocation().getFile() }
}

class BinaryExpression extends TBinaryExpression, AstNode {
  // TBinaryExpression is NOT an algebraic data type (it is an alias) so we can use it to generate a characteristic predicate
  private Solidity::BinaryExpression node;

  BinaryExpression() { this = TBinaryExpression(node) }

  override AstNode getAChild() { 
    // Return both left and right operands
    toTreeSitter(result) = node.getLeft() or toTreeSitter(result) = node.getRight()
  }

  AstNode getLeft() { toTreeSitter(result) = node.getLeft() }

  AstNode getRight() { toTreeSitter(result) = node.getRight() }

  string getOperator() { result = node.getOperator() }

  override string toString() { result = node.getOperator() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}