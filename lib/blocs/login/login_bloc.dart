import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:mandiapp/dao/charge_type_dao.dart';
import 'package:mandiapp/dao/customer_dao.dart';
import 'package:mandiapp/dao/product_dao.dart';
import 'package:mandiapp/dao/vegetable_dao.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/models/user_model.dart';
import 'package:mandiapp/services/auth_api.dart';
import 'package:mandiapp/services/customer_service.dart';
import 'package:mandiapp/services/sync_service.dart';
import 'package:mandiapp/services/user_service.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/utils/constants.dart';
import 'package:mandiapp/utils/db_helper.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  // final UserDAO userDAO = UserDAO(); // local - commented out
  final AuthApi _authApi = AuthApi();

  LoginBloc() : super(LoginChecking()) {
    // Check if user is already logged in on app start
    on<CheckLoginStatus>((event, emit) async {
      try {
        final userData = await AppHelper.getPreferences(PrefsKeys.user);
        if (userData != null) {
          final user = User.fromJson(userData);
          if (user.role == 'customer') {
            emit(LoginCustomerSuccess(user: user));
          } else {
            emit(SyncLoading());
            await SyncService.instance.connectAndSync();
            emit(LoginSuccess(user: user));
          }
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

        final user = await _authApi.login(
          mobile: event.mobile,
          password: event.password,
        );

        await AppHelper.savePreferences(PrefsKeys.user, user.toJson());
        emit(SyncLoading());
        await SyncService.instance.connectAndSync();
        emit(LoginSuccess(user: user));
      } catch (e) {
        emit(LoginFailure(error: e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<CustomerLoginSubmit>((event, emit) async {
      try {
        emit(LoginCustomerLoading());

        final user = await _authApi.customerLogin(
          mandiId: event.mandiId,
          mobile: event.mobile,
        );

        await AppHelper.savePreferences(PrefsKeys.user, user.toJson());
        await CustomerService.instance.sync();
        emit(LoginCustomerSuccess(user: user));
      } catch (e) {
        emit(LoginCustomerFailure(
            error: e.toString().replaceFirst('Exception: ', '')));
      }
    });

    // Register new user (separate from login)
    on<RegisterUser>((event, emit) async {
      try {
        emit(LoginLoading());

        final user = await _authApi.signup(
          name: event.name,
          mobile: event.mobile,
          password: event.password,
        );

        await AppHelper.savePreferences(PrefsKeys.user, user.toJson());

        // Seed customers from phone contacts
        final customerDao = CustomerDAO();
        final existingCount = await customerDao.getCustomerCount();
        if (existingCount <= 1) {
          final hasPermission =
              await FlutterContacts.requestPermission(readonly: true);
          if (hasPermission) {
            final phoneContacts =
                await FlutterContacts.getContacts(withProperties: true);
            final converted = phoneContacts
                .where((c) =>
                    c.phones.isNotEmpty &&
                    c.phones.first.normalizedNumber.isNotEmpty)
                .map((c) {
              final phone = c.phones.first.normalizedNumber;
              final last10 = phone.length >= 10
                  ? phone.substring(phone.length - 10)
                  : phone;
              return Customer(name: c.displayName, phone: last10);
            }).toList();
            if (converted.isNotEmpty) {
              await customerDao.bulkInsert(converted);
            }
          }
        }

        await VegetableDAO().syncVegetables();
        await ProductDAO().productsSync();
        await ChargeTypeDAO().insertDefaultCharges();

        emit(SyncLoading());
        await SyncService.instance.connectAndSync();
        emit(LoginSuccess(user: user));
      } catch (e) {
        emit(LoginFailure(error: e.toString().replaceFirst('Exception: ', '')));
      }
    });

    on<LogoutSubmit>((event, emit) async {
      try {
        SyncService.instance.stopListening();
        UserService.instance.disconnect();
        CustomerService.instance.disconnect();
        await DBHelper.instance.clearAllTables();
        await AppHelper.removePreferences(PrefsKeys.user);
        emit(LogoutSuccess());
      } catch (error) {
        emit(LogoutSuccess());
      }
    });

    on<ResetDatabase>((event, emit) async {
      emit(LoginInitial());
    });
  }
}
