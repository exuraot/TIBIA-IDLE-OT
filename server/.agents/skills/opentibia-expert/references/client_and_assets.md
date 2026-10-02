# Arquitetura do Cliente Tibia 15 & OTClient

## 1. Cliente Oficial Tibia 15 (Qt6 + WebEngine)

### Estrutura de Arquivos
```
client/
├── bin/
│   ├── client.exe            # Executável oficial compilado em C++ / Qt6
│   ├── Qt6Core.dll, Qt6Gui.dll, Qt6Quick.dll, etc.
│   └── QtWebEngineProcess.exe
├── assets/                   # Blocos compactados em LZMA (.lzma)
├── appearances.dat           # Definições binárias Google Protobuf (itens, outfits, efeitos)
├── assets.json               # Manifest de integridade e catálogo de assets com hashes SHA256
├── package.json              # Metadados e versão (ex: 15.24.eb0021)
└── conf/
    └── clientoptions.json    # Configurações de interface, renderizador gráfico e hotkeys
```

### O Protocolo Protobuf (`appearances.dat`)
A partir do Tibia 11/12 e consolidado no 15, os arquivos clássicos `Tibia.spr` e `Tibia.dat` foram substituídos pelo formato Google Protobuf:
* Os nós no Protobuf contêm:
  * `Appearance`: ID visual, flags (bloqueia passagem, tem luz, é container, etc.).
  * `FrameGroup`: Animações, rotações, camadas de cor (head, body, legs, feet).
  * `SpriteSheet`: Referências aos índices nas folhas de sprites.

### Como Customizar Sprites no Tibia 15:
1. Abra o **Assets Editor** em [`C:/.../Tibia 15/sprite editor/Assets Editor.exe`](file:///C:/Users/desig/OneDrive/Documentos/Tibia%2015/sprite%20editor/Assets%20Editor.exe).
2. Carregue o `appearances.dat` e `assets.json` do cliente.
3. Importe os novos sprites (formato PNG 32x32 ou múltiplos).
4. Crie um novo ID de aparência (Appearance ID).
5. Salve e exporte:
   * O `appearances.dat` gerado deve ser copiado para o servidor em [`C:/otserv/data/items/appearances.dat`](file:///C:/otserv/data/items/appearances.dat) para que o servidor reconheça as colisões e propriedades do novo item!
   * E também mantido na pasta do cliente.

---

## 2. OTClient (Open Source Client)

Para servidores que optam pelo cliente aberto em vez do cliente oficial da CipSoft:

### Arquitetura de Módulos
* **Diretório `modules/`:**
  * `client_entergame/`: Tela inicial de login e lista de servidores.
  * `game_battle/`: Janela de batalha.
  * `game_inventory/`: Slots de inventário e equipamentos.
  * `game_console/`: Canais de chat (Default, Server Log, Help, etc.).
  * `game_interface/`: Layout geral da tela do jogo.

### Linguagem OTUI (.otui)
* Define a estrutura visual de maneira similar ao CSS / QML.
* Exemplo de Janela:
  ```otui
  MainWindow
    id: myCustomWindow
    !text: tr('Painel Especial')
    size: 250 300
    @onEscape: self:destroy()

    Label
      id: lblInfo
      anchors.top: parent.top
      anchors.left: parent.left
      margin-top: 10
      margin-left: 10
      text: Bem-vindo!

    Button
      id: btnAction
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-bottom: 10
      text: Executar
      @onClick: modules.my_module.doAction()
  ```

### Extended Opcodes (Comunicação Customizada Servidor <-> Cliente)
No cliente (Lua):
```lua
ProtocolGame.registerExtendedOpcode(50, function(protocol, opcode, buffer)
    print("Mensagem do servidor: " .. buffer)
end)

g_game.sendExtendedOpcode(51, "pedido_dados")
```

No servidor Canary/Crystal Server:
```lua
local creatureEvent = CreatureEvent("ExtendedOpcodeHandler")
function creatureEvent.onExtendedOpcode(player, opcode, buffer)
    if opcode == 51 then
        player:sendExtendedOpcode(50, "dados_confirmados")
    end
    return true
end
creatureEvent:register()
```
