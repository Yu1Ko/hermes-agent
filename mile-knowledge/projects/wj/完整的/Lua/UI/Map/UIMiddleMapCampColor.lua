-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiddleMapCampColor
-- Date: 2025-03-18 16:52:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiddleMapCampColor = class("UIMiddleMapCampColor")

function UIMiddleMapCampColor:OnEnter(nMapID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nMapID = nMapID
    self:UpdateInfo()
end

function UIMiddleMapCampColor:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMiddleMapCampColor:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp, TipsLayoutDir.TOP_CENTER, g_tStrings.HEATMAP_HELP_TEXT)
    end)
end

function UIMiddleMapCampColor:RegEvent()
    Event.Reg(self, EventType.OnHeatMapDataUpdate, function()
        self:UpdateInfo()
    end)
end

function UIMiddleMapCampColor:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiddleMapCampColor:UpdateInfo()
    if not self.nMapID then return end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    UIHelper.SetVisible(self._rootNode, HeatMapData.CanShowHeatMap(self.nMapID))
    if Table_IsTongWarFieldMap(self.nMapID) then
        UIHelper.SetString(self.LabelHaoQi, "蓝方"..HeatMapData.GetCampCount(CAMP.GOOD))
        UIHelper.SetString(self.LabelERen, "红方"..HeatMapData.GetCampCount(CAMP.EVIL))
        UIHelper.SetVisible(self.ImgHaoQi, hPlayer.nBattleFieldSide == 0)
        UIHelper.SetVisible(self.LabelHaoQi, hPlayer.nBattleFieldSide == 0)
        UIHelper.SetVisible(self.ImgERen, hPlayer.nBattleFieldSide == 1)
        UIHelper.SetVisible(self.LabelERen, hPlayer.nBattleFieldSide == 1)
    else
        UIHelper.SetString(self.LabelHaoQi, "浩气盟"..HeatMapData.GetCampCount(CAMP.GOOD))
        UIHelper.SetString(self.LabelERen, "恶人谷"..HeatMapData.GetCampCount(CAMP.EVIL))
        UIHelper.SetVisible(self.ImgHaoQi, true)
        UIHelper.SetVisible(self.LabelHaoQi, true)
        UIHelper.SetVisible(self.ImgERen, true)
        UIHelper.SetVisible(self.LabelERen, true)
    end
    UIHelper.LayoutDoLayout(self.LayoutCamp)
end


return UIMiddleMapCampColor