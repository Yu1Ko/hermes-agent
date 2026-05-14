-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiddleMapCampPanel
-- Date: 2025-03-18 16:27:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiddleMapCampPanel = class("UIMiddleMapCampPanel")

function UIMiddleMapCampPanel:OnEnter(nMapID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bFirtsUpdate = true
    end
    self.nMapID = nMapID
    self.cellPool = self.cellPool or PrefabPool.New(PREFAB_ID.WidgetCampCell)
    self:UpdateInfo()
end

function UIMiddleMapCampPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.cellPool then
        self.cellPool:Dispose()
        self.cellPool = nil
    end
end

function UIMiddleMapCampPanel:BindUIEvent()
    
end

function UIMiddleMapCampPanel:RegEvent()
    
end

function UIMiddleMapCampPanel:UnRegEvent()
    
end



function UIMiddleMapCampPanel:RemoveAllChildren()
    if self.tbNode then
        for index, node in ipairs(self.tbNode) do
            self.cellPool:Recycle(node)
        end
    end
    self.tbNode = {}
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiddleMapCampPanel:UpdateInfo()
    if not self.nMapID then return end
    local bCanShowHeatMap = HeatMapData.CanShowHeatMap(self.nMapID)
    local tbGongFang = HeatMapData.GetGFAreaNumInfo(self.nMapID)
    UIHelper.SetVisible(self.WidgetEmpty, not bCanShowHeatMap)
    UIHelper.SetVisible(self.WidgetScrollViewContent, bCanShowHeatMap)
    if bCanShowHeatMap then
        self:RemoveAllChildren()
        for index, tbInfo in ipairs(tbGongFang) do
            local node = self.cellPool:Allocate(self.ScrollViewContent, tbInfo)
            table.insert(self.tbNode, node)
        end
        if self.bFirtsUpdate then
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        else
            UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
        end
        self.bFirtsUpdate = false
    end
end


return UIMiddleMapCampPanel