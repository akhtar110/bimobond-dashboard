/// Mirrors backend `AdminBulkPostAction`.
enum AdminBulkPostAction {
  delete('DELETE'),
  ban('BAN'),
  hide('HIDE'),
  publish('PUBLISH'),
  updateStatus('UPDATE_STATUS');

  const AdminBulkPostAction(this.apiValue);

  final String apiValue;
}
