from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP

from app.models.daily_bar import DailyBar
from app.models.enums import SignalType, SupportStatus
from app.models.price_level import PriceLevel
from app.models.support_state import SupportState

PCT_QUANT = Decimal("0.01")
HUNDRED = Decimal("100")


@dataclass(slots=True)
class SupportStateEngineConfig:
    support_near_pct: Decimal = Decimal("1.50")
    rebound_success_pct: Decimal = Decimal("5.00")
    support_retouch_pct: Decimal = Decimal("0.50")
    support_break_basis: str = "CLOSE_BREAK"
    reuse_high_basis: str = "PREVIOUS_MAJOR_HIGH"
    invalidation_basis: str = "REBOUND_LOW_BREAK"
    max_testing_days: int = 20


@dataclass(slots=True)
class SupportStateEvaluationResult:
    previous_status: SupportStatus
    current_status: SupportStatus
    status_changed: bool
    reason: str
    signal_type: SignalType | None


class SupportStateEngine:
    def __init__(self, config: SupportStateEngineConfig | None = None) -> None:
        self.config = config or SupportStateEngineConfig()

    def evaluate(
        self,
        support_state: SupportState,
        price_level: PriceLevel,
        latest_bar: DailyBar,
        previous_major_high: Decimal | None,
    ) -> SupportStateEvaluationResult:
        previous_status = support_state.status
        support_price = Decimal(price_level.price)
        config = self._effective_config(price_level)

        support_state.last_price = latest_bar.close_price
        support_state.last_evaluated_at = self._bar_time(latest_bar)
        support_state.previous_major_high = previous_major_high

        if previous_status == SupportStatus.WAITING:
            if self._is_support_near(latest_bar, support_price, config.support_near_pct):
                self._mark_testing_touch(support_state, latest_bar)
                support_state.status = SupportStatus.TESTING_SUPPORT
                support_state.reference_price = support_state.testing_low_price or latest_bar.low_price
                support_state.status_reason = "지지선 근처 진입으로 반응 확인을 시작했습니다."
                return self._result(previous_status, support_state, SignalType.SUPPORT_NEAR)
            support_state.status_reason = "아직 지지선 테스트 전입니다."
            return self._result(previous_status, support_state, None)

        if previous_status == SupportStatus.TESTING_SUPPORT:
            self._mark_testing_touch(support_state, latest_bar)
            if self._is_support_broken(latest_bar, support_price, config.support_break_basis):
                self._mark_breakdown(support_state, latest_bar)
            if self._is_direct_rebound_success(support_state, config.rebound_success_pct):
                support_state.status = SupportStatus.DIRECT_REBOUND_SUCCESS
                support_state.reaction_confirmed_at = self._bar_time(latest_bar)
                support_state.status_reason = "지지선 직접 반등이 기준 상승폭을 충족했습니다."
                return self._result(previous_status, support_state, SignalType.SUPPORT_DIRECT_REBOUND_SUCCESS)
            if self._is_break_rebound_success(support_state, support_price, config.support_retouch_pct):
                support_state.status = SupportStatus.BREAK_REBOUND_SUCCESS
                support_state.reaction_confirmed_at = self._bar_time(latest_bar)
                support_state.status_reason = "지지선 이탈 후 가격대 회복에 성공했습니다."
                return self._result(previous_status, support_state, SignalType.SUPPORT_BREAK_REBOUND_SUCCESS)
            support_state.status_reason = "지지선 반응 확인 중입니다."
            return self._result(previous_status, support_state, None)

        if previous_status in {SupportStatus.DIRECT_REBOUND_SUCCESS, SupportStatus.BREAK_REBOUND_SUCCESS}:
            self._update_post_success_prices(support_state, latest_bar)
            if self._is_reusable(support_state, latest_bar.high_price):
                support_state.status = SupportStatus.REUSABLE
                support_state.reusable_confirmed_at = self._bar_time(latest_bar)
                support_state.status_reason = "직전 주요 고점 돌파로 지지선을 재활용할 수 있습니다."
                return self._result(previous_status, support_state, SignalType.SUPPORT_REUSABLE)
            if self._is_invalid(support_state, latest_bar):
                support_state.status = SupportStatus.INVALID
                support_state.invalidated_at = self._bar_time(latest_bar)
                support_state.status_reason = "반등 이후 구조가 무너져 지지선이 무효화되었습니다."
                support_state.invalid_reason = config.invalidation_basis
                return self._result(previous_status, support_state, SignalType.SUPPORT_INVALIDATED)
            support_state.status_reason = "반등 이후 상단 구조 완성을 추적 중입니다."
            return self._result(previous_status, support_state, None)

        support_state.status_reason = support_state.status_reason or "상태 유지"
        return self._result(previous_status, support_state, None)

    def _effective_config(self, price_level: PriceLevel) -> SupportStateEngineConfig:
        return SupportStateEngineConfig(
            support_near_pct=Decimal(price_level.proximity_threshold_pct),
            rebound_success_pct=Decimal(price_level.rebound_threshold_pct),
            support_retouch_pct=self.config.support_retouch_pct,
            support_break_basis=self.config.support_break_basis,
            reuse_high_basis=self.config.reuse_high_basis,
            invalidation_basis=self.config.invalidation_basis,
            max_testing_days=self.config.max_testing_days,
        )

    def _bar_time(self, bar: DailyBar) -> datetime:
        return bar.updated_at

    def _mark_testing_touch(self, support_state: SupportState, latest_bar: DailyBar) -> None:
        touch_time = self._bar_time(latest_bar)
        support_state.first_touched_at = support_state.first_touched_at or touch_time
        support_state.last_touched_at = touch_time
        low = latest_bar.low_price
        high = latest_bar.high_price
        support_state.testing_low_price = self._min_decimal(support_state.testing_low_price, low)
        support_state.testing_high_price = self._max_decimal(support_state.testing_high_price, high)
        support_state.rebound_high_price = self._max_decimal(support_state.rebound_high_price, high)
        reference = support_state.testing_low_price or low
        support_state.reference_price = reference
        support_state.rebound_pct = self._calculate_pct_change(reference, support_state.rebound_high_price)

    def _mark_breakdown(self, support_state: SupportState, latest_bar: DailyBar) -> None:
        support_state.breakdown_occurred = True
        support_state.breakdown_at = support_state.breakdown_at or self._bar_time(latest_bar)
        support_state.breakdown_low_price = self._min_decimal(support_state.breakdown_low_price, latest_bar.low_price)

    def _update_post_success_prices(self, support_state: SupportState, latest_bar: DailyBar) -> None:
        support_state.testing_high_price = self._max_decimal(support_state.testing_high_price, latest_bar.high_price)
        support_state.rebound_high_price = self._max_decimal(support_state.rebound_high_price, latest_bar.high_price)
        if support_state.reference_price:
            support_state.rebound_pct = self._calculate_pct_change(
                support_state.reference_price,
                support_state.rebound_high_price,
            )

    def _is_support_near(self, latest_bar: DailyBar, support_price: Decimal, support_near_pct: Decimal) -> bool:
        low_distance = self._abs_pct_distance(latest_bar.low_price, support_price)
        close_distance = self._abs_pct_distance(latest_bar.close_price, support_price)
        return low_distance <= support_near_pct or close_distance <= support_near_pct

    def _is_support_broken(self, latest_bar: DailyBar, support_price: Decimal, break_basis: str) -> bool:
        if break_basis == "LOW_BREAK":
            return latest_bar.low_price < support_price
        return latest_bar.close_price < support_price

    def _is_direct_rebound_success(self, support_state: SupportState, rebound_success_pct: Decimal) -> bool:
        if support_state.breakdown_occurred:
            return False
        if support_state.reference_price is None or support_state.rebound_high_price is None:
            return False
        pct = self._calculate_pct_change(support_state.reference_price, support_state.rebound_high_price)
        support_state.rebound_pct = pct
        return pct is not None and pct >= rebound_success_pct

    def _is_break_rebound_success(
        self,
        support_state: SupportState,
        support_price: Decimal,
        support_retouch_pct: Decimal,
    ) -> bool:
        if not support_state.breakdown_occurred or support_state.rebound_high_price is None:
            return False
        if support_state.rebound_high_price >= support_price:
            return True
        return self._abs_pct_distance(support_state.rebound_high_price, support_price) <= support_retouch_pct

    def _is_reusable(self, support_state: SupportState, current_high: Decimal) -> bool:
        if support_state.previous_major_high is None:
            return False
        return current_high > support_state.previous_major_high

    def _is_invalid(self, support_state: SupportState, latest_bar: DailyBar) -> bool:
        if support_state.previous_major_high and latest_bar.high_price > support_state.previous_major_high:
            return False
        reference_low = support_state.testing_low_price or support_state.reference_price
        if reference_low is None:
            return False
        return latest_bar.close_price < reference_low

    def _calculate_pct_change(self, base: Decimal | None, value: Decimal | None) -> Decimal | None:
        if base in (None, Decimal("0")) or value is None:
            return None
        pct = ((value - base) / base) * HUNDRED
        return pct.quantize(PCT_QUANT, rounding=ROUND_HALF_UP)

    def _abs_pct_distance(self, current: Decimal, reference: Decimal) -> Decimal:
        pct = ((current - reference) / reference) * HUNDRED
        return pct.copy_abs().quantize(PCT_QUANT, rounding=ROUND_HALF_UP)

    def _min_decimal(self, left: Decimal | None, right: Decimal | None) -> Decimal | None:
        if left is None:
            return right
        if right is None:
            return left
        return min(left, right)

    def _max_decimal(self, left: Decimal | None, right: Decimal | None) -> Decimal | None:
        if left is None:
            return right
        if right is None:
            return left
        return max(left, right)

    def _result(
        self,
        previous_status: SupportStatus,
        support_state: SupportState,
        signal_type: SignalType | None,
    ) -> SupportStateEvaluationResult:
        return SupportStateEvaluationResult(
            previous_status=previous_status,
            current_status=support_state.status,
            status_changed=previous_status != support_state.status,
            reason=support_state.status_reason or "",
            signal_type=signal_type,
        )
