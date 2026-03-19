from dataclasses import dataclass


@dataclass(slots=True)
class AppError(Exception):
    message: str
    error_code: str
    status_code: int
