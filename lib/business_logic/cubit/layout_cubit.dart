import 'package:akarina/business_logic/cubit/layout_state.dart';
import 'package:akarina/presentations/screens/cart/my_home.dart';
import 'package:akarina/presentations/screens/category/category.dart';
import 'package:akarina/presentations/screens/home/home.dart';
import 'package:akarina/presentations/screens/immobillier/add_immobilier.dart';
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
    const Category(),
    // const ChatPage(),
     PostAnnonceScreen(),
     MyHome(),
    const Profile(),
  ];

  void changeBottom(int index)
  {
    currentIndex = index;
    emit(LayoutChangeBottomNavState());
  }

}