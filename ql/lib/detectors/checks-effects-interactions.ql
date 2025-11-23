/*
 * @name Checks-Effects-Interactions
 * @description Detects code that does not follow CEI, where state variables are written after external calls
 * @kind problem
 * @problem.severity warning
 * @id solidity/checks-effects-interactions
 */

import codeql.Solidity
import codeql.Cfg

/**
 * Holds if the assignment expression writes to a state variable.
 * This is done by matching the identifier name on the left-hand side
 * with a StateVariableDeclaration in the same contract.
 */
predicate isStateWrite(AssignmentExpression expr) {
  exists(StateVariableDeclaration decl, Identifier leftId, Identifier declId |
    // Get the identifier from the left side of the assignment
    // Note: getLeft() returns an Expression wrapper, the Identifier is its child
    leftId = expr.getLeft().getAChild() and
    // Get the identifier from the state variable declaration
    declId = decl.getName() and
    // Match by name
    leftId.getValue() = declId.getValue() and
    // Ensure they're in the same contract (same file and within parent chain)
    leftId.getFile() = decl.getFile()
  )
}

/**
 * This handles assignments to struct members or contract state via member expressions.
 */
predicate isStateWriteViaMember(AssignmentExpression expr) {
  exists(StateVariableDeclaration decl, MemberExpression memberExpr, Identifier propId, Identifier declId |
    // Get the member expression from the left side
    memberExpr = expr.getLeft() and
    // Get the property being assigned
    propId = memberExpr.getProperty() and
    // Get the identifier from the state variable declaration
    declId = decl.getName() and
    // Match by name
    propId.getValue() = declId.getValue() and
    // Ensure they're in the same file
    memberExpr.getFile() = decl.getFile()
  )
}

/**
 * Comprehensive predicate that checks both direct and member-based state writes
 */
predicate isAnyStateWrite(AssignmentExpression expr) {
  isStateWrite(expr) or isStateWriteViaMember(expr)
}

/**
 * Holds if the call expression is likely an external call.
 * This includes:
 * - Low-level calls: address.call(), delegatecall(), etc.
 * - Interface calls: IToken(addr).transfer()
 * - Contract instance calls: someContract.method()
 */
predicate isExternalCall(CallExpression call) {
  // Any call that uses member expression syntax (obj.method())
  // Note: getFunction() returns an Expression wrapper, the MemberExpression is its child
  call.getFunction().getAChild() instanceof MemberExpression
  or
  // Calls on type casts, e.g., IToken(addr).transfer() or ContractType(addr).method()
  // The function is accessed via a member expression on a type cast
  exists(TypeCastExpression typeCast |
    typeCast.getParent+() = call.getFunction().getAChild()
  )
  or
  isLowLevelExternalCall(call)
}

/**
 * Detects low-level external calls like .call(), .delegatecall(), etc.
 */
predicate isLowLevelExternalCall(CallExpression call) {
  exists(MemberExpression memberExpr, Identifier method |
    memberExpr = call.getFunction().getAChild() and
    method = memberExpr.getProperty() and
    (
      method.getValue() = "call" or
      method.getValue() = "delegatecall"
    )
  )
}

from AssignmentExpression stateWrite, CallExpression externalCall
where
  // The assignment writes to a state variable
  isAnyStateWrite(stateWrite) and
  // The call is an external call
  isExternalCall(externalCall) and
  // Check if the external call happens before the state write in the control flow
  exists(Node callStmt, Node writeStmt, FunctionDefinition func |
    // Expressions are wrapped: AssignmentExpression -> Expression -> ExpressionStatement
    externalCall.getParent().getParent() = callStmt.getAstNode() and
    stateWrite.getParent().getParent() = writeStmt.getAstNode() and
    // Both must be in the same function to avoid cross-function matches
    func = callStmt.getScope() and
    func = writeStmt.getScope() and
    // The call statement reaches the write statement in control flow
    callStmt.getASuccessor+() = writeStmt
  )
select stateWrite, "State variable modified after external call at line " +
  externalCall.getLocation().getStartLine() + ", violating Checks-Effects-Interactions pattern"