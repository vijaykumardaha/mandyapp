part of 'vegetable_bloc.dart';

sealed class VegetableState extends Equatable {
  const VegetableState();

  @override
  List<Object> get props => [];
}

final class VegetableInitial extends VegetableState {}

final class VegetableLoading extends VegetableState {}

final class VegetableLoaded extends VegetableState {
  final List<Vegetable> vegetables;
  const VegetableLoaded({required this.vegetables});

  @override
  List<Object> get props => [vegetables];
}

final class VegetableError extends VegetableState {
  final String errorMsg;
  const VegetableError({required this.errorMsg});

  @override
  List<Object> get props => [errorMsg];
}
