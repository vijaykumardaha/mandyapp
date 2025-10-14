import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/dao/charge_dao.dart';
import 'charges_event.dart';
import 'charges_state.dart';

class ChargesBloc extends Bloc<ChargesEvent, ChargesState> {
  final ChargeDAO _chargeDAO = ChargeDAO();

  ChargesBloc() : super(ChargesInitial()) {
    on<LoadCharges>(_onLoadCharges);
    on<AddCharge>(_onAddCharge);
    on<UpdateCharge>(_onUpdateCharge);
    on<DeleteCharge>(_onDeleteCharge);
    on<ToggleChargeStatus>(_onToggleChargeStatus);
  }

  Future<void> _onLoadCharges(LoadCharges event, Emitter<ChargesState> emit) async {
    emit(ChargesLoading());
    try {
      final charges = await _chargeDAO.getAllCharges();
      emit(ChargesLoaded(charges: charges));
    } catch (e) {
      emit(ChargesError(message: 'Failed to load charges: ${e.toString()}'));
    }
  }

  Future<void> _onAddCharge(AddCharge event, Emitter<ChargesState> emit) async {
    try {
      await _chargeDAO.insertCharge(event.charge);
      add(LoadCharges());
    } catch (e) {
      emit(ChargesError(message: 'Failed to add charge: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateCharge(UpdateCharge event, Emitter<ChargesState> emit) async {
    try {
      await _chargeDAO.updateCharge(event.charge);
      add(LoadCharges());
    } catch (e) {
      emit(ChargesError(message: 'Failed to update charge: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteCharge(DeleteCharge event, Emitter<ChargesState> emit) async {
    try {
      await _chargeDAO.deleteCharge(event.chargeId);
      add(LoadCharges());
    } catch (e) {
      emit(ChargesError(message: 'Failed to delete charge: ${e.toString()}'));
    }
  }

  Future<void> _onToggleChargeStatus(ToggleChargeStatus event, Emitter<ChargesState> emit) async {
    try {
      if (event.charge.isActive == 1) {
        await _chargeDAO.deactivateCharge(event.charge.id!);
      } else {
        await _chargeDAO.activateCharge(event.charge.id!);
      }
      add(LoadCharges());
    } catch (e) {
      emit(ChargesError(message: 'Failed to toggle charge status: ${e.toString()}'));
    }
  }
}
