// lib/pages/post_editor.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/post.dart';
import '../services/post_service.dart';

class PostEditor extends StatefulWidget {
  final String? postId;

  const PostEditor({Key? key, this.postId}) : super(key: key);

  @override
  State<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isPicking = false; // флаг для предотвращения повторного вызова ImagePicker
  Post? _post;

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      _loadPost();
    }
  }

  Future<void> _loadPost() async {
    setState(() => _isLoading = true);
    try {
      final post = await PostService.getPostById(widget.postId!);
      if (post == null) {
        throw Exception('Пост не найден');
      }
      _post = post;
      _textController.text = _post?.text ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке поста: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    // Если уже идёт выбор фото, не даём снова открыть
    if (_isPicking) return;

    setState(() => _isPicking = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Ошибка выбора фото: $e');
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _savePost() async {
    final text = _textController.text.trim();

    // Проверяем, что у нас есть хотя бы текст или (старое/новое фото)
    final hasOldImage = _post?.imageUrl.isNotEmpty ?? false;
    final hasNewImage = _selectedImage != null;
    if (text.isEmpty && !hasNewImage && !hasOldImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нужно добавить текст или фото')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Если выбрали новое изображение, загружаем его
      String? newImageUrl;
      if (_selectedImage != null) {
        newImageUrl = await PostService.uploadImage(_selectedImage!);
      }

      if (widget.postId == null) {
        // Создаём новый пост
        await PostService.createPost(
          text: text,
          imageUrl: newImageUrl ?? '',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пост создан')),
          );
        }
      } else {
        // Редактируем пост
        await PostService.updatePost(
          postId: widget.postId!,
          newText: text,
          newImageUrl: newImageUrl,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пост обновлён')),
          );
        }
      }

      // Возвращаемся назад
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении поста: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.postId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать пост' : 'Новый пост'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Если редактируем и есть старая картинка, но не выбрана новая
                  if ((_post?.imageUrl.isNotEmpty ?? false) && _selectedImage == null)
                    Image.network(
                      _post!.imageUrl,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  // Если выбрали новое фото
                  if (_selectedImage != null)
                    Image.file(
                      _selectedImage!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('Выбрать фото'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Текст поста',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _savePost,
                    child: Text(isEditing ? 'Сохранить изменения' : 'Опубликовать'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
