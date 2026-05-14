-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPlayerMvpNum
-- Date: 2023-12-20 15:13:04
-- Desc: WidgetPlayerMvpNum
-- ---------------------------------------------------------------------------------

local UIWidgetPlayerMvpNum = class("UIWidgetPlayerMvpNum")

function UIWidgetPlayerMvpNum:OnEnter(szName, nValue, szImgPath, bBreak)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szName, nValue, szImgPath, bBreak)
end

function UIWidgetPlayerMvpNum:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPlayerMvpNum:BindUIEvent()
    
end

function UIWidgetPlayerMvpNum:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPlayerMvpNum:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPlayerMvpNum:UpdateInfo(szName, nValue, szImgPath, bBreak)
    UIHelper.SetString(self.LabelPlayerNumTitle, szName)
    UIHelper.SetString(self.LabelPlayerNum, tostring(nValue))
    UIHelper.SetSpriteFrame(self.IconPlayerNum, szImgPath)
    UIHelper.SetVisible(self.ImgPalyerIconUp, bBreak or false)
    UIHelper.LayoutDoLayout(self.LayoutPlayerNum)
end


return UIWidgetPlayerMvpNum