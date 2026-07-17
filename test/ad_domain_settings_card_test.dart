import 'package:ad_use_flutter/ad_use_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AD settings card edits configuration and saves it', (
    tester,
  ) async {
    AdDomainSettingsValue? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdDomainSettingsCard(
            value: const AdDomainSettingsValue(
              enabled: true,
              host: 'ad.example.com',
              port: 636,
              useSsl: true,
              baseDn: 'DC=example,DC=com',
              bindDn: 'CN=svc,DC=example,DC=com',
              bindPassword: 'secret',
            ),
            onSave: (value) async {
              saved = value;
            },
          ),
        ),
      ),
    );

    expect(find.text('AD Domain'), findsOneWidget);
    expect(find.text('AD server host'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ldap.example.com');
    await tester.tap(find.text('Save AD Settings'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.host, 'ldap.example.com');
    expect(saved!.port, 636);
    expect(saved!.useSsl, isTrue);
  });
}
