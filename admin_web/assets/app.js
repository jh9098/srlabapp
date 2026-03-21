import { apiRequest, loginRequest } from './api.js';
import {
  renderContentOptions,
  renderHomeWatchlistItems,
  renderPriceLevels,
  renderSelectionSummary,
  renderStats,
  renderStockSearchResults,
  renderStockSummary,
  renderThemeOptions,
  renderThemeSearchResults,
  renderThemeStockList,
} from './renderers.js';
import { byText, numberOrNull, setMessage } from './utils.js';

const storageKey = 'srlab-admin-session';
const runtimeConfig = window.__SRLAB_ADMIN_CONFIG__ || {};
const HOME_SOURCE_LABEL = 'admin_home';

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
    homeFeatured: [],
    themes: [],
    contents: [],
  },
  ui: {
    selectedHomeStockId: null,
    editingFeaturedStockId: null,
    selectedLevelStockId: null,
    selectedThemeId: null,
    themeStockDraft: [],
    selectedContentId: null,
    selectedContentStockId: null,
    selectedContentThemeId: null,
  },
};

const ids = [
  'apiBaseUrl', 'adminUsername', 'adminPassword', 'loginButton', 'logoutButton', 'loginMessage',
  'loginPanel', 'dashboardPanel', 'dashboardStats', 'workspacePanel', 'manualPushPanel', 'refreshButton',
  'homeStockSearchInput', 'homeStockSearchResults', 'selectedHomeStockSummary', 'homeSupportPrice', 'homeComment',
  'saveHomeWatchlistButton', 'resetHomeWatchlistButton', 'homeWatchlistMessage', 'homeWatchlistList',
  'levelStockSearchInput', 'levelStockSearchResults', 'levelStockSummary', 'priceLevelType', 'priceLevelPrice',
  'priceLevelProximity', 'priceLevelRebound', 'priceLevelSource', 'priceLevelNote', 'savePriceLevelButton',
  'priceLevelMessage', 'supportLevelsList', 'resistanceLevelsList', 'themeSelect', 'themeName', 'themeScore',
  'themeSummary', 'themeActive', 'themeStockSearchInput', 'themeStockSearchResults', 'themeStockList',
  'saveThemeButton', 'themeFormMessage', 'themeCreateNewButton', 'contentSelect', 'contentCategory', 'contentTitle',
  'contentSummary', 'contentUrl', 'contentThumbnailUrl', 'contentSortOrder', 'contentPublishedAt', 'contentPublished',
  'contentStockSearchInput', 'contentStockSearchResults', 'contentStockSummary', 'contentThemeSearchInput',
  'contentThemeSearchResults', 'contentThemeSummary', 'saveContentButton', 'contentFormMessage',
  'contentCreateNewButton', 'pushUserIdentifier', 'pushTargetPath', 'pushTitle', 'pushMemo', 'pushMessage',
  'pushButton', 'pushMessageStatus', 'tabNav',
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

function currentHomeStock() {
  return appState.data.stocks.find((item) => item.id === appState.ui.selectedHomeStockId) || null;
}

function currentLevelStock() {
  return appState.data.stocks.find((item) => item.id === appState.ui.selectedLevelStockId) || null;
}

function getAdminHomeSupportLevel(stockId) {
  return appState.data.priceLevels.find(
    (item) => item.stock_id === stockId && item.level_type === 'SUPPORT' && item.source_label === HOME_SOURCE_LABEL && item.is_active,
  ) || null;
}

function buildHomeWatchlistItems() {
  return [...appState.data.homeFeatured]
    .filter((item) => item.is_active)
    .sort((a, b) => a.display_order - b.display_order)
    .map((item) => {
      const supportLevel = getAdminHomeSupportLevel(item.stock_id);
      const stock = appState.data.stocks.find((entry) => entry.id === item.stock_id);
      return {
        stock_id: item.stock_id,
        stock_name: item.stock_name,
        stock_code: item.stock_code,
        support_price: supportLevel?.price || '-',
        comment: stock?.operator_memo || supportLevel?.note || '',
        is_active: item.is_active,
      };
    });
}

function renderAll() {
  if (appState.data.session && appState.data.dashboard) {
    renderStats(elements.dashboardStats, appState.data.session, appState.data.dashboard);
  }

  const homeSearchQuery = elements.homeStockSearchInput.value || '';
  const homeResults = homeSearchQuery.trim()
    ? byText(appState.data.stocks, homeSearchQuery, ['code', 'name']).slice(0, 12)
    : [];
  renderStockSearchResults(elements.homeStockSearchResults, homeResults, appState.ui.selectedHomeStockId);
  renderStockSummary(
    elements.selectedHomeStockSummary,
    currentHomeStock(),
    appState.data.homeFeatured.filter((item) => item.is_active).map((item) => item.stock_id),
  );
  renderHomeWatchlistItems(elements.homeWatchlistList, buildHomeWatchlistItems());
  elements.saveHomeWatchlistButton.disabled = !appState.ui.selectedHomeStockId;

  const levelResults = byText(appState.data.stocks, elements.levelStockSearchInput.value || '', ['code', 'name']).slice(0, 12);
  renderStockSearchResults(elements.levelStockSearchResults, levelResults, appState.ui.selectedLevelStockId);
  const selectedLevelStock = currentLevelStock();
  renderStockSummary(elements.levelStockSummary, selectedLevelStock);
  const levelItems = appState.data.priceLevels.filter((item) => item.stock_id === appState.ui.selectedLevelStockId);
  renderPriceLevels(elements.supportLevelsList, levelItems, 'SUPPORT');
  renderPriceLevels(elements.resistanceLevelsList, levelItems, 'RESISTANCE');

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
  const [sessionRes, dashboardRes, stocksRes, levelsRes, featuredRes, themesRes, contentsRes] = await Promise.all([
    apiRequest(appState, '/admin/auth/me'),
    apiRequest(appState, '/admin/dashboard'),
    apiRequest(appState, '/admin/stocks'),
    apiRequest(appState, '/admin/price-levels'),
    apiRequest(appState, '/admin/home-featured'),
    apiRequest(appState, '/admin/themes'),
    apiRequest(appState, '/admin/contents'),
  ]);

  appState.data.session = sessionRes.data;
  appState.data.dashboard = dashboardRes.data;
  appState.data.stocks = stocksRes.data;
  appState.data.priceLevels = levelsRes.data;
  appState.data.homeFeatured = featuredRes.data;
  appState.data.themes = themesRes.data;
  appState.data.contents = contentsRes.data;

  if (appState.ui.selectedThemeId) {
    hydrateThemeDraft(appState.ui.selectedThemeId);
  }
  if (appState.ui.selectedContentId) {
    hydrateContentDraft(appState.ui.selectedContentId);
  }
  if (appState.ui.selectedHomeStockId) {
    const supportLevel = getAdminHomeSupportLevel(appState.ui.selectedHomeStockId);
    const stock = currentHomeStock();
    if (stock) {
      elements.homeComment.value = stock.operator_memo || supportLevel?.note || '';
      elements.homeSupportPrice.value = supportLevel?.price || '';
    }
  }
  renderAll();
}

function fillHomeWatchlistForm(stock = null, message = '') {
  appState.ui.selectedHomeStockId = stock?.id || null;
  appState.ui.editingFeaturedStockId = stock?.id || null;
  const supportLevel = stock ? getAdminHomeSupportLevel(stock.id) : null;
  elements.homeSupportPrice.value = supportLevel?.price || '';
  elements.homeComment.value = stock?.operator_memo || supportLevel?.note || '';
  renderAll();
  if (message) {
    setMessage(elements.homeWatchlistMessage, message, 'success');
  }
}

function resetHomeWatchlistForm() {
  appState.ui.selectedHomeStockId = null;
  appState.ui.editingFeaturedStockId = null;
  elements.homeStockSearchInput.value = '';
  elements.homeSupportPrice.value = '';
  elements.homeComment.value = '';
  setMessage(elements.homeWatchlistMessage, '');
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

async function upsertStockMemo(stock, comment) {
  await apiRequest(appState, `/admin/stocks/${stock.id}`, {
    method: 'PUT',
    body: JSON.stringify({
      code: stock.code,
      name: stock.name,
      market_type: stock.market_type,
      sector: stock.sector || null,
      theme_tags: stock.theme_tags || null,
      operator_memo: comment,
      is_active: stock.is_active,
    }),
  });
}

async function upsertAdminHomeSupportLevel(stockId, comment) {
  const existingLevels = appState.data.priceLevels.filter(
    (item) => item.stock_id === stockId && item.level_type === 'SUPPORT' && item.source_label === HOME_SOURCE_LABEL,
  );
  const targetLevel = existingLevels.find((item) => item.is_active) || existingLevels[0] || null;
  const payload = {
    stock_id: stockId,
    level_type: 'SUPPORT',
    price: elements.homeSupportPrice.value.trim(),
    proximity_threshold_pct: '1.50',
    rebound_threshold_pct: '5.00',
    source_label: HOME_SOURCE_LABEL,
    note: comment,
    is_active: true,
  };
  if (targetLevel) {
    await apiRequest(appState, `/admin/price-levels/${targetLevel.id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  } else {
    await apiRequest(appState, '/admin/price-levels', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  await Promise.all(
    existingLevels
      .filter((item) => item.id !== targetLevel?.id && item.is_active)
      .map((item) =>
        apiRequest(appState, `/admin/price-levels/${item.id}`, {
          method: 'PUT',
          body: JSON.stringify({
            stock_id: item.stock_id,
            level_type: item.level_type,
            price: item.price,
            proximity_threshold_pct: item.proximity_threshold_pct,
            rebound_threshold_pct: item.rebound_threshold_pct,
            source_label: item.source_label,
            note: item.note,
            is_active: false,
          }),
        }),
      ),
  );
}

async function saveHomeWatchlist() {
  const stock = currentHomeStock();
  if (!stock) {
    throw new Error('검색 결과에서 종목을 먼저 선택해주세요.');
  }
  const supportPrice = elements.homeSupportPrice.value.trim();
  if (!supportPrice) {
    throw new Error('지지선 가격을 입력해주세요.');
  }
  const comment = elements.homeComment.value.trim() || null;

  await upsertStockMemo(stock, comment);
  await upsertAdminHomeSupportLevel(stock.id, comment);

  const existingItem = appState.data.homeFeatured.find((item) => item.stock_id === stock.id);
  const activeItems = [...appState.data.homeFeatured]
    .filter((item) => item.is_active && item.stock_id !== stock.id)
    .sort((a, b) => a.display_order - b.display_order)
    .map((item, index) => ({
      stock_id: item.stock_id,
      display_order: index + 1,
      is_active: true,
    }));

  if (existingItem) {
    const insertIndex = Math.max(0, Math.min((existingItem.display_order || 1) - 1, activeItems.length));
    activeItems.splice(insertIndex, 0, {
      stock_id: stock.id,
      display_order: existingItem.display_order || insertIndex + 1,
      is_active: true,
    });
  } else {
    activeItems.push({
      stock_id: stock.id,
      display_order: activeItems.length + 1,
      is_active: true,
    });
  }

  activeItems.forEach((item, index) => {
    item.display_order = index + 1;
  });

  await apiRequest(appState, '/admin/home-featured', {
    method: 'PUT',
    body: JSON.stringify({ items: activeItems }),
  });

  await refreshAll();
  fillHomeWatchlistForm(currentHomeStock());
  setMessage(elements.homeWatchlistMessage, '관심종목을 저장했습니다.', 'success');
}

async function removeHomeWatchlist(stockId) {
  const nextItems = appState.data.homeFeatured
    .filter((item) => item.is_active && item.stock_id !== stockId)
    .sort((a, b) => a.display_order - b.display_order)
    .map((item, index) => ({
      stock_id: item.stock_id,
      display_order: index + 1,
      is_active: true,
    }));

  await apiRequest(appState, '/admin/home-featured', {
    method: 'PUT',
    body: JSON.stringify({ items: nextItems }),
  });

  const supportLevel = getAdminHomeSupportLevel(stockId);
  if (supportLevel) {
    await apiRequest(appState, `/admin/price-levels/${supportLevel.id}`, {
      method: 'PUT',
      body: JSON.stringify({
        stock_id: supportLevel.stock_id,
        level_type: supportLevel.level_type,
        price: supportLevel.price,
        proximity_threshold_pct: supportLevel.proximity_threshold_pct,
        rebound_threshold_pct: supportLevel.rebound_threshold_pct,
        source_label: supportLevel.source_label,
        note: supportLevel.note,
        is_active: false,
      }),
    });
  }

  if (appState.ui.selectedHomeStockId === stockId) {
    resetHomeWatchlistForm();
  }
  await refreshAll();
  setMessage(elements.homeWatchlistMessage, '관심종목에서 제외했습니다.', 'success');
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
    published_at: elements.contentPublishedAt.value || null,
    sort_order: Number(elements.contentSortOrder.value || 0),
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
    elements.homeStockSearchInput,
    elements.levelStockSearchInput,
    elements.themeStockSearchInput,
    elements.contentStockSearchInput,
    elements.contentThemeSearchInput,
  ].forEach((input) => input.addEventListener('input', renderAll));
}

function bindDelegatedClicks() {
  document.body.addEventListener('click', async (event) => {
    const stockItem = event.target.closest('[data-stock-id]');
    if (stockItem && stockItem.classList.contains('selection-item')) {
      const stock = appState.data.stocks.find((item) => item.id === Number(stockItem.dataset.stockId));
      if (stockItem.parentElement === elements.homeStockSearchResults) {
        fillHomeWatchlistForm(stock);
        return;
      }
      if (stockItem.parentElement === elements.levelStockSearchResults) {
        appState.ui.selectedLevelStockId = stock?.id || null;
        renderAll();
        return;
      }
      if (stockItem.parentElement === elements.themeStockSearchResults) {
        if (stock && !appState.ui.themeStockDraft.some((item) => item.stock_id === stock.id)) {
          appState.ui.themeStockDraft.push({ stock_id: stock.id, stock_name: stock.name, role_type: 'FOLLOWER', score: '' });
          renderAll();
        }
        return;
      }
      if (stockItem.parentElement === elements.contentStockSearchResults) {
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
    if (event.target.matches('[data-featured-edit]')) {
      const stock = appState.data.stocks.find((item) => item.id === Number(event.target.dataset.featuredEdit));
      fillHomeWatchlistForm(stock, '수정할 관심종목 정보를 불러왔습니다.');
      return;
    }
    if (event.target.matches('[data-featured-remove]')) {
      await removeHomeWatchlist(Number(event.target.dataset.featuredRemove));
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
  elements.saveHomeWatchlistButton.addEventListener('click', async () => {
    try {
      await saveHomeWatchlist();
    } catch (error) {
      setMessage(elements.homeWatchlistMessage, error.message, 'error');
    }
  });
  elements.resetHomeWatchlistButton.addEventListener('click', resetHomeWatchlistForm);
  elements.savePriceLevelButton.addEventListener('click', async () => {
    try {
      await savePriceLevel();
    } catch (error) {
      setMessage(elements.priceLevelMessage, error.message, 'error');
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
}

async function bootstrap() {
  loadSession();
  wireTabNavigation();
  bindSearchReRendering();
  bindDelegatedClicks();
  bindPrimaryActions();
  renderAll();
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
