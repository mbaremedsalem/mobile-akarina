import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:akarina/data/data_providers/network_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  final int participantId;
  final String participantImage;
  final String participantName;

  const ChatPage({
    Key? key,
    required this.participantId,
    required this.participantImage,
    required this.participantName,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<Map<String, dynamic>> futureConversation;
  List<dynamic> messages = [];
  final TextEditingController messageController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchConversationAndMessages();
  }

  void _fetchConversationAndMessages() {
    setState(() {
      futureConversation = NetworkService().getConversation(widget.participantId, context);
      futureConversation.then((conversationData) {
        int conversationId = conversationData['id'];
        _fetchMessages(conversationId);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $error')),
        );
      });
    });
  }

  void _fetchMessages(int conversationId) async {
    try {
      List<dynamic> fetchedMessages = await NetworkService().fetchMessages(conversationId, context);
      setState(() {
        messages = fetchedMessages.reversed.toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des messages: $e')),
      );
    }
  }

  void _sendMessage(int conversationId) async {
    if (messageController.text.isNotEmpty) {
      try {
        await NetworkService().sendMessage(conversationId, messageController.text, context);
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
    final XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        File imageFile = File(pickedFile.path);
        await NetworkService().sendImage(conversationId, imageFile, context);
        _fetchMessages(conversationId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi de l\'image: $e')),
        );
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.participantImage),
            ),
            const SizedBox(width: 10),
            Text(widget.participantName),
          ],
        ),
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
                  child: messages.isEmpty
                      ? const Center(child: Text('Pas de messages pour cette conversation.'))
                      : ListView.builder(
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isSender = message['sender'] == widget.participantId;

                            return Align(
                              alignment: isSender ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSender ? Colors.grey[300] : Colors.blue[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (message['type'] == 'image')
                                      Image.network(
                                        message['content'],
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      Text(
                                        message['content'],
                                        style: TextStyle(
                                          color: isSender ? Colors.black : Colors.white,
                                        ),
                                      ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _formatTimestamp(message['timestamp']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSender ? Colors.black54 : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                            labelText: 'Envoyer un message...',
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
