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
  static Future<List<dynamic>> getExploreVenues({double? lat, double? lng, double? radius}) async {
        String url = '$baseUrl/explore';
        if (lat != null && lng != null) {
          url += '?lat=$lat&lng=$lng&radius=${radius ?? 10}';
        }
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          return json.decode(res.body) as List;
        }
        throw Exception('Failed to load explore venues: ${res.statusCode}');
      }

      // Conversations
  static Future<List<dynamic>> getConversations(int userId) async {
        final uri = Uri.parse('$baseUrl/conversations?userId=$userId');
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

  static Future<void> updateUserProfile(int userId, String email, String phone, String location, {String? avatarUrl}) async {
        final uri = Uri.parse('$baseUrl/users/$userId');
        final body = <String, dynamic>{
          'email': email,
          'phone': phone,
          'location': location,
        };
        if (avatarUrl != null) body['avatar_url'] = avatarUrl;
        final res = await http.put(uri,
            body: json.encode(body),
            headers: {'Content-Type': 'application/json'});
        if (res.statusCode != 200) {
          throw Exception('Failed to update profile: ${res.statusCode}');
        }
      }

  // Auth
  static Future<Map<String, dynamic>?> login(String identifier, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'identifier': identifier, 'password': password}),
    );
    if (res.statusCode == 200) return json.decode(res.body) as Map<String, dynamic>;
    final err = json.decode(res.body);
    throw Exception(err['error'] ?? 'Login failed');
  }

  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email, 'password': password}),
    );
    if (res.statusCode == 201) return json.decode(res.body) as Map<String, dynamic>;
    final err = json.decode(res.body);
    throw Exception(err['error'] ?? 'Signup failed');
  }

  static Future<List<Venue>> getVenues({double? lat, double? lng}) async {
    String url = '$baseUrl/venues';
    if (lat != null && lng != null) {
      url += '?lat=$lat&lng=$lng&radius=10';
    }
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final List data = json.decode(res.body) as List;
      return data.map((e) => Venue.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load venues: ${res.statusCode}');
  }

  // Venues created by a user
  static Future<List<dynamic>> getUserVenues(int userId) async {
    final uri = Uri.parse('$baseUrl/venues?createdBy=$userId');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return json.decode(res.body) as List;
    }
    throw Exception('Failed to load user venues: ${res.statusCode}');
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
    static Future<void> createBooking({
        required int userId,
        required int venueId,
        String? time,
        String? description,
      }) async {
        final uri = Uri.parse('$baseUrl/bookings');
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': userId,
            'venue_id': venueId,
            'time': time ?? DateTime.now().toIso8601String(),
            'description': description ?? '',
          }),
        );
        if (res.statusCode != 200 && res.statusCode != 201) {
          throw Exception('Failed to create booking: ${res.statusCode}');
        }
      }

      // Add this method to your existing ApiService class

      static Future<Map<String, dynamic>> createVenue({
        required String name,
        required double price,
        required String imageUrl,
        String? address,
        double? latitude,
        double? longitude,
        int? categoryId,
        int? createdBy,
      }) async {
        final response = await http.post(
          Uri.parse('$baseUrl/venues'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'price': price,
            'image_url': imageUrl,
            if (address != null) 'address': address,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (categoryId != null) 'category_id': categoryId,
            if (createdBy != null) 'created_by': createdBy,
          }),
        );

        if (response.statusCode == 201) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? 'Failed to create venue');
        }
      }

  // ── Groups ──────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getUserGroups(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/groups'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Failed to load groups');
  }

  static Future<List<dynamic>> getGroups({
    required int venueId,
    required String date,
    required String startTime,
  }) async {
    final uri = Uri.parse(
        '$baseUrl/groups?venueId=$venueId&date=$date&startTime=$startTime');
    final res = await http.get(uri);
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Failed to load groups');
  }

  static Future<Map<String, dynamic>> getGroup(int groupId) async {
    final res = await http.get(Uri.parse('$baseUrl/groups/$groupId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load group');
  }

  static Future<int> createGroup({
    required int venueId,
    required String date,
    required String startTime,
    required int durationHours,
    required String name,
    String? description,
    required int maxMembers,
    int? createdBy,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'venueId': venueId,
        'date': date,
        'startTime': startTime,
        'durationHours': durationHours,
        'name': name,
        if (description != null) 'description': description,
        'maxMembers': maxMembers,
        if (createdBy != null) 'createdBy': createdBy,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body)['group_id'];
    throw Exception(jsonDecode(res.body)['error'] ?? 'Failed to create group');
  }

  static Future<void> joinGroup(int groupId, int userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['error'] ?? 'Failed to join group');
    }
  }

  static Future<void> leaveGroup(int groupId, int userId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/groups/$groupId/leave'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    if (res.statusCode != 200) throw Exception('Failed to leave group');
  }

  static Future<List<dynamic>> getGroupMessages(int groupId) async {
    final res = await http.get(Uri.parse('$baseUrl/groups/$groupId/messages'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Failed to load messages');
  }

  static Future<void> sendGroupMessage(int groupId, int senderId, String text) async {
    final res = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'senderId': senderId, 'text': text}),
    );
    if (res.statusCode != 201) throw Exception('Failed to send message');
  }
}