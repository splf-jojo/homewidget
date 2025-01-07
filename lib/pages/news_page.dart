// lib/pages/news_page.dart
import 'package:flutter/material.dart';
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

  // Пример userId — в реальном проекте возьмите из FirebaseAuth.instance.currentUser.uid
  final String currentUserId = 'userA';

  @override
  void initState() {
    super.initState();
    _loadPosts();
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
        // Например, "like" или "love"
        final likeCount = post.reactions['like'] ?? 0;
        final loveCount = post.reactions['love'] ?? 0;

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Текст
                Text(post.text, style: const TextStyle(fontSize: 16)),

                // Картинка
                if (post.imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: AspectRatio(
                      aspectRatio: 3 / 4, // ограничиваем пропорции
                      child: Image.network(post.imageUrl, fit: BoxFit.cover),
                    ),
                  ),

                const SizedBox(height: 8.0),

                // Кнопки лайк/сердце
                Row(
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
              ],
            ),
          ),
        );
      },
    );
  }
}
