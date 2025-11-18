private import solidity.ast.internal.Ast
private import Ast
private import Locations

/* Derivations of the SolToken class instantiated under TAstNode are defined here */

class ReservedWord extends TReservedWord, AstNode, AstNodeImpl {
  private SolToken node;

  ReservedWord() { this = TReservedWord(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class AnySourceType extends TAnySourceType, AstNode, AstNodeImpl {
  private SolToken node;

  AnySourceType() { this = TAnySourceType(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class DecimalNumber extends TDecimalNumber, Literal, AstNode, AstNodeImpl {
  private SolToken node;

  DecimalNumber() { this = TDecimalNumber(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class EnumValue extends TEnumValue, AstNode, AstNodeImpl {
  private SolToken node;

  EnumValue() { this = TEnumValue(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class False extends TFalse, AstNode, AstNodeImpl {
  private SolToken node;

  False() { this = TFalse(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class HexNumber extends THexNumber, AstNode, AstNodeImpl {
  private SolToken node;

  HexNumber() { this = THexNumber(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class HexStringLiteral extends THexStringLiteral, Literal, AstNode, AstNodeImpl {
  private SolToken node;

  HexStringLiteral() { this = THexStringLiteral(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class Identifier extends TIdentifier, AstNode, AstNodeImpl {
  private SolToken node;

  Identifier() { this = TIdentifier(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class Immutable extends TImmutable, AstNode, AstNodeImpl {
  private SolToken node;

  Immutable() { this = TImmutable(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class NumberUnit extends TNumberUnit, AstNode, AstNodeImpl {
  private SolToken node;

  NumberUnit() { this = TNumberUnit(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class PragmaValue extends TPragmaValue, AstNode, AstNodeImpl {
  private SolToken node;

  PragmaValue() { this = TPragmaValue(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class PrimitiveType extends TPrimitiveType, AstNode, AstNodeImpl {
  private SolToken node;

  PrimitiveType() { this = TPrimitiveType(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class SolidityVersion extends TSolidityVersion, AstNode, AstNodeImpl {
  private SolToken node;

  SolidityVersion() { this = TSolidityVersion(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class StateLocation extends TStateLocation, AstNode, AstNodeImpl {
  private SolToken node;

  StateLocation() { this = TStateLocation(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class StateMutability extends TStateMutability, AstNode, AstNodeImpl {
  private SolToken node;

  StateMutability() { this = TStateMutability(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class String extends TString, AstNode, AstNodeImpl {
  private SolToken node;

  String() { this = TString(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class True extends TTrue, AstNode, AstNodeImpl {
  private SolToken node;

  True() { this = TTrue(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class Unchecked extends TUnchecked, AstNode, AstNodeImpl {
  private SolToken node;

  Unchecked() { this = TUnchecked(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class UnicodeStringLiteral extends TUnicodeStringLiteral, Literal, AstNode, AstNodeImpl {
  private SolToken node;

  UnicodeStringLiteral() { this = TUnicodeStringLiteral(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class UserDefinableOperator extends TUserDefinableOperator, AstNode, AstNodeImpl {
  private SolToken node;

  UserDefinableOperator() { this = TUserDefinableOperator(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class Virtual extends TVirtual, AstNode, AstNodeImpl {
  private SolToken node;

  Virtual() { this = TVirtual(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class Visibility extends TVisibility, AstNode, AstNodeImpl {
  private SolToken node;

  Visibility() { this = TVisibility(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulBoolean extends TYulBoolean, YulLiteral, AstNode, AstNodeImpl {
  private SolToken node;

  YulBoolean() { this = TYulBoolean(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulBreak extends TYulBreak, AstNode, AstNodeImpl {
  private SolToken node;

  YulBreak() { this = TYulBreak(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulContinue extends TYulContinue, AstNode, AstNodeImpl {
  private SolToken node;

  YulContinue() { this = TYulContinue(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulDecimalNumber extends TYulDecimalNumber, YulLiteral, AstNode, AstNodeImpl {
  private SolToken node;

  YulDecimalNumber() { this = TYulDecimalNumber(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulEvmBuiltin extends TYulEvmBuiltin, AstNode, AstNodeImpl {
  private SolToken node;

  YulEvmBuiltin() { this = TYulEvmBuiltin(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulHexNumber extends TYulHexNumber, YulLiteral, AstNode, AstNodeImpl {
  private SolToken node;

  YulHexNumber() { this = TYulHexNumber(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulHexStringLiteral extends TYulHexStringLiteral, YulLiteral, AstNode, AstNodeImpl {
  private SolToken node;

  YulHexStringLiteral() { this = TYulHexStringLiteral(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}

class YulLeave extends TYulLeave, AstNode, AstNodeImpl {
  private SolToken node;

  YulLeave() { this = TYulLeave(node) }

  override AstNode getParent() { toTreeSitter(result) = toToken(node).getParent() }

  override AstNode getAChild() { toTreeSitter(result) = toToken(node).getAFieldOrChild() }

  override string toString() { result = toToken(node).toString() }

  string getValue() { result = toToken(node).getValue() }

  override string getAPrimaryQlClass() { result = toToken(node).getAPrimaryQlClass() }

  override Location getLocation() { result = toToken(node).getLocation() }
}
