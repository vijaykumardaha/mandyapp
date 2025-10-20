part of 'bill_list_bloc.dart';

abstract class BillListState extends Equatable {
  const BillListState();

  @override
  List<Object?> get props => [];
}

class BillListInitial extends BillListState {}

class BillListLoading extends BillListState {}

class BillListEmpty extends BillListState {}

class BillListError extends BillListState {
  final String message;

  const BillListError(this.message);

  @override
  List<Object?> get props => [message];
}

class BillListLoaded extends BillListState {
  final List<BillSummary> bills;
  final double totalSales;
  final double averageSale;
  final int billCount;
  final double totalPending;

  const BillListLoaded({
    required this.bills,
    required this.totalSales,
    required this.averageSale,
    required this.billCount,
    required this.totalPending,
  });

  @override
  List<Object?> get props => [bills, totalSales, averageSale, billCount, totalPending];
}
