import 'package:akarina/data/localization/language_constants.dart';
import 'package:akarina/presentations/components/refreshable_widget.dart';
import 'package:akarina/presentations/components/no_internet_page.dart';
import 'package:akarina/presentations/constants/constants.dart';
import 'package:akarina/presentations/constants/icon_broken.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:akarina/data/services/connectivity_service.dart';

class ChatPage extends StatefulWidget {
  final int participantId;
  final String participantImage;
  final String participantName;

  const ChatPage({
    super.key,
    required this.participantId,
    required this.participantImage,
    required this.participantName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Future<Map<String, dynamic>> futureConversation = Future.value({});
  List<dynamic> messages = [];
  final TextEditingController messageController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();
  bool hasInternetConnection = true;

  int? conversationId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Vérifier la connectivité internet d'abord
    final hasConnection = await ConnectivityService.hasInternetConnection();
    setState(() {
      hasInternetConnection = hasConnection;
    });

    if (!hasConnection) {
      return; // Ne pas charger les données si pas de connexion
    }

    _fetchConversationAndMessages();
  }

  void _fetchConversationAndMessages() {
    setState(() {
      futureConversation =
          NetworkService().getConversation(widget.participantId, context);
      futureConversation.then((conversationData) {
        conversationId = conversationData['id'];
        _fetchMessages(conversationId ?? 0);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $error')),
        );
      });
    });
  }

  void _fetchMessages(int conversationId) async {
    try {
      List<dynamic> fetchedMessages =
          await NetworkService().fetchMessages(conversationId, context);

      // Transforme les messages pour s'assurer que l'image et le contenu sont bien définis
      List<Map<String, dynamic>> processedMessages =
          fetchedMessages.map((message) {
        return {
          'id': message['id'],
          'conversation': message['conversation'],
          'sender': message['sender'],
          'content': message['content'] ??
              '', // Assurer que le contenu textuel est bien géré
          'image': message['image'] ?? '', // Assurer que l'image est bien gérée
          'timestamp': message['timestamp'],
          'message_type': message['message_type'],
        };
      }).toList();

      setState(() {
        messages = processedMessages.reversed
            .toList(); // Afficher du plus ancien au plus récent
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la récupération des messages: $e')),
      );
    }
  }

  void _sendMessage(int conversationId) async {
    if (messageController.text.isNotEmpty) {
      try {
        await NetworkService()
            .sendMessage(conversationId, messageController.text, context);
        messageController.clear();
        _fetchMessages(conversationId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi du message: $e')),
        );
      }
    }
  }

  void _sendImage(int conversationId) async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles =
        await picker.pickMultiImage(); // Permet la sélection multiple

    if (pickedFiles.isNotEmpty) {
      List<File> images = pickedFiles.map((file) => File(file.path)).toList();

      if (images.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vous ne pouvez envoyer que 5 images maximum')),
        );
        return;
      }

      try {
        await NetworkService().sendImages(conversationId, images, context);
        _fetchMessages(conversationId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi de l\'image: $e')),
        );
      }
    }
  }

  void _blockUser() async {
    if (conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ID de conversation introuvable')),
      );
      return;
    }

    try {
      final url = Uri.parse(
          'https://akarina.shop/user/conversation/delete/$conversationId/');
      final response = await http.delete(url);
 
      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Utilisateur bloqué avec succès')),
        );
        Navigator.pop(
            context); // Tu peux changer cette logique selon ton besoin
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du blocage de l\'utilisateur')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  void _showBlockConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Voulez-vous vraiment bloquer cet utilisateur ?'),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
              },
            ),
            ElevatedButton(
              child: Text('Confirmer'),
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
                _blockUser(); // Appeler la fonction pour bloquer
              },
            ),
          ],
        );
      },
    );
  }

  void _sendVoice(int conversationId) async {
    // Add functionality to record and send voice messages
    // Placeholder implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enregistrement vocal à implémenter.')),
    );
  }

  String _formatTimestamp(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    // Afficher la page d'erreur de connexion si pas de connexion internet
    if (!hasInternetConnection) {
      return NoInternetPage(
        onRetry: () async {
          final hasConnection =
              await ConnectivityService.hasInternetConnection();
          setState(() {
            hasInternetConnection = hasConnection;
          });

          if (hasConnection) {
            _initializeData();
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Localizations.localeOf(context).languageCode == 'ar'
                ? IconBroken.Arrow___Right_2
                : IconBroken.Arrow___Left_2,
            color: kBlackColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                widget.participantImage.isNotEmpty
                    ? widget.participantImage
                    : 'https://icons.veryicon.com/png/o/internet--web/web-interface-flat/6606-male-user.png',
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.participantName.isNotEmpty
                  ? widget.participantName
                  : 'Utilisateur inconnu',
              style: TextStyle(color: kBlackColor),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            iconColor: kBlackColor,
            onSelected: (value) {
              if (value == 'block') {
                _showBlockConfirmationDialog(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'block',
                  child: Text('Bloquer cet utilisateur'),
                ),
              ];
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureConversation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final conversationId = snapshot.data!['id'];

            return Column(
              children: [
                Expanded(
                  child: RefreshableWidget(
                    onRefresh: () async {
                      if (conversationId != null) {
                        _fetchMessages(conversationId!);
                      }
                    },
                    child: messages.isEmpty
                        ? Center(
                            child: Text(getTranslated(context,
                                "Pas de messages pour cette conversation.")!))
                        : ListView.builder(
                            reverse: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isSender =
                                  message['sender'] == widget.participantId;

                              return Align(
                                alignment: isSender
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSender
                                        ? Colors.grey[300]
                                        : Colors.blue[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (message['message_type'] == 'image' &&
                                          message['image'].isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    FullScreenImage(
                                                        imageUrl:
                                                            message['image']),
                                              ),
                                            );
                                          },
                                          child: Image.network(
                                            message[
                                                'image'], // Affichage de l'image réduite
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey);
                                            },
                                          ),
                                        )
                                      else if (message['content']
                                          .isNotEmpty) // Afficher du texte si disponible
                                        Text(
                                          message['content'],
                                          style: TextStyle(
                                            color: isSender
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _formatTimestamp(message['timestamp']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSender
                                              ? Colors.black54
                                              : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo),
                        onPressed: () => _sendImage(conversationId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic),
                        onPressed: () => _sendVoice(conversationId),
                      ),
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            labelText: getTranslated(
                                context, "Envoyer un message...")!,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (snapshot.hasData) {
                            _sendMessage(conversationId);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('Aucune conversation trouvée.'));
        },
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          // Permet de zoomer et déplacer l'image
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image,
                  size: 100, color: Colors.white);
            },
          ),
        ),
      ),
    );
  }
}
