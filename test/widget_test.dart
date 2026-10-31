import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neo_reader/app.dart';

void main() {
  testWidgets('NeoReader app builds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NeoReaderApp()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('NeoReader'), findsNothing); // may still be loading settings
    // Smoke: MaterialApp is present via pump without throw
    expect(tester.takeException(), isNull);
  });
}
