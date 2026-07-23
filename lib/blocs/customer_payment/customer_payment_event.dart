part of 'customer_payment_bloc.dart';

sealed class CustomerPaymentEvent extends Equatable {
  const CustomerPaymentEvent();

  @override
  List<Object?> get props => [];
}

class FetchPayments extends CustomerPaymentEvent {
  final int customerId;
  const FetchPayments({required this.customerId});

  @override
  List<Object?> get props => [customerId];
}

class AddPayment extends CustomerPaymentEvent {
  final CustomerPayment payment;
  const AddPayment({required this.payment});

  @override
  List<Object?> get props => [payment];
}

class EditPayment extends CustomerPaymentEvent {
  final CustomerPayment payment;
  const EditPayment({required this.payment});

  @override
  List<Object?> get props => [payment];
}

class RemovePayment extends CustomerPaymentEvent {
  final int paymentId;
  final int customerId;
  const RemovePayment({required this.paymentId, required this.customerId});

  @override
  List<Object?> get props => [paymentId, customerId];
}
