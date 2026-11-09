class BookQuery {
  final String search;
  final int? genreId;
  final int? publisherId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  BookQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? publisherId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    final filtersChanged = search != null ||
        genreId != _unset ||
        publisherId != _unset ||
        yearFrom != _unset ||
        yearTo != _unset ||
        includeDeleted != null;

    return BookQuery(
      search: search ?? this.search,
      genreId: genreId == _unset ? this.genreId : genreId as int?,
      publisherId:
          publisherId == _unset ? this.publisherId : publisherId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
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
    if (genreId != null) params['genreId'] = '$genreId';
    if (publisherId != null) params['publisherId'] = '$publisherId';
    if (yearFrom != null) params['yearFrom'] = '$yearFrom';
    if (yearTo != null) params['yearTo'] = '$yearTo';
    if (sortField != 'title' || !sortAscending) {
      params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) params['page'] = '$page';
    if (size != 10) params['size'] = '$size';
    if (includeDeleted) params['includeDeleted'] = '1';
    return params;
  }

  factory BookQuery.fromQueryParameters(Map<String, String> params) {
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

    return BookQuery(
      search: params['search'] ?? '',
      genreId: int.tryParse(params['genreId'] ?? ''),
      publisherId: int.tryParse(params['publisherId'] ?? ''),
      yearFrom: int.tryParse(params['yearFrom'] ?? ''),
      yearTo: int.tryParse(params['yearTo'] ?? ''),
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
