/**
 * @name Delegatecall in Loop
 * @description Detects delegatecall in a loop within a payable function - delegatecall always sets msg.value equal to the value of the function call
 * @kind problem
 * @id solidity/delegatecall-in-loop
 * @problem.severity warning
 * @precision high
 * @tags security
 *       correctness
 */

import codeql.Solidity

predicate isDelegatecall(AstNode node) {
  // Check if any descendant (including self) is a "delegatecall" identifier using transitive closure
  exists(Identifier identifier |
    identifier = node.getAChild*() and
    identifier.toString() = "delegatecall"
  )
}

predicate isInLoop(AstNode node) {
  // Check if any ancestor (including self) is a loop using transitive closure
  exists(AstNode ancestor | 
    ancestor = node.getParent*() and
    (ancestor instanceof ForStatement or
     ancestor instanceof WhileStatement or 
     ancestor instanceof DoWhileStatement)
  )
}

predicate isPayable(AstNode node) {
  // Check if any ancestor (including self) is a payable function using transitive closure
  exists(FunctionDefinition func, StateMutability modifier | 
    func = node.getParent*() and
    modifier = func.getAChild*() and
    modifier.getValue() = "payable"
  )
}

from CallExpression call
where isDelegatecall(call.getFunction()) and isInLoop(call) and isPayable(call)
select 
  call,
  "Delegatecall in loop within payable function detected at line " + call.getLocation().getStartLine().toString() + 
  " in " + call.getLocation().getFile().getBaseName()

  