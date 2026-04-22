from __future__ import annotations

import time
import uuid
from contextlib import contextmanager
from pathlib import Path
from tempfile import TemporaryDirectory

import pytest

from tests.helpers import docker_available, reserve_host_port, run_command

IMAGE_TAG = "khoj-aio:pytest"
pytestmark = pytest.mark.integration


def logs(name: str) -> str:
    result = run_command(["docker", "logs", name], check=False)
    return result.stdout + result.stderr


def wait_for_http(name: str, host_port: int, timeout: int = 600) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        status = run_command(
            ["docker", "inspect", "-f", "{{.State.Status}}", name],
            check=False,
        ).stdout.strip()
        if status != "running":
            raise AssertionError(f"{name} stopped before becoming ready.\n{logs(name)}")

        if (
            run_command(
                ["curl", "-fsS", f"http://127.0.0.1:{host_port}/"], check=False
            ).returncode
            == 0
        ):
            return
        time.sleep(2)

    raise AssertionError(f"{name} did not become ready.\n{logs(name)}")


@contextmanager
def container(config_dir: Path, pgdata_dir: Path):
    name = f"khoj-aio-pytest-{uuid.uuid4().hex[:10]}"
    host_port = reserve_host_port()
    command = [
        "docker",
        "run",
        "-d",
        "--platform",
        "linux/amd64",
        "--name",
        name,
        "-p",
        f"{host_port}:42110",
        "-v",
        f"{config_dir}:/root/.khoj",
        "-v",
        f"{pgdata_dir}:/var/lib/postgresql/data",
        IMAGE_TAG,
    ]
    run_command(command)
    try:
        yield name, host_port
    finally:
        run_command(["docker", "rm", "-f", name], check=False)


@pytest.fixture(scope="session", autouse=True)
def build_image() -> None:
    if not docker_available():
        pytest.skip("Docker is unavailable; integration tests require Docker/OrbStack.")
    run_command(["docker", "build", "--platform", "linux/amd64", "-t", IMAGE_TAG, "."])


def test_happy_path_boot_and_restart() -> None:
    with (
        TemporaryDirectory(prefix="khoj-aio-config-") as config_dir,
        TemporaryDirectory(prefix="khoj-aio-pg-") as pgdata_dir,
    ):
        with container(Path(config_dir), Path(pgdata_dir)) as (name, host_port):
            wait_for_http(name, host_port)
            assert Path(config_dir, "aio", "generated.env").is_file()  # nosec B101
            assert Path(pgdata_dir, "PG_VERSION").is_file()  # nosec B101
            run_command(
                [
                    "docker",
                    "exec",
                    name,
                    "sh",
                    "-lc",
                    "pg_isready -h 127.0.0.1 -p 5432 -U khoj",
                ]
            )
            first_logs = logs(name)
            assert "Starting Khoj on" in first_logs  # nosec B101

            run_command(["docker", "restart", name])
            wait_for_http(name, host_port)
            assert (
                Path(config_dir, "aio", "generated.env").stat().st_size > 0
            )  # nosec B101
