import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/product_dao.dart';
import 'package:mandyapp/models/product_model.dart';

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
        emit(ProductError('Failed to load products: ${error.toString()}'));
      }
    });

    on<LoadProductsByCategory>((event, emit) async {
      try {
        emit(ProductLoading());
        final products = await productDAO.getProductsByCategoryWithVariants(event.categoryId);
        emit(ProductLoaded(products));
      } catch (error) {
        emit(ProductError('Failed to load products: ${error.toString()}'));
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
        emit(ProductError('Failed to add product: ${error.toString()}'));
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
        emit(ProductError('Failed to update product: ${error.toString()}'));
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
        emit(ProductError('Failed to delete product: ${error.toString()}'));
      }
    });

    on<SearchProducts>((event, emit) async {
      try {
        emit(ProductLoading());
        final allProducts = await productDAO.getAllProductsWithVariants();
        final filteredProducts = allProducts.where((product) {
          final queryLower = event.query.toLowerCase();
          final defaultName = product.defaultVariantModel?.variantName.toLowerCase() ?? '';
          if (defaultName.contains(queryLower)) {
            return true;
          }
          if (product.variants == null) return false;
          return product.variants!.any((variant) => variant.variantName.toLowerCase().contains(queryLower));
        }).toList();
        emit(ProductLoaded(filteredProducts));
      } catch (error) {
        emit(ProductError('Failed to search products: ${error.toString()}'));
      }
    });
  }
}
