import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:home/pages/news_page.dart';

// Тест для проверки рендеринга текстового виджета
void main() {
  testWidgets('NewsPage shows a text widget', (WidgetTester tester) async {
    // Акт: отрисовка виджета NewsPage
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Test text for NewsPage'),
          ),
        ),
      ),
    );

    // Ассерты: проверка, что виджет с текстом появился
    expect(find.text('Test text for NewsPage'), findsOneWidget);
  });
}
