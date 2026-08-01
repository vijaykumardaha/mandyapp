import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/dao/customer_dao.dart';
import 'package:krishimandi/models/customer_model.dart';
import 'package:krishimandi/services/customer_service.dart';
import 'package:krishimandi/utils/app_helper.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerDAO contactDAO = CustomerDAO();

  CustomerBloc() : super(CustomerInitial()) {
    on<SyncCustomer>((event, emit) async {
      try {
        emit(CustomerLoading());
        await contactDAO.bulkInsert(event.customers);
        add(const FetchCustomer(query: ''));
      } catch (error) {
        emit(const SyncCustomerError(
            errorMsg: 'Something went wrong. Please try again.'));
      }
    });

    on<FetchCustomer>((event, emit) async {
      try {
        emit(CustomerLoading());
        final contacts = await contactDAO.getCustomers();
        emit(
            CustomerLoaded(customers: _filterCustomers(contacts, event.query)));
      } catch (error) {
        emit(const SyncCustomerError(
            errorMsg: 'Something went wrong. Please try again.'));
      }
    });

    on<AddCustomer>((event, emit) async {
      try {
        emit(CustomerLoading());
        await contactDAO.insertCustomer(
          Customer(
            name: event.name.trim(),
            phone: event.phone.trim(),
            productIds: event.productIds,
          ),
        );
        final contacts = await contactDAO.getCustomers();
        emit(
            CustomerLoaded(customers: _filterCustomers(contacts, event.query)));
      } catch (error) {
        emit(const SyncCustomerError(
            errorMsg: 'Something went wrong. Please try again.'));
      }
    });

    on<DeleteCustomer>((event, emit) async {
      try {
        emit(CustomerLoading());
        await contactDAO.deleteCustomer(event.customerId);
        final contacts = await contactDAO.getCustomers();
        emit(
            CustomerLoaded(customers: _filterCustomers(contacts, event.query)));
      } catch (error) {
        emit(const SyncCustomerError(
            errorMsg: 'Something went wrong. Please try again.'));
      }
    });

    on<UpdateCustomer>((event, emit) async {
      try {
        emit(CustomerLoading());
        await contactDAO.updateCustomer(event.customer);
        final contacts = await contactDAO.getCustomers();
        emit(
            CustomerLoaded(customers: _filterCustomers(contacts, event.query)));
      } catch (error) {
        emit(const SyncCustomerError(
            errorMsg: 'Something went wrong. Please try again.'));
      }
    });

    on<LoadCurrentCustomer>(_onLoadCurrentCustomer);
    on<SyncCurrentCustomer>(_onSyncCurrentCustomer);
  }

  Future<void> _onLoadCurrentCustomer(
    LoadCurrentCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CurrentCustomerLoading());
    try {
      final customer = await _loadCurrentCustomer();
      emit(CurrentCustomerLoaded(customer: customer));
    } catch (e) {
      emit(CurrentCustomerError(e.toString()));
    }
  }

  Future<void> _onSyncCurrentCustomer(
    SyncCurrentCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    final current = state is CurrentCustomerLoaded
        ? (state as CurrentCustomerLoaded).customer
        : state is CurrentCustomerSyncSuccess
            ? (state as CurrentCustomerSyncSuccess).customer
            : null;

    emit(CurrentCustomerSyncLoading(customer: current));
    try {
      final tables = await CustomerService.instance.sync();
      if (tables == null) {
        emit(const CurrentCustomerError('Sync failed'));
        return;
      }
      final customer = await _loadCurrentCustomer();
      emit(CurrentCustomerSyncSuccess(customer: customer));
    } catch (e) {
      emit(CurrentCustomerError(e.toString()));
    }
  }

  Future<Customer?> _loadCurrentCustomer() async {
    final userData = await AppHelper.getPreferences('user');
    if (userData == null) return null;
    final user = userData as Map<String, dynamic>;
    final mobile = user['mobile'] as String?;
    if (mobile == null || mobile.isEmpty) return null;
    return await contactDAO.getCustomerByMobile(mobile);
  }

  List<Customer> _filterCustomers(List<Customer> contacts, String query) {
    final normalizedQuery = query.toLowerCase();
    return contacts.where((item) {
      final name = item.name?.toLowerCase() ?? '';
      final phone = item.phone ?? '';
      if (normalizedQuery.isEmpty) return true;
      return name.contains(normalizedQuery) || phone.contains(normalizedQuery);
    }).toList();
  }
}
