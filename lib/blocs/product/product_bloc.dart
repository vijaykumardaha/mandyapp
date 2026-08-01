import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:krishimandi/dao/product_dao.dart';
import 'package:krishimandi/models/product_model.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductDAO productDAO = ProductDAO();

  ProductBloc() : super(ProductInitial()) {
    on<LoadProducts>((event, emit) async {
      try {
        emit(ProductLoading());
        final products = await productDAO.getAllProductsWithVariants();
        emit(ProductLoaded(products));
      } catch (error) {
        emit(const ProductError('Failed to load products. Please try again.'));
      }
    });

    on<AddProduct>((event, emit) async {
      try {
        emit(ProductLoading());
        await productDAO.insertProduct(event.product);
        final products = await productDAO.getAllProductsWithVariants();
        emit(ProductLoaded(products));
        emit(const ProductOperationSuccess('Product added successfully'));
      } catch (error) {
        emit(const ProductError('Failed to add product. Please try again.'));
      }
    });

    on<UpdateProduct>((event, emit) async {
      try {
        emit(ProductLoading());
        await productDAO.updateProduct(event.product);
        final products = await productDAO.getAllProductsWithVariants();
        emit(ProductLoaded(products));
        emit(const ProductOperationSuccess('Product updated successfully'));
      } catch (error) {
        emit(const ProductError('Failed to update product. Please try again.'));
      }
    });

    on<DeleteProduct>((event, emit) async {
      try {
        emit(ProductLoading());
        await productDAO.deleteProduct(event.id);
        final products = await productDAO.getAllProductsWithVariants();
        emit(ProductLoaded(products));
        emit(const ProductOperationSuccess('Product deleted successfully'));
      } catch (error) {
        emit(const ProductError('Failed to delete product. Please try again.'));
      }
    });

    on<SearchProducts>((event, emit) async {
      try {
        emit(ProductLoading());
        final allProducts = await productDAO.getAllProductsWithVariants();
        final filteredProducts = allProducts.where((product) {
          final queryLower = event.query.toLowerCase();
          final defaultName =
              product.defaultVariantModel?.variantName.toLowerCase() ?? '';
          if (defaultName.contains(queryLower)) {
            return true;
          }
          if (product.variants == null) return false;
          return product.variants!.any((variant) =>
              variant.variantName.toLowerCase().contains(queryLower));
        }).toList();
        emit(ProductLoaded(filteredProducts));
      } catch (error) {
        emit(
            const ProductError('Failed to search products. Please try again.'));
      }
    });

    on<ProductsSync>((event, emit) async {
      try {
        await productDAO.productsSync();
        final products = await productDAO.getAllProductsWithVariants();
        emit(ProductLoaded(products));
      } catch (error) {
        emit(const ProductError('Failed to sync products. Please try again.'));
      }
    });
  }
}
