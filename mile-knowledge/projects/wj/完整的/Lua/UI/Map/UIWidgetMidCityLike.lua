-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMidCityLike
-- Date: 2024-03-03 11:31:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMidCityLike = class("UIWidgetMidCityLike")

function UIWidgetMidCityLike:OnEnter(nMapID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nMapID = nMapID
    self:UpdateInfo()
end

function UIWidgetMidCityLike:OnExit()
    self.nMapID = nil
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMidCityLike:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCityLike, EventType.OnClick, function()
        Event.Dispatch("ON_MIDDLE_MAP_REFRESH", self.nMapID, 0)
    end)

    UIHelper.BindUIEvent(self.BtnDel, EventType.OnClick, function()
        MapMgr.RemoveLikeMap(self.nMapID)
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        local nMapID = g_pClientPlayer and g_pClientPlayer.GetMapID()
        Event.Dispatch("ON_MIDDLE_MAP_REFRESH", nMapID, 0)
    end)
end

function UIWidgetMidCityLike:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_MIDDLE_MAP_REFRESH", function(nMapID)
        if not self:IsBtnBack() then
            UIHelper.SetVisible(self.Eff_MenuSelect, nMapID == self.nMapID)
        end
    end)
end

function UIWidgetMidCityLike:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMidCityLike:UpdateInfo()
    if self.nMapID then
        local szName = Table_GetMapName(self.nMapID) or ""
        UIHelper.SetString(self.LabelCityName, UIHelper.GBKToUTF8(szName))
        UIHelper.SetString(self.LabelCityName_Select, UIHelper.GBKToUTF8(szName))
    end
    
    local bShowBtnBack = self:IsBtnBack()
    local nCount = self:GetLikeMapCount()
    UIHelper.SetVisible(self.BtnBack, bShowBtnBack and nCount > 0)
    UIHelper.SetVisible(self.BtnCityLike, not bShowBtnBack)

    if self.nMapID then
        UIHelper.SetVisible(self.Eff_MenuSelect, g_pClientPlayer.GetMapID() == self.nMapID)
    end
end

function UIWidgetMidCityLike:SetBtnDelVisible(bShow)
    UIHelper.SetVisible(self.BtnDel, bShow)
    UIHelper.SetVisible(self.ImgSelect, not bShow)
end

--是否为返回当前地图按钮
function UIWidgetMidCityLike:IsBtnBack()
    return self.nMapID == nil
end

function UIWidgetMidCityLike:GetLikeMapCount()
    local tbLikeMapList = MapMgr.GetLikeMapList()
    return #tbLikeMapList
end

return UIWidgetMidCityLike