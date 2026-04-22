from __future__ import annotations

import time
import uuid
from contextlib import contextmanager

import pytest

from tests.helpers import (
    container_file_size,
    container_path_exists,
    docker_available,
    docker_volume,
    ensure_pytest_image,
    reserve_host_port,
    run_command,
)

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
def container(config_volume: str, pgdata_volume: str):
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
        f"{config_volume}:/root/.khoj",
        "-v",
        f"{pgdata_volume}:/var/lib/postgresql/data",
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
    ensure_pytest_image(IMAGE_TAG)


def test_happy_path_boot_and_restart() -> None:
    with (
        docker_volume("khoj-aio-config") as config_volume,
        docker_volume("khoj-aio-pg") as pgdata_volume,
    ):
        with container(config_volume, pgdata_volume) as (name, host_port):
            wait_for_http(name, host_port)
            assert container_path_exists(
                name, "/root/.khoj/aio/generated.env"
            )  # nosec B101
            assert container_path_exists(
                name, "/var/lib/postgresql/data/PG_VERSION"
            )  # nosec B101
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
                container_file_size(name, "/root/.khoj/aio/generated.env") > 0
            )  # nosec B101
