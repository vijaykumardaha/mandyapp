import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/dao/user_dao.dart';
import 'package:mandiapp/models/user_model.dart';
import 'package:mandiapp/services/auth_api.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/utils/constants.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserDAO userDAO = UserDAO();
  final AuthApi _authApi = AuthApi();

  UserBloc() : super(UserInitial()) {
    // Load user by ID from database
    on<LoadUser>((event, emit) async {
      try {
        emit(UserLoading());

        final User? user = await userDAO.getUserById(event.userId);

        if (user != null) {
          emit(UserLoaded(user: user));
        } else {
          emit(const UserError(errorMsg: 'User not found'));
        }
      } catch (error) {
        emit(UserError(errorMsg: 'Failed to load user: ${error.toString()}'));
      }
    });

    // Load current logged-in user from SharedPreferences
    on<LoadCurrentUser>((event, emit) async {
      try {
        emit(UserLoading());

        final userData = await AppHelper.getPreferences(PrefsKeys.user);

        if (userData != null) {
          final user = User.fromJson(userData);
          emit(UserLoaded(user: user));
        } else {
          emit(const UserError(errorMsg: 'No user logged in'));
        }
      } catch (error) {
        emit(UserError(
            errorMsg: 'Failed to load current user: ${error.toString()}'));
      }
    });

    // Update complete user object
    on<UpdateUser>((event, emit) async {
      try {
        emit(UserLoading());

        await userDAO.updateUser(event.user);

        emit(UserUpdated(user: event.user));
      } catch (error) {
        emit(UserError(errorMsg: 'Failed to update user: ${error.toString()}'));
      }
    });

    // Update user profile fields (partial update)
    on<UpdateUserProfile>((event, emit) async {
      try {
        emit(UserLoading());

        // Get current user from SharedPreferences
        final userData = await AppHelper.getPreferences(PrefsKeys.user);

        if (userData == null) {
          emit(const UserError(errorMsg: 'No user logged in'));
          return;
        }

        final currentUser = User.fromJson(userData);

        // Update only provided fields
        final updatedUser = User(
          id: currentUser.id,
          name: event.name ?? currentUser.name,
          mobile: event.mobile ?? currentUser.mobile,
          password: event.password ?? currentUser.password,
          role: currentUser.role,
        );

        // Update in database
        await userDAO.updateUser(updatedUser);

        // Update in SharedPreferences
        await AppHelper.savePreferences(PrefsKeys.user, updatedUser.toJson());

        emit(UserUpdated(user: updatedUser));
      } catch (error) {
        emit(UserError(
            errorMsg: 'Failed to update profile: ${error.toString()}'));
      }
    });

    // Delete user
    on<DeleteUser>((event, emit) async {
      try {
        emit(UserLoading());

        await userDAO.deleteUser(event.userId);

        // If deleting current user, clear session
        final userData = await AppHelper.getPreferences(PrefsKeys.user);
        if (userData != null) {
          final currentUser = User.fromJson(userData);
          if (currentUser.id == event.userId) {
            await AppHelper.removePreferences(PrefsKeys.user);
          }
        }

        emit(UserDeleted());
      } catch (error) {
        emit(UserError(errorMsg: 'Failed to delete user: ${error.toString()}'));
      }
    });

    // Save/Create new staff via API
    on<SaveUser>((event, emit) async {
      try {
        emit(UserLoading());

        final mandiId = await AppHelper.getCurrentMandiId();

        final newUser = await _authApi.addStaff(
          mandiId: mandiId ?? 0,
          name: event.name,
          mobile: event.mobile,
          password: event.password,
        );

        newUser.role = event.role;
        newUser.password = event.password;
        newUser.mandiId = mandiId ?? newUser.mandiId;
        await userDAO.registerUser(newUser);

        emit(UserUpdated(user: newUser));
      } catch (e) {
        emit(UserError(errorMsg: e.toString().replaceFirst('Exception: ', '')));
      }
    });

    // Load users by role
    on<LoadUsersByRole>((event, emit) async {
      try {
        emit(UserLoading());

        final users = await userDAO.getUsersByRole(event.role);

        emit(UsersByRoleLoaded(users: users, role: event.role));
      } catch (error) {
        emit(UserError(
            errorMsg: 'Failed to load users by role: ${error.toString()}'));
      }
    });

    // Load admin user
    on<LoadAdminUser>((event, emit) async {
      try {
        emit(UserLoading());

        final adminUser = await userDAO.getAdminUser();

        if (adminUser != null) {
          emit(UserLoaded(user: adminUser));
        } else {
          emit(const UserError(errorMsg: 'No admin user found'));
        }
      } catch (error) {
        emit(UserError(
            errorMsg: 'Failed to load admin user: ${error.toString()}'));
      }
    });

    // Toggle user active status
    on<ToggleUserActive>((event, emit) async {
      try {
        await userDAO.toggleUserActive(event.userId, event.active);
        emit(UserUpdated(
          user: User(id: event.userId, isActive: event.active ? 1 : 0),
        ));
      } catch (error) {
        emit(UserError(
            errorMsg: 'Failed to update status: ${error.toString()}'));
      }
    });
  }
}
