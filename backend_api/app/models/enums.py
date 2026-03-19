from enum import Enum


class MarketType(str, Enum):
    KOSPI = "KOSPI"
    KOSDAQ = "KOSDAQ"
    ETF = "ETF"
    ETN = "ETN"
    OTHER = "OTHER"


class PriceLevelType(str, Enum):
    SUPPORT = "SUPPORT"
    RESISTANCE = "RESISTANCE"


class SupportStatus(str, Enum):
    WAITING = "WAITING"
    TESTING_SUPPORT = "TESTING_SUPPORT"
    DIRECT_REBOUND_SUCCESS = "DIRECT_REBOUND_SUCCESS"
    BREAK_REBOUND_SUCCESS = "BREAK_REBOUND_SUCCESS"
    REUSABLE = "REUSABLE"
    INVALID = "INVALID"
