-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetKillFeedCell
-- Date: 2025-11-20 15:42:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetKillFeedCell = class("UIWidgetKillFeedCell")

local MAX_NAME_CHAR_COUNT = 6
function UIWidgetKillFeedCell:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self:UpdateInfo()
end

function UIWidgetKillFeedCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetKillFeedCell:BindUIEvent()
    
end

function UIWidgetKillFeedCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetKillFeedCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ¡ý¡ý¡ý
-- ----------------------------------------------------------

function UIWidgetKillFeedCell:UpdateInfo()
    if not self.tInfo then
        return
    end
    UIHelper.SetVisible(self.ImgKill, self.tInfo.dwType == 0)
    UIHelper.SetVisible(self.ImgHelp, self.tInfo.dwType == 1)
    UIHelper.SetStringEllipsis(self.LabelMessageNameL, UIHelper.GBKToUTF8(self.tInfo.szKiller), MAX_NAME_CHAR_COUNT)
    UIHelper.SetStringEllipsis(self.LabelMessageNameR, UIHelper.GBKToUTF8(self.tInfo.szTarget), MAX_NAME_CHAR_COUNT)

    local tConfig = Table_GetKillFeedConfig(self.tInfo.dwEffectID)
    if not tConfig then
        return
    end

    if tConfig.szMBBgPath ~= "" then
        UIHelper.SetSpriteFrame(self.ImgKillFeedBg, tConfig.szMBBgPath)
    end

    if tConfig.szMBSFXPath ~= "" then
        self.bHasSFX = true
        UIHelper.SetVisible(self.SFXKillFeedBg, true)
        UIHelper.SetSFXPath(self.SFXKillFeedBg, tConfig.szMBSFXPath)
        UIHelper.PlaySFX(self.SFXKillFeedBg)
        UIHelper.SetVisible(self.SFXKill, false)
        UIHelper.SetVisible(self.ImgKillFeedBg, false)
    else
        UIHelper.SetVisible(self.SFXKillFeedBg, false)
        UIHelper.SetVisible(self.SFXKill, true)
        UIHelper.PlaySFX(self.SFXKill)
    end
end


return UIWidgetKillFeedCell