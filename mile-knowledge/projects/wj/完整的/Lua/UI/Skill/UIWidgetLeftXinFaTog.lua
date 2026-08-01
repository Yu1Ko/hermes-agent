-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetLeftXinFaTog
local UIWidgetLeftXinFaTog = class("UIWidgetLeftXinFaTog")

function UIWidgetLeftXinFaTog:OnEnter(nSkillID, bDisplayOnly)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nSkillID = nSkillID
        self.bDisplayOnly = bDisplayOnly
    end
    self:UpdateInfo()
end

function UIWidgetLeftXinFaTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetLeftXinFaTog:BindUIEvent()

end

function UIWidgetLeftXinFaTog:RegEvent()

end

function UIWidgetLeftXinFaTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetLeftXinFaTog:UpdateInfo()
    if self.nSkillID then
        local tSkillInfo = TabHelper.GetUISkill(self.nSkillID)
        local nHDKungFuID = self.nSkillID
        if tSkillInfo then
            local skillName1 = tSkillInfo.szName

            local szIconPath = PlayerKungfuImg[self.nSkillID]
            UIHelper.SetString(self.LabelSkill, skillName1)
            UIHelper.SetString(self.LabelSkill1, skillName1)
            UIHelper.SetSpriteFrame(self.ImgSkillIcon, szIconPath)
            UIHelper.SetSpriteFrame(self.ImgSkillSelectIcon, szIconPath)

            if self.WidgetImgIcon and self.WidgetImgIcon2 then
                UIHelper.SetSpriteFrame(self.WidgetImgIcon, szIconPath)
                UIHelper.SetSpriteFrame(self.WidgetImgIcon2, szIconPath)
            end

            nHDKungFuID = TabHelper.GetHDKungfuID(self.nSkillID)
            local nPosType = PlayerKungfuPosition[nHDKungFuID] or KUNGFU_POSITION.DPS
            local szXinFaImg = SkillKungFuTypeImg[nPosType]
            UIHelper.SetSpriteFrame(self.ImgXinFaType, szXinFaImg)
        else
            local tSkill = Table_GetSkill(self.nSkillID, 1)
            local szName = UIHelper.GBKToUTF8(tSkill.szName)
            UIHelper.SetString(self.LabelSkill, szName)
            UIHelper.SetString(self.LabelSkill1, szName)

            --local szImgPath = TabHelper.GetSkillIconPathByIDAndLevel(self.nSkillID, 1)
            UIHelper.SetSpriteFrame(self.ImgSkillIcon, PlayerKungfuImg[self.nSkillID])
            UIHelper.SetSpriteFrame(self.ImgSkillSelectIcon, PlayerKungfuImg[self.nSkillID])
        end

        local nPosType = PlayerKungfuPosition[nHDKungFuID] or KUNGFU_POSITION.DPS
        local szXinFaImg = SkillKungFuTypeImg[nPosType]
        UIHelper.SetSpriteFrame(self.ImgXinFaType, szXinFaImg)

        if not self.bDisplayOnly then
            local bLearned = g_pClientPlayer.GetSkillLevel(self.nSkillID) > 0
            UIHelper.SetVisible(self.ImgLock, not bLearned) -- 流派心法未学习时显示锁定状态
            UIHelper.SetNodeGray(self.TogSkill, not bLearned, true) -- 流派心法未学习时显示锁定状态
        end
    end
end

function UIWidgetLeftXinFaTog:GetToggle()
    return self.TogSkill
end

return UIWidgetLeftXinFaTog