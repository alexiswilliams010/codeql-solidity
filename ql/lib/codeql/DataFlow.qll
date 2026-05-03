/**
 * Public dataflow library for Solidity.
 *
 * Importing this file makes the `DataFlow` module available, exposing:
 * - The dataflow `Node` hierarchy: `Node`, `ExprNode`, `ParameterNode`,
 *   `ArgumentNode`, `ReturnNode`, `OutNode`, `PostUpdateNode`, `CastNode`.
 * - Top-level helpers `exprNode(Expression)` and `parameterNode(Parameter)`
 *   for going AST → Node.
 * - The `DataFlowMake` outputs: `Global<Config>`, `GlobalWithState<Config>`,
 *   `ConfigSig`, `StateConfigSig`, `PathGraph`, etc.
 *
 * AST ↔ DataFlow cast cheatsheet:
 *
 * | Direction                 | How                                    |
 * | ------------------------- | -------------------------------------- |
 * | `Expression` → `Node`     | `DataFlow::exprNode(e)`                |
 * | `Parameter` → `Node`      | `DataFlow::parameterNode(p)`           |
 * | `Node` → `Expression`     | `n.asExpr()`                           |
 * | `Node` → `Parameter`      | `n.asParameter()`                      |
 * | type test                 | `n instanceof DataFlow::ParameterNode` |
 * | inner AST kind            | `n.asExpr() instanceof CallExpression` |
 *
 * Usage:
 * ```
 * import codeql.Solidity
 * import codeql.DataFlow
 *
 * module MyConfig implements DataFlow::ConfigSig {
 *   predicate isSource(DataFlow::Node n) { ... }
 *   predicate isSink(DataFlow::Node n) { ... }
 * }
 * module MyFlow = DataFlow::Global<MyConfig>;
 *
 * from DataFlow::Node src, DataFlow::Node snk
 * where MyFlow::flow(src, snk)
 * select snk, "tainted by $@", src, src.toString()
 * ```
 */

module DataFlow {
  import dataflow.internal.DataFlowPublic
  import dataflow.internal.DataFlowGraphImpl::DataFlow
}
