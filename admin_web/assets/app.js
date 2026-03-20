const storageKey = 'srlab-admin-session';

const state = {
  apiBaseUrl: '',
  token: '',
  adminUsername: '',
};

const elements = {
  apiBaseUrl: document.getElementById('apiBaseUrl'),
  adminUsername: document.getElementById('adminUsername'),
  adminPassword: document.getElementById('adminPassword'),
  loginButton: document.getElementById('loginButton'),
  logoutButton: document.getElementById('logoutButton'),
  loginMessage: document.getElementById('loginMessage'),
  loginPanel: document.getElementById('loginPanel'),
  dashboardPanel: document.getElementById('dashboardPanel'),
  dashboardStats: document.getElementById('dashboardStats'),
  crudPanel: document.getElementById('crudPanel'),
  manualPushPanel: document.getElementById('manualPushPanel'),
  resourcesPanel: document.getElementById('resourcesPanel'),
  refreshButton: document.getElementById('refreshButton'),
  pushUserIdentifier: document.getElementById('pushUserIdentifier'),
  pushTargetPath: document.getElementById('pushTargetPath'),
  pushTitle: document.getElementById('pushTitle'),
  pushMemo: document.getElementById('pushMemo'),
  pushMessage: document.getElementById('pushMessage'),
  pushButton: document.getElementById('pushButton'),
  pushMessageStatus: document.getElementById('pushMessageStatus'),
  stockId: document.getElementById('stockId'),
  stockCode: document.getElementById('stockCode'),
  stockName: document.getElementById('stockName'),
  stockMarketType: document.getElementById('stockMarketType'),
  stockSector: document.getElementById('stockSector'),
  stockThemeTags: document.getElementById('stockThemeTags'),
  stockMemo: document.getElementById('stockMemo'),
  stockActive: document.getElementById('stockActive'),
  saveStockButton: document.getElementById('saveStockButton'),
  stockFormMessage: document.getElementById('stockFormMessage'),
  featuredItems: document.getElementById('featuredItems'),
  saveFeaturedButton: document.getElementById('saveFeaturedButton'),
  featuredFormMessage: document.getElementById('featuredFormMessage'),
  themeId: document.getElementById('themeId'),
  themeName: document.getElementById('themeName'),
  themeScore: document.getElementById('themeScore'),
  themeSummary: document.getElementById('themeSummary'),
  themeStocks: document.getElementById('themeStocks'),
  themeActive: document.getElementById('themeActive'),
  saveThemeButton: document.getElementById('saveThemeButton'),
  themeFormMessage: document.getElementById('themeFormMessage'),
  contentId: document.getElementById('contentId'),
  contentCategory: document.getElementById('contentCategory'),
  contentTitle: document.getElementById('contentTitle'),
  contentSummary: document.getElementById('contentSummary'),
  contentUrl: document.getElementById('contentUrl'),
  contentThumbnailUrl: document.getElementById('contentThumbnailUrl'),
  contentStockId: document.getElementById('contentStockId'),
  contentThemeId: document.getElementById('contentThemeId'),
  contentSortOrder: document.getElementById('contentSortOrder'),
  contentPublishedAt: document.getElementById('contentPublishedAt'),
  contentPublished: document.getElementById('contentPublished'),
  saveContentButton: document.getElementById('saveContentButton'),
  contentFormMessage: document.getElementById('contentFormMessage'),
  stocksOutput: document.getElementById('stocksOutput'),
  levelsOutput: document.getElementById('levelsOutput'),
  statesOutput: document.getElementById('statesOutput'),
  eventsOutput: document.getElementById('eventsOutput'),
  featuredOutput: document.getElementById('featuredOutput'),
  themesOutput: document.getElementById('themesOutput'),
  contentsOutput: document.getElementById('contentsOutput'),
  logsOutput: document.getElementById('logsOutput'),
};

function persistSession() {
  localStorage.setItem(storageKey, JSON.stringify(state));
}

function loadSession() {
  const saved = localStorage.getItem(storageKey);
  if (!saved) {
    state.apiBaseUrl = elements.apiBaseUrl.value.trim();
    return;
  }
  const parsed = JSON.parse(saved);
  state.apiBaseUrl = parsed.apiBaseUrl || elements.apiBaseUrl.value.trim();
  state.token = parsed.token || '';
  state.adminUsername = parsed.adminUsername || '';
  elements.apiBaseUrl.value = state.apiBaseUrl;
  elements.adminUsername.value = state.adminUsername || elements.adminUsername.value;
}

function setLoggedIn(isLoggedIn) {
  elements.loginPanel.hidden = isLoggedIn;
  elements.dashboardPanel.hidden = !isLoggedIn;
  elements.crudPanel.hidden = !isLoggedIn;
  elements.manualPushPanel.hidden = !isLoggedIn;
  elements.resourcesPanel.hidden = !isLoggedIn;
  elements.logoutButton.hidden = !isLoggedIn;
}

async function apiRequest(path, options = {}) {
  const response = await fetch(`${state.apiBaseUrl}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(state.token ? { Authorization: `Bearer ${state.token}` } : {}),
      ...(options.headers || {}),
    },
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || '요청에 실패했습니다.');
  }
  return data;
}

function renderJson(element, payload) {
  element.textContent = JSON.stringify(payload, null, 2);
}

function renderStats(sessionData, dashboard) {
  const stats = [
    ['관리자', sessionData.admin_username],
    ['권한', sessionData.role],
    ['활성 종목 수', dashboard.stock_count],
    ['오늘 신호 수', dashboard.signal_event_count],
    ['공개 콘텐츠 수', dashboard.content_count],
    ['INVALID 수', dashboard.invalid_count],
    ['REUSABLE 수', dashboard.reusable_count],
    ['수동 푸시 로그', dashboard.push_queue_count],
  ];
  elements.dashboardStats.innerHTML = stats
    .map(([label, value]) => `<div class="stat-card"><span class="stat-label">${label}</span><span class="stat-value">${value}</span></div>`)
    .join('');
}

async function refreshAll() {
  const [sessionRes, dashboardRes, stocksRes, levelsRes, statesRes, eventsRes, featuredRes, themesRes, contentsRes, logsRes] = await Promise.all([
    apiRequest('/admin/auth/me'),
    apiRequest('/admin/dashboard'),
    apiRequest('/admin/stocks'),
    apiRequest('/admin/price-levels'),
    apiRequest('/admin/support-states'),
    apiRequest('/admin/signal-events'),
    apiRequest('/admin/home-featured'),
    apiRequest('/admin/themes'),
    apiRequest('/admin/contents'),
    apiRequest('/admin/audit-logs'),
  ]);
  renderStats(sessionRes.data, dashboardRes.data);
  renderJson(elements.stocksOutput, stocksRes.data);
  renderJson(elements.levelsOutput, levelsRes.data);
  renderJson(elements.statesOutput, statesRes.data);
  renderJson(elements.eventsOutput, eventsRes.data);
  renderJson(elements.featuredOutput, featuredRes.data);
  renderJson(elements.themesOutput, themesRes.data);
  renderJson(elements.contentsOutput, contentsRes.data);
  renderJson(elements.logsOutput, logsRes.data.items);
}

function parseBooleanText(value) {
  return ['true', '1', 'y', 'yes'].includes(String(value).trim().toLowerCase());
}

function parseCsvLines(text, mapper) {
  return text
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => mapper(line.split(',').map((item) => item.trim())));
}

async function login() {
  state.apiBaseUrl = elements.apiBaseUrl.value.trim().replace(/\/$/, '');
  const username = elements.adminUsername.value.trim();
  const password = elements.adminPassword.value;
  const response = await fetch(`${state.apiBaseUrl}/admin/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload.message || '로그인에 실패했습니다.');
  }
  state.token = payload.data.access_token;
  state.adminUsername = payload.data.admin_username;
  persistSession();
  setLoggedIn(true);
  elements.loginMessage.textContent = '로그인 성공. 관리자 데이터를 불러옵니다.';
  await refreshAll();
}

async function saveStock() {
  const stockId = elements.stockId.value.trim();
  const payload = {
    code: elements.stockCode.value.trim(),
    name: elements.stockName.value.trim(),
    market_type: elements.stockMarketType.value.trim() || 'OTHER',
    sector: elements.stockSector.value.trim() || null,
    theme_tags: elements.stockThemeTags.value.trim() || null,
    operator_memo: elements.stockMemo.value.trim() || null,
    is_active: elements.stockActive.checked,
  };
  const path = stockId ? `/admin/stocks/${stockId}` : '/admin/stocks';
  const method = stockId ? 'PUT' : 'POST';
  const response = await apiRequest(path, { method, body: JSON.stringify(payload) });
  elements.stockFormMessage.textContent = response.message;
  await refreshAll();
}

async function saveFeatured() {
  const items = parseCsvLines(elements.featuredItems.value, ([stockId, displayOrder, isActive]) => ({
    stock_id: Number(stockId),
    display_order: Number(displayOrder || 0),
    is_active: parseBooleanText(isActive ?? 'true'),
  }));
  const response = await apiRequest('/admin/home-featured', {
    method: 'PUT',
    body: JSON.stringify({ items }),
  });
  elements.featuredFormMessage.textContent = response.message;
  await refreshAll();
}

async function saveTheme() {
  const themeId = elements.themeId.value.trim();
  const stocks = parseCsvLines(elements.themeStocks.value, ([stockId, roleType, score]) => ({
    stock_id: Number(stockId),
    role_type: roleType || 'FOLLOWER',
    score: score ? Number(score) : null,
  }));
  const payload = {
    name: elements.themeName.value.trim(),
    score: elements.themeScore.value.trim() ? Number(elements.themeScore.value.trim()) : null,
    summary: elements.themeSummary.value.trim() || null,
    is_active: elements.themeActive.checked,
    stocks,
  };
  const path = themeId ? `/admin/themes/${themeId}` : '/admin/themes';
  const method = themeId ? 'PUT' : 'POST';
  const response = await apiRequest(path, { method, body: JSON.stringify(payload) });
  elements.themeFormMessage.textContent = response.message;
  await refreshAll();
}

async function saveContent() {
  const contentId = elements.contentId.value.trim();
  const payload = {
    category: elements.contentCategory.value.trim(),
    title: elements.contentTitle.value.trim(),
    summary: elements.contentSummary.value.trim() || null,
    external_url: elements.contentUrl.value.trim() || null,
    thumbnail_url: elements.contentThumbnailUrl.value.trim() || null,
    stock_id: elements.contentStockId.value.trim() ? Number(elements.contentStockId.value.trim()) : null,
    theme_id: elements.contentThemeId.value.trim() ? Number(elements.contentThemeId.value.trim()) : null,
    sort_order: Number(elements.contentSortOrder.value.trim() || 0),
    published_at: elements.contentPublishedAt.value.trim() || null,
    is_published: elements.contentPublished.checked,
  };
  const path = contentId ? `/admin/contents/${contentId}` : '/admin/contents';
  const method = contentId ? 'PUT' : 'POST';
  const response = await apiRequest(path, { method, body: JSON.stringify(payload) });
  elements.contentFormMessage.textContent = response.message;
  await refreshAll();
}

async function sendManualPush() {
  const payload = {
    user_identifier: elements.pushUserIdentifier.value.trim(),
    target_path: elements.pushTargetPath.value.trim(),
    title: elements.pushTitle.value.trim(),
    message: elements.pushMessage.value.trim(),
    memo: elements.pushMemo.value.trim(),
  };
  const response = await apiRequest('/admin/manual-push', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  elements.pushMessageStatus.textContent = response.message;
  await refreshAll();
}

function logout() {
  localStorage.removeItem(storageKey);
  state.token = '';
  state.adminUsername = '';
  setLoggedIn(false);
  elements.loginMessage.textContent = '로그아웃했습니다.';
}

elements.loginButton.addEventListener('click', async () => {
  elements.loginMessage.textContent = '';
  try {
    await login();
  } catch (error) {
    elements.loginMessage.textContent = error.message;
  }
});

elements.logoutButton.addEventListener('click', logout);
elements.refreshButton.addEventListener('click', async () => {
  try {
    await refreshAll();
  } catch (error) {
    elements.loginMessage.textContent = error.message;
  }
});

elements.saveStockButton.addEventListener('click', async () => {
  elements.stockFormMessage.textContent = '';
  try {
    await saveStock();
  } catch (error) {
    elements.stockFormMessage.textContent = error.message;
  }
});

elements.saveFeaturedButton.addEventListener('click', async () => {
  elements.featuredFormMessage.textContent = '';
  try {
    await saveFeatured();
  } catch (error) {
    elements.featuredFormMessage.textContent = error.message;
  }
});

elements.saveThemeButton.addEventListener('click', async () => {
  elements.themeFormMessage.textContent = '';
  try {
    await saveTheme();
  } catch (error) {
    elements.themeFormMessage.textContent = error.message;
  }
});

elements.saveContentButton.addEventListener('click', async () => {
  elements.contentFormMessage.textContent = '';
  try {
    await saveContent();
  } catch (error) {
    elements.contentFormMessage.textContent = error.message;
  }
});

elements.pushButton.addEventListener('click', async () => {
  elements.pushMessageStatus.textContent = '';
  try {
    await sendManualPush();
  } catch (error) {
    elements.pushMessageStatus.textContent = error.message;
  }
});

loadSession();
if (state.token) {
  setLoggedIn(true);
  refreshAll().catch((error) => {
    elements.loginMessage.textContent = error.message;
    logout();
  });
} else {
  setLoggedIn(false);
}
