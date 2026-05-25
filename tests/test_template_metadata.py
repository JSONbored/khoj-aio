from __future__ import annotations

from xml.etree import ElementTree as ET  # nosec B405

from tests.conftest import REPO_ROOT


def test_ca_metadata_uses_current_categories_and_discovery_fields() -> None:
    root = ET.parse(REPO_ROOT / "khoj-aio.xml").getroot()  # nosec B314

    assert root.findtext("Category") == "AI Productivity Tools:Utilities"  # nosec B101
    assert (
        root.findtext("ReadMe") == "https://github.com/JSONbored/khoj-aio#readme"
    )  # nosec B101
    assert [s.text for s in root.findall("Screenshot")] == [  # nosec B101
        "https://raw.githubusercontent.com/JSONbored/awesome-unraid/main/screenshots/khoj-aio/01-home.png",
        "https://raw.githubusercontent.com/JSONbored/awesome-unraid/main/screenshots/khoj-aio/02-chat.png",
        "https://raw.githubusercontent.com/JSONbored/awesome-unraid/main/screenshots/khoj-aio/03-settings.png",
    ]
