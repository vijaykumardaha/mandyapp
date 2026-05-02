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

final class UsersByRoleLoaded extends UserState {
  final List<User> users;
  final String role;

  const UsersByRoleLoaded({required this.users, required this.role});

  @override
  List<Object> get props => [users, role];
}

final class UserRoleUpdated extends UserState {
  final int userId;
  final String newRole;

  const UserRoleUpdated({required this.userId, required this.newRole});

  @override
  List<Object> get props => [userId, newRole];
}

final class UsersCreatedByLoaded extends UserState {
  final List<User> users;
  final int createdBy;

  const UsersCreatedByLoaded({required this.users, required this.createdBy});

  @override
  List<Object> get props => [users, createdBy];
}

final class CreatorInfoLoaded extends UserState {
  final User creator;

  const CreatorInfoLoaded({required this.creator});

  @override
  List<Object> get props => [creator];
}
