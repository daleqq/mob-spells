MobSpells = LibStub("AceAddon-3.0"):NewAddon("MobSpells")

local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local DataBroker = LibStub("LibDataBroker-1.1", true)

local L = LibStub("AceLocale-3.0"):GetLocale("MobSpells")

LibStub("AceAddon-3.0"):EmbedLibraries(
    MobSpells,
    "AceEvent-3.0",
    "AceConsole-3.0",
    "AceHook-3.0"
)

local defaults = {
    global = {
        mobs = {},
        zones = {},
    },
    profile = {
        upgradedOldDB = false,
        showTooltips = true,
        recordNone = true,
        recordPvp = nil,
        recordArena = nil,
        recordParty = true,
        recordRaid = true,
        recordWhenSolo = true,
        recordWhenParty = true,
        recordWhenRaid = true,
        fiveman = true,
        fivemanHeroic = true,
        fivemanMythic = true,
        challengemode = true,
        scenario = true,
        heroicscenario = true,
        tenman = true,
        twentyfiveman = true,
        tenmanHeroic = true,
        twentyfivemanHeroic = true,
        lookingforraid = true,
        fourtyman = true,
        flexible = true,
        flexibleHeroic = true,
        mythic = true,
        flexibleLFR = true,
        event1 = nil,
        event2 = nil,
        eventScenario = nil,
        fivemanMythic = true,
        fivemanTimewalker = true
    },
}
--[[
  The difficulty IDs
  1  : "Normal" (Dungeons)
  2  : "Heroic" (Dungeons)
  3  : "10 Player"
  4  : "25 Player"
  5  : "10 Player (Heroic)"
  6  : "25 Player (Heroic)"
  7  : "Looking For Raid" (Legacy; everything prior to Siege of Orgrimmar)
  8  : "Challenge Mode"
  9  : "40 Player"
  10 : nil
  11 : "Heroic Scenario"
  12 : "Normal Scenario"
  13 : nil
  14 : "Normal" (Raids)
  15 : "Herioc" (Raids)
  16 : "Mythic" (Raids)
  17 : "Looking For Raid"
  18 : "Event"
  19 : "Event"
  20 : "Event Scenario"
  21 : nil
  22 : nil
  23 : "Mythic" (Dungeons)
  24 : Timewalker
]]--
local DIFFICULTY_NONE, DIFFICULTY_HEROIC_SCENARIO, DIFFICULTY_SCENARIO = 0,11,12
local EVENT1, EVENT2, EVENT_SCENARIO, DIFFICULTY_DUNGEON_MYTHIC, DIFFICULTY_DUNGEON_TIMEWALER = 18, 19, 20, 23, 24

local diffIDtoName = { -- as returned by local name, type, diffID = GetInstanceInfo(); 
    [DIFFICULTY_NONE] 					= _G.NONE, -- 0
    [_G.DIFFICULTY_DUNGEON_NORMAL] 		= _G.DUNGEON_DIFFICULTY_5PLAYER, -- 1
    [_G.DIFFICULTY_DUNGEON_HEROIC] 		= _G.DUNGEON_DIFFICULTY_5PLAYER_HEROIC, -- 2
    [_G.DIFFICULTY_RAID10_NORMAL] 		= _G.RAID_DIFFICULTY_10PLAYER, -- 3
    [_G.DIFFICULTY_RAID25_NORMAL] 		= _G.RAID_DIFFICULTY_25PLAYER, -- 4
    [_G.DIFFICULTY_RAID10_HEROIC] 		= _G.RAID_DIFFICULTY_10PLAYER_HEROIC, -- 5
    [_G.DIFFICULTY_RAID25_HEROIC] 		= _G.RAID_DIFFICULTY_25PLAYER_HEROIC, -- 6
    [_G.DIFFICULTY_RAID_LFR] 			= _G.RAID_FINDER, -- 7
    [_G.DIFFICULTY_DUNGEON_CHALLENGE] 	= _G.CHALLENGE_MODE, -- 8
    [_G.DIFFICULTY_RAID40] 				= _G.RAID_DIFFICULTY_40PLAYER, -- 9

    [DIFFICULTY_HEROIC_SCENARIO]		= _G.HEROIC_SCENARIO, -- 11
    [DIFFICULTY_SCENARIO]				= _G.SCENARIOS, -- 12

    [_G.DIFFICULTY_PRIMARYRAID_NORMAL]	= _G.PLAYER_DIFFICULTY4, -- 14
    [_G.DIFFICULTY_PRIMARYRAID_HEROIC]	= _G.PLAYER_DIFFICULTY4, -- 15
    [_G.DIFFICULTY_PRIMARYRAID_MYTHIC]	= _G.PLAYER_DIFFICULTY6, -- 16
    [_G.DIFFICULTY_PRIMARYRAID_LFR]		= _G.RAID_FINDER, -- 17
    [EVENT1]                            = "", -- 18  -- TODO: Change to right description
    [EVENT2]                            = "", -- 19  -- TODO: Change to right description
    [EVENT_SCENARIO]                    = "", -- 20  -- TODO: Change to right description
    [DIFFICULTY_DUNGEON_MYTHIC]         = "", -- 23  -- TODO: Change to right description
    [DIFFICULTY_DUNGEON_TIMEWALER]      = "", -- 24  -- TODO: Change to right description
}
local diffIDtoOption = {
    [_G.DIFFICULTY_DUNGEON_NORMAL] 		= "fiveman", -- 1
    [_G.DIFFICULTY_DUNGEON_HEROIC] 		= "fivemanHeroic", -- 2
    [_G.DIFFICULTY_RAID10_NORMAL] 		= "tenman", -- 3
    [_G.DIFFICULTY_RAID25_NORMAL] 		= "twentyfiveman", -- 4
    [_G.DIFFICULTY_RAID10_HEROIC] 		= "tenmanHeroic", -- 5
    [_G.DIFFICULTY_RAID25_HEROIC] 		= "twentyfivemanHeroic", -- 6
    [_G.DIFFICULTY_RAID_LFR] 			= "lookingforraid", -- 7
    [_G.DIFFICULTY_DUNGEON_CHALLENGE] 	= "challengemode", -- 8
    [_G.DIFFICULTY_RAID40] 				= "fourtyman", -- 9

    [DIFFICULTY_HEROIC_SCENARIO]		= "heroicscenario", -- 11
    [DIFFICULTY_SCENARIO]				= "scenario", -- 12

    [_G.DIFFICULTY_PRIMARYRAID_NORMAL]	= "flexible", -- 14
    [_G.DIFFICULTY_PRIMARYRAID_HEROIC]	= "flexibleHeroic", -- 15
    [_G.DIFFICULTY_PRIMARYRAID_MYTHIC]	= "mythic", -- 16
    [_G.DIFFICULTY_PRIMARYRAID_LFR]		= "flexibleLFR", -- 17

    [EVENT1]                            = "event1", -- 18
    [EVENT2]                            = "event2", -- 19
    [EVENT_SCENARIO]                    = "eventScenario", -- 20
    [DIFFICULTY_DUNGEON_MYTHIC]         = "fivemanMythic", -- 23
    [DIFFICULTY_DUNGEON_TIMEWALER]      = "fivemanTimewalker", -- 24
}

local mobs
local bit_band = _G.bit.band
local frame

-- Upvalues
local next = _G.next
local select = _G.select
local pairs = _G.pairs
local type = _G.type
local table_sort = _G.table.sort
--[[
local COMBATLOG_OBJECT_CONTROL_NPC = _G.COMBATLOG_OBJECT_CONTROL_NPC
local COMBATLOG_OBJECT_TYPE_NPC = _G.COMBATLOG_OBJECT_TYPE_NPC
local COMBATLOG_OBJECT_REACTION_HOST = _G.COMBATLOG_OBJECT_REACTION_HOST
local COMBATLOG_OBJECT_REACTION_HOSTILE = _G.COMBATLOG_OBJECT_REACTION_HOSTILE
local COMBATLOG_DEFAULT_COLORS = _G.COMBATLOG_DEFAULT_COLORS
]]--
local tonumber = _G.tonumber
local UnitGUID = _G.UnitGUID
local GetTime = _G.GetTime
local UnitName = _G.UnitName
local tremove = _G.tremove

BINDING_NAME_MOBSPELLS = L["Show MobSpells"]
BINDING_HEADER_MOBSPELLS = L["Mob Spells"]

local function shouldLog()
    local db = MobSpells.db.profile
    local should = nil
    local i, t = IsInInstance()
    if i and not t and IsInScenarioGroup() then t = "scenario" end
    local n, _, d = GetInstanceInfo()
    if t == "none" then
        should = db.recordNone
    elseif t == "pvp" then
        should = db.recordPvp
    elseif t == "arena" then
        should = db.recordArena
    elseif t == "party" then
        if db.recordParty then
            if db[diffIDtoOption[d]] then
                should = true
            end
        else
            should = nil
        end
    elseif t == "scenario" then
        if db.recordParty then
            should = db.scenario
        else
            should = nil
        end
    elseif t == "raid" then
        if db.recordRaid then
            if db[diffIDtoOption[d]] then
                should = true
            end
        else
            should = nil
        end
    end

    if IsInRaid() then
        should = should and db.recordWhenRaid
    elseif IsInGroup() then
        should = should and db.recordWhenParty
    elseif db.recordWhenSolo then
        should = should and true
    end
    t = t or ""
    if should then
        MobSpells:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        if not MobSpells.recording then
          MobSpells:Print("Recording started ("..(i and tostring(i) or "nil").." "..t.." "..d..")")
        end
        MobSpells.recording = true
    else
        MobSpells:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        if MobSpells.recording then
          MobSpells:Print("Recording paused ("..(i and tostring(i) or "nil").." "..t.." "..d..")")
        end
        MobSpells.recording = false
    end
end

local function get(info) return MobSpells.db.profile[info[#info]] end
local function set(info, v) MobSpells.db.profile[info[#info]] = v; shouldLog() end

local options = {
    type = "group",
    handler = MobSpells,
    childGroups = "tab",
    get = get,
    set = set,
    args = {
        desc = {
            type = "description",
            name = L["description"],
            order = 1,
            fontSize = "medium",
        },
        show = {
            type = "execute",
            name = L["Show MobSpells"],
            desc = L["Show MobSpells"],
            func = "Show",
            order = 2,
            width = "full",
        },
        report = {
            type = "execute",
            name = L["Report target's spells"],
            desc = L["Report your target spells to the group"],
            func = "ReportTargetSpells",
            order = 3,
            width = "full",
        },
        showTooltips = {
            type = "toggle",
            name = L["Use Tooltips"],
            desc = L["Show spell info in tooltips"],
            set = function(info, v)
                MobSpells.db.profile.showTooltips = v
                if v then
                    MobSpells:SecureHookScript(GameTooltip, "OnTooltipSetUnit")
                    MobSpells:Print(L["Now showing abilities in tooltip"])
                else
                    MobSpells:Unhook(GameTooltip, "OnTooltipSetUnit")
                    MobSpells:Print(L["NOT showing abilities in tooltip"])
                end
            end,
            order = 4,
            width = "full",
        },
        config = {
            type = "execute",
            name = L["Config"],
            desc = L["Configure MobSpells"],
            func = function() InterfaceOptionsFrame_OpenToCategory(MobSpells.optFrame) end,
            guiHidden = true,
        },
        recordIn = {
            type = "group",
            name = L["Record in ..."],
            order = 5,
            args = {
                recordNone = {
                    type = "toggle",
                    name = L["Outside"],
                    desc = L["Whether to record when you're not in a battleground, arena or PvE instance."],
                    order = 11,
                },
                recordPvp = {
                    type = "toggle",
                    name = L["PvP battleground"],
                    desc = L["Whether to record when you're in a battleground."],
                    order = 12,
                },
                recordArena = {
                    type = "toggle",
                    name = L["Arena"],
                    desc = L["Whether to record when you're in an arena battle."],
                    order = 13,
                },
                recordParty = {
                    type = "toggle",
                    name = L["5-man instance"],
                    desc = L["Whether to record when you're in a 5-man instance."],
                    order = 14,
                },
                recordRaid = {
                    type = "toggle",
                    name = L["Raid instance"],
                    desc = L["Whether to record when you're in a raid instance."],
                    order = 15,
                },
            },
        },
        recordWhen = {
            type = "group",
            name = L["Record when ..."],
            order = 6,
            args = {
                recordWhenSolo = {
                    type = "toggle",
                    name = L["Solo"],
                    desc = L["Whether to record when you're playing solo."],
                    order = 21,
                },
                recordWhenParty = {
                    type = "toggle",
                    name = L["Party"],
                    desc = L["Whether to record when you're in a 5-man group."],
                    order = 22,
                },
                recordWhenRaid = {
                    type = "toggle",
                    name = L["Raid"],
                    desc = L["Whether to record when you're in a raid group."],
                    order = 23,
                },
            },
        },
        recordDifficulty = {
            type = "group",
            name = L["Difficulty ..."],
            order = 7,
            args = {
                scenario = {
                    type = "toggle",
                    name = _G["SCENARIOS"],
                    desc = L["Record in %s."]:format(_G["SCENARIOS"]),
                    order = 1,
                },
                heroicscenario = {
                    type = "toggle",
                    name = _G["HEROIC_SCENARIO"],
                    desc = L["Record in %s."]:format(_G["HEROIC_SCENARIO"]),
                    order = 2,
                },
                fiveman = {
                    type = "toggle",
                    name = _G["DUNGEON_DIFFICULTY1"],
                    desc = L["Record in %s."]:format(_G["DUNGEON_DIFFICULTY1"]),
                    order = 3,
                },
                fivemanHeroic = {
                    type = "toggle",
                    name = _G["DUNGEON_DIFFICULTY2"],
                    desc = L["Record in %s."]:format(_G["DUNGEON_DIFFICULTY2"]),
                    order = 4,
                },
                challengemode = {
                    type = "toggle",
                    name = _G["CHALLENGE_MODE"],
                    desc = L["Record in %s."]:format(_G["CHALLENGE_MODE"]),
                    order = 5,
                },
                tenman = {
                    type = "toggle",
                    name = _G["RAID_DIFFICULTY1"],
                    desc = L["Record in %s."]:format(_G["RAID_DIFFICULTY1"]),
                    order = 6,
                },
                twentyfiveman = {
                    type = "toggle",
                    name = _G["RAID_DIFFICULTY2"],
                    desc = L["Record in %s."]:format(_G["RAID_DIFFICULTY2"]),
                    order = 7,
                },
                tenmanHeroic = {
                    type = "toggle",
                    name = _G["RAID_DIFFICULTY3"],
                    desc = L["Record in %s."]:format(_G["RAID_DIFFICULTY3"]),
                    order = 8,
                },
                twentyfivemanHeroic = {
                    type = "toggle",
                    name = _G["RAID_DIFFICULTY4"],
                    desc = L["Record in %s."]:format(_G["RAID_DIFFICULTY4"]),
                    order = 9,
                },
                lookingforraid = {
                    type = "toggle",
                    name = _G["PLAYER_DIFFICULTY3"],
                    desc = L["Record in %s."]:format(_G["PLAYER_DIFFICULTY3"]),
                    order = 10,
                },
                fourtyman = {
                    type = "toggle",
                    name = _G["RAID_DIFFICULTY_40PLAYER"],
                    desc = L["Record in %s."]:format(_G["RAID_DIFFICULTY_40PLAYER"]),
                    order = 11,
                },
                flexible = {
                    type = "toggle",
                    name = format("%s (%s)", _G["PLAYER_DIFFICULTY4"], _G["PLAYER_DIFFICULTY1"]),
                    desc = L["Record in %s (%s)."]:format(_G["PLAYER_DIFFICULTY4"], _G["PLAYER_DIFFICULTY1"]),
                    order = 12,
                },
                flexibleHeroic = {
                    type = "toggle",
                    name = format("%s (%s)", _G["PLAYER_DIFFICULTY4"], _G["PLAYER_DIFFICULTY2"]),
                    desc = L["Record in %s (%s)."]:format(_G["PLAYER_DIFFICULTY4"], _G["PLAYER_DIFFICULTY2"]),
                    order = 13,
                },
                flexibleLFR = {
                    type = "toggle",
                    name = format("%s (%s)", _G["PLAYER_DIFFICULTY4"], _G["PLAYER_DIFFICULTY3"]),
                    desc = L["Record in %s (%s)."]:format(_G["PLAYER_DIFFICULTY4"], _G["PLAYER_DIFFICULTY3"]),
                    order = 14,
                },
                mythic = {
                    type = "toggle",
                    name = _G["PLAYER_DIFFICULTY6"],
                    desc = L["Record in %s."]:format(_G["PLAYER_DIFFICULTY6"]),
                    order = 15,
                },
                event1 = {
                    type = "toggle",
                    name = "", -- TODO: Change to right description
                    desc = L["Record in %s."]:format(""), -- TODO: Change to right description
                    order = 16,
                },
                event2 = {
                    type = "toggle",
                    name = "", -- TODO: Change to right description
                    desc = L["Record in %s."]:format(""), -- TODO: Change to right description
                    order = 17,
                },
                eventScenario = {
                    type = "toggle",
                    name = "", -- TODO: Change to right description
                    desc = L["Record in %s."]:format(""), -- TODO: Change to right description
                    order = 18,
                },
                fivemanMythic = {
                    type = "toggle",
                    name = "", -- TODO: Change to right description
                    desc = L["Record in %s."]:format(""), -- TODO: Change to right description
                    order = 19,
                },
                fivemanTimewalker = {
                    type = "toggle",
                    name = "", -- TODO: Change to right description
                    desc = L["Record in %s."]:format(""), -- TODO: Change to right description
                    order = 20,
                },
            },
        },
    },
}

AceConfig:RegisterOptionsTable("MobSpells", options, { "mobspells", "ms" } )

local SPELL_BLACKLIST = {
    [0] = true,     -- ??
    [2600] = true,  -- Rejuvenation Potion
    [1604] = true,  -- Dazed
    [50424] = true, -- Mark of Blood effect
    [1] = true,     -- Word of Recall (OLD)
    [4] = true,     -- Word of Recall Other
}

local MOB_BLACKLIST = {
    [0] = true,     -- ??
    [89] = true,    -- Infernal
    [1964] = true,  -- Treant
    [19833] = true, -- Venomous Snake
    [48360] = true, -- 3rd Officer Kronkar (XXX he seems to show up all over, wtf)
    [30230] = true, -- Risen Ally (XXX no longer exists)
    [26125] = true, -- Risen Ghoul
    [28017] = true, -- Bloodworm
    [11859] = true, -- Doomguard
    [50675] = true, -- Ebon Imp
    [46157] = true, -- Hand of Gul'dan
    [43484] = true, -- Fungal Growth II
    [49530] = true, -- Beauty Quest Bang
    [49526] = true, -- Corla Quest Bang
    [49529] = true, -- Karsh Quest Bang
    [49531] = true, -- Obsidius Quest Bang
    [24207] = true, -- Army of the Dead Ghoul
    [32819] = true, -- Plump Turkey Bunny
    [33988] = true, -- Immortal Guardian (Ulduar)
    [33136] = true, -- Guardian of Yogg-Saron (Ulduar)
    [46506] = true, -- Guardian of Ancient Kings
    [46499] = true, -- Guardian of Ancient Kings
    [46490] = true, -- Guardian of Ancient Kings
    [19668] = true, -- Shadowfiend
    [35642] = true, -- Jeeves
    [47244] = true, -- Mirror Image
    [47243] = true, -- Mirror Image
    [31216] = true, -- Mirror Image
    [29264] = true, -- Spirit Wolf
    [27829] = true, -- Ebon Gargoyle
    [46954] = true, -- Shadowy Apparition
    [27893] = true, -- Rune Weapon
    [5925] = true,  -- Grounding Totem
    [2523] = true,  -- Searing Totem
    [5929] = true,  -- Magma Totem
    [42211] = true, -- Magma Totem
    [5873] = true,  -- Stoneskin Totem
    [3579] = true,  -- Stoneclaw Totem
    [9637] = true,  -- Scorching Totem
    [15447] = true, -- Wrath of Air Totem
    [3527] = true,  -- Healing Stream Totem
    [2630] = true,  -- Earthbind Totem
    [15439] = true, -- Fire Elemental Totem
    [5950] = true,  -- Flametongue Totem
    [15430] = true, -- Earth Elemental Totem
    [53006] = true, -- Spirit Link Totem
    [28306] = true, -- Anti-Magic Zone
}

--    1 - Normal (5 or 10 players)
--    2 - Heroic (5 players) / Normal (25 players)
--    3 - Heroic (10 players)
--    4 - Heroic (25 players)
-- 1, 2, 4, 8
local diffBits = {1, 2, 4, 8}

local translationError = "The zone %q/%q could not be translated to the new MobSpells database format and will be purged."

function MobSpells:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("MobSpellsDB", defaults, true)

    mobs = self.db.global.mobs

    if not self.db.profile.upgradedOldDB then
        print("Converting old MobSpells database...")
        -- XXX Need this to upgrade the DB
        local temporaryTranslationTable = {
            [RAID_DIFFICULTY1] = 1,
            [RAID_DIFFICULTY2] = 2,
            [RAID_DIFFICULTY3] = 3,
            [RAID_DIFFICULTY4] = 4,
            [DUNGEON_DIFFICULTY1] = 1,
            [DUNGEON_DIFFICULTY2] = 2,
        }
        for zone, v in pairs(mobs) do
            local z, diff = zone:match("^(.*)%s%[(.*)%]$")
            if not z then z = zone end
            if z:trim():len() > 3 then
                local diffBit = diff and diffBits[temporaryTranslationTable[diff]] or 1
                if not mobs[z] then mobs[z] = {} end
                for mobID, mobData in pairs(v) do
                    if not MOB_BLACKLIST[mobID] and mobData.spells then
                        if not mobs[z][mobID] then mobs[z][mobID] = {name=mobData.name, spells={}} end
                        for spellId, spellData in pairs(mobData.spells) do
                            if not SPELL_BLACKLIST[spellId] then
                                if mobs[z][mobID].spells[spellId] then
                                    if type(mobs[z][mobID].spells[spellId].school) ~= "number" then
                                        mobs[z][mobID].spells[spellId] = nil
                                    else
                                        -- Clear out old keys
                                        local x = mobs[z][mobID].spells[spellId]
                                        x.lastGUID = nil
                                        x.missing = nil
                                        x.minSpeed = nil
                                        x.parry = nil
                                        x.glancing = nil
                                        x.amountMin = nil
                                        x.critical = nil
                                        x.dodge = nil
                                        x.maxSpeed = nil
                                        x.resisted = nil
                                        x.resist = nil
                                        x.amountMax = nil
                                        x.blocked = nil
                                        x.lastTime = nil
                                        x.reflect = nil
                                        -- Set new diff bit
                                        if not x.diff or bit_band(x.diff, diffBit) ~= diffBit then
                                            x.diff = (x.diff or 0) + diffBit
                                        end
                                    end
                                else
                                    mobs[z][mobID].spells[spellId] = {
                                        school = spellData.school,
                                        diff = diffBit,
                                    }
                                end
                            else
                                mobs[z][mobID].spells[spellId] = nil
                            end
                        end
                        if not next(mobs[z][mobID].spells) then
                            mobs[z][mobID] = nil
                        end
                    else
                        mobs[z][mobID] = nil
                    end
                end
            else
                print(translationError:format(tostring(z), tostring(zone)))
            end
            if zone ~= z then
                mobs[zone] = nil
            end
            if mobs[z] and not next(mobs[z]) then
                mobs[z] = nil
            end
            self.db.profile.upgradedOldDB = true
        end
    end

    self:RegisterChatCommand("spells", "GetTargetSpells")
    self.searchIndex = self.searchIndex or "NPC"
    self.optFrame = AceConfigDialog:AddToBlizOptions("MobSpells", "MobSpells")

    -- LDB launcher, mostly copy/paste from grid2
    local MobSpellsLDB = DataBroker:NewDataObject("MobSpells", {
        type  = "launcher",
        label = GetAddOnInfo("MobSpells", "Title"),
        icon  = "Interface\\Icons\\Spell_Shadow_SoothingKiss",
        OnClick = function(self, button)
            if button=="LeftButton" then
                MobSpells:Toggle()
            elseif button=="RightButton" then
                InterfaceOptionsFrame_OpenToCategory("MobSpells") -- Still bugged
                InterfaceOptionsFrame_OpenToCategory("MobSpells") -- so call it twice ?
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("MobSpells")
            tooltip:AddLine("Left Click to open main window", 0.2, 1, 0.2)
            tooltip:AddLine("Right Click to open configuration", 0.2, 1, 0.2)
        end,
    })
end

function MobSpells:OnEnable()
    if self.db.profile.showTooltips then
        self:SecureHookScript(GameTooltip, "OnTooltipSetUnit")
    end
    self:RegisterEvent("ZONE_CHANGED", shouldLog)
    self:RegisterEvent("ZONE_CHANGED_INDOORS", shouldLog)
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", shouldLog)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", shouldLog)
    self:RegisterEvent("GROUP_ROSTER_UPDATE", shouldLog)
    self:RegisterEvent("GROUP_JOINED", shouldLog)
    shouldLog()
end

do
    local tmp = {}
    local DEFAULT_COLOR = {r = 1, g = 1, b = 1, a = 1}
    function MobSpells:OnTooltipSetUnit(tt)
        local zone = GetRealZoneText()
        if not mobs[zone] then return end
        local guid = UnitGUID("mouseover")
        if not guid then return end
        local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
        local NPCID = tonumber(npc_id, 16)
        if NPCID == 0 then return end

        if mobs[zone][NPCID] and mobs[zone][NPCID].spells and not MOB_BLACKLIST[NPCID] then
            for k, v in pairs(mobs[zone][NPCID].spells) do
                if not SPELL_BLACKLIST[k] then
                    local name = GetSpellInfo(k)
                    if name and not tmp[name] then
                        local c = COMBATLOG_DEFAULT_COLORS.schoolColoring[v.school]
                        if not c then
                            c = COMBATLOG_DEFAULT_COLORS.schoolColoring.default or DEFAULT_COLOR
                        end
                        tmp[#tmp+1] = ("|c%02x%02x%02x%02x%s|r"):format(c.a * 255, c.r * 255, c.g * 255, c.b * 255, name)
                        tmp[name] = true
                    end
                end
            end
        end
        if #tmp > 0 then
            tt:AddLine(L["Casts"] .. ": " .. table.concat(tmp, ", "), 1, 1, 1, 1)
            wipe(tmp)
        end
    end
end

local whitelistedEvents = {
    SPELL_DAMAGE = true,
    SPELL_MISSED = true,
    SPELL_HEAL = true,
    SPELL_ENERGIZE = true,
    SPELL_DRAIN = true,
    SPELL_LEECH = true,
    SPELL_AURA_APPLIED = true,
    SPELL_CAST_START = true,
    SPELL_CAST_SUCCESS = true,
    SPELL_CAST_FAILED = true,
    SPELL_CREATE = true,
    SPELL_SUMMON = true,
    SPELL_INSTAKILL = true,
    SPELL_PERIODIC_DAMAGE = true,
    SPELL_PERIODIC_HEAL = true,
}

function MobSpells:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    local timestamp, eventtype, hidecaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, spellID, spellName, spellSchool = ...

    -- Is this spell blacklisted?
    if not spellID or SPELL_BLACKLIST[spellID] then return end

    -- Do we care about this event?
    if not whitelistedEvents[eventtype] then return end

    -- Get out early if the source of the event is not an NPC.
    if bit_band(srcFlags, COMBATLOG_OBJECT_CONTROL_NPC) ~= COMBATLOG_OBJECT_CONTROL_NPC or
        (bit_band(srcFlags,COMBATLOG_OBJECT_CONTROL_NPC) == COMBATLOG_OBJECT_CONTROL_NPC and bit_band(srcFlags,COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER) or
        bit_band(srcFlags, COMBATLOG_OBJECT_TYPE_NPC) ~= COMBATLOG_OBJECT_TYPE_NPC then return end

    -- Get the real NPC ID, and bail out early if it's blacklisted or invalid.
    local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", srcGUID);
    local NPCID = tonumber(npc_id, 16) -- http://wow.gamepedia.com/GUID
    if not NPCID or MOB_BLACKLIST[NPCID] then return end

    -- If we can't determine the name properly, mark it as UNKNOWN
    local name = srcName or UNKNOWN

    -- ignore Haunt heals, since blizzard chose to code it as victim casting on player
    if eventtype == "SPELL_HEAL" and spellID == 48210 then return end

    local z = GetRealZoneText()
    if not z then return end -- can occur during zone-in

    if not mobs[z] then mobs[z] = {} end
    if not mobs[z][NPCID] then mobs[z][NPCID] = {name = name, spells = {}} end

    local m = mobs[z][NPCID]
    local spell = m.spells[spellID]
    if not spell then
        spell = {
            school = spellSchool,
        }
    end

    if (IsInInstance()) then
        local n,_,d = GetInstanceInfo()
        spell.diff = d
    end

    m.spells[spellID] = spell
end

local function showSpellTooltip(this)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(this.frame, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(("spell:%s"):format(this:GetUserData("spellID")))
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(("|cffffffff%s #|r|cffffff00%s|r"):format(L["Spell ID"], this:GetUserData("spellID")))
    GameTooltip:Show()
end

local addLink

local function SelectSpell(widget, event, value)
    widget:ReleaseChildren()

    local zone, mobID = ("\001"):split(value)

    if not mobID then return end
    local zoneData = mobs[zone]
    local data = zoneData[tonumber(mobID)]
    if not data then return end

    local sf = AceGUI:Create("ScrollFrame")
    sf:SetLayout("List")
    local spellsToList = {
        [DIFFICULTY_NONE]={}, -- 0
        [_G.DIFFICULTY_DUNGEON_NORMAL]={}, -- 1
        [_G.DIFFICULTY_DUNGEON_HEROIC]={}, -- 2
        [_G.DIFFICULTY_RAID10_NORMAL]={}, -- 3
        [_G.DIFFICULTY_RAID25_NORMAL]={}, -- 4
        [_G.DIFFICULTY_RAID10_HEROIC]={}, -- 5
        [_G.DIFFICULTY_RAID25_HEROIC]={}, -- 6
        [_G.DIFFICULTY_RAID_LFR]={}, -- 7
        [_G.DIFFICULTY_DUNGEON_CHALLENGE]={}, -- 8
        [_G.DIFFICULTY_RAID40]={}, -- 9
        [DIFFICULTY_HEROIC_SCENARIO]={}, -- 11
        [DIFFICULTY_SCENARIO]={}, -- 12
        [_G.DIFFICULTY_PRIMARYRAID_NORMAL]={}, -- 14
        [_G.DIFFICULTY_PRIMARYRAID_HEROIC]={}, -- 15
        [_G.DIFFICULTY_PRIMARYRAID_MYTHIC]={}, -- 16
        [_G.DIFFICULTY_PRIMARYRAID_LFR]={}, -- 17
        [EVENT1] = {}, -- 18
        [EVENT2] = {}, -- 19
        [EVENT_SCENARIO] = {}, -- 20
        [DIFFICULTY_DUNGEON_MYTHIC]  = {}, -- 23
        [DIFFICULTY_DUNGEON_TIMEWALER] = {}, -- 24
    }
    for spellId, data in pairs(data.spells) do
        if not SPELL_BLACKLIST[spellId] then
            if not data.diff then
                spellsToList[0][spellId] = data.school
            else
                spellsToList[data.diff][spellId] = data.school
            end
        end
    end

    for diff, spellList in next, spellsToList do
        if next(spellList) then
            local heading = AceGUI:Create("Heading")
            heading:SetFullWidth(true)
            heading:SetText(diffIDtoName[diff])
            sf:AddChild(heading)
            for spell, school in pairs(spellList) do
                local name, rank, icon = GetSpellInfo(spell)
                if name then
                    local label = AceGUI:Create("InteractiveLabel")
                    if rank and #rank > 0 then
                        label:SetText((" [%s (%s)] |cff777777(%d)|r"):format(name, rank, spell))
                    else
                        label:SetText((" [%s] |cff777777(%d)|r"):format(name, spell))
                    end
                    local colors = COMBATLOG_DEFAULT_COLORS.schoolColoring[school] or COMBATLOG_DEFAULT_COLORS.schoolColoring.default
                    if colors then
                        label.label:SetTextColor(colors.r, colors.g, colors.b, colors.a)
                    end
                    label:SetFullWidth(true)
                    local p, h, f = label.label:GetFont()
                    label:SetFont(STANDARD_TEXT_FONT, 12, f)
                    label:SetUserData("spellID", spell)
                    label:SetUserData("spell", spell)
                    label:SetUserData("zone", zone)
                    label:SetUserData("mobID", mobID)
                    label:SetCallback("OnEnter", showSpellTooltip)
                    label:SetCallback("OnLeave", GameTooltip_Hide)
                    label:SetCallback("OnClick", addLink)
                    label:SetHighlight("Interface\\Buttons\\UI-PlusButton-Hilight")
                    if icon then
                        label:SetImage(icon)
                        label:SetImageSize(22, 22)
                    end

                    sf:AddChild(label)
                end
            end
        end
    end

    widget:AddChild(sf)
end

function MobSpells:CreateFrame()
    if frame then return end

    local f = AceGUI:Create("Frame")
    _G["MobSpellsFrame"] = f.frame
    UISpecialFrames[#UISpecialFrames+1] = "MobSpellsFrame"

    f:SetTitle(L["Mob Spells"])
    f:SetStatusText("")
    f:SetLayout("Flow")
    f:SetWidth(650)
    f:SetHeight(450)

    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetText(L["NPCs"])
    dropdown:SetLabel(L["Search"])
    dropdown:SetList({NPC = L["NPCs"], SPELL = L["Spells"], ZONE = L["Zones"]})
    dropdown:SetWidth(100)
    dropdown:SetCallback("OnValueChanged",function(widget,event,value) MobSpells.searchIndex = value end )

    local edit = AceGUI:Create("EditBox")
    edit:SetText("")
    edit:SetWidth(200)
    edit:SetLabel(L["Keywords"])
    edit:SetCallback("OnEnterPressed",function(widget,event,text) MobSpells:Filter(text) end )
    edit:SetCallback("OnTextChanged",function(widget,event,text) MobSpells:Filter(text) end )
    f.editBox = edit

    local tgtbutton = AceGUI:Create("Button")
    tgtbutton:SetText(L["Find Target"])
    tgtbutton:SetWidth(150)
    tgtbutton:SetCallback("OnClick", self.GetTargetSpells)

    local t = AceGUI:Create("TreeGroup")
    t:SetLayout("Fill")
    t:SetCallback("OnGroupSelected", SelectSpell)
    t:SetCallback("OnClick", self.OnTreeClick)
    t:SetFullWidth(true)
    t:SetFullHeight(true)

    f:AddChildren(dropdown, edit, tgtbutton, t)

    f.tree = t

    frame = f
end

do
    local menuFrame = CreateFrame("Frame", "MobSpellsMenu", UIParent, "UIDropDownMenuTemplate")
    local deleteEntry = function(_, uniq)
        local zone, mobID, spellID = ("\001"):split(uniq)
        spellID, mobID = tonumber(spellID), tonumber(mobID)
        if spellID then
            MobSpells:Print(L["Deleted "] .. (GetSpellInfo(spellID) or L["Melee Attack"]))
            mobs[zone][mobID].spells[spellID] = nil
            frame.tree:SelectByValue(zone .. "\001" .. mobID)
            local ct = 0
            for k, v in pairs(mobs[zone][mobID].spells) do
                ct = ct + 1
            end
            if ct == 0 then
                mobs[zone][mobID] = nil
                ct = 0
                for k, v in pairs(mobs[zone]) do
                    ct = ct + 1
                end
                if ct == 0 then
                    mobs[zone] = nil
                end
            end
        elseif mobID then
            MobSpells:Print(L["Deleted "] .. mobs[zone][mobID].name)
            mobs[zone][mobID] = nil

            local ct = 0
            for k, v in pairs(mobs[zone]) do
                ct = ct + 1
            end
            if ct == 0 then
                mobs[zone] = nil
            end
        else
            MobSpells:Print(L["Deleted "] .. zone)
            mobs[zone] = nil
        end
        if MobSpellsFrame:IsVisible() then
            frame.tree:SetTree(MobSpells:BuildTree())
        end
    end

    local reportEntry = function(_, uniq)
        local zone, mobID = ("\001"):split(uniq)
        mobID = tonumber(mobID)
        MobSpells:ReportMobSpells(zone, mobID)
    end

    local menuDelete = {
        {}
    }
    local menuCancel = { text = L["Cancel"], func = function() CloseDropDownMenus(1) end }

    function addLink(self)
        menuFrame:Hide()
        if GetMouseButtonClicked() == "RightButton" then
            menuDelete[1].text = L["Delete this spell"]
            menuDelete[1].func = deleteEntry
            menuDelete[1].arg1 = self:GetUserData("zone") .. "\001" .. self:GetUserData("mobID") .. "\001" .. self:GetUserData("spellID")
            menuDelete[2] = menuCancel
            menuDelete[3] = nil
            EasyMenu(menuDelete, menuFrame, "cursor", nil, nil, "MENU")
        else
            if IsShiftKeyDown() and ChatFrame1EditBox:IsShown() then
                ChatFrame1EditBox:Insert(GetSpellLink(self:GetUserData("spellID")))
            end
        end
    end

    function MobSpells.OnTreeClick(widget, evt, unique, selected)
        menuFrame:Hide()
        if GetMouseButtonClicked() == "RightButton" then
            local zone, mobID = ("\001"):split(unique)
            menuDelete[1].arg1 = unique
            menuDelete[1].func = deleteEntry
            if mobID then
                menuDelete[1].text = L["Delete this mob"]
                menuDelete[2] = {}
                menuDelete[2].text = L["Report this mob"]
                menuDelete[2].arg1 = unique
                menuDelete[2].func = reportEntry
                    menuDelete[3] = menuCancel
                menuDelete[4] = nil
            else
                menuDelete[1].text = L["Delete this zone"]
                    menuDelete[2] = menuCancel
                menuDelete[3] = nil
            end
            EasyMenu(menuDelete, menuFrame, "cursor", nil, nil, "MENU")
        end
    end
end

local function comp(a, b)
    if a.text > b.text then
        return false
    elseif a.text < b.text then
        return true
    else
        if a.value > b.value then
            return false
        elseif a.value < b.value then
            return true
        else
            return false
        end
    end
end

local t = {}
function MobSpells:BuildTree() -- 5.4 bug fixed on Ace3 side
    t = wipe(t)

    local zones = {}
    for zone in pairs(mobs) do
        zones[#zones+1] = zone
    end
    table_sort(zones)

    for i, zone in next, zones do
        local tzone = {text=zone,value=zone}
        local tmp = {}
        for id, data in pairs(mobs[zone]) do
            tmp[#tmp+1] = {text=data.name, value=id}
        end
        table_sort(tmp, comp)
        tzone.children = tmp
        t[#t+1] = tzone
    end
    zones = nil

    return t
end

function MobSpells:Filter(text)
    local t = self:BuildTree()
    -- Iterate zones
    local zOffset = 0
    for i = 1, #t do
        local v = t[i-zOffset]
        local offset = 0
        if self.searchIndex == "ZONE" then
            if v and #v.children == 0 then
                tremove(t, i - zOffset)
                zOffset = zOffset + 1
            end
            if not v.text:lower():match(text:lower()) then
                tremove(t, i - zOffset)
            end
        else
            for j = 1, #v.children do
                local child = v.children[j-offset]
                local useMob = false
                if #text == 0 then
                    useMob = true
                end
                if self.searchIndex == "NPC" then
                    -- escape magic chars so we can search for eg. 'Shado-Pan' without tripping over '-'
                    if child.text:lower():match((text:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")):lower()) then
                        useMob = true
                    end
                elseif self.searchIndex == "SPELL" then
                    for k, v in pairs(mobs[v.value][child.value].spells) do
                        local name = GetSpellInfo(k)
                        if name and name:lower():match(text:lower()) then
                            useMob = true
                            break
                        end
                    end
                end
            end
            if not useMob then
                tremove(v.children, j - offset)
                offset = offset + 1
            end
            if #v.children == 0 then
                tremove(t, i - zOffset)
                zOffset = zOffset + 1
            end
        end
    end
    frame.tree:SetTree(t)
end

function MobSpells:GetSpells(unit)
    if not UnitExists(unit) then
        self:Print(L["No target selected"])
        return
    end
    local name = UnitName(unit)
    MobSpells.searchIndex = "NPC"
    self:Show()
    frame.editBox:SetText(name)
    self:Filter(name)
    local guid = UnitGUID(unit)
    local _, _, _, _, _, npc_id = strsplit("-", guid);
    local NPCID = tonumber(npc_id, 16)
    frame.tree:SelectByValue(GetRealZoneText() .. "\001" .. NPCID)
end

function MobSpells.GetTargetSpells()
    MobSpells:GetSpells(UnitExists("target") and "target" or "mouseover")
end

function MobSpells:ReportTargetSpells()
    local unit = UnitExists("target") and "target" or "mouseover"
    if not UnitExists(unit) then
        self:Print(L["No target selected"])
        return
    end
    local guid = UnitGUID(unit)
    local _, _, _, _, _, npc_id = strsplit("-", guid);
    local NPCID = tonumber(npc_id, 16)
    local name = UnitName(unit)

    self:ReportMobSpells(GetRealZoneText(), NPCID, name)
end

local function SendMsg(s)
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        SendChatMessage(s,"RAID")
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        SendChatMessage(s,"INSTANCE_CHAT")
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        SendChatMessage(s,"PARTY")
    else
        print(s)
    end
end

function MobSpells:ReportMobSpells(zone, NPCID, nameoptional)
    local name = nameoptional or (mobs[zone] and mobs[zone][NPCID] and mobs[zone][NPCID].name) or ""
    local s = name .. L[" casts: "]
    local added = false
    if mobs and mobs[zone] and mobs[zone][NPCID] and mobs[zone][NPCID].spells then
        for k, v in pairs(mobs[zone][NPCID].spells) do
            local link = GetSpellLink(k)
            if link and #link > 0 and not SPELL_BLACKLIST[k] then
                if #s + #link > 255 then
                    SendMsg(s)
                    s = ""
                end
                s = s .. link
                added = true
            end
        end
        if #s > 0 and added then
            SendMsg(s)
        elseif not added then
            print(L["No recorded spells for "] .. name)
        end
    end
end
function MobSpells:Show()
    self:CreateFrame()
    frame.tree:SetTree(self:BuildTree())
    frame:Show()
end
function MobSpells:Toggle()
    if frame and frame:IsShown() then
        frame:Hide()
    else
        self:Show()
    end
end
