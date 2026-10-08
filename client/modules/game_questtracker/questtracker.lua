--[[
  Universal Quest, Addon & Mount Walkthrough Guide
  100% Native CipSoft / Cyclopedia Map Design
  Exura OT Server - Client Redemption
]]

g_ui.importStyle('questtracker')

questTracker = {}

local trackerMiniWindow = nil
local guideExplorerWindow = nil
local questWalkthroughWindow = nil
local mainPanelButton = nil

local guidesDatabase = {}
local activeGuide = nil
local walkthroughGuide = nil
local currentWalkthroughStep = 1

local currentCategory = 'all'
local searchQuery = ''

-- Comprehensive NPC outfit mappings (LookTypes)
local NPC_OUTFIT_MAP = {
    ['kevin'] = 128,
    ['kroox'] = 160,
    ['henricus'] = 132,
    ['markwin'] = 25,
    ['luboo'] = 128,
    ['hanna'] = 136,
    ['elane'] = 137,
    ['gregor'] = 131,
    ['marvik'] = 144,
    ['lynda'] = 138,
    ['chester kahs'] = 131,
    ['quentin'] = 133,
    ['gorn'] = 128,
    ['avar tar'] = 131,
    ['jack fate'] = 128,
    ['eremo'] = 130,
    ['bozo'] = 273,
    ['hrodmir'] = 143,
    ['charlotta'] = 138,
    ['eleonore'] = 140,
    ['palimuth'] = 324,
    ['maelyrra'] = 144,
    ['melchior'] = 153,
    ['pemaret'] = 128,
    ['captain bluebear'] = 134,
    ['captain fearless'] = 134,
    ['sam'] = 131,
    ['xodet'] = 130,
    ['frodo'] = 128,
    ['king tibianus'] = 332,
    ['queen eloise'] = 331,
    ['emperor kruzak'] = 66,
    ['central temple'] = 133
}

-- Monster outfit mappings
local MONSTER_OUTFIT_MAP = {
    ['demon'] = 35,
    ['banshee'] = 78,
    ['the queen of the banshees'] = 78,
    ['dragon'] = 34,
    ['dragon lord'] = 39,
    ['behemoth'] = 55,
    ['giant spider'] = 38,
    ['warlock'] = 130,
    ['hero cave lever'] = 35,
    ['blue djinn'] = 80,
    ['green djinn'] = 51,
    ['marid'] = 80,
    ['efreet'] = 51
}

-- Direction helper
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

    if not guidesDatabase.entries or #guidesDatabase.entries == 0 then
        guidesDatabase = {
            categories = {
                { id = 'all', name = 'All Guides' },
                { id = 'quest', name = 'Main Quests' },
                { id = 'addon', name = 'Outfits & Addons' },
                { id = 'mount', name = 'Mounts' },
                { id = 'access', name = 'Access & Gates' }
            },
            entries = {}
        }
    end
end

--[[=================================================
=           Visual Resolution & Helper              =
=================================================== ]]
local function getGuideVisual(guide, step)
    if not guide then return { type = 'item', itemId = 2815 } end

    -- 1. Check step specific NPC / creature
    if step then
        if step.npcLookType and step.npcLookType > 0 then
            return { type = 'creature', lookType = step.npcLookType, addons = step.addons or 0 }
        elseif step.creatureLookType and step.creatureLookType > 0 then
            return { type = 'creature', lookType = step.creatureLookType, addons = step.addons or 0 }
        elseif step.npc then
            local n = string.lower(step.npc)
            if NPC_OUTFIT_MAP[n] then
                return { type = 'creature', lookType = NPC_OUTFIT_MAP[n], addons = 0 }
            elseif MONSTER_OUTFIT_MAP[n] then
                return { type = 'creature', lookType = MONSTER_OUTFIT_MAP[n], addons = 0 }
            end
        end
    end

    -- 2. Check guide level lookTypes
    if guide.creatureLookType and guide.creatureLookType > 0 then
        return { type = 'creature', lookType = guide.creatureLookType, addons = guide.addons or 0 }
    elseif guide.npcLookType and guide.npcLookType > 0 then
        return { type = 'creature', lookType = guide.npcLookType, addons = guide.addons or 0 }
    elseif guide.startNpc then
        local n = string.lower(guide.startNpc)
        if NPC_OUTFIT_MAP[n] then
            return { type = 'creature', lookType = NPC_OUTFIT_MAP[n], addons = 0 }
        elseif MONSTER_OUTFIT_MAP[n] then
            return { type = 'creature', lookType = MONSTER_OUTFIT_MAP[n], addons = 0 }
        end
    end

    -- 3. Check guide items (ensure NEVER wooden painting 2596)
    if guide.rewardItemId and guide.rewardItemId > 0 and guide.rewardItemId ~= 2596 then
        return { type = 'item', itemId = guide.rewardItemId }
    elseif guide.requiredItems and #guide.requiredItems > 0 and guide.requiredItems[1].id and guide.requiredItems[1].id ~= 2596 then
        return { type = 'item', itemId = guide.requiredItems[1].id }
    elseif guide.iconItem and guide.iconItem > 0 and guide.iconItem ~= 1988 and guide.iconItem ~= 2596 then
        return { type = 'item', itemId = guide.iconItem }
    end

    -- 4. Category-based robust fallbacks
    if guide.category == 'mount' then
        return { type = 'creature', lookType = 388, addons = 0 }
    elseif guide.category == 'addon' then
        return { type = 'creature', lookType = 128, addons = 3 }
    elseif guide.category == 'access' then
        return { type = 'creature', lookType = 131, addons = 0 }
    elseif guide.category == 'quest' then
        return { type = 'creature', lookType = 128, addons = 0 }
    end

    return { type = 'item', itemId = 2815 } -- Classic scroll
end

local function applyVisualToWidgets(creatureWidget, itemWidget, visual)
    if not creatureWidget or not itemWidget then return end

    if visual.type == 'creature' then
        creatureWidget:setOutfit({
            type = visual.lookType,
            addons = visual.addons or 0,
            head = 0, body = 0, legs = 0, feet = 0
        })
        creatureWidget:show()
        itemWidget:hide()
    else
        itemWidget:setItemId(visual.itemId or 2815)
        itemWidget:show()
        creatureWidget:hide()
    end
end

--[[=================================================
=         Authentic Tibia Item Look Tooltip         =
=================================================== ]]
function questTracker.formatItemLook(itemId, count, customName)
    local thing = g_things.getThingType(itemId, ThingCategoryItem)
    local itemName = customName or (thing and thing.getName and thing:getName()) or "item"
    local countStr = ""
    if count and count > 1 then
        countStr = string.format(" (%dx)", count)
    end
    local lines = {}
    table.insert(lines, string.format("You see %s%s (Item ID: %d).", itemName, countStr, itemId))

    pcall(function()
        local item = Item.create(itemId)
        if item then
            if item.getDescription then
                local desc = item:getDescription()
                if desc and #desc > 0 then
                    table.insert(lines, desc)
                end
            end
            if item.getWeight then
                local w = item:getWeight()
                if w and w > 0 then
                    table.insert(lines, string.format("It weighs %.2f oz.", w / 100))
                end
            end
        end
    end)

    return table.concat(lines, "\n")
end

--[[=================================================
=             Cyclopedia Map Integration            =
=================================================== ]]
function questTracker.markOnMap(coords, description)
    if not coords or not coords.x or not coords.y then return end

    local flagDesc = description or "Quest Objective"

    -- 1. Add flag to main minimap
    if modules.game_minimap and modules.game_minimap.addFlag then
        pcall(function() modules.game_minimap.addFlag(coords, 4, flagDesc) end)
    end

    -- 2. Open Cyclopedia Map tab and center on coords
    if modules.game_cyclopedia and modules.game_cyclopedia.Cyclopedia then
        pcall(function()
            modules.game_cyclopedia.Cyclopedia.showMapAt(coords, flagDesc)
        end)
    end

    -- Sound feedback
    pcall(function()
        if g_resources.fileExists("/sounds/click.ogg") and g_sounds then
            local ch = g_sounds.getChannel(SoundChannels.Interface)
            if ch then ch:play("/sounds/click.ogg", 0.5) end
        end
    end)
end

--[[=================================================
=            Walkthrough Window (Step Carousel)     =
=================================================== ]]
local function createWalkthroughWindow()
    if questWalkthroughWindow then return end

    questWalkthroughWindow = g_ui.createWidget('QuestWalkthroughWindow', rootWidget)
    questWalkthroughWindow:hide()

    local p = questWalkthroughWindow

    -- Step carousel navigation
    p.stepNavBar.prevStepBtn.onClick = function()
        questTracker.navigateWalkthroughStep(-1)
    end
    p.stepNavBar.nextStepBtn.onClick = function()
        questTracker.navigateWalkthroughStep(1)
    end
    p.footerPanel.btnPrevStepBottom.onClick = function()
        questTracker.navigateWalkthroughStep(-1)
    end
    p.footerPanel.btnNextStepBottom.onClick = function()
        questTracker.navigateWalkthroughStep(1)
    end
end

function questTracker.showWalkthrough(guide, initialStep)
    if not guide then return end
    createWalkthroughWindow()

    walkthroughGuide = guide
    currentWalkthroughStep = initialStep or 1

    local p = questWalkthroughWindow
    p:show()
    p:raise()
    p:focus()

    -- Setup Header
    p.headerBox.detailTitle:setText(guide.name or 'Quest Guide')
    local sub = string.format('%s  |  %s', string.upper(guide.category or 'Quest'), guide.city or 'Worldwide')
    p.headerBox.detailSubtitle:setText(sub)

    -- Avatar in header
    local vis = getGuideVisual(guide)
    applyVisualToWidgets(p.headerBox.detailAvatarBox.detailCreature, p.headerBox.detailAvatarBox.detailItem, vis)

    questTracker.updateWalkthroughDisplay()
end

function questTracker.navigateWalkthroughStep(delta)
    if not walkthroughGuide or not walkthroughGuide.steps then return end
    local total = #walkthroughGuide.steps
    if total <= 0 then return end

    local newStep = currentWalkthroughStep + delta
    if newStep < 1 then newStep = 1 end
    if newStep > total then newStep = total end

    if newStep ~= currentWalkthroughStep then
        currentWalkthroughStep = newStep
        questTracker.updateWalkthroughDisplay()
    end
end

function questTracker.updateWalkthroughDisplay()
    if not questWalkthroughWindow or not walkthroughGuide then return end
    local p = questWalkthroughWindow

    local steps = walkthroughGuide.steps or {}
    local totalSteps = #steps
    if totalSteps == 0 then
        steps = {
            {
                step = 1,
                title = walkthroughGuide.name,
                instruction = walkthroughGuide.description or walkthroughGuide.lore or 'Follow the instructions to complete this quest.',
                npc = walkthroughGuide.startNpc,
                city = walkthroughGuide.city,
                targetCoords = walkthroughGuide.coords
            }
        }
        totalSteps = 1
    end

    if currentWalkthroughStep > totalSteps then currentWalkthroughStep = totalSteps end
    if currentWalkthroughStep < 1 then currentWalkthroughStep = 1 end

    local st = steps[currentWalkthroughStep]

    -- 1. Update Carousel Navigation Bar
    p.stepNavBar.stepProgressLabel:setText(string.format('%d / %d', currentWalkthroughStep, totalSteps))
    p.stepNavBar.prevStepBtn:setEnabled(currentWalkthroughStep > 1)
    p.stepNavBar.nextStepBtn:setEnabled(currentWalkthroughStep < totalSteps)
    p.footerPanel.btnPrevStepBottom:setEnabled(currentWalkthroughStep > 1)
    p.footerPanel.btnNextStepBottom:setEnabled(currentWalkthroughStep < totalSteps)

    -- Clean step title without repeating "Step X: Mission X:"
    local rawTitle = st.title or ('Step ' .. currentWalkthroughStep)
    local lTitle = string.lower(rawTitle)
    if string.find(lTitle, '^step') or string.find(lTitle, '^mission') or string.find(lTitle, '^trial') then
        p.stepTitleLabel:setText(rawTitle)
    else
        p.stepTitleLabel:setText(string.format('Step %d: %s', currentWalkthroughStep, rawTitle))
    end

    -- 2. Step Target Box
    local targetCoords = st.targetCoords or st.npcCoords or walkthroughGuide.coords
    local npcName = st.npc or walkthroughGuide.startNpc
    if npcName and #npcName > 0 then
        p.stepContentPanel.stepTargetBox.stepNpcLabel:setText('Target: ' .. npcName)
    else
        p.stepContentPanel.stepTargetBox.stepNpcLabel:setText('Objective Location')
    end

    local locStr = string.format('%s (%d, %d, %d)', st.city or walkthroughGuide.city or 'Tibia', targetCoords.x or 0, targetCoords.y or 0, targetCoords.z or 7)
    p.stepContentPanel.stepTargetBox.stepLocationLabel:setText(locStr)

    -- Step visual icon (creature or item)
    local stepVis = getGuideVisual(walkthroughGuide, st)
    applyVisualToWidgets(p.stepContentPanel.stepTargetBox.stepCreatureBox.stepCreature, p.stepContentPanel.stepTargetBox.stepCreatureBox.stepItem, stepVis)

    -- Button [Mark on Map] on this step
    p.stepContentPanel.stepTargetBox.btnStepMarkMap.onClick = function()
        questTracker.markOnMap(targetCoords, walkthroughGuide.name .. ' - ' .. rawTitle)
    end

    -- 3. Step Instructions
    local instr = st.instruction or st.description or walkthroughGuide.description or 'No instructions provided.'
    p.stepContentPanel.stepInstructionText:setText(instr)

    -- 4. Dialogue Transcript
    local dialog = st.dialogTranscript or (currentWalkthroughStep == 1 and walkthroughGuide.dialogTranscript)
    if dialog and #dialog > 0 then
        p.stepContentPanel.dialogueHeader:show()
        p.stepContentPanel.stepDialogueText:setText(dialog)
        p.stepContentPanel.stepDialogueText:show()
    else
        p.stepContentPanel.dialogueHeader:hide()
        p.stepContentPanel.stepDialogueText:hide()
    end

    -- 5. Rewards & Unlocks Panel (Bottom)
    p.rewardsBox.rewardItemsContainer:destroyChildren()

    local hasOutfit = false
    if walkthroughGuide.creatureLookType and walkthroughGuide.creatureLookType > 0 and (walkthroughGuide.category == 'addon' or walkthroughGuide.category == 'mount' or walkthroughGuide.category == 'quest') then
        p.rewardsBox.rewardOutfitBox:show()
        p.rewardsBox.rewardOutfitBox.rewardCreature:setOutfit({
            type = walkthroughGuide.creatureLookType,
            addons = walkthroughGuide.addons or 3,
            head = 0, body = 0, legs = 0, feet = 0
        })
        hasOutfit = true
    else
        p.rewardsBox.rewardOutfitBox:hide()
    end

    -- Item slots with Look Tooltip
    local itemsToShow = {}
    if walkthroughGuide.rewards then
        for _, rew in ipairs(walkthroughGuide.rewards) do
            if rew.id and rew.id > 0 and rew.id ~= 2596 then
                table.insert(itemsToShow, { id = rew.id, count = rew.count or 1, name = rew.name })
            end
        end
    end
    if #itemsToShow == 0 and walkthroughGuide.rewardItemId and walkthroughGuide.rewardItemId > 0 and walkthroughGuide.rewardItemId ~= 2596 then
        table.insert(itemsToShow, { id = walkthroughGuide.rewardItemId, count = 1, name = walkthroughGuide.name })
    end
    if #itemsToShow == 0 and walkthroughGuide.requiredItems then
        for i = 1, math.min(3, #walkthroughGuide.requiredItems) do
            local req = walkthroughGuide.requiredItems[i]
            if req.id and req.id ~= 2596 then
                table.insert(itemsToShow, { id = req.id, count = req.count or 1, name = req.name })
            end
        end
    end

    for _, it in ipairs(itemsToShow) do
        local slot = g_ui.createWidget('WalkthroughItemSlot', p.rewardsBox.rewardItemsContainer)
        slot:setItemId(it.id)
        if it.count and it.count > 1 then
            slot.countLabel:setText(tostring(it.count))
            slot.countLabel:show()
        else
            slot.countLabel:hide()
        end
        local tip = questTracker.formatItemLook(it.id, it.count, it.name)
        slot:setTooltip(tip)
    end

    -- Rewards summary text
    local rewDesc = {}
    if walkthroughGuide.rewards then
        for _, rew in ipairs(walkthroughGuide.rewards) do
            table.insert(rewDesc, rew.name or ('Item ' .. rew.id))
        end
    end
    if #rewDesc > 0 then
        p.rewardsBox.rewardsSummaryText:setText(table.concat(rewDesc, '  |  '))
    else
        p.rewardsBox.rewardsSummaryText:setText(walkthroughGuide.description or 'Quest progression & unlocks.')
    end
end

--[[=================================================
=            Explorer Window & Card Rendering       =
=================================================== ]]
local function createGuideCard(guide)
    local card = g_ui.createWidget('GuideCard', guideExplorerWindow.cardsContainer)
    card:setId(guide.id)

    card.name:setText(guide.name or 'Guide')

    local catBadge = string.upper(guide.category or 'QUEST')
    card.categoryBadge:setText(catBadge)

    local locText = string.format('City: %s  |  Level: %d+', guide.city or 'Worldwide', guide.level or 1)
    if guide.startNpc then
        locText = locText .. string.format('  |  NPC: %s', guide.startNpc)
    end
    card.npcInfo:setText(locText)

    local desc = guide.description or ''
    if #desc > 75 then desc = string.sub(desc, 1, 72) .. '...' end
    card.details:setText(desc)

    -- Avatar setup
    local vis = getGuideVisual(guide)
    applyVisualToWidgets(card.previewBox.creaturePreview, card.previewBox.itemPreview, vis)

    -- Action Button 1: [Walkthrough]
    card.actionButtons.btnWalkthrough.onClick = function()
        questTracker.showWalkthrough(guide, 1)
    end

    -- Action Button 2: [Mark on Map]
    card.actionButtons.btnMarkMap.onClick = function()
        local coords = guide.coords
        if guide.steps and guide.steps[1] then
            coords = guide.steps[1].targetCoords or guide.steps[1].npcCoords or coords
        end
        questTracker.markOnMap(coords, guide.name)
    end

    return card
end

local function refreshExplorerList()
    if not guideExplorerWindow then return end

    local container = guideExplorerWindow.cardsContainer
    container:destroyChildren()

    local entries = guidesDatabase.entries or {}
    local count = 0

    local query = string.lower(searchQuery or '')

    for _, guide in ipairs(entries) do
        local matchCategory = (currentCategory == 'all') or (guide.category == currentCategory)
        local matchSearch = true

        if #query > 0 then
            local n = string.lower(guide.name or '')
            local d = string.lower(guide.description or '')
            local c = string.lower(guide.city or '')
            local npc = string.lower(guide.startNpc or '')
            matchSearch = string.find(n, query, 1, true) or
                          string.find(d, query, 1, true) or
                          string.find(c, query, 1, true) or
                          string.find(npc, query, 1, true)
        end

        if matchCategory and matchSearch then
            createGuideCard(guide)
            count = count + 1
        end
    end

    guideExplorerWindow.footerPanel.countLabel:setText(string.format('Displaying %d guides.', count))
end

local function setCategory(cat, btn)
    currentCategory = cat
    local sb = guideExplorerWindow.sidebar
    sb.catAll:setChecked(false)
    sb.catQuest:setChecked(false)
    sb.catAddon:setChecked(false)
    sb.catMount:setChecked(false)
    sb.catAccess:setChecked(false)
    if btn then btn:setChecked(true) end
    refreshExplorerList()
end

local function createExplorerWindow()
    if guideExplorerWindow then return end

    guideExplorerWindow = g_ui.createWidget('GuideExplorerWindow', rootWidget)
    guideExplorerWindow:hide()

    local sb = guideExplorerWindow.sidebar
    sb.catAll.onClick = function(b) setCategory('all', b) end
    sb.catQuest.onClick = function(b) setCategory('quest', b) end
    sb.catAddon.onClick = function(b) setCategory('addon', b) end
    sb.catMount.onClick = function(b) setCategory('mount', b) end
    sb.catAccess.onClick = function(b) setCategory('access', b) end

    local searchEdit = guideExplorerWindow.searchPanel.searchEdit
    searchEdit.onTextChange = function(w, text)
        searchQuery = text
        refreshExplorerList()
    end
end

function questTracker.showExplorer()
    createExplorerWindow()
    guideExplorerWindow:show()
    guideExplorerWindow:raise()
    guideExplorerWindow:focus()
    refreshExplorerList()
end

function questTracker.toggleExplorer()
    if guideExplorerWindow and guideExplorerWindow:isVisible() then
        guideExplorerWindow:hide()
    else
        questTracker.showExplorer()
    end
end

--[[=================================================
=             MiniWindow (Lateral HUD Pinned)       =
=================================================== ]]
local function initTrackerMiniWindow()
    if trackerMiniWindow then return end
    if not g_game.isOnline() then return end
    if not modules.game_interface or not modules.game_interface.getRightPanel then return end
    local rightPanel = modules.game_interface.getRightPanel()
    if not rightPanel then return end

    trackerMiniWindow = g_ui.createWidget('QuestTrackerMiniWindow', rightPanel)
    trackerMiniWindow:setup()

    local ab = trackerMiniWindow.contentsPanel.activeBox
    ab.miniControls.btnMiniDetails.onClick = function()
        if activeGuide then
            questTracker.showWalkthrough(activeGuide, 1)
        end
    end
    ab.miniControls.btnMiniMap.onClick = function()
        if activeGuide then
            local coords = activeGuide.coords
            if activeGuide.steps and activeGuide.steps[1] then
                coords = activeGuide.steps[1].targetCoords or activeGuide.steps[1].npcCoords or coords
            end
            questTracker.markOnMap(coords, activeGuide.name)
        end
    end
end

local function updateTrackerMiniWindow()
    if not trackerMiniWindow then end
    if not trackerMiniWindow then return end

    local contents = trackerMiniWindow.contentsPanel
    if not contents then return end

    if not activeGuide then
        contents.emptyBox:show()
        contents.activeBox:hide()
        return
    end

    contents.emptyBox:hide()
    contents.activeBox:show()

    local ab = contents.activeBox
    ab.trackedTitle:setText(activeGuide.name or 'Active Mission')
    ab.trackedCity:setText(string.format('%s  |  %s', string.upper(activeGuide.category or 'QUEST'), activeGuide.city or 'Worldwide'))

    local targetStr = 'Target: ' .. (activeGuide.startNpc or 'Objective')
    if activeGuide.steps and activeGuide.steps[1] and activeGuide.steps[1].npc then
        targetStr = 'Target: ' .. activeGuide.steps[1].npc
    end
    ab.trackedTarget:setText(targetStr)

    local stepStr = activeGuide.description or ''
    if activeGuide.steps and activeGuide.steps[1] and activeGuide.steps[1].instruction then
        stepStr = activeGuide.steps[1].instruction
    end
    if #stepStr > 65 then stepStr = string.sub(stepStr, 1, 62) .. '...' end
    ab.trackedStep:setText(stepStr)
end

function questTracker.setTrackedGuide(guide)
    activeGuide = guide
    if not trackerMiniWindow then
        initTrackerMiniWindow()
    end
    updateTrackerMiniWindow()
    if trackerMiniWindow then
        trackerMiniWindow:open()
    end
end

function questTracker.toggleMiniWindow()
    if not trackerMiniWindow then
        initTrackerMiniWindow()
    end
    if trackerMiniWindow then
        if trackerMiniWindow:isVisible() then
            trackerMiniWindow:close()
        else
            trackerMiniWindow:open()
        end
    end
end

function questTracker.onMiniWindowOpen()
    updateTrackerMiniWindow()
end

function questTracker.onMiniWindowClose()
end

--[[=================================================
=             Main Panel Toggle Button              =
=================================================== ]]
local function ensureMainPanelButton()
    if mainPanelButton then return end
    if modules.game_mainpanel then
        mainPanelButton = modules.game_mainpanel.addToggleButton(
            'questTrackerButton',
            tr('Quests & Walkthrough Guides'),
            '/images/topbuttons/icon-questtracker-widget',
            function() questTracker.toggleExplorer() end,
            false,
            6
        )
    end
end

--[[=================================================
=            Module Lifecycle Hooks                 =
=================================================== ]]
function init()
    loadDatabase()

    scheduleEvent(function()
        ensureMainPanelButton()
    end, 500)

    connect(g_game, {
        onGameStart = function()
            ensureMainPanelButton()
            initTrackerMiniWindow()
            updateTrackerMiniWindow()
        end,
        onGameEnd = function()
            if guideExplorerWindow then guideExplorerWindow:hide() end
            if questWalkthroughWindow then questWalkthroughWindow:hide() end
            activeGuide = nil
            updateTrackerMiniWindow()
        end
    })
end

function terminate()
    disconnect(g_game, {
        onGameStart = function() end,
        onGameEnd = function() end
    })

    if trackerMiniWindow then
        trackerMiniWindow:destroy()
        trackerMiniWindow = nil
    end

    if guideExplorerWindow then
        guideExplorerWindow:destroy()
        guideExplorerWindow = nil
    end

    if questWalkthroughWindow then
        questWalkthroughWindow:destroy()
        questWalkthroughWindow = nil
    end
end