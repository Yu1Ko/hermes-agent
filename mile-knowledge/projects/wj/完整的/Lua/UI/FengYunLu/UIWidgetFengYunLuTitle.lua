-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPvPCampRewardListNormal
-- Date: 2023-03-02 19:49:15
-- Desc: WidgetPvPCampRewardListAttribute、WidgetPvPCampRewardListEquip
-- ---------------------------------------------------------------------------------

---@class UIWidgetFengYunLuTitle
local UIWidgetFengYunLuTitle = class("UIWidgetFengYunLuTitle")

function UIWidgetFengYunLuTitle:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetFengYunLuTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetFengYunLuTitle:BindUIEvent()
end

function UIWidgetFengYunLuTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetFengYunLuTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetFengYunLuTitle:UpdateInfo()
   
end

return UIWidgetFengYunLuTitle