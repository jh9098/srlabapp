from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory


def _get_script_directory() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parents[1]
    config = Config(str(backend_root / "alembic.ini"))
    config.set_main_option("script_location", str(backend_root / "alembic"))
    return ScriptDirectory.from_config(config)


def test_alembic_revisions_are_unique_and_single_head() -> None:
    script = _get_script_directory()
    revisions = list(script.walk_revisions(base="base", head="heads"))
    revision_ids = [revision.revision for revision in revisions]

    assert revision_ids
    assert len(revision_ids) == len(set(revision_ids))

    heads = script.get_heads()
    assert len(heads) == 1


def test_alembic_down_revision_chain_is_not_broken() -> None:
    script = _get_script_directory()
    revisions = list(script.walk_revisions(base="base", head="heads"))
    revision_map = {revision.revision: revision for revision in revisions}

    for revision in revisions:
        down_revisions = revision._normalized_down_revisions
        for down_revision in down_revisions:
            assert down_revision in revision_map
