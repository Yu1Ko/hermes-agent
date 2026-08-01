-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetCharacterSkill2
-- Date: 2024-11-26 11:07:19
-- Desc: WidgetCharacterSkill2 门客培养 附魔
-- ---------------------------------------------------------------------------------

local UIWidgetCharacterSkill2 = class("UIWidgetCharacterSkill2")

local COLOR_ACTIVE = "#95ff95"
local COLOR_UNACTIVE = "#b5bcc1"

function UIWidgetCharacterSkill2:OnEnter(dwEnchantID, bIsEnchantSuit, szTip)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwEnchantID = dwEnchantID
    self.tEnchantInfo = Table_GetNPCEnchantInfo(dwEnchantID)
    self.bIsEnchantSuit = bIsEnchantSuit
    self.szTip = szTip

    self:UpdateInfo()
end

function UIWidgetCharacterSkill2:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCharacterSkill2:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnEmptyTop, EventType.OnClick, function()
        if not string.is_nil(self.szTip) then
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnEmptyTop, TipsLayoutDir.TOP_CENTER, self.szTip)
        end
    end)
    
end

function UIWidgetCharacterSkill2:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCharacterSkill2:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCharacterSkill2:UpdateInfo()
    if self.dwEnchantID == 0 then
        UIHelper.SetRichText(self.LabelDetail, "未激活门客附魔")
        UIHelper.SetVisible(self.ImgBarTypeBg, true)
    else
        local szAttribute = UIHelper.GBKToUTF8(self.tEnchantInfo.szAttribute)
        local szSuitAttribute = UIHelper.GBKToUTF8(self.tEnchantInfo.szSuitAttribute)

        local szColor = self.bIsEnchantSuit and COLOR_ACTIVE or COLOR_UNACTIVE
        szSuitAttribute = UIHelper.AttachTextColor(szSuitAttribute, szColor)

        UIHelper.SetRichText(self.LabelDetail, szAttribute .. "\n" .. szSuitAttribute)
        -- UIHelper.SetSpriteFrame(self.ImgBarTypeBg, self.tEnchantInfo.szMobileIconFrame)
        UIHelper.SetVisible(self.ImgBarTypeBg, false)
        UIHelper.SetSpriteFrame(self.ImgIcon1, self.tEnchantInfo.szMobileFrame)
    end

    UIHelper.LayoutDoLayout(self._rootNode)
end

return UIWidgetCharacterSkill2