/// Mirrors backend `AdminBulkGiftAction`.
enum AdminBulkGiftAction {
  delete('DELETE'),
  activate('ACTIVATE'),
  deactivate('DEACTIVATE');

  const AdminBulkGiftAction(this.apiValue);
  final String apiValue;
}
