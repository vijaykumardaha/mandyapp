part of 'customer_bloc.dart';

sealed class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object> get props => [];
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