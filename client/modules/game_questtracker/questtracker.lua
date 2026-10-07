--[[
  Universal Quest & Guide Tracker with In-Game Visual GPS
  Exura OT Server - Client Redemption
  100% Manual Walking - Visual Guidance Only
]]

questTracker = {}

local trackerMiniWindow = nil
local guideExplorerWindow = nil
local topMenuButton = nil
local mainPanelButton = nil

local guidesDatabase = {}
local activeGuide = nil
local isGpsActive = false
local gpsTimer = nil

local gpsOverlay = nil
local gpsDots = {}
local gpsBeacon = nil
local MAX_GPS_DOTS = 35

local currentCategory = 'all'
local searchQuery = ''

-- Helper for direction and compass
local function getCompassDirection(dx, dy)
    if dx == 0 and dy < 0 then return 'Norte (↑)'
    elseif dx > 0 and dy < 0 then return 'Nordeste (↗)'
    elseif dx > 0 and dy == 0 then return 'Leste (→)'
    elseif dx > 0 and dy > 0 then return 'Sudeste (↘)'
    elseif dx == 0 and dy > 0 then return 'Sul (↓)'
    elseif dx < 0 and dy > 0 then return 'Sudoeste (↙)'
    elseif dx < 0 and dy == 0 then return 'Oeste (←)'
    elseif dx < 0 and dy < 0 then return 'Noroeste (↖)'
    end
    return 'Aqui (◉)'
end

--[[=================================================
=            Database Loading & Management          =
=================================================== ]]
local function loadDatabase()
    local path = '/modules/game_questtracker/data/quests_guide.json'
    if not g_resources.fileExists(path) then
        pcall(function()
            local raw = g_resources.readFileContents(path)
            if raw then
                guidesDatabase = json.decode(raw)
            end
        end)
    else
        local content = g_resources.readFileContents(path)
        if content then
            local ok, data = pcall(function() return json.decode(content) end)
            if ok and data then
                guidesDatabase = data
            end
        end
    end

    if not guidesDatabase or not guidesDatabase.entries then
        guidesDatabase = { entries = {}, categories = {} }
    end
end

--[[=================================================
=                 GPS Overlay Engine                =
=================================================== ]]
local function initGpsOverlay()
    local mapPanel = modules.game_interface.getMapPanel()
    if not mapPanel then return end

    if not gpsOverlay then
        gpsOverlay = g_ui.createWidget('UIWidget', mapPanel)
        gpsOverlay:fill('parent')
        gpsOverlay:setPhantom(true)

        -- Create Pool of GPS breadcrumb dots
        for i = 1, MAX_GPS_DOTS do
            local dot = g_ui.createWidget('UIWidget', gpsOverlay)
            dot:setSize({width = 14, height = 14})
            dot:setBackgroundColor('#00ffffcc')
            dot:setBorderWidth(1)
            dot:setBorderColor('#ffffff')
            dot:setPhantom(true)
            dot:hide()
            gpsDots[i] = dot
        end

        -- Create Target Beacon
        gpsBeacon = g_ui.createWidget('UIWidget', gpsOverlay)
        gpsBeacon:setSize({width = 38, height = 38})
        gpsBeacon:setBackgroundColor('#ffd70044')
        gpsBeacon:setBorderWidth(2)
        gpsBeacon:setBorderColor('#ffd700')
        gpsBeacon:setPhantom(true)

        local beaconLabel = g_ui.createWidget('UILabel', gpsBeacon)
        beaconLabel:setId('beaconLabel')
        beaconLabel:setFont('verdana-11px-rounded')
        beaconLabel:setColor('#ffd700')
        beaconLabel:setTextAlign(AlignTopCenter)
        beaconLabel:setMarginTop(-16)
        beaconLabel:setPhantom(true)
        beaconLabel:setParent(gpsBeacon)
        beaconLabel:addAnchor(AnchorBottom, 'parent', AnchorTop)
        beaconLabel:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)

        gpsBeacon:hide()
    end
end

local function hideGpsVisuals()
    for _, dot in ipairs(gpsDots) do
        dot:hide()
    end
    if gpsBeacon then
        gpsBeacon:hide()
    end
end

local function updateGpsDisplay()
    if not isGpsActive or not activeGuide then
        hideGpsVisuals()
        return
    end

    local player = g_game.getLocalPlayer()
    if not player then
        hideGpsVisuals()
        return
    end

    local playerPos = player:getPosition()
    if not playerPos then
        hideGpsVisuals()
        return
    end

    local targetPos = nil
    local stepData = nil
    if activeGuide.steps and #activeGuide.steps > 0 then
        stepData = activeGuide.steps[1]
        targetPos = stepData.targetCoords or stepData.npcCoords or activeGuide.coords
    else
        targetPos = activeGuide.coords
    end

    if not targetPos or not targetPos.x or not targetPos.y or not targetPos.z then
        hideGpsVisuals()
        return
    end

    local mapPanel = modules.game_interface.getMapPanel()
    if not mapPanel then return end

    local dx = targetPos.x - playerPos.x
    local dy = targetPos.y - playerPos.y
    local dz = targetPos.z - playerPos.z
    local dist = math.floor(math.sqrt(dx * dx + dy * dy))
    local dirStr = getCompassDirection(dx, dy)

    -- Update MiniWindow text
    if trackerMiniWindow and trackerMiniWindow.contentsPanel and trackerMiniWindow.contentsPanel.activeBox then
        local ab = trackerMiniWindow.contentsPanel.activeBox
        local distText = string.format('📍 %s - %d sqm %s', activeGuide.city or 'Destino', dist, dirStr)
        if dz > 0 then
            distText = distText .. string.format(' (Descer %d andares)', dz)
        elseif dz < 0 then
            distText = distText .. string.format(' (Subir %d andares)', math.abs(dz))
        end
        ab.trackedDistance:setText(distText)
    end

    -- Update Minimap Crosshair
    pcall(function()
        if modules.game_minimap and modules.game_minimap.mapController then
            local mm = modules.game_minimap.mapController.ui.minimapBorder.minimap
            if mm then
                mm:setCrossPosition(targetPos)
            end
        end
    end)

    -- Check if arrived
    if dist <= 1 and dz == 0 then
        hideGpsVisuals()
        if trackerMiniWindow and trackerMiniWindow.contentsPanel.activeBox then
            trackerMiniWindow.contentsPanel.activeBox.trackedDistance:setText('🎯 Você chegou ao local!')
        end
        return
    end

    -- If on different floor, hide ground breadcrumbs and indicate floor change
    if playerPos.z ~= targetPos.z then
        hideGpsVisuals()
        return
    end

    -- Calculate breadcrumb path on same floor
    local pathPoints = {}
    local stepsCount = math.min(dist, 16)
    if stepsCount > 0 then
        for i = 1, stepsCount do
            local ratio = i / stepsCount
            local px = math.floor(playerPos.x + dx * ratio + 0.5)
            local py = math.floor(playerPos.y + dy * ratio + 0.5)
            table.insert(pathPoints, {x = px, y = py, z = playerPos.z})
        end
    end

    -- Render Breadcrumb Dots on MapPanel tiles
    local dotIndex = 1
    for _, pt in ipairs(pathPoints) do
        if dotIndex > MAX_GPS_DOTS then break end

        if mapPanel:isInRange(pt) then
            local rect = mapPanel:getTileRect(pt)
            if rect and rect.width and rect.width > 0 and rect.height and rect.height > 0 then
                local dot = gpsDots[dotIndex]
                dot:show()
                local dotSize = (dotIndex == #pathPoints) and 18 or 12
                dot:setSize({width = dotSize, height = dotSize})
                dot:setX(rect.x + math.floor((rect.width - dotSize) / 2))
                dot:setY(rect.y + math.floor((rect.height - dotSize) / 2))

                -- Color gradient from player (cyan) to destination (golden)
                if dotIndex == #pathPoints then
                    dot:setBackgroundColor('#ffd700ee')
                    dot:setBorderColor('#ffffff')
                else
                    dot:setBackgroundColor('#00ffffbb')
                    dot:setBorderColor('#008888')
                end

                dotIndex = dotIndex + 1
            end
        end
    end

    -- Hide remaining dots
    for i = dotIndex, MAX_GPS_DOTS do
        gpsDots[i]:hide()
    end

    -- Render Target Beacon if target is visible on screen
    if mapPanel:isInRange(targetPos) then
        local rect = mapPanel:getTileRect(targetPos)
        if rect and rect.width and rect.width > 0 then
            gpsBeacon:show()
            gpsBeacon:setSize({width = rect.width, height = rect.height})
            gpsBeacon:setX(rect.x)
            gpsBeacon:setY(rect.y)
            local lbl = gpsBeacon:getChildById('beaconLabel')
            if lbl then
                lbl:setText(activeGuide.startNpc or activeGuide.name or 'Alvo')
            end
        else
            gpsBeacon:hide()
        end
    else
        gpsBeacon:hide()
    end
end

--[[=================================================
=             Tracker MiniWindow Logic              =
=================================================== ]]
local function updateTrackerMiniWindow()
    if not trackerMiniWindow then return end

    local contents = trackerMiniWindow.contentsPanel
    if not contents then return end

    local emptyBox = contents.emptyBox
    local activeBox = contents.activeBox

    if not activeGuide then
        emptyBox:show()
        activeBox:hide()
        return
    end

    emptyBox:hide()
    activeBox:show()

    activeBox.trackedTitle:setText(activeGuide.name or 'Guia Ativo')
    
    local stepTitle = 'Passo 1/1: Dirija-se ao local'
    local npcStr = 'NPC: ' .. (activeGuide.startNpc or 'Local Marcado') .. ' (' .. (activeGuide.city or 'Outdoors') .. ')'
    local dialogStr = 'Diálogo: ' .. (activeGuide.dialog or 'Converse com o NPC')

    if activeGuide.steps and #activeGuide.steps > 0 then
        local s = activeGuide.steps[1]
        stepTitle = 'Passo 1/' .. #activeGuide.steps .. ': ' .. (s.title or s.instruction or '')
        if s.npc then
            npcStr = 'NPC: ' .. s.npc .. ' (' .. (s.city or activeGuide.city or '') .. ')'
        end
        if s.dialog then
            dialogStr = 'Diálogo: ' .. s.dialog
        end
    end

    activeBox.trackedStep:setText(stepTitle)
    activeBox.trackedNpc:setText(npcStr)
    activeBox.trackedDialog:setText(dialogStr)

    local btnGps = activeBox.miniControls.btnToggleGps
    if isGpsActive then
        btnGps:setText('GPS: ON')
        btnGps:setColor('#00ff88')
    else
        btnGps:setText('GPS: OFF')
        btnGps:setColor('#ff5555')
    end

    updateGpsDisplay()
end

function questTracker.setTrackedGuide(guide, enableGps)
    activeGuide = guide
    if enableGps ~= nil then
        isGpsActive = enableGps
    else
        isGpsActive = true
    end

    if guideExplorerWindow and guideExplorerWindow.sidebar and guideExplorerWindow.sidebar.trackerStatusBox then
        local box = guideExplorerWindow.sidebar.trackerStatusBox
        box.activeGuideName:setText(guide and guide.name or 'Nenhum selecionado')
        box.activeGpsStatus:setText(isGpsActive and 'GPS: Ativo' or 'GPS: Desligado')
        box.activeGpsStatus:setColor(isGpsActive and '#00ff88' or '#888888')
    end

    updateTrackerMiniWindow()

    if isGpsActive then
        initGpsOverlay()
        updateGpsDisplay()
    else
        hideGpsVisuals()
    end
end

function questTracker.clearTrackedGuide()
    activeGuide = nil
    isGpsActive = false
    hideGpsVisuals()
    if guideExplorerWindow and guideExplorerWindow.sidebar and guideExplorerWindow.sidebar.trackerStatusBox then
        local box = guideExplorerWindow.sidebar.trackerStatusBox
        box.activeGuideName:setText('Nenhum selecionado')
        box.activeGpsStatus:setText('GPS: Desligado')
        box.activeGpsStatus:setColor('#888888')
    end
    updateTrackerMiniWindow()
end

function questTracker.toggleGps()
    if not activeGuide then return end
    isGpsActive = not isGpsActive
    if isGpsActive then
        initGpsOverlay()
        updateGpsDisplay()
    else
        hideGpsVisuals()
    end
    updateTrackerMiniWindow()
end

--[[=================================================
=             Explorer Window & Filtering           =
=================================================== ]]
local function createGuideCard(guide)
    local card = g_ui.createWidget('GuideCard')
    card:setId('guide_' .. (guide.id or 'unknown'))

    if guide.iconItem and guide.iconItem > 0 then
        card.iconItem:setItemId(guide.iconItem)
    else
        card.iconItem:setItemId(1988)
    end

    card.name:setText(guide.name or 'Guia')
    card.details:setText(guide.description or '')
    
    local npcCity = 'NPC: ' .. (guide.startNpc or 'Local') .. ' | ' .. (guide.city or 'Outdoors') .. ' | Lv ' .. (guide.level or 1) .. '+'
    card.npcInfo:setText(npcCity)

    local catBadge = card.categoryBadge
    if guide.category == 'addon' then
        catBadge:setText('ADDON')
        catBadge:setBackgroundColor('#3d2b50')
        catBadge:setColor('#ff88ff')
    elseif guide.category == 'mount' then
        catBadge:setText('MOUNT')
        catBadge:setBackgroundColor('#2b503d')
        catBadge:setColor('#88ff88')
    elseif guide.category == 'access' then
        catBadge:setText('ACESSO')
        catBadge:setBackgroundColor('#50452b')
        catBadge:setColor('#ffff88')
    else
        catBadge:setText('QUEST')
        catBadge:setBackgroundColor('#2b3a4a')
        catBadge:setColor('#88ccff')
    end

    -- Button handlers
    card.actionButtons.btnGps.onClick = function()
        questTracker.setTrackedGuide(guide, true)
        modules.game_textmessage.displayStatusConsole(string.format('[GPS Ativado] Guiando ate %s em %s.', guide.startNpc or guide.name, guide.city or 'destino'))
    end

    card.actionButtons.btnTrack.onClick = function()
        questTracker.setTrackedGuide(guide, false)
        modules.game_textmessage.displayStatusConsole(string.format('[Tracker Fixado] %s fixado no seu painel lateral.', guide.name))
    end

    card.actionButtons.btnDialog.onClick = function()
        local d = guide.dialog or 'Converse normalmente com o NPC.'
        local msg = string.format('=== %s ===\nNPC: %s (%s)\nDiálogo:\n%s', guide.name, guide.startNpc or 'NPC', guide.city or '', d)
        if guide.requiredItems and #guide.requiredItems > 0 then
            msg = msg .. '\n\nItens Necessários:\n'
            for _, it in ipairs(guide.requiredItems) do
                msg = msg .. string.format('• %dx %s\n', it.count or 1, it.name or ('Item ' .. it.id))
            end
        end
        displayInfoBox(guide.name, msg)
    end

    return card
end

local function refreshExplorerList()
    if not guideExplorerWindow then return end

    local list = guideExplorerWindow.mainContent.guideList
    list:destroyChildren()

    local q = string.lower(string.trim(searchQuery))
    local count = 0

    for _, guide in ipairs(guidesDatabase.entries or {}) do
        local matchCat = (currentCategory == 'all') or (guide.category == currentCategory)
        local matchSearch = true

        if q ~= '' then
            local gName = string.lower(guide.name or '')
            local gNpc = string.lower(guide.startNpc or '')
            local gCity = string.lower(guide.city or '')
            local gDesc = string.lower(guide.description or '')

            if not string.find(gName, q, 1, true) and
               not string.find(gNpc, q, 1, true) and
               not string.find(gCity, q, 1, true) and
               not string.find(gDesc, q, 1, true) then
                matchSearch = false
            end
        end

        if matchCat and matchSearch then
            local card = createGuideCard(guide)
            list:addChild(card)
            count = count + 1
        end
    end
end

local function setCategory(cat, btn)
    currentCategory = cat
    local sb = guideExplorerWindow.sidebar
    local buttons = {sb.catAll, sb.catQuest, sb.catAddon, sb.catMount, sb.catAccess}
    for _, b in ipairs(buttons) do
        if b then b:setChecked(b == btn) end
    end
    refreshExplorerList()
end

function questTracker.showExplorer()
    if not guideExplorerWindow then return end
    guideExplorerWindow:show()
    guideExplorerWindow:raise()
    guideExplorerWindow:focus()
    refreshExplorerList()
end

function questTracker.toggleExplorer()
    if not guideExplorerWindow then return end
    if guideExplorerWindow:isVisible() then
        guideExplorerWindow:hide()
    else
        questTracker.showExplorer()
    end
end

function questTracker.toggleMiniWindow()
    if not trackerMiniWindow then return end
    if trackerMiniWindow:isVisible() then
        trackerMiniWindow:hide()
    else
        trackerMiniWindow:show()
    end
end

--[[=================================================
=                Module Lifecycle                   =
=================================================== ]]
function init()
    g_ui.importStyle('questtracker.otui')

    loadDatabase()

    -- 1. Create MiniWindow docked into Right Panel
    local rightPanel = modules.game_interface.getMainRightPanel() or modules.game_interface.getRightPanel()
    trackerMiniWindow = g_ui.createWidget('QuestTrackerMiniWindow', rightPanel)
    trackerMiniWindow:setup()

    -- Connect buttons inside MiniWindow
    local activeBox = trackerMiniWindow.contentsPanel.activeBox
    if activeBox then
        activeBox.miniControls.btnToggleGps.onClick = questTracker.toggleGps
        activeBox.miniControls.btnClearTrack.onClick = questTracker.clearTrackedGuide
    end

    -- 2. Create Explorer Window
    guideExplorerWindow = g_ui.createWidget('GuideExplorerWindow', modules.game_interface.getRootPanel())
    guideExplorerWindow:hide()

    -- Connect Explorer Search & Filters
    local sb = guideExplorerWindow.sidebar
    sb.catAll.onClick = function(b) setCategory('all', b) end
    sb.catQuest.onClick = function(b) setCategory('quest', b) end
    sb.catAddon.onClick = function(b) setCategory('addon', b) end
    sb.catMount.onClick = function(b) setCategory('mount', b) end
    sb.catAccess.onClick = function(b) setCategory('access', b) end
    sb.trackerStatusBox.btnStopAllGps.onClick = questTracker.clearTrackedGuide

    local searchEdit = guideExplorerWindow.mainContent.searchInput
    searchEdit.onTextChange = function(w, text)
        searchQuery = text
        refreshExplorerList()
    end

    -- 3. Register TopMenu and MainPanel Toggle Buttons
    topMenuButton = modules.client_topmenu.addRightGameToggleButton('questTrackerTopBtn', tr('Quest & GPS Tracker'), '/images/topbuttons/icon-questtracker-widget', questTracker.toggleExplorer)
    mainPanelButton = modules.game_mainpanel.addToggleButton('questTrackerMainBtn', tr('Quest & GPS Tracker'), '/images/topbuttons/icon-questtracker-widget', questTracker.toggleMiniWindow, false, 1002)

    -- 4. Register LocalPlayer position event for real-time GPS update
    connect(LocalPlayer, {
        onPositionChange = function()
            if isGpsActive then
                updateGpsDisplay()
            end
        end
    })

    -- 5. Periodic GPS update timer (for moving map camera or smooth updates)
    gpsTimer = cycleEvent(function()
        if isGpsActive then
            updateGpsDisplay()
        end
    end, 500)

    connect(g_game, {
        onGameStart = function()
            initGpsOverlay()
            updateTrackerMiniWindow()
        end,
        onGameEnd = function()
            hideGpsVisuals()
        end
    })

    initGpsOverlay()
    updateTrackerMiniWindow()
end

function terminate()
    if gpsTimer then
        removeEvent(gpsTimer)
        gpsTimer = nil
    end

    hideGpsVisuals()

    if gpsOverlay then
        gpsOverlay:destroy()
        gpsOverlay = nil
    end

    if trackerMiniWindow then
        trackerMiniWindow:destroy()
        trackerMiniWindow = nil
    end

    if guideExplorerWindow then
        guideExplorerWindow:destroy()
        guideExplorerWindow = nil
    end

    if topMenuButton then
        topMenuButton:destroy()
        topMenuButton = nil
    end

    if mainPanelButton then
        mainPanelButton:destroy()
        mainPanelButton = nil
    end
end
