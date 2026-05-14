-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelBaHuangEditSkillView
-- Date: 2024-01-25 16:09:51
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbSkillNum = {
    [1] = 1,
    [2] = 4,
    [3] = 1,
    [4] = 6,
}

local UIPanelBaHuangEditSkillView = class("UIPanelBaHuangEditSkillView")

function UIPanelBaHuangEditSkillView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelBaHuangEditSkillView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelBaHuangEditSkillView:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleGroupSelect, EventType.OnToggleGroupSelectedChanged, function(toggle, nIndex)
        self:OnSelectSettingType(nIndex)
    end)
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.ToggleFightDataSwitch2, EventType.OnSelectChanged, function(_, bSelect)
        UIHelper.SetVisible(self.WidgetShow, not bSelect)
        UIHelper.LayoutDoLayout(self.LayoutSkillTog)
        UIHelper.LayoutDoLayout(self.WidgetShow)
        UIHelper.LayoutDoLayout(self.WidgetAutoFightSwitch)
        BahuangData.SetAutoCastAllSkill(bSelect)
    end)

    for nIndex, Btn in ipairs(self.tbBtnRecall) do
        UIHelper.BindUIEvent(Btn, EventType.OnClick, function()
            local tbSkillInfo = BahuangData.GetSkillInfoByIndex(nIndex + 1)
            BahuangData.DeleteSkill(tbSkillInfo.nType, tbSkillInfo.dwSkillID, BahuangData.IsShowDropConfirm())
        end)
    end

    UIHelper.BindUIEvent(self.ToggleFightDataSwitch1, EventType.OnSelectChanged, function(_, bSelect)
        BahuangData.SetEnableBreakFirstSkill(bSelect)
    end)

    UIHelper.BindUIEvent(self.ToggleFightDataSwitch, EventType.OnSelectChanged, function(_, bSelect)
        BahuangData.SetShowDropConfirm(bSelect)
    end)
end

function UIPanelBaHuangEditSkillView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnGetSkillList, function()
        self:UpdateBankSkillCount()
        self:InitWidgetSkill()
    end)

    Event.Reg(self, EventType.OnExChangeBahuangSkill, function()
        self:InitWidgetSkill()
    end)

    Event.Reg(self, EventType.OnMoveBahungSkill, function(nIndex, bStart)
        self:UpdateBtnRecall(nIndex, not bStart)
    end)
end

function UIPanelBaHuangEditSkillView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelBaHuangEditSkillView:UpdateInfo()
    BahuangData.SetShowRedPoint(false)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupSelect, self.TogBahuangBuff)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupSelect, self.TogBahuangSkill)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupSelect, self.TogSkillSetting)
    UIHelper.SetToggleGroupSelected(self.ToggleGroupSelect, 0)
    UIHelper.SetSelected(self.ToggleFightDataSwitch2, BahuangData.IsAutoCastAllSkill(), true)

    UIHelper.SetSelected(self.ToggleFightDataSwitch, BahuangData.IsShowDropConfirm(), false)
    self:InitBankSkill()
    self:InitAutoSkill()
    self:InitWidgetSkill()
end

function UIPanelBaHuangEditSkillView:InitBankSkill()
    for nIndex = 1, 12 do
        if nIndex % 2 == 1 then 
            UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangBuffGroup, self.LayoutBahuangBuff, nIndex, self.ToggleGroupBuffGroup)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutBahuangBuff)
    self:UpdateBankSkillCount()
end

function UIPanelBaHuangEditSkillView:UpdateBankSkillCount()
    local nCount = BahuangData.GetBangSkillListLength()
    local szCount = string.format("（%s/%s）", nCount, tbSkillNum[4])
    UIHelper.SetString(self.LabelBuffProgress, szCount)
end

function UIPanelBaHuangEditSkillView:InitAutoSkill()
    local tbSetting = {
        {szName = "心决", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
        {szName = "秘技1", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
        {szName = "秘技2", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
        {szName = "秘技3", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
        {szName = "秘技4", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
        {szName = "绝学", funcSetting = function(nIndex, bSelect) BahuangData.SetAutoCast(nIndex, bSelect) end},
    }
    for nIndex, tbSettingInfo in ipairs(tbSetting) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSettingTog, self.LayoutSkillTog, tbSettingInfo, nIndex)
    end

    UIHelper.LayoutDoLayout(self.LayoutSkillTog)
    UIHelper.LayoutDoLayout(self.WidgetShow)
    UIHelper.LayoutDoLayout(self.WidgetAutoFightSwitch)

    UIHelper.SetSelected(self.ToggleFightDataSwitch1, BahuangData.IsEnableBreakFirstSkill(), false)
end

function UIPanelBaHuangEditSkillView:InitWidgetSkill()
    local tbName = {"心决", "秘技1", "秘技2", "秘技3", "秘技4", "绝学"}
    for nIndex, WidgetSkill in ipairs(self.tbWidgetSkill) do
        local tbSkillInfo = BahuangData.GetSkillInfoByIndex(nIndex)
        UIHelper.RemoveAllChildren(WidgetSkill)
        local scriptView = nil
        if tbSkillInfo then 
            scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSkillCell, WidgetSkill, tbSkillInfo, self.ToggleGroupSelect, nil, nIndex)
        else
            scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetBahuangSkillCell, WidgetSkill, nil, self.ToggleGroupSelect, tbName[nIndex], nIndex)
        end
        scriptView:SetOnDragEndedCallBack(function(tbSkillInfo)--拖动结束回调
            return self:OnDragEnded(scriptView, nIndex)
        end) 
        if nIndex >= 2 then
            UIHelper.SetVisible(self.tbBtnRecall[nIndex - 1], tbSkillInfo ~= nil)
        end
    end
end 

function UIPanelBaHuangEditSkillView:UpdateBtnRecall(nIndex, bShow)
    local tbSkillInfo = BahuangData.GetSkillInfoByIndex(nIndex)
    UIHelper.SetVisible(self.tbBtnRecall[nIndex - 1], tbSkillInfo ~= nil and bShow)
end


function UIPanelBaHuangEditSkillView:OnSelectSettingType(nIndex)
    UIHelper.SetVisible(self.WidgetContentBahuangBuff, nIndex == 0)
    UIHelper.SetVisible(self.WidgetContentBahuangSkillEdit, nIndex == 1)
    UIHelper.SetVisible(self.WidgetContentSkillSetting, nIndex == 2)
end

function UIPanelBaHuangEditSkillView:OnDragEnded(script1, nOriginIndex)
    local script2, nIndex = self:GetScriptByCursorPosition(nOriginIndex)
    if script2 then
        return BahuangData.ExChangeSkill(script1, script2, nOriginIndex, nIndex)
    end
    return false
end


function UIPanelBaHuangEditSkillView:GetScriptByCursorPosition(nOriginIndex)
    for nIndex, WidgetSkill in ipairs(self.tbWidgetSkill) do
        local node = UIHelper.GetChildren(WidgetSkill)[1]
        local scriptView = UIHelper.GetBindScript(node)
        if scriptView:HitTest() and nIndex ~= nOriginIndex then
           return scriptView, nIndex
        end
    end
    return nil, nil
end


return UIPanelBaHuangEditSkillView