// test/widget_test.dart
// Test de fumée basique pour VigiRoutes Terrain.

import 'package:flutter_test/flutter_test.dart';
import 'package:vigiroutes_terrain/main.dart';

void main() {
  testWidgets('L\'app démarre sans crash', (WidgetTester tester) async {
    await tester.pumpWidget(const TerrainApp());
    expect(find.byType(TerrainApp), findsOneWidget);
  });
}
