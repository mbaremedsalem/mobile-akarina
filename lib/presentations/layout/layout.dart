import 'package:akarina/business_logic/cubit/layout_cubit.dart';
import 'package:akarina/business_logic/cubit/layout_state.dart';
import 'package:akarina/business_logic/search/search_criteria.dart';
import 'package:akarina/data/data_providers/account_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/services/notification_store.dart';
import 'package:akarina/presentations/components/search/search_criteria_sheet.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:akarina/presentations/screens/immobillier/ajouter_bien.dart';
import 'package:akarina/presentations/screens/localisation/localization.dart';
import 'package:akarina/presentations/screens/login/index_login.dart';
import 'package:akarina/presentations/screens/notification/notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Layout extends StatelessWidget {
  const Layout({super.key});

  /// Ajouter une annonce est réservé aux gestionnaires connectés
  /// (`is_staff: true` sur /api/profil/, admin-akarina).
  Future<void> _handleAddAnnonceTap(BuildContext context) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "admin_token");
    if (!context.mounted) return;

    if (token == null) {
      _showLoginRequiredDialog(context);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? profile;
    try {
      profile = await AccountService().fetchProfile(token);
    } catch (_) {
      profile = null;
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // ferme le spinner

    if (profile != null && profile['is_staff'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AjouterBienScreen(adminToken: token)),
      );
    } else {
      _showAccessDeniedDialog(context);
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getTranslated(context, 'Connexion requise')!),
        content: Text(getTranslated(context, 'Vous devez être connecté pour ajouter une annonce.')!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(getTranslated(context, 'Annuler')!),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: pcolor, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IndexLogin()));
            },
            child: Text(getTranslated(context, 'Se connecter')!),
          ),
        ],
      ),
    );
  }

  void _showAccessDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getTranslated(context, 'Accès refusé')!),
        content: Text(getTranslated(context, "Seuls les gestionnaires peuvent ajouter une annonce.")!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(getTranslated(context, 'OK')!),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSearchTap(BuildContext context) async {
    final criteria = await showSearchCriteriaSheet(context, simple: true);
    if (criteria == null) return;
    ImmobilierSearchBus.publish(criteria);
    if (context.mounted) {
      LayoutCubit.get(context).changeBottom(1);
    }
  }

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
                    color: pcolor,
                  ),
              ),
              actions: [
                IconButton(onPressed: ()
                {
                  _handleSearchTap(context);
                },
                  tooltip: getTranslated(context, 'Rechercher'),
                  icon: const Icon(
                    Icons.search,
                    size: 28,
                    color: Colors.black,
                ),
                ),

                IconButton(onPressed: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
                },
                  tooltip: getTranslated(context, 'Notifications'),
                  icon: ValueListenableBuilder<int>(
                    valueListenable: NotificationStore.unreadCountNotifier,
                    builder: (context, unread, _) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          IconBroken.Notification,
                          size: 32,
                          color: Colors.black,
                        ),
                        if (unread > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                IconButton(onPressed: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (context) =>  Location()));

                },
                  tooltip: getTranslated(context, 'Localisation'),
                  icon: const Icon(
                    IconBroken.Location,
                    size: 32,
                    color: Colors.black,
                ),
                )
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _handleAddAnnonceTap(context),
              backgroundColor: pcolor,
              tooltip: getTranslated(context, 'Ajouter une annonce'),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: cubit.bottomScreen[cubit.currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              onTap: (index) {
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
                  Icon(
                    Icons.apartment_rounded,
                    color: pcolor,
                  ):
                  const Icon(
                    Icons.apartment_rounded,
                  ),
                    label: getTranslated(context, 'Immobilier')!,
                ),
                BottomNavigationBarItem(
                  icon: cubit.currentIndex == 2?
                  Icon(
                    Icons.sell_rounded,
                    color: pcolor,
                  ):
                  const Icon(
                    Icons.sell_outlined,
                  ),
                    label: getTranslated(context, 'Vente')!,
                ),
                BottomNavigationBarItem(
                icon: cubit.currentIndex == 3?
                  Icon(
                    Icons.shopping_bag_rounded,
                    color: pcolor,
                  ):
                  const Icon(
                    Icons.shopping_bag_outlined,
                  ),
                    label: getTranslated(context, 'Achat')!,
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
