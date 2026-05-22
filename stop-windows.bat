@echo off
echo ====================================
echo Stopping SuperBizAgent services
echo ====================================
echo.

echo [1/4] Stopping FastAPI service...
taskkill /FI "WINDOWTITLE eq SuperBizAgent API*" /F >nul 2>&1
if errorlevel 1 (
    echo [INFO] FastAPI service was not running.
) else (
    echo [OK] FastAPI service stopped.
)
echo.

echo [2/4] Stopping CLS MCP service...
taskkill /FI "WINDOWTITLE eq CLS MCP Server*" /F >nul 2>&1
if errorlevel 1 (
    echo [INFO] CLS MCP service was not running.
) else (
    echo [OK] CLS MCP service stopped.
)
echo.

echo [3/4] Stopping Monitor MCP service...
taskkill /FI "WINDOWTITLE eq Monitor MCP Server*" /F >nul 2>&1
if errorlevel 1 (
    echo [INFO] Monitor MCP service was not running.
) else (
    echo [OK] Monitor MCP service stopped.
)
echo.

echo [4/5] Stopping Prometheus mock service...
taskkill /FI "WINDOWTITLE eq Prometheus Mock Server*" /F >nul 2>&1
if errorlevel 1 (
    echo [INFO] Prometheus mock service was not running.
) else (
    echo [OK] Prometheus mock service stopped.
)
echo.

echo [5/5] Stopping Milvus containers...
where docker >nul 2>&1
if errorlevel 1 (
    echo [INFO] Docker command was not found. Skipping containers.
) else (
    docker ps --format "{{.Names}}" | findstr "milvus" >nul 2>&1
    if not errorlevel 1 (
        docker compose -f vector-database.yml down
    ) else (
        echo [INFO] Milvus containers were not running.
    )
)

echo.
echo ====================================
echo All services stopped
echo ====================================
pause
