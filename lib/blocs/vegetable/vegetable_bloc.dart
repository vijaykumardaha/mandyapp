import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/dao/vegetable_dao.dart';
import 'package:mandyapp/models/vegetable_model.dart';

part 'vegetable_event.dart';
part 'vegetable_state.dart';

class VegetableBloc extends Bloc<VegetableEvent, VegetableState> {
  final VegetableDAO vegetableDAO = VegetableDAO();

  VegetableBloc() : super(VegetableInitial()) {
    on<SyncVegetables>((event, emit) async {
      try {
        emit(VegetableLoading());
        await vegetableDAO.syncVegetables();
        add(const FetchVegetables());
      } catch (error) {
        emit(VegetableError(errorMsg: error.toString()));
      }
    });

    on<FetchVegetables>((event, emit) async {
      try {
        emit(VegetableLoading());
        final vegetables = await vegetableDAO.getVegetables();
        emit(VegetableLoaded(vegetables: vegetables));
      } catch (error) {
        emit(VegetableError(errorMsg: error.toString()));
      }
    });

    on<SearchVegetables>((event, emit) async {
      try {
        emit(VegetableLoading());
        final vegetables = await vegetableDAO.getVegetables();
        emit(VegetableLoaded(
          vegetables: _filterVegetables(vegetables, event.query),
        ));
      } catch (error) {
        emit(VegetableError(errorMsg: error.toString()));
      }
    });
  }

  List<Vegetable> _filterVegetables(List<Vegetable> vegetables, String query) {
    final normalizedQuery = query.toLowerCase();
    return vegetables.where((item) {
      final name = item.name.toLowerCase();
      final key = item.key.toLowerCase();
      if (normalizedQuery.isEmpty) return true;
      return name.contains(normalizedQuery) || key.contains(normalizedQuery);
    }).toList();
  }
}
