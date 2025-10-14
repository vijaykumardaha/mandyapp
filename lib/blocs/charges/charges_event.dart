import 'package:mandyapp/models/charge_model.dart';

abstract class ChargesEvent {}

class LoadCharges extends ChargesEvent {}

class AddCharge extends ChargesEvent {
  final Charge charge;
  AddCharge(this.charge);
}

class UpdateCharge extends ChargesEvent {
  final Charge charge;
  UpdateCharge(this.charge);
}

class DeleteCharge extends ChargesEvent {
  final int chargeId;
  DeleteCharge(this.chargeId);
}

class ToggleChargeStatus extends ChargesEvent {
  final Charge charge;
  ToggleChargeStatus(this.charge);
}
