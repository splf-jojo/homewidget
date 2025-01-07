// lib/services/post_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post.dart';

class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final _postsRef = _firestore.collection('posts');

  static Future<Post?> getPostById(String postId) async {
    final doc = await _postsRef.doc(postId).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return Post.fromMap(doc.id, data);
  }

  static Future<String> uploadImage(File imageFile) async {
    // Проверка существования файла
    if (!imageFile.existsSync()) {
      throw Exception('Файл не найден по пути: ${imageFile.path}');
    }

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('post_images')
          .child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  static Future<void> createPost({
    required String text,
    String imageUrl = '',
  }) async {
    final postData = {
      'text': text,
      'image_url': imageUrl,
      'created_at': FieldValue.serverTimestamp(),
      'reactions': <String, int>{},
      'user_reactions': <String, String>{},
    };

    final postRef = await _postsRef.add(postData);

    // Безопасное создание подстроки длиной до 100 символов
    final bodyText = text.length > 100 ? text.substring(0, 100) : text;

    final notificationData = {
      'type': 'new_post',
      'title': 'Новый пост!',
      'body': bodyText,
      'timestamp': FieldValue.serverTimestamp(),
      'postId': postRef.id,
    };

    await _firestore.collection('notifications').add(notificationData);
  }


  static Future<void> updatePost({
    required String postId,
    required String newText,
    String? newImageUrl,
  }) async {
    final updates = <String, dynamic>{
      'text': newText,
    };
    if (newImageUrl != null) {
      updates['image_url'] = newImageUrl;
    }
    await _postsRef.doc(postId).update(updates);
  }

  static Future<List<Post>> getPostsOnce() async {
    final snapshot = await _postsRef.orderBy('created_at', descending: true).get();
    return snapshot.docs.map((doc) {
      return Post.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  static Future<void> setReaction({
    required Post post,
    required String userId,
    required String reactionType,
  }) async {
    final docRef = _postsRef.doc(post.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Пост не найден');

      final data = snapshot.data() as Map<String, dynamic>;
      final currentReactions = Map<String, int>.from(data['reactions'] ?? {});
      final currentUserReactions = Map<String, String>.from(data['user_reactions'] ?? {});

      if (currentUserReactions.containsKey(userId)) {
        final oldReaction = currentUserReactions[userId]!;
        if (currentReactions.containsKey(oldReaction)) {
          currentReactions[oldReaction] = (currentReactions[oldReaction]! - 1).clamp(0, 999999);
        }
      }

      currentUserReactions[userId] = reactionType;
      currentReactions[reactionType] = (currentReactions[reactionType] ?? 0) + 1;

      transaction.update(docRef, {
        'reactions': currentReactions,
        'user_reactions': currentUserReactions,
      });
    });
  }
}
