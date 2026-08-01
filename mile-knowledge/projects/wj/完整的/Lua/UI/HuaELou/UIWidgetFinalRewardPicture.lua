-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetFinalRewardPicture
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetFinalRewardPicture = class("UIWidgetFinalRewardPicture")
function UIWidgetFinalRewardPicture:OnEnter(szImagePath, eSetState)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(szImagePath, eSetState)
end

function UIWidgetFinalRewardPicture:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetFinalRewardPicture:BindUIEvent()
end

function UIWidgetFinalRewardPicture:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetFinalRewardPicture:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetFinalRewardPicture:UpdateInfo(szImagePath, eSetState)
    --UIHelper.SetSpriteFrame(self.ImgPage_1, szImagePath)
    --UIHelper.ClearTexture(self.ImgPage_1)
    UIHelper.SetTexture(self.ImgPage_1, szImagePath, true)
    if eSetState == SET_COLLECTION_STATE_TYPE.TO_AWARD or eSetState == SET_COLLECTION_STATE_TYPE.COLLECTED then
        UIHelper.SetSpriteFrame(self.ImgStatus1, OperactRewardStateImg[eSetState])
    end
end

return UIWidgetFinalRewardPicture