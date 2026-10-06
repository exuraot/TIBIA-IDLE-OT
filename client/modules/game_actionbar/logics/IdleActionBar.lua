local KNOWN_POTIONS_AND_RUNES = {
    -- Potions
    { id = 7876, name = "Small Health Potion", cost = 20, resource = "HP", percent = 80, offensive = false, cat = "Potions" },
    { id = 266, name = "Health Potion", cost = 50, resource = "HP", percent = 70, offensive = false, cat = "Potions" },
    { id = 236, name = "Strong Health Potion", cost = 115, resource = "HP", percent = 60, offensive = false, cat = "Potions" },
    { id = 239, name = "Great Health Potion", cost = 225, resource = "HP", percent = 50, offensive = false, cat = "Potions" },
    { id = 7643, name = "Ultimate Health Potion", cost = 379, resource = "HP", percent = 40, offensive = false, cat = "Potions" },
    { id = 23375, name = "Supreme Health Potion", cost = 650, resource = "HP", percent = 35, offensive = false, cat = "Potions" },
    { id = 268, name = "Mana Potion", cost = 56, resource = "MP", percent = 60, offensive = false, cat = "Potions" },
    { id = 237, name = "Strong Mana Potion", cost = 108, resource = "MP", percent = 50, offensive = false, cat = "Potions" },
    { id = 238, name = "Great Mana Potion", cost = 158, resource = "MP", percent = 40, offensive = false, cat = "Potions" },
    { id = 23373, name = "Ultimate Mana Potion", cost = 488, resource = "MP", percent = 35, offensive = false, cat = "Potions" },
    { id = 7642, name = "Great Spirit Potion", cost = 254, resource = "HP", percent = 50, offensive = false, cat = "Potions" },
    { id = 23374, name = "Ultimate Spirit Potion", cost = 488, resource = "HP", percent = 40, offensive = false, cat = "Potions" },

    -- Offensive Runes
    { id = 3155, name = "Sudden Death Rune", cost = 162, resource = "MP", percent = 30, offensive = true, cat = "Runes" },
    { id = 3191, name = "Great Fireball Rune", cost = 64, resource = "MP", percent = 30, offensive = true, cat = "Runes" },
    { id = 3161, name = "Avalanche Rune", cost = 64, resource = "MP", percent = 30, offensive = true, cat = "Runes" },
    { id = 3175, name = "Stone Shower Rune", cost = 41, resource = "MP", percent = 30, offensive = true, cat = "Runes" },
    { id = 3202, name = "Thunderstorm Rune", cost = 52, resource = "MP", percent = 30, offensive = true, cat = "Runes" },
    { id = 3198, name = "Heavy Magic Missile", cost = 65, resource = "MP", percent = 20, offensive = true, cat = "Runes" },
    { id = 3174, name = "Light Magic Missile", cost = 4, resource = "MP", percent = 20, offensive = true, cat = "Runes" },
    { id = 3200, name = "Explosion Rune", cost = 31, resource = "MP", percent = 30, offensive = true, cat = "Runes" }
}

modules.game_actionbar.isIdleMode = false
local idleHotkeysCache = nil

local function getSavedIdleHotkeys()
    if not idleHotkeysCache then
        idleHotkeysCache = g_settings.getNode('idle_action_bar_hotkeys') or {}
    end
    return idleHotkeysCache
end

local function saveIdleHotkeys()
    if idleHotkeysCache then
        g_settings.setNode('idle_action_bar_hotkeys', idleHotkeysCache)
        g_settings.save()
    end
end

function modules.game_actionbar.getIdleHotkeys()
    local list = {}
    local data = getSavedIdleHotkeys()
    for slotId, conf in pairs(data) do
        if conf and (conf.type == "spell" or conf.type == "object") then
            conf.slotId = slotId
            table.insert(list, conf)
        end
    end
    return list
end

function modules.game_actionbar.toggleIdleMode()
    modules.game_actionbar.isIdleMode = not modules.game_actionbar.isIdleMode
    local isIdle = modules.game_actionbar.isIdleMode

    for _, ab in pairs(activeActionBars or {}) do
        if ab.idleModeButton then
            ab.idleModeButton:setOn(isIdle)
        end
    end

    if isIdle then
        if modules.game_textmessage and modules.game_textmessage.displayStatusMessage then
            modules.game_textmessage.displayStatusMessage("[IDLE Hotkeys ON] Editing IDLE Tactical Hotkeys. Right-click any slot to configure.")
        end
    else
        if modules.game_textmessage and modules.game_textmessage.displayStatusMessage then
            modules.game_textmessage.displayStatusMessage("[IDLE Hotkeys OFF] Normal Hotkeys restored.")
        end
    end

    modules.game_actionbar.refreshActionBarDisplay()
end

function modules.game_actionbar.renderIdleButton(button)
    if not button then return end
    local slotId = button:getId()
    local idleData = getSavedIdleHotkeys()
    local conf = idleData[slotId]

    -- 1. Apply Green Glowing Border
    if button.activeSpell then
        button.activeSpell:setVisible(true)
        button.activeSpell:setImageColor('#00ff88')
    end

    -- 2. Clean normal hotkey elements completely
    if button.multiIcon then
        button.multiIcon:setVisible(false)
    end
    if button.item and button.item.gray then
        button.item.gray:setVisible(false)
    end
    if button.item and button.item.text and button.item.text.gray then
        button.item.text.gray:setVisible(false)
    end
    if button.item then
        button.item:setDisplayCount(0)
        button.item:setOn(false)
    end

    if conf then
        if conf.type == "spell" then
            if button.item then
                button.item:setItemId(0)
            end
            local spellData = nil
            if Spells and Spells.getSpellDataByParamWords and conf.words then
                spellData = Spells.getSpellDataByParamWords(conf.words:lower())
            end
            if spellData and spellData.clientId and Spells and Spells.getImageClip and SpelllistSettings and SpelllistSettings['Default'] then
                local source = SpelllistSettings['Default'].iconFile
                local clip = Spells.getImageClip(spellData.clientId, 'Default')
                button.item.text:setImageSource(source)
                button.item.text:setImageClip(clip)
                button.item.text:setText("")
            else
                button.item.text:setImageSource("")
                button.item.text:setText(conf.words or conf.spellName or "")
            end

            local op = conf.operator or (conf.offensive and ">=" or "<=")
            local displayTxt = ""
            if conf.resource == "Combat" or conf.resource == "Always" or conf.resource == "In Combat" then
                displayTxt = "COMBAT"
            else
                displayTxt = string.format("%s%s%d%%", conf.resource, op, conf.percent)
            end

            if button.parameterText then
                button.parameterText:setText(displayTxt)
                button.parameterText:setColor('#00ff88')
                button.parameterText:setVisible(true)
            end
            button:setTooltip(string.format("IDLE Spell: %s (%s)\nTrigger: %s\nCooldown: %.1fs\nRight-click to edit", conf.spellName, conf.words, displayTxt, (conf.cooldown or 1000) / 1000))
        elseif conf.type == "object" then
            if button.item.text then
                button.item.text:setImageSource("")
                button.item.text:setText("")
            end
            if button.item then
                button.item:setItemId(conf.itemId)
            end
            local op = conf.operator or (conf.offensive and ">=" or "<=")
            local displayTxt = string.format("%s%s%d%%", conf.resource, op, conf.percent)
            if button.parameterText then
                button.parameterText:setText(displayTxt)
                button.parameterText:setColor('#00ddff')
                button.parameterText:setVisible(true)
            end
            button:setTooltip(string.format("IDLE Object: %s\nCost: ~%d gp / use\nTrigger: %s\nRight-click to edit", conf.name, conf.cost or 0, displayTxt))
        end
    else
        -- Empty slot in IDLE mode: MUST NOT show any normal hotkeys!
        if button.item then
            button.item:setItemId(0)
        end
        if button.item and button.item.text then
            button.item.text:setImageSource("")
            button.item.text:setText("")
        end
        if button.parameterText then
            button.parameterText:setText("")
            button.parameterText:setVisible(false)
        end
        button:setTooltip("IDLE Slot (Empty)\nRight-click to assign an IDLE Spell or Object")
    end
end

function modules.game_actionbar.refreshActionBarDisplay()
    local isIdle = modules.game_actionbar.isIdleMode

    for _, ab in pairs(activeActionBars or {}) do
        if ab.tabBar then
            for _, btn in pairs(ab.tabBar:getChildren()) do
                if isIdle then
                    modules.game_actionbar.renderIdleButton(btn)
                else
                    -- Normal Mode: Hide IDLE glow and completely restore normal hotkeys
                    if btn.activeSpell then
                        btn.activeSpell:setVisible(false)
                    end
                    if btn.parameterText then
                        btn.parameterText:setText("")
                        btn.parameterText:setVisible(false)
                    end
                    if btn.item and btn.item.text then
                        btn.item.text:setImageSource("")
                        btn.item.text:setText("")
                    end
                    updateButton(btn)
                end
            end
        end
    end
end

function modules.game_actionbar.clearIdleSlot(button)
    local slotId = button:getId()
    local idleData = getSavedIdleHotkeys()
    idleData[slotId] = nil
    saveIdleHotkeys()
    modules.game_actionbar.refreshActionBarDisplay()
    if modules.game_textmessage and modules.game_textmessage.displayStatusMessage then
        modules.game_textmessage.displayStatusMessage(string.format("Cleared IDLE slot %s.", slotId))
    end
end

-- =============================================================
-- Open Assign Spell (IDLE) Modal - Exact match to native CipSoft UI
-- =============================================================
function modules.game_actionbar.openIdleSpellWindow(button)
    local win = g_ui.displayUI('/modules/game_actionbar/otui/idle_assign_spell')
    if not win then return end

    local slotId = button:getId()
    win:setText("Assign Spell to Action Button " .. slotId .. " (IDLE)")

    local localPlayer = g_game.getLocalPlayer()
    local rawVoc = localPlayer and localPlayer:getVocation() or 0
    local playerVocation = (translateVocation and translateVocation(rawVoc)) or rawVoc
    local playerLevel = localPlayer and localPlayer:getLevel() or 1

    local combo = win.conditionBox.triggerRow.resourceCombo
    combo:clearOptions()
    combo:addOption("MP", "MP")
    combo:addOption("HP", "HP")
    combo:addOption("In Combat", "Combat")
    combo:setCurrentOption("MP")

    local radio = UIRadioGroup.create()
    local selectedSpell = nil
    local listPanel = win.spellList
    local defaultIconsFolder = SpelllistSettings and SpelllistSettings['Default'] and SpelllistSettings['Default'].iconFile or '/images/game/spells/defaultspells'

    local showAll = false

    local function renderSpells(searchFilter)
        radio:clearSelected()
        listPanel:destroyChildren()

        local spells = modules.gamelib and modules.gamelib.SpellInfo and modules.gamelib.SpellInfo['Default'] or {}
        local onlyLearnt = win.learntPanel.learntCheck:isChecked()
        local filterLower = searchFilter and searchFilter:lower():gsub("^%s*(.-)%s*$", "%1") or ""

        local sortedSpells = {}
        for sName, sData in pairs(spells) do
            local matchesVoc = showAll or (playerVocation == 0) or (sData.vocations and table.contains(sData.vocations, playerVocation))
            local matchesFilter = (filterLower == "") or sName:lower():find(filterLower, 1, true) or (sData.words and sData.words:lower():find(filterLower, 1, true))
            local matchesLearnt = not onlyLearnt or (playerLevel >= (sData.level or 0))

            if matchesVoc and matchesFilter and matchesLearnt then
                table.insert(sortedSpells, { name = sName, data = sData })
            end
        end

        table.sort(sortedSpells, function(a, b)
            return a.name < b.name
        end)

        for _, item in ipairs(sortedSpells) do
            local sName = item.name
            local sData = item.data

            local widget = g_ui.createWidget('SpellPreview', listPanel)
            radio:addWidget(widget)

            widget:setId(sData.id or sName)
            widget:setText(sName .. "\n" .. (sData.words or ""))
            widget.spellItem = item

            local spellId = sData.clientId
            if spellId and Spells and Spells.getImageClip then
                local clip = Spells.getImageClip(spellId, 'Default')
                widget.image:setImageSource(defaultIconsFolder)
                widget.image:setImageClip(clip)
            end

            if sData.level then
                widget.levelLabel:setVisible(true)
                widget.levelLabel:setText(string.format("Level: %d", sData.level))
                if widget.image and widget.image.gray then
                    widget.image.gray:setVisible(playerLevel < sData.level)
                end
            end

            local primaryGroup = Spells and Spells.getPrimaryGroup and Spells.getPrimaryGroup(sData) or -1
            if primaryGroup ~= -1 and widget.imageGroup then
                local offSet = (primaryGroup == 2 and 20) or (primaryGroup == 3 and 40) or 0
                widget.imageGroup:setImageClip(offSet .. " 0 20 20")
                widget.imageGroup:setVisible(true)
            end
        end

        local children = listPanel:getChildren()
        if #children > 0 then
            radio:selectWidget(children[1])
        end
    end

    radio.onSelectionChange = function(w, selected)
        if selected and selected.spellItem then
            selectedSpell = selected.spellItem
            local sName = selectedSpell.name
            local sData = selectedSpell.data

            win.previewContainer.previewLabel:setText(string.format("%s (%s)\nMana: %d | Level: %d", sName, sData.words or "", sData.mana or 0, sData.level or 0))
            local spellId = sData.clientId
            if spellId and Spells and Spells.getImageClip then
                local clip = Spells.getImageClip(spellId, 'Default')
                win.previewContainer.previewIcon:setImageSource(defaultIconsFolder)
                win.previewContainer.previewIcon:setImageClip(clip)
            end

            -- Smart classification: Healing vs Offensive
            local isHealing = (sData.words and (sData.words:lower():find("exura") or sData.words:lower():find("heal") or sData.words:lower():find("san") or sData.words:lower():find("vita") or sData.words:lower():find("cure"))) or (sData.group and sData.group[2])

            if isHealing then
                combo:setCurrentOption("HP")
                win.conditionBox.triggerRow.opLabel:setText("<=")
                win.conditionBox.triggerRow.percentInput:setText("80")
                win.conditionBox.triggerRow.percentInput:setEnabled(true)
                win.conditionBox.combatOnlyCheck:setChecked(false)
            else
                combo:setCurrentOption("MP")
                win.conditionBox.triggerRow.opLabel:setText(">=")
                win.conditionBox.triggerRow.percentInput:setText("20")
                win.conditionBox.triggerRow.percentInput:setEnabled(true)
                win.conditionBox.combatOnlyCheck:setChecked(true)
            end
        end
    end

    combo.onOptionChange = function(c, optionText, optionData)
        if optionData == "Combat" then
            win.conditionBox.triggerRow.opLabel:setText("=")
            win.conditionBox.triggerRow.percentInput:setText("100")
            win.conditionBox.triggerRow.percentInput:setEnabled(false)
        elseif optionData == "HP" then
            win.conditionBox.triggerRow.opLabel:setText("<=")
            win.conditionBox.triggerRow.percentInput:setEnabled(true)
        else
            win.conditionBox.triggerRow.opLabel:setText(">=")
            win.conditionBox.triggerRow.percentInput:setEnabled(true)
        end
    end

    win.searchInput.onTextChange = function(widget, newText)
        renderSpells(newText)
    end

    win.learntPanel.learntCheck.onCheckChange = function()
        renderSpells(win.searchInput:getText())
    end

    win.footerPanel.buttonShowAll.onClick = function()
        showAll = not showAll
        win.footerPanel.buttonShowAll:setText(showAll and tr('Vocation') or tr('show All'))
        renderSpells(win.searchInput:getText())
    end

    local function applyAction(destroy)
        if not selectedSpell then
            modules.game_textmessage.displayStatusMessage("Please select a spell first!")
            return
        end

        local pct = tonumber(win.conditionBox.triggerRow.percentInput:getText()) or 80
        local res = combo:getCurrentOption().data
        local op = win.conditionBox.triggerRow.opLabel:getText()
        local combatOnly = win.conditionBox.combatOnlyCheck:isChecked()

        local isHealing = (selectedSpell.data.words and (selectedSpell.data.words:lower():find("exura") or selectedSpell.data.words:lower():find("heal") or selectedSpell.data.words:lower():find("san") or selectedSpell.data.words:lower():find("vita") or selectedSpell.data.words:lower():find("cure"))) or (selectedSpell.data.group and selectedSpell.data.group[2])

        local idleData = getSavedIdleHotkeys()
        idleData[slotId] = {
            type = "spell",
            spellName = selectedSpell.name,
            words = selectedSpell.data.words,
            mana = selectedSpell.data.mana or 0,
            level = selectedSpell.data.level or 0,
            resource = res,
            operator = op,
            percent = pct,
            combatOnly = combatOnly,
            offensive = not isHealing,
            cooldown = math.max(1000, tonumber(selectedSpell.data.exhaustion) or 1000)
        }
        saveIdleHotkeys()
        modules.game_actionbar.refreshActionBarDisplay()

        if destroy then
            win:destroy()
        else
            modules.game_textmessage.displayStatusMessage(string.format("Applied IDLE spell '%s' to slot %s.", selectedSpell.name, slotId))
        end
    end

    win.footerPanel.buttonOk.onClick = function() applyAction(true) end
    win.footerPanel.buttonApply.onClick = function() applyAction(false) end
    win.footerPanel.buttonClose.onClick = function() win:destroy() end

    renderSpells()
end

-- =============================================================
-- Open Assign Object (IDLE) Modal - Real Potions & Runes Catalog
-- =============================================================
function modules.game_actionbar.openIdleObjectWindow(button)
    local win = g_ui.displayUI('/modules/game_actionbar/otui/idle_assign_object')
    if not win then return end

    local slotId = button:getId()
    win:setText("Assign Object to Action Button " .. slotId .. " (IDLE)")

    local combo = win.conditionBox.triggerRow.resourceCombo
    combo:clearOptions()
    combo:addOption("HP", "HP")
    combo:addOption("MP", "MP")
    combo:setCurrentOption("HP")

    local radio = UIRadioGroup.create()
    local selectedObj = nil
    local listPanel = win.itemList

    local currentCat = "All"

    -- Setup Category Tabs
    if win.catPanel then
        win.catPanel:destroyChildren()
        local categories = { "All", "Potions", "Runes" }
        for _, cat in ipairs(categories) do
            local btn = g_ui.createWidget('Button', win.catPanel)
            btn:setText(cat)
            btn:setWidth(70)
            btn:setFont('verdana-11px-rounded')
            btn.onClick = function()
                currentCat = cat
                for _, b in pairs(win.catPanel:getChildren()) do
                    b:setColor(b == btn and '#ffd700' or '#ffffff')
                end
                renderObjects()
            end
            if cat == "All" then
                btn:setColor('#ffd700')
            end
        end
    end

    local function renderObjects()
        radio:clearSelected()
        listPanel:destroyChildren()

        for _, item in ipairs(KNOWN_POTIONS_AND_RUNES) do
            if currentCat == "All" or item.cat == currentCat then
                local widget = g_ui.createWidget('ObjectPreview', listPanel)
                radio:addWidget(widget)

                widget.objData = item
                widget:setText(item.name)
                widget.itemWidget:setItemId(item.id)
                widget.costLabel:setText(string.format("~%d gp", item.cost))
                widget.typeLabel:setText(item.cat)
            end
        end

        local children = listPanel:getChildren()
        if #children > 0 then
            radio:selectWidget(children[1])
        end
    end

    radio.onSelectionChange = function(w, selected)
        if selected and selected.objData then
            selectedObj = selected.objData
            win.previewContainer.previewItem:setItemId(selectedObj.id)
            win.previewContainer.previewLabel:setText(string.format("%s\nCost: ~%d gp / use", selectedObj.name, selectedObj.cost))

            combo:setCurrentOption(selectedObj.resource or "HP")
            win.conditionBox.triggerRow.percentInput:setText(tostring(selectedObj.percent or 60))
            if win.conditionBox.triggerRow.opLabel then
                win.conditionBox.triggerRow.opLabel:setText(selectedObj.offensive and ">=" or "<=")
            end
        end
    end

    combo.onOptionChange = function(c, optionText, optionData)
        if optionData == "HP" then
            win.conditionBox.triggerRow.opLabel:setText("<=")
        else
            win.conditionBox.triggerRow.opLabel:setText(selectedObj and selectedObj.offensive and ">=" or "<=")
        end
    end

    local function applyAction(destroy)
        if not selectedObj then
            modules.game_textmessage.displayStatusMessage("Please select an item first!")
            return
        end

        local pct = tonumber(win.conditionBox.triggerRow.percentInput:getText()) or 60
        local res = combo:getCurrentOption().data
        local op = win.conditionBox.triggerRow.opLabel:getText()

        local idleData = getSavedIdleHotkeys()
        idleData[slotId] = {
            type = "object",
            itemId = selectedObj.id,
            name = selectedObj.name,
            cost = selectedObj.cost,
            resource = res,
            operator = op,
            percent = pct,
            offensive = selectedObj.offensive or false,
            combatOnly = selectedObj.offensive or false,
            cooldown = 1000
        }
        saveIdleHotkeys()
        modules.game_actionbar.refreshActionBarDisplay()

        if destroy then
            win:destroy()
        else
            modules.game_textmessage.displayStatusMessage(string.format("Applied IDLE object '%s' to slot %s.", selectedObj.name, slotId))
        end
    end

    win.footerPanel.buttonOk.onClick = function() applyAction(true) end
    win.footerPanel.buttonApply.onClick = function() applyAction(false) end
    win.footerPanel.buttonClose.onClick = function() win:destroy() end

    renderObjects()
end
modules.game_actionbar.IdleActionBar = modules.game_actionbar.IdleActionBar or {}
modules.game_actionbar.IdleActionBar.getIdleHotkeys = modules.game_actionbar.getIdleHotkeys
