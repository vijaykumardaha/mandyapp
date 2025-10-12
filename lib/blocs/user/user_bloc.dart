import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/dao/user_dao.dart';
import 'package:mandyapp/models/user_model.dart';
import 'package:mandyapp/utils/app_helper.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserDAO userDAO = UserDAO();

  UserBloc() : super(UserInitial()) {
    // Load user by ID from database
    on<LoadUser>((event, emit) async {
      try {
        emit(UserLoading());
        
        User? user = await userDAO.getUserById(event.userId);
        
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
        
        final userData = await AppHelper.getPreferences('user');
        
        if (userData != null) {
          final user = User.fromJson(userData);
          emit(UserLoaded(user: user));
        } else {
          emit(const UserError(errorMsg: 'No user logged in'));
        }
      } catch (error) {
        emit(UserError(errorMsg: 'Failed to load current user: ${error.toString()}'));
      }
    });

    // Update complete user object
    on<UpdateUser>((event, emit) async {
      try {
        emit(UserLoading());
        
        // Update in database
        await userDAO.updateUser(event.user);
        
        // Update in SharedPreferences
        await AppHelper.savePreferences('user', event.user.toJson());
        
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
        final userData = await AppHelper.getPreferences('user');
        
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
        );
        
        // Update in database
        await userDAO.updateUser(updatedUser);
        
        // Update in SharedPreferences
        await AppHelper.savePreferences('user', updatedUser.toJson());
        
        emit(UserUpdated(user: updatedUser));
      } catch (error) {
        emit(UserError(errorMsg: 'Failed to update profile: ${error.toString()}'));
      }
    });

    // Delete user
    on<DeleteUser>((event, emit) async {
      try {
        emit(UserLoading());
        
        await userDAO.deleteUser(event.userId);
        
        // If deleting current user, clear session
        final userData = await AppHelper.getPreferences('user');
        if (userData != null) {
          final currentUser = User.fromJson(userData);
          if (currentUser.id == event.userId) {
            await AppHelper.removePreferences('user');
          }
        }
        
        emit(UserDeleted());
      } catch (error) {
        emit(UserError(errorMsg: 'Failed to delete user: ${error.toString()}'));
      }
    });

    // Save/Create new user (legacy support)
    on<SaveUser>((event, emit) async {
      try {
        emit(UserLoading());
        
        final newUser = User(
          name: event.name,
          mobile: event.mobile,
          password: event.password,
        );
        
        int userId = await userDAO.insertUser(newUser);
        newUser.id = userId;
        
        // Save to SharedPreferences
        await AppHelper.savePreferences('user', newUser.toJson());
        
        emit(UserLoaded(user: newUser));
      } catch (error) {
        emit(UserError(errorMsg: 'Failed to save user: ${error.toString()}'));
      }
    });
  }
}
