part of 'charge_types_bloc.dart';

abstract class ChargeTypesState extends Equatable {
  const ChargeTypesState();

  @override
  List<Object?> get props => [];
}

// Initial state
class ChargeTypesInitial extends ChargeTypesState {}

// Loading state
class ChargeTypesLoading extends ChargeTypesState {}

// Loaded state - list of charge types
class ChargeTypesLoaded extends ChargeTypesState {
  final List<ChargeType> chargeTypes;

  const ChargeTypesLoaded(this.chargeTypes);

  @override
  List<Object?> get props => [chargeTypes];
}

// Single charge type loaded
class ChargeTypeLoaded extends ChargeTypesState {
  final ChargeType chargeType;

  const ChargeTypeLoaded(this.chargeType);

  @override
  List<Object?> get props => [chargeType];
}

// Charge type operation success
class ChargeTypesOperationSuccess extends ChargeTypesState {
  final String message;

  const ChargeTypesOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Charge type error state
class ChargeTypesError extends ChargeTypesState {
  final String message;

  const ChargeTypesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Charge type empty state
class ChargeTypesEmpty extends ChargeTypesState {}
