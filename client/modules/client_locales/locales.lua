dofile 'neededtranslations'

-- Lock strictly to English
_G.allowedLocales = { ['en'] = true }

-- private variables
local defaultLocaleName = 'en'
local installedLocales = {}
local currentLocale = nil

function sendLocale(localeName)
    local protocolGame = g_game.getProtocolGame()
    if protocolGame then
        protocolGame:sendExtendedOpcode(ExtendedIds.Locale, 'en')
        return true
    end
    return false
end

function createWindow()
    -- Localization window disabled: English is strictly enforced
end

function selectFirstLocale(name)
    setLocale('en')
end

-- hooked functions
function onGameStart()
    sendLocale('en')
end

function onExtendedLocales(protocol, opcode, buffer)
    -- Enforce English regardless of server hints
    setLocale('en')
end

-- public functions
function init()
    installedLocales = {}
    installLocales('/locales')

    -- Always enforce English
    setLocale('en')
    g_settings.set('locale', 'en')

    ProtocolGame.registerExtendedOpcode(ExtendedIds.Locale, onExtendedLocales)
    connect(g_game, {
        onGameStart = onGameStart
    })
end

function terminate()
    installedLocales = nil
    currentLocale = nil

    ProtocolGame.unregisterExtendedOpcode(ExtendedIds.Locale)
    disconnect(g_game, {
        onGameStart = onGameStart
    })
end

function generateNewTranslationTable(localename)
end

function installLocale(locale)
    if not locale or not locale.name then
        return
    end

    if _G.allowedLocales and not _G.allowedLocales[locale.name] then
        return
    end

    installedLocales[locale.name] = locale
end

function installLocales(directory)
    dofiles(directory)
end

function setLocale(name)
    name = 'en'
    local locale = installedLocales[name]
    if not locale then
        return false
    end
    currentLocale = locale
    g_settings.set('locale', 'en')
    if onLocaleChanged then
        onLocaleChanged('en')
    end
    return true
end

function getInstalledLocales()
    return installedLocales
end

function getCurrentLocale()
    return currentLocale
end

-- global function used to translate texts (in English mode, returns original text directly)
function _G.tr(text, ...)
    if text == nil then
        return ''
    end
    if tonumber(text) and currentLocale and currentLocale.formatNumbers then
        local number = tostring(text):split('.')
        local out = ''
        local reverseNumber = number[1]:reverse()
        for i = 1, #reverseNumber do
            out = out .. reverseNumber:sub(i, i)
            if i % 3 == 0 and i ~= #number then
                out = out .. (currentLocale.thousandsSeperator or ',')
            end
        end

        if number[2] then
            out = number[2] .. (currentLocale.decimalSeperator or '.') .. out
        end
        return out:reverse()
    elseif tostring(text) then
        return string.format(tostring(text), ...)
    end
    return text
end