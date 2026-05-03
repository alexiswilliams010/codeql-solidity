/**
 * @name Arbitrary external call
 * @description Detects low-level external calls (`call` / `delegatecall`)
 *              where both the call target and the call data are tainted by
 *              user-controllable input. Such calls let an attacker invoke any
 *              function on any contract; the `delegatecall` variant additionally
 *              executes that code in the calling contract's storage context,
 *              giving the attacker full control over contract state.
 * @kind problem
 * @id solidity/arbitrary-external-call
 * @problem.severity error
 * @security-severity 9.0
 * @precision high
 * @tags security
 *       external/cwe/cwe-829
 *       external/cwe/cwe-94
 *       external/cwe/cwe-913
 */

import codeql.Solidity
import codeql.DataFlow
import codeql.TaintTracking

/**
 * A parameter of an externally-callable function — i.e. one declared `external`
 * or `public`. Values flowing in here are user-controllable.
 */
class ExternalParameter extends Parameter {
  ExternalParameter() {
    exists(FunctionDefinition fd, Visibility vis |
      fd.getAChild() = this and
      fd.getAChild() = vis and
      vis.getValue() in ["external", "public"]
    )
  }
}

/**
 * A low-level external call: `target.call(data)` or `target.delegatecall(data)`.
 * Excludes `staticcall` (read-only).
 *
 * The Solidity AST wraps the call's `function` slot in a generic `Expression`
 * node, so the actual `MemberExpression` is one `getAChild()` step away.
 */
class LowLevelCall extends CallExpression {
  MemberExpression callee;
  string method;

  LowLevelCall() {
    this.getFunction().getAChild() = callee and
    method = callee.getProperty().getValue() and
    method in ["call", "delegatecall"]
  }

  /** Gets `"call"` or `"delegatecall"`. */
  string getMethod() { result = method }

  /**
   * Gets the target address node (the receiver of the member access). May be
   * an `Expression` wrapper or a bare `Identifier` token, depending on whether
   * the parser wrapped the receiver.
   */
  AstNode getTarget() { result = callee.getObject() }

  /**
   * Gets the calldata node (the inner content of the first call argument). May
   * be an `Expression` wrapper or a bare `Identifier` token.
   */
  AstNode getCallData() { result = this.getArgument(0).getAChild() }
}

/** Taint flow from external parameters into the target expression of a low-level call. */
module ExternalToTargetConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node n) {
    n.(DataFlow::ParameterNode).getParameter() instanceof ExternalParameter
  }

  predicate isSink(DataFlow::Node n) {
    exists(LowLevelCall ll | n.asExpr() = ll.getTarget())
  }
}

/** Taint flow from external parameters into the calldata expression of a low-level call. */
module ExternalToCallDataConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node n) {
    n.(DataFlow::ParameterNode).getParameter() instanceof ExternalParameter
  }

  predicate isSink(DataFlow::Node n) {
    exists(LowLevelCall ll | n.asExpr() = ll.getCallData())
  }
}

module TargetFlow = TaintTracking::Global<ExternalToTargetConfig>;

module CallDataFlow = TaintTracking::Global<ExternalToCallDataConfig>;

from LowLevelCall ll, DataFlow::ParameterNode targetSrc, DataFlow::ParameterNode dataSrc
where
  TargetFlow::flow(targetSrc, DataFlow::valueNode(ll.getTarget())) and
  CallDataFlow::flow(dataSrc, DataFlow::valueNode(ll.getCallData()))
select ll,
  "Arbitrary " + ll.getMethod() +
    ": both the target $@ and the calldata $@ are user-controllable.", targetSrc.getParameter(),
  targetSrc.getParameter().toString(), dataSrc.getParameter(), dataSrc.getParameter().toString()
