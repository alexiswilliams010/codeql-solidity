/**
 * Solidity name resolution: maps identifier references to the AST node that
 * declares them. The single name-string match per declaration kind is contained
 * here; downstream code uses AST identity.
 *
 * Scoping cascade for `NameResolution::resolve(Identifier id)`:
 *   1. Local scope (variables declared in `id`'s enclosing function-like, plus
 *      that function's parameters).
 *   2. Contract scope (state variables, constants, functions, modifiers of the
 *      enclosing contract and its inheritance chain).
 *   3. File scope (top-level contracts, interfaces, libraries, and free
 *      functions in the same source file).
 *
 * Returns no result for language built-ins (`msg`, `block`, `tx`, `abi`,
 * `this`, `super`, etc.) — these are not declared in user code.
 *
 * Cross-file import resolution is NOT yet implemented. Inheritance walking
 * uses the same name-based scoping as the rest of the resolver.
 */

import Solidity

module NameResolution {
  // ==========================================================================
  // Scoping helpers
  // ==========================================================================

  /**
   * Gets the closest function-like ancestor of `n`: a `FunctionDefinition`,
   * `ModifierDefinition`, `ConstructorDefinition`, or `FallbackReceiveDefinition`.
   */
  AstNode enclosingFunctionLike(AstNode n) {
    result = n.getParent*() and
    isFunctionLike(result) and
    not exists(AstNode closer |
      closer = n.getParent+() and
      result = closer.getParent+() and
      closer != result and
      isFunctionLike(closer)
    )
  }

  private predicate isFunctionLike(AstNode n) {
    n instanceof FunctionDefinition or
    n instanceof ModifierDefinition or
    n instanceof ConstructorDefinition or
    n instanceof FallbackReceiveDefinition
  }

  /**
   * Gets the closest contract-like ancestor of `n`: a `ContractDeclaration`,
   * `InterfaceDeclaration`, or `LibraryDeclaration`.
   */
  AstNode enclosingContractLike(AstNode n) {
    result = n.getParent*() and
    isContractLike(result) and
    not exists(AstNode closer |
      closer = n.getParent+() and
      result = closer.getParent+() and
      closer != result and
      isContractLike(closer)
    )
  }

  private predicate isContractLike(AstNode n) {
    n instanceof ContractDeclaration or
    n instanceof InterfaceDeclaration or
    n instanceof LibraryDeclaration
  }

  /** Gets the source file containing `n`. */
  SourceFile enclosingFile(AstNode n) { result = n.getParent*() }

  // ==========================================================================
  // Inheritance
  // ==========================================================================

  /**
   * Gets a directly-inherited contract-like declaration of `c`, by name match
   * against any `ContractDeclaration` / `InterfaceDeclaration` /
   * `LibraryDeclaration` in the database.
   *
   * NOTE: Cross-file import resolution is not yet implemented, so this can
   * over-match on cousin-named contracts in unrelated files. Tighten in a
   * future revision by intersecting with `ImportDirective`-reachable files.
   */
  AstNode directParent(AstNode c) {
    isContractLike(c) and
    exists(InheritanceSpecifier is, Identifier ancestorName, string name |
      is.getParent*() = c and
      ancestorName = is.getAncestor() and
      name = ancestorName.getValue() and
      result != c and
      isContractLike(result) and
      contractLikeName(result) = name
    )
  }

  /** Gets a transitively-inherited contract-like declaration of `c`, including `c` itself. */
  AstNode parentOrSelf(AstNode c) {
    result = c and isContractLike(c)
    or
    result = directParent(parentOrSelf(c))
  }

  /** Gets the declared name of a `ContractDeclaration`/`InterfaceDeclaration`/`LibraryDeclaration`. */
  private string contractLikeName(AstNode c) {
    result = c.(ContractDeclaration).getName().(Identifier).getValue()
    or
    result = c.(InterfaceDeclaration).getName().(Identifier).getValue()
    or
    result = c.(LibraryDeclaration).getName().(Identifier).getValue()
  }

  // ==========================================================================
  // Reference contexts
  // ==========================================================================

  /**
   * Holds if `id` is a free identifier reference appearing in expression
   * position (the inner identifier of an `IdentifierExpression`). Excludes
   * declaration names and member-access properties.
   */
  predicate isFreeReference(Identifier id) {
    exists(IdentifierExpression ie | ie.getIdentifier() = id)
  }

  // ==========================================================================
  // Kind-specific resolvers
  // ==========================================================================

  /**
   * Gets a local variable or parameter that `id` may refer to, scoped to
   * `id`'s enclosing function-like.
   */
  AstNode resolveLocal(Identifier id) {
    isFreeReference(id) and
    exists(AstNode scope, string name |
      scope = enclosingFunctionLike(id) and
      name = id.getValue()
    |
      result.(VariableDeclaration).getName().getValue() = name and
      enclosingFunctionLike(result) = scope
      or
      result.(Parameter).getName().getValue() = name and
      result.getParent*() = scope and
      not result.getParent*() = scope.(FunctionDefinition).getBody() and
      not result.getParent*() = scope.(ModifierDefinition).getBody() and
      not result.getParent*() = scope.(ConstructorDefinition).getBody() and
      not result.getParent*() = scope.(FallbackReceiveDefinition).getBody()
    )
  }

  /**
   * Gets a state variable or contract-level constant that `id` may refer to,
   * scoped to `id`'s enclosing contract and its inheritance chain.
   */
  AstNode resolveStateVar(Identifier id) {
    isFreeReference(id) and
    exists(AstNode contract, string name |
      contract = enclosingContractLike(id) and
      name = id.getValue() and
      enclosingContractLike(result) = parentOrSelf(contract)
    |
      result.(StateVariableDeclaration).getName().(Identifier).getValue() = name
      or
      result.(ConstantVariableDeclaration).getName().(Identifier).getValue() = name
    )
  }

  /**
   * Gets a callable (function or modifier) that `id` may refer to, scoped to
   * `id`'s enclosing contract and its inheritance chain.
   *
   * Multiple results indicate function-overloading or ambiguous resolution.
   */
  AstNode resolveCallable(Identifier id) {
    isFreeReference(id) and
    exists(AstNode contract, string name |
      contract = enclosingContractLike(id) and
      name = id.getValue() and
      enclosingContractLike(result) = parentOrSelf(contract)
    |
      result.(FunctionDefinition).getName().getValue() = name
      or
      result.(ModifierDefinition).getName().(Identifier).getValue() = name
    )
  }

  /**
   * Gets a contract-like declaration (`ContractDeclaration`,
   * `InterfaceDeclaration`, `LibraryDeclaration`) or top-level free function
   * that `id` may refer to, scoped to the source file containing `id`.
   */
  AstNode resolveFileMember(Identifier id) {
    isFreeReference(id) and
    exists(SourceFile file, string name |
      file = enclosingFile(id) and
      name = id.getValue()
    |
      isContractLike(result) and
      result.getParent() = file and
      contractLikeName(result) = name
      or
      result.(FunctionDefinition).getParent() = file and
      result.(FunctionDefinition).getName().getValue() = name
    )
  }

  /**
   * Gets the contract-like declaration (`ContractDeclaration` /
   * `InterfaceDeclaration` / `LibraryDeclaration`) that an `InheritanceSpecifier`
   * resolves to. Reuses `directParent`'s contract-name matching.
   */
  AstNode resolveInheritanceTarget(InheritanceSpecifier is) {
    exists(AstNode child, string name |
      child = is.getParent*() and
      isContractLike(child) and
      name = is.getAncestor().(Identifier).getValue() and
      isContractLike(result) and
      result != child and
      contractLikeName(result) = name
    )
  }

  /**
   * Gets a callable that the given `CallExpression` may invoke. Resolves both
   * internal calls (`foo(x)`) and `this.foo(x)` style calls; for external calls
   * via member access on an unknown-typed receiver, falls back to name match
   * within the caller's enclosing contract chain.
   */
  AstNode resolveCallTarget(CallExpression ce) {
    // Internal call: function is a bare identifier.
    exists(IdentifierExpression callee | ce.getFunction() = callee |
      result = resolveCallable(callee.getIdentifier())
    )
    or
    // Method-style call (`obj.foo(x)` / `this.foo(x)`): match `foo` within the
    // caller's enclosing contract + inheritance.
    exists(MemberExpression callee, AstNode contract, string name |
      ce.getFunction() = callee and
      contract = enclosingContractLike(ce) and
      name = callee.getProperty().getValue() and
      enclosingContractLike(result) = parentOrSelf(contract) and
      (
        result.(FunctionDefinition).getName().getValue() = name
        or
        result.(ModifierDefinition).getName().(Identifier).getValue() = name
      )
    )
  }

  // ==========================================================================
  // Unified resolver
  // ==========================================================================

  /**
   * Gets a possible declaration that `id` refers to, following Solidity's
   * scoping rules: local first, then contract members, then file-level.
   *
   * Returns multiple results for overloaded functions, ambiguous
   * cross-contract names, etc. Returns no results for language built-ins
   * (`msg`, `abi`, `this`, ...) and unresolved references.
   */
  AstNode resolve(Identifier id) {
    result = resolveLocal(id)
    or
    not exists(resolveLocal(id)) and
    (
      result = resolveStateVar(id)
      or
      result = resolveCallable(id)
    )
    or
    not exists(resolveLocal(id)) and
    not exists(resolveStateVar(id)) and
    not exists(resolveCallable(id)) and
    result = resolveFileMember(id)
  }
}
