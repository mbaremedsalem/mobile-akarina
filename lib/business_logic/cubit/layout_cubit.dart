import 'package:akarina/business_logic/cubit/layout_state.dart';
import 'package:akarina/business_logic/search/search_criteria.dart';
import 'package:akarina/presentations/screens/home/home.dart';
import 'package:akarina/presentations/screens/immobillier/immobilier_screen.dart';
import 'package:akarina/presentations/screens/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LayoutCubit extends Cubit<LayoutStates>
{
  LayoutCubit():super(LayoutInitialState());
  static LayoutCubit get(context) => BlocProvider.of(context);
  int currentIndex = 0;

  List<Widget> bottomScreen = [
    const Home(),
    const ImmobilierScreen(title: 'Immobilier', listenToGlobalSearch: true),
    const ImmobilierScreen(title: 'Vente', initialCriteria: SearchCriteria(typeTransaction: 'vente')),
    const ImmobilierScreen(title: 'Achat', initialCriteria: SearchCriteria(typeTransaction: 'location')),
    ProfilePage(),
  ];

  void changeBottom(int index)
  {
    currentIndex = index;
    emit(LayoutChangeBottomNavState());
  }

}