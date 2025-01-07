// lib/admin/post_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/post.dart';
import 'post_editor.dart'; // экран для редактирования поста в админке

class PostList extends StatelessWidget {
  final CollectionReference postsRef =
  FirebaseFirestore.instance.collection('posts');

  PostList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: StreamBuilder<QuerySnapshot>(
        stream: postsRef.orderBy('created_at', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Постов пока нет.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final post = Post.fromMap(doc.id, doc.data() as Map<String, dynamic>);
              final dateStr = DateFormat('dd MMM yyyy HH:mm', 'ru').format(post.createdAt);

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8.0),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.imageUrl.isNotEmpty)
                        Image.network(
                          post.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        post.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Создано: $dateStr',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  // Управление постом (редактировать / удалить)
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        // Переход к экрану редактирования (в админке)
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PostEditor(postId: post.id)),
                        );
                      } else if (value == 'delete') {
                        // Удаление поста
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Удаление'),
                            content: const Text('Удалить этот пост?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Отмена'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Удалить'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await postsRef.doc(post.id).delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Пост удалён')),
                          );
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Редактировать'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Удалить'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // FAB для добавления нового поста (админка)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostEditor()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Добавить пост',
      ),
    );
  }
}
