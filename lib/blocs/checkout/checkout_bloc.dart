import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/dao/cart_dao.dart';
import 'package:mandyapp/dao/product_dao.dart';
import 'package:mandyapp/dao/product_variant_dao.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final CartDAO cartDAO = CartDAO();
  final ProductDAO productDAO = ProductDAO();
  final ProductVariantDAO variantDAO = ProductVariantDAO();

  Map<int, Product> _products = {};
  Map<int, ProductVariant> _variants = {};

  CheckoutBloc() : super(CheckoutInitial()) {
    // ==================== CHECKOUT OPERATIONS ====================

    // Load cart for checkout
    on<LoadCheckoutCart>((event, emit) async {
      try {
        emit(CheckoutLoading());

        final cart = await cartDAO.getCartWithItems(event.cartId);
        if (cart != null) {
          emit(CheckoutCartLoaded(cart));

          // Extract product and variant IDs from cart items
          final productIds = cart.items?.map((item) => item.productId).toSet().toList() ?? [];
          final variantIds = cart.items?.map((item) => item.variantId).toSet().toList() ?? [];

          // Load product details
          if (productIds.isNotEmpty) {
            add(LoadProductDetails(productIds));
          }

          // Load variant details
          if (variantIds.isNotEmpty) {
            add(LoadVariantDetails(variantIds));
          }
        } else {
          emit(const CheckoutError('Cart not found'));
        }
      } catch (error) {
        emit(CheckoutError('Failed to load cart: ${error.toString()}'));
      }
    });

    // Load product details
    on<LoadProductDetails>((event, emit) async {
      try {
        for (final productId in event.productIds) {
          if (!_products.containsKey(productId)) {
            final product = await productDAO.getProductById(productId);
            if (product != null) {
              _products[productId] = product;
            }
          }
        }

        // Check if we have all data loaded
        _checkAndEmitLoadedState(emit);
      } catch (error) {
        emit(CheckoutError('Failed to load product details: ${error.toString()}'));
      }
    });

    // Load variant details
    on<LoadVariantDetails>((event, emit) async {
      try {
        for (final variantId in event.variantIds) {
          if (!_variants.containsKey(variantId)) {
            final variant = await variantDAO.getVariantById(variantId);
            if (variant != null) {
              _variants[variantId] = variant;
            }
          }
        }

        // Check if we have all data loaded
        _checkAndEmitLoadedState(emit);
      } catch (error) {
        emit(CheckoutError('Failed to load variant details: ${error.toString()}'));
      }
    });

    // Complete checkout
    on<CompleteCheckout>((event, emit) async {
      try {
        emit(CheckoutLoading());

        await cartDAO.updateCartStatus(event.cartId, 'completed');

        // Reload cart to confirm status update
        final updatedCart = await cartDAO.getCartWithItems(event.cartId);
        if (updatedCart != null) {
          emit(const CheckoutCompleted('Order completed successfully'));
        } else {
          emit(const CheckoutError('Failed to confirm order completion'));
        }
      } catch (error) {
        emit(CheckoutError('Failed to complete checkout: ${error.toString()}'));
      }
    });

    // ==================== CHECKOUT ITEM OPERATIONS ====================

    // Update cart item (for increment/decrement in checkout)
    on<UpdateCheckoutItem>((event, emit) async {
      try {
        await cartDAO.updateCartItem(event.item);

        Cart? updatedCart;
        if (state is CheckoutDataLoaded) {
          final current = state as CheckoutDataLoaded;
          final updatedItems = current.cart.items?.map((existing) {
            if (existing.id == event.item.id) {
              return event.item;
            }
            return existing;
          }).toList();

          updatedCart = current.cart.copyWith(
            id: current.cart.id,
            items: updatedItems,
          );

          emit(CheckoutDataLoaded(updatedCart, _products, _variants));
        } else {
          final cartId = event.item.buyerCartId;
          if (cartId != null) {
            add(LoadCheckoutCart(cartId));
          }
        }
      } catch (error) {
        emit(CheckoutError('Failed to update item: ${error.toString()}'));
      }
    });

    // Remove item from cart (for removing items in checkout)
    on<RemoveCheckoutItem>((event, emit) async {
      try {
        await cartDAO.deleteCartItem(event.item.id!);
        // Reload current cart to get updated items
        add(LoadCheckoutCart(event.item.buyerCartId!));
      } catch (error) {
        emit(CheckoutError('Failed to remove item: ${error.toString()}'));
      }
    });
  }

  void _checkAndEmitLoadedState(Emitter<CheckoutState> emit) {
    // Get current state
    final currentState = state;

    if (currentState is CheckoutCartLoaded) {
      final cart = currentState.cart;

      // Check if we have all required data
      final hasAllProducts = cart.items?.every((item) => _products.containsKey(item.productId)) ?? true;
      final hasAllVariants = cart.items?.every((item) => _variants.containsKey(item.variantId)) ?? true;

      if (hasAllProducts && hasAllVariants) {
        emit(CheckoutDataLoaded(cart, _products, _variants));
      }
    }
  }

  // Getters for accessing loaded data
  Map<int, Product> get products => _products;
  Map<int, ProductVariant> get variants => _variants;
}
