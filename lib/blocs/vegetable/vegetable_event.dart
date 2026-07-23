part of 'vegetable_bloc.dart';

sealed class VegetableEvent extends Equatable {
  const VegetableEvent();

  @override
  List<Object> get props => [];
}

class SyncVegetables extends VegetableEvent {
  const SyncVegetables();
}

class FetchVegetables extends VegetableEvent {
  const FetchVegetables();
}

class SearchVegetables extends VegetableEvent {
  final String query;
  const SearchVegetables({required this.query});

  @override
  List<Object> get props => [query];
}
