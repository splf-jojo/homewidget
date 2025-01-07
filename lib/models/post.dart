// lib/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String imageUrl;
  final String text;
  final DateTime createdAt;

  /// Словарь вида {"like": 3, "love": 2, ...}
  final Map<String, int> reactions;

  /// Словарь вида {userId: "like", userId2: "love", ...}
  final Map<String, String> userReactions;

  Post({
    required this.id,
    required this.imageUrl,
    required this.text,
    required this.createdAt,
    required this.reactions,
    required this.userReactions,
  });

  /// Создание Post из документа Firestore
  factory Post.fromMap(String id, Map<String, dynamic> data) {
    final rawReactions = data['reactions'] as Map<String, dynamic>? ?? {};
    final Map<String, int> parsedReactions = {};
    rawReactions.forEach((key, value) {
      parsedReactions[key] = (value is int) ? value : 0;
    });

    final rawUserReactions = data['user_reactions'] as Map<String, dynamic>? ?? {};
    final Map<String, String> parsedUserReactions = {};
    rawUserReactions.forEach((userId, reaction) {
      if (reaction is String) parsedUserReactions[userId] = reaction;
    });

    return Post(
      id: id,
      imageUrl: data['image_url'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: parsedReactions,
      userReactions: parsedUserReactions,
    );
  }

  /// Преобразование в Map для сохранения в Firestore
  Map<String, dynamic> toMap() {
    return {
      'image_url': imageUrl,
      'text': text,
      'created_at': Timestamp.fromDate(createdAt),
      'reactions': reactions,
      'user_reactions': userReactions,
    };
  }
}
