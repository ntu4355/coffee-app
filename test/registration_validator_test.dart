import 'package:coffee_app/service/registration_validator.dart';
import 'package:coffee_app/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegistrationValidator.isValidEmail', () {
    test('accepts a standard email address', () {
      expect(RegistrationValidator.isValidEmail('name@example.com'), isTrue);
    });

    test('rejects incomplete or malformed email addresses', () {
      for (final email in [
        '',
        'name',
        'name@',
        'name@example',
        'name@example.c',
        'name@-example.com',
        'name..last@example.com',
        '.name@example.com',
        'name@example..com',
        'name @example.com',
      ]) {
        expect(
          RegistrationValidator.isValidEmail(email),
          isFalse,
          reason: email,
        );
      }
    });
  });

  group('RegistrationValidator.passwordError', () {
    test('accepts a password meeting all requirements', () {
      expect(RegistrationValidator.passwordError('CoffeeShop9!'), isNull);
    });

    test('rejects passwords missing each security requirement', () {
      for (final password in [
        'Ab1!',
        'coffeeshop9!',
        'COFFEESHOP9!',
        'CoffeeShop!!',
        'CoffeeShop99',
      ]) {
        expect(
          RegistrationValidator.passwordError(password),
          isNotNull,
          reason: password,
        );
      }
    });
  });

  testWidgets('sign-up rejects a malformed email before creating an account', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SignUp()));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Test User');
    await tester.enterText(fields.at(2), 'user@example.c');
    await tester.enterText(fields.at(4), 'CoffeeShop9!');
    await tester.enterText(fields.at(5), 'CoffeeShop9!');

    final signUpButton = find.widgetWithText(ElevatedButton, 'Đăng ký');
    await tester.ensureVisible(signUpButton);
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập địa chỉ email hợp lệ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
