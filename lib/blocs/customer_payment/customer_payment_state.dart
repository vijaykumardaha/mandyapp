part of 'customer_payment_bloc.dart';

sealed class CustomerPaymentState extends Equatable {
  const CustomerPaymentState();

  @override
  List<Object?> get props => [];
}

final class CustomerPaymentInitial extends CustomerPaymentState {}

final class CustomerPaymentLoading extends CustomerPaymentState {}

final class CustomerPaymentsLoaded extends CustomerPaymentState {
  final List<CustomerPayment> payments;
  final double totalPaid;
  final double totalReceived;

  const CustomerPaymentsLoaded({
    required this.payments,
    required this.totalPaid,
    required this.totalReceived,
  });

  @override
  List<Object?> get props => [payments, totalPaid, totalReceived];
}

final class CustomerPaymentError extends CustomerPaymentState {
  final String message;
  const CustomerPaymentError({required this.message});

  @override
  List<Object?> get props => [message];
}
