import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/author.dart';
import '../models/book.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import '../state/book_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/state_views.dart';

class BookFormScreen extends StatefulWidget {
  const BookFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  Future<_Data>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_Data> _load() async {
    final books = context.read<BookRepository>();
    final authorRepo = context.read<AuthorRepository>();
    final genreRepo = context.read<GenreRepository>();
    final publisherRepo = context.read<PublisherRepository>();
    final authors = await authorRepo.allActive();
    final genres = await genreRepo.allActive();
    final publishers = await publisherRepo.allActive();
    Book? book;
    if (widget.isEditing) {
      book = await books.findById(widget.id!);
    }
    return _Data(
      book: book,
      authors: authors,
      genres: genres,
      publishers: publishers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Data>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingView();
        if (snap.hasError) return ErrorView(message: '${snap.error}');
        final data = snap.data!;
        if (widget.isEditing && data.book == null) {
          return const EmptyView(message: 'Книга не найдена');
        }
        return _BookForm(isEditing: widget.isEditing, data: data);
      },
    );
  }
}

class _BookForm extends StatefulWidget {
  const _BookForm({required this.isEditing, required this.data});

  final bool isEditing;
  final _Data data;

  @override
  State<_BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<_BookForm> {
  final _formKey = GlobalKey<EntityFormState>();
  late List<Author> _authors = widget.data.authors;
  late List<Genre> _genres = widget.data.genres;
  int? _lastPublisherId;

  Map<String, dynamic> get _initial {
    final b = widget.data.book;
    return {
      'title': b?.title ?? '',
      'isbn': b?.isbn ?? '',
      'year': '${b?.year ?? DateTime.now().year}',
      'pages': '${b?.pages ?? 100}',
      'publisherId':
          b?.publisherId ??
          (widget.data.publishers.isNotEmpty
              ? widget.data.publishers.first.id
              : null),
      'authorIds': List<int>.from(b?.authorIds ?? const []),
      'genreIds': List<int>.from(b?.genreIds ?? const []),
      'copiesTotal': '${b?.copiesTotal ?? 1}',
      'copiesAvailable': '${b?.copiesAvailable ?? 1}',
    };
  }

  Future<void> _applyCascade(int? publisherId) async {
    if (publisherId == null || publisherId == _lastPublisherId) return;
    _lastPublisherId = publisherId;
    final books = context.read<BookRepository>();
    final authorIds = await books.authorIdsLinkedToPublisher(publisherId);
    final genreIds = await books.genreIdsLinkedToPublisher(publisherId);
    setState(() {
      _authors = authorIds.isEmpty
          ? widget.data.authors
          : widget.data.authors
              .where((a) => authorIds.contains(a.id))
              .toList();
      if (_authors.isEmpty) _authors = widget.data.authors;

      _genres = genreIds.isEmpty
          ? widget.data.genres
          : widget.data.genres.where((g) => genreIds.contains(g.id)).toList();
      if (_genres.isEmpty) _genres = widget.data.genres;
    });
    _formKey.currentState?.updateValues(const {}, rebuildFields: true);
  }

  @override
  void initState() {
    super.initState();
    final publisherId = _initial['publisherId'] as int?;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyCascade(publisherId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      key: _formKey,
      title: widget.isEditing ? 'Редактирование книги' : 'Новая книга',
      initialValues: _initial,
      onChanged: (values) {
        final publisherId = values['publisherId'] as int?;
        _applyCascade(publisherId);
      },
      fields: [
        EntityFieldSpec(
          key: 'title',
          label: 'Название',
          type: EntityFieldType.text,
          stringValidator: (v) => Validators.combine(v, [
            (x) => Validators.required(x, label: 'Название'),
            (x) => Validators.maxLength(x, 200, label: 'Название'),
          ]),
        ),
        EntityFieldSpec(
          key: 'isbn',
          label: 'ISBN',
          type: EntityFieldType.text,
          stringValidator: (v) => Validators.combine(v, [
            (x) => Validators.required(x, label: 'ISBN'),
            (x) => Validators.minLength(x, 10, label: 'ISBN'),
            (x) => Validators.maxLength(x, 20, label: 'ISBN'),
          ]),
        ),
        EntityFieldSpec(
          key: 'year',
          label: 'Год',
          type: EntityFieldType.number,
          stringValidator: (v) => Validators.intInRange(
            v,
            min: 1400,
            max: DateTime.now().year + 1,
            label: 'Год',
          ),
        ),
        EntityFieldSpec(
          key: 'pages',
          label: 'Страниц',
          type: EntityFieldType.number,
          stringValidator: (v) => Validators.positiveInt(v, label: 'Страниц'),
        ),
        EntityFieldSpec(
          key: 'publisherId',
          label: 'Издательство',
          type: EntityFieldType.dropdown,
          dropdownItems: () => [
            for (final p in widget.data.publishers)
              DropdownMenuItem(value: p.id, child: Text(p.name)),
          ],
          idValidator: (v) => Validators.requiredId(v, label: 'издательство'),
        ),
        EntityFieldSpec(
          key: 'authorIds',
          label: 'Авторы',
          type: EntityFieldType.multiChip,
          chipItems: () => [
            for (final a in _authors) (id: a.id, label: a.fullName),
          ],
          idsValidator: (v) => Validators.requiredIds(v, label: 'автор'),
        ),
        EntityFieldSpec(
          key: 'genreIds',
          label: 'Жанры',
          type: EntityFieldType.multiChip,
          chipItems: () => [
            for (final g in _genres) (id: g.id, label: g.name),
          ],
          idsValidator: (v) => Validators.requiredIds(v, label: 'жанр'),
        ),
        EntityFieldSpec(
          key: 'copiesTotal',
          label: 'Всего экземпляров',
          type: EntityFieldType.number,
          stringValidator: (v) =>
              Validators.positiveInt(v, label: 'Всего экземпляров'),
        ),
        EntityFieldSpec(
          key: 'copiesAvailable',
          label: 'Доступно',
          type: EntityFieldType.number,
          stringValidator: (v) =>
              Validators.nonNegativeInt(v, label: 'Доступно'),
        ),
      ],
      onSubmit: (values) async {
        final books = context.read<BookRepository>();
        final isbn = '${values['isbn']}'.trim();
        if (await books.isbnExists(isbn, excludingId: widget.data.book?.id)) {
          return const FormSubmitResult(
            fieldErrors: {'isbn': 'ISBN уже используется'},
          );
        }

        final total = int.parse('${values['copiesTotal']}'.trim());
        final available = int.parse('${values['copiesAvailable']}'.trim());
        if (available > total) {
          return const FormSubmitResult(
            fieldErrors: {
              'copiesAvailable':
                  'Доступно не может быть больше общего числа экземпляров',
            },
          );
        }

        final book = Book(
          id: widget.data.book?.id ?? 0,
          title: '${values['title']}'.trim(),
          isbn: isbn,
          year: int.parse('${values['year']}'.trim()),
          pages: int.parse('${values['pages']}'.trim()),
          publisherId: values['publisherId'] as int,
          authorIds: List<int>.from(values['authorIds'] as List),
          genreIds: List<int>.from(values['genreIds'] as List),
          copiesTotal: total,
          copiesAvailable: available,
          deletedAt: widget.data.book?.deletedAt,
        );

        if (widget.isEditing) {
          await books.update(book);
        } else {
          await books.create(book);
        }
        if (context.mounted) {
          await context.read<BookListNotifier>().load();
        }
        return FormSubmitResult.ok;
      },
    );
  }
}

class _Data {
  const _Data({
    required this.book,
    required this.authors,
    required this.genres,
    required this.publishers,
  });

  final Book? book;
  final List<Author> authors;
  final List<Genre> genres;
  final List<Publisher> publishers;
}
