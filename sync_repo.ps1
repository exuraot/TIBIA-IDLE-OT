# Sincronizador de arquivos ativos para o repositório TIBIA-IDLE-OT
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Sincronizando Dev Client -> Prod Client..." -ForegroundColor Cyan
robocopy "C:\Users\desig\OneDrive\Documentos\Tibia 15\ot client redemption (dev)\modules" "C:\Users\desig\OneDrive\Documentos\Tibia 15\ot client redemption\modules" /E /XF *.log *.bak

Write-Host "Sincronizando Server (c:\otserv) -> $repoDir\server..." -ForegroundColor Cyan
robocopy "c:\otserv" "$repoDir\server" /E /XF *.pdb *.zip *.tar.gz *.log *.bak *.php scratch* check* apply* update* find* fix* /XD .git .planning otserv logs cache

Write-Host "Sincronizando Site (c:\xampp\htdocs) -> $repoDir\site..." -ForegroundColor Cyan
robocopy "c:\xampp\htdocs" "$repoDir\site" /E /XF *.zip *.tar.gz *.log *.bak /XD .git cache downloads system\cache

Write-Host "Sincronizando Client -> $repoDir\client..." -ForegroundColor Cyan
robocopy "C:\Users\desig\OneDrive\Documentos\Tibia 15\ot client redemption" "$repoDir\client" /E /XF *.zip *.log *.bak /XD .git

Write-Host "Sincronizando GEMINI.md..." -ForegroundColor Cyan
Copy-Item "c:\otserv\GEMINI.md" "$repoDir\server\GEMINI.md" -Force

Write-Host "Sincronizacao concluida com sucesso!" -ForegroundColor Green
