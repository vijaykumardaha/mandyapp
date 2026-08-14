import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:krishimandi/dao/charge_type_dao.dart';
import 'package:krishimandi/dao/product_dao.dart';
import 'package:krishimandi/dao/vegetable_dao.dart';
import 'package:krishimandi/models/user_model.dart';
import 'package:krishimandi/services/auth_api.dart';
import 'package:krishimandi/services/customer_service.dart';
import 'package:krishimandi/services/sync_service.dart';
import 'package:krishimandi/services/user_service.dart';
import 'package:krishimandi/utils/app_helper.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/utils/db_helper.dart';

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
      } catch (_) {
        emit(const LoginFailure(
            error:
                'Login failed. Please check your mobile number and password.'));
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
      } catch (_) {
        emit(const LoginCustomerFailure(
            error: 'Login failed. Please check your mandi and mobile number.'));
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

        await VegetableDAO().syncVegetables();
        await ProductDAO().productsSync();
        await ChargeTypeDAO().insertDefaultCharges();

        emit(SyncLoading());
        await SyncService.instance.connectAndSync();
        emit(LoginSuccess(user: user));
      } catch (_) {
        emit(const LoginFailure(error: 'Signup failed. Please try again.'));
      }
    });

    on<LogoutSubmit>((event, emit) async {
      try {
        final pendingCount = await SyncService.instance.pendingRecordCount();
        if (pendingCount > 0) {
          emit(LogoutBlocked(pendingCount: pendingCount));
          return;
        }
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
