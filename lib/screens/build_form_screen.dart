import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/build.dart';
import '../models/dota_hero.dart';
import '../models/pro_player.dart';
import '../models/role.dart';
import '../repositories/build_repository.dart';
import '../repositories/hero_repository.dart';
import '../repositories/pro_player_repository.dart';
import '../repositories/role_repository.dart';
import '../state/build_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/state_views.dart';

class BuildFormScreen extends StatefulWidget {
  const BuildFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<BuildFormScreen> createState() => _BuildFormScreenState();
}

class _BuildFormScreenState extends State<BuildFormScreen> {
  Future<_Data>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_Data> _load() async {
    final builds = context.read<BuildRepository>();
    final heroRepo = context.read<HeroRepository>();
    final proRepo = context.read<ProPlayerRepository>();
    final roleRepo = context.read<RoleRepository>();
    final heroes = await heroRepo.allActive();
    final proPlayers = await proRepo.allActive();
    final roles = await roleRepo.allActive();
    Build? build;
    if (widget.isEditing) {
      build = await builds.findById(widget.id!);
    }
    return _Data(
      build: build,
      heroes: heroes,
      proPlayers: proPlayers,
      roles: roles,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Data>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snap.hasError) {
          return ErrorView(
            message: '${snap.error}',
            onRetry: () => setState(() => _future = _load()),
          );
        }
        if (!snap.hasData) return const LoadingView();
        final data = snap.data!;
        if (widget.isEditing && data.build == null) {
          return const EmptyView(message: 'Сборка не найдена');
        }
        return _BuildForm(isEditing: widget.isEditing, data: data);
      },
    );
  }
}

class _BuildForm extends StatefulWidget {
  const _BuildForm({required this.isEditing, required this.data});

  final bool isEditing;
  final _Data data;

  @override
  State<_BuildForm> createState() => _BuildFormState();
}

class _BuildFormState extends State<_BuildForm> {
  final _formKey = GlobalKey<EntityFormState>();
  late List<ProPlayer> _proPlayers = widget.data.proPlayers;
  late List<Role> _roles = widget.data.roles;
  int? _lastHeroId;

  Map<String, dynamic> get _initial {
    final b = widget.data.build;
    return {
      'title': b?.title ?? '',
      'code': b?.code ?? '',
      'patch': b?.patch ?? '',
      'difficulty': '${b?.difficulty ?? 3}',
      'heroId':
          b?.heroId ??
          (widget.data.heroes.isNotEmpty ? widget.data.heroes.first.id : null),
      'proPlayerIds': List<int>.from(b?.proPlayerIds ?? const []),
      'roleIds': List<int>.from(b?.roleIds ?? const []),
      'picks': '${b?.picks ?? 0}',
      'wins': '${b?.wins ?? 0}',
    };
  }

  Future<void> _applyCascade(int? heroId) async {
    if (heroId == null || heroId == _lastHeroId) return;
    _lastHeroId = heroId;
    final builds = context.read<BuildRepository>();
    final proIds = await builds.proPlayerIdsLinkedToHero(heroId);
    final roleIds = await builds.roleIdsLinkedToHero(heroId);
    if (!mounted) return;
    setState(() {
      _proPlayers = proIds.isEmpty
          ? widget.data.proPlayers
          : widget.data.proPlayers.where((p) => proIds.contains(p.id)).toList();
      if (_proPlayers.isEmpty) _proPlayers = widget.data.proPlayers;
      _roles = roleIds.isEmpty
          ? widget.data.roles
          : widget.data.roles.where((r) => roleIds.contains(r.id)).toList();
      if (_roles.isEmpty) _roles = widget.data.roles;
    });
    _formKey.currentState?.updateValues(const {}, rebuildFields: true);
  }

  @override
  void initState() {
    super.initState();
    final heroId = _initial['heroId'] as int?;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyCascade(heroId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return EntityForm(
      key: _formKey,
      title: widget.isEditing ? 'Редактирование сборки' : 'Новая сборка',
      initialValues: _initial,
      onChanged: (values) {
        final heroId = values['heroId'] as int?;
        _applyCascade(heroId);
      },
      fields: [
        const EntityFieldSpec(
          key: 'title',
          label: 'Название',
          type: EntityFieldType.text,
        ),
        const EntityFieldSpec(
          key: 'code',
          label: 'Код',
          type: EntityFieldType.text,
        ),
        const EntityFieldSpec(
          key: 'patch',
          label: 'Патч',
          type: EntityFieldType.text,
        ),
        const EntityFieldSpec(
          key: 'difficulty',
          label: 'Сложность (1–5)',
          type: EntityFieldType.number,
        ),
        EntityFieldSpec(
          key: 'heroId',
          label: 'Герой',
          type: EntityFieldType.dropdown,
          dropdownItems: () => [
            for (final h in widget.data.heroes)
              DropdownMenuItem(value: h.id, child: Text(h.name)),
          ],
        ),
        EntityFieldSpec(
          key: 'proPlayerIds',
          label: 'Про-игроки',
          type: EntityFieldType.multiChip,
          chipItems: () => [
            for (final p in _proPlayers) (id: p.id, label: p.nickname),
          ],
        ),
        EntityFieldSpec(
          key: 'roleIds',
          label: 'Роли',
          type: EntityFieldType.multiChip,
          chipItems: () => [
            for (final r in _roles) (id: r.id, label: r.name),
          ],
        ),
        const EntityFieldSpec(
          key: 'picks',
          label: 'Пики',
          type: EntityFieldType.number,
        ),
        const EntityFieldSpec(
          key: 'wins',
          label: 'Победы',
          type: EntityFieldType.number,
        ),
      ],
      onSubmit: (values) async {
        final builds = context.read<BuildRepository>();
        final build = Build(
          id: widget.data.build?.id ?? 0,
          title: '${values['title']}'.trim(),
          code: '${values['code']}'.trim(),
          patch: '${values['patch']}'.trim(),
          difficulty: int.tryParse('${values['difficulty']}'.trim()) ?? 0,
          heroId: values['heroId'] as int? ?? 0,
          proPlayerIds: List<int>.from(
            (values['proPlayerIds'] as List?) ?? const [],
          ),
          roleIds: List<int>.from((values['roleIds'] as List?) ?? const []),
          picks: int.tryParse('${values['picks']}'.trim()) ?? -1,
          wins: int.tryParse('${values['wins']}'.trim()) ?? -1,
          deletedAt: widget.data.build?.deletedAt,
        );

        if (widget.isEditing) {
          await builds.update(build);
        } else {
          await builds.create(build);
        }
        if (context.mounted) {
          await context.read<BuildListNotifier>().load();
        }
        return FormSubmitResult.ok;
      },
    );
  }
}

class _Data {
  const _Data({
    required this.build,
    required this.heroes,
    required this.proPlayers,
    required this.roles,
  });

  final Build? build;
  final List<DotaHero> heroes;
  final List<ProPlayer> proPlayers;
  final List<Role> roles;
}
