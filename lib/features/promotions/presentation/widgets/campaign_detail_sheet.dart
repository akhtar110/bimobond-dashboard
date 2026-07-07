import 'package:flutter/material.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/campaign_detail_bloc.dart';
import '../pages/campaign_detail_page.dart';
import 'promotion_sheet_frame.dart';

Future<bool?> showCampaignDetailSheet(
  BuildContext context,
  String campaignId,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return PersistentBlocProvider<CampaignDetailBloc>(
        debugLabel: 'CampaignDetailSheet',
        create: () => di.sl<CampaignDetailBloc>()
          ..add(LoadCampaignDetailEvent(campaignId)),
        child: PromotionDetailSheetFrame(
          title: sheetContext.l10n.t('promoCampaignDetail'),
          child: CampaignDetailBody(
            campaignId: campaignId,
            embedded: true,
            onDeleted: () => Navigator.of(sheetContext).pop(true),
          ),
        ),
      );
    },
  );
}
