import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/dao/customer_dao.dart';
import 'package:mandyapp/models/customer_model.dart';

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
        emit(SyncCustomerError(errorMsg: error.toString()));
      }
    });

    on<FetchCustomer>((event, emit) async {
      try {
        emit(CustomerLoading());
        final contacts = await contactDAO.getCustomers();
        emit(CustomerLoaded(customers: _filterCustomers(contacts, event.query)));
      } catch (error) {
        emit(SyncCustomerError(errorMsg: error.toString()));
      }
    });

    on<AddCustomer>((event, emit) async {
      try {
        emit(CustomerLoading());
        await contactDAO.insertCustomer(
          Customer(
            name: event.name.trim(),
            phone: event.phone.trim(),
            borrowAmount: event.borrowAmount,
            advancedAmount: event.advancedAmount,
          ),
        );
        final contacts = await contactDAO.getCustomers();
        emit(CustomerLoaded(customers: _filterCustomers(contacts, event.query)));
      } catch (error) {
        emit(SyncCustomerError(errorMsg: error.toString()));
      }
    });

    on<DeleteCustomer>((event, emit) async {
      try {
        emit(CustomerLoading());
        await contactDAO.deleteCustomer(event.customerId);
        final contacts = await contactDAO.getCustomers();
        emit(CustomerLoaded(customers: _filterCustomers(contacts, event.query)));
      } catch (error) {
        emit(SyncCustomerError(errorMsg: error.toString()));
      }
    });

    on<UpdateCustomer>((event, emit) async {
      try {
        emit(CustomerLoading());
        await contactDAO.updateCustomer(event.customer);
        final contacts = await contactDAO.getCustomers();
        emit(CustomerLoaded(customers: _filterCustomers(contacts, event.query)));
      } catch (error) {
        emit(SyncCustomerError(errorMsg: error.toString()));
      }
    });
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

