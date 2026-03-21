export async function apiRequest(appState, path, options = {}) {
  const response = await fetch(`${appState.apiBaseUrl}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(appState.token ? { Authorization: `Bearer ${appState.token}` } : {}),
      ...(options.headers || {}),
    },
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload.message || '요청에 실패했습니다.');
  }
  return payload;
}

export async function loginRequest(apiBaseUrl, username, password) {
  const response = await fetch(`${apiBaseUrl}/admin/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload.message || '로그인에 실패했습니다.');
  }
  return payload;
}
