import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iloveopera/app/app.dart';

void main() {
  testWidgets('App boots and shows the viewer placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: IloveoperaApp()));
    await tester.pump();

    expect(find.text('iloveopera'), findsOneWidget);
    expect(find.text('Aquí irá el visor PDF'), findsOneWidget);
  });
}
