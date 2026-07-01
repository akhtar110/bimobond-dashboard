/// Actions supported by `POST /users/admin/bulk`.
enum AdminBulkUserAction {
  delete('DELETE'),
  ban('BAN'),
  unban('UNBAN'),
  update('UPDATE'),
  updateRoles('UPDATE_ROLES'),
  promote('PROMOTE'),
  demote('DEMOTE');

  const AdminBulkUserAction(this.apiValue);

  final String apiValue;
}
