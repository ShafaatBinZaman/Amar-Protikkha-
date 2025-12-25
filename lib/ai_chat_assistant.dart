import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIChatAssistant {
  // Replace with your computer's local IP address if you're using a physical device
  final String apiUrl = "http://192.168.0.163:8080/get";  // Update with your local IP address

  // Function to send the user's message and get the chatbot's response
  Future<String> getChatbotResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"msg": message}), // Sending the message in JSON format
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['answer']; // Extracting the answer from the response
      } else {
        throw Exception("Failed to load response");
      }
    } catch (e) {
      return "Error: $e"; // Return an error message if something goes wrong
    }
  }
}

class AIChatPage extends StatefulWidget {
  const AIChatPage({Key? key}) : super(key: key);

  @override
  _AIChatPageState createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _controller = TextEditingController(); // Controller for the input field
  String _chatResponse = ""; // Variable to store the chatbot's response

  // Function to send the message and display the response
  void _sendMessage() async {
    if (_controller.text.isEmpty) {
      setState(() {
        _chatResponse = "Please enter a message."; // Show a message if the input is empty
      });
      return;
    }

    AIChatAssistant aiChat = AIChatAssistant();
    String userMessage = _controller.text; // Get the message from the user input

    try {
      // Get the response from the chatbot
      String response = await aiChat.getChatbotResponse(userMessage);

      // Update the UI with the chatbot's response
      setState(() {
        _chatResponse = response;
      });
    } catch (e) {
      setState(() {
        _chatResponse = "Error: Unable to fetch response"; // Display an error message if the request fails
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chat Assistant"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            // Text input field to type the message
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type your message",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage, // Send the message when the send button is pressed
                ),
              ),
              onSubmitted: (value) {
                _sendMessage(); // Send the message when the enter key is pressed
              },
            ),
            SizedBox(height: 20),
            // Display the chatbot's response
            if (_chatResponse.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _chatResponse,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}