from __future__ import annotations

import argparse
import json
import random
import statistics
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib import error, request


DEFAULT_USERS = [
    {"role": "admin", "email": "admin@admin.com", "password": "admin123"},
    {"role": "visualizador", "email": "visualizador@test.com", "password": "vis123"},
    {"role": "carga", "email": "carga@test.com", "password": "carga123"},
]


@dataclass
class RequestMetric:
    endpoint: str
    method: str
    role: str
    status: int
    elapsed_ms: float
    ok: bool
    error: str = ""


def percentile(values: list[float], p: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    if len(ordered) == 1:
        return ordered[0]
    idx = (len(ordered) - 1) * p
    lower = int(idx)
    upper = min(lower + 1, len(ordered) - 1)
    weight = idx - lower
    return ordered[lower] * (1 - weight) + ordered[upper] * weight


def http_call(method: str, url: str, *, token: str | None = None, payload: dict[str, Any] | None = None, timeout: int = 20) -> tuple[int, bytes]:
    data = None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
    req = request.Request(url, data=data, headers=headers, method=method)
    try:
        with request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read()
    except error.HTTPError as exc:
        return exc.code, exc.read()


def timed_call(method: str, url: str, *, role: str, token: str | None = None, payload: dict[str, Any] | None = None) -> RequestMetric:
    started = time.perf_counter()
    status = 0
    body = b""
    err_text = ""
    try:
        status, body = http_call(method, url, token=token, payload=payload)
        ok = 200 <= status < 400
        if not ok:
            err_text = body.decode("utf-8", errors="ignore")[:300]
    except Exception as exc:  # pragma: no cover - defensive
        ok = False
        err_text = str(exc)
    elapsed_ms = (time.perf_counter() - started) * 1000
    return RequestMetric(
        endpoint=url,
        method=method,
        role=role,
        status=status,
        elapsed_ms=elapsed_ms,
        ok=ok,
        error=err_text,
    )


def login(base_url: str, role: str, email: str, password: str) -> tuple[str | None, dict[str, Any] | None, list[RequestMetric]]:
    started = time.perf_counter()
    status, body = http_call(
        "POST",
        f"{base_url}/api/auth/login/",
        payload={"email": email, "password": password},
    )
    elapsed_ms = (time.perf_counter() - started) * 1000
    ok = 200 <= status < 400
    metric = RequestMetric(
        endpoint=f"{base_url}/api/auth/login/",
        method="POST",
        role=role,
        status=status,
        elapsed_ms=elapsed_ms,
        ok=ok,
        error="" if ok else body.decode("utf-8", errors="ignore")[:300],
    )
    if not ok:
        return None, None, [metric]
    data = json.loads(body.decode("utf-8"))
    return data.get("token"), data.get("user"), [metric]


def scenario_for_user(base_url: str, virtual_user_id: int, iterations: int) -> list[RequestMetric]:
    user_data = DEFAULT_USERS[virtual_user_id % len(DEFAULT_USERS)]
    return scenario_for_credential(base_url, user_data, iterations)


def scenario_for_credential(base_url: str, user_data: dict[str, str], iterations: int) -> list[RequestMetric]:
    role = str(user_data["role"])
    token, user, metrics = login(base_url, role, str(user_data["email"]), str(user_data["password"]))
    if not token or not user:
        return metrics

    user_id = user.get("id")
    common_endpoints = [
        "/api/auth/me/",
    ]
    role_endpoints = {
        "admin": [
            "/api/dashboard/analitico/",
            "/api/dashboard/proyectos/",
            "/api/proyectos/",
            "/api/tareas/",
            "/api/avances/por-area/",
            "/api/avances/por-secretaria/",
        ],
        "visualizador": [
            "/api/dashboard/analitico/",
            "/api/dashboard/proyectos/",
            "/api/proyectos/",
            "/api/tareas/",
            "/api/avances/por-area/",
            "/api/avances/por-secretaria/",
        ],
        "carga": [
            f"/api/dashboard/usuarios/{user_id}/proyectos/",
            "/api/proyectos/",
            "/api/tareas/",
        ],
    }
    endpoints = common_endpoints + role_endpoints.get(role, common_endpoints)

    for _ in range(iterations):
        for endpoint in endpoints:
            metrics.append(
                timed_call("GET", f"{base_url}{endpoint}", role=role, token=token)
            )
    return metrics


def summarize(metrics: list[RequestMetric]) -> dict[str, Any]:
    latencies = [m.elapsed_ms for m in metrics]
    ok_count = sum(1 for m in metrics if m.ok)
    grouped: dict[str, list[RequestMetric]] = {}
    for metric in metrics:
        key = metric.endpoint.split("/api/")[-1]
        grouped.setdefault(key, []).append(metric)

    by_endpoint = {}
    for key, items in grouped.items():
        item_lat = [m.elapsed_ms for m in items]
        by_endpoint[key] = {
            "requests": len(items),
            "ok": sum(1 for m in items if m.ok),
            "errors": sum(1 for m in items if not m.ok),
            "avg_ms": round(statistics.mean(item_lat), 2) if item_lat else 0,
            "p95_ms": round(percentile(item_lat, 0.95), 2) if item_lat else 0,
            "max_ms": round(max(item_lat), 2) if item_lat else 0,
        }

    errors = [
        {
            "endpoint": m.endpoint,
            "role": m.role,
            "status": m.status,
            "error": m.error,
        }
        for m in metrics if not m.ok
    ][:20]

    return {
        "requests_total": len(metrics),
        "requests_ok": ok_count,
        "requests_error": len(metrics) - ok_count,
        "success_rate_pct": round((ok_count / len(metrics)) * 100, 2) if metrics else 0,
        "avg_ms": round(statistics.mean(latencies), 2) if latencies else 0,
        "p50_ms": round(percentile(latencies, 0.50), 2) if latencies else 0,
        "p95_ms": round(percentile(latencies, 0.95), 2) if latencies else 0,
        "p99_ms": round(percentile(latencies, 0.99), 2) if latencies else 0,
        "max_ms": round(max(latencies), 2) if latencies else 0,
        "by_endpoint": by_endpoint,
        "sample_errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Prueba de concurrencia basica para SIPRA")
    parser.add_argument("--base-url", default="http://localhost:8001")
    parser.add_argument("--users", type=int, default=18, help="Usuarios virtuales concurrentes")
    parser.add_argument("--iterations", type=int, default=2, help="Vueltas de endpoints por usuario")
    parser.add_argument("--workers", type=int, default=18, help="Hilos concurrentes")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--email", default="", help="Email para usar el mismo usuario en todos los hilos")
    parser.add_argument("--password", default="", help="Contraseña para usar el mismo usuario en todos los hilos")
    parser.add_argument("--role-label", default="custom", help="Etiqueta del rol al usar --email/--password")
    args = parser.parse_args()

    random.seed(args.seed)
    started = time.perf_counter()
    all_metrics: list[RequestMetric] = []
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = [
            executor.submit(
                scenario_for_credential if args.email and args.password else scenario_for_user,
                args.base_url,
                {"role": args.role_label, "email": args.email, "password": args.password} if args.email and args.password else i,
                args.iterations,
            )
            for i in range(args.users)
        ]
        for future in as_completed(futures):
            all_metrics.extend(future.result())

    elapsed_s = round(time.perf_counter() - started, 2)
    summary = summarize(all_metrics)
    summary["config"] = {
        "base_url": args.base_url,
        "virtual_users": args.users,
        "iterations": args.iterations,
        "workers": args.workers,
        "elapsed_s": elapsed_s,
    }

    out_dir = Path(__file__).resolve().parent
    out_file = out_dir / f"resultado_concurrencia_{int(time.time())}.json"
    out_file.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")

    print(json.dumps(summary, indent=2, ensure_ascii=False))
    print(f"\nResultado guardado en: {out_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
