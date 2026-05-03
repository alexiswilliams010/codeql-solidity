/**
 * Provides the public dataflow `Node` hierarchy.
 *
 * Users import `codeql.DataFlow` (a re-export of this file) and write
 * `Configuration` modules in terms of `Node`, `ExprNode`, `ParameterNode`,
 * etc. To translate between AST types and `Node`s, use the top-level
 * helpers `exprNode(Expression)` and `parameterNode(Parameter)`, or the
 * `Node::asExpr()` / `Node::asParameter()` accessors.
 */

private import codeql.Solidity
private import codeql.Locations

newtype TNode =
  MkExprNode(Expression e) or
  MkParameterNode(Parameter p) or
  MkPostUpdateNode(Expression e) {
    // An expression that appears as a mutation-target qualifier: the receiver
    // of a member access, the base of an array access, the LHS of an assignment,
    // or the receiver of a method call (`x.foo()` may mutate `x`).
    exists(MemberExpression me | me.getObject() = e)
    or
    exists(ArrayAccess aa | aa.getBase() = e)
    or
    exists(AssignmentExpression ae | ae.getLeft() = e)
    or
    exists(CallExpression ce, MemberExpression callee |
      ce.getFunction() = callee and callee.getObject() = e
    )
  }

/**
 * A node in the data flow graph. Every dataflow `Node` corresponds to either
 * an AST `Expression`, an AST `Parameter`, or the post-state (`PostUpdateNode`)
 * of an expression that may have been mutated.
 */
class Node extends TNode {
  /** Gets a textual representation of this node. */
  string toString() {
    exists(Expression e | this = MkExprNode(e) | result = e.toString())
    or
    exists(Parameter p | this = MkParameterNode(p) | result = p.toString())
    or
    exists(Expression e | this = MkPostUpdateNode(e) | result = "[post update] " + e.toString())
  }

  /** Gets the location of this node. */
  Location getLocation() {
    exists(Expression e | this = MkExprNode(e) | result = e.getLocation())
    or
    exists(Parameter p | this = MkParameterNode(p) | result = p.getLocation())
    or
    exists(Expression e | this = MkPostUpdateNode(e) | result = e.getLocation())
  }

  /**
   * Gets the wrapped `Expression` if this is an `ExprNode` (which includes
   * `ArgumentNode`, `ReturnNode`, `OutNode`, and `CastNode`).
   */
  Expression asExpr() { this = MkExprNode(result) }

  /** Gets the wrapped `Parameter` if this is a `ParameterNode`. */
  Parameter asParameter() { this = MkParameterNode(result) }

  /** Gets the wrapped `Expression` if this is a `PostUpdateNode`. */
  Expression asPostUpdateExpr() { this = MkPostUpdateNode(result) }
}

/** A dataflow node that wraps an AST `Expression`. */
class ExprNode extends Node, MkExprNode {
  Expression e;

  ExprNode() { this = MkExprNode(e) }

  /** Gets the wrapped expression. */
  Expression getExpr() { result = e }

  override string toString() { result = e.toString() }

  override Location getLocation() { result = e.getLocation() }
}

/** A dataflow node that wraps an AST `Parameter`. */
class ParameterNode extends Node, MkParameterNode {
  Parameter p;

  ParameterNode() { this = MkParameterNode(p) }

  /** Gets the wrapped parameter. */
  Parameter getParameter() { result = p }

  override string toString() { result = p.toString() }

  override Location getLocation() { result = p.getLocation() }
}

/**
 * A dataflow node representing the post-state of an expression that may have
 * been mutated by an operation (e.g. the receiver of a method call, or the
 * qualifier of a field write).
 */
class PostUpdateNode extends Node, MkPostUpdateNode {
  Expression e;

  PostUpdateNode() { this = MkPostUpdateNode(e) }

  /** Gets the corresponding pre-update node (the same expression's value before mutation). */
  Node getPreUpdateNode() { result = MkExprNode(e) }

  /** Gets the underlying expression whose post-state this represents. */
  Expression getExpr() { result = e }

  override string toString() { result = "[post update] " + e.toString() }

  override Location getLocation() { result = e.getLocation() }
}

/**
 * An `ExprNode` that appears as an argument to a `CallExpression`.
 *
 * The wrapped expression is the value being passed; its enclosing
 * `CallArgument` and `CallExpression` provide the call context.
 */
class ArgumentNode extends ExprNode {
  ArgumentNode() {
    exists(CallExpression ce, CallArgument ca |
      ce.getArgument(_) = ca and ca.getAChild() = this.getExpr()
    )
  }
}

/**
 * An `ExprNode` that is the value of a `ReturnStatement`. For `return (a, b)`
 * the wrapped expression is the `TupleExpression` itself; element-wise return
 * tracking is handled at the dataflow-step level.
 */
class ReturnNode extends ExprNode {
  ReturnNode() {
    exists(ReturnStatement rs | rs.getChild() = this.getExpr())
  }
}

/**
 * An `ExprNode` that *is* a `CallExpression` — the result value of the call,
 * which the dataflow engine connects to callee returns via `getAnOutNode`.
 */
class OutNode extends ExprNode {
  OutNode() { this.getExpr() instanceof CallExpression }
}

/** An `ExprNode` that *is* a `TypeCastExpression` (treated as transparent for type pruning). */
class CastNode extends ExprNode {
  CastNode() { this.getExpr() instanceof TypeCastExpression }
}

/** Gets the `ExprNode` that wraps the given AST `Expression`. */
ExprNode exprNode(Expression e) { result = MkExprNode(e) }

/** Gets the `ParameterNode` that wraps the given AST `Parameter`. */
ParameterNode parameterNode(Parameter p) { result = MkParameterNode(p) }
