# Diagnóstico, Solução de Problemas & Hot-Reloading

## 1. Guia de Hot-Reloading In-Game

Com o personagem GOD (Group ID 5) conectado ao jogo, use os comandos abaixo para aplicar alterações sem reiniciar o executável `crystalserver.exe`:

| Comando | O que Recarrega |
|---|---|
| `/reload scripts` | Recarrega todos os scripts de actions, movements, quests, talkactions e globalevents. |
| `/reload monsters` | Recarrega definições de monstros, ataques, defesas, spells e loots. |
| `/reload spells` | Recarrega magias instantâneas e runas. |
| `/reload npcs` | Recarrega falas, lógicas e tabelas de shop de todos os NPCs. |
| `/reload items` | Recarrega atributos, pesos e flags do `items.xml`. |
| `/reload config` | Recarrega opções não-estruturais do `config.lua` (ex: rates de loot/exp, mensagens de broadcast). |
| `/reload mounts` | Recarrega montarias cadastradas em `mounts.xml`. |
| `/reload outfits` | Recarrega outfits cadastrados em `outfits.xml`. |
| `/reload quests` | Recarrega missões e logs do Quest Tracker. |

---

## 2. Erros Mais Comuns e Como Resolver

### A. Erro: "Duplicate registered action/spell/moveevent"
* **Causa:** O mesmo Item ID, Action ID ou palavras de magia (`words`) já foram registrados em outro arquivo.
* **Solução:** Faça uma busca global (`grep`) pelo ID duplicado e remova a duplicata ou utilize um ID diferente.

### B. Erro: "Cannot connect to MySQL server"
* **Causa:** O MariaDB/MySQL não está rodando no XAMPP ou as credenciais no `config.lua` estão incorretas.
* **Solução:**
  1. Verifique se o processo `mysqld.exe` está ativo.
  2. Teste a conexão via linha de comando:
     ```powershell
     & "C:\xampp\mysql\bin\mysql.exe" -u root -e "SHOW DATABASES;"
     ```
  3. Garanta que no `config.lua` o usuário seja `root` e a senha vazia (`""`).

### C. Cliente não conecta ("Couldn't load assets" ou Erro de Login)
* **Causa 1 (Assets):** Se modificou `appearances.dat`, o arquivo `assets.json` pode estar com hash inválido ou o `appearances.dat` não foi sincronizado entre cliente e servidor.
* **Causa 2 (Login):** Apache (`httpd.exe`) fechado no XAMPP ou rota do `login.php` inacessível. Teste abrindo `http://127.0.0.1/login.php` no navegador. Deve retornar um JSON estruturado.

### D. Mapa não salva ou erros de spawn no Map Editor
* **Causa:** Canary Map Editor precisa apontar para os mesmos arquivos de criaturas e itens que o servidor usa.
* **Solução:** Verifique as preferências do Map Editor em *File > Preferences > Client Version* apontando para a versão correta e os arquivos `datspr`.
