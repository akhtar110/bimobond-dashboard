import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../injection_container.dart';
import '../../../auctions/domain/usecases/preview_auction_pricing_usecase.dart';
import '../../../settings/domain/entities/economy_setting_entity.dart';
import '../../../settings/domain/usecases/economy_setting_usecases.dart';

class GiftPriceCoinsField extends StatefulWidget {
  const GiftPriceCoinsField({
    super.key,
    required this.controller,
    required this.validator,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final bool enabled;

  @override
  State<GiftPriceCoinsField> createState() => _GiftPriceCoinsFieldState();
}

class _GiftPriceCoinsFieldState extends State<GiftPriceCoinsField> {
  final _getEconomySetting = sl<GetEconomySettingUseCase>();
  final _previewPricing = sl<PreviewAuctionPricing>();

  double _coinsPerPriceUnit = 100;
  String _currencyCode = 'USD';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCoinsChanged);
    _loadPricingContext();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCoinsChanged);
    super.dispose();
  }

  Future<void> _loadPricingContext() async {
    try {
      final setting = await _getEconomySetting(
        EconomySettingKeys.coinsPerPriceUnit,
      );
      final rate = double.tryParse(setting.value);
      if (rate != null && rate > 0) {
        _coinsPerPriceUnit = rate;
      }
    } catch (_) {}

    try {
      final preview = await _previewPricing(targetPrice: 1);
      final code = preview.resolvedCurrencyCode ?? preview.inputCurrencyCode;
      if (code != null && code.trim().isNotEmpty) {
        _currencyCode = code.trim();
      }
    } catch (_) {}

    if (mounted) setState(() {});
  }

  void _onCoinsChanged() => setState(() {});

  double? _priceForCoins() {
    final coins = double.tryParse(widget.controller.text.trim());
    if (coins == null || coins <= 0 || _coinsPerPriceUnit <= 0) return null;
    return coins / _coinsPerPriceUnit;
  }

  String _priceLabel(AppLocalizations l10n) {
    return l10n
        .t('giftPriceLabel')
        .replaceAll(' (USD)', '')
        .replaceAll(' *', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final price = _priceForCoins();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            labelText: 'coins',
            hintText: 'coins',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: widget.validator,
          onChanged: (_) => _onCoinsChanged(),
        ),
        if (price != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_priceLabel(l10n)}: ${MoneyFormat.format(price, _currencyCode)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }
}
