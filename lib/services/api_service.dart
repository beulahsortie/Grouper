    
  
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/venue.dart';

class ApiService {
  // Use environment override or default to emulator-friendly host
  static const String _defaultBase = 'http://localhost:3000/api';
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBase);

  static Future<List<Category>> getCategories() async {
    final uri = Uri.parse('$baseUrl/categories');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List data = json.decode(res.body) as List;
      return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load categories: ${res.statusCode}');
  }

  
      // Explore venues
  static Future<List<dynamic>> getExploreVenues() async {
        final uri = Uri.parse('$baseUrl/explore');
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          return json.decode(res.body) as List;
        }
        throw Exception('Failed to load explore venues: ${res.statusCode}');
      }

      // Conversations
  static Future<List<dynamic>> getConversations() async {
        final uri = Uri.parse('$baseUrl/conversations?userId=1');
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          return json.decode(res.body) as List;
        }
        throw Exception('Failed to load conversations: ${res.statusCode}');
      }

      // Messages
  static Future<List<dynamic>> getMessages(int conversationId) async {
        final uri = Uri.parse('$baseUrl/conversations/$conversationId/messages');
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          return json.decode(res.body) as List;
        }
        throw Exception('Failed to load messages: ${res.statusCode}');
      }

      // Send message
  static Future<void> sendMessage(int conversationId, int senderId, String text) async {
        final uri = Uri.parse('$baseUrl/conversations/$conversationId/messages');
        final res = await http.post(uri, body: json.encode({'sender_id': senderId, 'text': text}), headers: {'Content-Type': 'application/json'});
        if (res.statusCode != 200) {
          throw Exception('Failed to send message: ${res.statusCode}');
        }
      }

      // User profile
  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
        final uri = Uri.parse('$baseUrl/users/$userId');
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          return json.decode(res.body) as Map<String, dynamic>;
        }
        throw Exception('Failed to load user profile: ${res.statusCode}');
      }

  static Future<void> updateUserProfile(int userId, String email, String phone, String location) async {
        final uri = Uri.parse('$baseUrl/users/$userId');
        final res = await http.put(uri, body: json.encode({'email': email, 'phone': phone, 'location': location}), headers: {'Content-Type': 'application/json'});
        if (res.statusCode != 200) {
          throw Exception('Failed to update profile: ${res.statusCode}');
        }
      }

      // Auth login
  static Future<Map<String, dynamic>?> login(String email) async {
        final uri = Uri.parse('$baseUrl/auth/login');
        final res = await http.post(uri, body: json.encode({'email': email}), headers: {'Content-Type': 'application/json'});
        if (res.statusCode == 200) {
          return json.decode(res.body) as Map<String, dynamic>;
        }
        return null;
      }

  static Future<List<Venue>> getVenues() async {
    final uri = Uri.parse('$baseUrl/venues');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List data = json.decode(res.body) as List;
      return data.map((e) => Venue.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load venues: ${res.statusCode}');
  }

  // Order history (activities)
  static Future<List<dynamic>> getOrderHistory(int userId) async {
    final uri = Uri.parse('$baseUrl/bookings?userId=$userId');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return json.decode(res.body) as List;
    }
    throw Exception('Failed to load order history: \\${res.statusCode}');
  }

  // Create booking
    static Future<void> createBooking({required int userId, required int venueId, required double amount, String? date}) async {
      final uri = Uri.parse('$baseUrl/bookings');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'venue_id': venueId,
          'amount': amount,
          if (date != null) 'date': date,
        }),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('Failed to create booking: \\${res.statusCode}');
      }
    }
}
