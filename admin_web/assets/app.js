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
  stocksOutput: document.getElementById('stocksOutput'),
  levelsOutput: document.getElementById('levelsOutput'),
  statesOutput: document.getElementById('statesOutput'),
  eventsOutput: document.getElementById('eventsOutput'),
  featuredOutput: document.getElementById('featuredOutput'),
  themesOutput: document.getElementById('themesOutput'),
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
    ['INVALID 수', dashboard.invalid_count],
    ['REUSABLE 수', dashboard.reusable_count],
    ['수동 푸시 로그', dashboard.push_queue_count],
  ];
  elements.dashboardStats.innerHTML = stats
    .map(([label, value]) => `<div class="stat-card"><span class="stat-label">${label}</span><span class="stat-value">${value}</span></div>`)
    .join('');
}

async function refreshAll() {
  const [sessionRes, dashboardRes, stocksRes, levelsRes, statesRes, eventsRes, featuredRes, themesRes, logsRes] = await Promise.all([
    apiRequest('/admin/auth/me'),
    apiRequest('/admin/dashboard'),
    apiRequest('/admin/stocks'),
    apiRequest('/admin/price-levels'),
    apiRequest('/admin/support-states'),
    apiRequest('/admin/signal-events'),
    apiRequest('/admin/home-featured'),
    apiRequest('/admin/themes'),
    apiRequest('/admin/audit-logs'),
  ]);
  renderStats(sessionRes.data, dashboardRes.data);
  renderJson(elements.stocksOutput, stocksRes.data);
  renderJson(elements.levelsOutput, levelsRes.data);
  renderJson(elements.statesOutput, statesRes.data);
  renderJson(elements.eventsOutput, eventsRes.data);
  renderJson(elements.featuredOutput, featuredRes.data);
  renderJson(elements.themesOutput, themesRes.data);
  renderJson(elements.logsOutput, logsRes.data.items);
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
