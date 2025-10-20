part of 'bill_list_bloc.dart';

abstract class BillListEvent extends Equatable {
  const BillListEvent();

  @override
  List<Object?> get props => [];
}

class LoadBillSummaries extends BillListEvent {
  final bool forceRefresh;
  final String? statusFilter; // 'open', 'completed', null = all
  final int? customerId;

  const LoadBillSummaries({this.forceRefresh = false, this.statusFilter, this.customerId});

  @override
  List<Object?> get props => [forceRefresh, statusFilter, customerId];
}
