import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_builder/responsive_builder.dart';

DeviceScreenType getScreenType(WidgetTester tester) {
  return DeviceScreenType.Tablet;
  // return getDeviceType(tester.view.physicalSize);
}
