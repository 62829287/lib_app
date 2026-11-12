import '../models/app_user.dart';
import '../models/build.dart';
import '../models/dota_hero.dart';
import '../models/pro_player.dart';
import '../models/role.dart';
import '../models/steam_profile.dart';

const seedRoles = <Role>[
  Role(
    id: 1,
    name: 'Carry',
    description: 'Выносит БФ к 40 минуте.',
  ),
  Role(
    id: 2,
    name: 'Mid',
    description: 'ГДЕ ГАНК АЛО?',
  ),
  Role(
    id: 3,
    name: 'Offlane',
    description: 'нужен танк.',
  ),
  Role(
    id: 4,
    name: 'Soft Support',
    description: 'синий вард за 4200 норм тема.',
  ),
  Role(
    id: 5,
    name: 'Hard Support',
    description: 'синий вард за 4200 тоже норм, но не так норм, как раньше.',
  ),
];

const seedHeroes = <DotaHero>[
  DotaHero(id: 1, name: 'Phantom Assassin', primaryAttribute: 'Ловкость', attackType: 'Ближний'),
  DotaHero(id: 2, name: 'Invoker', primaryAttribute: 'Универсал', attackType: 'Дальний'),
  DotaHero(id: 3, name: 'Pudge', primaryAttribute: 'Сила', attackType: 'Ближний'),
  DotaHero(id: 4, name: 'Anti-Mage', primaryAttribute: 'Ловкость', attackType: 'Ближний'),
  DotaHero(id: 5, name: 'Crystal Maiden', primaryAttribute: 'Интеллект', attackType: 'Дальний'),
  DotaHero(id: 6, name: 'Axe', primaryAttribute: 'Сила', attackType: 'Ближний'),
  DotaHero(id: 7, name: 'Storm Spirit', primaryAttribute: 'Интеллект', attackType: 'Дальний'),
  DotaHero(id: 8, name: 'Shadow Fiend', primaryAttribute: 'Ловкость', attackType: 'Дальний'),
];

const seedProPlayers = <ProPlayer>[
  ProPlayer(id: 1, nickname: 'Yatoro', realName: 'Илья Мулярчук', team: 'Team Spirit', rating: 9200, country: 'Украина'),
  ProPlayer(id: 2, nickname: 'Collapse', realName: 'Магомед Халилов', team: 'No team', rating: 9100, country: 'Россия'),
  ProPlayer(id: 3, nickname: 'TORONTOTOKYO', realName: 'Александр Хертек', team: 'No team', rating: 8800, country: 'Россия'),
  ProPlayer(id: 4, nickname: 'Miposhka', realName: 'Ярослав Найдёнов', team: 'No team', rating: 8500, country: 'Россия'),
  ProPlayer(id: 5, nickname: 'Nisha', realName: 'Михал Янковски', team: 'Team Liquid', rating: 9000, country: 'Польша'),
  ProPlayer(id: 6, nickname: 'Ame', realName: 'Ван Чунью', team: 'Xtreme Gaming', rating: 8950, country: 'Китай'),
  ProPlayer(id: 7, nickname: 'Quinn', realName: 'Quinn Callahan', team: 'No team', rating: 9050, country: 'США'),
  ProPlayer(id: 8, nickname: 'Sneyking', realName: 'Jingjun Wu', team: 'No team', rating: 8600, country: 'США'),
];

const seedBuilds = <Build>[
  Build(
    id: 1,
    title: 'PA Battle Fury Tempo',
    code: 'PA-BF-736A',
    patch: '7.41c',
    difficulty: 3,
    heroId: 1,
    proPlayerIds: [1, 6],
    roleIds: [1],
    picks: 1240,
    wins: 680,
  ),
  Build(
    id: 2,
    title: 'Invoker Mid Quas-Wex',
    code: 'INV-QW-736',
    patch: '7.41c',
    difficulty: 5,
    heroId: 2,
    proPlayerIds: [5, 7],
    roleIds: [2],
    picks: 890,
    wins: 470,
  ),
  Build(
    id: 3,
    title: 'Pudge Roaming Hook',
    code: 'PUDGE-HOOK',
    patch: '7.41c',
    difficulty: 2,
    heroId: 3,
    proPlayerIds: [3],
    roleIds: [4, 3],
    picks: 2100,
    wins: 1050,
  ),
  Build(
    id: 4,
    title: 'AM Manta Corrosive',
    code: 'AM-MANTA',
    patch: '7.41c',
    difficulty: 3,
    heroId: 4,
    proPlayerIds: [1],
    roleIds: [1],
    picks: 980,
    wins: 540,
  ),
  Build(
    id: 5,
    title: 'CM Hard Support Glimmer',
    code: 'CM-GLIM',
    patch: '7.41c',
    difficulty: 1,
    heroId: 5,
    proPlayerIds: [4, 8],
    roleIds: [5],
    picks: 1560,
    wins: 820,
  ),
  Build(
    id: 6,
    title: 'Axe Blink Call Offlane',
    code: 'AXE-BLINK',
    patch: '7.41c',
    difficulty: 2,
    heroId: 6,
    proPlayerIds: [2],
    roleIds: [3],
    picks: 1340,
    wins: 710,
  ),
  Build(
    id: 7,
    title: 'Storm Orchid Mid',
    code: 'STORM-ORCH',
    patch: '7.41c',
    difficulty: 4,
    heroId: 7,
    proPlayerIds: [5, 3],
    roleIds: [2],
    picks: 760,
    wins: 400,
  ),
  Build(
    id: 8,
    title: 'SF Mid Desolator',
    code: 'SF-DESO',
    patch: '7.41c',
    difficulty: 4,
    heroId: 8,
    proPlayerIds: [7],
    roleIds: [2, 1],
    picks: 1100,
    wins: 560,
  ),
];

final seedUsers = <AppUser>[
  AppUser(
    id: 1,
    nickname: 'zxcksdksdka',
    email: 'shadow@dota.mail',
    region: 'EU East',
    steam: SteamProfile(
      url: 'https://steamcommunity.com/id/zxcksdksdka',
      nickname: 'zxcksdksdka',
      rating: 4200,
    ),
  ),
  AppUser(
    id: 2,
    nickname: 'wards',
    email: 'ward@dota.mail',
    region: 'EU West',
    steam: SteamProfile(
      url: 'https://steamcommunity.com/id/only5pos',
      nickname: 'pos 5 only',
      rating: 3100,
    ),
  ),
  AppUser(
    id: 3,
    nickname: 'midOrfeed',
    email: 'mid@dota.mail',
    region: 'Russia',
    steam: SteamProfile(
      url: 'https://steamcommunity.com/id/mid_or_feed',
      nickname: 'MidOrFeed',
      rating: 5100,
    ),
  ),
  AppUser(
    id: 4,
    nickname: '33king',
    email: 'rosh@dota.mail',
    region: 'SEA',
    steam: SteamProfile(
      url: 'https://steamcommunity.com/id/33king',
      nickname: 'not human (животное)',
      rating: 2800,
    ),
  ),
  AppUser(
    id: 5,
    nickname: 'Unnamed User',
    email: 'courier@dota.mail',
    region: 'China',
    steam: SteamProfile(
      url: 'https://steamcommunity.com/id/89792864315690243',
      nickname: 'жоский паца',
      rating: 3600,
    ),
  ),
];
