--[[
  Universal Quest & Guide Tracker with In-Game Visual GPS
  Exura OT Server - Client Redemption
  100% Manual Walking - Visual Guidance Only
]]

questTracker = {}

local trackerMiniWindow = nil
local guideExplorerWindow = nil
local questDetailsWindow = nil
local topMenuButton = nil
local mainPanelButton = nil

local guidesDatabase = {}
local activeGuide = nil
local isGpsActive = false
local gpsTimer = nil

local gpsOverlay = nil
local gpsDots = {}
local gpsBeacon = nil
local gpsEdgeArrow = nil
local MAX_GPS_DOTS = 30

local currentCategory = 'all'
local searchQuery = ''

-- Compass direction calculations
local function getCompassDirection(dx, dy)
    if dx == 0 and dy < 0 then return 'North (↑)'
    elseif dx > 0 and dy < 0 then return 'Northeast (↗)'
    elseif dx > 0 and dy == 0 then return 'East (→)'
    elseif dx > 0 and dy > 0 then return 'Southeast (↘)'
    elseif dx == 0 and dy > 0 then return 'South (↓)'
    elseif dx < 0 and dy > 0 then return 'Southwest (↙)'
    elseif dx < 0 and dy == 0 then return 'West (←)'
    elseif dx < 0 and dy < 0 then return 'Northwest (↖)'
    end
    return 'Here (◉)'
end

--[[=================================================
=            Database Loading & Management          =
=================================================== ]]
local function loadDatabase()
    local path = '/modules/game_questtracker/data/quests_guide.json'
    local content = nil
    if g_resources.fileExists(path) then
        content = g_resources.readFileContents(path)
    end

    if content then
        local ok, data = pcall(function() return json.decode(content) end)
        if ok and data then
            guidesDatabase = data
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

        -- Create Target Beacon for visible target
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

        -- Create Edge Compass Arrow for off-screen targets
        gpsEdgeArrow = g_ui.createWidget('UIButton', gpsOverlay)
        gpsEdgeArrow:setSize({width = 140, height = 26})
        gpsEdgeArrow:setBackgroundColor('#101620dd')
        gpsEdgeArrow:setBorderWidth(1)
        gpsEdgeArrow:setBorderColor('#00ffff')
        gpsEdgeArrow:setFont('verdana-11px-rounded')
        gpsEdgeArrow:setColor('#00ffff')
        gpsEdgeArrow:setPhantom(true)
        gpsEdgeArrow:hide()
    end
end

local function hideGpsVisuals()
    for _, dot in ipairs(gpsDots) do
        dot:hide()
    end
    if gpsBeacon then gpsBeacon:hide() end
    if gpsEdgeArrow then gpsEdgeArrow:hide() end
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
    if activeGuide.steps and #activeGuide.steps > 0 then
        local s = activeGuide.steps[1]
        targetPos = s.targetCoords or s.npcCoords or activeGuide.coords
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
        local distText = string.format('Location: %s - %dm %s', activeGuide.city or 'World', dist, dirStr)
        if dz > 0 then
            distText = distText .. string.format(' (Go down %d fl)', dz)
        elseif dz < 0 then
            distText = distText .. string.format(' (Go up %d fl)', math.abs(dz))
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
            trackerMiniWindow.contentsPanel.activeBox.trackedDistance:setText('Target Reached!')
        end
        return
    end

    -- If on different floor, hide ground breadcrumbs and indicate floor change
    if playerPos.z ~= targetPos.z then
        hideGpsVisuals()
        return
    end

    -- Calculate local breadcrumb points starting from the player's current tile
    local pathPoints = {}
    local norm = math.sqrt(dx * dx + dy * dy)
    local udx = norm > 0 and (dx / norm) or 0
    local udy = norm > 0 and (dy / norm) or 0

    local stepsToDraw = math.min(dist, 10)
    for i = 1, stepsToDraw do
        local px = math.floor(playerPos.x + udx * i + 0.5)
        local py = math.floor(playerPos.y + udy * i + 0.5)
        table.insert(pathPoints, {x = px, y = py, z = playerPos.z})
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
                local dotSize = (dotIndex == #pathPoints and dist <= 10) and 18 or 12
                dot:setSize({width = dotSize, height = dotSize})
                dot:setX(rect.x + math.floor((rect.width - dotSize) / 2))
                dot:setY(rect.y + math.floor((rect.height - dotSize) / 2))

                if dotIndex == #pathPoints and dist <= 10 then
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
                lbl:setText(activeGuide.startNpc or activeGuide.name or 'Target')
            end
        else
            gpsBeacon:hide()
        end
        if gpsEdgeArrow then gpsEdgeArrow:hide() end
    else
        gpsBeacon:hide()

        -- Render Edge Compass Arrow pointing toward offscreen target
        if gpsEdgeArrow then
            gpsEdgeArrow:show()
            local mapW = mapPanel:getWidth()
            local mapH = mapPanel:getHeight()
            local cx = mapW / 2
            local cy = mapH / 2

            local arrowX = math.max(16, math.min(mapW - 150, cx + udx * (cx - 30) - 70))
            local arrowY = math.max(16, math.min(mapH - 40, cy + udy * (cy - 30) - 13))

            gpsEdgeArrow:setX(arrowX)
            gpsEdgeArrow:setY(arrowY)
            gpsEdgeArrow:setText(string.format('%s (%dm)', activeGuide.startNpc or 'Target', dist))
        end
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

    activeBox.trackedTitle:setText(activeGuide.name or 'Active Guide')
    
    local stepTitle = 'Step 1/1: Travel to destination'
    local npcStr = 'NPC: ' .. (activeGuide.startNpc or 'Target Location') .. ' (' .. (activeGuide.city or 'Outdoors') .. ')'
    local dialogStr = 'Talk: ' .. (activeGuide.dialogTranscript or 'Speak with the NPC')

    if activeGuide.steps and #activeGuide.steps > 0 then
        local s = activeGuide.steps[1]
        stepTitle = 'Step 1/' .. #activeGuide.steps .. ': ' .. (s.title or s.instruction or '')
        if s.npc then
            npcStr = 'NPC: ' .. s.npc .. ' (' .. (s.city or activeGuide.city or '') .. ')'
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
        box.activeGuideName:setText(guide and guide.name or 'None Selected')
        box.activeGpsStatus:setText(isGpsActive and 'GPS: Active' or 'GPS: Disabled')
        box.activeGpsStatus:setColor(isGpsActive and '#00ff88' or '#888888')
    end

    updateTrackerMiniWindow()

    if isGpsActive then
        initGpsOverlay()
        updateGpsDisplay()
    else
        hideGpsVisuals()
    end

    -- Refresh active highlight in explorer cards
    questTracker.refreshActiveCardHighlights()
end

function questTracker.clearTrackedGuide()
    activeGuide = nil
    isGpsActive = false
    hideGpsVisuals()
    if guideExplorerWindow and guideExplorerWindow.sidebar and guideExplorerWindow.sidebar.trackerStatusBox then
        local box = guideExplorerWindow.sidebar.trackerStatusBox
        box.activeGuideName:setText('None Selected')
        box.activeGpsStatus:setText('GPS: Disabled')
        box.activeGpsStatus:setColor('#888888')
    end
    updateTrackerMiniWindow()
    questTracker.refreshActiveCardHighlights()
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
    questTracker.refreshActiveCardHighlights()
end

function questTracker.refreshActiveCardHighlights()
    if not guideExplorerWindow then return end
    local list = guideExplorerWindow.mainContent.guideList
    if not list then return end

    for _, card in ipairs(list:getChildren()) do
        local btnTrack = card.actionButtons and card.actionButtons.btnTrack
        local btnGps = card.actionButtons and card.actionButtons.btnGps
        if btnTrack and card.guideData then
            if activeGuide and activeGuide.id == card.guideData.id then
                btnTrack:setText('Active')
                btnTrack:setColor('#00ff88')
                btnTrack:setBorderColor('#00aa55')
                if btnGps then
                    if isGpsActive then
                        btnGps:setText('Stop GPS')
                        btnGps:setColor('#ff5555')
                    else
                        btnGps:setText('Start GPS')
                        btnGps:setColor('#00ffff')
                    end
                end
            else
                btnTrack:setText('Track Map')
                btnTrack:setColor('#ffd700')
                btnTrack:setBorderColor('#ccaa00')
                if btnGps then
                    btnGps:setText('Start GPS')
                    btnGps:setColor('#00ffff')
                end
            end
        end
    end
end

--[[=================================================
=             Detailed Quest Dialog Modal           =
=================================================== ]]
function questTracker.showDetails(guide)
    if not questDetailsWindow then return end

    local hb = questDetailsWindow.headerBox
    hb.detailTitle:setText(guide.name or 'Quest Details')
    hb.detailNpcInfo:setText(string.format('Starting NPC: %s (%s)', guide.startNpc or 'NPC', guide.city or 'World'))
    hb.detailLevelInfo:setText(string.format('Recommended Level: %d+', guide.level or 1))

    -- Set visual avatar in details
    if guide.creatureLookType and guide.creatureLookType > 0 then
        hb.detailAvatarBox.detailCreature:show()
        hb.detailAvatarBox.detailCreature:setOutfit({
            type = guide.creatureLookType,
            head = 0, body = 114, legs = 94, feet = 114,
            addons = guide.addons or 0
        })
        hb.detailAvatarBox.detailItem:hide()
    elseif guide.mountClientId and guide.mountClientId > 0 then
        hb.detailAvatarBox.detailCreature:show()
        hb.detailAvatarBox.detailCreature:setOutfit({ type = guide.mountClientId })
        hb.detailAvatarBox.detailItem:hide()
    elseif guide.npcLookType and guide.npcLookType > 0 then
        hb.detailAvatarBox.detailCreature:show()
        hb.detailAvatarBox.detailCreature:setOutfit({
            type = guide.npcLookType,
            head = 76, body = 43, legs = 38, feet = 76,
            addons = 0
        })
        hb.detailAvatarBox.detailItem:hide()
    elseif guide.rewardItemId and guide.rewardItemId > 0 then
        hb.detailAvatarBox.detailItem:show()
        hb.detailAvatarBox.detailItem:setItemId(guide.rewardItemId)
        hb.detailAvatarBox.detailCreature:hide()
    else
        hb.detailAvatarBox.detailItem:show()
        hb.detailAvatarBox.detailItem:setItemId(guide.iconItem or 1988)
        hb.detailAvatarBox.detailCreature:hide()
    end

    local badge = hb.detailBadge
    if guide.category == 'addon' then
        badge:setText('ADDON')
        badge:setBackgroundColor('#3d2b50')
        badge:setColor('#ff88ff')
    elseif guide.category == 'mount' then
        badge:setText('MOUNT')
        badge:setBackgroundColor('#2b503d')
        badge:setColor('#88ff88')
    elseif guide.category == 'access' then
        badge:setText('ACCESS')
        badge:setBackgroundColor('#50452b')
        badge:setColor('#ffff88')
    else
        badge:setText('QUEST')
        badge:setBackgroundColor('#2b3a4a')
        badge:setColor('#88ccff')
    end

    local content = questDetailsWindow.detailsContent
    content.loreText:setText(guide.lore or guide.description or 'No lore available.')
    content.dialogueText:setText(guide.dialogTranscript or 'Speak with the starting NPC to begin.')

    -- Rewards text
    local rStr = ''
    if guide.rewards and #guide.rewards > 0 then
        for _, r in ipairs(guide.rewards) do
            rStr = rStr .. '• ' .. r.name .. '\n'
        end
    else
        rStr = '• Quest Experience and Completion Entry in Quest Log.'
    end
    content.rewardsText:setText(rStr)

    -- Footer buttons
    local footer = questDetailsWindow.footerPanel
    footer.btnDetailTrack.onClick = function()
        questTracker.setTrackedGuide(guide, false)
        modules.game_textmessage.displayStatusConsole(string.format('[Quest Tracker] Now tracking: %s on your map.', guide.name))
    end
    footer.btnDetailGps.onClick = function()
        questTracker.setTrackedGuide(guide, true)
        modules.game_textmessage.displayStatusConsole(string.format('[GPS Guide] Navigating to %s in %s.', guide.startNpc or guide.name, guide.city or 'world'))
    end

    questDetailsWindow:show()
    questDetailsWindow:raise()
    questDetailsWindow:focus()
end

--[[=================================================
=             Explorer Window & Filtering           =
=================================================== ]]
local function createGuideCard(guide)
    local card = g_ui.createWidget('GuideCard')
    card:setId('guide_' .. (guide.id or 'unknown'))
    card.guideData = guide

    -- Visual Creature / Mount / NPC Preview
    if guide.creatureLookType and guide.creatureLookType > 0 then
        card.previewBox.creaturePreview:show()
        card.previewBox.creaturePreview:setOutfit({
            type = guide.creatureLookType,
            head = 0, body = 114, legs = 94, feet = 114,
            addons = guide.addons or 0
        })
        card.previewBox.itemPreview:hide()
    elseif guide.mountClientId and guide.mountClientId > 0 then
        card.previewBox.creaturePreview:show()
        card.previewBox.creaturePreview:setOutfit({
            type = guide.mountClientId
        })
        card.previewBox.itemPreview:hide()
    elseif guide.npcLookType and guide.npcLookType > 0 then
        card.previewBox.creaturePreview:show()
        card.previewBox.creaturePreview:setOutfit({
            type = guide.npcLookType,
            head = 76, body = 43, legs = 38, feet = 76,
            addons = 0
        })
        card.previewBox.itemPreview:hide()
    elseif guide.rewardItemId and guide.rewardItemId > 0 then
        card.previewBox.itemPreview:show()
        card.previewBox.itemPreview:setItemId(guide.rewardItemId)
        card.previewBox.creaturePreview:hide()
    else
        card.previewBox.itemPreview:show()
        card.previewBox.itemPreview:setItemId(guide.iconItem or 1988)
        card.previewBox.creaturePreview:hide()
    end

    card.name:setText(guide.name or 'Guide')
    card.details:setText(guide.description or '')
    
    local npcCity = 'NPC: ' .. (guide.startNpc or 'Location') .. ' | ' .. (guide.city or 'Outdoors') .. ' | Lv ' .. (guide.level or 1) .. '+'
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
        catBadge:setText('ACCESS')
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
        modules.game_textmessage.displayStatusConsole(string.format('[GPS Guide] Navigating to %s in %s.', guide.startNpc or guide.name, guide.city or 'world'))
    end

    card.actionButtons.btnTrack.onClick = function()
        questTracker.setTrackedGuide(guide, false)
        modules.game_textmessage.displayStatusConsole(string.format('[Quest Tracker] Now tracking: %s.', guide.name))
    end

    card.actionButtons.btnDetails.onClick = function()
        questTracker.showDetails(guide)
    end

    return card
end

local function refreshExplorerList()
    if not guideExplorerWindow then return end

    local list = guideExplorerWindow.mainContent.guideList
    list:destroyChildren()

    local q = string.lower(string.trim(searchQuery))

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
        end
    end

    questTracker.refreshActiveCardHighlights()
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

    -- 1. Create MiniWindow dockable in the Sidebar panels (Right or Left Panel)
    local rightPanel = modules.game_interface.getRightPanel() or modules.game_interface.getMainRightPanel()
    trackerMiniWindow = g_ui.createWidget('QuestTrackerMiniWindow', rightPanel)
    trackerMiniWindow:setup()

    local activeBox = trackerMiniWindow.contentsPanel.activeBox
    if activeBox then
        activeBox.miniControls.btnToggleGps.onClick = questTracker.toggleGps
        activeBox.miniControls.btnClearTrack.onClick = questTracker.clearTrackedGuide
    end

    -- 2. Create Explorer Window
    guideExplorerWindow = g_ui.createWidget('GuideExplorerWindow', modules.game_interface.getRootPanel())
    guideExplorerWindow:hide()

    -- Connect Explorer Search & Category Filters
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

    -- 3. Create Quest Details Window
    questDetailsWindow = g_ui.createWidget('QuestDetailsWindow', modules.game_interface.getRootPanel())
    questDetailsWindow:hide()

    -- 4. Register Single Button directly below Idle Hunt in MainPanel
    -- Disable legacy questlog duplicate button if present
    if modules.game_questlog and modules.game_questlog.buttonQuestLogTrackerButton then
        modules.game_questlog.buttonQuestLogTrackerButton:destroy()
        modules.game_questlog.buttonQuestLogTrackerButton = nil
    end

    -- Register single clean button in MainPanel (index 1002 places it directly below Idle Hunt)
    mainPanelButton = modules.game_mainpanel.addToggleButton(
        'questTrackerMainBtn',
        tr('Quest & GPS Tracker'),
        '/images/topbuttons/icon-questtracker-widget',
        questTracker.toggleExplorer,
        false,
        1002
    )

    -- 5. Register LocalPlayer position event for real-time GPS update
    connect(LocalPlayer, {
        onPositionChange = function()
            if isGpsActive then
                updateGpsDisplay()
            end
        end
    })

    -- 6. Periodic GPS update timer
    gpsTimer = cycleEvent(function()
        if isGpsActive then
            updateGpsDisplay()
        end
    end, 400)

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

    if questDetailsWindow then
        questDetailsWindow:destroy()
        questDetailsWindow = nil
    end

    if mainPanelButton then
        mainPanelButton:destroy()
        mainPanelButton = nil
    end
end
