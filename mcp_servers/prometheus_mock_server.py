"""Local Prometheus-compatible mock server for demos.

The app queries GET /api/v1/alerts. This lightweight server provides that
endpoint so local development does not fail when a real Prometheus instance is
not available on port 9090.
"""

from datetime import datetime, timedelta, timezone

from fastapi import FastAPI


app = FastAPI(title="Local Prometheus Mock")


@app.get("/-/ready")
def ready() -> str:
    return "Prometheus mock is ready"


@app.get("/api/v1/alerts")
def alerts() -> dict:
    now = datetime.now(timezone.utc)
    return {
        "status": "success",
        "data": {
            "alerts": [
                {
                    "labels": {
                        "alertname": "HighCPUUsage",
                        "severity": "warning",
                        "instance": "data-sync-service-01",
                        "job": "super-biz-agent-demo",
                        "namespace": "default",
                        "pod": "data-sync-service-7c9f",
                    },
                    "annotations": {
                        "summary": "CPU usage is above threshold",
                        "description": "data-sync-service CPU usage has stayed above 80% for 10 minutes.",
                    },
                    "state": "firing",
                    "activeAt": (now - timedelta(minutes=18)).isoformat().replace("+00:00", "Z"),
                    "value": "91.4",
                },
                {
                    "labels": {
                        "alertname": "MemoryPressure",
                        "severity": "info",
                        "instance": "api-gateway-02",
                        "job": "super-biz-agent-demo",
                        "namespace": "default",
                        "pod": "api-gateway-5b82",
                    },
                    "annotations": {
                        "summary": "Memory usage is rising",
                        "description": "api-gateway memory usage is approaching the configured threshold.",
                    },
                    "state": "pending",
                    "activeAt": (now - timedelta(minutes=6)).isoformat().replace("+00:00", "Z"),
                    "value": "72.8",
                },
            ]
        },
    }

