@echo off
echo ========================================
echo    VERIFICACAO DE STATUS DO SISTEMA
echo ========================================
echo.

echo [1/3] Verificando status do Git...
cd /d "%~dp0"
git status --short
if %errorlevel% equ 0 (
    echo ✅ Git funcionando normalmente
) else (
    echo ❌ Problema com Git
)

echo.
echo [2/3] Verificando conectividade com GitHub...
git remote -v
if %errorlevel% equ 0 (
    echo ✅ GitHub configurado corretamente
) else (
    echo ❌ Problema com GitHub
)

echo.
echo [3/3] Verificando status do sistema na AWS...
echo Tentando conectar ao servidor...
timeout /t 2 /nobreak >nul
curl -I http://18.230.87.151 --connect-timeout 10 --max-time 15 2>nul
if %errorlevel% equ 0 (
    echo ✅ Sistema online e acessível
    echo 🌐 URL: http://18.230.87.151
) else (
    echo ❌ Sistema offline ou inacessível
)

echo.
echo ========================================
echo    VERIFICACAO CONCLUIDA
echo ========================================
pause





