enum CampaignStatus {
  pendingPayment('PENDING_PAYMENT'),
  active('ACTIVE'),
  paused('PAUSED'),
  completed('COMPLETED'),
  cancelled('CANCELLED'),
  rejected('REJECTED');

  const CampaignStatus(this.apiValue);
  final String apiValue;

  static CampaignStatus? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final s in CampaignStatus.values) {
      if (s.apiValue == value) return s;
    }
    return null;
  }
}

enum CampaignObjective {
  views('VIEWS'),
  followers('FOLLOWERS'),
  engagement('ENGAGEMENT'),
  challenges('CHALLENGES'),
  profileVisits('PROFILE_VISITS'),
  sales('SALES');

  const CampaignObjective(this.apiValue);
  final String apiValue;

  static CampaignObjective? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final o in CampaignObjective.values) {
      if (o.apiValue == value) return o;
    }
    return null;
  }
}

enum BulkCampaignAction {
  pause('PAUSE'),
  activate('ACTIVATE'),
  reject('REJECT'),
  cancel('CANCEL'),
  delete('DELETE'),
  updateStatus('UPDATE_STATUS'),
  deactivatePackages('DEACTIVATE_PACKAGES'),
  activatePackages('ACTIVATE_PACKAGES');

  const BulkCampaignAction(this.apiValue);
  final String apiValue;
}

enum LocationSource {
  appOpen('APP_OPEN'),
  feed('FEED'),
  manual('MANUAL'),
  background('BACKGROUND');

  const LocationSource(this.apiValue);
  final String apiValue;

  static LocationSource? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final s in LocationSource.values) {
      if (s.apiValue == value) return s;
    }
    return null;
  }
}
