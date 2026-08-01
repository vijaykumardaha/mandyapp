import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/dao/charge_type_dao.dart';
import 'package:krishimandi/models/charge_type_model.dart';

part 'charge_types_event.dart';
part 'charge_types_state.dart';

class ChargeTypesBloc extends Bloc<ChargeTypesEvent, ChargeTypesState> {
  final ChargeTypeDAO _chargeTypeDAO = ChargeTypeDAO();

  ChargeTypesBloc() : super(ChargeTypesInitial()) {
    on<LoadChargeTypes>(_onLoadChargeTypes);
    on<LoadActiveChargeTypes>(_onLoadActiveChargeTypes);
    on<CreateChargeType>(_onCreateChargeType);
    on<UpdateChargeType>(_onUpdateChargeType);
    on<DeleteChargeType>(_onDeleteChargeType);
    on<ToggleChargeTypeStatus>(_onToggleChargeTypeStatus);
    on<LoadChargeTypesByType>(_onLoadChargeTypesByType);
    on<GetChargeTypeById>(_onGetChargeTypeById);
  }

  Future<void> _onLoadChargeTypes(
    LoadChargeTypes event,
    Emitter<ChargeTypesState> emit,
  ) async {
    try {
      emit(ChargeTypesLoading());
      final chargeTypes = await _chargeTypeDAO.getAllChargeTypes();
      emit(ChargeTypesLoaded(chargeTypes));
    } catch (e) {
      emit(const ChargeTypesError(
          'Failed to load charge types. Please try again.'));
    }
  }

  Future<void> _onLoadActiveChargeTypes(
    LoadActiveChargeTypes event,
    Emitter<ChargeTypesState> emit,
  ) async {
    try {
      emit(ChargeTypesLoading());
      final chargeTypes = await _chargeTypeDAO.getActiveChargeTypes();
      emit(ChargeTypesLoaded(chargeTypes));
    } catch (e) {
      emit(const ChargeTypesError(
          'Failed to load active charge types. Please try again.'));
    }
  }

  Future<void> _onCreateChargeType(
    CreateChargeType event,
    Emitter<ChargeTypesState> emit,
  ) async {
    try {
      emit(ChargeTypesLoading());
      await _chargeTypeDAO.insertChargeType(event.chargeType);
      final chargeTypes = await _chargeTypeDAO.getAllChargeTypes();
      emit(ChargeTypesLoaded(chargeTypes));
      emit(const ChargeTypesOperationSuccess('Charge type added successfully'));
    } catch (e) {
      emit(const ChargeTypesError(
          'Failed to add charge type. Please try again.'));
    }
  }

  Future<void> _onUpdateChargeType(
    UpdateChargeType event,
    Emitter<ChargeTypesState> emit,
  ) async {
    try {
      emit(ChargeTypesLoading());
      await _chargeTypeDAO.updateChargeType(event.chargeType);
      final chargeTypes = await _chargeTypeDAO.getAllChargeTypes();
      emit(ChargeTypesLoaded(chargeTypes));
      emit(const ChargeTypesOperationSuccess(
          'Charge type updated successfully'));
    } catch (e) {
      emit(const ChargeTypesError(
          'Failed to update charge type. Please try again.'));
    }
  }

  Future<void> _onDeleteChargeType(
    DeleteChargeType event,
    Emitter<ChargeTypesState> emit,
  ) async {
    try {
      emit(ChargeTypesLoading());
      await _chargeTypeDAO.deleteChargeType(event.chargeTypeId);
      final chargeTypes = await _chargeTypeDAO.getAllChargeTypes();
      emit(ChargeTypesLoaded(chargeTypes));
      emit(const ChargeTypesOperationSuccess(
          'Charge type deleted successfully'));
    } catch (e) {
      emit(const ChargeTypesError(
          'Failed to delete charge type. Please try again.'));
    }
  }

  Future<void> _onToggleChargeTypeStatus(
    ToggleChargeTypeStatus event,
    Emitter<ChargeTypesState> emit,
  ) async {
    try {
      emit(ChargeTypesLoading());
      if (event.activate) {
        await _chargeTypeDAO.activateChargeType(event.chargeTypeId);
      } else {
        await _chargeTypeDAO.deactivateChargeType(event.chargeTypeId);
      }
      final chargeTypes = await _chargeTypeDAO.getAllChargeTypes();
      emit(ChargeTypesLoaded(chargeTypes));
      emit(const ChargeTypesOperationSuccess(
          'Charge type status updated successfully'));
    } catch (e) {
      emit(const ChargeTypesError(
          'Failed to update charge type status. Please try again.'));
    }
  }

  Future<void> _onLoadChargeTypesByType(
    LoadChargeTypesByType event,
    Emitter<ChargeTypesState> emit,
  ) async {
    try {
      emit(ChargeTypesLoading());
      final chargeTypes =
          await _chargeTypeDAO.getChargeTypesByType(event.chargeFor);
      emit(ChargeTypesLoaded(chargeTypes));
    } catch (e) {
      emit(const ChargeTypesError(
          'Failed to load charge types by type. Please try again.'));
    }
  }

  Future<void> _onGetChargeTypeById(
    GetChargeTypeById event,
    Emitter<ChargeTypesState> emit,
  ) async {
    try {
      emit(ChargeTypesLoading());
      final chargeType =
          await _chargeTypeDAO.getChargeTypeById(event.chargeTypeId);
      if (chargeType != null) {
        emit(ChargeTypeLoaded(chargeType));
      } else {
        emit(const ChargeTypesError('Charge type not found'));
      }
    } catch (e) {
      emit(const ChargeTypesError(
          'Failed to get charge type. Please try again.'));
    }
  }
}
