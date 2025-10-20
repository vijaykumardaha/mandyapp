import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/category_dao.dart';
import 'package:mandyapp/models/category_model.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryDAO categoryDAO = CategoryDAO();

  CategoryBloc() : super(CategoryInitial()) {
    on<LoadCategories>((event, emit) async {
      try {
        emit(CategoryLoading());
        final categories = await categoryDAO.getAllCategories();
        emit(CategoryLoaded(categories));
      } catch (error) {
        emit(CategoryError('Failed to load categories: ${error.toString()}'));
      }
    });

    on<AddCategory>((event, emit) async {
      try {
        emit(CategoryLoading());
        await categoryDAO.insertCategory(event.category);
        final categories = await categoryDAO.getAllCategories();
        emit(CategoryOperationSuccess(categories, 'Category added successfully'));
      } catch (error) {
        emit(CategoryError('Failed to add category: ${error.toString()}'));
      }
    });

    on<UpdateCategory>((event, emit) async {
      try {
        emit(CategoryLoading());
        await categoryDAO.updateCategory(event.category);
        final categories = await categoryDAO.getAllCategories();
        emit(CategoryOperationSuccess(categories, 'Category updated successfully'));
      } catch (error) {
        emit(CategoryError('Failed to update category: ${error.toString()}'));
      }
    });

    on<DeleteCategory>((event, emit) async {
      try {
        emit(CategoryLoading());
        await categoryDAO.deleteCategory(event.id);
        final categories = await categoryDAO.getAllCategories();
        emit(CategoryOperationSuccess(categories, 'Category deleted successfully'));
      } catch (error) {
        emit(CategoryError('Failed to delete category: ${error.toString()}'));
      }
    });
  }
}
