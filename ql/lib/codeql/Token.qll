private import solidity.ast.internal.Ast
private import Ast
private import Locations

/* Derivations of the SolToken class instantiated under TAstNode are defined here */

class ReservedWord extends TReservedWord, AstNode {
  private SolToken node;

  ReservedWord() { this = TReservedWord(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class AnySourceType extends TAnySourceType, AstNode {
  private SolToken node;

  AnySourceType() { this = TAnySourceType(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class BreakStatement extends TBreakStatement, AstNode {
  private SolToken node;

  BreakStatement() { this = TBreakStatement(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class ContinueStatement extends TContinueStatement, AstNode {
  private SolToken node;

  ContinueStatement() { this = TContinueStatement(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class DecimalNumber extends TDecimalNumber, AstNode {
  private SolToken node;

  DecimalNumber() { this = TDecimalNumber(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class EnumValue extends TEnumValue, AstNode {
  private SolToken node;

  EnumValue() { this = TEnumValue(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class False extends TFalse, AstNode {
  private SolToken node;

  False() { this = TFalse(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class HexNumber extends THexNumber, AstNode {
  private SolToken node;

  HexNumber() { this = THexNumber(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class HexStringLiteral extends THexStringLiteral, AstNode {
  private SolToken node;

  HexStringLiteral() { this = THexStringLiteral(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class Identifier extends TIdentifier, AstNode {
  private SolToken node;

  Identifier() { this = TIdentifier(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class Immutable extends TImmutable, AstNode {
  private SolToken node;

  Immutable() { this = TImmutable(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class NumberUnit extends TNumberUnit, AstNode {
  private SolToken node;

  NumberUnit() { this = TNumberUnit(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class PragmaValue extends TPragmaValue, AstNode {
  private SolToken node;

  PragmaValue() { this = TPragmaValue(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class PrimitiveType extends TPrimitiveType, AstNode {
  private SolToken node;

  PrimitiveType() { this = TPrimitiveType(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class SolidityVersion extends TSolidityVersion, AstNode {
  private SolToken node;

  SolidityVersion() { this = TSolidityVersion(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class StateLocation extends TStateLocation, AstNode {
  private SolToken node;

  StateLocation() { this = TStateLocation(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class StateMutability extends TStateMutability, AstNode {
  private SolToken node;

  StateMutability() { this = TStateMutability(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class String extends TString, AstNode {
  private SolToken node;

  String() { this = TString(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class True extends TTrue, AstNode {
  private SolToken node;

  True() { this = TTrue(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class Unchecked extends TUnchecked, AstNode {
  private SolToken node;

  Unchecked() { this = TUnchecked(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class UnicodeStringLiteral extends TUnicodeStringLiteral, AstNode {
  private SolToken node;

  UnicodeStringLiteral() { this = TUnicodeStringLiteral(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class UserDefinableOperator extends TUserDefinableOperator, AstNode {
  private SolToken node;

  UserDefinableOperator() { this = TUserDefinableOperator(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class Virtual extends TVirtual, AstNode {
  private SolToken node;

  Virtual() { this = TVirtual(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class Visibility extends TVisibility, AstNode {
  private SolToken node;

  Visibility() { this = TVisibility(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulBoolean extends TYulBoolean, AstNode {
  private SolToken node;

  YulBoolean() { this = TYulBoolean(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulBreak extends TYulBreak, AstNode {
  private SolToken node;

  YulBreak() { this = TYulBreak(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulContinue extends TYulContinue, AstNode {
  private SolToken node;

  YulContinue() { this = TYulContinue(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulDecimalNumber extends TYulDecimalNumber, AstNode {
  private SolToken node;

  YulDecimalNumber() { this = TYulDecimalNumber(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulEvmBuiltin extends TYulEvmBuiltin, AstNode {
  private SolToken node;

  YulEvmBuiltin() { this = TYulEvmBuiltin(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulHexNumber extends TYulHexNumber, AstNode {
  private SolToken node;

  YulHexNumber() { this = TYulHexNumber(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulHexStringLiteral extends TYulHexStringLiteral, AstNode {
  private SolToken node;

  YulHexStringLiteral() { this = TYulHexStringLiteral(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulLeave extends TYulLeave, AstNode {
  private SolToken node;

  YulLeave() { this = TYulLeave(node) }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}
