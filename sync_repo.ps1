# Sincronizador de arquivos ativos para o repositório TIBIA-IDLE-OT
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Sincronizando Server (c:\otserv) -> $repoDir\server..." -ForegroundColor Cyan
robocopy "c:\otserv" "$repoDir\server" /E /XF *.pdb *.zip *.tar.gz *.log *.bak /XD .git .planning otserv logs

Write-Host "Sincronizando Site (c:\xampp\htdocs) -> $repoDir\site..." -ForegroundColor Cyan
robocopy "c:\xampp\htdocs" "$repoDir\site" /E /XF *.zip *.tar.gz *.log *.bak /XD .git cache downloads

Write-Host "Sincronizando Client -> $repoDir\client..." -ForegroundColor Cyan
robocopy "C:\Users\desig\OneDrive\Documentos\Tibia 15\ot client redemption" "$repoDir\client" /E /XF *.zip *.log *.bak /XD .git

Write-Host "Sincronizacao concluida com sucesso!" -ForegroundColor Green
