import { apiRequest, loginRequest } from './api.js';
import {
  renderContentOptions,
  renderFeaturedItems,
  renderPriceLevels,
  renderSelectionSummary,
  renderStats,
  renderStockSearchResults,
  renderStockSummary,
  renderSupportStatesTable,
  renderThemeOptions,
  renderThemeSearchResults,
  renderThemeStockList,
} from './renderers.js';
import { byText, numberOrNull, setMessage } from './utils.js';

const storageKey = 'srlab-admin-session';
const runtimeConfig = window.__SRLAB_ADMIN_CONFIG__ || {};

function detectDefaultApiBaseUrl() {
  if (runtimeConfig.apiBaseUrl) {
    return String(runtimeConfig.apiBaseUrl).replace(/\/$/, '');
  }
  const { protocol, hostname, port } = window.location;
  if (hostname === '127.0.0.1' || hostname === 'localhost') {
    return 'http://127.0.0.1:8000/api/v1';
  }
  const normalizedPort = port ? `:${port}` : '';
  return `${protocol}//${hostname}${normalizedPort}/api/v1`;
}

const appState = {
  apiBaseUrl: detectDefaultApiBaseUrl(),
  token: '',
  adminUsername: '',
  data: {
    session: null,
    dashboard: null,
    stocks: [],
    priceLevels: [],
    supportStates: [],
    homeFeatured: [],
    themes: [],
    contents: [],
  },
  ui: {
    selectedStockId: null,
    selectedLevelStockId: null,
    featuredDraft: [],
    selectedThemeId: null,
    themeStockDraft: [],
    selectedContentId: null,
    selectedContentStockId: null,
    selectedContentThemeId: null,
    stateForceTarget: null,
  },
};

const ids = [
  'apiBaseUrl', 'adminUsername', 'adminPassword', 'loginButton', 'logoutButton', 'loginMessage',
  'loginPanel', 'dashboardPanel', 'dashboardStats', 'workspacePanel', 'manualPushPanel', 'refreshButton',
  'stockSearchInput', 'stockSearchResults', 'stockCode', 'stockName', 'stockMarketType', 'stockSector',
  'stockThemeTags', 'stockMemo', 'stockActive', 'saveStockButton', 'resetStockButton', 'stockCreateNewButton',
  'stockFormMessage', 'selectedStockSummary', 'levelStockSearchInput', 'levelStockSearchResults',
  'levelStockSummary', 'priceLevelType', 'priceLevelPrice', 'priceLevelProximity', 'priceLevelRebound',
  'priceLevelSource', 'priceLevelNote', 'savePriceLevelButton', 'priceLevelMessage', 'supportLevelsList',
  'resistanceLevelsList', 'stateStatusFilter', 'stateSearchInput', 'supportStatesTable', 'featuredSearchInput',
  'featuredSearchResults', 'featuredItemsList', 'saveFeaturedButton', 'featuredFormMessage', 'themeSelect',
  'themeName', 'themeScore', 'themeSummary', 'themeActive', 'themeStockSearchInput', 'themeStockSearchResults',
  'themeStockList', 'saveThemeButton', 'themeFormMessage', 'themeCreateNewButton', 'contentSelect',
  'contentCategory', 'contentTitle', 'contentSummary', 'contentUrl', 'contentThumbnailUrl', 'contentSortOrder',
  'contentPublishedAt', 'contentPublished', 'contentStockSearchInput', 'contentStockSearchResults',
  'contentStockSummary', 'contentThemeSearchInput', 'contentThemeSearchResults', 'contentThemeSummary',
  'saveContentButton', 'contentFormMessage', 'contentCreateNewButton', 'pushUserIdentifier', 'pushTargetPath',
  'pushTitle', 'pushMemo', 'pushMessage', 'pushButton', 'pushMessageStatus', 'stateForceModal',
  'stateForceTarget', 'stateForceStatus', 'stateForceMemo', 'stateForceReason', 'stateForceInvalidReason',
  'submitStateForceButton', 'cancelStateForceButton', 'closeStateModalButton', 'stateForceMessage', 'tabNav',
];
const elements = Object.fromEntries(ids.map((id) => [id, document.getElementById(id)]));

function persistSession() {
  localStorage.setItem(storageKey, JSON.stringify({
    apiBaseUrl: appState.apiBaseUrl,
    token: appState.token,
    adminUsername: appState.adminUsername,
  }));
}

function loadSession() {
  const saved = localStorage.getItem(storageKey);
  elements.apiBaseUrl.value = appState.apiBaseUrl;
  elements.adminUsername.value = runtimeConfig.adminUsername || 'admin';
  if (!saved) {
    return;
  }
  const parsed = JSON.parse(saved);
  appState.apiBaseUrl = parsed.apiBaseUrl || appState.apiBaseUrl;
  appState.token = parsed.token || '';
  appState.adminUsername = parsed.adminUsername || '';
  elements.apiBaseUrl.value = appState.apiBaseUrl;
  elements.adminUsername.value = appState.adminUsername || runtimeConfig.adminUsername || 'admin';
}

function setLoggedIn(isLoggedIn) {
  elements.loginPanel.hidden = isLoggedIn;
  elements.dashboardPanel.hidden = !isLoggedIn;
  elements.workspacePanel.hidden = !isLoggedIn;
  elements.manualPushPanel.hidden = !isLoggedIn;
  elements.logoutButton.hidden = !isLoggedIn;
}

function currentStock() {
  return appState.data.stocks.find((item) => item.id === appState.ui.selectedStockId) || null;
}

function currentLevelStock() {
  return appState.data.stocks.find((item) => item.id === appState.ui.selectedLevelStockId) || null;
}

function renderAll() {
  if (appState.data.session && appState.data.dashboard) {
    renderStats(elements.dashboardStats, appState.data.session, appState.data.dashboard);
  }

  const stockResults = byText(appState.data.stocks, elements.stockSearchInput.value || '', ['code', 'name']).slice(0, 12);
  renderStockSearchResults(elements.stockSearchResults, stockResults, appState.ui.selectedStockId);
  renderStockSummary(
    elements.selectedStockSummary,
    currentStock(),
    appState.data.homeFeatured.map((item) => item.stock_id),
  );

  const levelResults = byText(appState.data.stocks, elements.levelStockSearchInput.value || '', ['code', 'name']).slice(0, 12);
  renderStockSearchResults(elements.levelStockSearchResults, levelResults, appState.ui.selectedLevelStockId);
  const selectedLevelStock = currentLevelStock();
  renderStockSummary(elements.levelStockSummary, selectedLevelStock);
  const levelItems = appState.data.priceLevels.filter((item) => item.stock_id === appState.ui.selectedLevelStockId);
  renderPriceLevels(elements.supportLevelsList, levelItems, 'SUPPORT');
  renderPriceLevels(elements.resistanceLevelsList, levelItems, 'RESISTANCE');

  const stateFiltered = appState.data.supportStates.filter((item) => {
    const statusOk = elements.stateStatusFilter.value === 'ALL' || item.status === elements.stateStatusFilter.value;
    const q = (elements.stateSearchInput.value || '').trim().toLowerCase();
    const searchOk = !q || `${item.stock_name} ${item.stock_code}`.toLowerCase().includes(q);
    return statusOk && searchOk;
  });
  renderSupportStatesTable(elements.supportStatesTable, stateFiltered);

  const featuredResults = byText(appState.data.stocks, elements.featuredSearchInput.value || '', ['code', 'name']).slice(0, 8);
  renderStockSearchResults(elements.featuredSearchResults, featuredResults, null);
  renderFeaturedItems(elements.featuredItemsList, appState.ui.featuredDraft);

  renderThemeOptions(elements.themeSelect, appState.data.themes, appState.ui.selectedThemeId);
  const themeSearchResults = byText(appState.data.stocks, elements.themeStockSearchInput.value || '', ['code', 'name']).slice(0, 8);
  renderStockSearchResults(elements.themeStockSearchResults, themeSearchResults, null);
  renderThemeStockList(elements.themeStockList, appState.ui.themeStockDraft);

  renderContentOptions(elements.contentSelect, appState.data.contents, appState.ui.selectedContentId);
  const contentStockResults = byText(appState.data.stocks, elements.contentStockSearchInput.value || '', ['code', 'name']).slice(0, 8);
  renderStockSearchResults(elements.contentStockSearchResults, contentStockResults, null);
  const contentThemeResults = byText(appState.data.themes, elements.contentThemeSearchInput.value || '', ['name', 'summary']).slice(0, 8);
  renderThemeSearchResults(elements.contentThemeSearchResults, contentThemeResults);

  const selectedContentStock = appState.data.stocks.find((item) => item.id === appState.ui.selectedContentStockId);
  const selectedContentTheme = appState.data.themes.find((item) => item.id === appState.ui.selectedContentThemeId);
  renderSelectionSummary(
    elements.contentStockSummary,
    selectedContentStock ? `${selectedContentStock.name} (${selectedContentStock.code})` : '',
  );
  renderSelectionSummary(
    elements.contentThemeSummary,
    selectedContentTheme ? `${selectedContentTheme.name}${selectedContentTheme.summary ? ` · ${selectedContentTheme.summary}` : ''}` : '',
  );
}

async function refreshAll() {
  const [sessionRes, dashboardRes, stocksRes, levelsRes, statesRes, featuredRes, themesRes, contentsRes] = await Promise.all([
    apiRequest(appState, '/admin/auth/me'),
    apiRequest(appState, '/admin/dashboard'),
    apiRequest(appState, '/admin/stocks'),
    apiRequest(appState, '/admin/price-levels'),
    apiRequest(appState, '/admin/support-states'),
    apiRequest(appState, '/admin/home-featured'),
    apiRequest(appState, '/admin/themes'),
    apiRequest(appState, '/admin/contents'),
  ]);

  appState.data.session = sessionRes.data;
  appState.data.dashboard = dashboardRes.data;
  appState.data.stocks = stocksRes.data;
  appState.data.priceLevels = levelsRes.data;
  appState.data.supportStates = statesRes.data;
  appState.data.homeFeatured = featuredRes.data;
  appState.data.themes = themesRes.data;
  appState.data.contents = contentsRes.data;

  appState.ui.featuredDraft = featuredRes.data.map((item) => ({
    stock_id: item.stock_id,
    stock_name: item.stock_name,
    stock_code: item.stock_code,
    is_active: item.is_active,
    display_order: item.display_order,
  }));

  if (appState.ui.selectedThemeId) {
    hydrateThemeDraft(appState.ui.selectedThemeId);
  }
  if (appState.ui.selectedContentId) {
    hydrateContentDraft(appState.ui.selectedContentId);
  }
  renderAll();
}

function fillStockForm(stock = null) {
  appState.ui.selectedStockId = stock?.id || null;
  elements.stockCode.value = stock?.code || '';
  elements.stockName.value = stock?.name || '';
  elements.stockMarketType.value = stock?.market_type || 'KOSPI';
  elements.stockSector.value = stock?.sector || '';
  elements.stockThemeTags.value = stock?.theme_tags || '';
  elements.stockMemo.value = stock?.operator_memo || '';
  elements.stockActive.checked = stock?.is_active ?? true;
  renderAll();
}

function hydrateThemeDraft(themeId) {
  const theme = appState.data.themes.find((item) => item.id === Number(themeId));
  appState.ui.selectedThemeId = theme ? theme.id : null;
  elements.themeName.value = theme?.name || '';
  elements.themeScore.value = theme?.score || '';
  elements.themeSummary.value = theme?.summary || '';
  elements.themeActive.checked = theme?.is_active ?? true;
  appState.ui.themeStockDraft = (theme?.stocks || []).map((item) => ({ ...item }));
  renderAll();
}

function hydrateContentDraft(contentId) {
  const content = appState.data.contents.find((item) => item.id === Number(contentId));
  appState.ui.selectedContentId = content ? content.id : null;
  elements.contentCategory.value = content?.category || 'SHORTS';
  elements.contentTitle.value = content?.title || '';
  elements.contentSummary.value = content?.summary || '';
  elements.contentUrl.value = content?.external_url || '';
  elements.contentThumbnailUrl.value = content?.thumbnail_url || '';
  elements.contentSortOrder.value = String(content?.sort_order ?? 0);
  elements.contentPublishedAt.value = content?.published_at || '';
  elements.contentPublished.checked = content?.is_published ?? true;
  appState.ui.selectedContentStockId = content?.stock_id || null;
  appState.ui.selectedContentThemeId = content?.theme_id || null;
  renderAll();
}

async function login() {
  appState.apiBaseUrl = elements.apiBaseUrl.value.trim().replace(/\/$/, '');
  const payload = await loginRequest(appState.apiBaseUrl, elements.adminUsername.value.trim(), elements.adminPassword.value);
  appState.token = payload.data.access_token;
  appState.adminUsername = payload.data.admin_username;
  persistSession();
  setLoggedIn(true);
  setMessage(elements.loginMessage, '로그인 성공. 관리자 데이터를 불러옵니다.');
  await refreshAll();
}

async function saveStock() {
  const payload = {
    code: elements.stockCode.value.trim(),
    name: elements.stockName.value.trim(),
    market_type: elements.stockMarketType.value.trim() || 'OTHER',
    sector: elements.stockSector.value.trim() || null,
    theme_tags: elements.stockThemeTags.value.trim() || null,
    operator_memo: elements.stockMemo.value.trim() || null,
    is_active: elements.stockActive.checked,
  };
  const path = appState.ui.selectedStockId ? `/admin/stocks/${appState.ui.selectedStockId}` : '/admin/stocks';
  const method = appState.ui.selectedStockId ? 'PUT' : 'POST';
  const response = await apiRequest(appState, path, { method, body: JSON.stringify(payload) });
  setMessage(elements.stockFormMessage, response.message, 'success');
  await refreshAll();
  const savedStock = appState.data.stocks.find((item) => item.id === response.data.id) || null;
  fillStockForm(savedStock);
}

async function savePriceLevel() {
  if (!appState.ui.selectedLevelStockId) {
    throw new Error('먼저 종목을 선택해주세요.');
  }
  const payload = {
    stock_id: appState.ui.selectedLevelStockId,
    level_type: elements.priceLevelType.value,
    price: elements.priceLevelPrice.value.trim(),
    proximity_threshold_pct: elements.priceLevelProximity.value.trim() || '1.50',
    rebound_threshold_pct: elements.priceLevelRebound.value.trim() || '5.00',
    source_label: elements.priceLevelSource.value,
    note: elements.priceLevelNote.value.trim() || null,
    is_active: true,
  };
  const response = await apiRequest(appState, '/admin/price-levels', { method: 'POST', body: JSON.stringify(payload) });
  setMessage(elements.priceLevelMessage, response.message, 'success');
  elements.priceLevelPrice.value = '';
  elements.priceLevelNote.value = '';
  await refreshAll();
}

async function togglePriceLevel(levelId, nextActive) {
  const current = appState.data.priceLevels.find((item) => item.id === Number(levelId));
  if (!current) {
    return;
  }
  const payload = {
    stock_id: current.stock_id,
    level_type: current.level_type,
    price: current.price,
    proximity_threshold_pct: current.proximity_threshold_pct,
    rebound_threshold_pct: current.rebound_threshold_pct,
    source_label: current.source_label,
    note: current.note,
    is_active: nextActive === 'true',
  };
  await apiRequest(appState, `/admin/price-levels/${levelId}`, { method: 'PUT', body: JSON.stringify(payload) });
  await refreshAll();
}

async function saveFeatured() {
  const items = appState.ui.featuredDraft.map((item, index) => ({
    stock_id: item.stock_id,
    display_order: index + 1,
    is_active: item.is_active,
  }));
  const response = await apiRequest(appState, '/admin/home-featured', {
    method: 'PUT',
    body: JSON.stringify({ items }),
  });
  setMessage(elements.featuredFormMessage, response.message, 'success');
  await refreshAll();
}

async function saveTheme() {
  const payload = {
    name: elements.themeName.value.trim(),
    score: numberOrNull(elements.themeScore.value),
    summary: elements.themeSummary.value.trim() || null,
    is_active: elements.themeActive.checked,
    stocks: appState.ui.themeStockDraft.map((item) => ({
      stock_id: item.stock_id,
      role_type: item.role_type,
      score: numberOrNull(item.score),
    })),
  };
  const path = appState.ui.selectedThemeId ? `/admin/themes/${appState.ui.selectedThemeId}` : '/admin/themes';
  const method = appState.ui.selectedThemeId ? 'PUT' : 'POST';
  const response = await apiRequest(appState, path, { method, body: JSON.stringify(payload) });
  setMessage(elements.themeFormMessage, response.message, 'success');
  await refreshAll();
  hydrateThemeDraft(response.data.id);
}

async function saveContent() {
  const payload = {
    category: elements.contentCategory.value,
    title: elements.contentTitle.value.trim(),
    summary: elements.contentSummary.value.trim() || null,
    external_url: elements.contentUrl.value.trim() || null,
    thumbnail_url: elements.contentThumbnailUrl.value.trim() || null,
    stock_id: appState.ui.selectedContentStockId,
    theme_id: appState.ui.selectedContentThemeId,
    sort_order: Number(elements.contentSortOrder.value.trim() || 0),
    published_at: elements.contentPublishedAt.value.trim() || null,
    is_published: elements.contentPublished.checked,
  };
  const path = appState.ui.selectedContentId ? `/admin/contents/${appState.ui.selectedContentId}` : '/admin/contents';
  const method = appState.ui.selectedContentId ? 'PUT' : 'POST';
  const response = await apiRequest(appState, path, { method, body: JSON.stringify(payload) });
  setMessage(elements.contentFormMessage, response.message, 'success');
  await refreshAll();
  hydrateContentDraft(response.data.id);
}

async function sendManualPush() {
  const payload = {
    user_identifier: elements.pushUserIdentifier.value.trim(),
    target_path: elements.pushTargetPath.value.trim(),
    title: elements.pushTitle.value.trim(),
    message: elements.pushMessage.value.trim(),
    memo: elements.pushMemo.value.trim(),
  };
  const response = await apiRequest(appState, '/admin/manual-push', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  setMessage(elements.pushMessageStatus, response.message, 'success');
}

async function submitStateForceUpdate() {
  if (!appState.ui.stateForceTarget) {
    throw new Error('수정할 상태를 먼저 선택해주세요.');
  }
  const response = await apiRequest(
    appState,
    `/admin/support-states/${appState.ui.stateForceTarget.id}/force`,
    {
      method: 'PATCH',
      body: JSON.stringify({
        status: elements.stateForceStatus.value,
        memo: elements.stateForceMemo.value.trim(),
        status_reason: elements.stateForceReason.value.trim() || null,
        invalid_reason: elements.stateForceInvalidReason.value.trim() || null,
      }),
    },
  );
  setMessage(elements.stateForceMessage, response.message, 'success');
  await refreshAll();
  closeStateModal();
}

function closeStateModal() {
  elements.stateForceModal.hidden = true;
  appState.ui.stateForceTarget = null;
  elements.stateForceMemo.value = '';
  elements.stateForceReason.value = '';
  elements.stateForceInvalidReason.value = '';
  setMessage(elements.stateForceMessage, '');
}

function openStateModal(stateId) {
  const target = appState.data.supportStates.find((item) => item.id === Number(stateId));
  if (!target) {
    return;
  }
  appState.ui.stateForceTarget = target;
  elements.stateForceTarget.textContent = `${target.stock_name} (${target.stock_code}) · ${target.level_price} · 현재 ${target.status}`;
  elements.stateForceStatus.value = target.status;
  elements.stateForceModal.hidden = false;
}

function wireTabNavigation() {
  elements.tabNav.addEventListener('click', (event) => {
    const button = event.target.closest('.tab-button');
    if (!button) {
      return;
    }
    document.querySelectorAll('.tab-button').forEach((item) => item.classList.remove('active'));
    document.querySelectorAll('.tab-panel').forEach((item) => item.classList.remove('active'));
    button.classList.add('active');
    document.getElementById(button.dataset.tab).classList.add('active');
  });
}

function bindSearchReRendering() {
  [
    elements.stockSearchInput,
    elements.levelStockSearchInput,
    elements.stateSearchInput,
    elements.featuredSearchInput,
    elements.themeStockSearchInput,
    elements.contentStockSearchInput,
    elements.contentThemeSearchInput,
    elements.stateStatusFilter,
  ].forEach((input) => input.addEventListener('input', renderAll));
  elements.stateStatusFilter.addEventListener('change', renderAll);
}

function bindDelegatedClicks() {
  document.body.addEventListener('click', async (event) => {
    const stockItem = event.target.closest('[data-stock-id]');
    if (stockItem && stockItem.classList.contains('selection-item')) {
      const stock = appState.data.stocks.find((item) => item.id === Number(stockItem.dataset.stockId));
      if (stockItem.parentElement === elements.stockSearchResults) {
        fillStockForm(stock);
      } else if (stockItem.parentElement === elements.levelStockSearchResults) {
        appState.ui.selectedLevelStockId = stock?.id || null;
        renderAll();
      } else if (stockItem.parentElement === elements.featuredSearchResults) {
        if (stock && !appState.ui.featuredDraft.some((item) => item.stock_id === stock.id)) {
          appState.ui.featuredDraft.push({ stock_id: stock.id, stock_name: stock.name, stock_code: stock.code, is_active: true });
          renderAll();
        }
      } else if (stockItem.parentElement === elements.themeStockSearchResults) {
        if (stock && !appState.ui.themeStockDraft.some((item) => item.stock_id === stock.id)) {
          appState.ui.themeStockDraft.push({ stock_id: stock.id, stock_name: stock.name, role_type: 'FOLLOWER', score: '' });
          renderAll();
        }
      } else if (stockItem.parentElement === elements.contentStockSearchResults) {
        appState.ui.selectedContentStockId = stock?.id || null;
        renderAll();
      }
      return;
    }

    const themeItem = event.target.closest('[data-theme-id]');
    if (themeItem && themeItem.parentElement === elements.contentThemeSearchResults) {
      appState.ui.selectedContentThemeId = Number(themeItem.dataset.themeId);
      renderAll();
      return;
    }

    if (event.target.matches('[data-level-toggle-id]')) {
      await togglePriceLevel(event.target.dataset.levelToggleId, event.target.dataset.nextActive);
      return;
    }
    if (event.target.matches('[data-force-state-id]')) {
      openStateModal(event.target.dataset.forceStateId);
      return;
    }
    if (event.target.matches('[data-featured-remove]')) {
      appState.ui.featuredDraft = appState.ui.featuredDraft.filter((item) => item.stock_id !== Number(event.target.dataset.featuredRemove));
      renderAll();
      return;
    }
    if (event.target.matches('[data-featured-toggle]')) {
      const item = appState.ui.featuredDraft.find((entry) => entry.stock_id === Number(event.target.dataset.featuredToggle));
      if (item) {
        item.is_active = !item.is_active;
      }
      renderAll();
      return;
    }
    if (event.target.matches('[data-featured-move]')) {
      const stockId = Number(event.target.dataset.stockId);
      const index = appState.ui.featuredDraft.findIndex((item) => item.stock_id === stockId);
      const direction = event.target.dataset.featuredMove;
      const swapIndex = direction === 'up' ? index - 1 : index + 1;
      if (index >= 0 && appState.ui.featuredDraft[swapIndex]) {
        [appState.ui.featuredDraft[index], appState.ui.featuredDraft[swapIndex]] = [appState.ui.featuredDraft[swapIndex], appState.ui.featuredDraft[index]];
      }
      renderAll();
      return;
    }
    if (event.target.matches('[data-theme-stock-remove]')) {
      appState.ui.themeStockDraft = appState.ui.themeStockDraft.filter((item) => item.stock_id !== Number(event.target.dataset.themeStockRemove));
      renderAll();
    }
  });

  document.body.addEventListener('change', (event) => {
    if (event.target.matches('[data-theme-stock-role]')) {
      const target = appState.ui.themeStockDraft.find((item) => item.stock_id === Number(event.target.dataset.themeStockRole));
      if (target) {
        target.role_type = event.target.value;
      }
    }
    if (event.target.matches('[data-theme-stock-score]')) {
      const target = appState.ui.themeStockDraft.find((item) => item.stock_id === Number(event.target.dataset.themeStockScore));
      if (target) {
        target.score = event.target.value;
      }
    }
  });
}

function bindPrimaryActions() {
  elements.loginButton.addEventListener('click', async () => {
    try {
      await login();
    } catch (error) {
      setMessage(elements.loginMessage, error.message, 'error');
    }
  });
  elements.logoutButton.addEventListener('click', () => {
    localStorage.removeItem(storageKey);
    appState.token = '';
    setLoggedIn(false);
    setMessage(elements.loginMessage, '로그아웃했습니다.');
  });
  elements.refreshButton.addEventListener('click', async () => {
    try {
      await refreshAll();
    } catch (error) {
      setMessage(elements.loginMessage, error.message, 'error');
    }
  });
  elements.saveStockButton.addEventListener('click', async () => {
    try {
      await saveStock();
    } catch (error) {
      setMessage(elements.stockFormMessage, error.message, 'error');
    }
  });
  elements.resetStockButton.addEventListener('click', () => fillStockForm(null));
  elements.stockCreateNewButton.addEventListener('click', () => fillStockForm(null));
  elements.savePriceLevelButton.addEventListener('click', async () => {
    try {
      await savePriceLevel();
    } catch (error) {
      setMessage(elements.priceLevelMessage, error.message, 'error');
    }
  });
  elements.saveFeaturedButton.addEventListener('click', async () => {
    try {
      await saveFeatured();
    } catch (error) {
      setMessage(elements.featuredFormMessage, error.message, 'error');
    }
  });
  elements.themeSelect.addEventListener('change', () => hydrateThemeDraft(elements.themeSelect.value));
  elements.themeCreateNewButton.addEventListener('click', () => hydrateThemeDraft(null));
  elements.saveThemeButton.addEventListener('click', async () => {
    try {
      await saveTheme();
    } catch (error) {
      setMessage(elements.themeFormMessage, error.message, 'error');
    }
  });
  elements.contentSelect.addEventListener('change', () => hydrateContentDraft(elements.contentSelect.value));
  elements.contentCreateNewButton.addEventListener('click', () => hydrateContentDraft(null));
  elements.saveContentButton.addEventListener('click', async () => {
    try {
      await saveContent();
    } catch (error) {
      setMessage(elements.contentFormMessage, error.message, 'error');
    }
  });
  elements.pushButton.addEventListener('click', async () => {
    try {
      await sendManualPush();
    } catch (error) {
      setMessage(elements.pushMessageStatus, error.message, 'error');
    }
  });
  elements.submitStateForceButton.addEventListener('click', async () => {
    try {
      await submitStateForceUpdate();
    } catch (error) {
      setMessage(elements.stateForceMessage, error.message, 'error');
    }
  });
  elements.cancelStateForceButton.addEventListener('click', closeStateModal);
  elements.closeStateModalButton.addEventListener('click', closeStateModal);
}

async function bootstrap() {
  loadSession();
  wireTabNavigation();
  bindSearchReRendering();
  bindDelegatedClicks();
  bindPrimaryActions();
  if (appState.token) {
    setLoggedIn(true);
    try {
      await refreshAll();
    } catch (error) {
      localStorage.removeItem(storageKey);
      appState.token = '';
      setLoggedIn(false);
      setMessage(elements.loginMessage, `세션을 복원하지 못했습니다: ${error.message}`, 'error');
    }
  }
}

bootstrap();
