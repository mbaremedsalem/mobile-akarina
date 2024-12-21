import 'package:akarina/business_logic/cubit/layout_cubit.dart';
import 'package:akarina/business_logic/cubit/layout_state.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/chat/user.dart';
import 'package:akarina/presentations/screens/localisation/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Layout extends StatelessWidget {
  const Layout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>LayoutCubit(),
      child: BlocConsumer<LayoutCubit,LayoutStates>(
        listener: (context,state){},
        builder: (context,state){
          var cubit = LayoutCubit.get(context);
          return Scaffold(
            appBar: AppBar(
              leading:  Padding(
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.asset(
                    'assets/svg/logo.svg',
                  ),
              ),
              actions: [
                IconButton(onPressed: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => UserListPage()));
                },
                  icon: const Icon(
                    IconBroken.Chat,
                    size: 32,
                    color: Colors.black,
                ),
                ),

                IconButton(onPressed: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (context) =>  Location()));
                  
                },
                  icon: const Icon(
                    IconBroken.Location,
                    size: 32,
                    color: Colors.black,
                ),
                )
              ],
            ),
            body: cubit.bottomScreen[cubit.currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              onTap: (index)
              {
                cubit.changeBottom(index);
              },
              currentIndex: cubit.currentIndex,
              selectedItemColor: Colors.black,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: cubit.currentIndex == 0?
                  const Icon(
                    IconBroken.Home,
                    color: pcolor,
                  ):
                  const Icon(
                    IconBroken.Home,  
                  ),
                  label: getTranslated(context, 'Accueil')!,
                ),
                BottomNavigationBarItem(
                  icon: cubit.currentIndex == 1?
                  const Icon(
                    IconBroken.Category,
                    color: pcolor,
                  ):
                  const Icon(
                    IconBroken.Category,  
                  ),
                    label: getTranslated(context, 'category')!,
                ),
                BottomNavigationBarItem(
                  icon: cubit.currentIndex == 2?
                  const Icon(
                    Icons.add,
                    color: pcolor,
                  ):
                  const Icon(
                    Icons.add,  
                  ),
                    label: getTranslated(context, 'add')!,
                ),
                BottomNavigationBarItem(
                icon: cubit.currentIndex == 3?
                  const Icon(
                    IconBroken.Filter,
                    color: pcolor,
                  ):
                  const Icon(
                    IconBroken.Filter,  
                  ),
                    label: getTranslated(context, 'My Home')!,
                ),
                BottomNavigationBarItem(
                icon: cubit.currentIndex == 4?
                  const Icon(
                    IconBroken.Profile,
                    color: pcolor,
                  ):
                  const Icon(
                    IconBroken.Profile,  
                  ),
                  label: getTranslated(context, 'profile')!,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}