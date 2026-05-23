-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIClickToHide
-- Date: 2023-04-21 17:51:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIClickToHide = class("UIClickToHide")

function UIClickToHide:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIClickToHide:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIClickToHide:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        UIHelper.SetTabVisible(self.tbHideList, false)
        
        Event.Dispatch(EventType.OnClickToHide)
    end)
end

function UIClickToHide:IsHidden()
    for _, v in ipairs(self.tbHideList or {}) do
        if UIHelper.GetVisible(v) then
            return false
        end
    end
    return true
end

function UIClickToHide:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIClickToHide:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIClickToHide:SetTouchEnabled(bEnable)
    UIHelper.SetTouchEnabled(self._rootNode, bEnable)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIClickToHide:UpdateInfo()
    
end


return UIClickToHide