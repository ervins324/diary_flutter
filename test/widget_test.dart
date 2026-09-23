import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diary_flutter/main.dart';
import 'package:diary_flutter/core/database/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DiaryApp basic smoke test', (WidgetTester tester) async {
    Hive.init('./test_hive');
    await HiveBoxes.init();

    await tester.pumpWidget(
      const ProviderScope(
        child: DiaryApp(),
      ),
    );

    // Pump a single frame for animated components
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DiaryApp), findsOneWidget);
  });
}
