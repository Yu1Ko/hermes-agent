-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetRightPopLabel
-- Date: 2023-04-07 09:34:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetRightPopLabel = class("UIWidgetRightPopLabel")

function UIWidgetRightPopLabel:OnEnter(szText, bFinished)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szText = szText
    self.bFinished = bFinished
    self:UpdateInfo()
end

function UIWidgetRightPopLabel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetRightPopLabel:BindUIEvent()

end

function UIWidgetRightPopLabel:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRightPopLabel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetRightPopLabel:UpdateInfo()
    UIHelper.SetString(self.LabelTask, self.szText)
    UIHelper.SetSpriteFrame(self.ImgTag, self.bFinished and "UIAtlas2_Public_PublicButton_PublicButton1_btnTog" or "UIAtlas2_Public_PublicPanel_PublicPanel1_TitielHintImg")
end


return UIWidgetRightPopLabel