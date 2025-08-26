/* This library wraps values from the internal AST library into higher-level language abstractions */
private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Locations

// Useful for ensuring that all AstNode implementations have the required methods
abstract class AstNodeImpl extends TAstNode {
  abstract AstNode getAChild();

  abstract string toString();

  abstract string getAPrimaryQlClass();

  abstract Location getLocation();
}

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

// Wrapper for the Token class in the internal AST library
class Token extends TToken, TAstNode {
  // TToken is an algebraic data type so we can't use it to generate a characteristic predicate
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  string toString() { result = toTreeSitter(this).toString() }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  Location getLocation() { result = toTreeSitter(this).getLocation() }
}

// Wrapper for the Expression class in the internal AST library
class Expression extends TExpression, TAstNode {
  // TExpression is an algebraic data type so we can't use it to generate a characteristic predicate
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  string toString() { result = toTreeSitter(this).toString() }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class Literal extends TLiteral, Expression {
  override string toString() { result = toTreeSitter(this).toString() }
}

class Block extends TBlock, TAstNode {
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  string toString() { result = toTreeSitter(this).toString() }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class Statement extends TStatement, Block {
  override AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  override string toString() { result = toTreeSitter(this).toString() }

  override string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  override Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class AssemblyStatement extends TAssemblyStatement, Statement {
  override AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  override string toString() { result = toTreeSitter(this).toString() }

  override string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  override Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class YulStatement extends TYulStatement, AssemblyStatement {
  override AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  override string toString() { result = toTreeSitter(this).toString() }

  override string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  override Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class YulExpression extends TYulExpression, TAstNode {
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  string toString() { result = toTreeSitter(this).toString() }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class YulLiteral extends TYulLiteral, YulExpression {
  override AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  override string toString() { result = toTreeSitter(this).toString() }

  override string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  override Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class Declaration extends TDeclaration, TAstNode {
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  string toString() { result = toTreeSitter(this).toString() }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class FunctionElement extends TFunctionElement, TAstNode {
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  string toString() { result = toTreeSitter(this).toString() }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class SourceUnit extends TSourceUnit, TAstNode {
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  string toString() { result = toTreeSitter(this).toString() }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class Contract extends TContract, TAstNode {
  AstNode getAChild() { toTreeSitter(result) = toTreeSitter(this).getAFieldOrChild() }

  string toString() { result = toTreeSitter(this).toString() }

  string getAPrimaryQlClass() { result = toTreeSitter(this).getAPrimaryQlClass() }

  Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class CallStructArgument extends TCallStructArgument, AstNode, AstNodeImpl {
  private Solidity::CallStructArgument node;

  CallStructArgument() { this = TCallStructArgument(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getValue()
  }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  AstNode getValue() { toTreeSitter(result) = node.getValue() }

  override string toString() { result = "CallStructArgument" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ConstantVariableDeclaration extends TConstantVariableDeclaration, AstNode, AstNodeImpl {
  private Solidity::ConstantVariableDeclaration node;

  ConstantVariableDeclaration() { this = TConstantVariableDeclaration(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getType() or toTreeSitter(result) = node.getValue()
  }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  AstNode getType() { toTreeSitter(result) = node.getType() }

  AstNode getValue() { toTreeSitter(result) = node.getValue() }

  override string toString() { result = "ConstantVariableDeclaration" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ConstructorDefinition extends TConstructorDefinition, AstNode, AstNodeImpl {
  private Solidity::ConstructorDefinition node;

  ConstructorDefinition() { this = TConstructorDefinition(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getChild(_)
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  override string toString() { result = "ConstructorDefinition" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ContractDeclaration extends TContractDeclaration, AstNode, AstNodeImpl {
  private Solidity::ContractDeclaration node;

  ContractDeclaration() { this = TContractDeclaration(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getChild(_)
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  override string toString() { result = "ContractDeclaration" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class EnumDeclaration extends TEnumDeclaration, AstNode, AstNodeImpl {
  private Solidity::EnumDeclaration node;

  EnumDeclaration() { this = TEnumDeclaration(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getName()
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  override string toString() { result = "EnumDeclaration" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ErrorDeclaration extends TErrorDeclaration, AstNode, AstNodeImpl {
  private Solidity::ErrorDeclaration node;

  ErrorDeclaration() { this = TErrorDeclaration(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getChild(_)
  }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  override string toString() { result = "ErrorDeclaration" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class EventDefinition extends TEventDefinition, AstNode, AstNodeImpl {
  private Solidity::EventDefinition node;

  EventDefinition() { this = TEventDefinition(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getChild(_)
  }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  override string toString() { result = "EventDefinition" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class FunctionDefinition extends TFunctionDefinition, AstNode, AstNodeImpl {
  private Solidity::FunctionDefinition node;

  FunctionDefinition() { this = TFunctionDefinition(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getReturnType() or toTreeSitter(result) = node.getChild(_)
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  AstNode getReturnType() { toTreeSitter(result) = node.getReturnType() }

  override string toString() { result = "FunctionDefinition" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class InterfaceDeclaration extends TInterfaceDeclaration, AstNode, AstNodeImpl {
  private Solidity::InterfaceDeclaration node;

  InterfaceDeclaration() { this = TInterfaceDeclaration(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getChild(_)
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  override string toString() { result = "InterfaceDeclaration" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class LibraryDeclaration extends TLibraryDeclaration, AstNode, AstNodeImpl {
  private Solidity::LibraryDeclaration node;

  LibraryDeclaration() { this = TLibraryDeclaration(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getName()
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  override string toString() { result = "LibraryDeclaration" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ModifierDefinition extends TModifierDefinition, AstNode, AstNodeImpl {
  private Solidity::ModifierDefinition node;

  ModifierDefinition() { this = TModifierDefinition(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getChild(_)
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  override string toString() { result = "ModifierDefinition" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class Parameter extends TParameter, AstNode, AstNodeImpl {
  private Solidity::Parameter node;

  Parameter() { this = TParameter(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getType()
  }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  AstNode getType() { toTreeSitter(result) = node.getType() }

  override string toString() { result = "Parameter" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  AstNode location() { toTreeSitter(result) = node.getLocation() }

  // Have to call to the underlying AstNode class to get the correct Location type
  override Location getLocation() { result = toTreeSitter(this).getLocation() }
}

class StateVariableDeclaration extends TStateVariableDeclaration, AstNode, AstNodeImpl {
  private Solidity::StateVariableDeclaration node;

  StateVariableDeclaration() { this = TStateVariableDeclaration(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getLocation(_) or toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getType() or toTreeSitter(result) = node.getValue() or toTreeSitter(result) = node.getVisibility(_)
  }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  AstNode getType() { toTreeSitter(result) = node.getType() }

  AstNode getValue() { toTreeSitter(result) = node.getValue() }

  override string toString() { result = "StateVariableDeclaration" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class StructDeclaration extends TStructDeclaration, AstNode, AstNodeImpl {
  private Solidity::StructDeclaration node;

  StructDeclaration() { this = TStructDeclaration(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBody() or toTreeSitter(result) = node.getName()
  }

  AstNode getBody() { toTreeSitter(result) = node.getBody() }

  AstNode getName() { toTreeSitter(result) = node.getName() }

  override string toString() { result = "StructDeclaration" }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}
