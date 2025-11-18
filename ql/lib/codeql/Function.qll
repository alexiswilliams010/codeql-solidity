private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Ast
private import Locations
private import Token

class FunctionDefinition extends TFunctionDefinition, AstNode, AstNodeImpl {
  private Solidity::FunctionDefinition node;

  FunctionDefinition() { this = TFunctionDefinition(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getReturnType() or toTreeSitter(result) = node.getChild(_)
  }

  FunctionBody getBody() { toTreeSitter(result) = node.getBody() }

  Identifier getName() { toTreeSitter(result) = node.getName() }

  ReturnTypeDefinition getReturnType() { toTreeSitter(result) = node.getReturnType() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class FunctionElement extends TFunctionElement, AstNode, AstNodeImpl {
  override AstNode getParent() { toTreeSitter(result) = toTreeSitter(this).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  override string toString() { result = toTreeSitter(this).toString() }

  override string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  override Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class ReturnTypeDefinition extends TReturnTypeDefinition, AstNode, AstNodeImpl {
  private Solidity::ReturnTypeDefinition node;

  ReturnTypeDefinition() { this = TReturnTypeDefinition(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override Parameter getAChild() { toTreeSitter(result) = node.getChild(_) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class YulFunctionDefinition extends TYulFunctionDefinition, AstNode, AstNodeImpl {
  private Solidity::YulFunctionDefinition node;

  YulFunctionDefinition() { this = TYulFunctionDefinition(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { toTreeSitter(result) = node.getChild(_) }

  AstNode getAFieldOrChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class FallbackReceiveDefinition extends TFallbackReceiveDefinition, AstNode, AstNodeImpl {
  private Solidity::FallbackReceiveDefinition node;

  FallbackReceiveDefinition() { this = TFallbackReceiveDefinition(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { toTreeSitter(result) = node.getChild(_) }

  AstNode getAFieldOrChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  FunctionBody getBody() { toTreeSitter(result) = node.getBody() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class FunctionBody extends TFunctionBody, AstNode, AstNodeImpl {
  private Solidity::FunctionBody node;

  FunctionBody() { this = TFunctionBody(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { toTreeSitter(result) = node.getChild(_) }
  AstNode getAFieldOrChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}