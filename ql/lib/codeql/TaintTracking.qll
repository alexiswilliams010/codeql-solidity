/**
 * Public taint-tracking library for Solidity.
 *
 * Importing this file makes the `TaintTracking` module available, with the
 * same `Global<Config>` / `GlobalWithState<Config>` API as `DataFlow`, but
 * with taint-aware flow (binary expressions, abi.encode/decode, hash built-ins
 * propagate taint in addition to ordinary value flow).
 *
 * The `Config` interface is `DataFlow::ConfigSig` — there is no separate
 * taint-config interface. Per-query sanitizers go in `Config::isBarrier`;
 * additional flow steps go in `Config::isAdditionalFlowStep`.
 *
 * Usage:
 * ```
 * import codeql.Solidity
 * import codeql.DataFlow
 * import codeql.TaintTracking
 *
 * module MyTaintConfig implements DataFlow::ConfigSig {
 *   predicate isSource(DataFlow::Node n) { ... }
 *   predicate isSink(DataFlow::Node n) { ... }
 * }
 * module MyFlow = TaintTracking::Global<MyTaintConfig>;
 * ```
 */

module TaintTracking {
  import dataflow.internal.DataFlowPublic
  import dataflow.internal.TaintTrackingImpl::TaintFlow
}
