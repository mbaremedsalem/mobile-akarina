
import 'package:akarina/business_logic/cubits/cubit/facturier_cubit.dart';
import 'package:akarina/business_logic/cubits/cubit/login_cubit.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/repositories/repository.dart';
import 'package:akarina/presentations/screens/login/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// class AppRouter {
//   Repository? repository;

//   late FacturierCubit facturierCubit;


//   AppRouter() {
//     repository = Repository(networkService: NetworkService());

//     facturierCubit = FacturierCubit(repository: repository);

//   }

//   Route? generateRoute(RouteSettings settings) {
//     switch (settings.name) {
//       case "login":
//         return MaterialPageRoute(
//             builder: (_) => MultiBlocProvider(
//                   providers: [
//                     BlocProvider.value(
//                       value: facturierCubit,
//                     ),
//                     BlocProvider(
//                       create: (context) => LoginCubit(
//                         repository: repository,
//                       ),
//                     ),
//                   ],
//                   child: Login(),
//                 )
//                 );

//       default:
//         return null;
//     }
//   }

//   void dispose() {
//     // tranactionsCubitCubit.close();
//     // balanceCubit.close();
//     // cagnotteCubit.close();
//     // paiementdemaseeCubit.close();
//     facturierCubit.close();
//   }
// }





// import 'package:akarina/business_logic/cubits/cubit/facturier_cubit.dart';
// import 'package:akarina/business_logic/cubits/cubit/login_cubit.dart';
// import 'package:akarina/data/data_providers/network_service.dart';
// import 'package:akarina/data/repositories/repository.dart';
// import 'package:akarina/presentations/screens/login/login.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouter {
  Repository? repository;


  late FacturierCubit facturierCubit;





  AppRouter() {
    repository = Repository(networkService: NetworkService());

    facturierCubit = FacturierCubit(repository: repository);


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



      default:
        return null;
    }
  }

  void dispose() {

    facturierCubit.close();
  }
}
