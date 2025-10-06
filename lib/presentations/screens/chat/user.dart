import 'package:akarina/data/data_providers/network_service.dart';
import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/data/models/user.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
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
                leading: IconButton(
          icon: Icon(
            Localizations.localeOf(context).languageCode == 'ar' 
              ? IconBroken.Arrow___Right_2 // Icône pour l'arabe (flèche à droite)
              : IconBroken.Arrow___Left_2, // Icône pour le français (flèche à gauche)
              color: kBlackColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(getTranslated(context, "Liste des utilisateurs")!,style: TextStyle(color: kBlackColor),),
      ),
      body: FutureBuilder<List<User>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return  Center(child: Text(getTranslated(context, "Aucun utilisateur trouvé.")!));
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
                    backgroundImage: NetworkImage(
                      user.image?.isNotEmpty == true
                          ? user.image!
                          : 'https://icons.veryicon.com/png/o/internet--web/web-interface-flat/6606-male-user.png',
                    ),
                  ),
                  title: Text(
                    user.nomComplet?.isNotEmpty == true
                        ? user.nomComplet!
                        : 'Utilisateur inconnu',
                  ),
                  subtitle: Text(
                    user.email?.isNotEmpty == true
                        ? user.email!
                        : 'Email non disponible',
                  ),
                  onTap: () {
                    // Valeurs par défaut pour l'image et le nom
                    final participantImage = user.image?.isNotEmpty == true
                        ? user.image!
                        : 'https://icons.veryicon.com/png/o/internet--web/web-interface-flat/6606-male-user.png';

                    final participantName = user.nomComplet?.isNotEmpty == true
                        ? user.nomComplet!
                        : 'Utilisateur inconnu';

                    // Naviguer vers la page de chat avec l'image et l'ID du participant
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          participantId: user.id,
                          participantImage: participantImage, // Utiliser la valeur par défaut si nécessaire
                          participantName: participantName, // Utiliser la valeur par défaut si nécessaire
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
