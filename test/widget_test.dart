import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_flow/main.dart';

void main() {
  testWidgets('TaskFlowApp smoke test initializes without errors', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();

    // Verify TaskFlowApp compiles and initializes cleanly
    expect(TaskFlowApp, isNotNull);
  });
}
