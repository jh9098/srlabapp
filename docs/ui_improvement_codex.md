# UI 개선 Codex 작업명령서
> srlabapp · Flutter MVP · 모바일 UX 개선

---

## 🎯 개선 목표

홈 화면 **"오늘의 관찰 종목"** 섹션이 현재 `StockCard` (기본 레이아웃)를 사용하여
종목 하나당 화면의 약 30–40%를 차지하고 있음.
한 화면에 2–3종목만 표시되는 불편함을 개선하여 **5–7종목이 한 화면에 들어오도록** 가로 압축형 레이아웃으로 교체한다.

표시 필드: **종목명 · 현재가 · 상승률 · 관찰상태(StatusBadge) · 메모(summary 1줄)**
지지선 거리·이탈·반등 상태를 직관적으로 표현하는 컴팩트 배지를 별도 행에 포함한다.

---

## 📁 작업 대상 파일

| 구분 | 경로 | 작업 유형 |
|------|------|-----------|
| 신규 생성 | `lib/features/home/presentation/widgets/featured_stock_tile.dart` | **CREATE** |
| 수정 | `lib/features/home/presentation/home_screen.dart` | **MODIFY** |
| 참고 (수정 없음) | `lib/core/widgets/stock_card.dart` | READ-ONLY |
| 참고 (수정 없음) | `lib/core/widgets/status_badge.dart` | READ-ONLY |
| 참고 (수정 없음) | `lib/core/widgets/support_distance_bar.dart` | READ-ONLY |
| 참고 (수정 없음) | `lib/features/home/data/home_models.dart` | READ-ONLY |

---

## ✅ 체크리스트

### TASK 1 · 신규 파일 생성
`lib/features/home/presentation/widgets/featured_stock_tile.dart`

- [ ] **1-1** 파일 생성 및 imports 구성
  ```dart
  import 'package:flutter/material.dart';
  import '../../../../core/utils/formatters.dart';
  import '../../../../core/widgets/status_badge.dart';
  import '../../../../features/home/data/home_models.dart';
  ```

- [ ] **1-2** `FeaturedStockTile` StatelessWidget 선언
  - 생성자 파라미터: `HomeFeaturedStockModel item`, `VoidCallback? onTap`
  - `const` 생성자 사용

- [ ] **1-3** `build()` 반환: `Card` > `InkWell` > `Padding(horizontal: 12, vertical: 10)`

- [ ] **1-4** 레이아웃: `Column` (children: Row 1 + SizedBox(4) + Row 2(조건부))

---

#### Row 1 — 메인 정보 행

- [ ] **1-5** Row 1 구성 (children 순서대로):

  **(a) 심각도 점(Severity Dot)**
  - 너비/높이 `8×8`, `BoxShape.circle`
  - `item.status.severity` 에 따라 색상:
    - `'positive'` → `Color(0xFF22C55E)` (초록)
    - `'warning'` → `Color(0xFFF59E0B)` (주황)
    - `'watch'` → `Color(0xFF3B82F6)` (파랑)
    - 그 외 → `Color(0xFF94A3B8)` (회색)
  - 오른쪽 `SizedBox(width: 8)`

  **(b) 종목명 + 종목코드**
  - `Expanded(flex: 3)` 로 감싸기
  - `Column(crossAxisAlignment: start)`:
    - 종목명: `titleSmall` + `fontWeight: w700` + `maxLines: 1` + `overflow: ellipsis`
    - 종목코드: `labelSmall` + `color: onSurfaceVariant` + `maxLines: 1`

  **(c) 현재가**
  - `Expanded(flex: 3)` 로 감싸기
  - `Formatters.price(item.currentPrice)` 텍스트
  - `bodySmall` + `fontWeight: w600` + `textAlign: right`

  **(d) 상승률**
  - 고정 너비 `SizedBox(width: 62)`
  - `Formatters.percent(item.changePct)` 텍스트
  - `changePct >= 0` → `Color(0xFFDC2626)` / 음수 → `Color(0xFF2563EB)`
  - `labelMedium` + `fontWeight: w700` + `textAlign: right`
  - 오른쪽 `SizedBox(width: 8)`

  **(e) 관찰상태 배지 (StatusBadge 컴팩트)**
  - `item.status` 의 severity 와 label 을 사용하여 직접 인라인 컨테이너로 렌더링
    (기존 `StatusBadge` 위젯은 padding이 커서 직접 구현)
  - `Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), ...)`
  - `decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6))`
  - `labelSmall` + `fontWeight: w700` + `color: badgeFg`
  - severity별 색상은 `StatusBadge._palette()` 로직 그대로 복사:
    - `'positive'` → bg `0xFFDCFCE7`, fg `0xFF166534`
    - `'warning'` → bg `0xFFFFEDD5`, fg `0xFF9A3412`
    - `'watch'`   → bg `0xFFDBEAFE`, fg `0xFF1D4ED8`
    - default    → bg `0xFFE2E8F0`, fg `0xFF334155`
  - 오른쪽 `SizedBox(width: 4)` + `Icon(Icons.chevron_right_rounded, size: 14, color: grey400)`

---

#### Row 2 — 지지선 상태 행 (조건부)

- [ ] **1-6** `item.supportPrice != null` 인 경우에만 Row 2 렌더링

- [ ] **1-7** Row 2: **지지선 거리 인라인 미니 바** 구성
  - `Padding(left: 16)`으로 왼쪽 들여쓰기
  - `Row(children: [지지라벨, SizedBox(6), 지지가격, SizedBox(8), 진행바(Expanded), SizedBox(8), 상태텍스트])`

  **(a) 지지라벨**
  - `Text('지지', style: labelSmall + color: onSurfaceVariant + fontWeight: w600)`

  **(b) 지지가격**
  - `Text(Formatters.price(item.supportPrice!), style: labelSmall + color: onSurfaceVariant)`

  **(c) 미니 진행바**
  - `_resolveStatus(ratio)` 내부 함수로 상태 계산:
    ```dart
    double ratio = (item.currentPrice - item.supportPrice!) / item.supportPrice!;
    ```
    - `ratio < 0`   → label: `'이탈'`, color: `Colors.red.shade500`
    - `ratio <= 0.03` → label: `'근접'`, color: `Colors.red.shade400`
    - `ratio <= 0.07` → label: `'주의'`, color: `Colors.orange.shade500`
    - `ratio > 0.07`  → label: `'여유'`, color: `Colors.green.shade500`
  - `ClipRRect(borderRadius: circular(999))` > `LinearProgressIndicator(minHeight: 5, value: ratio.clamp(0.0, 1.0), ...)`
  - `valueColor: AlwaysStoppedAnimation(statusColor)`

  **(d) 상태텍스트**
  - `Text('$label ${_distanceLabel(ratio)}')`
    - `_distanceLabel`: `ratio < 0 ? '-${pct.toStringAsFixed(1)}%' : '+${pct.toStringAsFixed(1)}%'`
  - `labelSmall` + `fontWeight: w700` + `color: statusColor`

---

#### Row 3 — 메모 행 (조건부)

- [ ] **1-8** `item.summary.isNotEmpty` 이고 summary가 `'운영자 코멘트가 아직 없습니다.'` 가 **아닌** 경우에만 표시
  - `Padding(top: 4, left: 16)` > `Text(item.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: bodySmall + color: grey600)`

---

### TASK 2 · home_screen.dart 수정

- [ ] **2-1** 파일 상단 import 추가:
  ```dart
  import 'widgets/featured_stock_tile.dart';
  ```

- [ ] **2-2** `featuredStocks` 리스트 빌드 부분 교체
  - **변경 전**: `StockCard(name: item.stockName, code: ..., status: StatusBadge(...), summary: ..., ...)`
  - **변경 후**: `FeaturedStockTile(item: item, onTap: () => Navigator.of(context).push(...))`
  - 기존 `Padding(bottom: 8)` 은 유지
  - `StockCard` 관련 import 가 home_screen 에서 더 이상 사용되지 않으면 제거

- [ ] **2-3** `StatusBadge` import 가 home_screen 에서 더 이상 사용되지 않으면 제거
  (기존 `StockCard`의 `status:` 파라미터에 `StatusBadge(status: item.status)`를 전달하던 코드가 사라지므로)

---

### TASK 3 · 시각적 일관성 확인

- [ ] **3-1** `FeaturedStockTile` 의 배경색은 `Card` 기본 테마를 사용 (별도 색상 지정 없음)

- [ ] **3-2** `Card` 의 `shape`은 `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`
  - 기존 `StockCard` 의 `BorderRadius.circular(16)` 보다 작게 → 더 촘촘한 느낌

- [ ] **3-3** `Card` 의 `margin`을 `EdgeInsets.zero` 로 설정하고, `Padding(bottom: 8)` 로 간격 조절 (기존 방식 유지)

- [ ] **3-4** 다크 모드 대응
  - `severity dot` 의 색상은 라이트/다크 동일한 상수값 사용 (이미 `stock_card.dart` 와 동일 값)
  - `statusBadge` 색상도 라이트/다크 동일하게 고정 (기존 `StatusBadge` 와 동일 방식)

---

### TASK 4 · 상태 표현 강화 (선택적, 권장)

- [ ] **4-1** 상태코드(`status.code`) 별 아이콘 추가 *(선택)*
  - `status.code` 가 아래 값에 해당할 경우 종목명 오른쪽에 아이콘(14px) 표시:
    - `'SUPPORT_BOUNCE'` (지지 반등) → `Icons.trending_up_rounded` + `green`
    - `'SUPPORT_BREAK_BOUNCE'` (이탈 후 반등) → `Icons.restart_alt_rounded` + `orange`
    - `'SUPPORT_NEAR'` (지지 근접) → `Icons.arrow_downward_rounded` + `red`
    - `'SUPPORT_BREAK'` (지지 이탈) → `Icons.warning_amber_rounded` + `red.shade700`
  - 아이콘이 없는 코드는 점(dot)만 표시

- [ ] **4-2** 지지선 이탈 상태(`ratio < 0`)일 때 Row 2 배경을 연한 적색으로 강조 *(선택)*
  - `Container(decoration: BoxDecoration(color: Color(0xFFFEE2E2), borderRadius: circular(6)), padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3), ...)`

---

### TASK 5 · 완료 검증

- [ ] **5-1** 핫 리로드 후 "오늘의 관찰 종목" 섹션에서 각 타일의 높이가 **72px 이하**인지 확인
  - 종목명이 없는 메모(summary default값) 있을 때 Row 3이 숨겨져 타일이 더 작아지는지 확인

- [ ] **5-2** 종목이 8개 이상일 때 한 화면에서 스크롤 없이 최소 **5종목** 이상 보이는지 확인
  (표준 6.1인치 폰 기준 viewport 높이 약 780px, 상단 UI 약 200px 제외 시 약 580px 가용)

- [ ] **5-3** 기존 `StockCard` 는 Watchlist 화면 등 다른 화면에서 계속 사용됨을 확인
  - `home_screen.dart` 외의 파일에서 `StockCard` import를 제거하지 않음

- [ ] **5-4** `item.supportPrice == null` 인 종목에서 Row 2가 렌더링되지 않아 crash 없음 확인

- [ ] **5-5** 종목명이 긴 경우(10자 이상) `maxLines: 1` + `overflow: ellipsis` 로 잘리는지 확인

- [ ] **5-6** 라이트 모드 / 다크 모드 양쪽에서 텍스트 가독성 확인

---

## 🔧 참고: 현재 코드의 문제 원인

```
home_screen.dart (L84–L93)
  StockCard(
    name: item.stockName,       // 행 1: 종목명 + 코드 (별도 2줄)
    code: item.stockCode,       //   ↑
    price: item.currentPrice,   // 행 2: Wrap(가격, 변동률, StatusBadge) → 최소 40px
    changePct: item.changePct,
    status: StatusBadge(...),
    summary: item.summary,      // 행 3: 요약 텍스트 (1–3줄)
    onTap: ...
  )
  // + Card padding all(16) + SizedBox(height: 12) × 2
  // = 카드 1개당 최소 약 130–160px
```

`_DefaultStockCardBody` 는 세로 `Column` 3단 구조로 항상 130px 이상 소비.
`summary`(메모) 가 길면 최대 3줄 × 20px = 60px 추가.

---

## 📐 완성 레이아웃 시안

```
┌────────────────────────────────────────────────────┐
│ ● 삼성전자   005930  │  72,300원  │ +1.23%  │[반등확인]  › │  ← Row 1 (~44px)
│   지지 71,000원  ████░░░░  근접 +1.8%            │  ← Row 2 (~20px)
│   "단기 지지선 테스트 중, 거래량 확인 필요"            │  ← Row 3 (~16px, 조건부)
└────────────────────────────────────────────────────┘
                                        전체 합계 ≈ 80–84px
```

---

*생성일: 2026-03-25 · 대상 SDK: Flutter ^3.11.1 · Dart null-safety 적용*
