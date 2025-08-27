private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Ast
private import Locations
private import Token

/* Contains classes related to Smart Contracts */

class ContractDeclaration extends TContractDeclaration, AstNode, AstNodeImpl {
  private Solidity::ContractDeclaration node;

  ContractDeclaration() { this = TContractDeclaration(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getChild(_)
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  override string toString() { result = toTreeSitter(this).toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ImportDirective extends TImportDirective, AstNode, AstNodeImpl {
  private Solidity::ImportDirective node;

  ImportDirective() { this = TImportDirective(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getAlias(_) or toTreeSitter(result) = node.getImportName(_) or toTreeSitter(result) = node.getSource()
  }

  Identifier getAlias(int i) { toTreeSitter(result) = node.getAlias(i) }

  Identifier getImportName(int i) { toTreeSitter(result) = node.getImportName(i) }

  String getSource() { toTreeSitter(result) = node.getSource() }

  override string toString() { result = toTreeSitter(this).toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class SourceFile extends TSourceFile, AstNode, AstNodeImpl {
  private Solidity::SourceFile node;

  SourceFile() { this = TSourceFile(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  override string toString() { result = toTreeSitter(this).toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}
