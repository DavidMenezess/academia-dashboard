@echo off
echo ========================================
echo    ATUALIZACAO DO SISTEMA ACADEMIA
echo ========================================
echo.

echo [1/3] Fazendo commit das alteracoes locais...
cd /d "%~dp0"
git add .
git commit -m "🔄 Update: Atualizacao automatica do sistema"
if %errorlevel% neq 0 (
    echo ERRO: Falha no commit. Verifique se ha alteracoes pendentes.
    pause
    exit /b 1
)

echo.
echo [2/3] Enviando alteracoes para o GitHub...
git push origin main
if %errorlevel% neq 0 (
    echo ERRO: Falha no push para GitHub.
    pause
    exit /b 1
)

echo.
echo [3/3] Atualizando sistema na AWS...
echo Aguarde, isso pode demorar alguns minutos...
echo.

REM Tentar conectar via SSH e atualizar
echo Tentando conectar ao servidor...
ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no ubuntu@18.230.87.151 "cd /home/ubuntu/academia-dashboard && git pull origin main && cd web-site && docker-compose -f docker-compose.prod.yml restart" 2>nul

if %errorlevel% equ 0 (
    echo.
    echo ✅ SUCESSO! Sistema atualizado com sucesso!
    echo 🌐 Acesse: http://18.230.87.151
) else (
    echo.
    echo ⚠️  AVISO: Nao foi possivel conectar via SSH.
    echo 📝 Mas as alteracoes foram enviadas para o GitHub.
    echo 🔄 O sistema sera atualizado automaticamente em alguns minutos.
)

echo.
echo ========================================
echo    ATUALIZACAO CONCLUIDA
echo ========================================
pause

