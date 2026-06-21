-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetMainCityElementInfo
-- Date: 2026-03-05 20:21:55
-- Desc: 扬刀大会-主界面左侧元素点信息显示 WidgetMainCityElementInfo
-- ---------------------------------------------------------------------------------

local UIWidgetMainCityElementInfo = class("UIWidgetMainCityElementInfo")

function UIWidgetMainCityElementInfo:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetMainCityElementInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMainCityElementInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBless, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelYangDaoOverview, 2)
    end)
end

function UIWidgetMainCityElementInfo:RegEvent()
    Event.Reg(self, EventType.OnArenaTowerDataUpdate, function()
        self:UpdateInfo()
    end)
    Event.Reg(self, "On_ArenaTower_UpdateCoinInGame", function()
        self:UpdateCoinInGame()
    end)
end

function UIWidgetMainCityElementInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetMainCityElementInfo:UpdateInfo()
    self:UpdateElementPoint()
    self:UpdateCoinInGame()
end

function UIWidgetMainCityElementInfo:UpdateElementPoint()
    -- 注意这里self.tLabelElement的顺序要与BlessElementType的顺序一致
    local tElementPoint, _, _ = ArenaTowerData.GetElementPointInfo()
    for _, nType in pairs(BlessElementType) do
        UIHelper.SetString(self.tLabelElement[nType], tElementPoint[nType] or 0)
    end
end

function UIWidgetMainCityElementInfo:UpdateCoinInGame()
    local nCoinInGame, _ = ArenaTowerData.GetCoinInGameInfo()
    UIHelper.SetString(self.LabelNum, nCoinInGame)
    UIHelper.LayoutDoLayout(self.LayoutCoin)
end

return UIWidgetMainCityElementInfo