-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahuangBuffCell
-- Date: 2024-01-26 10:15:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahuangBuffCell = class("UIWidgetBahuangBuffCell")

function UIWidgetBahuangBuffCell:OnEnter(toggleGroup, tbBuffInfo, bBuff)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.toggleGroup = toggleGroup
    self.tbBuffInfo = tbBuffInfo
    self.bBuff = bBuff
    if bBuff then
        self:UpdateBuffInfo()
    else
        self:UpdateInfo()
    end
end

function UIWidgetBahuangBuffCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahuangBuffCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSkill, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect and self.tbBuffInfo then
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, self.TogSkill,
            TipsLayoutDir.TOP_LEFT, self.tbBuffInfo.dwSkillID, nil, nil, self.tbBuffInfo.nSkillLevel)
            tipsScriptView:SetBtnVisible(false)
        end
    end)
end

function UIWidgetBahuangBuffCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBahuangBuffCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahuangBuffCell:UpdateBuffInfo()
    local tbExpProgressData = BahuangData.GetExpProgressData()
    local nLevel = tbExpProgressData.nLevel
    local nBuffID = BahuangData.GetLevelBuffID()
    local szName = Table_GetBuffName(nBuffID, nLevel)
    UIHelper.SetString(self.LabelBuffName, UIHelper.GBKToUTF8(szName))

    local nIconID = Table_GetBuffIconID(nBuffID, nLevel)
    local szPath = UIHelper.GetIconPathByIconID(nIconID)
    UIHelper.SetTexture(self.ImgSkillIcon, szPath, true, function()
        UIHelper.UpdateMask(self.MaskSkill)
    end)

    UIHelper.UpdateMask(self.MaskSkill)

    UIHelper.ToggleGroupAddToggle(self.toggleGroup, self.TogSkill)
    UIHelper.SetCanSelect(self.TogSkill, false)
    UIHelper.SetVisible(self.LabelBuffLevel, false)
end

function UIWidgetBahuangBuffCell:UpdateInfo()
    local tbBuffInfo = self.tbBuffInfo
    UIHelper.SetTexture(self.ImgSkillIcon, tbBuffInfo ~= nil and TabHelper.GetSkillIconPathByIDAndLevel(tbBuffInfo.dwSkillID, tbBuffInfo.nSkillLevel) or "", true, function()
        UIHelper.UpdateMask(self.MaskSkill)
    end)
    UIHelper.SetString(self.LabelBuffName, tbBuffInfo ~= nil and UIHelper.GBKToUTF8(Table_GetSkillName(tbBuffInfo.dwSkillID, tbBuffInfo.nSkillLevel)) or "")
    UIHelper.UpdateMask(self.MaskSkill)

    UIHelper.SetString(self.LabelBuffLevel, tbBuffInfo ~= nil and tbBuffInfo.nSkillLevel or 0)
    UIHelper.SetVisible(self.LabelBuffLevel, tbBuffInfo ~= nil)
end

return UIWidgetBahuangBuffCell