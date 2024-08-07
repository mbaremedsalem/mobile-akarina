
import 'package:akarina/business_logic/cubits/cubit/facturier_state.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';




class FacturierCubit extends Cubit<FacturierState> {
  Repository? repository;
  FacturierCubit({this.repository}) : super(FacturierInitial());

  void fetchfacturier() {
    emit(FacturierLoading());
    repository!.facturier().then((value) {
      // final String encodeddata = Facturier.encode(value);
      // print(value);
      // storage.write(key: 'facturier', value: encodeddata);
      emit(FacturierSuccess(facturier: value));
    }).onError((dynamic error, stackTrace) {
      emit(FacturierError());
    });
  }
}
