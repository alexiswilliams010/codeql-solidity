/**
 * @name Unused imports in Solidity
 * @description Finds import statements that are not used in the file
 * @kind problem
 * @problem.severity warning
 * @id solidity/unused-imports
 */

import codeql.Solidity

/**
 * Checks if a file is in the src/ directory (for Foundry projects)
 * Excludes any paths that contain lib/ to avoid library dependencies
 */
predicate isInSrcDirectory(File file) {
  (file.getRelativePath().matches("src/%") or
   file.getAbsolutePath().matches("%/src/%")) and
  not file.getRelativePath().matches("%lib/%") and
  not file.getAbsolutePath().matches("%/lib/%")
}

/**
 * Gets the imported name from an import directive
 */
string getImportedName(ImportDirective imp) {
  // For aliased imports (import {A as B} or import * as Name), use the alias
  result = imp.getAlias(_).getValue()
  or
  // For named imports without alias (import {A}), use the import name
  (not exists(imp.getAlias(_)) and 
   exists(int i | result = imp.getImportName(i).getValue()))
}

/**
 * Gets all identifiers used in expressions within the same file as the import
 */
predicate isIdentifierUsedInFile(ImportDirective imp, string name) {
  exists(Identifier id | 
    id.getFile() = imp.getFile() and
    id.getValue() = name and
    // Exclude identifiers that are part of the import directive itself
    not id.getParent*() = imp
  )
}

/**
 * Checks if an import is used through inheritance
 */
predicate isUsedInInheritance(ImportDirective imp, string importName) {
  exists(InheritanceSpecifier inh |
    inh.getFile() = imp.getFile() and
    exists(Identifier id | 
      id = inh.getAncestor().getAChild() and
      id.getValue() = importName
    )
  )
}

/**
 * Checks if an import is used in using directives
 */
predicate isUsedInUsingDirective(ImportDirective imp, string importName) {
  exists(UsingDirective using |
    using.getFile() = imp.getFile() and
    exists(Identifier id |
      id = using.getSource().getAChild() and
      id.getValue() = importName
    )
  )
}

/**
 * Checks if an import is used in type annotations
 */
predicate isUsedInTypeAnnotation(ImportDirective imp, string importName) {
  exists(TypeName typeName |
    typeName.getFile() = imp.getFile() and
    exists(Identifier id | 
      id = typeName.getAChild() and
      id.getValue() = importName
    )
  )
}

/**
 * Checks if an import is used in variable declarations
 */
predicate isUsedInVariableContext(ImportDirective imp, string importName) {
  exists(VariableDeclaration varDecl |
    varDecl.getFile() = imp.getFile() and
    exists(Identifier id |
      id = varDecl.getAChild() and
      id.getValue() = importName
    )
  )
  or
  exists(StateVariableDeclaration stateVar |
    stateVar.getFile() = imp.getFile() and
    exists(Identifier id |
      id = stateVar.getAChild() and
      id.getValue() = importName
    )
  )
}

/**
 * Checks if an import is used in new expressions
 */
predicate isUsedInNewExpression(ImportDirective imp, string importName) {
  exists(NewExpression newExpr |
    newExpr.getFile() = imp.getFile() and
    exists(Identifier id |
      id = newExpr.getAChild() and
      id.getValue() = importName
    )
  )
}

/**
 * Checks if an import is used in event definitions or emit statements
 */
predicate isUsedInEvents(ImportDirective imp, string importName) {
  exists(EmitStatement emit |
    emit.getFile() = imp.getFile() and
    exists(Identifier id |
      id = emit.getAChild() and
      id.getValue() = importName
    )
  )
}

/**
 * Checks if an import is used in error handling
 */
predicate isUsedInErrorHandling(ImportDirective imp, string importName) {
  exists(RevertStatement revert |
    revert.getFile() = imp.getFile() and
    exists(Identifier id |
      id = revert.getAChild() and
      id.getValue() = importName
    )
  )
}

/**
 * Optimized: check if import is used with early termination
 */
predicate isImportUsed(ImportDirective imp, string importName) {
  // Most common case first - direct identifier usage
  isIdentifierUsedInFile(imp, importName)
  or
  // Then check other specific contexts
  isUsedInInheritance(imp, importName)
  or
  isUsedInTypeAnnotation(imp, importName)
  or
  isUsedInVariableContext(imp, importName)
  or
  isUsedInUsingDirective(imp, importName)
  or
  isUsedInNewExpression(imp, importName)
  or
  isUsedInEvents(imp, importName)
  or
  isUsedInErrorHandling(imp, importName)
}

// Find all unused imports - optimized to only check src/ directory
from ImportDirective imp, string importName
where 
  // Only check files in src/ directory
  isInSrcDirectory(imp.getFile()) and
  importName = getImportedName(imp) and
  importName != "" and
  not isImportUsed(imp, importName)
 select imp, "Unused import: '" + importName + "' from " + imp.getSource().getValue() + " in " + imp.getFile().getBaseName()