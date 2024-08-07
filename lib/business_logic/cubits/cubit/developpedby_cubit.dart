import 'package:akarina/business_logic/cubits/cubit/developpedby_state.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class DevelopedbyCubit extends Cubit<DevelopedbyState> {
  Repository? repository;
  DevelopedbyCubit({this.repository}) : super(DevelopedbyInitial());

  void developedBy() async {
    emit(DevelopedByLoading());
    try {
      final message = await repository!.developedBy();
      String? developedBy = message['message'];
      // print(developedBy);
      if (developedBy != null && developedBy != '') {
        emit(DevelopedBySuccess(developedBy: developedBy));
      } else {
        emit(DevelopedByError());
      }
    } catch (e) {
      emit(DevelopedByError());
    }
  }
}
