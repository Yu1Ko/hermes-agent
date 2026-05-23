-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UITradeMessagePopView
-- Date: 2024-08-27 10:42:14
-- Desc: PanelTradeMessagePop 跑商时无法使用轻功/神行/骑马的提示界面
-- ---------------------------------------------------------------------------------

local UITradeMessagePopView = class("UITradeMessagePopView")

local BUFF_BUSINESS_RIDE = 7682 --走货郎
local BUFF_BUSINESS = 7732 --据点贸易

function UITradeMessagePopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        
        self.scriptBuffBusinessRide = UIHelper.GetBindScript(self.WidgetBuffMessage1)
        self.scriptBuffBusiness = UIHelper.GetBindScript(self.WidgetBuffMessage2)
        self.scriptBuffBusinessRide:OnEnter(BUFF_BUSINESS_RIDE)
        self.scriptBuffBusiness:OnEnter(BUFF_BUSINESS)
    end

    self:UpdateInfo()
end

function UITradeMessagePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITradeMessagePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    
end

function UITradeMessagePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITradeMessagePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITradeMessagePopView:UpdateInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end

    if not player.IsHaveBuff(BUFF_BUSINESS_RIDE, 1) then
        UIHelper.SetVisible(self.WidgetBuffMessage1, false)
        UIHelper.SetVisible(self.LabelTradeMessage2, false)
        UIHelper.SetString(self.LabelTradeMessage1, "跑商时无法使用大轻功或神行。")
    end

    UIHelper.LayoutDoLayout(self.LayoutContent2)
end


return UITradeMessagePopView