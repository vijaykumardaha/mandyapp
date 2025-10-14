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
        List<Customer> contacts = await contactDAO.getCustomers();
        final filteredItems = contacts
            .where((item) =>
                item.name!.toLowerCase().contains(event.query.toLowerCase()) ||
                item.phone!.contains(event.query.toLowerCase()))
            .toList();
        emit(CustomerLoaded(customers: filteredItems));
      } catch (error) {
        emit(SyncCustomerError(errorMsg: error.toString()));
      }
    });
  }
}
