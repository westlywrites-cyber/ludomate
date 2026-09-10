// Basic smoke test: the app boots to the home screen and shows the brand
// name and Play button. (The previous version of this file was still the
// unmodified `flutter create` counter-app test — it referenced a `MyApp`
// class that doesn't exist in this project and would not compile.)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ludomate/main.dart';

void main() {
  testWidgets('Home screen shows title and Play button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LudoMateApp()),
    );

    expect(find.text('LudoMate'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });
}
