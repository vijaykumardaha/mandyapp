part of 'bill_list_bloc.dart';

abstract class BillListEvent extends Equatable {
  const BillListEvent();

  @override
  List<Object?> get props => [];
}

class LoadBillSummaries extends BillListEvent {
  final bool forceRefresh;
  final int? customerId;

  const LoadBillSummaries({this.forceRefresh = false, this.customerId});

  @override
  List<Object?> get props => [forceRefresh, customerId];
}

class DeleteBillRequested extends BillListEvent {
  final BillSummary bill;

  const DeleteBillRequested(this.bill);

  @override
  List<Object?> get props => [bill];
}
