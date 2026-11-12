class BuildQuery {
  final String search;
  final int? roleId;
  final int? heroId;
  final int? proPlayerId;
  final int? difficultyFrom;
  final int? difficultyTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BuildQuery({
    this.search = '',
    this.roleId,
    this.heroId,
    this.proPlayerId,
    this.difficultyFrom,
    this.difficultyTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  BuildQuery copyWith({
    String? search,
    Object? roleId = _unset,
    Object? heroId = _unset,
    Object? proPlayerId = _unset,
    Object? difficultyFrom = _unset,
    Object? difficultyTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    final filtersChanged = search != null ||
        roleId != _unset ||
        heroId != _unset ||
        proPlayerId != _unset ||
        difficultyFrom != _unset ||
        difficultyTo != _unset ||
        includeDeleted != null;

    return BuildQuery(
      search: search ?? this.search,
      roleId: roleId == _unset ? this.roleId : roleId as int?,
      heroId: heroId == _unset ? this.heroId : heroId as int?,
      proPlayerId:
          proPlayerId == _unset ? this.proPlayerId : proPlayerId as int?,
      difficultyFrom: difficultyFrom == _unset
          ? this.difficultyFrom
          : difficultyFrom as int?,
      difficultyTo:
          difficultyTo == _unset ? this.difficultyTo : difficultyTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? (filtersChanged ? 1 : this.page),
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (search.trim().isNotEmpty) params['search'] = search.trim();
    if (roleId != null) params['roleId'] = '$roleId';
    if (heroId != null) params['heroId'] = '$heroId';
    if (proPlayerId != null) params['proPlayerId'] = '$proPlayerId';
    if (difficultyFrom != null) params['difficultyFrom'] = '$difficultyFrom';
    if (difficultyTo != null) params['difficultyTo'] = '$difficultyTo';
    if (sortField != 'title' || !sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['includeDeleted'] = '1';
    return params;
  }

  factory BuildQuery.fromQueryParameters(Map<String, String> params) {
    final sortRaw = params['sort'];
    var sortField = 'title';
    var sortAscending = true;
    if (sortRaw != null && sortRaw.isNotEmpty) {
      final parts = sortRaw.split(',');
      sortField = parts.first;
      if (parts.length > 1) {
        sortAscending = parts[1].toLowerCase() != 'desc';
      }
    }

    return BuildQuery(
      search: params['search'] ?? '',
      roleId: int.tryParse(params['roleId'] ?? ''),
      heroId: int.tryParse(params['heroId'] ?? ''),
      proPlayerId: int.tryParse(params['proPlayerId'] ?? ''),
      difficultyFrom: int.tryParse(params['difficultyFrom'] ?? ''),
      difficultyTo: int.tryParse(params['difficultyTo'] ?? ''),
      sortField: sortField,
      sortAscending: sortAscending,
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == '1' ||
          params['includeDeleted'] == 'true',
    );
  }

  static const _unset = Object();
}
