import 'dart:io';
import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser =
      ChatUser(id: "1", firstName: "Gemini", profileImage: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQb8pqb7raVEvKDdS6saUQ2ZNpiqjqkEU9HnQ&s");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration:const  BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/gemini.jpg"),

              fit: BoxFit.cover,
            ),
          ),
          child: _builtUI()),
    );
  }

  Widget _builtUI() {
    return DashChat(
      inputOptions: InputOptions(
        trailing: [
          IconButton(onPressed: _sendMediaMessage, icon: const Icon(Icons.image,color: Colors.white,)),
        ]
      ),
        currentUser: currentUser, onSend: _sendMessage, messages: messages,

    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      List <Uint8List>? images;
      if(chatMessage.medias?.isNotEmpty??false){
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];

      }
      String question = chatMessage.text;
      gemini.streamGenerateContent(question,images: images).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
            lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold(
              "",
                  (previousValue, currentValue) =>
              "$previousValue ${currentValue.text}") ??
              "";
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!,...messages];
          });
        } else {
          String response = event.content?.parts?.fold(
                  "",
                  (previousValue, currentValue) =>
                      "$previousValue ${currentValue.text}") ??
              "";
          ChatMessage message = ChatMessage(
              user: geminiUser, createdAt: DateTime.now(), text: response);
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }
  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);

    ChatMessage chatMessage = ChatMessage(user: currentUser, createdAt: DateTime.now(),text: "Describe this picture?",medias: [
      ChatMedia(url:file!.path, fileName: "", type: MediaType.image),
    ]);
    _sendMessage(chatMessage);

  }
}
