-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetFinalRewardPoint
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetFinalRewardPoint = class("UIWidgetFinalRewardPoint")
function UIWidgetFinalRewardPoint:OnEnter(szName, szNormalImgPath, szUpImgPath, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(szName, szNormalImgPath, szUpImgPath, fCallBack)
end

function UIWidgetFinalRewardPoint:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetFinalRewardPoint:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleNavigation, EventType.OnSelectChanged, function (_, bSelected)
        self.fCallBack(bSelected)
    end)
end

function UIWidgetFinalRewardPoint:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetFinalRewardPoint:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetFinalRewardPoint:UpdateInfo(szName, szNormalImgPath, szUpImgPath, fCallBack)
    self.fCallBack = fCallBack

    UIHelper.SetString(self.LabelNormalName, szName)
    UIHelper.SetString(self.LabelUpName, szName)
    UIHelper.SetSpriteFrame(self.ImgNormalIcon, szNormalImgPath)
    UIHelper.SetSpriteFrame(self.ImgUpIcon, szUpImgPath)
end

return UIWidgetFinalRewardPoint