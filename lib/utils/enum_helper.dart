enum PartyTypes {
  customer("customer"),
  supplier("supplier");

  final String value;
  const PartyTypes(this.value);
}

enum PaymentType {
  debit("debit"),
  credit("credit"),
  none("none");

  final String value;
  const PaymentType(this.value);
}

enum PaymentMode {
  cash("cash"),
  online("online");

  final String value;
  const PaymentMode(this.value);
}

enum PaymentStatus {
  paid("paid"),
  pending("pending");

  final String value;
  const PaymentStatus(this.value);
}