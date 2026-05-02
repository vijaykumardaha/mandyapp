part of 'charge_types_bloc.dart';

abstract class ChargeTypesEvent extends Equatable {
  const ChargeTypesEvent();

  @override
  List<Object?> get props => [];
}

// Load all charge types
class LoadChargeTypes extends ChargeTypesEvent {}

// Load active charge types
class LoadActiveChargeTypes extends ChargeTypesEvent {}

// Create new charge type
class CreateChargeType extends ChargeTypesEvent {
  final ChargeType chargeType;

  const CreateChargeType(this.chargeType);

  @override
  List<Object?> get props => [chargeType];
}

// Update charge type
class UpdateChargeType extends ChargeTypesEvent {
  final ChargeType chargeType;

  const UpdateChargeType(this.chargeType);

  @override
  List<Object?> get props => [chargeType];
}

// Delete charge type
class DeleteChargeType extends ChargeTypesEvent {
  final int chargeTypeId;

  const DeleteChargeType(this.chargeTypeId);

  @override
  List<Object?> get props => [chargeTypeId];
}

// Toggle charge type status (activate/deactivate)
class ToggleChargeTypeStatus extends ChargeTypesEvent {
  final int chargeTypeId;
  final bool activate;

  const ToggleChargeTypeStatus({required this.chargeTypeId, required this.activate});

  @override
  List<Object?> get props => [chargeTypeId, activate];
}

// Load charge types by type (buyer/seller)
class LoadChargeTypesByType extends ChargeTypesEvent {
  final String chargeFor;

  const LoadChargeTypesByType(this.chargeFor);

  @override
  List<Object?> get props => [chargeFor];
}

// Get charge type by ID
class GetChargeTypeById extends ChargeTypesEvent {
  final int chargeTypeId;

  const GetChargeTypeById(this.chargeTypeId);

  @override
  List<Object?> get props => [chargeTypeId];
}
