import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/glass.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _rate;
  late final TextEditingController _url;
  late final TextEditingController _key;
  bool _sync = false;
  bool _reminder = true;
  int _leadDays = 3;

  @override
  void initState() {
    super.initState();
    final s = ref.read(appProvider).settings;
    _rate = TextEditingController(text: s.usdToCny.toString());
    _url = TextEditingController(text: s.supabaseUrl);
    _key = TextEditingController(text: s.supabaseAnonKey);
    _sync = s.syncEnabled;
    _reminder = s.reminderEnabled;
    _leadDays = s.reminderLeadDays;
  }

  void _saveReminder() {
    final s = ref.read(appProvider).settings;
    s.reminderEnabled = _reminder;
    s.reminderLeadDays = _leadDays;
    ref.read(appProvider.notifier).updateSettings(s);
  }

  void _saveRate() {
    final s = ref.read(appProvider).settings;
    s.usdToCny = double.tryParse(_rate.text) ?? s.usdToCny;
    ref.read(appProvider.notifier).updateSettings(s);
  }

  void _saveSync() {
    final s = ref.read(appProvider).settings;
    s.supabaseUrl = _url.text.trim();
    s.supabaseAnonKey = _key.text.trim();
    s.syncEnabled = _sync;
    ref.read(appProvider.notifier).updateSettings(s);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存，重启后云同步生效')),
    );
  }

  @override
  void dispose() {
    _rate.dispose();
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('设置'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('固定汇率',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('1 美元 = ? 人民币（用于双框联动与统计折算）',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rate,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: _dec('1 USD = ? CNY'),
                      onChanged: (_) => _saveRate(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('到期提醒',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('在订阅期结束前若干天发本地通知，提醒确认续费',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('启用到期提醒',
                          style: TextStyle(color: Colors.white)),
                      value: _reminder,
                      onChanged: (v) {
                        setState(() => _reminder = v);
                        _saveReminder();
                      },
                    ),
                    Row(
                      children: [
                        const Text('提前天数',
                            style: TextStyle(color: Colors.white70)),
                        const Spacer(),
                        for (final d in [1, 3, 7, 14])
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text('$d 天'),
                              selected: _leadDays == d,
                              onSelected: (_) {
                                setState(() => _leadDays = d);
                                _saveReminder();
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('云同步（手机 / 电脑互通）',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('填入 Supabase 项目 URL 与 anon key，多端同账号互通',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('启用云同步',
                          style: TextStyle(color: Colors.white)),
                      value: _sync,
                      onChanged: (v) => setState(() => _sync = v),
                    ),
                    TextField(
                      controller: _url,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dec('Supabase URL'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _key,
                      style: const TextStyle(color: Colors.white),
                      decoration: _dec('anon key'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C9CFF)),
                      onPressed: _saveSync,
                      child: const Text('保存云同步设置'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C9CFF)),
        ),
      );
}
