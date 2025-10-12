part of 'user_bloc.dart';

sealed class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class LoadUser extends UserEvent {
  final int userId;

  const LoadUser({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LoadCurrentUser extends UserEvent {}

class UpdateUser extends UserEvent {
  final User user;

  const UpdateUser({required this.user});

  @override
  List<Object> get props => [user];
}

class UpdateUserProfile extends UserEvent {
  final String? name;
  final String? mobile;
  final String? password;

  const UpdateUserProfile({this.name, this.mobile, this.password});

  @override
  List<Object> get props => [name ?? '', mobile ?? '', password ?? ''];
}

class DeleteUser extends UserEvent {
  final int userId;

  const DeleteUser({required this.userId});

  @override
  List<Object> get props => [userId];
}

class SaveUser extends UserEvent {
  final String name, mobile, password;

  const SaveUser(
      {required this.name, required this.mobile, required this.password});

  @override
  List<Object> get props => [name, mobile, password];
}
