part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class CheckLoginStatus extends LoginEvent {}

class LoginSubmit extends LoginEvent {
  final String mobile, password;

  const LoginSubmit({
    required this.mobile,
    required this.password
  });

  @override
  List<Object> get props => [mobile, password];
}

class RegisterUser extends LoginEvent {
  final String name, mobile, password;

  const RegisterUser({
    required this.name,
    required this.mobile,
    required this.password
  });

  @override
  List<Object> get props => [name, mobile, password];
}

class LogoutSubmit extends LoginEvent {}

class ResetDatabase extends LoginEvent {}
