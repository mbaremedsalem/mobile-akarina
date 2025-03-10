// import 'package:akarina/data/data_providers/network_service.dart';
// import 'package:akarina/data/models/user.dart';
// import 'package:akarina/presentations/screens/chat/chat.dart';
// import 'package:flutter/material.dart';

// class UserListPage extends StatefulWidget {
//   @override
//   _UserListPageState createState() => _UserListPageState();
// }

// class _UserListPageState extends State<UserListPage> {
//   late Future<List<User>> futureUsers;

//   @override
//   void initState() {
//     super.initState();
//     futureUsers = NetworkService().fetchUsers(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Liste des utilisateurs'),
//       ),
//       body: FutureBuilder<List<User>>(
//         future: futureUsers,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Erreur: ${snapshot.error}'));
//           } else if (snapshot.hasData && snapshot.data!.isEmpty) {
//             return const Center(child: Text('Aucun utilisateur trouvé.'));
//           } else if (snapshot.hasData) {
//             List<User> users = snapshot.data!;

//             return ListView.builder(
//               itemCount: users.length,
//               itemBuilder: (context, index) {
//                 User user = users[index];
                
//                 // Vérification et assignation de valeurs par défaut
//                 String userImage = (user.image != null && user.image!.isNotEmpty)
//                     ? user.image!
//                     : 'https://icons.veryicon.com/png/o/internet--web/web-interface-flat/6606-male-user.png';
//                 String userName = (user.nomComplet != null && user.nomComplet!.isNotEmpty)
//                     ? user.nomComplet!
//                     : 'Utilisateur inconnu';
//                 String userEmail = (user.email != null && user.email.isNotEmpty)
//                     ? user.email
//                     : 'Email non disponible';
                
//                 return Card(
//                   margin: const EdgeInsets.all(8.0),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundImage: NetworkImage(userImage),
//                     ),
//                     title: Text(userName),
//                     subtitle: Text(userEmail),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ChatPage(
//                             participantId: user.id,
//                             participantImage: userImage, 
//                             participantName: userName, 
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             );
//           }
//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }
// }

import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/models/user.dart';
import 'package:akarina/presentations/screens/chat/chat.dart';
import 'package:flutter/material.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late Future<List<User>> futureUsers;

  @override
  void initState() {
    super.initState();
    futureUsers = NetworkService().fetchUsers(context); // Récupère les utilisateurs depuis l'API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des utilisateurs'),
      ),
      body: FutureBuilder<List<User>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun utilisateur trouvé.'));
          } else if (snapshot.hasData) {
            List<User> users = snapshot.data!;

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                User user = users[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(

                    leading: CircleAvatar(
                    backgroundImage: user.image != null && user.image!.isNotEmpty
                        ? NetworkImage(user.image!)
                        : const NetworkImage('https://icons.veryicon.com/png/o/internet--web/web-interface-flat/6606-male-user.png'),
                    ),
                    title: Text(user.nomComplet!),
                    subtitle: Text(user.email),
                    onTap: () {
                      // Naviguer vers la page de chat avec l'image et l'ID du participant
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            participantId: user.id,
                            participantImage: user.image!, // Passer l'image
                            participantName: user.nomComplet!, // Passer le nom pour l'AppBar
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink(); // En cas d'absence de données
        },
      ),
    );
  }
}
