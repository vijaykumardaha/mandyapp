import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/blocs/order/order_bloc.dart';
import 'package:mandyapp/blocs/order_payment/order_payment_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/dao/order_charge_dao.dart';
import 'package:mandyapp/dao/order_payment_dao.dart';
import 'package:mandyapp/dao/order_item_dao.dart';
import 'package:mandyapp/models/bill_summary_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/models/order_payment_model.dart';

part 'bill_list_event.dart';
part 'bill_list_state.dart';

class BillListBloc extends Bloc<BillListEvent, BillListState> {
  final OrderBloc orderBloc;
  final OrderPaymentBloc paymentBloc;
  final ChargeTypesBloc chargeTypesBloc;

  final OrderChargeDAO orderChargeDAO;
  final OrderPaymentDAO orderPaymentDAO;
  final OrderItemDAO orderItemDAO;

  BillListBloc({
    required this.orderBloc,
    required this.paymentBloc,
    required this.chargeTypesBloc,
    required this.orderChargeDAO,
    required this.orderPaymentDAO,
    required this.orderItemDAO,
  }) : super(BillListInitial()) {
    on<LoadBillSummaries>(_onLoadBillSummaries);
    on<DeleteBillRequested>(_onDeleteBillRequested);
  }

  Future<void> _onLoadBillSummaries(
    LoadBillSummaries event,
    Emitter<BillListState> emit,
  ) async {
    emit(BillListLoading());

    if (orderBloc.state is! OrdersLoaded && orderBloc.state is! OrderEmpty) {
      orderBloc.add(LoadOrders());
      await orderBloc.stream.firstWhere(
        (state) => state is OrdersLoaded || state is OrderEmpty || state is OrderError,
      );
    }
    if (paymentBloc.state is! OrderPaymentsLoaded) {
      paymentBloc.add(const LoadOrderPayments());
      await paymentBloc.stream.firstWhere(
        (state) => state is OrderPaymentsLoaded || state is OrderPaymentError,
      );
    }
    // Note: ChargeTypesBloc state checking removed as it uses sealed classes
    // The charge types will be loaded by the UI components that need them

    final orderState = orderBloc.state;
    final paymentState = paymentBloc.state;

    if (orderState is OrderError) {
      emit(BillListError(orderState.message));
      return;
    }

    if (paymentState is OrderPaymentError) {
      emit(BillListError(paymentState.message));
      return;
    }

    if (orderState is OrderEmpty || orderState is! OrdersLoaded) {
      emit(BillListEmpty());
      return;
    }

    if (paymentState is! OrderPaymentsLoaded) {
      emit(const BillListError('Failed to load payment data'));
      return;
    }

    final orders = List.of(orderState.orders);
    List<Order> filteredOrders = orders;

    if (event.statusFilter != null && event.statusFilter!.isNotEmpty) {
      filteredOrders = filteredOrders
          .where((order) => order.status.toLowerCase() == event.statusFilter!.toLowerCase())
          .toList();
    }

    if (event.customerId != null) {
      filteredOrders = filteredOrders.where((order) => order.customerId == event.customerId).toList();
    }

    if (filteredOrders.isEmpty) {
      emit(BillListEmpty());
      return;
    }

    final payments = paymentState.orderPayments;

    final List<BillSummary> summaries = [];
    double totalSales = 0.0;
    double totalPending = 0.0;

    for (final order in filteredOrders) {
      OrderPayment? paymentMatch;
      for (final payment in payments) {
        if (payment.orderId == order.id) {
          paymentMatch = payment;
          break;
        }
      }

      final itemTotal = paymentMatch?.itemTotal ?? order.totalPrice;
      final chargeTotal = paymentMatch?.chargeTotal ?? 0.0;
      final expenseTotal = paymentMatch?.expenseTotal ?? 0.0;
      final receiveAmount = paymentMatch?.receiveAmount ?? 0.0;

      // Calculate amounts based on order type
      double grandTotal, pendingAmount, pendingPayment;
      if (order.orderFor == 'seller') {
        // For seller orders: grandTotal = subtotal - charges - expenses (seller gets less due to charges and expenses)
        grandTotal = itemTotal - chargeTotal - expenseTotal;
        pendingAmount = grandTotal - receiveAmount;
        // For seller: pendingPayment is the amount still owed to seller
        pendingPayment = grandTotal - receiveAmount;
      } else {
        // For buyer orders: grandTotal = subtotal + charges + expenses (buyer pays more due to charges and expenses)
        grandTotal = itemTotal + chargeTotal + expenseTotal;
        pendingAmount = grandTotal - receiveAmount;
        // For buyer: pendingPayment is the same as pendingAmount
        pendingPayment = pendingAmount;
      }

      final totalAmount = itemTotal + chargeTotal + expenseTotal;

      totalSales += receiveAmount;
      totalPending += pendingAmount;

      summaries.add(
        BillSummary(
          cartId: order.id!,
          customerId: order.customerId,
          createdAt: DateTime.tryParse(order.createdAt) ?? DateTime.now(),
          itemTotal: itemTotal,
          chargesTotal: chargeTotal,
          expensesTotal: expenseTotal,
          receiveAmount: receiveAmount,
          pendingAmount: pendingAmount,
          pendingPayment: pendingPayment,
          totalAmount: totalAmount,
          billNumber: order.id,
          status: order.status,
          billType: order.orderFor,
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

  Future<void> _onDeleteBillRequested(
    DeleteBillRequested event,
    Emitter<BillListState> emit,
  ) async {
    try {
      await orderBloc.orderDAO.deleteOrder(event.bill.cartId);
      
      await orderChargeDAO.deleteOrderCharges(event.bill.cartId);
      await orderPaymentDAO.deleteOrderPayments(event.bill.cartId);

      chargeTypesBloc.add(LoadChargeTypes());
      paymentBloc.add(const LoadOrderPayments());
      orderBloc.add(LoadOrders());

      add(const LoadBillSummaries(forceRefresh: true));
    } catch (error) {
      emit(BillListError('Failed to delete bill: ${error.toString()}'));
    }
  }
}
