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
 * The `Imports` sub-module exposes helpers for cross-file lookup
 * (`importedDeclaration`, `qualifiedImportedDeclaration`,
 * `topLevelDeclByName`, `staticTypeName`). These are used by the cross-file
 * disjuncts of `resolveCallTarget` and `directParent` (Phase 3).
 */

import Solidity
private import solidity.ast.internal.TreeSitter as TS
private import solidity.ast.internal.Ast as InternalAst

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
   * Holds if `id` is a free identifier reference appearing in a value-producing
   * expression position. This covers both the wrapped case (the inner identifier
   * of an `IdentifierExpression`) and the bare-token case where the Solidity
   * grammar emitted an `Identifier` directly in an expression slot — for
   * example the receiver of `target.call(data)` or the base of `arr[0]`.
   * Excludes declaration names and member-access properties.
   */
  predicate isFreeReference(Identifier id) {
    exists(IdentifierExpression ie | ie.getIdentifier() = id)
    or
    exists(MemberExpression me | me.getObject() = id)
    or
    exists(ArrayAccess aa | aa.getBase() = id)
    or
    exists(CallArgument ca | ca.getAChild() = id)
    or
    exists(AssignmentExpression ae | ae.getLeft() = id)
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

  // ==========================================================================
  // Cross-file lookup (Imports)
  // ==========================================================================

  /**
   * Helpers for resolving names across `import` directives. Backed by the
   * extractor's `solidity_import_resolution` relation (via
   * `ImportDirective.getResolvedFile()`).
   *
   * Solidity import semantics modeled here:
   *   - `import "X";`               — wildcard: all top-level decls of X are in
   *                                   scope under their original names.
   *   - `import {A, B} from "X";`   — selective: only A and B are in scope.
   *   - `import {A as Z} from "X";` — selective with rename. Pairing aliases
   *                                   to import names is a v1 limitation: this
   *                                   module currently exposes A under both A
   *                                   and Z (via separate disjuncts), without
   *                                   verifying the source-position pairing.
   *   - `import "X" as N;` /
   *     `import * as N from "X";`   — module alias: NOT in scope under bare
   *                                   names. Use `qualifiedImportedDeclaration`.
   *
   * Solidity does NOT transitively re-export. `importedDeclaration` is
   * non-transitive — only direct imports of `callerFile` are consulted.
   */
  module Imports {
    /**
     * Gets a top-level (file-scope) declaration in `f` whose declared name is
     * `name`. Covers contract-likes, free functions, top-level constants.
     */
    AstNode topLevelDeclByName(SourceFile f, string name) {
      result.getParent() = f and
      (
        result.(ContractDeclaration).getName().(Identifier).getValue() = name
        or
        result.(InterfaceDeclaration).getName().(Identifier).getValue() = name
        or
        result.(LibraryDeclaration).getName().(Identifier).getValue() = name
        or
        result.(FunctionDefinition).getName().getValue() = name
        or
        result.(ConstantVariableDeclaration).getName().(Identifier).getValue() = name
      )
    }

    /**
     * Gets the `SourceFile` AST root of the file `f`.
     */
    SourceFile sourceFileOf(File f) { result.getLocation().getFile() = f }

    /**
     * Holds if `imp` is a wildcard import — `import "X";` with no named imports
     * and no aliases. Brings every top-level decl of the imported file into
     * scope under its original name.
     */
    private predicate isWildcardImport(ImportDirective imp) {
      not exists(imp.getImportName(_)) and not exists(imp.getAlias(_))
    }

    /**
     * Holds if `imp` is a module-alias import — `import "X" as N;` or
     * `import * as N from "X";`. Has aliases but no named imports.
     * Bare `Foo` does NOT resolve through these; use `qualifiedImportedDeclaration`.
     */
    private predicate isModuleAliasImport(ImportDirective imp) {
      not exists(imp.getImportName(_)) and exists(imp.getAlias(_))
    }

    /**
     * Gets a top-level declaration in a file directly imported by `callerFile`,
     * brought into scope under the (possibly renamed) name `name`.
     *
     * Bare-identifier resolution should consult this. Module-alias imports
     * (`import * as N from "X"`) are NOT included — those are accessible only
     * via `qualifiedImportedDeclaration`.
     */
    AstNode importedDeclaration(SourceFile callerFile, string name) {
      exists(ImportDirective imp, SourceFile importedFile |
        enclosingFile(imp) = callerFile and
        importedFile = sourceFileOf(imp.getResolvedFile()) and
        result = topLevelDeclByName(importedFile, name)
      |
        // Wildcard: `name` matches the decl's declared name.
        isWildcardImport(imp)
        or
        // Selective: `name` matches one of the listed import names.
        // Note: aliases (`{A as Z}`) are not yet pairing-checked, so a renamed
        // import is reachable under its original name here. The `as`-rename
        // local name is also exposed via the next disjunct.
        name = imp.getImportName(_).getValue()
        or
        // Selective with alias: `name` is the local alias (`Z` in `{A as Z}`).
        // The decl's actual name is matched up via `topLevelDeclByName`, so
        // this over-approximates if the user mixes renamed and bare items —
        // see the v1-limitation note on the `Imports` module.
        exists(int i |
          name = imp.getAlias(i).getValue() and
          result = topLevelDeclByName(importedFile, imp.getImportName(i).getValue())
        )
      )
    }

    /**
     * Gets a top-level declaration accessible via a module-alias import
     * (`import * as N from "X";` or `import "X" as N;`). The `qualifier` is
     * the module's local name (`N`); `name` is the underlying decl's name.
     */
    AstNode qualifiedImportedDeclaration(SourceFile callerFile, string qualifier, string name) {
      exists(ImportDirective imp, SourceFile importedFile |
        enclosingFile(imp) = callerFile and
        importedFile = sourceFileOf(imp.getResolvedFile()) and
        isModuleAliasImport(imp) and
        qualifier = imp.getAlias(_).getValue() and
        result = topLevelDeclByName(importedFile, name)
      )
    }

    /**
     * Coarse static-type oracle: returns the leaf identifier(s) of `receiver`'s
     * declared type, when that type is a user-defined type (contract /
     * interface / library / struct / etc.). Used by the using-for and
     * external-call disjuncts of `resolveCallTarget` (Phase 3).
     *
     * `receiver` is `AstNode` rather than `Expression` because Solidity's
     * grammar emits both `IdentifierExpression` and bare `Identifier` token
     * receivers depending on context (e.g. the object of a `MemberExpression`
     * is often a bare token). Both shapes resolve through `identifierOf`.
     *
     * Three sources of type information:
     *   1. Identifier (wrapped or bare) referring to a typed local, parameter,
     *      or state variable — read the leaf identifier of the declaration's
     *      `TypeName`.
     *   2. `TypeCastExpression` (e.g. `IERC20(addr)`) — leaf identifier of
     *      the cast target type.
     *   3. `CallExpression` whose callee identifier resolves to a contract /
     *      interface / library — the contract's name (covers `IERC20(addr)`
     *      when parsed as a function call rather than a type cast).
     *
     * Multi-result on purpose for compound types (`mapping(K=>V)`); callers
     * should handle multiple type names. Returns no result when the receiver
     * type is not statically known.
     */
    string staticTypeName(AstNode receiver) {
      // Case 1: identifier (wrapped or bare) resolving to a typed declaration.
      exists(AstNode decl, Identifier id |
        id = identifierOf(receiver) and
        (decl = resolveLocal(id) or decl = resolveStateVar(id))
      |
        result = typeLeafIdentifier(declTypeNode(decl))
      )
      or
      // Case 2: explicit type cast — leaf identifier of the target type.
      result = typeLeafIdentifier(receiver.(TypeCastExpression).getType())
      or
      // Case 3: call whose callee is a contract-like name (`IERC20(addr)`
      // parsed as a function call). Allow one level of wrapper descent because
      // the grammar emits a generic `expression` node around primary
      // expressions in many positions (notably the receiver of a member call).
      exists(CallExpression ce, IdentifierExpression callee, AstNode contract, string calleeName |
        (receiver = ce or ce = astDirectChild(receiver)) and
        ce.getFunction() = callee and
        calleeName = callee.getIdentifier().getValue() and
        (
          contract = resolveFileMember(callee.getIdentifier())
          or
          contract = importedDeclaration(enclosingFile(ce), calleeName)
        ) and
        isContractLike(contract) and
        result = contractLikeName(contract)
      )
    }

    /**
     * Gets the underlying `Identifier` of `e`, whether `e` is a wrapped
     * `IdentifierExpression` or a bare `Identifier` token used in expression
     * position.
     */
    private Identifier identifierOf(AstNode e) {
      result = e.(IdentifierExpression).getIdentifier()
      or
      result = e.(Identifier)
    }

    /**
     * Gets the type-bearing AST node of a typed declaration. For each kind of
     * `decl` the relevant `getType()` returns the declaration's type subtree
     * (typically a `TypeName`).
     */
    private AstNode declTypeNode(AstNode decl) {
      result = decl.(VariableDeclaration).getType()
      or
      result = decl.(Parameter).getType()
      or
      result = decl.(StateVariableDeclaration).getType()
      or
      result = decl.(ConstantVariableDeclaration).getType()
    }

    /**
     * Gets the value of any `Identifier` inside `typeNode`. Walks the subtree
     * because a `TypeName` for `Foo[]` or `mapping(address => Foo)` nests its
     * leaf identifiers below intermediate grammar nodes.
     *
     * Uses the dbscheme's `solidity_ast_node_parent` relation directly because
     * several QL wrappers (notably `TypeName`) override `getAChild()` to
     * surface only named fields and elide unnamed children like
     * `user_defined_type` — those overrides hide the very identifier we need.
     */
    private string typeLeafIdentifier(AstNode typeNode) {
      exists(Identifier id |
        id = astDescendantOrSelf(typeNode) and
        result = id.getValue()
      )
    }

    /** Reflexive-transitive descendants of `n` over the raw AST parent table. */
    private AstNode astDescendantOrSelf(AstNode n) {
      result = n
      or
      exists(AstNode child |
        child = astDirectChild(n) and
        result = astDescendantOrSelf(child)
      )
    }

    /**
     * Direct AST child via the underlying tree-sitter `getAFieldOrChild()`.
     * The wrapper `getAChild()` predicates on several QL classes (e.g. `TypeName`)
     * elide unnamed children like `user_defined_type`; this dropdown sees them.
     */
    private AstNode astDirectChild(AstNode parent) {
      InternalAst::toTreeSitter(result) = InternalAst::toTreeSitter(parent).getAFieldOrChild()
    }
  }
}
