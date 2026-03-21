export const STATUS_LABELS = {
  WAITING: '대기',
  TESTING_SUPPORT: '지지 확인중',
  DIRECT_REBOUND_SUCCESS: '직접 반등 성공',
  BREAK_REBOUND_SUCCESS: '이탈 후 복원 성공',
  REUSABLE: '재사용 가능',
  INVALID: '무효',
};

export function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

export function byText(items, query, fields) {
  const normalized = query.trim().toLowerCase();
  if (!normalized) {
    return items;
  }
  return items.filter((item) =>
    fields.some((field) => String(item[field] ?? '').toLowerCase().includes(normalized)),
  );
}

export function setMessage(element, message, type = 'info') {
  element.textContent = message || '';
  element.dataset.type = type;
}

export function badgeClass(sourceLabel) {
  return String(sourceLabel || '').toLowerCase().includes('firebase') ? 'firebase' : 'operator';
}

export function numberOrNull(value) {
  const normalized = String(value ?? '').trim();
  return normalized ? Number(normalized) : null;
}

export function formatDate(value) {
  if (!value) {
    return '-';
  }
  try {
    return new Date(value).toLocaleString('ko-KR');
  } catch {
    return value;
  }
}
