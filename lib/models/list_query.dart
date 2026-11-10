class ListQuery {
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;
  final Map<String, String> filters;

  const ListQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
    this.filters = const {},
  });

  ListQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
    Map<String, String>? filters,
    bool resetPageOnFilter = true,
  }) {
    final nextFilters = filters ?? this.filters;
    final filtersChanged = filters != null;
    final searchChanged = search != null;
    final includeChanged = includeDeleted != null;
    final shouldReset = resetPageOnFilter &&
        (filtersChanged || searchChanged || includeChanged);

    return ListQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? (shouldReset ? 1 : this.page),
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
      filters: nextFilters,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (search.trim().isNotEmpty) params['search'] = search.trim();
    if (sortField.isNotEmpty &&
        (sortField != 'name' || !sortAscending)) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['includeDeleted'] = '1';
    params.addAll(filters);
    return params;
  }

  factory ListQuery.fromQueryParameters(
    Map<String, String> params, {
    String defaultSort = 'name',
  }) {
    final sortRaw = params['sort'];
    var sortField = defaultSort;
    var sortAscending = true;
    if (sortRaw != null && sortRaw.isNotEmpty) {
      final parts = sortRaw.split(',');
      sortField = parts.first;
      if (parts.length > 1) {
        sortAscending = parts[1].toLowerCase() != 'desc';
      }
    }

    final known = {
      'search',
      'sort',
      'page',
      'size',
      'includeDeleted',
    };
    final filters = <String, String>{};
    for (final entry in params.entries) {
      if (!known.contains(entry.key) && entry.value.isNotEmpty) {
        filters[entry.key] = entry.value;
      }
    }

    return ListQuery(
      search: params['search'] ?? '',
      sortField: sortField,
      sortAscending: sortAscending,
      page: int.tryParse(params['page'] ?? '') ?? 1,
      size: int.tryParse(params['size'] ?? '') ?? 10,
      includeDeleted: params['includeDeleted'] == '1' ||
          params['includeDeleted'] == 'true',
      filters: filters,
    );
  }
}
