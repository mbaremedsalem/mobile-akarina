import 'package:intl/intl.dart';  
import 'package:flutter/material.dart';
import 'package:akarina/data/data_providers/network_service.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchConversationAndMessages(); // Fetch conversation and messages when the page loads
  }

  void _fetchConversationAndMessages() {
    setState(() {
      futureConversation = NetworkService().getConversation(widget.participantId, context);
      futureConversation.then((conversationData) {
        int conversationId = conversationData['id'];
        _fetchMessages(conversationId); // Fetch messages for the conversation
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $error')),
        );
      });
    });
  }

  // Fetch messages for the conversation
  void _fetchMessages(int conversationId) async {
    try {
      List<dynamic> fetchedMessages = await NetworkService().fetchMessages(conversationId, context);
      setState(() {
        messages = fetchedMessages.reversed.toList(); // Reverse the messages to show the latest at the bottom
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des messages: $e')),
      );
    }
  }

  // Send a message and refresh the messages
  void _sendMessage(int conversationId) async {
    if (messageController.text.isNotEmpty) {
      try {
        await NetworkService().sendMessage(conversationId, messageController.text, context);
        messageController.clear();  // Clear input field after sending
        _fetchMessages(conversationId);  // Refresh messages after sending
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi du message: $e')),
        );
      }
    }
  }
  String _formatTimestamp(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('HH:mm').format(dateTime);  // Display only hours and minutes
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.participantImage), // Affiche l'image du participant dans l'AppBar
            ),
            const SizedBox(width: 10),
            Text(widget.participantName), // Affiche le nom du participant
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
                // Messages list
                Expanded(
                  child: messages.isEmpty
                      ? const Center(child: Text('Pas de messages pour cette conversation.'))
                      : ListView.builder(
                          reverse: true, // Show latest messages at the bottom
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
                // Input field for sending a new message
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
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
