

import 'package:akarina/data/models/facture.dart';
import 'package:equatable/equatable.dart';


abstract class FacturierState extends Equatable {
  const FacturierState();

  @override
  List<Object> get props => [];
}

class FacturierInitial extends FacturierState {}

class FacturierLoading extends FacturierState {}

class FacturierError extends FacturierState {}

class FacturierSuccess extends FacturierState {
  final List<Factures>? facturier;

  FacturierSuccess({this.facturier});
}
