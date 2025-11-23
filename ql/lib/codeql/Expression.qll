private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Locations
private import Ast
private import Call
private import Token

/* Derivations of the Expression class are defined here */

class ArrayAccess extends TArrayAccess, Expression, AstNodeImpl {
  private Solidity::ArrayAccess node;

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getBase() or toTreeSitter(result) = node.getIndex()
  }

  AstNode getBase() { toTreeSitter(result) = node.getBase() }

  AstNode getIndex() { toTreeSitter(result) = node.getIndex() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class AssignmentExpression extends TAssignmentExpression, Expression, AstNodeImpl {
  private Solidity::AssignmentExpression node;

  AssignmentExpression() { this = TAssignmentExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getLeft() or toTreeSitter(result) = node.getRight()
  }

  AstNode getLeft() { toTreeSitter(result) = node.getLeft() }

  AstNode getRight() { toTreeSitter(result) = node.getRight() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class AugmentedAssignmentExpression extends TAugmentedAssignmentExpression, Expression, AstNodeImpl {
  private Solidity::AugmentedAssignmentExpression node;

  AugmentedAssignmentExpression() { this = TAugmentedAssignmentExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getLeft() or toTreeSitter(result) = node.getRight()
  }

  AstNode getLeft() { toTreeSitter(result) = node.getLeft() }

  AstNode getRight() { toTreeSitter(result) = node.getRight() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class BinaryExpression extends TBinaryExpression, Expression, AstNodeImpl {
  // TBinaryExpression is NOT an algebraic data type, so we CAN use it to generate a characteristic predicate
  private Solidity::BinaryExpression node;

  BinaryExpression() { this = TBinaryExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

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

class CallExpression extends TCallExpression, Expression, AstNodeImpl {
  private Solidity::CallExpression node;

  CallExpression() { this = TCallExpression(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getFunction() or toTreeSitter(result) = node.getChild(_)
  }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  CallArgument getArguments() { toTreeSitter(result) = node.getChild(_) }

  CallArgument getArgument(int i) { toTreeSitter(result) = node.getChild(i) }

  Expression getFunction() { toTreeSitter(result) = node.getFunction() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class InlineArrayExpression extends TInlineArrayExpression, Expression, AstNodeImpl {
  private Solidity::InlineArrayExpression node;

  InlineArrayExpression() { this = TInlineArrayExpression(node) }
  
  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  Expression getChild(int i) { toTreeSitter(result) = node.getChild(i) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class MemberExpression extends TMemberExpression, Expression, AstNodeImpl {
  private Solidity::MemberExpression node;

  MemberExpression() { this = TMemberExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getObject() or toTreeSitter(result) = node.getProperty()
  }

  AstNode getObject() { toTreeSitter(result) = node.getObject() }

  Identifier getProperty() { toTreeSitter(result) = node.getProperty() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class NewExpression extends TNewExpression, Expression, AstNodeImpl {
  private Solidity::NewExpression node;

  NewExpression() { this = TNewExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getChild(_)
  }

  // TODO: Should be TypeName and not AstNode directly
  AstNode getName() { toTreeSitter(result) = node.getName() }

  CallArgument getArguments() { toTreeSitter(result) = node.getChild(_) }

  CallArgument getArgument(int i) { toTreeSitter(result) = node.getChild(i) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ParenthesizedExpression extends TParenthesizedExpression, Expression, AstNodeImpl {
  private Solidity::ParenthesizedExpression node;

  ParenthesizedExpression() { this = TParenthesizedExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild()
  }

  Expression getChild() { toTreeSitter(result) = node.getChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class PayableConversionExpression extends TPayableConversionExpression, Expression, AstNodeImpl {
  private Solidity::PayableConversionExpression node;

  PayableConversionExpression() { this = TPayableConversionExpression(node) }
  
  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  CallArgument getChild(int i) { toTreeSitter(result) = node.getChild(i) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class SliceAccess extends TSliceAccess, Expression, AstNodeImpl {
  private Solidity::SliceAccess node;

  SliceAccess() { this = TSliceAccess(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() {
    toTreeSitter(result) = node.getBase() or 
    toTreeSitter(result) = node.getFrom() or 
    toTreeSitter(result) = node.getTo()
  }

  Expression getBase() { toTreeSitter(result) = node.getBase() }

  Expression getFrom() { toTreeSitter(result) = node.getFrom() }

  Expression getTo() { toTreeSitter(result) = node.getTo() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class StructExpression extends TStructExpression, Expression, AstNodeImpl {
  private Solidity::StructExpression node;

  StructExpression() { this = TStructExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() {
    toTreeSitter(result) = node.getType() or 
    toTreeSitter(result) = node.getChild(_)
  }

  Expression getType() { toTreeSitter(result) = node.getType() }

  AstNode getChild(int i) { toTreeSitter(result) = node.getChild(i) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class TernaryExpression extends TTernaryExpression, Expression, AstNodeImpl {
  private Solidity::TernaryExpression node;

  TernaryExpression() { this = TTernaryExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  Expression getChild(int i) { toTreeSitter(result) = node.getChild(i) }

  Expression getCondition() { result = this.getChild(0) }

  Expression getThen() { result = this.getChild(1) }

  Expression getElse() { result = this.getChild(2) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class TypeCastExpression extends TTypeCastExpression, Expression, AstNodeImpl {
  private Solidity::TypeCastExpression node;

  TypeCastExpression() { this = TTypeCastExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  AstNode getChild(int i) { toTreeSitter(result) = node.getChild(i) }

  // The type being cast to (e.g., uint256, address)
  AstNode getType() { toTreeSitter(result) = node.getChild(0) }

  // The value being cast (wrapped in CallArgument)
  CallArgument getValue() { toTreeSitter(result) = node.getChild(1) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class TupleExpression extends TTupleExpression, Expression, AstNodeImpl {
  private Solidity::TupleExpression node;

  TupleExpression() { this = TTupleExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  Expression getChild(int i) { toTreeSitter(result) = node.getChild(i) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class UnaryExpression extends TUnaryExpression, Expression, AstNodeImpl {
  private Solidity::UnaryExpression node;

  UnaryExpression() { this = TUnaryExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { toTreeSitter(result) = node.getAFieldOrChild() }

  Expression getArgument() { toTreeSitter(result) = node.getArgument() }

  string getOperator() { result = node.getOperator() }

  override string toString() { result = this.getOperator() + "..." }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class UpdateExpression extends TUpdateExpression, Expression, AstNodeImpl {
  private Solidity::UpdateExpression node;

  UpdateExpression() { this = TUpdateExpression(node) }

  override AstNode getParent() { toTreeSitter(result) = node.getParent() }

  override AstNode getAChild() { toTreeSitter(result) = node.getArgument() }

  Expression getArgument() { toTreeSitter(result) = node.getArgument() }

  string getOperator() { result = node.getOperator() }

  override string toString() { result = this.getOperator() + "..." }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}
