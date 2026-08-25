import 'package:ad_use_flutter/ad_use_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AdDomainSdk.resetForTesting);

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

  testWidgets(
    'AD settings card prefills shell-provided SDK defaults when value is '
    'empty',
    (tester) async {
      AdDomainSdk.initialize(
        defaults: const AdDomainSettingsValue(
          enabled: true,
          host: 'it2004.gree.com.cn',
          port: 389,
          useSsl: false,
          baseDn: 'OU=格力电器,DC=it2004,DC=gree,DC=com,DC=cn',
        ),
      );
      AdDomainSettingsValue? saved;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdDomainSettingsCard(
              value: const AdDomainSettingsValue(),
              onSave: (value) async {
                saved = value;
              },
            ),
          ),
        ),
      );

      final hostField = tester.widget<TextField>(find.byType(TextField).first);
      expect(hostField.controller!.text, 'it2004.gree.com.cn');

      await tester.tap(find.text('Save AD Settings'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.host, 'it2004.gree.com.cn');
      expect(saved!.port, 389);
      expect(saved!.baseDn, 'OU=格力电器,DC=it2004,DC=gree,DC=com,DC=cn');
    },
  );
}
