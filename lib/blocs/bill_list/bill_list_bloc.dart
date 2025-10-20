import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/blocs/cart/cart_bloc.dart';
import 'package:mandyapp/blocs/cart_payment/cart_payment_bloc.dart';
import 'package:mandyapp/blocs/charges/charges_bloc.dart';
import 'package:mandyapp/blocs/charges/charges_event.dart';
import 'package:mandyapp/blocs/charges/charges_state.dart';
import 'package:mandyapp/models/bill_summary_model.dart';
import 'package:mandyapp/models/cart_payment_model.dart';
import 'package:mandyapp/models/cart_model.dart';

part 'bill_list_event.dart';
part 'bill_list_state.dart';

class BillListBloc extends Bloc<BillListEvent, BillListState> {
  final CartBloc cartBloc;
  final CartPaymentBloc paymentBloc;
  final ChargesBloc chargesBloc;

  BillListBloc({
    required this.cartBloc,
    required this.paymentBloc,
    required this.chargesBloc,
  }) : super(BillListInitial()) {
    on<LoadBillSummaries>(_onLoadBillSummaries);
  }

  Future<void> _onLoadBillSummaries(
    LoadBillSummaries event,
    Emitter<BillListState> emit,
  ) async {
    emit(BillListLoading());

    if (cartBloc.state is! CartsLoaded && cartBloc.state is! CartEmpty) {
      cartBloc.add(LoadCarts());
      await cartBloc.stream.firstWhere(
        (state) => state is CartsLoaded || state is CartEmpty || state is CartError,
      );
    }
    if (paymentBloc.state is! CartPaymentsLoaded) {
      paymentBloc.add(const LoadCartPayments());
      await paymentBloc.stream.firstWhere(
        (state) => state is CartPaymentsLoaded || state is CartPaymentOperationFailure,
      );
    }
    if (chargesBloc.state is! ChargesLoaded) {
      chargesBloc.add(LoadCharges());
      await chargesBloc.stream.firstWhere(
        (state) => state is ChargesLoaded || state is ChargesError,
      );
    }

    final cartState = cartBloc.state;
    final paymentState = paymentBloc.state;

    if (cartState is CartError) {
      emit(BillListError(cartState.message));
      return;
    }

    if (paymentState is CartPaymentOperationFailure) {
      emit(BillListError(paymentState.error));
      return;
    }

    if (cartState is CartEmpty || cartState is! CartsLoaded) {
      emit(BillListEmpty());
      return;
    }

    if (paymentState is! CartPaymentsLoaded) {
      emit(const BillListError('Failed to load payment data'));
      return;
    }

    final carts = List.of(cartState.carts);
    List<Cart> filteredCarts = carts;

    if (event.statusFilter != null && event.statusFilter!.isNotEmpty) {
      filteredCarts = filteredCarts
          .where((cart) => cart.status.toLowerCase() == event.statusFilter!.toLowerCase())
          .toList();
    }

    if (event.customerId != null) {
      filteredCarts = filteredCarts.where((cart) => cart.customerId == event.customerId).toList();
    }

    if (filteredCarts.isEmpty) {
      emit(BillListEmpty());
      return;
    }

    final payments = paymentState.payments;

    final List<BillSummary> summaries = [];
    double totalSales = 0.0;
    double totalPending = 0.0;

    for (final cart in filteredCarts) {
      CartPayment? paymentMatch;
      for (final payment in payments) {
        if (payment.cartId == cart.id) {
          paymentMatch = payment;
          break;
        }
      }

      final itemTotal = paymentMatch?.itemTotal ?? cart.totalPrice;
      final chargesTotal = paymentMatch?.chargesTotal ?? 0.0;
      final receiveAmount = paymentMatch?.receiveAmount ?? 0.0;
      final pendingAmount = paymentMatch?.pendingAmount ?? (itemTotal + chargesTotal);
      final totalAmount = itemTotal + chargesTotal;

      totalSales += receiveAmount;
      totalPending += pendingAmount;

      summaries.add(
        BillSummary(
          cartId: cart.id,
          customerId: cart.customerId,
          createdAt: DateTime.tryParse(cart.createdAt) ?? DateTime.now(),
          itemTotal: itemTotal,
          chargesTotal: chargesTotal,
          receiveAmount: receiveAmount,
          pendingAmount: pendingAmount,
          totalAmount: totalAmount,
          billNumber: cart.id,
          status: cart.status,
        ),
      );
    }

    final billCount = summaries.length;
    final averageSale = billCount > 0 ? totalSales / billCount.toDouble() : 0.0;

    emit(
      BillListLoaded(
        bills: summaries,
        totalSales: totalSales,
        averageSale: averageSale,
        billCount: billCount,
        totalPending: totalPending,
      ),
    );
  }
}
