import 'package:flutter_test/flutter_test.dart';
import 'package:home/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  test('Post is created correctly from map and converts back to map', () {
    // Arrange: создаем карту данных, которая имитирует данные Firestore
    final postData = {
      'image_url': 'https://example.com/image.jpg',
      'text': 'Test post text',
      'created_at': Timestamp.fromDate(DateTime(2023, 1, 1)),
      'reactions': {'like': 10, 'love': 5},
      'user_reactions': {'user1': 'like', 'user2': 'love'},
    };

    // Act: создаем объект Post из карты данных
    final post = Post.fromMap('testPostId', postData);

    // Assert: проверяем корректность полей объекта
    expect(post.id, 'testPostId');
    expect(post.imageUrl, 'https://example.com/image.jpg');
    expect(post.text, 'Test post text');
    expect(post.createdAt, DateTime(2023, 1, 1));
    expect(post.reactions['like'], 10);
    expect(post.reactions['love'], 5);
    expect(post.userReactions['user1'], 'like');
    expect(post.userReactions['user2'], 'love');

    // Act: преобразуем объект обратно в карту данных
    final convertedMap = post.toMap();

    // Assert: проверяем, что карта данных соответствует исходным данным
    expect(convertedMap['image_url'], 'https://example.com/image.jpg');
    expect(convertedMap['text'], 'Test post text');
    expect((convertedMap['created_at'] as Timestamp).toDate(), DateTime(2023, 1, 1));
    expect(convertedMap['reactions'], {'like': 10, 'love': 5});
    expect(convertedMap['user_reactions'], {'user1': 'like', 'user2': 'love'});
  });
}
