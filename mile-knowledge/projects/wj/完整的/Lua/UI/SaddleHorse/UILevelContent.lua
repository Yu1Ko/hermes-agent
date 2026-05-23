-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILevelContent
-- Date: 2022-12-07 16:11:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UILevelContent = class("UILevelContent")

function UILevelContent:OnEnter(szTitle, szLevelContent, nIconID, szFeedTip)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szTitle = szTitle
    self.szLevelContent = szLevelContent
    self.nIconID = nIconID
    self.szFeedTip = szFeedTip or ""

    self:UpdateInfo()
end

function UILevelContent:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UILevelContent:BindUIEvent()

end

function UILevelContent:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UILevelContent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILevelContent:UpdateInfo()
    if self.nIconID == nil then
        return
    end
    UIHelper.SetString(self.LabelLevel, self.szTitle)
    UIHelper.SetString(self.LabelLevelContent, self.szLevelContent)
    UIHelper.SetVisible(self.RichHungryWarning, self.szFeedTip ~= "")
    UIHelper.SetVisible(self.WidgetAniArrow, self.szFeedTip ~= "")
    UIHelper.SetRichText(self.RichHungryWarning, "<color=#ff7676>" .. self.szFeedTip .. "</color>")
    UIHelper.SetItemIconByIconID(self.ImgSkill, self.nIconID)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end


return UILevelContent