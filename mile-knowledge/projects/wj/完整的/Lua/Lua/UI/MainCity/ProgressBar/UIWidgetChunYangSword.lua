-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UIWidgetChunYangSword
-- Date: 2025-07-24 15:00:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local nCycleTime = 1 / 8

local COUSTOM_BUFF_LIST_ID = 1
local SWORD_SKILL_ID = 18640
local OPEN_AUTO_ATTACK_SKILL_ID = 22987
local CLOSE_AUTO_ATTACK_SKILL_ID = 22989

-----------------------------DataModel------------------------------

local DataModel = {}

function DataModel.Init()
    DataModel.UpdateDataModel()
end

function DataModel.UnInit()
    DataModel.nCurrentBuffID = nil
    DataModel.nLeftTime = nil
    DataModel.nSwordNum = nil
end

function DataModel.UpdateDataModel()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    DataModel.nSwordNum = pPlayer.nCurrentRage
    DataModel.UpdateTime(pPlayer)
end

function DataModel.GetCurrentBuffID(pPlayer)
    local tBuffList = Table_GetCustomBuffList(COUSTOM_BUFF_LIST_ID)
    for _, nBuffID in ipairs(tBuffList) do
        if pPlayer.IsHaveBuff(nBuffID, 1) then
            return nBuffID
        end
    end
end

function DataModel.UpdateTime(pPlayer)
    DataModel.nCurrentBuffID = DataModel.GetCurrentBuffID(pPlayer)
    if DataModel.nCurrentBuffID then
        local tBuffInfo = {}
        Buffer_GetByID(pPlayer, DataModel.nCurrentBuffID, 0, tBuffInfo)
        if tBuffInfo.dwID then
            local nLeftFrame = Buffer_GetLeftFrame(tBuffInfo)
            local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)
            DataModel.nLeftTime = nHour * 3600 + nMinute * 60 + nSecond
        end
    end
end

local UIWidgetChunYangSword = class("UIWidgetChunYangSword")

function UIWidgetChunYangSword:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self:UpdateVisibility()
    end
end

function UIWidgetChunYangSword:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSword, EventType.OnClick, function()
        if self.nPoseState == 2 then
            OnUseSkill(OPEN_AUTO_ATTACK_SKILL_ID, (OPEN_AUTO_ATTACK_SKILL_ID % 10 + 1))
        else
            OnUseSkill(CLOSE_AUTO_ATTACK_SKILL_ID, (CLOSE_AUTO_ATTACK_SKILL_ID % 10 + 1))
        end
    end)
end

function UIWidgetChunYangSword:RegEvent()
    Event.Reg(self, "PLAYER_LEVEL_UPDATE", function()
        self:UpdateVisibility()
    end)

    Event.Reg(self, "LOADING_END", function()
        self:UpdateVisibility()
    end)

    Event.Reg(self, "ON_CHARACTER_POSE_STATE_UPDATE", function()
        self:UpdateCheck()
    end)
end

function UIWidgetChunYangSword:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetChunYangSword:UpdateVisibility()
    local nKungfuMountID = g_pClientPlayer and g_pClientPlayer.GetActualKungfuMountID()
    if not nKungfuMountID then
        return
    end
    local nSkillLevel = g_pClientPlayer.GetSkillLevel(SWORD_SKILL_ID)
    local bShow = nKungfuMountID == 10014 and nSkillLevel > 0 and not BattleFieldData.IsInTreasureBattleFieldMap()
    UIHelper.SetVisible(self._rootNode, bShow)

    Timer.DelAllTimer(self)
    if bShow then
        self:UpdateCheck()
        Timer.AddCycle(self, nCycleTime, function()
            DataModel.UpdateDataModel()
            self:UpdateView()
        end)
    end
end

function UIWidgetChunYangSword:UpdateCheck()
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end
    local nPoseState = hPlayer.nPoseState
    nPoseState = nPoseState == 0 and 1 or nPoseState -- nPoseState为0时 视为开启状态
    self.nPoseState = nPoseState
    UIHelper.SetVisible(self.ImgBtnOff, nPoseState == 2)
    UIHelper.SetVisible(self.ImgBtnOn, nPoseState == 1)

    UIHelper.SetVisible(self.WidgetSward, nPoseState == 2)
    UIHelper.SetVisible(self.WidgetSwardSFX, nPoseState == 1)
end

function UIWidgetChunYangSword:UpdateView()
    for i = 1, #self.tActiveSwords do
        UIHelper.SetActiveAndCache(self, self.tBgSwords[i], DataModel.nSwordNum >= i)
        UIHelper.SetActiveAndCache(self, self.tActiveSwords[i], DataModel.nSwordNum >= i)
    end

    if DataModel.nCurrentBuffID ~= nil then
        UIHelper.SetLabel(self.LabelNum, tostring(DataModel.nLeftTime))
    end
    UIHelper.SetActiveAndCache(self, self.LabelNum, DataModel.nCurrentBuffID ~= nil)
end

function UIWidgetChunYangSword:RefreshTime()

end

return UIWidgetChunYangSword