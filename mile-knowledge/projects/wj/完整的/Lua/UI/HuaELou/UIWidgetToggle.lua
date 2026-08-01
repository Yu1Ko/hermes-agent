-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetToggle
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIWidgetToggle
local UIWidgetToggle = class("UIWidgetToggle")
function UIWidgetToggle:OnEnter(szName, fCallBack, nRedPointID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(szName, fCallBack)

    RedpointMgr.UnRegisterRedpoint(self.ImgRedPoint)
    if nRedPointID and nRedPointID > 0 then
        RedpointMgr.RegisterRedpoint(self.ImgRedPoint, nil, {nRedPointID})
    end
end

function UIWidgetToggle:OnExit()
    self.bInit = false
    self:UnRegEvent()
    RedpointMgr.UnRegisterRedpoint(self.ImgRedPoint)
end

function UIWidgetToggle:BindUIEvent()
end

function UIWidgetToggle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetToggle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetToggle:UpdateInfo(szName, fCallBack)
    self.fCallBack = fCallBack

    if szName then
        UIHelper.SetString(self.LabelNormalName, szName)
        UIHelper.SetString(self.LabelUpName, szName)
    end
end

function UIWidgetToggle:UpdateRedPoint(bShow)
    UIHelper.SetVisible(self.ImgRedPoint, bShow)
end

return UIWidgetToggle