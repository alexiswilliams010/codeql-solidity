/**
 * @name Divide Before Multiply
 * @description Detects expressions where division occurs before multiplication, which can lead to precision loss
 * @kind problem
 * @id solidity/divide-before-multiply
 * @problem.severity warning
 * @precision medium
 * @tags correctness
 *       precision
 */

import codeql.Ast
import codeql.Expression

/**
 * Holds if the given expression has a division operation as a descendant.
 * This predicate recursively traverses the AST to find division operations.
 */
predicate hasDivisionDescendant(AstNode node) {
  exists(BinaryExpression divExpr |
    divExpr.getOperator() = "/" and
    divExpr = node
  )
  or
  exists(AstNode child |
    child = node.getAChild() and
    hasDivisionDescendant(child)
  )
}

from BinaryExpression expr
where 
  expr.getOperator() = "*" and
  hasDivisionDescendant(expr.getLeft())
select 
  expr, 
  "Division before multiplication can lead to precision loss at line " + 
  expr.getLocation().getStartLine().toString() + 
  " in " + expr.getLocation().getFile().getBaseName()
