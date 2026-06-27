import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/platform.dart';
import '../models/subscription.dart';
import '../providers/providers.dart';
import '../theme/glass.dart';
import '../widgets/currency_dual_input.dart';

class SubscriptionEditScreen extends ConsumerStatefulWidget {
  const SubscriptionEditScreen({
    super.key,
    required this.categoryId,
    this.existing,
  });

  final String categoryId;
  final Subscription? existing;

  @override
  ConsumerState<SubscriptionEditScreen> createState() => _EditState();
}

class _EditState extends ConsumerState<SubscriptionEditScreen> {
  static final _df = DateFormat('yyyy-MM-dd');

  late String _platformId;
  BillingCycle _cycle = BillingCycle.monthly;
  double _amount = 0;
  Currency _currency = Currency.cny;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 365));
  bool _autoRenew = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final platforms = ref.read(appProvider).platforms
        .where((p) => p.categoryId == widget.categoryId)
        .toList();
    _platformId = e?.platformId ?? (platforms.isNotEmpty ? platforms.first.id : '');
    if (e != null) {
      _cycle = e.cycle;
      _amount = e.amount;
      _currency = e.currency;
      _start = e.startDate;
      _end = e.endDate;
      _autoRenew = e.autoRenew;
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2015),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  void _save() {
    if (_platformId.isEmpty) return;
    final id = widget.existing?.id ?? const Uuid().v4();
    final sub = Subscription(
      id: id,
      platformId: _platformId,
      cycle: _cycle,
      amount: _amount,
      currency: _currency,
      startDate: _start,
      endDate: _end,
      autoRenew: _autoRenew,
    );
    ref.read(appProvider.notifier).upsertSubscription(sub);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final converter = ref.watch(converterProvider);
    final platforms = ref.watch(appProvider).platforms
        .where((p) => p.categoryId == widget.categoryId)
        .toList();

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(widget.existing == null ? '添加订阅' : '编辑订阅'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('平台'),
                    DropdownButton<String>(
                      value: _platformId.isEmpty ? null : _platformId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1B2140),
                      style: const TextStyle(color: Colors.white),
                      items: [
                        for (final Platform p in platforms)
                          DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.emoji} ${p.name}')),
                      ],
                      onChanged: (v) => setState(() => _platformId = v ?? ''),
                    ),
                    const SizedBox(height: 16),
                    _label('计费周期'),
                    SegmentedButton<BillingCycle>(
                      segments: const [
                        ButtonSegment(
                            value: BillingCycle.monthly, label: Text('月付')),
                        ButtonSegment(
                            value: BillingCycle.quarterly, label: Text('季付')),
                        ButtonSegment(
                            value: BillingCycle.yearly, label: Text('年付')),
                      ],
                      selected: {_cycle},
                      onSelectionChanged: (s) =>
                          setState(() => _cycle = s.first),
                    ),
                    const SizedBox(height: 16),
                    _label('金额（人民币 / 美元 联动）'),
                    CurrencyDualInput(
                      converter: converter,
                      initialAmount: _amount,
                      initialCurrency: _currency,
                      onChanged: (amt, cur) {
                        _amount = amt;
                        _currency = cur;
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('订阅期'),
                    Row(
                      children: [
                        Expanded(child: _dateBtn('开始', _start, true)),
                        const SizedBox(width: 12),
                        Expanded(child: _dateBtn('结束', _end, false)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('自动续费',
                          style: TextStyle(color: Colors.white)),
                      value: _autoRenew,
                      onChanged: (v) => setState(() => _autoRenew = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C9CFF),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _save,
                child: const Text('保存', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      );

  Widget _dateBtn(String label, DateTime d, bool isStart) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.25)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () => _pickDate(isStart),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 2),
            Text(_df.format(d),
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      );
}
