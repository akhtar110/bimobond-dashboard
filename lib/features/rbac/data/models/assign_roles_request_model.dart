class AssignRolesRequestModel {
  const AssignRolesRequestModel(this.roleIds);

  final List<String> roleIds;

  Map<String, dynamic> toJson() => {'roleIds': roleIds};
}

class SaveRoleRequestModel {
  const SaveRoleRequestModel({
    required this.slug,
    required this.name,
    required this.permissionIds,
    this.description,
    this.isActive,
  });

  final String slug;
  final String name;
  final List<String> permissionIds;
  final String? description;
  final bool? isActive;

  /// POST body: slug and name are mandatory on create.
  Map<String, dynamic> toCreateJson() => {
    'slug': slug,
    'name': name,
    'permissionIds': permissionIds,
    if (description != null) 'description': description!.trim(),
    if (isActive != null) 'isActive': isActive,
  };

  /// PATCH body: only sends fields that carry a value so partial updates
  /// stay partial.
  Map<String, dynamic> toPatchJson() => {
    if (slug.isNotEmpty) 'slug': slug,
    if (name.isNotEmpty) 'name': name,
    'permissionIds': permissionIds,
    if (description != null) 'description': description!.trim(),
    if (isActive != null) 'isActive': isActive,
  };
}
