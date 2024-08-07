
import 'package:akarina/business_logic/cubits/cubit/facturier_cubit.dart';
import 'package:akarina/business_logic/cubits/cubit/login_cubit.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:akarina/presentations/screens/login/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouter {
  Repository? repository;
  // late TranactionsCubitCubit tranactionsCubitCubit;
  // late BalanceCubit balanceCubit;

  // late CagnotteCubit cagnotteCubit;

  // late PaiementdemaseeCubit paiementdemaseeCubit;

  late FacturierCubit facturierCubit;

  // late DevelopedbyCubit developedbyCubit;

  // late ChangeLangueCubit changeLangueCubit;

  // late RetraitgabCubit retraitgabCubit;

  // late ListCartesCubit listCartesCubit;

  // late NotficationsCubit notficationsCubit;

  // late ProfileCubit profileCubit;

  // late ListDernierBeneficiaireCubit listDernierBeneficiaireCubit;

  // late HistoriquesearshCubit historiquesearshCubit;

  // late RechargeTelAutresPaysCubit rechargeTelAutresPaysCubit;

  // late ConsultVignetteGuineeCubit consultVignetteGuineeCubit;

  // late ConsultGuineeInfoCubit consultGuineeInfoCubit;

  // late PaiementVignetteGuineeCubit paiementVignetteGuineeCubit;

  // late ConsultPaymentEtatCubit consultPaymentEtatCubit;

  // late CreditTelephoneCubit creditTelephoneCubit;

  // late ListBanqueInteroperableCubit listBanqueInteroperableCubit;

  // late FetchFraisCubit fetchFraisCubit;

  AppRouter() {
    repository = Repository(networkService: NetworkService());
    // tranactionsCubitCubit = TranactionsCubitCubit(
    //   repository: repository,
    // );
    // balanceCubit = BalanceCubit(repository: repository);
    // paiementdemaseeCubit = PaiementdemaseeCubit(repository: repository);
    // cagnotteCubit = CagnotteCubit(repository: repository);
    facturierCubit = FacturierCubit(repository: repository);
    // developedbyCubit = DevelopedbyCubit(repository: repository);
    // changeLangueCubit = ChangeLangueCubit(repository: repository);
    // retraitgabCubit = RetraitgabCubit(repository: repository);
    // listCartesCubit = ListCartesCubit(repository: repository);
    // notficationsCubit = NotficationsCubit(repository: repository);
    // profileCubit = ProfileCubit(repository: repository);
    // historiquesReferenceCubit =
    //     HistoriquesReferenceCubit(repository: repository);
    // listDernierBeneficiaireCubit =
    //     ListDernierBeneficiaireCubit(repository: repository);
    // historiquesearshCubit = HistoriquesearshCubit(repository: repository);
    // rechargeTelAutresPaysCubit =
    //     RechargeTelAutresPaysCubit(repository: repository);
    // consultVignetteGuineeCubit =
    //     ConsultVignetteGuineeCubit(repository: repository);
    // paiementVignetteGuineeCubit =
    //     PaiementVignetteGuineeCubit(repository: repository);
    // consultGuineeInfoCubit = ConsultGuineeInfoCubit(repository: repository);
    // consultPaymentEtatCubit = ConsultPaymentEtatCubit(repository: repository);
    // creditTelephoneCubit = CreditTelephoneCubit(repository: repository);
    // listBanqueInteroperableCubit =
    //     ListBanqueInteroperableCubit(repository: repository);
    // fetchFraisCubit = FetchFraisCubit(repository: repository);
  }

  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case "login":
        return MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(
                      value: facturierCubit,
                    ),
                    BlocProvider(
                      create: (context) => LoginCubit(
                        repository: repository,
                      ),
                    ),
                  ],
                  child: Login(),
                )
                );
      // case "restore_password":
      //   return MaterialPageRoute(builder: (_) {
      //     // final args = settings.arguments as String?;
      //     return MultiBlocProvider(
      //       providers: [
      //         BlocProvider(
      //           create: (context) => RestorePasswordCubit(
      //             repository: repository,
      //           ),
      //         ),
      //       ],
      //       child: RestorePassword(
      //           // phoneNumber: args,
      //           ),
      //     );
      //   });

      // case "home":
      //   return MaterialPageRoute(
      //     builder: (_) => MultiBlocProvider(providers: [
      //       BlocProvider(
      //         create: (context) => LogoutCubit(
      //           repository: repository,
      //         ),
      //       ),
      //       BlocProvider.value(
      //         value: facturierCubit,
      //       ),
      //       BlocProvider.value(
      //         value: tranactionsCubitCubit,
      //       ),
      //       BlocProvider.value(
      //         value: balanceCubit,
      //       ),
      //       BlocProvider.value(
      //         value: developedbyCubit,
      //       ),
      //       BlocProvider.value(
      //         value: changeLangueCubit,
      //       ),
      //     ], child: HomeScreen()),
      //   );




      default:
        return null;
    }
  }

  void dispose() {
    // tranactionsCubitCubit.close();
    // balanceCubit.close();
    // cagnotteCubit.close();
    // paiementdemaseeCubit.close();
    facturierCubit.close();
  }
}
