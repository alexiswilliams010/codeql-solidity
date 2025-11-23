/*
 * @name Checks-Effects-Interactions Pattern Violation
 * @description Detects state writes after external calls that transfer ETH (potential reentrancy vulnerability)
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
 * Holds if the call expression has a msg.value (transfers ETH).
 * This checks for the {value: ...} syntax in call options.
 */
predicate hasValue(CallExpression call) {
  // Look for CallArgument that contains a struct field assignment for "value"
  exists(AstNode arg |
    arg = call.getAChild() and
    exists(Identifier fieldName |
      fieldName = arg.getAChild+() and
      fieldName.getValue() = "value"
    )
  )
}

/**
 * Holds if the call expression is a state-changing external call.
 * We focus on calls we know transfer value:
 * - Low-level calls with value: addr.call{value: amount}()
 * - Interface/contract calls with value: IToken(addr).method{value: amount}()
 * 
 * Note: We exclude transfer/send
 */
predicate isStateChangingExternalCall(CallExpression call) {
  // Calls with {value: ...} are wrapped in a StructExpression
  // The actual .call or .method is in the StructExpression's type (as an Expression wrapper)
  // Structure: CallExpression -> Expression -> StructExpression -> Expression (type) -> MemberExpression
  exists(StructExpression structExpr, MemberExpression memberExpr, Identifier method |
    structExpr = call.getFunction().getAChild() and
    memberExpr = structExpr.getType().getAChild() and
    method = memberExpr.getProperty() and
    method.getValue() = "call" and
    hasValue(call)
  )
  or
  // Also catch any other call with value (interface calls with value)
  exists(StructExpression structExpr, MemberExpression memberExpr |
    structExpr = call.getFunction().getAChild() and
    memberExpr = structExpr.getType().getAChild() and
    hasValue(call)
  )
}

from AssignmentExpression stateWrite, CallExpression externalCall
where
  // The assignment writes to a state variable
  isAnyStateWrite(stateWrite) and
  // The call is a state-changing external call (transfers value or can modify state)
  isStateChangingExternalCall(externalCall) and
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
select stateWrite, "State variable modified after external call with value transfer at line " +
  externalCall.getLocation().getStartLine() + " (reentrancy risk - violates Checks-Effects-Interactions pattern)"