part of 'customer_bloc.dart';

sealed class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

final class CustomerInitial extends CustomerState {}

final class CustomerLoading extends CustomerState {}

final class CustomerLoaded extends CustomerState {
  final List<Customer> customers;
  const CustomerLoaded({required this.customers});

  @override
  List<Object> get props => [customers];
}

final class SyncCustomerError extends CustomerState {
  final String errorMsg;
  const SyncCustomerError({required this.errorMsg});
  @override
  List<Object> get props => [errorMsg];
}

final class CurrentCustomerLoading extends CustomerState {}

final class CurrentCustomerLoaded extends CustomerState {
  final Customer? customer;
  const CurrentCustomerLoaded({this.customer});

  @override
  List<Object?> get props => [customer];
}

final class CurrentCustomerSyncLoading extends CustomerState {
  final Customer? customer;
  const CurrentCustomerSyncLoading({this.customer});

  @override
  List<Object?> get props => [customer];
}

final class CurrentCustomerSyncSuccess extends CustomerState {
  final Customer? customer;
  const CurrentCustomerSyncSuccess({this.customer});

  @override
  List<Object?> get props => [customer];
}

final class CurrentCustomerError extends CustomerState {
  final String message;
  const CurrentCustomerError(this.message);

  @override
  List<Object> get props => [message];
}
