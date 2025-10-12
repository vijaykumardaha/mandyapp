part of 'user_bloc.dart';

sealed class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

final class UserInitial extends UserState {}

final class UserLoading extends UserState {}

final class UserLoaded extends UserState {
  final User user;

  const UserLoaded({required this.user});

  @override
  List<Object> get props => [user];
}

final class UserUpdated extends UserState {
  final User user;

  const UserUpdated({required this.user});

  @override
  List<Object> get props => [user];
}

final class UserDeleted extends UserState {}

final class UserError extends UserState {
  final String errorMsg;
  const UserError({required this.errorMsg});
  
  @override
  List<Object> get props => [errorMsg];
}
