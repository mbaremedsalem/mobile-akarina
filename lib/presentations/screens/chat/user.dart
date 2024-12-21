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
        title: Text('Liste des utilisateurs'),
      ),
      body: FutureBuilder<List<User>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Center(child: Text('Aucun utilisateur trouvé.'));
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
                      backgroundImage: NetworkImage(user.image), // Affiche l'image de l'utilisateur
                    ),
                    title: Text(user.nomComplet),
                    subtitle: Text(user.email),
                    onTap: () {
                      // Naviguer vers la page de chat avec l'image et l'ID du participant
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            participantId: user.id,
                            participantImage: user.image, // Passer l'image
                            participantName: user.nomComplet, // Passer le nom pour l'AppBar
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
          return SizedBox.shrink(); // En cas d'absence de données
        },
      ),
    );
  }
}
