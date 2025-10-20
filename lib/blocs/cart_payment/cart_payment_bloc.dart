import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/models/cart_payment_model.dart';
import 'package:mandyapp/dao/cart_payment_dao.dart';

part 'cart_payment_event.dart';
part 'cart_payment_state.dart';

class CartPaymentBloc extends Bloc<CartPaymentEvent, CartPaymentState> {
  final CartPaymentDAO paymentDAO = CartPaymentDAO();

  List<CartPayment> _payments = [];

  CartPaymentBloc() : super(CartPaymentInitial()) {
    // ==================== PAYMENT SUMMARY OPERATIONS ====================

    // Load all cart payment summaries
    on<LoadCartPayments>((event, emit) async {
      try {
        emit(CartPaymentLoading());

        _payments = await paymentDAO.getAllCartPayments();
        emit(CartPaymentsLoaded(_payments));
      } catch (error) {
        emit(CartPaymentOperationFailure('Failed to load payments: ${error.toString()}'));
      }
    });

    // Load cart payment summary for specific cart
    on<LoadCartPaymentsByCart>((event, emit) async {
      try {
        emit(CartPaymentLoading());

        final payment = await paymentDAO.getCartPaymentByCartId(event.cartId);
        if (payment != null) {
          _payments = [payment];
          emit(CartPaymentsLoaded(_payments));
        } else {
          _payments = [];
          emit(CartPaymentsLoaded(_payments));
        }
      } catch (error) {
        emit(CartPaymentOperationFailure('Failed to load cart payment: ${error.toString()}'));
      }
    });

    // Update cart payment summary
    on<UpdateCartPayment>((event, emit) async {
      try {
        emit(CartPaymentLoading());

        await paymentDAO.updateCartPayment(event.payment);

        // Reload payments to get updated list
        _payments = await paymentDAO.getAllCartPayments();
        emit(CartPaymentsLoaded(_payments));
        emit(const CartPaymentOperationSuccess('Payment updated successfully'));
      } catch (error) {
        emit(CartPaymentOperationFailure('Failed to update payment: ${error.toString()}'));
      }
    });

    // Refresh cart payment summaries
    on<RefreshCartPayments>((event, emit) async {
      try {
        _payments = await paymentDAO.getAllCartPayments();
        emit(CartPaymentsLoaded(_payments));
      } catch (error) {
        emit(CartPaymentOperationFailure('Failed to refresh payments: ${error.toString()}'));
      }
    });
  }

  // Getters for accessing loaded data
  List<CartPayment> get payments => _payments;

  // Helper method to get total payment amount for current payments
  double get totalPaymentAmount {
    return _payments.fold(0.0, (sum, payment) => sum + payment.receiveAmount);
  }

  // Helper method to get payment count for current payments
  int get paymentCount => _payments.length;
}
