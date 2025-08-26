private import solidity.ast.internal.TreeSitter
private import solidity.ast.internal.Ast
private import Locations
private import Ast
private import Call

/* Derivations of the Expression class are defined here */

class ArrayAccess extends TArrayAccess, Expression, AstNodeImpl {
  private Solidity::ArrayAccess node;

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

  CallArgument getArguments() { toTreeSitter(result) = node.getChild(_) }

  Expression getFunction() { toTreeSitter(result) = node.getFunction() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class MemberExpression extends TMemberExpression, Expression, AstNodeImpl {
  private Solidity::MemberExpression node;

  MemberExpression() { this = TMemberExpression(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getObject() or toTreeSitter(result) = node.getProperty()
  }

  AstNode getObject() { toTreeSitter(result) = node.getObject() }

  // TODO: Should be Identifier and not AstNode directly
  AstNode getProperty() { toTreeSitter(result) = node.getProperty() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class NewExpression extends TNewExpression, Expression, AstNodeImpl {
  private Solidity::NewExpression node;

  NewExpression() { this = TNewExpression(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getName() or toTreeSitter(result) = node.getChild(_)
  }

  // TODO: Should be TypeName and not AstNode directly
  AstNode getName() { toTreeSitter(result) = node.getName() }

  // TODO: CallArgument getArguments() equivalent to get the arguments for a NewExpression

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class ParenthesizedExpression extends TParenthesizedExpression, Expression, AstNodeImpl {
  private Solidity::ParenthesizedExpression node;

  ParenthesizedExpression() { this = TParenthesizedExpression(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild()
  }

  Expression getChild() { toTreeSitter(result) = node.getChild() }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class TernaryExpression extends TTernaryExpression, Expression, AstNodeImpl {
  private Solidity::TernaryExpression node;

  TernaryExpression() { this = TTernaryExpression(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  Expression getChild(int i) { toTreeSitter(result) = node.getChild(i) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}

class TupleExpression extends TTupleExpression, Expression, AstNodeImpl {
  private Solidity::TupleExpression node;

  TupleExpression() { this = TTupleExpression(node) }

  override AstNode getAChild() { 
    toTreeSitter(result) = node.getChild(_)
  }

  Expression getChild(int i) { toTreeSitter(result) = node.getChild(i) }

  override string toString() { result = node.toString() }

  override string getAPrimaryQlClass() { result = node.getAPrimaryQlClass() }

  override Location getLocation() { result = node.getLocation() }
}
