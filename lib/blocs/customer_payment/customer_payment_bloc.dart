import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/customer_payment_dao.dart';
import 'package:mandyapp/models/customer_payment_model.dart';

part 'customer_payment_event.dart';
part 'customer_payment_state.dart';

class CustomerPaymentBloc extends Bloc<CustomerPaymentEvent, CustomerPaymentState> {
  final CustomerPaymentDAO _dao = CustomerPaymentDAO();

  CustomerPaymentBloc() : super(CustomerPaymentInitial()) {
    on<FetchPayments>(_onFetchPayments);
    on<AddPayment>(_onAddPayment);
    on<EditPayment>(_onEditPayment);
    on<RemovePayment>(_onRemovePayment);
  }

  Future<void> _fetchPayments(int customerId, Emitter<CustomerPaymentState> emit) async {
    final payments = await _dao.getPaymentsByCustomerId(customerId);
    final totalPaid = await _dao.getTotalByType(customerId, 'paid');
    final totalReceived = await _dao.getTotalByType(customerId, 'received');
    emit(CustomerPaymentsLoaded(
      payments: payments,
      totalPaid: totalPaid,
      totalReceived: totalReceived,
    ));
  }

  Future<void> _onFetchPayments(FetchPayments event, Emitter<CustomerPaymentState> emit) async {
    try {
      emit(CustomerPaymentLoading());
      await _fetchPayments(event.customerId, emit);
    } catch (e) {
      emit(CustomerPaymentError(message: e.toString()));
    }
  }

  Future<void> _onAddPayment(AddPayment event, Emitter<CustomerPaymentState> emit) async {
    try {
      await _dao.insertPayment(event.payment);
      await _fetchPayments(event.payment.customerId, emit);
    } catch (e) {
      emit(CustomerPaymentError(message: e.toString()));
    }
  }

  Future<void> _onEditPayment(EditPayment event, Emitter<CustomerPaymentState> emit) async {
    try {
      await _dao.updatePayment(event.payment);
      await _fetchPayments(event.payment.customerId, emit);
    } catch (e) {
      emit(CustomerPaymentError(message: e.toString()));
    }
  }

  Future<void> _onRemovePayment(RemovePayment event, Emitter<CustomerPaymentState> emit) async {
    try {
      await _dao.deletePayment(event.paymentId);
      await _fetchPayments(event.customerId, emit);
    } catch (e) {
      emit(CustomerPaymentError(message: e.toString()));
    }
  }
}
