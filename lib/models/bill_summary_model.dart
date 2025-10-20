class BillSummary {
  final int cartId;
  final int customerId;
  final DateTime createdAt;
  final double itemTotal;
  final double chargesTotal;
  final double receiveAmount;
  final double pendingAmount;
  final double totalAmount;
  final int? billNumber;
  final String status;

  const BillSummary({
    required this.cartId,
    required this.customerId,
    required this.createdAt,
    required this.itemTotal,
    required this.chargesTotal,
    required this.receiveAmount,
    required this.pendingAmount,
    required this.totalAmount,
    this.billNumber,
    this.status = 'open',
  });

  double get totalCollected => receiveAmount;

  bool get isPending => pendingAmount > 0;

  bool get isOpen => status.toLowerCase() == 'open';

  bool get isCompleted => status.toLowerCase() == 'completed';
}
