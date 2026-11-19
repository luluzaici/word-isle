/* ============================================================
   词屿 Word Isle — a small, offline-first vocabulary app
   ============================================================ */
const STORAGE_KEY = 'wordisle.v1';
const $  = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

const icon = (name, cls = '') => `<svg class="${cls}" aria-hidden="true"><use href="#i-${name}"/></svg>`;
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (m) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const clamp = (n, a, b) => Math.max(a, Math.min(b, n));
const pad = (n) => String(n).padStart(2, '0');
const DAY_MS = 86400000;

const state = {
  data: [],
  byId: new Map(),
  stats: {},
  starred: {},
  history: {},
  settings: { size: 20, goal: 20, autoSpeak: false },
  tab: 'study',
  library: { query: '', filter: 'all', visible: 80 },
  session: null,
  detail: null,
};

let toastTimer = 0;
let saveTimer = 0;

/* ---------------- storage ---------------- */
function loadStore() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    const saved = JSON.parse(raw);
    if (saved && typeof saved === 'object') {
      state.stats = saved.stats || {};
      state.starred = saved.starred || {};
      state.history = saved.history || {};
      state.settings = Object.assign({ size: 20, goal: 20, autoSpeak: false }, saved.settings || {});
    }
  } catch (e) { console.warn('Could not read saved progress', e); }
}
function saveStore(now = false) {
  clearTimeout(saveTimer);
  const write = () => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({
        version: 1,
        stats: state.stats,
        starred: state.starred,
        history: state.history,
        settings: state.settings,
      }));
    } catch (e) { console.warn('Could not save progress', e); }
  };
  if (now) write(); else saveTimer = setTimeout(write, 180);
}

/* ---------------- dates & stats ---------------- */
function dayKey(d = new Date()) {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}
function dateFromKey(key) {
  const [y, m, d] = key.split('-').map(Number);
  return new Date(y, m - 1, d);
}
function dayOffset(n) {
  const d = new Date();
  d.setHours(12, 0, 0, 0);
  d.setDate(d.getDate() + n);
  return d;
}
const WEEK_CN = ['日', '一', '二', '三', '四', '五', '六'];
function weekday(key) { return '周' + WEEK_CN[dateFromKey(key).getDay()]; }

function statOf(id) {
  return state.stats[id] || { seen: 0, correct: 0, lastResult: null, lastSeen: 0 };
}
function accuracyOf(id) {
  const st = statOf(id);
  return st.seen ? Math.round((st.correct / st.seen) * 100) : null;
}
function todayStats() {
  return state.history[dayKey()] || { seen: 0, correct: 0 };
}
function totalStats() {
  let seen = 0, correct = 0;
  Object.values(state.stats).forEach((s) => { seen += s.seen || 0; correct += s.correct || 0; });
  return { seen, correct, accuracy: seen ? Math.round(correct / seen * 100) : 0 };
}
function uniqueSeen() {
  return state.data.reduce((n, w) => n + (statOf(w.id).seen > 0 ? 1 : 0), 0);
}
function isMastered(id) {
  const s = statOf(id);
  return s.seen >= 3 && (s.correct / s.seen) >= 0.8;
}
function currentStreak() {
  let d = new Date(); d.setHours(12, 0, 0, 0);
  if (!(state.history[dayKey(d)]?.seen > 0)) d = new Date(d.getTime() - DAY_MS);
  let streak = 0;
  for (let i = 0; i < 4000; i++) {
    const h = state.history[dayKey(d)];
    if (!h || !h.seen) break;
    streak++;
    d = new Date(d.getTime() - DAY_MS);
  }
  return streak;
}
function studiedDays() {
  return Object.values(state.history).filter((h) => h && h.seen > 0).length;
}
function weekSeries(days = 7) {
  const out = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = dayOffset(-i);
    const key = dayKey(d);
    const h = state.history[key] || { seen: 0, correct: 0 };
    out.push({ key, day: WEEK_CN[d.getDay()], date: d.getDate(), seen: h.seen || 0, correct: h.correct || 0, isToday: i === 0 });
  }
  return out;
}
function greeting() {
  const h = new Date().getHours();
  if (h < 6) return '夜深了';
  if (h < 11) return '早上好';
  if (h < 14) return '中午好';
  if (h < 18) return '下午好';
  return '晚上好';
}

/* ---------------- data ---------------- */
async function loadData() {
  const res = await fetch('data/vocabulary.json', { cache: 'no-cache' });
  if (!res.ok) throw new Error(`词库加载失败 (${res.status})`);
  const arr = await res.json();
  if (!Array.isArray(arr) || !arr.length) throw new Error('词库为空');
  state.data = arr
    .filter((w) => w && w.word && Array.isArray(w.senses) && w.senses.length)
    .sort((a, b) => a.word.localeCompare(b.word, 'en'));
  state.byId = new Map(state.data.map((w) => [w.id, w]));
}

/* ---------------- small UI helpers ---------------- */
function showToast(msg) {
  const el = $('#toast');
  if (!el) return;
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2100);
}
function firstSense(w) {
  const s = w.senses?.[0];
  if (!s) return '';
  return (s.pos ? s.pos + '. ' : '') + s.def;
}
function joinDefs(w) {
  return (w.senses || []).map((s) => s.def).join('；');
}
function phoneticText(w) {
  const p = (w.phonetic || '').trim();
  return p ? `/${p}/` : '';
}
function accuracyClass(acc) {
  if (acc === null || acc === undefined) return '';
  if (acc >= 80) return 'good';
  if (acc >= 60) return 'mid';
  return 'bad';
}
function badgeFor(id) {
  const st = statOf(id);
  if (!st.seen) return `<span class="badge">新</span>`;
  const acc = accuracyOf(id);
  return `<span class="badge ${accuracyClass(acc)}">${acc}%</span>`;
}
function ringSVG(percent, cls = '', label = '今日') {
  const c = 226.2; // 2πr, r=36
  const offset = c * (1 - clamp(percent, 0, 100) / 100);
  return `<div class="ring-wrap ${cls}">
    <svg viewBox="0 0 82 82" aria-hidden="true">
      <circle class="ring-bg" cx="41" cy="41" r="36"/>
      <circle class="ring-fg" cx="41" cy="41" r="36" style="stroke-dasharray:${c};stroke-dashoffset:${offset}"/>
    </svg>
    <div class="ring-label"><b>${Math.round(percent)}<span style="font-size:.55em">%</span></b><small>${esc(label)}</small></div>
  </div>`;
}
function bigRing(percent) {
  const c = 414.7; // 2π*66
  const offset = c * (1 - clamp(percent, 0, 100) / 100);
  return `<div class="big-ring">
    <svg viewBox="0 0 160 160" aria-hidden="true">
      <circle class="ring-bg" cx="80" cy="80" r="66"/>
      <circle class="ring-fg" cx="80" cy="80" r="66" style="stroke-dasharray:${c};stroke-dashoffset:${offset}"/>
    </svg>
    <div class="ring-label"><b>${Math.round(percent)}%</b><small>本组正确率</small></div>
  </div>`;
}

/* ---------------- selection ---------------- */
function poolFor(mode) {
  const all = state.data;
  const newWords = all.filter((w) => statOf(w.id).seen === 0);
  const seenWords = all.filter((w) => statOf(w.id).seen > 0);
  const wrongWords = seenWords.filter((w) => {
    const s = statOf(w.id); const a = s.seen ? s.correct / s.seen : 0;
    return s.lastResult === false || a < 0.6;
  });
  const mastered = seenWords.filter((w) => isMastered(w.id));
  const review = seenWords.filter((w) => !isMastered(w.id));
  if (mode === 'new') return newWords;
  if (mode === 'review') return review;
  if (mode === 'wrong') return wrongWords;
  return { newWords, review, seenWords, mastered, wrongWords };
}
function shuffle(a) {
  const arr = a.slice();
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}
function weakScore(w) {
  const s = statOf(w.id);
  const acc = s.seen ? s.correct / s.seen : 0;
  const days = s.lastSeen ? (Date.now() - s.lastSeen) / DAY_MS : 30;
  return (1 - acc) * 100 + Math.min(days, 30) * 1.3 + (s.lastResult === false ? 18 : 0) + Math.random() * 10;
}
function buildQueue(mode) {
  const size = clamp(state.settings.size, 5, 50);
  let list = [];
  if (mode === 'mixed') {
    const p = poolFor('mixed');
    const wantNew = Math.max(1, Math.round(size * 0.6));
    list = shuffle(p.newWords).slice(0, wantNew);
    const rest = size - list.length;
    if (rest > 0) {
      const rev = p.review.slice().sort((a, b) => weakScore(b) - weakScore(a));
      list = list.concat(shuffle(rev).slice(0, rest));
    }
    if (list.length < size) list = list.concat(shuffle(state.data.filter((w) => !list.includes(w))).slice(0, size - list.length));
  } else if (mode === 'review' || mode === 'wrong') {
    const pool = poolFor(mode);
    const sorted = pool.slice().sort((a, b) => weakScore(b) - weakScore(a));
    // take a little randomness among the neediest words
    const head = sorted.slice(0, Math.max(size * 3, size));
    list = shuffle(head).slice(0, size);
    if (list.length < size) {
      const extra = state.data.filter((w) => !list.includes(w) && statOf(w.id).seen === 0);
      list = list.concat(shuffle(extra).slice(0, size - list.length));
    }
  } else {
    list = shuffle(poolFor('new')).slice(0, size);
    if (list.length < size) {
      const extra = state.data.filter((w) => !list.includes(w) && statOf(w.id).seen > 0);
      list = list.concat(shuffle(extra).slice(0, size - list.length));
    }
  }
  return list.slice(0, size);
}

/* ---------------- app shell ---------------- */
function setTab(tab) {
  if (!['study', 'library', 'stats'].includes(tab)) return;
  state.tab = tab;
  $$('.tab').forEach((b) => b.classList.toggle('is-active', b.dataset.tab === tab));
  renderView();
}
function renderView() {
  const view = $('#view');
  if (!view) return;
  if (state.tab === 'study') view.innerHTML = `<div class="view-inner">${homeHTML()}</div>`;
  else if (state.tab === 'library') view.innerHTML = `<div class="view-inner">${libraryHTML()}</div>`;
  else view.innerHTML = `<div class="view-inner">${statsHTML()}</div>`;
  view.scrollTop = 0;
}

/* ---------------- home ---------------- */
function homeHTML() {
  const t = todayStats();
  const goal = clamp(state.settings.goal, 5, 200);
  const pct = Math.round((t.seen / goal) * 100);
  const total = totalStats();
  const seenUnique = uniqueSeen();
  const newCount = state.data.length - seenUnique;
  const seenWords = state.data.filter((w) => statOf(w.id).seen > 0);
  const wrongCount = seenWords.filter((w) => { const s = statOf(w.id); const a = s.seen ? s.correct / s.seen : 0; return s.lastResult === false || a < 0.6; }).length;
  const reviewCount = seenWords.filter((w) => !isMastered(w.id)).length;
  const streak = currentStreak();
  const week = weekSeries(7);
  const maxWeek = Math.max(1, ...week.map((d) => d.seen));

  const weak = seenWords
    .slice()
    .sort((a, b) => {
      const sa = statOf(a.id), sb = statOf(b.id);
      const aa = sa.seen ? sa.correct / sa.seen : 0, ab = sb.seen ? sb.correct / sb.seen : 0;
      return aa - ab || (sa.lastSeen || 0) - (sb.lastSeen || 0);
    })
    .slice(0, 4);

  return `
    <header class="topline">
      <div class="brand">
        <div class="brand-mark">词</div>
        <div class="brand-name"><b>词屿</b><small>WORD ISLE</small></div>
      </div>
      <div class="top-actions">
        <div class="streak-pill" title="连续学习天数">${icon('flame')}<span>${streak}</span></div>
        <button class="icon-btn" data-action="open-settings" aria-label="设置">${icon('settings')}</button>
      </div>
    </header>

    <section class="hello">
      <h1>${greeting()}，<br>和 <em>${Math.min(20, Math.max(1, goal - t.seen))}</em> 个词见个面。</h1>
      <p>释义先藏起来。轻点卡片揭晓，再记录这次有没有想起来。</p>
    </section>

    <section class="hero">
      <div class="hero-top">
        <div>
          <div class="hero-kicker">TODAY · 今日进度</div>
          <h2>已复习 <span>${t.seen}</span> 个词</h2>
          <p class="hero-sub">目标 ${goal} 个 · 正确率 ${t.seen ? Math.round(t.correct / t.seen * 100) : 0}%</p>
        </div>
        ${ringSVG(pct)}
      </div>
      <div class="hero-bottom">
        <div class="hero-stat">
          <div><b>${total.accuracy}%</b><small>总正确率</small></div>
          <div><b>${seenUnique}</b><small>已遇见</small></div>
        </div>
        <button class="btn-hero" data-action="start-session" data-mode="mixed">开始学习 ${icon('arrow-right')}</button>
      </div>
    </section>

    <div class="mode-grid">
      <button class="mode-card" data-action="start-session" data-mode="new">
        <span class="mode-count">${newCount}</span>
        <span class="mode-icon">${icon('spark')}</span>
        <span><b>新词</b><small>还没见过</small></span>
      </button>
      <button class="mode-card" data-action="start-session" data-mode="review">
        <span class="mode-count">${reviewCount}</span>
        <span class="mode-icon">${icon('refresh')}</span>
        <span><b>复习</b><small>再见面一次</small></span>
      </button>
      <button class="mode-card" data-action="start-session" data-mode="wrong">
        <span class="mode-count">${wrongCount}</span>
        <span class="mode-icon">${icon('flame')}</span>
        <span><b>错词</b><small>重点攻克</small></span>
      </button>
    </div>

    <div class="section-head">
      <h2>这一周</h2>
      <span class="link">连续 ${streak} 天 ${icon('arrow-right')}</span>
    </div>
    <section class="card week-card">
      <div class="week-top"><b>每天一点点</b><small>共 ${week.reduce((n, d) => n + d.seen, 0)} 次复习</small></div>
      <div class="week-bars">
        ${week.map((d) => `<div class="week-day ${d.isToday ? 'today' : ''}">
          <div class="week-bar ${d.seen ? 'has' : ''} ${d.isToday ? 'today' : ''}" style="height:${Math.max(4, Math.round((d.seen / maxWeek) * 100))}%"></div>
          <span>${d.day}</span>
        </div>`).join('')}
      </div>
    </section>

    <div class="section-head">
      <h2>最需要再见</h2>
      <span class="link">${wrongCount} 个错词</span>
    </div>
    <div class="review-list">
      ${weak.length ? weak.map((w) => {
        const acc = accuracyOf(w.id);
        return `<button class="review-row" data-action="open-detail" data-id="${esc(w.id)}">
          <div class="rw"><b>${esc(w.word)}</b><small>${esc(firstSense(w))}</small></div>
          <span class="mini-acc ${acc >= 60 ? 'ok' : ''}">${acc ?? 0}%</span>
          ${icon('arrow-right')}
        </button>`;
      }).join('') : `<div class="empty-mini">还没有错词。开始第一组，答案会慢慢长出来。</div>`}
    </div>
  `;
}

/* ---------------- library ---------------- */
function countsForLibrary() {
  let nw = 0, review = 0, mastered = 0, wrong = 0, starred = 0;
  state.data.forEach((w) => {
    const s = statOf(w.id);
    if (state.starred[w.id]) starred++;
    if (!s.seen) nw++;
    else {
      if (isMastered(w.id)) mastered++; else review++;
      const a = s.correct / s.seen;
      if (s.lastResult === false || a < 0.6) wrong++;
    }
  });
  return { all: state.data.length, new: nw, review, wrong, mastered, starred };
}
function matchFilter(w, filter) {
  const s = statOf(w.id);
  if (filter === 'new') return !s.seen;
  if (filter === 'review') return s.seen > 0 && !isMastered(w.id);
  if (filter === 'wrong') return s.seen > 0 && (s.lastResult === false || (s.correct / s.seen) < 0.6);
  if (filter === 'mastered') return isMastered(w.id);
  if (filter === 'starred') return !!state.starred[w.id];
  return true;
}
function filteredWords() {
  const q = state.library.query.trim().toLowerCase();
  return state.data.filter((w) => {
    if (!matchFilter(w, state.library.filter)) return false;
    if (!q) return true;
    if (w.word.toLowerCase().includes(q)) return true;
    if ((w.phonetic || '').toLowerCase().includes(q)) return true;
    return (w.senses || []).some((s) => (s.def || '').toLowerCase().includes(q));
  });
}
function libraryHTML() {
  const c = countsForLibrary();
  const filters = [
    ['all', '全部', c.all], ['new', '未学习', c.new], ['review', '需复习', c.review],
    ['wrong', '错词', c.wrong], ['mastered', '已掌握', c.mastered], ['starred', '星标', c.starred],
  ];
  return `
    <header class="topline">
      <div class="brand">
        <div class="brand-mark">词</div>
        <div class="brand-name"><b>词库</b><small>${state.data.length} WORDS</small></div>
      </div>
      <button class="icon-btn" data-action="open-settings" aria-label="设置">${icon('settings')}</button>
    </header>
    <div class="page-head">
      <div><h1>所有单词</h1><p>点击单词查看详细信息与正确率</p></div>
      <span class="count" id="lib-count">${filteredWords().length} 个</span>
    </div>
    <div class="search">
      ${icon('search')}
      <input id="search-input" type="search" inputmode="search" placeholder="搜索单词或中文释义" autocomplete="off" value="${esc(state.library.query)}">
      <button class="clear ${state.library.query ? '' : 'hidden'}" data-action="clear-search" aria-label="清空搜索">${icon('close')}</button>
    </div>
    <div class="filters">
      ${filters.map(([k, label, n]) => `<button class="filter ${state.library.filter === k ? 'is-active' : ''}" data-action="set-filter" data-filter="${k}">${label}<span class="n">${n}</span></button>`).join('')}
    </div>
    <div id="word-list">${wordRowsHTML()}</div>
    <div class="load-more" id="load-more">${filteredWords().length > state.library.visible ? `<button class="btn-ghost" data-action="load-more">再看一些</button>` : ''}</div>
  `;
}
function wordRowsHTML() {
  const list = filteredWords();
  const shown = list.slice(0, state.library.visible);
  if (!shown.length) {
    return `<div class="empty"><div class="big">没有找到</div><p>试试更短的关键词，或换一个筛选条件。</p></div>`;
  }
  return `<div class="word-list">${shown.map((w) => {
    const st = statOf(w.id);
    const on = !!state.starred[w.id];
    return `<div class="word-row" data-action="open-detail" data-id="${esc(w.id)}" role="button" tabindex="0">
      <div class="wmain">
        <div class="wline"><b>${esc(w.word)}</b><span class="ph">${esc(phoneticText(w))}</span></div>
        <div class="def">${esc(firstSense(w))}</div>
      </div>
      ${badgeFor(w.id)}
      <button class="star-btn ${on ? 'on' : ''}" data-action="toggle-star" data-id="${esc(w.id)}" aria-label="${on ? '取消星标' : '加星标'}">${icon('star')}</button>
    </div>`;
  }).join('')}</div>`;
}
function refreshLibraryList() {
  const listEl = $('#word-list');
  if (!listEl) return;
  listEl.innerHTML = wordRowsHTML();
  const count = $('#lib-count');
  if (count) count.textContent = `${filteredWords().length} 个`;
  const more = $('#load-more');
  if (more) more.innerHTML = filteredWords().length > state.library.visible ? `<button class="btn-ghost" data-action="load-more">再看一些</button>` : '';
}

/* ---------------- stats ---------------- */
function statsHTML() {
  const total = totalStats();
  const unique = uniqueSeen();
  const mastered = state.data.filter((w) => isMastered(w.id)).length;
  const learning = unique - mastered;
  const fresh = state.data.length - unique;
  const days = studiedDays();
  const streak = currentStreak();
  const week = weekSeries(7);
  const max = Math.max(1, ...week.map((d) => d.seen));
  const pctMastered = state.data.length ? (mastered / state.data.length) * 100 : 0;
  const pctLearning = state.data.length ? (learning / state.data.length) * 100 : 0;
  const pctFresh = 100 - pctMastered - pctLearning;
  const weak = state.data.filter((w) => statOf(w.id).seen > 0)
    .sort((a, b) => {
      const sa = statOf(a.id), sb = statOf(b.id);
      return (sa.correct / sa.seen) - (sb.correct / sb.seen);
    }).slice(0, 5);

  return `
    <header class="topline">
      <div class="brand">
        <div class="brand-mark">词</div>
        <div class="brand-name"><b>统计</b><small>YOUR ISLAND</small></div>
      </div>
      <button class="icon-btn" data-action="open-settings" aria-label="设置">${icon('settings')}</button>
    </header>
    <div class="page-head"><div><h1>学习足迹</h1><p>每一次“想起来”都算数</p></div></div>

    <section class="stat-hero">
      ${ringSVG(total.accuracy, 'stat-ring', '正确率')}
      <div class="sh-text">
        <div class="eyebrow">OVERALL ACCURACY</div>
        <h2>${total.accuracy}% 的总正确率</h2>
        <p>共作答 ${total.seen} 次 · 正确 ${total.correct} 次<br>遇见过 ${unique} / ${state.data.length} 个词</p>
      </div>
    </section>

    <div class="metric-grid">
      <div class="metric"><small>连续学习</small><b>${streak}<i>天</i></b></div>
      <div class="metric"><small>学习天数</small><b>${days}<i>天</i></b></div>
      <div class="metric"><small>作答次数</small><b>${total.seen}<i>次</i></b></div>
      <div class="metric"><small>已掌握</small><b>${mastered}<i>词</i></b></div>
    </div>

    <div class="section-head"><h2>最近 7 天</h2><span class="link">每天 ${state.settings.goal} 词</span></div>
    <section class="card chart-card">
      <div class="chart-top"><b>复习次数</b><small>共 ${week.reduce((n, d) => n + d.seen, 0)} 次</small></div>
      <div class="big-bars">
        ${week.map((d) => `<div class="big-day ${d.isToday ? 'today' : ''}">
          <span class="v">${d.seen || ''}</span>
          <div class="bar ${d.seen ? 'has' : ''} ${d.isToday ? 'today' : ''}" style="height:${Math.max(4, Math.round((d.seen / max) * 100))}%"></div>
          <span class="d">${d.isToday ? '今天' : d.day}</span>
        </div>`).join('')}
      </div>
    </section>

    <div class="section-head"><h2>掌握程度</h2><span class="link">${state.data.length} 个词</span></div>
    <section class="card chart-card">
      <div class="chart-top"><b>词库分布</b><small>已掌握 ${mastered} 个</small></div>
      <div class="stack">
        <i class="s1" style="width:${pctMastered}%"></i>
        <i class="s2" style="width:${pctLearning}%"></i>
        <i class="s3" style="width:${Math.max(0, pctFresh)}%"></i>
      </div>
      <div class="legend">
        <span><i style="background:var(--green)"></i>已掌握 ${mastered}</span>
        <span><i style="background:var(--lime)"></i>学习中 ${learning}</span>
        <span><i style="background:rgba(27,42,33,.13)"></i>未学习 ${fresh}</span>
      </div>
    </section>

    <div class="section-head"><h2>正确率最低</h2><span class="link">再见面一次</span></div>
    <section class="card chart-card">
      ${weak.length ? weak.map((w) => {
        const acc = accuracyOf(w.id);
        return `<button class="weak-row" data-action="open-detail" data-id="${esc(w.id)}" style="width:100%;text-align:left">
          <b>${esc(w.word)}</b>
          <span class="bar-wrap"><i style="width:${acc}%"></i></span>
          <small>${acc}%</small>
        </button>`;
      }).join('') : `<div class="empty-mini">还没有足够的数据。先完成一组学习吧。</div>`}
    </section>
  `;
}

/* ---------------- study session ---------------- */
function startSession(mode, fixedIds = null) {
  if (!state.data.length) return;
  let queue;
  if (fixedIds) {
    queue = fixedIds.map((id) => state.byId.get(id)).filter(Boolean);
  } else {
    queue = buildQueue(mode);
  }
  if (!queue.length) {
    showToast(mode === 'new' ? '新词已经学完啦，去复习吧' : '暂时没有符合条件的词');
    return;
  }
  state.session = {
    mode: fixedIds ? 'single' : mode,
    queue,
    idx: 0,
    revealed: false,
    locked: false,
    results: [],
    startedAt: Date.now(),
    fixedIds: !!fixedIds,
  };
  openStudyOverlay();
  renderStudy();
}
function openStudyOverlay() {
  closeDetail();
  let overlay = $('#study-overlay');
  if (!overlay) {
    overlay = document.createElement('div');
    overlay.id = 'study-overlay';
    overlay.className = 'overlay study-overlay';
    overlay.innerHTML = `<div class="study" id="study-root"></div>`;
    $('#overlay-root').appendChild(overlay);
    requestAnimationFrame(() => overlay.classList.add('is-open'));
  }
}
function closeStudy() {
  const overlay = $('#study-overlay');
  if (!overlay) return;
  overlay.classList.remove('is-open');
  setTimeout(() => { if (!state.session) overlay.remove(); }, 420);
  state.session = null;
  renderView();
}
function modeLabel(mode) {
  return { mixed: '混合学习', new: '新词', review: '复习', wrong: '错词', single: '单词复习' }[mode] || '学习';
}
function renderStudy() {
  const root = $('#study-root');
  if (!root || !state.session) return;
  const s = state.session;
  if (s.idx >= s.queue.length) { renderSummary(); return; }
  const w = s.queue[s.idx];
  const st = statOf(w.id);
  const acc = accuracyOf(w.id);
  const total = s.queue.length;
  const percent = Math.round((s.idx / total) * 100);
  const senses = w.senses || [];
  const note = w.note ? `<div class="note"><b>词源 · 助记</b>${esc(w.note)}</div>` : '';
  const example = w.examples?.[0];
  const exHTML = example ? `<div class="example"><div class="en">${esc(example.en)}</div>${example.zh ? `<div class="zh">${esc(example.zh)}</div>` : ''}</div>` : '';

  root.innerHTML = `
    <div class="study-top">
      <button class="study-close" data-action="close-study" aria-label="结束学习">${icon('close')}</button>
      <div class="study-progress">
        <div class="sp-line"><span>${s.idx + 1} / ${total}</span><b>${percent}% 完成</b></div>
        <div class="pbar"><i style="width:${percent}%"></i></div>
      </div>
      <span class="study-mode">${modeLabel(s.mode)}</span>
    </div>
    <div class="study-body">
      <article class="study-card ${s.revealed ? 'revealed' : ''}" data-action="reveal-card" aria-label="单词卡片，轻点查看释义">
        <div class="word-block">
          <h2 class="word-main">${esc(w.word)}</h2>
          <div class="word-phonetic">${esc(phoneticText(w))}</div>
          <div class="speak-row">
            <button class="speak-btn" data-action="speak" data-word="${esc(w.word)}" aria-label="朗读单词">${icon('volume')}</button>
          </div>
        </div>
        <div class="reveal-box">
          <div class="reveal-inner">
            <div class="reveal-kicker">MEANING · 释义</div>
            <div class="senses">
              ${senses.map((sn) => `<div class="sense">${sn.pos ? `<span class="chip pos">${esc(sn.pos)}.</span>` : ''}<p>${esc(sn.def)}</p></div>`).join('')}
            </div>
            ${note}
            ${exHTML}
            <div class="tap-hint" style="margin-top:16px;height:auto;opacity:.7"><span>正确率 ${acc === null ? '新词' : acc + '%'}</span><span>·</span><span>已作答 ${st.seen} 次</span></div>
          </div>
        </div>
        ${!s.revealed ? `<div class="tap-hint"><i></i>轻点卡片，揭晓释义</div>` : ''}
      </article>
    </div>
    <div class="study-actions ${s.revealed ? 'show' : ''}">
      <button class="big-btn btn-wrong" data-action="answer" data-correct="0">${icon('x')}没想起来</button>
      <button class="big-btn btn-right" data-action="answer" data-correct="1">${icon('check')}想起来了</button>
    </div>
    <div class="study-foot">${s.revealed ? '<kbd>←</kbd> 没想起来 · <kbd>→</kbd> 想起来了' : '<kbd>空格</kbd> 查看释义'} · 诚实比正确率重要</div>
  `;
}
function revealCard() {
  const s = state.session;
  if (!s || s.revealed) return;
  s.revealed = true;
  const card = $('.study-card');
  if (card) card.classList.add('revealed');
  // reveal by re-rendering after the CSS height transition starts
  const actions = $('.study-actions');
  if (actions) actions.classList.add('show');
  const hint = $('.tap-hint:not([style])');
  if (hint) hint.style.opacity = '0';
  // swap the hint and the bottom action labels without rebuilding the card
  const foot = $('.study-foot');
  if (foot) foot.innerHTML = '<kbd>←</kbd> 没想起来 · <kbd>→</kbd> 想起来了 · 诚实比正确率重要';
  // remove the "tap" hint if still present
  $$('.tap-hint').forEach((el) => {
    if (el.textContent.includes('轻点卡片')) el.remove();
  });
  if (state.settings.autoSpeak) speakWord(s.queue[s.idx].word);
}
function answer(correct) {
  const s = state.session;
  if (!s || !s.revealed || s.locked) return;
  s.locked = true;
  const w = s.queue[s.idx];
  const before = statOf(w.id);
  const now = Date.now();
  state.stats[w.id] = {
    seen: (before.seen || 0) + 1,
    correct: (before.correct || 0) + (correct ? 1 : 0),
    lastResult: !!correct,
    lastSeen: now,
  };
  const key = dayKey();
  const h = state.history[key] || { seen: 0, correct: 0 };
  h.seen += 1; h.correct += correct ? 1 : 0;
  state.history[key] = h;
  s.results.push({ id: w.id, correct: !!correct });
  saveStore();
  if (navigator.vibrate) { try { navigator.vibrate(correct ? 12 : [8, 30, 8]); } catch (e) {} }
  const card = $('.study-card');
  if (card) card.classList.add('card-out');
  setTimeout(() => {
    s.idx += 1;
    s.revealed = false;
    s.locked = false;
    if (s.idx >= s.queue.length) renderSummary();
    else renderStudy();
  }, 250);
}
function renderSummary() {
  const root = $('#study-root');
  const s = state.session;
  if (!root || !s) return;
  const total = s.results.length;
  const right = s.results.filter((r) => r.correct).length;
  const acc = total ? Math.round((right / total) * 100) : 0;
  const seconds = Math.max(1, Math.round((Date.now() - s.startedAt) / 1000));
  const mins = Math.floor(seconds / 60), secs = seconds % 60;
  const wrong = s.results.filter((r) => !r.correct).map((r) => state.byId.get(r.id)).filter(Boolean);
  const isPerfect = total > 0 && right === total;
  const title = isPerfect ? '这一组，全记得。' : acc >= 70 ? '感觉正在长出来。' : '没关系，再见一次。';
  const sub = isPerfect ? '漂亮的完成。要不要再来一组，趁热打铁？' : '答错的词已经记在词库里了，下一次会更容易。';
  root.innerHTML = `
    <div class="summary">
      <div class="sm-top"><span class="eyebrow">SESSION COMPLETE</span><span class="count">${modeLabel(s.mode)}</span></div>
      <h2>${title}</h2>
      <p class="sm-sub">${sub}</p>
      ${bigRing(acc)}
      <div class="summary-metrics">
        <div><b>${right}</b><small>想起来了</small></div>
        <div><b>${total - right}</b><small>没想起来</small></div>
        <div><b>${mins}:${pad(secs)}</b><small>用时</small></div>
      </div>
      ${wrong.length ? `<div class="section-head" style="margin:0 2px 8px"><h2>再见一次</h2><span class="link">${wrong.length} 个</span></div>
      <div class="summary-list">
        ${wrong.map((w) => `<button class="sr" data-action="open-detail" data-id="${esc(w.id)}" data-from="summary"><b>${esc(w.word)}</b><small>${esc((w.senses?.[0]?.def || '').slice(0, 22))}</small>${icon('arrow-right')}</button>`).join('')}
      </div>` : ''}
      <div class="summary-actions">
        <button class="btn-primary" data-action="restart-session">${icon('refresh')}再来一组</button>
        <button class="btn-secondary" data-action="close-study">回到首页</button>
      </div>
    </div>
  `;
}
function restartSession() {
  const old = state.session;
  if (!old) return;
  const mode = old.fixedIds ? 'review' : old.mode;
  const ids = old.fixedIds ? old.queue.map((w) => w.id) : null;
  startSession(mode, ids);
}

/* ---------------- detail ---------------- */
function openDetail(id, from = null) {
  const w = state.byId.get(id);
  if (!w) return;
  state.detail = { id, from };
  let overlay = $('#detail-overlay');
  if (!overlay) {
    overlay = document.createElement('div');
    overlay.id = 'detail-overlay';
    overlay.className = 'overlay detail-overlay';
    overlay.innerHTML = `<div class="detail" id="detail-root"></div>`;
    $('#overlay-root').appendChild(overlay);
    requestAnimationFrame(() => overlay.classList.add('is-open'));
  }
  renderDetail();
}
function closeDetail() {
  const overlay = $('#detail-overlay');
  if (!overlay) return;
  overlay.classList.remove('is-open');
  setTimeout(() => { if (!state.detail) overlay.remove(); }, 350);
  state.detail = null;
}
function renderDetail() {
  const root = $('#detail-root');
  if (!root || !state.detail) return;
  const w = state.byId.get(state.detail.id);
  if (!w) return;
  const st = statOf(w.id);
  const acc = accuracyOf(w.id);
  const on = !!state.starred[w.id];
  const last = st.lastSeen ? new Date(st.lastSeen) : null;
  const lastText = last ? `${last.getMonth() + 1}月${last.getDate()}日` : '还没学';
  root.innerHTML = `
    <div class="detail-top">
      <button class="round" data-action="close-detail" aria-label="返回">${icon('arrow-left')}</button>
      <div class="acts">
        <button class="round ${on ? 'star-on' : ''}" data-action="toggle-star" data-id="${esc(w.id)}" aria-label="${on ? '取消星标' : '加星标'}" style="${on ? 'color:var(--gold)' : ''}">${icon('star')}</button>
        <button class="round" data-action="speak" data-word="${esc(w.word)}" aria-label="朗读单词">${icon('volume')}</button>
      </div>
    </div>
    <div class="detail-scroll">
      <div class="detail-hero">
        <h1 class="dword">${esc(w.word)}</h1>
        <div class="dph">${esc(phoneticText(w))}</div>
        <button class="speak-btn" data-action="speak" data-word="${esc(w.word)}" aria-label="朗读单词">${icon('volume')}</button>
        <div class="dlesson">${icon('book')}<span>${esc(w.lesson || '')} · ${esc(w.lessonTitle || '')}</span></div>
      </div>

      <div class="detail-block">
        <div class="db-title">MEANING · 释义</div>
        ${(w.senses || []).map((sn) => `<div class="detail-sense">${sn.pos ? `<span class="chip pos">${esc(sn.pos)}.</span>` : ''}<p>${esc(sn.def)}</p></div>`).join('')}
      </div>

      <div class="metric-strip">
        <div><b>${st.seen}</b><small>作答次数</small></div>
        <div><b class="${accuracyClass(acc)}">${acc === null ? '—' : acc + '%'}</b><small>正确率</small></div>
        <div><b>${lastText}</b><small>上次学习</small></div>
      </div>

      ${w.examples?.length ? `<div class="detail-block">
        <div class="db-title">EXAMPLES · 例句</div>
        ${w.examples.slice(0, 4).map((ex) => `<div class="detail-ex"><div class="en">${esc(ex.en)}</div>${ex.zh ? `<div class="zh">${esc(ex.zh)}</div>` : ''}</div>`).join('')}
      </div>` : ''}

      ${w.note ? `<div class="detail-block"><div class="db-title">ROOTS · 词源助记</div><div class="detail-note">${esc(w.note)}</div></div>` : ''}

      <div class="detail-actions">
        <button class="btn-secondary" data-action="speak" data-word="${esc(w.word)}">${icon('volume')}朗读</button>
        <button class="btn-primary" data-action="single-study" data-id="${esc(w.id)}">${icon('refresh')}复习这个词</button>
      </div>
      <div class="study-foot" style="padding-top:14px">收藏这个词，之后可以在「星标」里找到它。</div>
    </div>
  `;
}

/* ---------------- settings ---------------- */
function openSettings() {
  closeSettings();
  const sizes = [10, 20, 30];
  const goals = [10, 20, 30, 50];
  const layer = document.createElement('div');
  layer.id = 'settings-layer';
  layer.innerHTML = `
    <div class="sheet-backdrop is-open" data-action="close-settings"></div>
    <div class="sheet is-open" role="dialog" aria-modal="true" aria-label="设置">
      <div class="sheet-grab"></div>
      <div class="sheet-head"><h2>设置</h2><button class="icon-btn" data-action="close-settings" aria-label="关闭">${icon('close')}</button></div>
      <div class="sheet-body">
        <div class="setting">
          <div class="setting-line">
            <div><b>每组单词数</b><small>一次学习抽多少个词</small></div>
            <div class="seg">${sizes.map((n) => `<button class="${state.settings.size === n ? 'on' : ''}" data-action="set-size" data-value="${n}">${n}</button>`).join('')}</div>
          </div>
        </div>
        <div class="setting">
          <div class="setting-line">
            <div><b>每日目标</b><small>完成多少个词算打卡</small></div>
            <div class="seg">${goals.map((n) => `<button class="${state.settings.goal === n ? 'on' : ''}" data-action="set-goal" data-value="${n}">${n}</button>`).join('')}</div>
          </div>
        </div>
        <div class="setting">
          <div class="setting-line">
            <div><b>揭晓时自动朗读</b><small>打开释义时顺便听一遍</small></div>
            <button class="switch ${state.settings.autoSpeak ? 'on' : ''}" data-action="toggle-autospeak" aria-label="自动朗读"></button>
          </div>
        </div>
        <div class="setting">
          <div class="setting-line">
            <div><b>学习进度</b><small>${uniqueSeen()} / ${state.data.length} 个词已遇见 · 连续 ${currentStreak()} 天</small></div>
            <button class="danger" data-action="reset-progress">${icon('trash')}重置</button>
          </div>
        </div>
        <button class="setting-btn" data-action="export-progress"><span class="left">${icon('download')}<b>导出学习进度</b></span>${icon('arrow-right', 'chev')}</button>
        <button class="setting-btn" data-action="import-progress"><span class="left">${icon('share')}<b>导入学习进度</b></span>${icon('arrow-right', 'chev')}</button>
        <div class="about">
          <div class="logo-mini">词</div>
          <b>词屿 · WORD ISLE</b>
          <p>把答案藏起来，诚实记录每一次。<br>词条整理自《5500 词》讲义 · 共 ${state.data.length} 词</p>
          <p style="margin-top:8px;color:var(--muted-2)">在 iPhone Safari 中「分享 → 添加到主屏幕」，即可全屏使用。</p>
        </div>
      </div>
    </div>
  `;
  $('#overlay-root').appendChild(layer);
}
function closeSettings() {
  const layer = $('#settings-layer');
  if (!layer) return;
  layer.querySelectorAll('.sheet,.sheet-backdrop').forEach((el) => el.classList.remove('is-open'));
  setTimeout(() => layer.remove(), 330);
}
function setSetting(key, val) {
  state.settings[key] = val;
  saveStore(true);
  closeSettings();
  setTimeout(openSettings, 200);
}
function resetProgress() {
  if (!window.confirm('确定要清空所有学习记录吗？这个操作无法撤销。')) return;
  state.stats = {}; state.history = {}; state.starred = {};
  saveStore(true);
  closeSettings();
  setTab('study');
  showToast('学习记录已重置');
}
function exportProgress() {
  const blob = new Blob([JSON.stringify({
    app: 'wordisle', version: 1, exportedAt: new Date().toISOString(),
    stats: state.stats, starred: state.starred, history: state.history, settings: state.settings,
  }, null, 2)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `wordisle-backup-${dayKey()}.json`;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  showToast('学习进度已导出');
}
function importProgress() {
  const input = document.createElement('input');
  input.type = 'file'; input.accept = 'application/json';
  input.onchange = async () => {
    const file = input.files?.[0];
    if (!file) return;
    try {
      const obj = JSON.parse(await file.text());
      if (!obj || !obj.stats) throw new Error('bad file');
      if (!window.confirm('导入会覆盖当前学习进度，继续吗？')) return;
      state.stats = obj.stats || {};
      state.starred = obj.starred || {};
      state.history = obj.history || {};
      if (obj.settings) state.settings = Object.assign(state.settings, obj.settings);
      saveStore(true);
      closeSettings(); setTab('study');
      showToast('学习进度已导入');
    } catch (e) {
      showToast('这个文件看起来不是词屿的备份');
    }
  };
  input.click();
}

/* ---------------- speech ---------------- */
const synth = window.speechSynthesis || null;
let voices = [];
function refreshVoices() {
  if (!synth) return;
  voices = synth.getVoices() || [];
}
if (synth) {
  refreshVoices();
  if (typeof synth.onvoiceschanged !== 'undefined') synth.onvoiceschanged = refreshVoices;
}
function speakWord(word, btn = null) {
  if (!synth) { showToast('这台设备暂不支持朗读'); return; }
  try {
    synth.cancel();
    if (synth.paused) synth.resume();
    const utter = new SpeechSynthesisUtterance(word);
    utter.lang = 'en-US';
    utter.rate = 0.86;
    utter.pitch = 1;
    const preferred = ['Samantha', 'Ava', 'Allison', 'Aria', 'Jenny', 'Google US English', 'Microsoft Zira', 'Microsoft Aria'];
    const pick = voices.find((v) => /en[-_]US/i.test(v.lang) && preferred.some((p) => v.name.includes(p)))
      || voices.find((v) => /en[-_]US/i.test(v.lang))
      || voices.find((v) => /^en/i.test(v.lang));
    if (pick) utter.voice = pick;
    const b = btn || $$('.speak-btn').find((el) => el.dataset.word === word);
    if (b) { b.classList.add('playing'); utter.onend = () => b.classList.remove('playing'); utter.onerror = () => b.classList.remove('playing'); }
    synth.speak(utter);
  } catch (e) {
    showToast('朗读失败，请再点一次');
  }
}

/* ---------------- events ---------------- */
document.addEventListener('click', (e) => {
  const tab = e.target.closest('[data-tab]');
  if (tab) { setTab(tab.dataset.tab); return; }

  const actionEl = e.target.closest('[data-action]');
  if (!actionEl) return;
  const action = actionEl.dataset.action;

  switch (action) {
    case 'start-session': startSession(actionEl.dataset.mode || 'mixed'); break;
    case 'close-study': closeStudy(); break;
    case 'restart-session': restartSession(); break;
    case 'reveal-card': revealCard(); break;
    case 'answer': answer(actionEl.dataset.correct === '1'); break;
    case 'speak': speakWord(actionEl.dataset.word, actionEl); break;
    case 'open-detail': {
      const id = actionEl.dataset.id;
      openDetail(id, actionEl.dataset.from || null);
      break;
    }
    case 'close-detail': closeDetail(); break;
    case 'toggle-star': {
      e.stopPropagation();
      const id = actionEl.dataset.id;
      if (!id) break;
      if (state.starred[id]) delete state.starred[id]; else state.starred[id] = true;
      saveStore();
      const on = !!state.starred[id];
      actionEl.classList.toggle('on', on);
      actionEl.setAttribute('aria-label', on ? '取消星标' : '加星标');
      if (state.detail && state.detail.id === id) renderDetail();
      if (state.tab === 'library') refreshLibraryList();
      showToast(on ? '已加入星标' : '已取消星标');
      break;
    }
    case 'single-study': {
      const id = actionEl.dataset.id;
      closeDetail();
      setTimeout(() => startSession('review', [id]), 180);
      break;
    }
    case 'set-size': setSetting('size', Number(actionEl.dataset.value)); break;
    case 'set-goal': setSetting('goal', Number(actionEl.dataset.value)); break;
    case 'toggle-autospeak':
      state.settings.autoSpeak = !state.settings.autoSpeak;
      saveStore(true);
      actionEl.classList.toggle('on', state.settings.autoSpeak);
      break;
    case 'open-settings': openSettings(); break;
    case 'close-settings': closeSettings(); break;
    case 'reset-progress': resetProgress(); break;
    case 'export-progress': exportProgress(); break;
    case 'import-progress': importProgress(); break;
    case 'set-filter':
      state.library.filter = actionEl.dataset.filter;
      state.library.visible = 80;
      document.querySelectorAll('.filter').forEach((b) => b.classList.toggle('is-active', b === actionEl));
      refreshLibraryList();
      break;
    case 'clear-search': {
      state.library.query = '';
      const input = $('#search-input');
      if (input) { input.value = ''; input.focus(); }
      const clear = $('.search .clear');
      if (clear) clear.classList.add('hidden');
      refreshLibraryList();
      break;
    }
    case 'load-more':
      state.library.visible += 80;
      refreshLibraryList();
      break;
  }
});

document.addEventListener('input', (e) => {
  if (e.target.id === 'search-input') {
    state.library.query = e.target.value;
    state.library.visible = 80;
    const clear = $('.search .clear');
    if (clear) clear.classList.toggle('hidden', !state.library.query);
    refreshLibraryList();
  }
});

document.addEventListener('keydown', (e) => {
  if ((e.key === 'Enter' || e.key === ' ') && e.target.classList?.contains('word-row')) {
    e.preventDefault(); e.target.click(); return;
  }
  const tag = (e.target.tagName || '').toLowerCase();
  if (tag === 'input' || tag === 'textarea') {
    if (e.key === 'Escape') e.target.blur();
    return;
  }
  if (e.key === 'Escape') {
    if ($('#settings-layer')) { closeSettings(); return; }
    if ($('#detail-overlay')) { closeDetail(); return; }
    if (state.session) { closeStudy(); return; }
  }
  if (!state.session) return;
  const s = state.session;
  if (e.code === 'Space') {
    e.preventDefault();
    if (!s.revealed) revealCard(); else if (!s.locked) answer(true);
  } else if (s.revealed && !s.locked) {
    if (e.key === 'ArrowLeft' || e.key === '1') { e.preventDefault(); answer(false); }
    if (e.key === 'ArrowRight' || e.key === '2') { e.preventDefault(); answer(true); }
  }
});

/* ---------------- boot ---------------- */
async function boot() {
  loadStore();
  try {
    await loadData();
    const bootEl = $('#boot');
    if (bootEl) {
      bootEl.classList.add('is-gone');
      setTimeout(() => bootEl.remove(), 600);
    }
    renderView();
    const startTab = new URLSearchParams(location.search).get('start');
    if (['study', 'library', 'stats'].includes(startTab)) setTab(startTab);
    if ('serviceWorker' in navigator && (location.protocol === 'https:' || location.hostname === 'localhost' || location.hostname === '127.0.0.1')) {
      navigator.serviceWorker.register('sw.js').catch(() => {});
    }
  } catch (err) {
    console.error(err);
    const bootEl = $('#boot');
    if (bootEl) {
      bootEl.innerHTML = `<div class="boot-mark" style="background:#C9604A">!</div>
        <p class="boot-title">词库没有上岛</p>
        <p class="boot-sub" style="max-width:260px;text-align:center;line-height:1.7">${esc(err.message || '加载失败')}<br>请通过本地服务器打开，而不是直接双击 HTML。</p>
        <button class="btn-ghost" onclick="location.reload()">再试一次</button>`;
    }
  }
}
boot();
