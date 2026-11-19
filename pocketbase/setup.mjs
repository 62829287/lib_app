const PB_URL = (process.env.PB_URL || 'http://127.0.0.1:8090').replace(/\/$/, '');
const EMAIL = process.env.PB_ADMIN_EMAIL;
const PASSWORD = process.env.PB_ADMIN_PASSWORD;

if (!EMAIL || !PASSWORD) {
  console.error('Set PB_ADMIN_EMAIL and PB_ADMIN_PASSWORD');
  process.exit(1);
}

async function req(method, path, { token, body } = {}) {
  const res = await fetch(`${PB_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: token } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  if (!res.ok) {
    const msg = typeof data === 'object' ? JSON.stringify(data) : text;
    throw new Error(`${method} ${path} → ${res.status}: ${msg}`);
  }
  return data;
}

async function authSuperuser() {
  const data = await req('POST', '/api/collections/_superusers/auth-with-password', {
    body: { identity: EMAIL, password: PASSWORD },
  });
  return data.token;
}

const text = (name, opts = {}) => ({
  name,
  type: 'text',
  required: !!opts.required,
  ...opts,
});
const number = (name, opts = {}) => ({
  name,
  type: 'number',
  required: !!opts.required,
  ...opts,
});
const date = (name) => ({ name, type: 'date', required: false });
const bool = (name) => ({ name, type: 'bool', required: false });
const json = (name) => ({ name, type: 'json', required: false });
const select = (name, values) => ({
  name,
  type: 'select',
  required: true,
  maxSelect: 1,
  values,
});
const relation = (name, collectionId, opts = {}) => ({
  name,
  type: 'relation',
  required: !!opts.required,
  collectionId,
  maxSelect: opts.maxSelect ?? 1,
  cascadeDelete: false,
});

function rulesCatalog() {
  return {
    listRule: '@request.auth.id != ""',
    viewRule: '@request.auth.id != ""',
    createRule: '@request.auth.id != "" && (@request.auth.role = "editor" || @request.auth.role = "admin")',
    updateRule: '@request.auth.id != "" && (@request.auth.role = "editor" || @request.auth.role = "admin")',
    deleteRule: '@request.auth.id != "" && @request.auth.role = "admin"',
  };
}

async function upsertCollection(token, body) {
  const list = await req('GET', '/api/collections?perPage=200', { token });
  const existing = (list.items || []).find((c) => c.name === body.name);
  if (existing) {
    return req('PATCH', `/api/collections/${existing.id}`, {
      token,
      body: { ...body, id: existing.id },
    });
  }
  return req('POST', '/api/collections', { token, body });
}

async function clearRecords(token, name) {
  for (;;) {
    const page = await req('GET', `/api/collections/${name}/records?perPage=100`, { token });
    const items = page.items || [];
    if (!items.length) break;
    for (const item of items) {
      await req('DELETE', `/api/collections/${name}/records/${item.id}`, { token });
    }
  }
}

async function main() {
  console.log('Auth as superuser…');
  const token = await authSuperuser();

  console.log('Ensure users auth fields…');
  const cols = await req('GET', '/api/collections?perPage=200', { token });
  const users = (cols.items || []).find((c) => c.name === 'users');
  if (!users) throw new Error('users collection missing');

  const userFields = [...(users.fields || users.schema || [])];
  const upsertField = (field) => {
    const i = userFields.findIndex((f) => f.name === field.name);
    if (i >= 0) userFields[i] = { ...userFields[i], ...field };
    else userFields.push(field);
  };
  upsertField({
    name: 'username',
    type: 'text',
    required: true,
    min: 3,
    max: 150,
  });
  upsertField({ name: 'name', type: 'text', required: false });
  upsertField({
    name: 'role',
    type: 'select',
    required: true,
    maxSelect: 1,
    values: ['viewer', 'editor', 'admin'],
  });

  const indexes = [...(users.indexes || [])].filter(
    (idx) => !String(idx).toLowerCase().includes('(username)'),
  );
  indexes.push(
    'CREATE UNIQUE INDEX `idx_users_username` ON `users` (`username`)',
  );

  await req('PATCH', `/api/collections/${users.id}`, {
    token,
    body: {
      fields: userFields,
      indexes,
    },
  });

  await req('PATCH', `/api/collections/${users.id}`, {
    token,
    body: {
      createRule: '@request.body.role = "viewer"',
      updateRule: '@request.auth.id = id || @request.auth.role = "admin"',
      listRule: '@request.auth.role = "admin"',
      viewRule: '@request.auth.id = id || @request.auth.role = "admin"',
      deleteRule: '@request.auth.role = "admin"',
      passwordAuth: {
        enabled: true,
        identityFields: ['email', 'username'],
      },
    },
  });

  const catalogRule = rulesCatalog();

  console.log('Upsert teams…');
  const teamsCol = await upsertCollection(token, {
    name: 'teams',
    type: 'base',
    ...catalogRule,
    fields: [
      text('name', { required: true }),
      text('tag', { required: false }),
      text('region', { required: false }),
      text('description', { required: false }),
      date('deletedAt'),
    ],
  });

  console.log('Upsert roles…');
  await upsertCollection(token, {
    name: 'roles',
    type: 'base',
    ...catalogRule,
    fields: [
      text('name', { required: true }),
      text('description', { required: false }),
      date('deletedAt'),
    ],
  });

  console.log('Upsert heroes…');
  await upsertCollection(token, {
    name: 'heroes',
    type: 'base',
    ...catalogRule,
    fields: [
      text('name', { required: true }),
      text('primaryAttribute', { required: true }),
      text('attackType', { required: true }),
      date('deletedAt'),
    ],
  });

  const refreshed = await req('GET', '/api/collections?perPage=200', { token });
  const byName = Object.fromEntries((refreshed.items || []).map((c) => [c.name, c]));

  console.log('Upsert pro_players…');
  await upsertCollection(token, {
    name: 'pro_players',
    type: 'base',
    ...catalogRule,
    fields: [
      text('nickname', { required: true }),
      text('realName', { required: false }),
      relation('teamId', byName.teams.id, { required: false }),
      number('rating', { required: false }),
      text('country', { required: false }),
      date('deletedAt'),
    ],
  });

  const again = await req('GET', '/api/collections?perPage=200', { token });
  const map = Object.fromEntries((again.items || []).map((c) => [c.name, c]));

  console.log('Upsert builds…');
  await upsertCollection(token, {
    name: 'builds',
    type: 'base',
    ...catalogRule,
    fields: [
      text('title', { required: true }),
      text('code', { required: true }),
      text('patch', { required: false }),
      number('difficulty', { required: true }),
      relation('heroId', map.heroes.id, { required: true }),
      relation('roleIds', map.roles.id, { maxSelect: 20 }),
      relation('proPlayerIds', map.pro_players.id, { maxSelect: 20 }),
      number('picks'),
      number('wins'),
      date('deletedAt'),
    ],
  });

  console.log('Upsert app_users…');
  await upsertCollection(token, {
    name: 'app_users',
    type: 'base',
    listRule: '@request.auth.role = "admin"',
    viewRule: '@request.auth.role = "admin"',
    createRule: '@request.auth.role = "admin"',
    updateRule: '@request.auth.role = "admin"',
    deleteRule: '@request.auth.role = "admin"',
    fields: [
      text('nickname', { required: true }),
      text('email', { required: true }),
      text('region', { required: false }),
      json('steam'),
      date('deletedAt'),
    ],
  });

  console.log('Clear & seed records…');
  for (const name of ['builds', 'pro_players', 'heroes', 'roles', 'teams', 'app_users']) {
    await clearRecords(token, name);
  }

  const teamSpirit = await req('POST', '/api/collections/teams/records', {
    token,
    body: {
      name: 'Team Spirit',
      tag: 'TS',
      region: 'СНГ',
      description: 'Чемпионы The International, сильный состав из СНГ.',
    },
  });
  const teamLiquid = await req('POST', '/api/collections/teams/records', {
    token,
    body: {
      name: 'Team Liquid',
      tag: 'Liquid',
      region: 'Европа',
      description: 'Европейская организация с богатой историей в Dota 2.',
    },
  });
  const xg = await req('POST', '/api/collections/teams/records', {
    token,
    body: {
      name: 'Xtreme Gaming',
      tag: 'XG',
      region: 'Китай',
      description: 'Китайский состав, известный агрессивной игрой.',
    },
  });
  const noTeam = await req('POST', '/api/collections/teams/records', {
    token,
    body: {
      name: 'No team',
      tag: '-',
      region: 'Без региона',
      description: 'Свободные агенты без контракта с организацией.',
    },
  });

  const roleBodies = [
    { name: 'Carry', description: 'Выносит БФ к 40 минуте.' },
    { name: 'Mid', description: 'ГДЕ ГАНК АЛО?' },
    { name: 'Offlane', description: 'нужен танк.' },
    { name: 'Soft Support', description: 'синий вард за 4200 норм тема.' },
    { name: 'Hard Support', description: 'синий вард за 4200 тоже норм.' },
  ];
  const roles = [];
  for (const b of roleBodies) {
    roles.push(await req('POST', '/api/collections/roles/records', { token, body: b }));
  }

  const heroBodies = [
    { name: 'Phantom Assassin', primaryAttribute: 'Ловкость', attackType: 'Ближний' },
    { name: 'Invoker', primaryAttribute: 'Универсал', attackType: 'Дальний' },
    { name: 'Pudge', primaryAttribute: 'Сила', attackType: 'Ближний' },
    { name: 'Anti-Mage', primaryAttribute: 'Ловкость', attackType: 'Ближний' },
    { name: 'Crystal Maiden', primaryAttribute: 'Интеллект', attackType: 'Дальний' },
    { name: 'Axe', primaryAttribute: 'Сила', attackType: 'Ближний' },
    { name: 'Storm Spirit', primaryAttribute: 'Интеллект', attackType: 'Дальний' },
    { name: 'Shadow Fiend', primaryAttribute: 'Ловкость', attackType: 'Дальний' },
  ];
  const heroes = [];
  for (const b of heroBodies) {
    heroes.push(await req('POST', '/api/collections/heroes/records', { token, body: b }));
  }

  const proBodies = [
    { nickname: 'Yatoro', realName: 'Илья Мулярчук', teamId: teamSpirit.id, rating: 9200, country: 'Украина' },
    { nickname: 'Collapse', realName: 'Магомед Халилов', teamId: noTeam.id, rating: 9100, country: 'Россия' },
    { nickname: 'TORONTOTOKYO', realName: 'Александр Хертек', teamId: noTeam.id, rating: 8800, country: 'Россия' },
    { nickname: 'Miposhka', realName: 'Ярослав Найдёнов', teamId: noTeam.id, rating: 8500, country: 'Россия' },
    { nickname: 'Nisha', realName: 'Михал Янковски', teamId: teamLiquid.id, rating: 9000, country: 'Польша' },
    { nickname: 'Ame', realName: 'Ван Чунью', teamId: xg.id, rating: 8950, country: 'Китай' },
    { nickname: 'Quinn', realName: 'Quinn Callahan', teamId: noTeam.id, rating: 9050, country: 'США' },
    { nickname: 'Sneyking', realName: 'Jingjun Wu', teamId: noTeam.id, rating: 8600, country: 'США' },
  ];
  const pros = [];
  for (const b of proBodies) {
    pros.push(await req('POST', '/api/collections/pro_players/records', { token, body: b }));
  }

  const buildBodies = [
    { title: 'PA Battle Fury Tempo', code: 'PA-BF-736A', patch: '7.41c', difficulty: 3, heroId: heroes[0].id, proPlayerIds: [pros[0].id, pros[5].id], roleIds: [roles[0].id], picks: 1240, wins: 680 },
    { title: 'Invoker Mid Quas-Wex', code: 'INV-QW-736', patch: '7.41c', difficulty: 5, heroId: heroes[1].id, proPlayerIds: [pros[4].id, pros[6].id], roleIds: [roles[1].id], picks: 890, wins: 470 },
    { title: 'Pudge Roaming Hook', code: 'PUDGE-HOOK', patch: '7.41c', difficulty: 2, heroId: heroes[2].id, proPlayerIds: [pros[2].id], roleIds: [roles[3].id, roles[2].id], picks: 2100, wins: 1050 },
    { title: 'AM Manta Corrosive', code: 'AM-MANTA', patch: '7.41c', difficulty: 3, heroId: heroes[3].id, proPlayerIds: [pros[0].id], roleIds: [roles[0].id], picks: 980, wins: 540 },
    { title: 'CM Hard Support Glimmer', code: 'CM-GLIM', patch: '7.41c', difficulty: 1, heroId: heroes[4].id, proPlayerIds: [pros[3].id, pros[7].id], roleIds: [roles[4].id], picks: 1560, wins: 820 },
    { title: 'Axe Blink Call Offlane', code: 'AXE-BLINK', patch: '7.41c', difficulty: 2, heroId: heroes[5].id, proPlayerIds: [pros[1].id], roleIds: [roles[2].id], picks: 1340, wins: 710 },
    { title: 'Storm Orchid Mid', code: 'STORM-ORCH', patch: '7.41c', difficulty: 4, heroId: heroes[6].id, proPlayerIds: [pros[4].id, pros[2].id], roleIds: [roles[1].id], picks: 760, wins: 400 },
    { title: 'SF Mid Desolator', code: 'SF-DESO', patch: '7.41c', difficulty: 4, heroId: heroes[7].id, proPlayerIds: [pros[6].id], roleIds: [roles[1].id, roles[0].id], picks: 1100, wins: 560 },
  ];
  for (const b of buildBodies) {
    await req('POST', '/api/collections/builds/records', { token, body: b });
  }

  const appUsers = [
    { nickname: 'zxcksdksdka', email: 'shadow@dota.mail', region: 'EU East', steam: { url: 'https://steamcommunity.com/id/zxcksdksdka', nickname: 'zxcksdksdka', rating: 4200 } },
    { nickname: 'wards', email: 'ward@dota.mail', region: 'EU West', steam: { url: 'https://steamcommunity.com/id/only5pos', nickname: 'pos 5 only', rating: 3100 } },
    { nickname: 'midOrfeed', email: 'mid@dota.mail', region: 'Russia', steam: { url: 'https://steamcommunity.com/id/mid_or_feed', nickname: 'MidOrFeed', rating: 5100 } },
  ];
  for (const b of appUsers) {
    await req('POST', '/api/collections/app_users/records', { token, body: b });
  }

  console.log('Seed auth users…');
  const authUsers = [
    { email: 'reader@dota.local', username: 'reader', name: 'Reader', password: 'reader123!', passwordConfirm: 'reader123!', role: 'viewer' },
    { email: 'editor@dota.local', username: 'editor', name: 'Editor', password: 'editor123!', passwordConfirm: 'editor123!', role: 'editor' },
    { email: 'admin@dota.local', username: 'admin', name: 'Admin', password: 'admin123!', passwordConfirm: 'admin123!', role: 'admin' },
  ];
  for (const u of authUsers) {
    const existing = await req(
      'GET',
      `/api/collections/users/records?filter=${encodeURIComponent(`email="${u.email}"`)}`,
      { token },
    );
    if (existing.items?.length) {
      await req('PATCH', `/api/collections/users/records/${existing.items[0].id}`, {
        token,
        body: { username: u.username, name: u.name, role: u.role, password: u.password, passwordConfirm: u.passwordConfirm },
      });
    } else {
      await req('POST', '/api/collections/users/records', { token, body: u });
    }
  }

  console.log('Done. PB ready at', PB_URL);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
