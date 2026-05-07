-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMapCampCell
-- Date: 2025-03-19 18:58:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMapCampCell = class("UIWidgetMapCampCell")

function UIWidgetMapCampCell:OnEnter(tbInfo, nHeatMapMode)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetMapCampCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMapCampCell:BindUIEvent()
    
end

function UIWidgetMapCampCell:RegEvent()
    Event.Reg(self, "ON_MIDDLE_MAP_SCALE_CHANGE", function()
        if not self.nLogicX or not self.nLogicY then
            return
        end
        
        Event.Dispatch("ON_MIDDLE_UPDATE_SIGN_BUTTON_POS", self, self.nLogicX, self.nLogicY)
    end)
end

function UIWidgetMapCampCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetMapCampCell:OnShow(tbInfo, nHeatMapMode)
    self.tbInfo = tbInfo
    self.nHeatMapMode = nHeatMapMode
    self:UpdateInfo()
end


function UIWidgetMapCampCell:GetUIIndex(nPlayerCount)
    if not nPlayerCount or nPlayerCount == 0 then
        return
    elseif nPlayerCount == 1 then
        return 4
    elseif nPlayerCount <= 9 then
        return 3
    elseif nPlayerCount <= 70 then
        return 2
    else
        return 1
    end
end

function UIWidgetMapCampCell:SetPosition(nX, nY, nLogicX, nLogicY)
    self.nX, self.nY, self.nLogicX, self.nLogicY = nX, nY, nLogicX, nLogicY
    self._rootNode:setPosition(nX, nY)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMapCampCell:UpdateInfo()
    if not self.tbInfo then
        return
    end

    local node = nil
    local tbGoodInfo = self.tbInfo[CAMP.GOOD]
    local tbEvilInfo = self.tbInfo[CAMP.EVIL]
    UIHelper.SetVisible(self.WidgetCamp_Red, tbEvilInfo ~= nil)
    UIHelper.SetVisible(self.WidgetCamp_Blue, tbGoodInfo ~= nil)
    if tbGoodInfo then
        local nPlayerCount = tbGoodInfo.nPlayerCount
        local nIndex = self:GetUIIndex(nPlayerCount)
        for index, Img in ipairs(self.tbBlueImg) do
            UIHelper.SetVisible(Img, index == nIndex)
        end
        node = self.WidgetCamp_Blue
        UIHelper.SetString(self.LabelBlue, nPlayerCount)
        UIHelper.SetVisible(self.LabelBlue, self.nHeatMapMode == HEAT_MAP_MODE.SHOW_ALL)
    end

    if tbEvilInfo then
        local nPlayerCount = tbEvilInfo.nPlayerCount
        local nIndex = self:GetUIIndex(nPlayerCount)
        for index, Img in ipairs(self.tbRedImg) do
            UIHelper.SetVisible(Img, index == nIndex)
        end
        node = node == nil and self.WidgetCamp_Red or nil
        UIHelper.SetString(self.LabelRed, nPlayerCount)
        UIHelper.SetVisible(self.LabelRed, self.nHeatMapMode == HEAT_MAP_MODE.SHOW_ALL)
    end
    

    if node then
        UIHelper.SetPosition(node, 0, 0)--只有一个时居中显示
    end
end


return UIWidgetMapCampCell