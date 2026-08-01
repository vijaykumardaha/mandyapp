import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/models/order_charge_model.dart';
import 'package:mandiapp/models/order_expense_model.dart';
import 'package:mandiapp/models/order_model.dart';
import 'package:mandiapp/models/order_payment_model.dart';
import 'package:mandiapp/widgets/billing/bill_line_item.dart';

class BillDetailsData {
  final Order order;
  final List<OrderPayment>? payments;
  final List<BillLineItem> lineItems;
  final List<OrderCharge> charges;
  final List<OrderExpense> expenses;
  final Map<int, Customer> customerById;

  const BillDetailsData({
    required this.order,
    this.payments,
    required this.lineItems,
    required this.charges,
    required this.expenses,
    required this.customerById,
  });

  String get customerName {
    final customer = customerById[order.customerId];
    return customer?.name?.trim().isNotEmpty ?? false
        ? customer!.name!.trim()
        : 'Customer';
  }

  double get itemTotal {
    return lineItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get chargesTotal {
    return charges.fold(0.0, (sum, charge) => sum + charge.chargeAmount);
  }

  double get expensesTotal {
    return expenses.fold(0.0, (sum, expense) => sum + expense.expenseAmount);
  }

  double get grandTotal {
    if (order.orderFor == 'seller') {
      return itemTotal - chargesTotal - expensesTotal;
    } else {
      return itemTotal + chargesTotal + expensesTotal;
    }
  }

  double get receivedAmount {
    if (payments == null || payments!.isEmpty) {
      return 0.0;
    }
    return payments!.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double get outstandingAmount => grandTotal - receivedAmount;

  double get paymentAmount {
    if (order.orderFor == 'seller') {
      return grandTotal;
    } else {
      return receivedAmount;
    }
  }

  double get pendingPayment {
    if (order.orderFor == 'seller') {
      return paymentAmount - receivedAmount;
    } else {
      return outstandingAmount;
    }
  }

  String get paymentMethodLabel {
    if (payments == null || payments!.isEmpty) {
      return 'Not recorded';
    }
    final methods = <String>[];
    for (final payment in payments!) {
      switch (payment.source) {
        case 'cash':
          methods.add('Cash');
          break;
        case 'upi':
          methods.add('UPI');
          break;
        case 'card':
          methods.add('Card');
          break;
        case 'credit':
          methods.add('Credit');
          break;
      }
    }
    if (methods.isEmpty) {
      return 'Not recorded';
    }
    return methods.join(', ');
  }
}
