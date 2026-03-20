from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory


def build_script_directory(backend_root: Path) -> ScriptDirectory:
    config = Config(str(backend_root / "alembic.ini"))
    config.set_main_option("script_location", str(backend_root / "alembic"))
    return ScriptDirectory.from_config(config)


def check_env_files(backend_root: Path) -> None:
    env_example = backend_root / ".env.example"
    env_file = backend_root / ".env"
    if not env_example.exists():
        raise SystemExit("[FAIL] backend_api/.env.example 파일이 없습니다.")
    print("[OK] backend_api/.env.example 파일이 있습니다.")
    if env_file.exists():
        print("[WARN] backend_api/.env 는 로컬 전용 파일입니다. 공유 산출물에는 포함하지 마세요.")
    else:
        print("[OK] backend_api/.env 가 저장소 산출물에 포함되지 않았습니다.")


def check_alembic(backend_root: Path) -> None:
    script = build_script_directory(backend_root)
    revisions = list(script.walk_revisions(base="base", head="heads"))
    revision_ids = [revision.revision for revision in revisions]
    if len(revision_ids) != len(set(revision_ids)):
        raise SystemExit("[FAIL] Alembic revision id 중복이 있습니다.")

    heads = script.get_heads()
    if len(heads) != 1:
        raise SystemExit(f"[FAIL] Alembic head 개수가 1개가 아닙니다: {heads}")

    revision_map = {revision.revision: revision for revision in revisions}
    for revision in revisions:
        for down_revision in revision._normalized_down_revisions:
            if down_revision not in revision_map:
                raise SystemExit(f"[FAIL] Alembic chain 이 끊겼습니다: {revision.revision} -> {down_revision}")

    print(f"[OK] Alembic head 1개 확인: {heads[0]}")


def run_pytest(backend_root: Path) -> None:
    command = [sys.executable, "-m", "pytest", "-q"]
    print(f"[RUN] {' '.join(command)}")
    completed = subprocess.run(command, cwd=backend_root)
    if completed.returncode != 0:
        raise SystemExit(completed.returncode)
    print("[OK] pytest -q 통과")


def print_health_check_hint() -> None:
    print("[INFO] backend 실행 후 health 점검 예시: curl http://127.0.0.1:8000/health")
    print("[INFO] backend 실행 후 API health 점검 예시: curl http://127.0.0.1:8000/api/v1/health")


def main() -> None:
    backend_root = Path(__file__).resolve().parents[1]
    check_env_files(backend_root)
    check_alembic(backend_root)
    run_pytest(backend_root)
    print_health_check_hint()


if __name__ == "__main__":
    main()
