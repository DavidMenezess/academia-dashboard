# ========================================
# SCRIPT DE ATUALIZACAO DO SISTEMA ACADEMIA
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    ATUALIZACAO DO SISTEMA ACADEMIA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Definir cores
$SuccessColor = "Green"
$ErrorColor = "Red"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

try {
    # Navegar para o diretório do projeto
    Set-Location $PSScriptRoot
    
    Write-Host "[1/4] Verificando status do Git..." -ForegroundColor $InfoColor
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Host "Alterações encontradas:" -ForegroundColor $WarningColor
        Write-Host $gitStatus -ForegroundColor Gray
        
        Write-Host "[2/4] Fazendo commit das alterações..." -ForegroundColor $InfoColor
        git add .
        git commit -m "🔄 Update: Atualização automática do sistema - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        
        if ($LASTEXITCODE -ne 0) {
            throw "Erro no commit do Git"
        }
        Write-Host "✅ Commit realizado com sucesso!" -ForegroundColor $SuccessColor
    } else {
        Write-Host "✅ Nenhuma alteração pendente." -ForegroundColor $SuccessColor
    }
    
    Write-Host ""
    Write-Host "[3/4] Enviando alterações para o GitHub..." -ForegroundColor $InfoColor
    git push origin main
    
    if ($LASTEXITCODE -ne 0) {
        throw "Erro no push para GitHub"
    }
    Write-Host "✅ Push realizado com sucesso!" -ForegroundColor $SuccessColor
    
    Write-Host ""
    Write-Host "[4/4] Tentando atualizar sistema na AWS..." -ForegroundColor $InfoColor
    
    # Verificar se SSH está disponível
    $sshPath = Get-Command ssh -ErrorAction SilentlyContinue
    if ($sshPath) {
        Write-Host "Tentando conectar via SSH..." -ForegroundColor $InfoColor
        
        # Comando SSH para atualizar o sistema
        $sshCommand = @"
cd /home/ubuntu/academia-dashboard && \
git pull origin main && \
cd web-site && \
docker-compose -f docker-compose.prod.yml down && \
docker-compose -f docker-compose.prod.yml up -d && \
echo 'Sistema atualizado com sucesso!'
"@
        
        # Executar SSH com timeout
        $result = ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no ubuntu@18.230.87.151 $sshCommand 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Sistema atualizado via SSH!" -ForegroundColor $SuccessColor
            Write-Host $result -ForegroundColor Gray
        } else {
            Write-Host "⚠️  SSH falhou, mas GitHub foi atualizado." -ForegroundColor $WarningColor
            Write-Host "O sistema será atualizado automaticamente em alguns minutos." -ForegroundColor $InfoColor
        }
    } else {
        Write-Host "⚠️  SSH não encontrado no sistema." -ForegroundColor $WarningColor
        Write-Host "As alterações foram enviadas para o GitHub." -ForegroundColor $InfoColor
        Write-Host "O sistema será atualizado automaticamente." -ForegroundColor $InfoColor
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    ATUALIZACAO CONCLUIDA COM SUCESSO!" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🌐 Acesse seu sistema:" -ForegroundColor $InfoColor
    Write-Host "   http://18.230.87.151" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 URLs do sistema:" -ForegroundColor $InfoColor
    Write-Host "   Login: http://18.230.87.151/login.html" -ForegroundColor White
    Write-Host "   Admin: http://18.230.87.151/admin.html" -ForegroundColor White
    Write-Host "   Caixa: http://18.230.87.151/cashier.html" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "❌ ERRO durante a atualização:" -ForegroundColor $ErrorColor
    Write-Host $_.Exception.Message -ForegroundColor $ErrorColor
    Write-Host ""
    Write-Host "🔧 Soluções possíveis:" -ForegroundColor $InfoColor
    Write-Host "   1. Verifique sua conexão com a internet" -ForegroundColor White
    Write-Host "   2. Verifique se o GitHub está acessível" -ForegroundColor White
    Write-Host "   3. Execute 'git status' para verificar o estado" -ForegroundColor White
    Write-Host "   4. Tente novamente em alguns minutos" -ForegroundColor White
}

Write-Host ""
Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")



