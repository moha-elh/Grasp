import 'package:flutter_test/flutter_test.dart';

import 'package:grasp/app.dart';

void main() {
  testWidgets('app boots to foundation placeholder', (tester) async {
    await tester.pumpWidget(const GraspApp());
    expect(find.text('Grasp — foundation ready'), findsOneWidget);
  });
}
