-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahungSkillTableCellView
-- Date: 2024-01-02 10:01:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahungSkillTableCellView = class("UIWidgetBahungSkillTableCellView")

function UIWidgetBahungSkillTableCellView:OnEnter(tbSKillInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbSKillInfo = tbSKillInfo
    self:UpdateInfo()
end

function UIWidgetBahungSkillTableCellView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahungSkillTableCellView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSkillTips, EventType.OnClick, function()
        local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, self.BtnSkillTips, TipsLayoutDir.RIGHT_CENTER,
        self.tbSKillInfo.dwSkillID, nil, nil, self.tbSKillInfo.dwLevel)
        tipsScriptView:SetBtnVisible(false)
    end)
end

function UIWidgetBahungSkillTableCellView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBahungSkillTableCellView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahungSkillTableCellView:UpdateInfo()
    local tbSKillInfo = self.tbSKillInfo
    local szName = Table_GetSkillName(tbSKillInfo.dwSkillID, tbSKillInfo.dwLevel)
    UIHelper.SetString(self.LabelSkillName, UIHelper.GBKToUTF8(szName))

    -- local nIconID = Table_GetSkillIconID(tbSKillInfo.dwSkillID, tbSKillInfo.dwLevel)
    local szImaPath = TabHelper.GetSkillIconPathByIDAndLevel(tbSKillInfo.dwSkillID, tbSKillInfo.dwLevel)
    UIHelper.SetTexture(self.ImgSkillIcon, szImaPath, true, function()
        UIHelper.UpdateMask(self.MaskSkillIcon)
    end)

    UIHelper.SetString(self.LabelObtainNum, tbSKillInfo.nGet)
    UIHelper.SetString(self.LabelSuccessNum, tbSKillInfo.nClear)
    UIHelper.UpdateMask(self.MaskSkillIcon)
end


return UIWidgetBahungSkillTableCellView