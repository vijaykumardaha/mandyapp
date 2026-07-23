
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/blocs/order_expense/order_expense_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/order_item_model.dart';

import 'package:mandyapp/widgets/checkout/checkout_content.dart';

class CheckoutScreen extends StatefulWidget {
  final List<OrderItem>? cartItems;
  final int? customerId;
  final String orderFor; // 'buyer' or 'seller'

  const CheckoutScreen({
    Key? key,
    this.cartItems,
    this.customerId,
    required this.orderFor,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {

  @override
  void initState() {
    super.initState();
    // ChargeTypesBloc is initialized in the build method with LoadChargeTypes()
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText.titleMedium('Checkout'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: MyText.bodyLarge(
                widget.orderFor == 'seller' ? 'Confirm Payment' : 'Place Order',
                fontWeight: 600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ChargeTypesBloc(),
          ),
          BlocProvider(
            create: (context) => OrderExpenseBloc(),
          ),
        ],
        child: CheckoutContent(
            cartItems: widget.cartItems,
            customerId: widget.customerId?.toString(),
            orderFor: widget.orderFor,
          ),
      ),
    );
  }

}
