private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Ast
private import Locations
private import Token

/* Contains classes related to Calls */

class CallArgument extends TCallArgument, AstNode, AstNodeImpl {
  private Solidity::CallArgument node;

  CallArgument() { this = TCallArgument(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class CallStructArgument extends TCallStructArgument, AstNode, AstNodeImpl {
  private Solidity::CallStructArgument node;

  CallStructArgument() { this = TCallStructArgument(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getValue()
  }

  Identifier getName() { toTreeSitter(result) = node.getName() }

  Expression getValue() { toTreeSitter(result) = node.getValue() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

