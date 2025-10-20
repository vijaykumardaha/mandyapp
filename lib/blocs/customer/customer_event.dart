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

class AddCustomer extends CustomerEvent {
  final String name;
  final String phone;
  final String query;
  final double borrowAmount;
  final double advancedAmount;

  const AddCustomer({
    required this.name,
    required this.phone,
    required this.query,
    this.borrowAmount = 0.0,
    this.advancedAmount = 0.0,
  });

  @override
  List<Object> get props => [name, phone, query, borrowAmount, advancedAmount];
}

class DeleteCustomer extends CustomerEvent {
  final int customerId;
  final String query;

  const DeleteCustomer({required this.customerId, required this.query});

  @override
  List<Object> get props => [customerId, query];
}

class UpdateCustomer extends CustomerEvent {
  final Customer customer;
  final String query;

  const UpdateCustomer({required this.customer, required this.query});

  @override
  List<Object> get props => [customer, query];
}
