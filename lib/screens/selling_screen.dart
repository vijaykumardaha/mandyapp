import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/blocs/category/category_bloc.dart';
import 'package:mandyapp/blocs/cart/cart_bloc.dart';
import 'package:mandyapp/helpers/extensions/string.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/cart_item_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:mandyapp/screens/checkout_screen.dart';

class SellingScreen extends StatefulWidget {
  const SellingScreen({super.key});

  @override
  State<SellingScreen> createState() => SellingScreenState();
}

class SellingScreenState extends State<SellingScreen> {
  late ThemeData theme;
  int? _selectedCategoryId;
  int? _selectedCartId;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<ProductBloc>().add(LoadProducts());
    context.read<CategoryBloc>().add(LoadCategories());
    context.read<CartBloc>().add(LoadCarts());
  }

  void _selectLastCart(List<Cart> carts) {
    if (carts.isNotEmpty && _selectedCartId == null) {
      // Select the last cart (most recently added)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedCartId = carts.last.id;
        });
      });
    }
  }

  void _showVariantSelectionDialog(Product product) {
    if (product.variants == null || product.variants!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No variants available for ${product.name}')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            // Get cart items for the selected cart
            List<CartItem> cartItems = [];
            if (cartState is CartsLoaded && _selectedCartId != null) {
              try {
                final selectedCart = cartState.carts.firstWhere((c) => c.id == _selectedCartId);
                cartItems = selectedCart.items ?? [];
              } catch (e) {
                // Cart not found
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: MySpacing.xy(16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: MyText.titleMedium(
                          product.name,
                          fontWeight: 600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                // Variants List
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: MySpacing.xy(16, 16),
                    itemCount: product.variants!.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                    itemBuilder: (context, index) {
                      final variant = product.variants![index];

                      // Check if this variant is in cart
                      final cartItem = _getCartItemForVariant(cartItems, variant.id!);

                      return Padding(
                        padding: MySpacing.xy(0, 12),
                        child: Row(
                          children: [
                            // Variant Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: variant.imagePath != null
                                  ? Image.asset(
                                      variant.imagePath!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          color: theme.colorScheme.surfaceVariant,
                                          child: Icon(
                                            Icons.inventory_2,
                                            size: 24,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      color: theme.colorScheme.surfaceVariant,
                                      child: Icon(
                                        Icons.inventory_2,
                                        size: 24,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                            MySpacing.width(12),

                            // Product Name & Unit
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MyText.bodyMedium(
                                    variant.variantName ?? product.name,
                                    fontWeight: 600,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  MySpacing.height(2),

                                ],
                              ),
                            ),

                            MySpacing.width(8),

                            // Price
                            Container(
                              alignment: Alignment.centerRight,
                              width: 150,
                              child: MyText.bodyLarge(
                                '₹${variant.sellingPrice.toStringAsFixed(2)} / ${variant.quantity.toStringAsFixed(0)}${variant.unit}',
                                fontWeight: 700,
                                color: theme.colorScheme.primary,
                                fontSize: 16,
                              ),
                            ),
                            MySpacing.width(12),

                            // ADD/Increment/Decrement buttons
                            if (cartItem != null) ...[
                              // Decrement button
                              InkWell(
                                onTap: () => _decrementCartItem(cartItem),
                                child: Container(
                                  padding: MySpacing.xy(8, 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    size: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              MySpacing.width(8),

                              // Quantity
                              Container(
                                padding: MySpacing.xy(8, 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: MyText.bodySmall(
                                  '${cartItem.quantity.toInt()}',
                                  color: Colors.white,
                                  fontWeight: 700,
                                  fontSize: 12,
                                ),
                              ),
                              MySpacing.width(8),

                              // Increment button
                              InkWell(
                                onTap: () => _incrementCartItem(cartItem),
                                child: Container(
                                  padding: MySpacing.xy(8, 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ] else ...[
                              // ADD button
                              InkWell(
                                onTap: () {
                                  _addVariantToCart(variant);
                                },
                                child: Container(
                                  padding: MySpacing.xy(16, 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: MyText.bodySmall(
                                    'ADD',
                                    color: Colors.white,
                                    fontWeight: 700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            );
          },
        ),
      ),
    );
  }

  void _addVariantToCart(ProductVariant variant) {
    if (_selectedCartId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a cart first')),
      );
      return;
    }

    if (variant.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid variant data')),
      );
      return;
    }

    final cartItem = CartItem(
      cartId: _selectedCartId!,
      productId: variant.productId,
      variantId: variant.id!,
      quantity: 1.0,
      unitPrice: variant.sellingPrice,
      totalPrice: variant.sellingPrice * 1.0,
    );

    context.read<CartBloc>().add(AddItemToCart(cartItem));
    
    // Removed toast message for cleaner UX
  }

  // Get cart item for a specific variant
  CartItem? _getCartItemForVariant(List<CartItem> cartItems, int variantId) {
    try {
      return cartItems.firstWhere(
        (item) => item.variantId == variantId && item.cartId == _selectedCartId,
      );
    } catch (e) {
      return null;
    }
  }

  void _incrementCartItem(CartItem cartItem) {
    final updatedItem = cartItem.copyWith(
      quantity: cartItem.quantity + 1,
      totalPrice: (cartItem.quantity + 1) * cartItem.unitPrice,
    );
    context.read<CartBloc>().add(UpdateCartItem(updatedItem));
  }

  void _decrementCartItem(CartItem cartItem) {
    if (cartItem.quantity > 1) {
      final updatedItem = cartItem.copyWith(
        quantity: cartItem.quantity - 1,
        totalPrice: (cartItem.quantity - 1) * cartItem.unitPrice,
      );
      context.read<CartBloc>().add(UpdateCartItem(updatedItem));
    } else {
      context.read<CartBloc>().add(RemoveItemFromCart(cartItem));
    }
  }


  void showCategoryFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoaded) {
            return AlertDialog(
              title: MyText.titleMedium('filter_by_category'.tr(), fontWeight: 600),
              contentPadding: MySpacing.xy(0, 20),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // All option
                    RadioListTile<int?>(
                      value: null,
                      groupValue: _selectedCategoryId,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                        context.read<ProductBloc>().add(LoadProducts());
                        Navigator.pop(context);
                      },
                      title: MyText.bodyMedium('all'.tr()),
                      dense: true,
                      contentPadding: MySpacing.x(24),
                    ),
                    const Divider(height: 1),
                    // Category options
                    ...state.categories.map((category) {
                      return RadioListTile<int?>(
                        value: category.id,
                        groupValue: _selectedCategoryId,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                          if (value != null) {
                            context.read<ProductBloc>().add(LoadProductsByCategory(value));
                          }
                          Navigator.pop(context);
                        },
                        title: MyText.bodyMedium(category.name),
                        dense: true,
                        contentPadding: MySpacing.x(24),
                      );
                    }),
                  ],
                ),
              ),
            );
          }
          return AlertDialog(
            title: MyText.titleMedium('filter_by_category'.tr(), fontWeight: 600),
            content: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  void _createNewCart() async {
    final cartId = DBHelper.generateUuidInt();
    final cart = Cart(
      id: cartId,
      userId: 1, // TODO: Get from logged in user
      name: 'Cart ${DateTime.now().toString().substring(11, 16)}',
      createdAt: DateTime.now().toIso8601String(),
      status: 'open',
    );
    context.read<CartBloc>().add(CreateCart(cart));
    setState(() {
      _selectedCartId = cartId;
    });
  }

  void _selectCart(int cartId) {
    setState(() {
      _selectedCartId = cartId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Cart Chips Row
            _buildCartChipsRow(),

            // Product Grid
            Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, productState) {
                if (productState is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (productState is ProductLoaded) {
                  if (productState.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: theme.colorScheme.onBackground.withOpacity(0.3),
                          ),
                          MySpacing.height(16),
                          MyText.bodyLarge(
                            'no_products_found'.tr(),
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: MySpacing.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: productState.products.length,
                    itemBuilder: (context, index) {
                      final product = productState.products[index];
                      return _buildProductCard(product);
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          ],
        ),
        
        // Floating View Cart Button
        if (_selectedCartId != null)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: _buildFloatingViewCartButton(),
            ),
          ),
      ],
    );
  }

  Widget _buildCartChipsRow() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        List<Cart> carts = [];
        
        if (state is CartsLoaded) {
          carts = state.carts.where((cart) => cart.status == 'open').toList();
          // Auto-select last cart if none selected
          _selectLastCart(carts);
        }

        return Container(
          padding: MySpacing.xy(16, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Cart chips
                ...carts.map((cart) {
                  final isSelected = _selectedCartId == cart.id;
                  return Padding(
                    padding: MySpacing.right(8),
                    child: InkWell(
                      onTap: () => _selectCart(cart.id),
                      child: Container(
                        padding: MySpacing.xy(12, 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            MySpacing.width(6),
                            MyText.bodySmall(
                              cart.name ?? 'Cart ${cart.id}',
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? 600 : 500,
                              fontSize: 12,
                            ),
                            if (cart.itemCount > 0) ...[
                              MySpacing.width(6),
                              Container(
                                padding: MySpacing.xy(6, 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.3)
                                      : theme.colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: MyText.bodySmall(
                                  '${cart.itemCount}',
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                  fontWeight: 700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            // Delete icon for selected cart
                            if (isSelected) ...[
                              MySpacing.width(6),
                              GestureDetector(
                                onTap: () {
                                  _deleteCart();
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                
                // Add new cart button
                InkWell(
                  onTap: _createNewCart,
                  child: Container(
                    padding: MySpacing.xy(12, 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        MySpacing.width(6),
                        MyText.bodySmall(
                          'New Cart',
                          color: theme.colorScheme.primary,
                          fontWeight: 600,
                          fontSize: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteCart() {
    if (_selectedCartId != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: MyText.titleMedium('Delete Cart?', fontWeight: 600),
          content: MyText.bodyMedium('Are you sure you want to delete this cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: MyText.bodyMedium('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<CartBloc>().add(DeleteCart(_selectedCartId!));
                setState(() {
                  _selectedCartId = null;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: MyText.bodyMedium('Delete', color: Colors.white),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFloatingViewCartButton() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        Cart? selectedCart;
        
        if (state is CartsLoaded) {
          try {
            selectedCart = state.carts.firstWhere((cart) => cart.id == _selectedCartId);
          } catch (e) {
            // Cart not found
          }
        }

        final itemCount = selectedCart?.itemCount ?? 0;
        
        // Hide button if cart has no items
        if (itemCount == 0) {
          return const SizedBox.shrink();
        }
        
        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(cartId: _selectedCartId!),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: MySpacing.xy(20, 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 20,
                    ),
                    MySpacing.width(12),
                    MyText.bodyMedium(
                      'Checkout',
                      color: Colors.white,
                      fontWeight: 700,
                      fontSize: 15,
                    ),
                    if (itemCount > 0) ...[
                      MySpacing.width(12),
                      Container(
                        padding: MySpacing.xy(10, 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MyText.bodySmall(
                          '$itemCount',
                          color: theme.colorScheme.primary,
                          fontWeight: 700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    MySpacing.width(8),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final variantCount = product.variantCount;

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        // Get cart items for the selected cart
        List<CartItem> cartItems = [];
        if (cartState is CartsLoaded && _selectedCartId != null) {
          try {
            final selectedCart = cartState.carts.firstWhere((c) => c.id == _selectedCartId);
            cartItems = selectedCart.items ?? [];
          } catch (e) {
            // Cart not found
          }
        }

        // Check if product has any variants in cart
        CartItem? cartItemForProduct;
        double totalQuantityInCart = 0;
        
        if (product.variants != null && product.variants!.isNotEmpty) {
          // For single variant products, get the specific cart item
          if (variantCount == 1) {
            cartItemForProduct = _getCartItemForVariant(cartItems, product.variants!.first.id!);
            if (cartItemForProduct != null) {
              totalQuantityInCart = cartItemForProduct.quantity;
            }
          } else {
            // For multiple variants, calculate total quantity across all variants
            for (var variant in product.variants!) {
              if (variant.id != null) {
                final item = _getCartItemForVariant(cartItems, variant.id!);
                if (item != null) {
                  totalQuantityInCart += item.quantity;
                  cartItemForProduct ??= item; // Keep reference to first found item
                }
              }
            }
          }
        }

        return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product Image with floating cart controls
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Image
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: product.imagePath != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          child: Image.asset(
                            product.imagePath!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.inventory_2,
                                  size: 32,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.inventory_2,
                            size: 32,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                
                // Variant count badge (top right)
                if (variantCount > 1)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: MySpacing.xy(6, 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: MyText.bodySmall(
                        '$variantCount ${'variants'.tr()}',
                        color: Colors.white,
                        fontWeight: 700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                
                // Floating cart controls - Always show counter
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Decrement button
                        InkWell(
                          onTap: () {
                            if (cartItemForProduct != null) {
                              if (variantCount == 1) {
                                // Single variant: decrement directly
                                _decrementCartItem(cartItemForProduct!);
                              } else {
                                // Multiple variants: open dialog
                                _showVariantSelectionDialog(product);
                              }
                            }
                          },
                          child: Container(
                            padding: MySpacing.xy(5, 2),
                            child: Icon(
                              cartItemForProduct != null && variantCount > 1 
                                  ? Icons.edit 
                                  : Icons.remove,
                              size: 10,
                              color: cartItemForProduct != null 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                        // Quantity
                        Container(
                          padding: MySpacing.x(4),
                          child: MyText.bodySmall(
                            totalQuantityInCart.toInt().toString(),
                            color: Colors.white,
                            fontWeight: 700,
                            fontSize: 10,
                          ),
                        ),
                        // Increment button
                        InkWell(
                          onTap: () {
                            if (variantCount == 1 && product.variants != null && product.variants!.isNotEmpty) {
                              if (cartItemForProduct != null) {
                                // Increment existing item
                                _incrementCartItem(cartItemForProduct!);
                              } else {
                                // Add new item
                                _addVariantToCart(product.variants!.first);
                              }
                            } else {
                              // Multiple variants: open dialog
                              _showVariantSelectionDialog(product);
                            }
                          },
                          child: Container(
                            padding: MySpacing.xy(5, 2),
                            child: const Icon(
                              Icons.add,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: MySpacing.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product Name
                  MyText.bodySmall(
                    product.name,
                    fontWeight: 600,
                    fontSize: 11,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Show variant info only if more than 1 variant
                  if (variantCount > 1) ...[
                    // Variant Count Badge
                    Container(
                      padding: MySpacing.xy(6, 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: MyText.bodySmall(
                        '$variantCount ${'variants'.tr()}',
                        fontSize: 9,
                        color: theme.colorScheme.primary,
                        fontWeight: 600,
                      ),
                    ),

                    // Available Variants (show only if more than 1)
                    if (variantCount > 1)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: product.variants?.take(3).map((variant) {
                          return Container(
                            padding: MySpacing.xy(6, 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: MyText.bodySmall(
                              variant.variantName ?? '${variant.quantity}${variant.unit}',
                              fontSize: 8,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          );
                        }).toList() ?? [],
                      ),
                  ],
                  
                  // Show single variant price
                  if (variantCount == 1 && product.variants != null && product.variants!.isNotEmpty)
                    MyText.bodyLarge(
                      '₹${product.variants!.first.sellingPrice.toStringAsFixed(0)}',
                      fontWeight: 700,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}
