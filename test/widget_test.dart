import 'package:flutter_test/flutter_test.dart';
import 'package:not_delivered/app.dart';
import 'package:not_delivered/core/utils/app_constants.dart';

void main() {
  testWidgets('App boots to the skeleton home', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.text(AppConstants.appName), findsWidgets);
  });
}
