import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankingAssistantService {
  static final BankingAssistantService _instance =
      BankingAssistantService._internal();
  factory BankingAssistantService() => _instance;
  BankingAssistantService._internal();

  // Cohere API configuration
  static const String _cohereApiUrl = 'https://api.cohere.ai/v1/chat';
  static const String _apiKey = 'UmX0WtC8B33CkkVC9i0g8WXhDoioOoMjMRHPW9Hm';

  // Banking context for Cohere
  static const String _bankingContext = '''
You are a helpful banking assistant for a student wallet app called Safe Budget. You should:

1. Only answer questions related to banking, finance, money management, and financial literacy
2. Provide clear, concise, and accurate information
3. Use simple language that students can understand
4. Focus on topics like:
   - Bank accounts (savings, checking, CDs, money market)
   - Banking procedures (opening accounts, transfers, deposits, withdrawals)
   - Financial concepts (interest rates, compound interest, credit scores)
   - Security and fraud protection
   - Budgeting and money management
   - Loans and mortgages
   - Investment basics
   - Fee avoidance strategies
   - Student-specific financial advice

5. If asked about non-banking topics, politely redirect to banking-related questions
6. Keep responses under 200 words for readability
7. Use bullet points when appropriate for better organization

Remember: You are specifically designed to help students with their banking and financial questions.
''';

  Future<String> getBankingResponse(String userQuestion) async {
    try {
      final response = await http.post(
        Uri.parse(_cohereApiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': userQuestion,
          'preamble': _bankingContext,
          'model': 'command',
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiResponse = data['text'] ?? 'No response from AI';

        // Save the conversation to Firestore
        await _saveConversation(userQuestion, aiResponse);

        return aiResponse;
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Error connecting to AI service: $e';
    }
  }

  // Save conversation to Firestore
  Future<void> _saveConversation(String question, String answer) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_conversations')
          .add({
            'question': question,
            'answer': answer,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // Silently fail - don't interrupt the chat if saving fails
    }
  }

  // Get conversation history from Firestore
  Future<List<Map<String, dynamic>>> getConversationHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('ai_conversations')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'question': data['question'] ?? '',
          'answer': data['answer'] ?? '',
          'timestamp': data['timestamp']?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Clear conversation history from Firestore
  Future<void> clearConversationHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('ai_conversations')
              .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Silently fail
    }
  }
}
