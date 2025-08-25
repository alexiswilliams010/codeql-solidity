/* This library wraps values from the internal AST library into higher-level language abstractions */
private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Locations

class AstNode instanceof TAstNode {
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  AstNode getParent() { toTreeSitter(result) = toTreeSitter(this).getParent() }

  int getParentIndex() { result = toTreeSitter(this).getParentIndex() }
  
  string toString() { result = "AstNode" }
  
  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }
  
  Location getLocation() { result = toTreeSitter(this).getLocation() }

  File getFile() { result = this.getLocation().getFile() }
}

class BinaryExpression instanceof TBinaryExpression {
  string toString() { result = "BinaryExpression" }

  AstNode getAChild() { 
    // Return either left or right operand
    result = this.getLeft() or result = this.getRight()
  }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  AstNode getLeft() { 
    // Cast to TreeSitter BinaryExpression and access getLeft
    exists(Solidity::BinaryExpression binExpr |
      binExpr = toTreeSitter(this) and
      toTreeSitter(result) = binExpr.getLeft()
    )
  }

  AstNode getRight() { 
    // Cast to TreeSitter BinaryExpression and access getRight
    exists(Solidity::BinaryExpression binExpr |
      binExpr = toTreeSitter(this) and
      toTreeSitter(result) = binExpr.getRight()
    )
  }

  string getOperator() { 
    // Cast to TreeSitter BinaryExpression and access getOperator
    exists(Solidity::BinaryExpression binExpr |
      binExpr = toTreeSitter(this) and 
      result = binExpr.getOperator()
    )
  }

  Location getLocation() { result = toTreeSitter(this).getLocation() }
}