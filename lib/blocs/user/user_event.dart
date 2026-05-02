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
  final String role;

  const SaveUser(
      {required this.name, 
      required this.mobile, 
      required this.password,
      this.role = 'admin'});

  @override
  List<Object> get props => [name, mobile, password, role];
}

class LoadUsersByRole extends UserEvent {
  final String role;

  const LoadUsersByRole({required this.role});

  @override
  List<Object> get props => [role];
}

class UpdateUserRole extends UserEvent {
  final int userId;
  final String newRole;

  const UpdateUserRole({required this.userId, required this.newRole});

  @override
  List<Object> get props => [userId, newRole];
}

class LoadAdminUser extends UserEvent {}

class LoadUsersCreatedBy extends UserEvent {
  final int createdBy;

  const LoadUsersCreatedBy({required this.createdBy});

  @override
  List<Object> get props => [createdBy];
}

class SaveUserWithCreator extends UserEvent {
  final String name, mobile, password;
  final String role;
  final int createdBy;

  const SaveUserWithCreator(
      {required this.name, 
      required this.mobile, 
      required this.password,
      this.role = 'staff',
      required this.createdBy});

  @override
  List<Object> get props => [name, mobile, password, role, createdBy];
}

class GetCreatorInfo extends UserEvent {
  final int creatorId;

  const GetCreatorInfo({required this.creatorId});

  @override
  List<Object> get props => [creatorId];
}
