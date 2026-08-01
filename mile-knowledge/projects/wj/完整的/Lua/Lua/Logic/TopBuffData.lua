-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: TopBuffData
-- Date: 2025-03-11 10:45:49
-- Desc: DX TopBuff.lua 功能实现
-- ---------------------------------------------------------------------------------

TopBuffData = TopBuffData or {className = "TopBuffData"}
local self = TopBuffData

local tArenaAllPlayer = {}

function TopBuffData.Init()
    self.RegEvent()

    self.tTopBuffMsgCache = {}
end

function TopBuffData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function TopBuffData.RegEvent()
    Event.Reg(self, EventType.OnChangeTopBuffSetting, function()
        local bForce = true
        local bShow = GameSettingData.GetNewValue(UISettingKey.ShowArenaHeadBuff) or self.IsSettingMode()
        print("[TopBuffData] OnChangeTopBuffSetting", bShow)
        local dwType, dwID = Target_GetTargetData()
        local pSelf = GetClientPlayer()
        if TypeIsPlayer(dwType, dwID) then
            self.dwTargetID = dwID
            self.UpdateTopBuff(bShow, dwID, bForce)
        end
        if pSelf then
            self.UpdateTopBuff(bShow, pSelf.dwID, bForce)
        end
        if TopBuffData.IsInArena() then
            ArenaData.SetShowTop(bShow, bForce)
        end
    end)
    Event.Reg(self, "LOADING_END", function()
        local pPlayer = GetClientPlayer()
        if pPlayer then
            self.UpdateTopBuff(true, pPlayer.dwID)
        end
    end)
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelHint then
            local bShow = GameSettingData.GetNewValue(UISettingKey.ShowArenaHeadBuff) or self.IsSettingMode()
            if bShow then
                for _, dwPlayerID in ipairs(self.tTopBuffMsgCache) do
                    print("[TopBuffData] CreateTopBuff (from cache)", dwPlayerID)
                    Event.Dispatch(EventType.OnShowArenaTopBuff, dwPlayerID)
                end
            end
            self.tTopBuffMsgCache = {}
        end
    end)
    Event.Reg(self, EventType.OnTargetChanged, function(nTargetType, nTargetId)
        -- print("[TopBuffData] OnTargetChanged", nTargetType, nTargetId, self.dwTargetID)
        if self.dwTargetID == nTargetId then
            return
        end

        local player = GetClientPlayer()
        if not player then
            return
        end

        if self.dwTargetID then
            if not TopBuffData.IsInArena() and self.dwTargetID ~= player.dwID then
                self.CloseTopBuff(self.dwTargetID)
            end
            self.dwTargetID = nil
        end

        if TypeIsPlayer(nTargetType, nTargetId) then
            self.UpdateTopBuff(true, nTargetId)
            self.dwTargetID = nTargetId
        end
    end)
    Event.Reg(self, "PLAYER_ENTER_SCENE", function(dwPlayerID)
        local bShow = GameSettingData.GetNewValue(UISettingKey.ShowArenaHeadBuff)
        if not bShow then
            return
        end

        if not TopBuffData.IsInArena() then
            return
        end
        self.CreateTopBuff(dwPlayerID)
    end)
    Event.Reg(self, "PLAYER_LEAVE_SCENE", function(dwPlayerID)
        self.CloseTopBuff(dwPlayerID)
    end)
    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self.tTopBuffMsgCache = {}
        self.dwTargetID = nil
        self.bSettingMode = false
    end)
end

function TopBuffData.CreateTopBuff(dwPlayerID)
    local bSettingMode = not self.IsSettingMode()
    if DungeonData.IsInDungeon() and not bSettingMode then
        return
    end

    local bShow = GameSettingData.GetNewValue(UISettingKey.ShowArenaHeadBuff) or bSettingMode
    if not bShow then
        return
    end

    if not UIMgr.IsViewOpened(VIEW_ID.PanelHint) and not table.contain_value(self.tTopBuffMsgCache, dwPlayerID) then
        table.insert(self.tTopBuffMsgCache, dwPlayerID)
        return
    end

    -- print("[TopBuffData] CreateTopBuff", dwPlayerID)
    Event.Dispatch(EventType.OnShowArenaTopBuff, dwPlayerID)
end

function TopBuffData.CloseTopBuff(dwPlayerID)
    table.remove_value(self.tTopBuffMsgCache, dwPlayerID)

    -- print("[TopBuffData] CloseTopBuff", dwPlayerID)
    Event.Dispatch(EventType.OnHideArenaTopBuff, dwPlayerID)
end

local function IsLegalUpdate(bShow, dwPlayerID, bForceSet)
	local pPlayer = GetClientPlayer()
	if not pPlayer or not dwPlayerID then
		return
	end

	if bForceSet then
		return true
	elseif (bShow and GameSettingData.GetNewValue(UISettingKey.ShowArenaHeadBuff)) then
		return true
	elseif (not bShow and not TopBuffData.IsInArena() and dwPlayerID ~= pPlayer.dwID) then
		return true
	end

	return false
end

function TopBuffData.UpdateTopBuff(bShow, dwPlayerID, bForceSet)
    if IsLegalUpdate(bShow, dwPlayerID, bForceSet) then
		if bShow then
			self.CreateTopBuff(dwPlayerID)
		else
			self.CloseTopBuff(dwPlayerID)
		end
	end
end

function TopBuffData.SetSettingMode(bEnabled)
    self.bSettingMode = bEnabled
    Event.Dispatch(EventType.OnChangeTopBuffSetting)
end

function TopBuffData.IsSettingMode()
    return self.bSettingMode or false
end

function TopBuffData.SetTopBuffSetting(tSetting)
    tSetting = tSetting or Storage.TopBuffSetting
    local nIconSize = tSetting.nIconSize or TopBuffDefaultInfo.nIconSize.nDefault
    local nIconPosition = tSetting.nIconPosition or TopBuffDefaultInfo.nIconPosition.nDefault
    Event.Dispatch(EventType.OnTopBuffSetting, nIconSize, nIconPosition)
end

function TopBuffData.IsInArena()
    return ArenaData.IsInArena() or ArenaTowerData.IsInArenaTowerMap()
end