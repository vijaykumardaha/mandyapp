import 'package:mandyapp/models/charge_model.dart';

abstract class ChargesState {}

class ChargesInitial extends ChargesState {}

class ChargesLoading extends ChargesState {}

class ChargesLoaded extends ChargesState {
  final List<Charge> charges;
  ChargesLoaded({required this.charges});
}

class ChargesError extends ChargesState {
  final String message;
  ChargesError({required this.message});
}
