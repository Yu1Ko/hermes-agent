-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: PvpEnterConfirmationData
-- Date: 2024-11-05 11:15:44
-- Desc: UIPvpEnterConfirmationView Logic
-- ---------------------------------------------------------------------------------

PvpEnterConfirmationData = PvpEnterConfirmationData or {className = "PvpEnterConfirmationData"}
local self = PvpEnterConfirmationData

local tbDataTable = {}

function PvpEnterConfirmationData.Init()
    self.RegEvent()
end

function PvpEnterConfirmationData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

    for _, tbData in pairs(tbDataTable) do
        Timer.DelAllTimer(tbData)
    end
    tbDataTable = {}
end

function PvpEnterConfirmationData.RegEvent()
    Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        for nPlayType, tbData in pairs(tbDataTable) do
            if tbData.nPlayEnterConfirmationType ~= PlayEnterConfirmationType.Enter then
                self.CloseView(nPlayType)
            end
        end
    end)
end

-- tbInfo = {
--     szTitle = "",
--     onClickCancelQueue = function () end,
--     onClickGoOnQueue = function () end,
--     onClickEnter = function () end,
--     nStartTime = GetTickCount(),
--     nTotalCountDown = Const.MAX_BATTLE_FIELD_OVERTIME,
-- }
function PvpEnterConfirmationData.OpenView(nPlayEnterConfirmationType, nPlayType, tbInfo)
    Timer.DelAllTimer(tbDataTable[nPlayType])

    local tbData = {
        nPlayEnterConfirmationType = nPlayEnterConfirmationType,
        nPlayType = nPlayType,
        tbInfo = tbInfo,
        scriptView = tbDataTable[nPlayType] and tbDataTable[nPlayType].scriptView,
        bAutoEnter = true,
        nLeftTime1 = nil,
        nLeftTime2 = nil,
    }
    tbDataTable[nPlayType] = tbData

    if nPlayEnterConfirmationType == PlayEnterConfirmationType.Enter then
        if nPlayType == PlayType.Arena or nPlayType == PlayType.BattleField or nPlayType == PlayType.TongBattleField then
            self.StartUpdateEnterLeftTime(nPlayType)
        end
    end

    if tbData.scriptView and tbData.scriptView.bInit then
        tbData.scriptView:OnEnter(nPlayEnterConfirmationType, nPlayType, tbInfo)
    else
        tbData.scriptView = UIMgr.Open(VIEW_ID.PanelPvpEnterConfirmation, nPlayEnterConfirmationType, nPlayType, tbInfo)
    end
end

function PvpEnterConfirmationData.CloseView(nPlayType)
    if not tbDataTable[nPlayType] then
        return
    end

    PSMMgr.ExitPSMMode()

    UIMgr.Close(tbDataTable[nPlayType].scriptView)
    Timer.DelAllTimer(tbDataTable[nPlayType])
    tbDataTable[nPlayType] = nil
end

function PvpEnterConfirmationData.HideView(nPlayType)
    if not tbDataTable[nPlayType] or not tbDataTable[nPlayType].scriptView then
        return
    end

    PSMMgr.ExitPSMMode()

    UIMgr.Close(tbDataTable[nPlayType].scriptView)
    tbDataTable[nPlayType].scriptView = nil
end

function PvpEnterConfirmationData.ShowView(nPlayType)
    if not tbDataTable[nPlayType] or (tbDataTable[nPlayType].scriptView and tbDataTable[nPlayType].scriptView.bInit) then
        return
    end

    tbDataTable[nPlayType].scriptView = UIMgr.Open(VIEW_ID.PanelPvpEnterConfirmation, tbDataTable[nPlayType].nPlayEnterConfirmationType, nPlayType, tbDataTable[nPlayType].tbInfo)
end

function PvpEnterConfirmationData.StartUpdateEnterLeftTime(nPlayType)
    local tbInfo = tbDataTable[nPlayType] and tbDataTable[nPlayType].tbInfo
    if not tbInfo then
        return
    end

    Timer.DelAllTimer(tbDataTable[nPlayType])
    self.UpdateEnterLeftTime(nPlayType)

    Timer.AddCycle(tbDataTable[nPlayType], 0.1, function()
        self.UpdateEnterLeftTime(nPlayType)

        if tbDataTable[nPlayType].nLeftTime2 and tbDataTable[nPlayType].nLeftTime2 <= 0 then
            if tbDataTable[nPlayType].bAutoEnter then
                if tbInfo and tbInfo.onClickEnter then
                    tbInfo.onClickEnter()
                end
                self.CloseView(nPlayType)
                return
            end
        end

        if tbDataTable[nPlayType].nLeftTime1 and tbDataTable[nPlayType].nLeftTime1 <= 0 then
            self.CloseView(nPlayType)
        end
    end)
end

function PvpEnterConfirmationData.UpdateEnterLeftTime(nPlayType)
    local tbInfo = tbDataTable[nPlayType] and tbDataTable[nPlayType].tbInfo
    if not tbInfo then
        return
    end

    if not tbInfo.nStartTime or not tbInfo.nTotalCountDown then
        return
    end

    local nLeftTime1 = tbInfo.nTotalCountDown - math.floor((GetTickCount() - tbInfo.nStartTime) / 1000)
    local nLeftTime2 = Const.MAX_AUTO_ENTER_FIELD_OVERTIME - math.floor((GetTickCount() - tbInfo.nStartTime) / 1000)
    tbDataTable[nPlayType].nLeftTime1 = math.max(nLeftTime1, 0)
    tbDataTable[nPlayType].nLeftTime2 = math.max(nLeftTime2, 0)
end

function PvpEnterConfirmationData.SetAutoEnter(nPlayType, bAutoEnter)
    if not tbDataTable[nPlayType] then
        return
    end

    tbDataTable[nPlayType].bAutoEnter = bAutoEnter
end

function PvpEnterConfirmationData.GetData(nPlayType)
    return tbDataTable[nPlayType]
end

-- 测试用打印
-- function PvpEnterConfirmationData.TogglePrint()
--     if self.nPrintTimerID then
--         Timer.DelTimer(self, self.nPrintTimerID)
--         self.nPrintTimerID = nil
--     else
--         self.nPrintTimerID = Timer.AddCycle(self, 0.5, function()
--             local tab = {}
--             for nPlayType, tbData in pairs(tbDataTable) do
--                 local t = {}
--                 for k, v in pairs(tbData) do
--                     t[k] = k ~= "scriptView" and v or (v and "(exist)")
--                 end
--                 tab[nPlayType] = t
--             end
--             print_table(tab)
--         end)
--     end
-- end