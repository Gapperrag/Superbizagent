@echo off
setlocal enabledelayedexpansion

echo ====================================
echo Starting SuperBizAgent services
echo ====================================
echo.

echo [1/9] Checking Python...
set PYTHON_EXE=

if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" (
    "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" -c "import sys; raise SystemExit(0 if (3,11) <= sys.version_info < (3,14) else 1)" >nul 2>&1
    if not errorlevel 1 set PYTHON_EXE="%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
)

if "%PYTHON_EXE%"=="" (
    if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
        "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" -c "import sys; raise SystemExit(0 if (3,11) <= sys.version_info < (3,14) else 1)" >nul 2>&1
        if not errorlevel 1 set PYTHON_EXE="%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    )
)

if "%PYTHON_EXE%"=="" (
    if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
        "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" -c "import sys; raise SystemExit(0 if (3,11) <= sys.version_info < (3,14) else 1)" >nul 2>&1
        if not errorlevel 1 set PYTHON_EXE="%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    )
)

if "%PYTHON_EXE%"=="" (
    where py >nul 2>&1
    if not errorlevel 1 (
        py -3.13 -c "import sys; raise SystemExit(0 if (3,11) <= sys.version_info < (3,14) else 1)" >nul 2>&1
        if not errorlevel 1 set PYTHON_EXE=py -3.13
    )
)

if "%PYTHON_EXE%"=="" (
    where py >nul 2>&1
    if not errorlevel 1 (
        py -3.12 -c "import sys; raise SystemExit(0 if (3,11) <= sys.version_info < (3,14) else 1)" >nul 2>&1
        if not errorlevel 1 set PYTHON_EXE=py -3.12
    )
)

if "%PYTHON_EXE%"=="" (
    where py >nul 2>&1
    if not errorlevel 1 (
        py -3.11 -c "import sys; raise SystemExit(0 if (3,11) <= sys.version_info < (3,14) else 1)" >nul 2>&1
        if not errorlevel 1 set PYTHON_EXE=py -3.11
    )
)

if "%PYTHON_EXE%"=="" (
    where python >nul 2>&1
    if not errorlevel 1 (
        python -c "import sys; raise SystemExit(0 if (3,11) <= sys.version_info < (3,14) else 1)" >nul 2>&1
        if not errorlevel 1 (
            for /f "tokens=*" %%i in ('python -c "import sys; print(sys.executable)" 2^>nul') do set PYTHON_EXE=%%i
        )
    )
)

if "%PYTHON_EXE%"=="" (
    echo [ERROR] Python 3.11-3.13 was not found.
    echo Install Python from https://www.python.org/downloads/windows/
    echo During install, check "Add python.exe to PATH".
    pause
    exit /b 1
)

%PYTHON_EXE% -c "import sys; raise SystemExit(0 if (3,11) <= sys.version_info < (3,14) else 1)" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] This project requires Python 3.11, 3.12, or 3.13.
    %PYTHON_EXE% --version
    pause
    exit /b 1
)
%PYTHON_EXE% --version
echo.

echo [2/9] Checking package manager...
where uv >nul 2>&1
if errorlevel 1 (
    echo [INFO] uv not found. pip will be used.
    set USE_UV=0
) else (
    echo [INFO] uv found.
    set USE_UV=1
)
echo.

echo [3/9] Creating or updating virtual environment...
if exist .venv\Scripts\python.exe (
    echo [INFO] Existing virtual environment found.
    .venv\Scripts\python.exe -c "import sys; raise SystemExit(0 if (3,11) <= sys.version_info < (3,14) else 1)" >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Existing .venv uses an unsupported Python version.
        .venv\Scripts\python.exe --version
        echo Delete the .venv folder after installing Python 3.11, 3.12, or 3.13, then run this script again.
        pause
        exit /b 1
    )
) else (
    if "%USE_UV%"=="1" (
        uv venv
    ) else (
        %PYTHON_EXE% -m venv .venv
    )
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
)

if "%USE_UV%"=="1" (
    uv sync
    if errorlevel 1 (
        echo [WARN] uv sync failed. Falling back to pip install.
        .venv\Scripts\python.exe -m pip install -e .
    )
) else (
    .venv\Scripts\python.exe -m pip install --upgrade pip
    .venv\Scripts\python.exe -m pip install -e .
)
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies.
    pause
    exit /b 1
)
echo [OK] Virtual environment is ready.
echo.

echo [4/9] Checking Docker...
set SKIP_DOCKER=0
where docker >nul 2>&1
if errorlevel 1 (
    echo [WARN] Docker command was not found.
    netstat -ano | findstr ":19530" >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Milvus is not listening on port 19530.
        echo Install and start Docker Desktop, then run this script again.
        pause
        exit /b 1
    ) else (
        echo [INFO] Milvus port 19530 is already available. Skipping Docker startup.
        set SKIP_DOCKER=1
    )
)
if "%SKIP_DOCKER%"=="0" (
    docker info >nul 2>&1
    if errorlevel 1 (
        echo [WARN] Docker Desktop is not available to this shell.
        netstat -ano | findstr ":19530" >nul 2>&1
        if errorlevel 1 (
            echo [ERROR] Milvus is not listening on port 19530.
            echo Start Docker Desktop, wait until it is ready, then run this script again.
            pause
            exit /b 1
        ) else (
            echo [INFO] Milvus port 19530 is already available. Skipping Docker startup.
            set SKIP_DOCKER=1
        )
    )
)
echo.

echo [5/9] Starting Milvus vector database...
if "%SKIP_DOCKER%"=="1" (
    echo [INFO] Using existing Milvus on port 19530.
) else (
    docker ps --format "{{.Names}}" | findstr /C:"milvus-standalone" >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Milvus is already running.
    ) else (
        docker compose -f vector-database.yml up -d
        if errorlevel 1 (
            echo [ERROR] Failed to start Milvus with Docker Compose.
            pause
            exit /b 1
        )
        echo [INFO] Waiting 15 seconds for Milvus startup...
        timeout /t 15 /nobreak >nul
    )
)
echo [OK] Milvus is ready.
echo.

echo [6/9] Starting local Prometheus mock if needed...
netstat -ano | findstr ":9090" >nul 2>&1
if not errorlevel 1 (
    echo [INFO] Port 9090 is already in use. Using existing Prometheus endpoint.
) else (
    start "Prometheus Mock Server" /min .venv\Scripts\python.exe -m uvicorn mcp_servers.prometheus_mock_server:app --host 127.0.0.1 --port 9090
    timeout /t 2 /nobreak >nul
    echo [OK] Prometheus mock started at http://127.0.0.1:9090
)
echo.

echo [7/9] Starting MCP servers...
start "CLS MCP Server" /min .venv\Scripts\python.exe mcp_servers\cls_server.py
timeout /t 2 /nobreak >nul
start "Monitor MCP Server" /min .venv\Scripts\python.exe mcp_servers\monitor_server.py
timeout /t 2 /nobreak >nul
echo [OK] MCP servers started.
echo.

echo [8/9] Starting FastAPI service...
start "SuperBizAgent API" .venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 9900
echo [INFO] Waiting 15 seconds for API startup...
timeout /t 15 /nobreak >nul
echo.

echo [9/9] Checking API and uploading built-in docs...
curl -s http://localhost:9900/health >nul 2>&1
if errorlevel 1 (
    echo [WARN] API may still be starting. Open http://localhost:9900 later.
) else (
    echo [OK] API is running.
    for %%f in (aiops-docs\*.md) do (
        echo Uploading %%~nxf
        curl -s -X POST http://localhost:9900/api/upload -F "file=@%%f" >nul 2>&1
    )
    echo [OK] Built-in docs uploaded.
)

echo.
echo ====================================
echo Services started
echo ====================================
echo Web UI:   http://localhost:9900
echo API docs: http://localhost:9900/docs
echo Health:   http://localhost:9900/health
echo Stop:     stop-windows.bat
echo ====================================
pause
