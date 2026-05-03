/**
 * Implements the shared `codeql.dataflow.TaintTracking` library's `InputSig`
 * for Solidity, then instantiates `TaintFlowMake` to produce a usable
 * taint-tracking `Global<Config>` API.
 *
 * Adds taint-only flow steps on top of the value-flow already provided by
 * `DataFlowGraphImpl`: binary/unary/update expressions propagate taint, as
 * do `abi.encode*` / `abi.decode*` and the cryptographic hash builtins
 * (`keccak256`, `sha256`, `ripemd160`).
 */

private import codeql.Solidity
private import codeql.Locations
private import codeql.dataflow.TaintTracking as TaintTracking
private import codeql.dataflow.DataFlow as DF
private import DataFlowPublic as DataFlowPublic
private import DataFlowGraphImpl as DataFlowGraphImpl

private module SolidityDataFlow = DataFlowGraphImpl::SolidityDataFlow;

module SolidityTaintTracking implements
  TaintTracking::InputSig<Location, DataFlowGraphImpl::SolidityDataFlow>
{
  predicate defaultTaintSanitizer(SolidityDataFlow::Node node) { none() }

  predicate defaultAdditionalTaintStep(
    SolidityDataFlow::Node src, SolidityDataFlow::Node sink, string model
  ) {
    // Binary expressions: both operands → result.
    exists(BinaryExpression be |
      (
        src = DataFlowPublic::exprNode(be.getLeft()) or
        src = DataFlowPublic::exprNode(be.getRight())
      ) and
      sink = DataFlowPublic::exprNode(be) and
      model = "binop"
    )
    or
    // Unary expressions: argument → result.
    exists(UnaryExpression ue |
      src = DataFlowPublic::exprNode(ue.getArgument()) and
      sink = DataFlowPublic::exprNode(ue) and
      model = "unop"
    )
    or
    // Update expressions (`x++`, `--x`): argument → result.
    exists(UpdateExpression ue |
      src = DataFlowPublic::exprNode(ue.getArgument()) and
      sink = DataFlowPublic::exprNode(ue) and
      model = "update"
    )
    or
    // `abi.encode*` / `abi.decode*` and similar built-in transforms:
    // every argument flows to the call result.
    exists(CallExpression ce, CallArgument ca, Expression inner |
      isAbiCall(ce) and
      ce.getArgument(_) = ca and
      ca.getAChild() = inner and
      src = DataFlowPublic::exprNode(inner) and
      sink = DataFlowPublic::exprNode(ce) and
      model = "abi"
    )
    or
    // Cryptographic hash built-ins: `keccak256`, `sha256`, `ripemd160`.
    // Argument → result.
    exists(CallExpression ce, CallArgument ca, Expression inner |
      isCryptoHashCall(ce) and
      ce.getArgument(_) = ca and
      ca.getAChild() = inner and
      src = DataFlowPublic::exprNode(inner) and
      sink = DataFlowPublic::exprNode(ce) and
      model = "crypto"
    )
  }

  bindingset[node]
  predicate defaultImplicitTaintRead(
    SolidityDataFlow::Node node, SolidityDataFlow::ContentSet c
  ) {
    none()
  }

  predicate speculativeTaintStep(SolidityDataFlow::Node src, SolidityDataFlow::Node sink) {
    none()
  }
}

/** Holds if `ce` is an `abi.encode*` / `abi.decode*` call. */
private predicate isAbiCall(CallExpression ce) {
  exists(MemberExpression callee, IdentifierExpression obj |
    ce.getFunction() = callee and
    callee.getObject() = obj and
    obj.getIdentifier().getValue() = "abi"
  )
}

/** Holds if `ce` is a call to one of `keccak256`, `sha256`, or `ripemd160`. */
private predicate isCryptoHashCall(CallExpression ce) {
  exists(IdentifierExpression callee |
    ce.getFunction() = callee and
    callee.getIdentifier().getValue() in ["keccak256", "sha256", "ripemd160"]
  )
}

module TaintFlow =
  TaintTracking::TaintFlowMake<Location, DataFlowGraphImpl::SolidityDataFlow,
    SolidityTaintTracking>;
