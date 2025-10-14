part of 'customer_bloc.dart';

sealed class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object> get props => [];
}

class SyncCustomer extends CustomerEvent {
  final List<Customer> customers;
  const SyncCustomer({required this.customers});

  @override
  List<Object> get props => [customers];
}

class FetchCustomer extends CustomerEvent {
  final String query;
  const FetchCustomer({required this.query});

  @override
  List<Object> get props => [query];
  
}

