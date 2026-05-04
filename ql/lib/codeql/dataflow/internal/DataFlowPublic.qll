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
private import codeql.NameResolution

/**
 * Holds if `id` is a bare `Identifier` token used in a value-producing
 * expression position. The Solidity grammar sometimes emits a bare `Identifier`
 * instead of a wrapper `Expression` around an identifier reference (per
 * `@solidity_member_expression_object_type = @solidity_expression | @solidity_token_identifier`),
 * for example the receiver of `target.call(data)` is a bare `Identifier`.
 * These bare identifiers need their own dataflow nodes so taint can flow
 * through them.
 */
private predicate isBareIdentifierInValueContext(Identifier id) {
  exists(MemberExpression me | me.getObject() = id)
  or
  exists(ArrayAccess aa | aa.getBase() = id)
  or
  exists(CallArgument ca | ca.getAChild() = id)
  or
  exists(AssignmentExpression ae | ae.getLeft() = id)
}

newtype TNode =
  MkExprNode(AstNode e) {
    e instanceof Expression
    or
    e instanceof Identifier and isBareIdentifierInValueContext(e)
  } or
  MkParameterNode(Parameter p) or
  MkPostUpdateNode(AstNode e) {
    // A node that appears as a mutation-target qualifier: the receiver
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
      or
      ce.getFunction().getAChild() = callee and callee.getObject() = e
    )
  }

/**
 * A node in the data flow graph. Every dataflow `Node` corresponds to either
 * an AST `Expression`, a bare `Identifier` used as a value, an AST `Parameter`,
 * or the post-state (`PostUpdateNode`) of an expression that may have been
 * mutated.
 */
class Node extends TNode {
  /** Gets a textual representation of this node. */
  string toString() {
    exists(AstNode n | this = MkExprNode(n) | result = n.toString())
    or
    exists(Parameter p | this = MkParameterNode(p) | result = p.toString())
    or
    exists(AstNode n | this = MkPostUpdateNode(n) | result = "[post update] " + n.toString())
  }

  /** Gets the location of this node. */
  Location getLocation() {
    exists(AstNode n | this = MkExprNode(n) | result = n.getLocation())
    or
    exists(Parameter p | this = MkParameterNode(p) | result = p.getLocation())
    or
    exists(AstNode n | this = MkPostUpdateNode(n) | result = n.getLocation())
  }

  /**
   * Gets the wrapped value-producing AST node — an `Expression`, or a bare
   * `Identifier` used as a value (e.g. the receiver of `target.call(data)`).
   */
  AstNode asExpr() { this = MkExprNode(result) }

  /** Gets the wrapped `Parameter` if this is a `ParameterNode`. */
  Parameter asParameter() { this = MkParameterNode(result) }

  /** Gets the wrapped node whose post-state this represents. */
  AstNode asPostUpdateExpr() { this = MkPostUpdateNode(result) }
}

/**
 * A dataflow node that wraps an AST `Expression` or a bare `Identifier` used
 * in value-producing position.
 */
class ExprNode extends Node, MkExprNode {
  AstNode e;

  ExprNode() { this = MkExprNode(e) }

  /**
   * Gets the wrapped node. This is always an `Expression` or a bare
   * `Identifier` token used as a value.
   */
  AstNode getExpr() { result = e }

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
 * A dataflow node representing the post-state of a value that may have been
 * mutated by an operation (e.g. the receiver of a method call, or the
 * qualifier of a field write).
 */
class PostUpdateNode extends Node, MkPostUpdateNode {
  AstNode e;

  PostUpdateNode() { this = MkPostUpdateNode(e) }

  /** Gets the corresponding pre-update node (the same value before mutation). */
  Node getPreUpdateNode() { result = MkExprNode(e) }

  /** Gets the underlying AST node whose post-state this represents. */
  AstNode getExpr() { result = e }

  override string toString() { result = "[post update] " + e.toString() }

  override Location getLocation() { result = e.getLocation() }
}

/**
 * An `ExprNode` that appears as an argument to a `CallExpression`.
 *
 * The wrapped expression is the value being passed; its enclosing
 * `CallArgument` and `CallExpression` provide the call context.
 *
 * Also includes the receiver of a `using-for` call (`y` in `y.foo(args)`
 * where `using Lib for T;` is in scope and `y` has type `T`). Solidity
 * desugars these to `Lib.foo(y, args)`, and the dataflow framework needs
 * `y` to appear as a real `ArgumentNode` for the position-0 mapping in
 * `isArgumentNode` to type-check.
 */
class ArgumentNode extends ExprNode {
  ArgumentNode() {
    exists(CallExpression ce, CallArgument ca |
      ce.getArgument(_) = ca and ca.getAChild() = this.getExpr()
    )
    or
    exists(CallExpression ce |
      NameResolution::Imports::usingForCall(ce, _) and
      this.getExpr() = NameResolution::Imports::usingForReceiver(ce)
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

/**
 * Gets the `ExprNode` that wraps the given AST node (an `Expression` or a
 * bare `Identifier` used in value position). Use this when a predicate
 * accessor like `MemberExpression.getObject()` may return either.
 */
ExprNode valueNode(AstNode n) { result = MkExprNode(n) }

/** Gets the `ParameterNode` that wraps the given AST `Parameter`. */
ParameterNode parameterNode(Parameter p) { result = MkParameterNode(p) }
