import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/charge_type_dao.dart';
import 'package:mandyapp/models/charge_type_model.dart';

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
      emit(ChargeTypesError('Failed to load charge types: $e'));
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
      emit(ChargeTypesError('Failed to load active charge types: $e'));
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
      emit(ChargeTypesOperationSuccess('Charge type added successfully'));
    } catch (e) {
      emit(ChargeTypesError('Failed to add charge type: $e'));
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
      emit(ChargeTypesOperationSuccess('Charge type updated successfully'));
    } catch (e) {
      emit(ChargeTypesError('Failed to update charge type: $e'));
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
      emit(ChargeTypesOperationSuccess('Charge type deleted successfully'));
    } catch (e) {
      emit(ChargeTypesError('Failed to delete charge type: $e'));
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
      emit(ChargeTypesOperationSuccess('Charge type status updated successfully'));
    } catch (e) {
      emit(ChargeTypesError('Failed to update charge type status: $e'));
    }
  }

  Future<void> _onLoadChargeTypesByType(
    LoadChargeTypesByType event,
    Emitter<ChargeTypesState> emit,
  ) async {
    try {
      emit(ChargeTypesLoading());
      final chargeTypes = await _chargeTypeDAO.getChargeTypesByType(event.chargeFor);
      emit(ChargeTypesLoaded(chargeTypes));
    } catch (e) {
      emit(ChargeTypesError('Failed to load charge types by type: $e'));
    }
  }

  Future<void> _onGetChargeTypeById(
    GetChargeTypeById event,
    Emitter<ChargeTypesState> emit,
  ) async {
    try {
      emit(ChargeTypesLoading());
      final chargeType = await _chargeTypeDAO.getChargeTypeById(event.chargeTypeId);
      if (chargeType != null) {
        emit(ChargeTypeLoaded(chargeType));
      } else {
        emit(ChargeTypesError('Charge type not found'));
      }
    } catch (e) {
      emit(ChargeTypesError('Failed to get charge type: $e'));
    }
  }
}
