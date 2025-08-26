private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Locations
private import Ast

class FunctionDefinition extends TFunctionDefinition, AstNode, AstNodeImpl {
  private Solidity::FunctionDefinition node;

  FunctionDefinition() { this = TFunctionDefinition(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getReturnType() or toTreeSitter(result) = node.getChild(_)
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  Identifier getName() { toTreeSitter(result) = node.getName() }

  ReturnTypeDefinition getReturnType() { toTreeSitter(result) = node.getReturnType() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class FunctionElement extends TFunctionElement, TAstNode {
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  string toString() { result = toTreeSitter(this).toString() }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class ReturnTypeDefinition extends TReturnTypeDefinition, AstNode, AstNodeImpl {
  private Solidity::ReturnTypeDefinition node;

  ReturnTypeDefinition() { this = TReturnTypeDefinition(node) }

  override Parameter getAChild() { toTreeSitter(result) = node.getChild(_) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}
