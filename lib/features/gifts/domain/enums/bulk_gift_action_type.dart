enum BulkGiftActionType {
  delete('DELETE'),
  activate('ACTIVATE'),
  deactivate('DEACTIVATE');

  const BulkGiftActionType(this.apiValue);
  final String apiValue;
}
