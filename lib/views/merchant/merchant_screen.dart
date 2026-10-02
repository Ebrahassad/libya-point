import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';
import '../../data/cities.dart';
import '../../widgets/open_link.dart';

/// نموذج طلب إضافة متجر أو خدمة. يُرسل بالبريد إن ضُبط CONTACT_EMAIL،
/// وإلا يُنسخ النص ويُحفظ محلياً ليرسله المستخدم بأي وسيلة.
class MerchantScreen extends StatefulWidget {
  const MerchantScreen({super.key});

  @override
  State<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _site = TextEditingController();
  String _category = 'cat_store';
  String _city = libyaCities.first.name;

  static const _categories = [
    'cat_store',
    'cat_pharmacy',
    'cat_delivery',
    'cat_service',
    'cat_app',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _site.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'required'.tr() : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final text = [
      '${'store_name'.tr()}: ${_name.text.trim()}',
      '${'category'.tr()}: ${_category.tr()}',
      '${'city'.tr()}: $_city',
      '${'phone'.tr()}: ${_phone.text.trim()}',
      if (_site.text.trim().isNotEmpty)
        '${'website'.tr()}: ${_site.text.trim()}',
    ].join('\n');

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('merchant_requests') ?? <String>[];
    saved.add(text);
    await prefs.setStringList('merchant_requests', saved);

    if (AppConfig.contactEmail.isNotEmpty) {
      if (!mounted) return;
      await openUri(
        context,
        Uri(
          scheme: 'mailto',
          path: AppConfig.contactEmail,
          query:
              'subject=${Uri.encodeComponent('Libya Point - ${_name.text.trim()}')}'
              '&body=${Uri.encodeComponent(text)}',
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text('request_saved'.tr())));
    } else {
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(SnackBar(content: Text('request_copied'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('merchant_title'.tr()), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'merchant_intro'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              validator: _required,
              decoration: InputDecoration(
                labelText: 'store_name'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'category'.tr(),
                border: const OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
                  value: _category,
                  items: [
                    for (final c in _categories)
                      DropdownMenuItem(value: c, child: Text(c.tr())),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
              ),
            ),
            const SizedBox(height: 14),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'city'.tr(),
                border: const OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
                  value: _city,
                  items: [
                    for (final c in libyaCities)
                      DropdownMenuItem(value: c.name, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _city = v ?? _city),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              validator: _required,
              decoration: InputDecoration(
                labelText: 'phone'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _site,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'website'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: Text('send_request'.tr()),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
