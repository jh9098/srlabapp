import { STATUS_LABELS, badgeClass, escapeHtml, formatDate } from './utils.js';

export function renderStats(element, sessionData, dashboard) {
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
  element.innerHTML = stats
    .map(
      ([label, value]) =>
        `<div class="stat-card"><span class="stat-label">${escapeHtml(label)}</span><span class="stat-value">${escapeHtml(value)}</span></div>`,
    )
    .join('');
}

export function renderStockSearchResults(element, stocks, selectedStockId) {
  if (!stocks.length) {
    element.innerHTML = '<div class="empty-inline">검색 결과가 없습니다.</div>';
    return;
  }
  element.innerHTML = stocks
    .map(
      (stock) => `
        <button class="selection-item ${stock.id === selectedStockId ? 'selected' : ''}" data-stock-id="${stock.id}">
          <strong>${escapeHtml(stock.name)}</strong>
          <span>${escapeHtml(stock.code)} · ${escapeHtml(stock.market_type)}</span>
        </button>`,
    )
    .join('');
}

export function renderStockSummary(element, stock, featuredStockIds = []) {
  if (!stock) {
    element.innerHTML = '종목을 선택하면 상세 정보가 표시됩니다.';
    element.classList.add('empty-inline');
    return;
  }
  element.classList.remove('empty-inline');
  const isFeatured = featuredStockIds.includes(stock.id);
  element.innerHTML = `
    <div class="summary-grid">
      <div><strong>${escapeHtml(stock.name)}</strong><p>${escapeHtml(stock.code)} · ${escapeHtml(stock.market_type)}</p></div>
      <div><span class="pill ${stock.is_active ? 'active' : 'inactive'}">${stock.is_active ? '운영 활성' : '비활성'}</span></div>
      <div><strong>섹터</strong><p>${escapeHtml(stock.sector || '-')}</p></div>
      <div><strong>홈 추천</strong><p>${isFeatured ? '포함됨' : '미포함'}</p></div>
      <div class="full"><strong>운영 메모</strong><p>${escapeHtml(stock.operator_memo || '-')}</p></div>
    </div>`;
}

export function renderPriceLevels(element, items, type) {
  const filtered = items.filter((item) => item.level_type === type);
  if (!filtered.length) {
    element.innerHTML = '<div class="empty-inline">등록된 레벨이 없습니다.</div>';
    return;
  }
  element.innerHTML = filtered
    .map(
      (item) => `
      <div class="list-card">
        <div>
          <div class="section-title-row compact">
            <strong>${escapeHtml(item.price)}</strong>
            <span class="source-badge ${badgeClass(item.source_label)}">${escapeHtml(item.source_label || 'operator')}</span>
          </div>
          <p class="muted small">${escapeHtml(item.note || '메모 없음')}</p>
        </div>
        <div class="button-row compact">
          <span class="pill ${item.is_active ? 'active' : 'inactive'}">${item.is_active ? '활성' : '비활성'}</span>
          <button class="ghost-button small" data-level-toggle-id="${item.id}" data-next-active="${item.is_active ? 'false' : 'true'}">${item.is_active ? '비활성화' : '재활성화'}</button>
        </div>
      </div>`,
    )
    .join('');
}

export function renderSupportStatesTable(element, items) {
  if (!items.length) {
    element.innerHTML = '<div class="empty-inline">조건에 맞는 지지선 상태가 없습니다.</div>';
    return;
  }
  element.innerHTML = `
    <table>
      <thead>
        <tr>
          <th>종목명</th>
          <th>종목코드</th>
          <th>지지선 가격</th>
          <th>현재 상태</th>
          <th>최근 업데이트</th>
          <th>사유</th>
          <th>액션</th>
        </tr>
      </thead>
      <tbody>
        ${items
          .map(
            (item) => `
          <tr>
            <td>${escapeHtml(item.stock_name || '-')}</td>
            <td>${escapeHtml(item.stock_code || '-')}</td>
            <td>${escapeHtml(item.level_price || '-')}</td>
            <td><span class="pill state">${escapeHtml(STATUS_LABELS[item.status] || item.status)}</span></td>
            <td>${escapeHtml(formatDate(item.updated_at))}</td>
            <td>${escapeHtml(item.status_reason || '-')}</td>
            <td><button class="small" data-force-state-id="${item.id}">강제 수정</button></td>
          </tr>`,
          )
          .join('')}
      </tbody>
    </table>`;
}

export function renderFeaturedItems(element, items) {
  if (!items.length) {
    element.innerHTML = '<div class="empty-inline">홈 추천 종목을 검색으로 추가해주세요.</div>';
    return;
  }
  element.innerHTML = items
    .map(
      (item, index) => `
      <div class="list-card">
        <div>
          <strong>${escapeHtml(item.stock_name)}</strong>
          <p>${escapeHtml(item.stock_code)} · 정렬 ${index + 1}</p>
        </div>
        <div class="button-row compact">
          <button class="ghost-button small" data-featured-move="up" data-stock-id="${item.stock_id}" ${index === 0 ? 'disabled' : ''}>위로</button>
          <button class="ghost-button small" data-featured-move="down" data-stock-id="${item.stock_id}" ${index === items.length - 1 ? 'disabled' : ''}>아래로</button>
          <button class="ghost-button small" data-featured-toggle="${item.stock_id}">${item.is_active ? '비활성화' : '활성화'}</button>
          <button class="ghost-button small" data-featured-remove="${item.stock_id}">제거</button>
        </div>
      </div>`,
    )
    .join('');
}

export function renderThemeOptions(element, themes, selectedId) {
  element.innerHTML = ['<option value="">신규 테마 작성</option>']
    .concat(
      themes.map(
        (theme) => `<option value="${theme.id}" ${theme.id === selectedId ? 'selected' : ''}>${escapeHtml(theme.name)}</option>`,
      ),
    )
    .join('');
}

export function renderThemeStockList(element, items) {
  if (!items.length) {
    element.innerHTML = '<div class="empty-inline">연결 종목을 검색으로 추가해주세요.</div>';
    return;
  }
  element.innerHTML = items
    .map(
      (item) => `
      <div class="list-card vertical-gap">
        <div class="section-title-row compact">
          <strong>${escapeHtml(item.stock_name)}</strong>
          <button class="ghost-button small" data-theme-stock-remove="${item.stock_id}">제거</button>
        </div>
        <div class="inline-form">
          <label><span>역할</span><select data-theme-stock-role="${item.stock_id}"><option value="LEADER" ${item.role_type === 'LEADER' ? 'selected' : ''}>LEADER</option><option value="FOLLOWER" ${item.role_type === 'FOLLOWER' ? 'selected' : ''}>FOLLOWER</option></select></label>
          <label><span>점수</span><input data-theme-stock-score="${item.stock_id}" value="${escapeHtml(item.score ?? '')}" /></label>
        </div>
      </div>`,
    )
    .join('');
}

export function renderContentOptions(element, contents, selectedId) {
  element.innerHTML = ['<option value="">신규 콘텐츠 작성</option>']
    .concat(
      contents.map(
        (content) => `<option value="${content.id}" ${content.id === selectedId ? 'selected' : ''}>${escapeHtml(content.title)}</option>`,
      ),
    )
    .join('');
}

export function renderThemeSearchResults(element, themes) {
  if (!themes.length) {
    element.innerHTML = '<div class="empty-inline">검색 결과가 없습니다.</div>';
    return;
  }
  element.innerHTML = themes
    .map(
      (theme) => `<button class="selection-item" data-theme-id="${theme.id}"><strong>${escapeHtml(theme.name)}</strong><span>${escapeHtml(theme.summary || '요약 없음')}</span></button>`,
    )
    .join('');
}

export function renderSelectionSummary(element, text) {
  element.classList.toggle('empty-inline', !text);
  element.textContent = text || '선택된 항목 없음';
}
