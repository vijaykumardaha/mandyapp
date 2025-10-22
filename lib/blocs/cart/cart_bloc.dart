import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/cart_dao.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/item_sale_model.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartDAO cartDAO = CartDAO();

  CartBloc() : super(CartInitial()) {
    // Load all carts (now loads open cart for default user)
    on<LoadCarts>((event, emit) async {
      try {
        emit(CartLoading());
        final carts = await cartDAO.getAllCarts();
        if (carts.isEmpty) {
          emit(CartEmpty());
        } else {
          emit(CartsLoaded(carts));
        }
      } catch (error) {
        emit(CartError('Failed to load carts: ${error.toString()}'));
      }
    });

    // Load cart with items
    on<LoadCartWithItems>((event, emit) async {
      try {
        // emit(CartLoading());
        final cart = await cartDAO.getCartWithItems(event.cartId);
        if (cart != null) {
          // emit(CartWithItemsLoaded(cart));
          add(LoadCarts());
        } else {
          emit(const CartError('Cart not found'));
        }
      } catch (error) {
        emit(CartError('Failed to load cart: ${error.toString()}'));
      }
    });

    // Load cart by ID (for checkout screen)
    on<LoadCartById>((event, emit) async {
      try {
        // emit(CartLoading());
        final cart = await cartDAO.getCartWithItems(event.cartId);
        if (cart != null) {
          emit(CartWithItemsLoaded(cart));
          add(LoadCartWithItems(event.cartId));
        } else {
          emit(const CartError('Cart not found'));
        }
      } catch (error) {
        emit(CartError('Failed to load cart: ${error.toString()}'));
      }
    });

    // Create new cart
    on<CreateCart>((event, emit) async {
      try {
        emit(CartLoading());
        final cartId = await cartDAO.insertCart(event.cart);
        final cart = await cartDAO.getCartWithItems(cartId);
        if (cart != null) {
          emit(CartWithItemsLoaded(cart));
          add(LoadCarts());
          emit(const CartOperationSuccess('Cart created successfully'));
        }
      } catch (error) {
        emit(CartError('Failed to create cart: ${error.toString()}'));
      }
    });

    // Update cart
    on<UpdateCart>((event, emit) async {
      try {
        emit(CartLoading());
        await cartDAO.updateCart(event.cart);
        final cart = await cartDAO.getCartWithItems(event.cart.id);
        if (cart != null) {
          emit(CartWithItemsLoaded(cart));
          emit(const CartOperationSuccess('Cart updated successfully'));
        }
      } catch (error) {
        emit(CartError('Failed to update cart: ${error.toString()}'));
      }
    });

    // Delete cart
    on<DeleteCart>((event, emit) async {
      try {
        await cartDAO.deleteCart(event.cartId);
        // Reload carts to get updated list
        add(LoadCarts());
      } catch (error) {
        emit(CartError('Failed to delete cart: ${error.toString()}'));
      }
    });

    // Add item to cart
    on<AddItemToCart>((event, emit) async {
      try {
        await cartDAO.insertCartItem(event.item);
        // Reload carts to get updated items
        add(LoadCarts());
      } catch (error) {
        emit(CartError('Failed to add item: ${error.toString()}'));
      }
    });

    // Update cart item
    on<UpdateCartItem>((event, emit) async {
      try {
        await cartDAO.updateCartItem(event.item);
        // Reload carts to get updated items
        add(LoadCarts());
        final cartId = event.item.buyerCartId;
        if (cartId != null) {
          add(LoadCartById(cartId));
        }
      } catch (error) {
        emit(CartError('Failed to update item: ${error.toString()}'));
      }
    });

    // Remove item from cart
    on<RemoveItemFromCart>((event, emit) async {
      try {
        await cartDAO.deleteCartItem(event.item.id!);
        // Reload carts to get updated items
        add(LoadCarts());
        final cartId = event.item.buyerCartId;
        if (cartId != null) {
          add(LoadCartById(cartId));
        }
      } catch (error) {
        emit(CartError('Failed to remove item: ${error.toString()}'));
      }
    });

    // Update cart status
    on<UpdateCartStatus>((event, emit) async {
      try {
        emit(CartLoading());
        await cartDAO.updateCartStatus(event.cartId, event.status);
        final cart = await cartDAO.getCartWithItems(event.cartId);
        if (cart != null) {
          emit(CartWithItemsLoaded(cart));
          emit(const CartOperationSuccess('Cart status updated'));
        }
      } catch (error) {
        emit(CartError('Failed to update status: ${error.toString()}'));
      }
    });

    // Clear cart
    on<ClearCart>((event, emit) async {
      try {
        emit(CartLoading());
        await cartDAO.clearCart(event.cartId);
        final cart = await cartDAO.getCartWithItems(event.cartId);
        if (cart != null) {
          emit(CartWithItemsLoaded(cart));
          emit(const CartOperationSuccess('Cart cleared'));
        }
      } catch (error) {
        emit(CartError('Failed to clear cart: ${error.toString()}'));
      }
    });
  }
}
