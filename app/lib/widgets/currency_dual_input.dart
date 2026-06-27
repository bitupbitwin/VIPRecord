import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/enums.dart';
import '../services/currency_service.dart';

/// 人民币 / 美元双框联动输入。
/// 填人民币框 -> 美元框自动更新；填美元框 -> 人民币框自动更新。
/// 以「最后编辑的框」作为存储币种，通过 [onChanged] 回报 (金额, 币种)。
class CurrencyDualInput extends StatefulWidget {
  const CurrencyDualInput({
    super.key,
    required this.converter,
    required this.initialAmount,
    required this.initialCurrency,
    required this.onChanged,
  });

  final CurrencyConverter converter;
  final double initialAmount;
  final Currency initialCurrency;
  final void Function(double amount, Currency currency) onChanged;

  @override
  State<CurrencyDualInput> createState() => _CurrencyDualInputState();
}

class _CurrencyDualInputState extends State<CurrencyDualInput> {
  late final TextEditingController _cny;
  late final TextEditingController _usd;
  Currency _source = Currency.cny; // 最后编辑的框
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _source = widget.initialCurrency;
    final cnyVal = widget.converter.toCny(
        widget.initialAmount, widget.initialCurrency);
    final usdVal = widget.converter.cnyToUsd(cnyVal);
    _cny = TextEditingController(text: _fmt(cnyVal));
    _usd = TextEditingController(text: _fmt(usdVal));
  }

  String _fmt(double v) => v == 0 ? '' : v.toStringAsFixed(2);

  void _onCny(String text) {
    if (_syncing) return;
    _source = Currency.cny;
    final cny = double.tryParse(text) ?? 0;
    _syncing = true;
    _usd.text = _fmt(widget.converter.cnyToUsd(cny));
    _syncing = false;
    widget.onChanged(cny, Currency.cny);
  }

  void _onUsd(String text) {
    if (_syncing) return;
    _source = Currency.usd;
    final usd = double.tryParse(text) ?? 0;
    _syncing = true;
    _cny.text = _fmt(widget.converter.usdToCnyAmount(usd));
    _syncing = false;
    widget.onChanged(usd, Currency.usd);
  }

  @override
  void didUpdateWidget(covariant CurrencyDualInput old) {
    super.didUpdateWidget(old);
    // 汇率变化时，按当前 source 重新联动另一框。
    if (old.converter.usdToCny != widget.converter.usdToCny) {
      if (_source == Currency.cny) {
        _onCny(_cny.text);
      } else {
        _onUsd(_usd.text);
      }
    }
  }

  @override
  void dispose() {
    _cny.dispose();
    _usd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _field(_cny, '人民币 ¥', _onCny, Currency.cny)),
        const SizedBox(width: 12),
        const Icon(Icons.sync_alt, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Expanded(child: _field(_usd, '美元 \$', _onUsd, Currency.usd)),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
      ValueChanged<String> onChanged, Currency cur) {
    final isSource = _source == cur;
    return TextField(
      controller: c,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(isSource ? 0.14 : 0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: Colors.white.withOpacity(isSource ? 0.5 : 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7C9CFF), width: 1.5),
        ),
      ),
    );
  }
}
