"""容器健康检查（用于 Dockerfile HEALTHCHECK）。"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request


def main() -> int:
    port = os.getenv("PORT", "8000")
    url = f"http://127.0.0.1:{port}/health"

    try:
        with urllib.request.urlopen(url, timeout=2) as resp:  # noqa: S310
            if resp.status != 200:
                return 1
            payload = json.loads(resp.read().decode("utf-8"))
            return 0 if payload.get("status") == "ok" else 1
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        return 1


if __name__ == "__main__":
    sys.exit(main())
