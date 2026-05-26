-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahuangBuffGroupView
-- Date: 2024-01-25 17:15:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahuangBuffGroupView = class("UIWidgetBahuangBuffGroupView")

function UIWidgetBahuangBuffGroupView:OnEnter(nIndex, toggleGroup)
    self.nIndex = nIndex
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.toggleGroup = toggleGroup
    self:UpdateInfo()
    self:AddToggleGroup()
end

function UIWidgetBahuangBuffGroupView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahuangBuffGroupView:BindUIEvent()
    for nIndex = 0, 1 do
        local WidgetBahuangBuff = self[string.format("WidgetBahuangBuff0%s", tostring(nIndex + 1))]
        UIHelper.BindUIEvent(WidgetBahuangBuff, EventType.OnSelectChanged, function(_, bSelect)
            if bSelect then
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
                local tbBankSkill = BahuangData.GetBangSkillListByIndex(self.nIndex + nIndex)
                local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, WidgetBahuangBuff,
                TipsLayoutDir.TOP_LEFT, tbBankSkill.dwSkillID, nil, nil, tbBankSkill.nSkillLevel)

                local szEquipText = tbBankSkill.nType == 4 and "卸下" or "装备"
                tipsScriptView:SetLeftButtonInfo(szEquipText, function()
                    BahuangData.OnLearnSkill(tbBankSkill.nType, tbBankSkill.dwSkillID)
                end)

                tipsScriptView:SetRightButtonInfo("丢弃", function()
                    BahuangData.DeleteSkill(tbBankSkill.nType, tbBankSkill.dwSkillID, false)
                end)
            end
        end)
    end
end

function UIWidgetBahuangBuffGroupView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnGetSkillList, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnExChangeBahuangSkill, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)
end

function UIWidgetBahuangBuffGroupView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahuangBuffGroupView:UpdateInfo()

    for nIndex = 0, 1 do

        local tbBankSkill = BahuangData.GetBangSkillListByIndex(self.nIndex + nIndex)

        local ImgSkillIcon = self[string.format("ImgSkillIcon0%s", tostring(nIndex + 1))]
        local MaskSkill = self[string.format("MaskSkill0%s", tostring(nIndex + 1))]
        local ImgUsing = self[string.format("ImgUsing0%s", tostring(nIndex + 1))]
        local LabelBuffLevel = self[string.format("LabelBuffLevel0%s", tostring(nIndex + 1))]
        local LabelBuffName = self[string.format("LabelBuffName0%s", tostring(nIndex + 1))]

        UIHelper.SetVisible(ImgSkillIcon, tbBankSkill ~= nil)
        UIHelper.SetVisible(ImgUsing, tbBankSkill ~= nil)
        UIHelper.SetVisible(LabelBuffLevel, tbBankSkill ~= nil)
        UIHelper.SetVisible(LabelBuffName, tbBankSkill ~= nil)

        if tbBankSkill then
            UIHelper.SetTexture(ImgSkillIcon, TabHelper.GetSkillIconPathByIDAndLevel(tbBankSkill.dwSkillID, tbBankSkill.nSkillLevel), true, function()
                UIHelper.UpdateMask(MaskSkill)
            end)
            UIHelper.UpdateMask(MaskSkill)
            UIHelper.SetString(LabelBuffLevel, tbBankSkill.nSkillLevel .. "级")
            UIHelper.SetString(LabelBuffName, UIHelper.GBKToUTF8(Table_GetSkillName(tbBankSkill.dwSkillID, tbBankSkill.nSkillLevel)))
            UIHelper.SetVisible(ImgUsing, tbBankSkill.nType == 4)
        end

        local WidgetBahuangBuff = self[string.format("WidgetBahuangBuff0%s", tostring(nIndex + 1))]
        UIHelper.SetCanSelect(WidgetBahuangBuff, tbBankSkill ~= nil, nil)
        UIHelper.SetSelected(WidgetBahuangBuff, false, false)

    end

end

function UIWidgetBahuangBuffGroupView:AddToggleGroup()

    for nIndex = 0, 1 do
        local WidgetBahuangBuff = self[string.format("WidgetBahuangBuff0%s", tostring(nIndex + 1))]
        UIHelper.ToggleGroupAddToggle(self.toggleGroup, WidgetBahuangBuff)
    end
end




return UIWidgetBahuangBuffGroupView