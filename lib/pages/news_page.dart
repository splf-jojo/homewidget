// lib/pages/news_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/post_service.dart';
import '../models/post.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  bool isLoading = true;
  List<Post> posts = [];
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeUserId();
    _loadPosts();
  }

  void _initializeUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    } else {
      currentUserId = 'guest'; // Временный идентификатор для тестов
    }
  }

  Future<void> _loadPosts() async {
    try {
      final fetchedPosts = await PostService.getPostsOnce();
      if (!mounted) return;
      setState(() {
        posts = fetchedPosts;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки постов: $e')),
      );
    }
  }

  Future<void> _onReaction(Post post, String reactionType) async {
    try {
      await PostService.setReaction(
        post: post,
        userId: currentUserId,
        reactionType: reactionType,
      );
      // Обновляем список, чтобы увидеть изменения
      await _loadPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при установке реакции: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return const Center(child: Text('Постов нет.'));
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final userReaction = post.userReactions[currentUserId];
        final likeCount = post.reactions['like'] ?? 0;
        final loveCount = post.reactions['love'] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Легкое закругление

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Картинка
              if (post.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ), // Скругляем только верхние углы
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 400, // Максимальная высота картинки
                      minHeight: 200, // Минимальная высота картинки (если требуется)
                    ),
                    child: Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity, // Картинка на всю ширину карточки
                    ),
                  ),
                ),
              // Текст под картинкой
              if (post.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    post.text,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

              // Кнопки лайк/сердце
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up,
                        color: (userReaction == 'like') ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () => _onReaction(post, 'like'),
                    ),
                    Text('$likeCount'),
                    const SizedBox(width: 16),

                    IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: (userReaction == 'love') ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _onReaction(post, 'love'),
                    ),
                    Text('$loveCount'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
