-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: PvpExtractData
-- Date: 2025-03-27 19:14:28
-- Desc: ?
-- ---------------------------------------------------------------------------------
local REMOTE_DATA_ID = 1183

PvpExtractData = PvpExtractData or {className = "PvpExtractData"}
local self = PvpExtractData
-------------------------------- 消息定义 --------------------------------
function PvpExtractData.Init()
    PvpExtractData.Reg()
end

function PvpExtractData.UnInit()
    self.nCurEventID = nil
    self.nEndTime = nil
end

function PvpExtractData.Reg()
    Event.Reg(self, EventType.OnRoleLogin, function ()
        package.loaded["scripts/Include/UIscript/UIScript_Linhai.lua"] = nil
        require("scripts/Include/UIscript/UIScript_Linhai.lua")
    end)

    Event.Reg(self, "PLAYER_LEAVE_SCENE", function (dwPlayerID)
        local player = PlayerData.GetClientPlayer()
        if player and player.dwID ~= dwPlayerID then
            return
        end

        self.nCurEventID = nil
        self.nEndTime = nil
        PvpExtractData.UnInitTeachBox()
    end)

    Event.Reg(self, EventType.OnTreasureHuntInfoOpen, function (dwID, nTime)
        self.nCurEventID = dwID
        self.nEndTime = not IsBoolean(nTime) and nTime or 0
        self:InitTeachBox()
    end)

    Event.Reg(self, "REMOTE_TBF_WARE_EVENT", function ()
        self.nUpdaterTimer = self.nUpdaterTimer or Timer.AddFrame(self, 1, function ()
            Event.Dispatch(EventType.OnTBFUpdateAllView)
            self.nUpdaterTimer = nil
        end)
    end)

    Event.Reg(self, "LOADING_END", function()
        if BattleFieldData.IsInXunBaoBattleFieldMap() then
            if JX_TargetList.IsShow() then
                JX_TargetList.SetVisible(false)
                Event.Dispatch(EventType.SwitchFocusVisibility, true)
            end
        end
    end)
end


function PvpExtractData.InitTeachBox()
    if not BattleFieldData.IsInXunBaoBattleFieldMap() then
        return
    end

    self.bShowTeachBox = true
    BubbleMsgData.PushMsgWithType("ExtractTeachBox",{
        nBarTime = 0,
        szAction = function ()
            TeachBoxData.OpenTeachBoxPanelWithSearch("寻宝模式")
        end,
    })
end

function PvpExtractData.UnInitTeachBox()
    if not self.bShowTeachBox then
        return
    end

    self.bShowTeachBox = false
    BubbleMsgData.RemoveMsg("ExtractTeachBox")
end

-------------------工具函数------------------------
function PvpExtractData.GetCurEventID()
    return self.nCurEventID
end

function PvpExtractData.GetEndTime()
    return self.nEndTime
end

function PvpExtractData.OpenBagAndHorse()
    local scriptView = UIMgr.OpenSingle(false, VIEW_ID.PanelBattleFieldXunBao)
    scriptView:OnShowHorse(true)
end

function PvpExtractData.CanGetBPReward()
    local hPlayer = GetClientPlayer()
    if not hPlayer.HaveRemoteData(REMOTE_DATA_ID) then
        hPlayer.ApplyRemoteData(REMOTE_DATA_ID, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK)
        return false
    end

    local tbInfo = GDAPI_TbfWareSeasonLvInfo()
    if not tbInfo then
        return false
    end

    local nGotLv = tbInfo.nGotLv
    local nCurLevel = tbInfo.nCurLv
    return nGotLv < nCurLevel
end