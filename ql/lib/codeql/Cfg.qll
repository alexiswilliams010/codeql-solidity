import controlflow.internal.ControlFlowGraphImpl as CfgInternal
import CfgInternal::Completion
import CfgInternal::CfgScope
import CfgInternal::CfgImpl

/**
 * Interprocedural CFG edges (additive, opt-in). The intra-procedural CFG
 * exposed above is unchanged; these are auxiliary predicates that detectors
 * can OR into their own walks when they want cross-function reachability.
 *
 * See `controlflow.internal.ControlFlowGraphImpl` for the full doc.
 */
predicate interproceduralCallEdge = CfgInternal::interproceduralCallEdge/2;

predicate interproceduralReturnEdge = CfgInternal::interproceduralReturnEdge/2;

predicate interproceduralSuccessor = CfgInternal::interproceduralSuccessor/2;