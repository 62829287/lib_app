const express = require('express');
const cors = require('cors');
const seed = require('./seed');

const app = express();
const PORT = process.env.PORT || 8080;

const db = {
  roles: structuredClone(seed.roles),
  heroes: structuredClone(seed.heroes),
  proPlayers: structuredClone(seed.proPlayers),
  builds: structuredClone(seed.builds),
  users: structuredClone(seed.users),
};

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

app.get('/', (_req, res) => {
  res.type('text').send('Dota Builds mock API.');
});

app.get('/api', (_req, res) => {
  res.json({
    ok: true,
    message: 'Mock API is running',
    endpoints: [
      '/api/builds',
      '/api/heroes',
      '/api/roles',
      '/api/pro-players',
      '/api/users',
    ],
  });
});

app.use('/api', (req, res, next) => {
  const fail = req.query.__fail;
  const delayMs = Number(req.query.__delay || 0);
  const run = () => {
    if (fail) {
      const code = Number(fail) || 500;
      return res.status(code).json({
        message: `Принудительная ошибка __fail=${fail}`,
      });
    }
    next();
  };
  if (delayMs > 0) {
    setTimeout(run, delayMs);
  } else {
    run();
  }
});

function nextId(list) {
  return list.reduce((m, x) => Math.max(m, x.id || 0), 0) + 1;
}

function fail422(res, errors) {
  return res.status(422).json({ message: 'Ошибка валидации', errors });
}

function validateRoleBody(body, excludingId) {
  const errors = {};
  const name = String(body.name || '').trim();
  const description = String(body.description || '');
  if (!name) errors.name = 'Название обязательно';
  else if (name.length > 80) errors.name = 'Название: не больше 80 символов';
  else if (
    db.roles.some(
      (r) =>
        !r.deletedAt &&
        r.name.toLowerCase() === name.toLowerCase() &&
        (excludingId == null || r.id !== excludingId),
    )
  ) {
    errors.name = 'Роль с таким названием уже есть';
  }
  if (description.length > 500) errors.description = 'Описание: не больше 500 символов';
  return errors;
}

function validateHeroBody(body, excludingId) {
  const errors = {};
  const name = String(body.name || '').trim();
  const primaryAttribute = String(body.primaryAttribute || '').trim();
  const attackType = String(body.attackType || '').trim();
  if (!name) errors.name = 'Имя обязательно';
  else if (name.length > 80) errors.name = 'Имя: не больше 80 символов';
  else if (
    db.heroes.some(
      (h) =>
        !h.deletedAt &&
        h.name.toLowerCase() === name.toLowerCase() &&
        (excludingId == null || h.id !== excludingId),
    )
  ) {
    errors.name = 'Герой с таким именем уже есть';
  }
  if (!primaryAttribute) errors.primaryAttribute = 'Атрибут обязателен';
  else if (primaryAttribute.length > 40) {
    errors.primaryAttribute = 'Атрибут: не больше 40 символов';
  }
  if (!attackType) errors.attackType = 'Тип атаки обязателен';
  else if (attackType.length > 40) errors.attackType = 'Тип атаки: не больше 40 символов';
  return errors;
}

function validateProBody(body, excludingId) {
  const errors = {};
  const nickname = String(body.nickname || '').trim();
  const realName = String(body.realName || '').trim();
  const team = String(body.team || '').trim();
  const country = String(body.country || '').trim();
  const rating = Number(body.rating);
  if (!nickname) errors.nickname = 'Ник обязателен';
  else if (nickname.length > 80) errors.nickname = 'Ник: не больше 80 символов';
  else if (
    db.proPlayers.some(
      (p) =>
        !p.deletedAt &&
        p.nickname.toLowerCase() === nickname.toLowerCase() &&
        (excludingId == null || p.id !== excludingId),
    )
  ) {
    errors.nickname = 'Ник уже используется';
  }
  if (!realName) errors.realName = 'Имя обязательно';
  else if (realName.length > 80) errors.realName = 'Имя: не больше 80 символов';
  if (!team) errors.team = 'Команда обязательна';
  else if (team.length > 80) errors.team = 'Команда: не больше 80 символов';
  if (!Number.isFinite(rating) || rating <= 0) {
    errors.rating = 'Рейтинг должен быть больше 0';
  }
  if (!country) errors.country = 'Страна обязательна';
  else if (country.length > 80) errors.country = 'Страна: не больше 80 символов';
  return errors;
}

function validateUserBody(body, excludingId) {
  const errors = {};
  const nickname = String(body.nickname || '').trim();
  const email = String(body.email || '').trim();
  const region = String(body.region || '').trim();
  const steam = body.steam || {};
  const steamUrl = String(steam.url || '').trim();
  const steamNickname = String(steam.nickname || '').trim();
  const steamRating = Number(steam.rating);
  if (!nickname) errors.nickname = 'Ник обязателен';
  else if (nickname.length > 80) errors.nickname = 'Ник: не больше 80 символов';
  if (!email) errors.email = 'Email обязателен';
  else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    errors.email = 'Некорректный формат email';
  } else if (
    db.users.some(
      (u) =>
        u.email.toLowerCase() === email.toLowerCase() &&
        (excludingId == null || u.id !== excludingId),
    )
  ) {
    errors.email = 'Email уже используется';
  }
  if (!region) errors.region = 'Регион обязателен';
  else if (region.length > 80) errors.region = 'Регион: не больше 80 символов';
  if (!steamUrl) errors.steamUrl = 'URL обязателен';
  else if (steamUrl.length > 200) errors.steamUrl = 'URL: не больше 200 символов';
  if (!steamNickname) errors.steamNickname = 'Ник Steam обязателен';
  else if (steamNickname.length > 80) {
    errors.steamNickname = 'Ник Steam: не больше 80 символов';
  }
  if (!Number.isFinite(steamRating) || steamRating < 0) {
    errors.steamRating = 'Рейтинг не может быть отрицательным';
  }
  return errors;
}

function validateBuildBody(body, excludingId) {
  const errors = {};
  const title = String(body.title || '').trim();
  const code = String(body.code || '').trim();
  const patch = String(body.patch || '').trim();
  const difficulty = Number(body.difficulty);
  const picks = Number(body.picks);
  const wins = Number(body.wins);
  const heroId = Number(body.heroId);
  const proPlayerIds = Array.isArray(body.proPlayerIds) ? body.proPlayerIds : [];
  const roleIds = Array.isArray(body.roleIds) ? body.roleIds : [];

  if (!title) errors.title = 'Название обязательно';
  else if (title.length > 200) errors.title = 'Название: не больше 200 символов';

  if (!code) errors.code = 'Код обязателен';
  else if (code.length < 4) errors.code = 'Код: не меньше 4 символов';
  else if (code.length > 40) errors.code = 'Код: не больше 40 символов';
  else if (
    db.builds.some(
      (b) =>
        b.code.toLowerCase() === code.toLowerCase() &&
        (excludingId == null || b.id !== excludingId),
    )
  ) {
    errors.code = 'Код уже используется';
  }

  if (!patch) errors.patch = 'Патч обязателен';
  else if (patch.length > 20) errors.patch = 'Патч: не больше 20 символов';

  if (!Number.isFinite(difficulty) || difficulty < 1 || difficulty > 5) {
    errors.difficulty = 'Сложность: от 1 до 5';
  }
  if (!Number.isFinite(heroId) || heroId <= 0) errors.heroId = 'Выберите героя';
  if (!proPlayerIds.length) errors.proPlayerIds = 'Выберите хотя бы одного про-игрока';
  if (!roleIds.length) errors.roleIds = 'Выберите хотя бы одну роль';
  if (!Number.isFinite(picks) || picks <= 0) errors.picks = 'Пики должны быть больше 0';
  if (!Number.isFinite(wins) || wins < 0) errors.wins = 'Победы не могут быть отрицательными';
  if (Number.isFinite(picks) && Number.isFinite(wins) && wins > picks) {
    errors.wins = 'Побед не может быть больше числа пиков';
  }
  return errors;
}

function parseSort(raw, fallbackField) {
  if (!raw) return { field: fallbackField, asc: true };
  const [field, dir] = String(raw).split(',');
  return { field: field || fallbackField, asc: (dir || 'asc').toLowerCase() !== 'desc' };
}

function cmp(a, b, field, asc) {
  const av = a[field];
  const bv = b[field];
  let r = 0;
  if (typeof av === 'number' && typeof bv === 'number') r = av - bv;
  else r = String(av ?? '').localeCompare(String(bv ?? ''), 'ru');
  return asc ? r : -r;
}

function pageOf(list, query, defaultSort) {
  const page = Math.max(1, Number(query.page) || 1);
  const size = Math.max(1, Number(query.size) || 10);
  const { field, asc } = parseSort(query.sort, defaultSort);
  const sorted = [...list].sort((a, b) => cmp(a, b, field, asc));
  const start = (page - 1) * size;
  return {
    items: sorted.slice(start, start + size),
    page,
    size,
    total: sorted.length,
  };
}

function activeFilter(list, includeDeleted) {
  if (includeDeleted === '1' || includeDeleted === 'true') return list;
  return list.filter((x) => !x.deletedAt);
}

function findById(list, id) {
  return list.find((x) => x.id === Number(id));
}

function softDelete(item) {
  item.deletedAt = new Date().toISOString();
}

function restore(item) {
  item.deletedAt = null;
}

function bulkOp(list, ids, op) {
  let n = 0;
  for (const id of ids) {
    const item = findById(list, id);
    if (!item) continue;
    op(item, list);
    n++;
  }
  return n;
}

function buildsUsingRole(roleId) {
  return db.builds.filter(
    (b) => !b.deletedAt && Array.isArray(b.roleIds) && b.roleIds.includes(Number(roleId)),
  );
}

function buildsUsingHero(heroId) {
  return db.builds.filter((b) => !b.deletedAt && b.heroId === Number(heroId));
}

function buildsUsingPro(proId) {
  return db.builds.filter(
    (b) =>
      !b.deletedAt &&
      Array.isArray(b.proPlayerIds) &&
      b.proPlayerIds.includes(Number(proId)),
  );
}

app.get('/api/roles', (req, res) => {
  let list = activeFilter(db.roles, req.query.includeDeleted);
  const search = (req.query.search || '').trim().toLowerCase();
  if (search) {
    list = list.filter(
      (r) =>
        r.name.toLowerCase().includes(search) ||
        String(r.description || '').toLowerCase().includes(search),
    );
  }
  res.json(pageOf(list, req.query, 'name'));
});

app.get('/api/roles/all', (req, res) => {
  res.json(db.roles.filter((r) => !r.deletedAt));
});

app.get('/api/roles/:id', (req, res) => {
  const item = findById(db.roles, req.params.id);
  if (!item) return res.status(404).json({ message: 'Роль не найдена.' });
  res.json(item);
});

app.get('/api/roles/:id/builds-count', (req, res) => {
  res.json({ count: buildsUsingRole(req.params.id).length });
});

app.post('/api/roles', (req, res) => {
  const errors = validateRoleBody(req.body, null);
  if (Object.keys(errors).length) return fail422(res, errors);
  const item = {
    id: nextId(db.roles),
    name: String(req.body.name).trim(),
    description: String(req.body.description || ''),
    deletedAt: null,
  };
  db.roles.push(item);
  res.status(201).json(item);
});

app.put('/api/roles/:id', (req, res) => {
  const item = findById(db.roles, req.params.id);
  if (!item) return res.status(404).json({ message: 'Роль не найдена.' });
  const errors = validateRoleBody(req.body, item.id);
  if (Object.keys(errors).length) return fail422(res, errors);
  item.name = String(req.body.name).trim();
  item.description = String(req.body.description || '');
  res.json(item);
});

app.delete('/api/roles/:id', (req, res) => {
  const item = findById(db.roles, req.params.id);
  if (!item) return res.status(404).json({ message: 'Роль не найдена.' });
  const hard = req.query.hard === 'true' || req.query.hard === '1';
  if (hard) {
    if (buildsUsingRole(item.id).length > 0) {
      return res.status(409).json({
        message: 'Нельзя удалить роль: есть связанные сборки.',
      });
    }
    db.roles = db.roles.filter((r) => r.id !== item.id);
  } else {
    softDelete(item);
  }
  res.status(204).end();
});

app.post('/api/roles/:id/restore', (req, res) => {
  const item = findById(db.roles, req.params.id);
  if (!item) return res.status(404).json({ message: 'Роль не найдена.' });
  restore(item);
  res.json(item);
});

app.post('/api/roles/bulk-delete', (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  const hard = !!req.body.hard;
  if (hard) {
    for (const id of ids) {
      if (buildsUsingRole(id).length > 0) {
        return res.status(409).json({
          message: 'Нельзя удалить роль: есть связанные сборки.',
        });
      }
    }
  }
  const deleted = bulkOp(db.roles, ids, (item, list) => {
    if (hard) {
      const i = list.indexOf(item);
      if (i >= 0) list.splice(i, 1);
    } else softDelete(item);
  });
  res.json({ deleted });
});

app.post('/api/roles/bulk-restore', (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  const restored = bulkOp(db.roles, ids, (item) => restore(item));
  res.json({ restored });
});

app.get('/api/heroes', (req, res) => {
  let list = activeFilter(db.heroes, req.query.includeDeleted);
  const search = (req.query.search || '').trim().toLowerCase();
  if (search) {
    list = list.filter(
      (h) =>
        h.name.toLowerCase().includes(search) ||
        h.primaryAttribute.toLowerCase().includes(search) ||
        h.attackType.toLowerCase().includes(search),
    );
  }
  if (req.query.primaryAttribute) {
    list = list.filter((h) => h.primaryAttribute === req.query.primaryAttribute);
  }
  if (req.query.attackType) {
    list = list.filter((h) => h.attackType === req.query.attackType);
  }
  res.json(pageOf(list, req.query, 'name'));
});

app.get('/api/heroes/all', (req, res) => {
  res.json(db.heroes.filter((h) => !h.deletedAt));
});

app.get('/api/heroes/:id', (req, res) => {
  const item = findById(db.heroes, req.params.id);
  if (!item) return res.status(404).json({ message: 'Герой не найден.' });
  res.json(item);
});

app.post('/api/heroes', (req, res) => {
  const errors = validateHeroBody(req.body, null);
  if (Object.keys(errors).length) return fail422(res, errors);
  const item = {
    id: nextId(db.heroes),
    name: String(req.body.name).trim(),
    primaryAttribute: String(req.body.primaryAttribute || '').trim(),
    attackType: String(req.body.attackType || '').trim(),
    deletedAt: null,
  };
  db.heroes.push(item);
  res.status(201).json(item);
});

app.put('/api/heroes/:id', (req, res) => {
  const item = findById(db.heroes, req.params.id);
  if (!item) return res.status(404).json({ message: 'Герой не найден.' });
  const errors = validateHeroBody(req.body, item.id);
  if (Object.keys(errors).length) return fail422(res, errors);
  item.name = String(req.body.name).trim();
  item.primaryAttribute = String(req.body.primaryAttribute || '').trim();
  item.attackType = String(req.body.attackType || '').trim();
  res.json(item);
});

app.delete('/api/heroes/:id', (req, res) => {
  const item = findById(db.heroes, req.params.id);
  if (!item) return res.status(404).json({ message: 'Герой не найден.' });
  const hard = req.query.hard === 'true' || req.query.hard === '1';
  if (hard) {
    if (buildsUsingHero(item.id).length > 0) {
      return res.status(409).json({
        message: 'Нельзя удалить героя: есть связанные сборки.',
      });
    }
    db.heroes = db.heroes.filter((h) => h.id !== item.id);
  } else softDelete(item);
  res.status(204).end();
});

app.post('/api/heroes/:id/restore', (req, res) => {
  const item = findById(db.heroes, req.params.id);
  if (!item) return res.status(404).json({ message: 'Герой не найден.' });
  restore(item);
  res.json(item);
});

app.post('/api/heroes/bulk-delete', (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  const hard = !!req.body.hard;
  if (hard) {
    for (const id of ids) {
      if (buildsUsingHero(id).length > 0) {
        return res.status(409).json({
          message: 'Нельзя удалить героя: есть связанные сборки.',
        });
      }
    }
  }
  const deleted = bulkOp(db.heroes, ids, (item, list) => {
    if (hard) {
      const i = list.indexOf(item);
      if (i >= 0) list.splice(i, 1);
    } else softDelete(item);
  });
  res.json({ deleted });
});

app.post('/api/heroes/bulk-restore', (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  res.json({ restored: bulkOp(db.heroes, ids, (item) => restore(item)) });
});

app.get('/api/pro-players', (req, res) => {
  let list = activeFilter(db.proPlayers, req.query.includeDeleted);
  const search = (req.query.search || '').trim().toLowerCase();
  if (search) {
    list = list.filter(
      (p) =>
        p.nickname.toLowerCase().includes(search) ||
        p.realName.toLowerCase().includes(search) ||
        p.team.toLowerCase().includes(search) ||
        p.country.toLowerCase().includes(search),
    );
  }
  if (req.query.country) {
    list = list.filter((p) => p.country === req.query.country);
  }
  res.json(pageOf(list, req.query, 'nickname'));
});

app.get('/api/pro-players/all', (req, res) => {
  res.json(db.proPlayers.filter((p) => !p.deletedAt));
});

app.get('/api/pro-players/:id', (req, res) => {
  const item = findById(db.proPlayers, req.params.id);
  if (!item) return res.status(404).json({ message: 'Проигрок не найден.' });
  res.json(item);
});

app.post('/api/pro-players', (req, res) => {
  const errors = validateProBody(req.body, null);
  if (Object.keys(errors).length) return fail422(res, errors);
  const item = {
    id: nextId(db.proPlayers),
    nickname: String(req.body.nickname).trim(),
    realName: String(req.body.realName || '').trim(),
    team: String(req.body.team || '').trim(),
    rating: Number(req.body.rating),
    country: String(req.body.country || '').trim(),
    deletedAt: null,
  };
  db.proPlayers.push(item);
  res.status(201).json(item);
});

app.put('/api/pro-players/:id', (req, res) => {
  const item = findById(db.proPlayers, req.params.id);
  if (!item) return res.status(404).json({ message: 'Проигрок не найден.' });
  const errors = validateProBody(req.body, item.id);
  if (Object.keys(errors).length) return fail422(res, errors);
  item.nickname = String(req.body.nickname).trim();
  item.realName = String(req.body.realName || '').trim();
  item.team = String(req.body.team || '').trim();
  item.rating = Number(req.body.rating);
  item.country = String(req.body.country || '').trim();
  res.json(item);
});

app.delete('/api/pro-players/:id', (req, res) => {
  const item = findById(db.proPlayers, req.params.id);
  if (!item) return res.status(404).json({ message: 'Проигрок не найден.' });
  const hard = req.query.hard === 'true' || req.query.hard === '1';
  if (hard) {
    if (buildsUsingPro(item.id).length > 0) {
      return res.status(409).json({
        message: 'Нельзя удалить проигрока: есть связанные сборки.',
      });
    }
    db.proPlayers = db.proPlayers.filter((p) => p.id !== item.id);
  } else softDelete(item);
  res.status(204).end();
});

app.post('/api/pro-players/:id/restore', (req, res) => {
  const item = findById(db.proPlayers, req.params.id);
  if (!item) return res.status(404).json({ message: 'Проигрок не найден.' });
  restore(item);
  res.json(item);
});

app.post('/api/pro-players/bulk-delete', (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  const hard = !!req.body.hard;
  if (hard) {
    for (const id of ids) {
      if (buildsUsingPro(id).length > 0) {
        return res.status(409).json({
          message: 'Нельзя удалить проигрока: есть связанные сборки.',
        });
      }
    }
  }
  const deleted = bulkOp(db.proPlayers, ids, (item, list) => {
    if (hard) {
      const i = list.indexOf(item);
      if (i >= 0) list.splice(i, 1);
    } else softDelete(item);
  });
  res.json({ deleted });
});

app.post('/api/pro-players/bulk-restore', (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  res.json({ restored: bulkOp(db.proPlayers, ids, (item) => restore(item)) });
});

app.get('/api/builds', (req, res) => {
  let list = activeFilter(db.builds, req.query.includeDeleted);
  const search = (req.query.search || '').trim().toLowerCase();
  if (search) {
    list = list.filter(
      (b) =>
        b.title.toLowerCase().includes(search) ||
        b.code.toLowerCase().includes(search) ||
        b.patch.toLowerCase().includes(search),
    );
  }
  if (req.query.roleId) {
    const rid = Number(req.query.roleId);
    list = list.filter((b) => Array.isArray(b.roleIds) && b.roleIds.includes(rid));
  }
  if (req.query.heroId) {
    list = list.filter((b) => b.heroId === Number(req.query.heroId));
  }
  if (req.query.proPlayerId) {
    const pid = Number(req.query.proPlayerId);
    list = list.filter(
      (b) => Array.isArray(b.proPlayerIds) && b.proPlayerIds.includes(pid),
    );
  }
  if (req.query.difficultyFrom) {
    list = list.filter((b) => b.difficulty >= Number(req.query.difficultyFrom));
  }
  if (req.query.difficultyTo) {
    list = list.filter((b) => b.difficulty <= Number(req.query.difficultyTo));
  }
  res.json(pageOf(list, req.query, 'title'));
});

app.get('/api/builds/code-exists', (req, res) => {
  const code = String(req.query.code || '').trim().toLowerCase();
  const excludingId = req.query.excludingId ? Number(req.query.excludingId) : null;
  const exists = db.builds.some(
    (b) =>
      b.code.toLowerCase() === code &&
      (excludingId == null || b.id !== excludingId),
  );
  res.json({ exists });
});

app.get('/api/builds/count-by-hero/:heroId', (req, res) => {
  res.json({ count: buildsUsingHero(req.params.heroId).length });
});

app.get('/api/builds/links-by-hero/:heroId', (req, res) => {
  const builds = buildsUsingHero(req.params.heroId);
  const proPlayerIds = [...new Set(builds.flatMap((b) => b.proPlayerIds || []))];
  const roleIds = [...new Set(builds.flatMap((b) => b.roleIds || []))];
  res.json({ proPlayerIds, roleIds });
});

app.get('/api/builds/:id', (req, res) => {
  const item = findById(db.builds, req.params.id);
  if (!item) return res.status(404).json({ message: 'Сборка не найдена.' });
  res.json(item);
});

app.post('/api/builds', (req, res) => {
  const errors = validateBuildBody(req.body, null);
  if (Object.keys(errors).length) return fail422(res, errors);
  const item = {
    id: nextId(db.builds),
    title: String(req.body.title).trim(),
    code: String(req.body.code).trim(),
    patch: String(req.body.patch || '').trim(),
    difficulty: Number(req.body.difficulty) || 1,
    heroId: Number(req.body.heroId),
    proPlayerIds: Array.isArray(req.body.proPlayerIds)
      ? req.body.proPlayerIds.map(Number)
      : [],
    roleIds: Array.isArray(req.body.roleIds) ? req.body.roleIds.map(Number) : [],
    picks: Number(req.body.picks) || 0,
    wins: Number(req.body.wins) || 0,
    deletedAt: null,
  };
  db.builds.push(item);
  res.status(201).json(item);
});

app.put('/api/builds/:id', (req, res) => {
  const item = findById(db.builds, req.params.id);
  if (!item) return res.status(404).json({ message: 'Сборка не найдена.' });
  const errors = validateBuildBody(req.body, item.id);
  if (Object.keys(errors).length) return fail422(res, errors);
  item.title = String(req.body.title).trim();
  item.code = String(req.body.code).trim();
  item.patch = String(req.body.patch || '').trim();
  item.difficulty = Number(req.body.difficulty) || 1;
  item.heroId = Number(req.body.heroId);
  item.proPlayerIds = Array.isArray(req.body.proPlayerIds)
    ? req.body.proPlayerIds.map(Number)
    : [];
  item.roleIds = Array.isArray(req.body.roleIds) ? req.body.roleIds.map(Number) : [];
  item.picks = Number(req.body.picks) || 0;
  item.wins = Number(req.body.wins) || 0;
  res.json(item);
});

app.delete('/api/builds/:id', (req, res) => {
  const item = findById(db.builds, req.params.id);
  if (!item) return res.status(404).json({ message: 'Сборка не найдена.' });
  const hard = req.query.hard === 'true' || req.query.hard === '1';
  if (hard) {
    db.builds = db.builds.filter((b) => b.id !== item.id);
  } else softDelete(item);
  res.status(204).end();
});

app.post('/api/builds/:id/restore', (req, res) => {
  const item = findById(db.builds, req.params.id);
  if (!item) return res.status(404).json({ message: 'Сборка не найдена.' });
  restore(item);
  res.json(item);
});

app.post('/api/builds/bulk-delete', (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  const hard = !!req.body.hard;
  const deleted = bulkOp(db.builds, ids, (item, list) => {
    if (hard) {
      const i = list.indexOf(item);
      if (i >= 0) list.splice(i, 1);
    } else softDelete(item);
  });
  res.json({ deleted });
});

app.post('/api/builds/bulk-restore', (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  res.json({ restored: bulkOp(db.builds, ids, (item) => restore(item)) });
});

app.get('/api/users', (req, res) => {
  let list = activeFilter(db.users, req.query.includeDeleted);
  const search = (req.query.search || '').trim().toLowerCase();
  if (search) {
    list = list.filter(
      (u) =>
        u.nickname.toLowerCase().includes(search) ||
        u.email.toLowerCase().includes(search) ||
        u.region.toLowerCase().includes(search),
    );
  }
  res.json(pageOf(list, req.query, 'nickname'));
});

app.get('/api/users/email-exists', (req, res) => {
  const email = String(req.query.email || '').trim().toLowerCase();
  const excludingId = req.query.excludingId ? Number(req.query.excludingId) : null;
  const exists = db.users.some(
    (u) =>
      u.email.toLowerCase() === email &&
      (excludingId == null || u.id !== excludingId),
  );
  res.json({ exists });
});

app.get('/api/users/:id', (req, res) => {
  const item = findById(db.users, req.params.id);
  if (!item) return res.status(404).json({ message: 'Пользователь не найден.' });
  res.json(item);
});

app.post('/api/users', (req, res) => {
  const errors = validateUserBody(req.body, null);
  if (Object.keys(errors).length) return fail422(res, errors);
  const steam = req.body.steam || {};
  const item = {
    id: nextId(db.users),
    nickname: String(req.body.nickname).trim(),
    email: String(req.body.email).trim(),
    region: String(req.body.region || '').trim(),
    steam: {
      url: String(steam.url || '').trim(),
      nickname: String(steam.nickname || '').trim(),
      rating: Number(steam.rating) || 0,
    },
    deletedAt: null,
  };
  db.users.push(item);
  res.status(201).json(item);
});

app.put('/api/users/:id', (req, res) => {
  const item = findById(db.users, req.params.id);
  if (!item) return res.status(404).json({ message: 'Пользователь не найден.' });
  const errors = validateUserBody(req.body, item.id);
  if (Object.keys(errors).length) return fail422(res, errors);
  const steam = req.body.steam || {};
  item.nickname = String(req.body.nickname).trim();
  item.email = String(req.body.email).trim();
  item.region = String(req.body.region || '').trim();
  item.steam = {
    url: String(steam.url || '').trim(),
    nickname: String(steam.nickname || '').trim(),
    rating: Number(steam.rating) || 0,
  };
  res.json(item);
});

app.delete('/api/users/:id', (req, res) => {
  const item = findById(db.users, req.params.id);
  if (!item) return res.status(404).json({ message: 'Пользователь не найден.' });
  const hard = req.query.hard === 'true' || req.query.hard === '1';
  if (hard) {
    db.users = db.users.filter((u) => u.id !== item.id);
  } else softDelete(item);
  res.status(204).end();
});

app.post('/api/users/:id/restore', (req, res) => {
  const item = findById(db.users, req.params.id);
  if (!item) return res.status(404).json({ message: 'Пользователь не найден.' });
  restore(item);
  res.json(item);
});

app.post('/api/users/bulk-delete', (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  const hard = !!req.body.hard;
  const deleted = bulkOp(db.users, ids, (item, list) => {
    if (hard) {
      const i = list.indexOf(item);
      if (i >= 0) list.splice(i, 1);
    } else softDelete(item);
  });
  res.json({ deleted });
});

app.post('/api/users/bulk-restore', (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  res.json({ restored: bulkOp(db.users, ids, (item) => restore(item)) });
});

app.listen(PORT, () => {
  console.log(`Mock API listening on http://localhost:${PORT}/api`);
});
