class AuthorQuery {
  final String search;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const AuthorQuery({
    this.search = '',
    this.country,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  AuthorQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    final filtersChanged =
        search != null || country != _unset || includeDeleted != null;

    return AuthorQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
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
    if (country != null && country!.isNotEmpty) params['country'] = country!;
    if (sortField != 'lastName' || !sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['includeDeleted'] = '1';
    return params;
  }

  factory AuthorQuery.fromQueryParameters(Map<String, String> params) {
    final sortRaw = params['sort'];
    var sortField = 'lastName';
    var sortAscending = true;
    if (sortRaw != null && sortRaw.isNotEmpty) {
      final parts = sortRaw.split(',');
      sortField = parts.first;
      if (parts.length > 1) {
        sortAscending = parts[1].toLowerCase() != 'desc';
      }
    }

    return AuthorQuery(
      search: params['search'] ?? '',
      country: params['country'],
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
