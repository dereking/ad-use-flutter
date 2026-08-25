import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ad_domain_sdk.dart';
import 'ad_domain_settings_value.dart';

class AdDomainSettingsCard extends StatefulWidget {
  const AdDomainSettingsCard({
    super.key,
    required this.value,
    required this.onSave,
    this.isSaving = false,
    this.savedMessage,
  });

  final AdDomainSettingsValue value;
  final Future<void> Function(AdDomainSettingsValue value) onSave;
  final bool isSaving;

  /// 保存成功后展示的 SnackBar 文案；为 null 时不展示。
  final String? savedMessage;

  @override
  State<AdDomainSettingsCard> createState() => _AdDomainSettingsCardState();
}

class _AdDomainSettingsCardState extends State<AdDomainSettingsCard> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _baseDnController = TextEditingController();
  final _bindDnController = TextEditingController();
  final _bindPasswordController = TextEditingController();

  bool _enabled = false;
  bool _useSsl = false;
  bool _isDirty = false;
  bool _isSaving = false;

  bool get _saving => widget.isSaving || _isSaving;

  @override
  void initState() {
    super.initState();
    _loadValue(widget.value);
  }

  @override
  void didUpdateWidget(covariant AdDomainSettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDirty && oldWidget.value != widget.value) {
      _loadValue(widget.value);
    }
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
              title: const Text('AD Domain'),
              subtitle: const Text(
                'Resolve recipient names, email addresses, and contacts from AD',
              ),
              value: _enabled,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _enabled = value;
                        _isDirty = true;
                      });
                    },
            ),
            if (_enabled) ...[
              const Divider(height: 24),
              _buildConnectionFields(),
              const SizedBox(height: 12),
              _buildSaveButton(),
            ] else if (_isDirty) ...[
              const SizedBox(height: 12),
              _buildSaveButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionFields() {
    return Column(
      children: [
        TextField(
          controller: _hostController,
          decoration: const InputDecoration(
            labelText: 'AD server host',
            hintText: 'ad.example.com',
            prefixIcon: Icon(Icons.dns_outlined),
          ),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '389 or 636',
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _markDirty(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use SSL'),
                value: _useSsl,
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          _useSsl = value;
                          _isDirty = true;
                        });
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _baseDnController,
          decoration: const InputDecoration(
            labelText: 'Base DN',
            hintText: 'DC=example,DC=com',
            prefixIcon: Icon(Icons.account_tree_outlined),
          ),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bindDnController,
          decoration: const InputDecoration(
            labelText: 'Bind DN',
            hintText: 'CN=svc-mail,OU=Service Accounts,DC=example,DC=com',
            prefixIcon: Icon(Icons.person_outline),
          ),
          onChanged: (_) => _markDirty(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bindPasswordController,
          decoration: const InputDecoration(
            labelText: 'Bind password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          obscureText: true,
          onChanged: (_) => _markDirty(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: const Text('Save AD Settings'),
      ),
    );
  }

  void _loadValue(AdDomainSettingsValue value) {
    // 值为空（尚未配置）时回退到 ad sdk 初始化时 shell 指定的默认参数。
    final effective = _effectiveValue(value);
    _enabled = effective.enabled;
    _useSsl = effective.useSsl;
    _hostController.text = effective.host;
    _portController.text = effective.port?.toString() ?? '';
    _baseDnController.text = effective.baseDn;
    _bindDnController.text = effective.bindDn;
    _bindPasswordController.text = effective.bindPassword;
  }

  /// 当前值为空时使用 [AdDomainSdk.defaults] 预填，否则原样使用。
  AdDomainSettingsValue _effectiveValue(AdDomainSettingsValue value) {
    final hasValue = value.host.isNotEmpty ||
        value.baseDn.isNotEmpty ||
        value.bindDn.isNotEmpty;
    if (hasValue) return value;
    final defaults = AdDomainSdk.defaults;
    if (defaults == null) return value;
    return AdDomainSettingsValue(
      enabled: defaults.enabled,
      host: defaults.host,
      port: defaults.port,
      useSsl: defaults.useSsl,
      baseDn: defaults.baseDn,
      bindDn: defaults.bindDn,
      bindPassword: defaults.bindPassword,
    );
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        AdDomainSettingsValue(
          enabled: _enabled,
          host: _hostController.text.trim(),
          port: _portController.text.trim().isEmpty
              ? null
              : int.tryParse(_portController.text.trim()),
          useSsl: _useSsl,
          baseDn: _baseDnController.text.trim(),
          bindDn: _bindDnController.text.trim(),
          bindPassword: _bindPasswordController.text,
        ),
      );
      if (mounted) {
        setState(() => _isDirty = false);
        final savedMessage = widget.savedMessage;
        if (savedMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(savedMessage)),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
