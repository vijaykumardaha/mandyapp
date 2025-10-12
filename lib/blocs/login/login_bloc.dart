
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/user_dao.dart';
import 'package:mandyapp/models/user_model.dart';
import 'package:mandyapp/utils/app_helper.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserDAO userDAO = UserDAO();

  LoginBloc() : super(LoginChecking()) {
    // Check if user is already logged in on app start
    on<CheckLoginStatus>((event, emit) async {
      try {
        final userData = await AppHelper.getPreferences('user');
        
        if (userData != null) {
          final user = User.fromJson(userData);
          emit(LoginSuccess(user: user));
        } else {
          emit(CheckingFailed());
        }
      } catch (error) {
        emit(CheckingFailed());
      }
    });

    on<LoginSubmit>((event, emit) async {
      try {
        emit(LoginLoading());
        
        // Validate credentials against database
        User? user = await userDAO.userLogin(event.mobile, event.password);

        if (user != null) {
          // Valid credentials - save user and emit success
          await AppHelper.savePreferences('user', user.toJson());
          emit(LoginSuccess(user: user));
        } else {
          // Invalid credentials - emit failure
          emit(LoginFailure(error: 'Invalid mobile number or password'));
        }
      } catch (error) {
        emit(LoginFailure(error: 'An error occurred. Please try again.'));
      }
    });

    // Register new user (separate from login)
    on<RegisterUser>((event, emit) async {
      try {
        emit(LoginLoading());
        
        // Check if user already exists by mobile number
        User? existingUser = await userDAO.getUserByMobile(event.mobile);
        
        if (existingUser != null) {
          emit(const LoginFailure(error: 'Mobile number already registered. Please login.'));
          return;
        }
        
        // Create new user
        final newUser = User(
          mobile: event.mobile,
          password: event.password,
          name: event.name,
        );
        
        int userId = await userDAO.insertUser(newUser);
        newUser.id = userId;
        
        // Auto-login after registration
        await AppHelper.savePreferences('user', newUser.toJson());
        emit(LoginSuccess(user: newUser));
      } catch (error) {
        emit(const LoginFailure(error: 'Registration failed. Please try again.'));
      }
    });

    on<LogoutSubmit>((event, emit) async {
      try {
        await AppHelper.removePreferences('user');
        emit(LogoutSuccess());
      } catch (error) {
        emit(LogoutSuccess());
      }
    });

    on<ResetDatabase>((event, emit) async {
      // Handle database reset if needed
      emit(LoginInitial());
    });
  }
}
