import 'package:flutter/material.dart';

import 'ad_domain_settings_value.dart';

class AdDomainSettingsCard extends StatefulWidget {
  const AdDomainSettingsCard({
    super.key,
    required this.value,
    required this.onSave,
  });

  final AdDomainSettingsValue value;
  final Future<void> Function(AdDomainSettingsValue value) onSave;

  @override
  State<AdDomainSettingsCard> createState() => _AdDomainSettingsCardState();
}

class _AdDomainSettingsCardState extends State<AdDomainSettingsCard> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _baseDnController;
  late final TextEditingController _bindDnController;
  late final TextEditingController _bindPasswordController;
  bool _enabled = false;
  bool _useSsl = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.value.enabled;
    _useSsl = widget.value.useSsl;
    _hostController = TextEditingController(text: widget.value.host);
    _portController = TextEditingController(
      text: widget.value.port?.toString() ?? '',
    );
    _baseDnController = TextEditingController(text: widget.value.baseDn);
    _bindDnController = TextEditingController(text: widget.value.bindDn);
    _bindPasswordController = TextEditingController(
      text: widget.value.bindPassword,
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _baseDnController.dispose();
    _bindDnController.dispose();
    _bindPasswordController.dispose();
    super.dispose();
  }

  AdDomainSettingsValue _buildValue() {
    final portText = _portController.text.trim();
    return AdDomainSettingsValue(
      enabled: _enabled,
      host: _hostController.text.trim(),
      port: portText.isNotEmpty ? int.tryParse(portText) : null,
      useSsl: _useSsl,
      baseDn: _baseDnController.text.trim(),
      bindDn: _bindDnController.text.trim(),
      bindPassword: _bindPasswordController.text.trim(),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_buildValue());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable AD Integration'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            const Divider(),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: 'e.g. ldap.example.com',
              ),
              enabled: _enabled,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '389',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: _enabled,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use SSL'),
                    value: _useSsl,
                    onChanged:
                        _enabled
                            ? (value) => setState(() => _useSsl = value)
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baseDnController,
              decoration: const InputDecoration(
                labelText: 'Base DN',
                hintText: 'e.g. dc=example,dc=com',
              ),
              enabled: _enabled,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bindDnController,
              decoration: const InputDecoration(
                labelText: 'Bind DN',
                hintText: 'e.g. cn=admin,dc=example,dc=com',
              ),
              enabled: _enabled,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bindPasswordController,
              decoration: const InputDecoration(labelText: 'Bind Password'),
              obscureText: true,
              enabled: _enabled,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
