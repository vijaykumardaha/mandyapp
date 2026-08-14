import 'package:krishimandi/utils/constants.dart';

class OtherTransaction {
  int? id;
  int? mandiId;
  String transactionNote;
  String transactionType;
  double transactionAmount;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;

  OtherTransaction({
    this.id,
    this.mandiId,
    required this.transactionNote,
    this.transactionType = 'debit',
    this.transactionAmount = 0,
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
  });

  bool get isDebit => transactionType == 'debit';
  bool get isCredit => transactionType == 'credit';

  Map<String, dynamic> toJson() {
    return {
      DbColumns.id: id,
      DbColumns.mandiId: mandiId,
      DbColumns.transactionNote: transactionNote,
      DbColumns.transactionType: transactionType,
      DbColumns.transactionAmount: transactionAmount,
      DbColumns.updatedAt: updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      DbColumns.isDeleted: isDeleted ?? 0,
      DbColumns.syncStatus: syncStatus ?? 0,
    };
  }

  factory OtherTransaction.fromJson(Map<String, dynamic> json) {
    return OtherTransaction(
      id: json[DbColumns.id] as int?,
      mandiId: json[DbColumns.mandiId] as int?,
      transactionNote: json[DbColumns.transactionNote] as String,
      transactionType: (json[DbColumns.transactionType] as String?) ?? 'debit',
      transactionAmount:
          (json[DbColumns.transactionAmount] as num?)?.toDouble() ?? 0,
      updatedAt: json[DbColumns.updatedAt] as int?,
      isDeleted: json[DbColumns.isDeleted] as int? ?? 0,
      syncStatus: json[DbColumns.syncStatus] as int? ?? 0,
    );
  }
}
