--[[
  Universal Quest & Guide Tracker with In-Game Visual GPS
  Exura OT Server - Client Redemption
  100% Manual Walking - Visual Guidance Only
]]

questTracker = {}

local trackerMiniWindow = nil
local guideExplorerWindow = nil
local questDetailsWindow = nil
local mainPanelButton = nil

local guidesDatabase = {}
local activeGuide = nil
local isGpsActive = false
local gpsTimer = nil

local gpsOverlay = nil
local gpsTopBanner = nil
local gpsDots = {}
local gpsBeacon = nil
local gpsEdgeArrow = nil
local MAX_GPS_DOTS = 30

local questMinimapMarker = nil

local currentCategory = 'all'
local searchQuery = ''

-- Compass direction calculations (Clean ASCII - No mojibake)
local function getCompassDirection(dx, dy)
    if dx == 0 and dy < 0 then return 'North (N)'
    elseif dx > 0 and dy < 0 then return 'Northeast (NE)'
    elseif dx > 0 and dy == 0 then return 'East (E)'
    elseif dx > 0 and dy > 0 then return 'Southeast (SE)'
    elseif dx == 0 and dy > 0 then return 'South (S)'
    elseif dx < 0 and dy > 0 then return 'Southwest (SW)'
    elseif dx < 0 and dy == 0 then return 'West (W)'
    elseif dx < 0 and dy < 0 then return 'Northwest (NW)'
    end
    return 'Here (*)'
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
    if not g_game.isOnline() then return end
    local mapPanel = modules.game_interface and modules.game_interface.getMapPanel()
    local rootPanel = modules.game_interface and modules.game_interface.getRootPanel()
    if not mapPanel then return end

    if not gpsOverlay then
        gpsOverlay = g_ui.createWidget('GpsOverlay', mapPanel)
        gpsOverlay:show()
        gpsOverlay:raise()

        -- Create Pool of GPS breadcrumb dots
        for i = 1, MAX_GPS_DOTS do
            local dot = g_ui.createWidget('GpsDot', gpsOverlay)
            dot:hide()
            gpsDots[i] = dot
        end

        -- Create Target Beacon for visible target
        gpsBeacon = g_ui.createWidget('GpsBeacon', gpsOverlay)
        gpsBeacon:hide()
    end

    -- Create or attach Top Banner to root panel
    if rootPanel and not gpsTopBanner then
        gpsTopBanner = g_ui.createWidget('GpsTopBanner', rootPanel)
        gpsTopBanner:hide()
    end
end

local function hideGpsVisuals()
    for _, dot in ipairs(gpsDots) do
        if dot then dot:hide() end
    end
    if gpsBeacon then gpsBeacon:hide() end
    if gpsTopBanner then gpsTopBanner:hide() end
    if gpsEdgeArrow then gpsEdgeArrow:hide() end
    if questMinimapMarker then questMinimapMarker:hide() end
    pcall(function()
        local mm = modules.game_minimap and (
            (modules.game_minimap.getMiniMapUi and modules.game_minimap.getMiniMapUi()) or
            (modules.game_minimap.mapController and modules.game_minimap.mapController.ui and modules.game_minimap.mapController.ui.minimapBorder and modules.game_minimap.mapController.ui.minimapBorder.minimap)
        )
        if mm and mm.setCrossPosition then
            mm:setCrossPosition(nil)
        end
    end)
end

--[[=================================================
=                 Minimap Marker Engine             =
=================================================== ]]
local function updateMinimapMarker(pos, guide)
    pcall(function()
        local mm = modules.game_minimap and (
            (modules.game_minimap.getMiniMapUi and modules.game_minimap.getMiniMapUi()) or
            (modules.game_minimap.mapController and modules.game_minimap.mapController.ui and modules.game_minimap.mapController.ui.minimapBorder and modules.game_minimap.mapController.ui.minimapBorder.minimap)
        )
        if not mm then return end

        if not pos or not guide then
            if questMinimapMarker then
                questMinimapMarker:hide()
            end
            if mm.setCrossPosition then
                mm:setCrossPosition(nil)
            end
            return
        end

        if not questMinimapMarker then
            questMinimapMarker = g_ui.createWidget('GpsMinimapMarker', mm)
        end

        local player = g_game.getLocalPlayer()
        local playerPos = player and player:getPosition()
        local mmRect = mm:getRect()
        local mmW = (mmRect and mmRect.width > 20) and mmRect.width or 106
        local mmH = (mmRect and mmRect.height > 20) and mmRect.height or 106
        local cx = mmW / 2
        local cy = mmH / 2

        if playerPos then
            local dx = pos.x - playerPos.x
            local dy = pos.y - playerPos.y
            local scale = (mm.getScale and mm:getScale()) or 1
            if scale > 1 then scale = 1 end

            local px = dx * scale
            local py = dy * scale
            local margin = 12
            local maxX = cx - margin
            local maxY = cy - margin

            if math.abs(px) <= maxX and math.abs(py) <= maxY and pos.z == playerPos.z then
                questMinimapMarker:setPosition({
                    x = math.floor(mmRect.x + cx + px - 10),
                    y = math.floor(mmRect.y + cy + py - 10)
                })
            else
                local angle = math.atan2(dy, dx)
                local edgeX = math.cos(angle) * maxX
                local edgeY = math.sin(angle) * maxY

                if math.abs(edgeX) > maxX then
                    edgeX = (edgeX > 0 and maxX or -maxX)
                    edgeY = edgeX * math.tan(angle)
                end
                if math.abs(edgeY) > maxY then
                    edgeY = (edgeY > 0 and maxY or -maxY)
                    edgeX = edgeY / math.tan(angle)
                end

                questMinimapMarker:setPosition({
                    x = math.floor(mmRect.x + cx + edgeX - 10),
                    y = math.floor(mmRect.y + cy + edgeY - 10)
                })
            end

            local dist = math.floor(math.sqrt(dx * dx + dy * dy))
            local dirStr = getCompassDirection(dx, dy)
            questMinimapMarker:setTooltip(string.format('%s\nTarget: %s (%s)\nDistance: %dm [%s]', guide.name or 'Quest', guide.startNpc or 'Objective', guide.city or 'World', dist, dirStr))
            questMinimapMarker:show()
            questMinimapMarker:raise()

            if mm.setCrossPosition and pos.z == playerPos.z then
                mm:setCrossPosition(pos)
            end
            if mm.addFlag then
                mm:addFlag(pos, 11, guide.name, true)
            end
        end
    end)
end

local function getNextStepPos(pos, dir)
    local p = {x = pos.x, y = pos.y, z = pos.z}
    if dir == North then p.y = p.y - 1
    elseif dir == East then p.x = p.x + 1
    elseif dir == South then p.y = p.y + 1
    elseif dir == West then p.x = p.x - 1
    elseif dir == NorthEast then p.x = p.x + 1; p.y = p.y - 1
    elseif dir == SouthEast then p.x = p.x + 1; p.y = p.y + 1
    elseif dir == SouthWest then p.x = p.x - 1; p.y = p.y + 1
    elseif dir == NorthWest then p.x = p.x - 1; p.y = p.y - 1
    end
    return p
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

    local mapPanel = modules.game_interface and modules.game_interface.getMapPanel()
    if not mapPanel then return end

    local dx = targetPos.x - playerPos.x
    local dy = targetPos.y - playerPos.y
    local dz = targetPos.z - playerPos.z
    local dist = math.floor(math.sqrt(dx * dx + dy * dy))
    local dirStr = getCompassDirection(dx, dy)

    -- Update MiniWindow distance text
    if trackerMiniWindow and trackerMiniWindow.contentsPanel and trackerMiniWindow.contentsPanel.activeBox then
        local ab = trackerMiniWindow.contentsPanel.activeBox
        local distText = string.format('Compass: %dm %s', dist, dirStr)
        if dz > 0 then
            distText = distText .. string.format(' • [Down %d fl]', dz)
        elseif dz < 0 then
            distText = distText .. string.format(' • [Up %d fl]', math.abs(dz))
        else
            distText = distText .. ' • [Same Floor]'
        end
        if ab.trackedDistance then
            ab.trackedDistance:setText(distText)
        end
    end

    -- Keep top banner hidden to preserve clean, uncluttered game view
    if gpsTopBanner then
        gpsTopBanner:hide()
    end

    -- Update minimap marker and compass edge pointer
    updateMinimapMarker(targetPos, activeGuide)

    -- Check if arrived at exact position
    if dist <= 1 and dz == 0 then
        hideGpsVisuals()
        if trackerMiniWindow and trackerMiniWindow.contentsPanel and trackerMiniWindow.contentsPanel.activeBox then
            local ab = trackerMiniWindow.contentsPanel.activeBox
            if ab.trackedDistance then
                ab.trackedDistance:setText('Target Reached!')
            end
        end
        return
    end

    -- Ensure GPS Overlay exists
    if not gpsOverlay then
        initGpsOverlay()
    end
    if gpsOverlay then
        gpsOverlay:show()
        gpsOverlay:raise()
    end

    -- Intelligent Pathfinding: Curve around buildings & walls using walkable map tiles
    local pathPoints = {}
    local foundPath = false

    if dist <= 14 and dz == 0 then
        local dirs, result = g_map.findPath(playerPos, targetPos, 150, 0)
        if dirs and #dirs > 0 then
            local curr = {x = playerPos.x, y = playerPos.y, z = playerPos.z}
            for _, d in ipairs(dirs) do
                curr = getNextStepPos(curr, d)
                local t = g_map.getTile(curr)
                if t and t:isWalkable() then
                    table.insert(pathPoints, curr)
                end
            end
            foundPath = true
        end
    end

    if not foundPath then
        local norm = math.sqrt(dx * dx + dy * dy)
        local udx = norm > 0 and (dx / norm) or 0
        local udy = norm > 0 and (dy / norm) or 0
        local baseAngle = math.atan2(udy, udx)

        local angleOffsets = {0, 0.25, -0.25, 0.5, -0.5, 0.75, -0.75, 1.0, -1.0}
        local bestDirs = nil

        for _, offset in ipairs(angleOffsets) do
            local ang = baseAngle + offset
            local cosA = math.cos(ang)
            local sinA = math.sin(ang)

            for r = 8, 4, -1 do
                local candPos = {
                    x = math.floor(playerPos.x + cosA * r + 0.5),
                    y = math.floor(playerPos.y + sinA * r + 0.5),
                    z = playerPos.z
                }
                local t = g_map.getTile(candPos)
                if t and t:isWalkable() then
                    local dirs, result = g_map.findPath(playerPos, candPos, 100, 0)
                    if dirs and #dirs > 0 then
                        bestDirs = dirs
                        break
                    end
                end
            end
            if bestDirs then break end
        end

        if bestDirs then
            local curr = {x = playerPos.x, y = playerPos.y, z = playerPos.z}
            for _, d in ipairs(bestDirs) do
                curr = getNextStepPos(curr, d)
                local t = g_map.getTile(curr)
                if t and t:isWalkable() then
                    table.insert(pathPoints, curr)
                end
            end
        else
            for i = 1, math.min(dist, 8) do
                local candPos = {
                    x = math.floor(playerPos.x + udx * i + 0.5),
                    y = math.floor(playerPos.y + udy * i + 0.5),
                    z = playerPos.z
                }
                local t = g_map.getTile(candPos)
                if t and t:isWalkable() then
                    table.insert(pathPoints, candPos)
                end
            end
        end
    end

    -- Render Breadcrumb Dots on MapPanel tiles
    local mapRect = mapPanel:getRect()
    local dim = mapPanel:getVisibleDimension() or {width = 15, height = 11}
    local cam = mapPanel:getCameraPosition() or playerPos
    local tileW = mapRect.width / dim.width
    local tileH = mapRect.height / dim.height
    local cx = mapRect.x + (mapRect.width / 2)
    local cy = mapRect.y + (mapRect.height / 2)

    local millis = g_clock.millis()
    local dotIndex = 1

    for _, pt in ipairs(pathPoints) do
        if dotIndex > MAX_GPS_DOTS then break end

        local diffX = pt.x - cam.x
        local diffY = pt.y - cam.y
        if math.abs(diffX) <= (dim.width / 2) + 0.5 and math.abs(diffY) <= (dim.height / 2) + 0.5 then
            local dot = gpsDots[dotIndex]
            if dot then
                local screenX = cx + (diffX * tileW)
                local screenY = cy + (diffY * tileH)
                local dotSize = 22

                dot:setSize({width = dotSize, height = dotSize})
                dot:setPosition({
                    x = math.floor(screenX - dotSize / 2),
                    y = math.floor(screenY - dotSize / 2)
                })

                local wave = 0.65 + 0.35 * math.sin((millis / 200) - (dotIndex * 0.5))
                dot:setOpacity(math.max(0.3, math.min(1.0, wave)))

                dot:show()
                dot:raise()
                dotIndex = dotIndex + 1
            end
        end
    end

    for i = dotIndex, MAX_GPS_DOTS do
        if gpsDots[i] then gpsDots[i]:hide() end
    end

    -- Render Target Beacon if target is visible on screen and on the same floor
    local targetDiffX = targetPos.x - cam.x
    local targetDiffY = targetPos.y - cam.y
    if dz == 0 and math.abs(targetDiffX) <= (dim.width / 2) + 0.5 and math.abs(targetDiffY) <= (dim.height / 2) + 0.5 then
        local bSize = 38
        local screenX = cx + (targetDiffX * tileW)
        local screenY = cy + (targetDiffY * tileH)
        gpsBeacon:show()
        gpsBeacon:setSize({width = bSize, height = bSize})
        gpsBeacon:setPosition({
            x = math.floor(screenX - bSize / 2),
            y = math.floor(screenY - bSize / 2)
        })
        gpsBeacon:raise()
        local lbl = gpsBeacon:getChildById('label')
        if lbl then
            lbl:setText(activeGuide.startNpc or activeGuide.name or 'Target')
        end
    else
        gpsBeacon:hide()
    end
end

--[[=================================================
=             Tracker MiniWindow Logic              =
=================================================== ]]
local function initTrackerMiniWindow()
    if trackerMiniWindow then return end
    if not g_game.isOnline() then return end

    local rightPanel = modules.game_interface and (modules.game_interface.getRightPanel() or modules.game_interface.getMainRightPanel())
    if not rightPanel then return end

    local existing = rightPanel:getChildById('questTrackerMiniWindow')
    if existing then
        trackerMiniWindow = existing
    else
        trackerMiniWindow = g_ui.createWidget('QuestTrackerMiniWindow', rightPanel)
        trackerMiniWindow:setup()
        if trackerMiniWindow.setupOnStart then
            trackerMiniWindow:setupOnStart()
        end
    end

    local activeBox = trackerMiniWindow.contentsPanel and trackerMiniWindow.contentsPanel.activeBox
    if activeBox and activeBox.miniControls then
        if activeBox.miniControls.btnToggleGps then
            activeBox.miniControls.btnToggleGps.onClick = questTracker.toggleGps
        end
        if activeBox.miniControls.btnUntrack then
            activeBox.miniControls.btnUntrack.onClick = questTracker.clearTrackedGuide
        end
        if activeBox.miniControls.btnMiniDetails then
            activeBox.miniControls.btnMiniDetails.onClick = function()
                if activeGuide then
                    questTracker.showDetails(activeGuide)
                end
            end
        end
    end

    local emptyBox = trackerMiniWindow.contentsPanel and trackerMiniWindow.contentsPanel.emptyBox
    if emptyBox and emptyBox.btnOpenExplorer then
        emptyBox.btnOpenExplorer.onClick = questTracker.showExplorer
    end
end

local function updateTrackerMiniWindow()
    if not trackerMiniWindow then
        initTrackerMiniWindow()
    end
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
    local targetStr = 'NPC: ' .. (activeGuide.startNpc or 'Target Location') .. ' (' .. (activeGuide.city or 'Outdoors') .. ')'
    local hintStr = 'Say: "hi" > "mission" > "yes"'

    if activeGuide.steps and #activeGuide.steps > 0 then
        local s = activeGuide.steps[1]
        stepTitle = 'Step 1/' .. #activeGuide.steps .. ': ' .. (s.title or s.instruction or 'Travel to target')
        if s.npc then
            targetStr = 'NPC: ' .. s.npc .. ' (' .. (s.city or activeGuide.city or '') .. ')'
        end
    end

    if activeGuide.dialogTranscript then
        local keywords = {}
        for kw in activeGuide.dialogTranscript:gmatch('Player:%s*"(.-)"') do
            table.insert(keywords, '"' .. kw .. '"')
        end
        if #keywords > 0 then
            hintStr = 'Say: ' .. table.concat(keywords, ' > ')
        end
    end

    if activeBox.trackedTarget then activeBox.trackedTarget:setText(targetStr) end
    if activeBox.trackedStep then activeBox.trackedStep:setText(stepTitle) end
    if activeBox.trackedHint then activeBox.trackedHint:setText(hintStr) end

    local btnGps = activeBox.miniControls and activeBox.miniControls.btnToggleGps
    if btnGps then
        if isGpsActive then
            btnGps:setText('GPS: ON')
            btnGps:setColor('#00ff88')
            btnGps:setBorderColor('#00aa55')
        else
            btnGps:setText('GPS: OFF')
            btnGps:setColor('#ff5555')
            btnGps:setBorderColor('#aa3333')
        end
    end

    updateGpsDisplay()
end

function questTracker.showDetailsForActive()
    if activeGuide then
        questTracker.showDetails(activeGuide)
    end
end

function questTracker.onMiniWindowOpen()
    updateTrackerMiniWindow()
end

function questTracker.onMiniWindowClose()
end

function questTracker.setTrackedGuide(guide, enableGps)
    activeGuide = guide
    if enableGps ~= nil then
        isGpsActive = enableGps
    else
        isGpsActive = true
    end

    local targetPos = nil
    if guide then
        if guide.steps and #guide.steps > 0 then
            local s = guide.steps[1]
            targetPos = s.targetCoords or s.npcCoords or guide.coords
        else
            targetPos = guide.coords
        end
    end

    -- Update Minimap single marker
    updateMinimapMarker(targetPos, guide)

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
    updateMinimapMarker(nil, nil)

    if guideExplorerWindow and guideExplorerWindow.sidebar and guideExplorerWindow.sidebar.trackerStatusBox then
        local box = guideExplorerWindow.sidebar.trackerStatusBox
        box.activeGuideName:setText('None Selected')
        box.activeGpsStatus:setText('GPS: Disabled')
        box.activeGpsStatus:setColor('#888888')
    end
    updateTrackerMiniWindow()
    questTracker.refreshActiveCardHighlights()
end


function questTracker.stopGps()
    isGpsActive = false
    hideGpsVisuals()
    updateTrackerMiniWindow()
    questTracker.refreshActiveCardHighlights()
    if modules.game_textmessage then
        modules.game_textmessage.displayStatusMessage('[GPS Guide] Navigation stopped.')
    end
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
    local list = guideExplorerWindow.mainContent and guideExplorerWindow.mainContent.guideList
    if not list then return end

    for _, card in ipairs(list:getChildren()) do
        local btnTrack = card.actionButtons and card.actionButtons.btnTrack
        local btnGps = card.actionButtons and card.actionButtons.btnGps
        if btnTrack and card.guideData then
            if activeGuide and activeGuide.id == card.guideData.id then
                btnTrack:setText('[Tracking]')
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
local function createDetailsWindow()
    if questDetailsWindow then return end
    questDetailsWindow = g_ui.createWidget('QuestDetailsWindow', rootWidget)
    questDetailsWindow:hide()
end

function questTracker.showDetails(guide)
    if not guide then return end
    createDetailsWindow()
    if not questDetailsWindow then return end

    local ok, err = pcall(function()
        local hb = questDetailsWindow.headerBox
        if hb then
            if hb.detailTitle then hb.detailTitle:setText(guide.name or 'Quest Details') end
            if hb.detailNpcInfo then hb.detailNpcInfo:setText(string.format('Starting NPC: %s (%s)', guide.startNpc or 'NPC', guide.city or 'World')) end
            if hb.detailLevelInfo then hb.detailLevelInfo:setText(string.format('Recommended Level: %d+', guide.level or 1)) end

            -- Set visual avatar in details (Outfit, Mount, NPC or Reward Item)
            if hb.detailAvatarBox then
                local dCreature = hb.detailAvatarBox.detailCreature
                local dItem = hb.detailAvatarBox.detailItem

                if guide.creatureLookType and guide.creatureLookType > 0 and dCreature and dItem then
                    dCreature:show()
                    dCreature:setOutfit({
                        type = guide.creatureLookType,
                        head = 0, body = 114, legs = 94, feet = 114,
                        addons = guide.addons or 0
                    })
                    dItem:hide()
                elseif guide.mountClientId and guide.mountClientId > 0 and dCreature and dItem then
                    dCreature:show()
                    dCreature:setOutfit({ type = 128, mount = guide.mountClientId })
                    dItem:hide()
                elseif guide.npcLookType and guide.npcLookType > 0 and dCreature and dItem then
                    dCreature:show()
                    dCreature:setOutfit({
                        type = guide.npcLookType,
                        head = 76, body = 43, legs = 38, feet = 76,
                        addons = 0
                    })
                    dItem:hide()
                elseif guide.rewardItemId and guide.rewardItemId > 0 and dCreature and dItem then
                    dItem:show()
                    dItem:setItemId(guide.rewardItemId)
                    dCreature:hide()
                elseif dCreature and dItem then
                    dItem:show()
                    dItem:setItemId(guide.iconItem or 1988)
                    dCreature:hide()
                end
            end

            local badge = hb.detailBadge
            if badge then
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
            end
        end

        local content = questDetailsWindow.detailsContent
        if content then
            if content.loreText then
                content.loreText:setText(guide.lore or guide.description or 'No lore available.')
            end
            if content.dialogueText then
                content.dialogueText:setText(guide.dialogTranscript or 'Speak with the starting NPC to begin.')
            elseif content.dialogueBox and content.dialogueBox.dialogueText then
                content.dialogueBox.dialogueText:setText(guide.dialogTranscript or 'Speak with the starting NPC to begin.')
            end

            -- Rewards text (Clean formatting without mojibake)
            local rStr = ''
            if guide.rewards and #guide.rewards > 0 then
                for _, r in ipairs(guide.rewards) do
                    rStr = rStr .. '- ' .. (r.name or 'Reward') .. '\n'
                end
            else
                rStr = '- Quest Experience and Completion Entry in Quest Log.'
            end
            if content.rewardsText then
                content.rewardsText:setText(rStr)
            end
        end

        -- Footer buttons
        local footer = questDetailsWindow.footerPanel
        if footer then
            if footer.btnDetailTrack then
                footer.btnDetailTrack.onClick = function()
                    questTracker.setTrackedGuide(guide, false)
                    if modules.game_textmessage then
                        modules.game_textmessage.displayStatusMessage(string.format('[Quest Tracker] Now tracking: %s on your map.', guide.name))
                    end
                end
            end
            if footer.btnDetailGps then
                footer.btnDetailGps.onClick = function()
                    questTracker.setTrackedGuide(guide, true)
                    questDetailsWindow:hide()
                    if guideExplorerWindow then
                        guideExplorerWindow:hide()
                    end
                    if modules.game_textmessage then
                        modules.game_textmessage.displayStatusMessage(string.format('[GPS Guide] Navigating to %s in %s.', guide.startNpc or guide.name, guide.city or 'world'))
                    end
                end
            end
        end

        questDetailsWindow:show()
        questDetailsWindow:raise()
        questDetailsWindow:focus()
    end)

    if not ok then
        pwarning('[Quest Tracker] Error showing details: ' .. tostring(err))
    end
end

--[[=================================================
=               Guide Explorer Window               =
=================================================== ]]
local function createGuideCard(guide)
    local card = g_ui.createWidget('GuideCard')
    card.guideData = guide

    -- Set visual avatar preview (Outfit, Mount, NPC or Reward Item)
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
        card.previewBox.creaturePreview:setOutfit({ type = 128, mount = guide.mountClientId })
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
        if activeGuide and activeGuide.id == guide.id and isGpsActive then
            questTracker.stopGps()
        else
            questTracker.setTrackedGuide(guide, true)
            if guideExplorerWindow then
                guideExplorerWindow:hide()
            end
            if modules.game_textmessage then
                modules.game_textmessage.displayStatusMessage(string.format('[GPS Guide] Navigating to %s in %s.', guide.startNpc or guide.name, guide.city or 'world'))
            end
        end
    end

    card.actionButtons.btnTrack.onClick = function()
        questTracker.setTrackedGuide(guide, false)
        if modules.game_textmessage then
            modules.game_textmessage.displayStatusMessage(string.format('[Quest Tracker] Now tracking: %s.', guide.name))
        end
    end

    card.actionButtons.btnDetails.onClick = function()
        questTracker.showDetails(guide)
    end

    return card
end

local function refreshExplorerList()
    if not guideExplorerWindow then return end

    local list = guideExplorerWindow.mainContent and guideExplorerWindow.mainContent.guideList
    if not list then return end
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
    if guideExplorerWindow and guideExplorerWindow.sidebar then
        local sb = guideExplorerWindow.sidebar
        local buttons = {sb.catAll, sb.catQuest, sb.catAddon, sb.catMount, sb.catAccess}
        for _, b in ipairs(buttons) do
            if b then b:setChecked(b == btn) end
        end
    end
    refreshExplorerList()
end

local function createExplorerWindow()
    if guideExplorerWindow then return end
    guideExplorerWindow = g_ui.createWidget('GuideExplorerWindow', rootWidget)
    guideExplorerWindow:hide()

    -- Connect Explorer Search & Category Filters
    local sb = guideExplorerWindow.sidebar
    if sb then
        sb.catAll.onClick = function(b) setCategory('all', b) end
        sb.catQuest.onClick = function(b) setCategory('quest', b) end
        sb.catAddon.onClick = function(b) setCategory('addon', b) end
        sb.catMount.onClick = function(b) setCategory('mount', b) end
        sb.catAccess.onClick = function(b) setCategory('access', b) end
        if sb.trackerStatusBox then
            sb.trackerStatusBox.btnStopAllGps.onClick = questTracker.clearTrackedGuide
        end
    end

    local searchEdit = guideExplorerWindow.mainContent and guideExplorerWindow.mainContent.searchInput
    if searchEdit then
        searchEdit.onTextChange = function(w, text)
            searchQuery = text
            refreshExplorerList()
        end
    end
end

function questTracker.showExplorer()
    if not guidesDatabase or not guidesDatabase.entries or #guidesDatabase.entries == 0 then
        loadDatabase()
    end
    createExplorerWindow()
    if not guideExplorerWindow then return end
    guideExplorerWindow:show()
    guideExplorerWindow:raise()
    guideExplorerWindow:focus()
    refreshExplorerList()
end

function questTracker.toggleExplorer()
    createExplorerWindow()
    if not guideExplorerWindow then return end
    if guideExplorerWindow:isVisible() then
        guideExplorerWindow:hide()
    else
        questTracker.showExplorer()
    end
end

function questTracker.toggleMiniWindow()
    if not trackerMiniWindow then
        initTrackerMiniWindow()
    end
    if not trackerMiniWindow then return end
    if trackerMiniWindow:isVisible() then
        trackerMiniWindow:hide()
    else
        trackerMiniWindow:show()
    end
end

local function ensureMainPanelButton()
    if mainPanelButton then return end

    if modules.client_topmenu and modules.client_topmenu.addLeftGameButton then
        mainPanelButton = modules.client_topmenu.addLeftGameButton(
            'questTrackerMainBtn',
            tr('Quest & GPS Tracker'),
            '/images/options/button_questlog_tracker',
            function() questTracker.toggleExplorer() end
        )
    elseif modules.game_mainpanel and modules.game_mainpanel.addSpecialToggleButton then
        mainPanelButton = modules.game_mainpanel.addSpecialToggleButton(
            'questTrackerMainBtn',
            tr('Quest & GPS Tracker'),
            '/images/options/button_questlog_tracker',
            function() questTracker.toggleExplorer() end,
            false
        )
    end
end

--[[=================================================
=                Module Lifecycle                   =
=================================================== ]]
function init()
    g_ui.importStyle('questtracker.otui')
    loadDatabase()

    -- Try to add button during init or shortly after mainpanel loads
    scheduleEvent(function()
        ensureMainPanelButton()
    end, 150)

    -- Global hotkey Ctrl+U to show/hide Quest Tracker
    pcall(function()
        Keybind.new("Windows", "Show/hide Quest Tracker", "Ctrl+U", "")
        Keybind.bind("Windows", "Show/hide Quest Tracker", {{
            type = KEY_DOWN,
            callback = function()
                questTracker.toggleExplorer()
            end
        }})
    end)

    -- Register LocalPlayer position event for real-time GPS update
    connect(LocalPlayer, {
        onPositionChange = function()
            if isGpsActive then
                updateGpsDisplay()
            end
        end
    })

    -- Periodic GPS update timer
    gpsTimer = cycleEvent(function()
        if isGpsActive then
            updateGpsDisplay()
        end
    end, 400)

    connect(g_game, {
        onGameStart = function()
            initGpsOverlay()
            initTrackerMiniWindow()
            ensureMainPanelButton()
            updateTrackerMiniWindow()
        end,
        onGameEnd = function()
            hideGpsVisuals()
            updateMinimapMarker(nil, nil)
            if trackerMiniWindow then
                trackerMiniWindow:destroy()
                trackerMiniWindow = nil
            end
        end
    })

    -- If already online (e.g. reload), initialize immediately
    if g_game.isOnline() then
        initGpsOverlay()
        initTrackerMiniWindow()
        ensureMainPanelButton()
        updateTrackerMiniWindow()
    end
end

function terminate()
    if gpsTimer then
        removeEvent(gpsTimer)
        gpsTimer = nil
    end

    hideGpsVisuals()
    updateMinimapMarker(nil, nil)

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

-- Export module functions
for k, v in pairs(questTracker) do
    if modules.game_questtracker then
        modules.game_questtracker[k] = v
    end
end
if modules.game_questtracker then
    modules.game_questtracker.showDetailsForActive = questTracker.showDetailsForActive
    modules.game_questtracker.showDetails = questTracker.showDetails
    modules.game_questtracker.clearTrackedGuide = questTracker.clearTrackedGuide
    modules.game_questtracker.showExplorer = questTracker.showExplorer
    modules.game_questtracker.toggleExplorer = questTracker.toggleExplorer
    modules.game_questtracker.toggleGps = questTracker.toggleGps
    modules.game_questtracker.stopGps = questTracker.stopGps
end
_G.questTracker = questTracker