-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiddleMapLikeList
-- Date: 2024-03-03 11:22:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiddleMapLikeList = class("UIMiddleMapLikeList")

function UIMiddleMapLikeList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.cellMidCityLike = PrefabPool.New(PREFAB_ID.WidgetMidCityLike, MapMgr.GetMaxLikeMapCount())
    end
    self:Init()
end

function UIMiddleMapLikeList:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.cellMidCityLike then self.cellMidCityLike:Dispose() end
    self.cellMidCityLike = nil
end

function UIMiddleMapLikeList:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSetting, EventType.OnSelectChanged, function(_, bSelect)
        self:SetBtnDelVisible(bSelect)
    end)
end

function UIMiddleMapLikeList:RegEvent()

    Event.Reg(self, EventType.OnLikeMapListChange, function()
        self:UpdateInfo()

        local tbLikeList = MapMgr.GetLikeMapList()
        if #tbLikeList == 0 then
            UIHelper.SetVisible(self.nodeBack, false)
            UIHelper.LayoutDoLayout(self.LayoutTab)
        end
    end)

    Event.Reg(self, "ON_MIDDLE_MAP_REFRESH", function(nMapID)
        local nCurMapID = g_pClientPlayer and g_pClientPlayer.GetMapID()
        UIHelper.SetVisible(self.nodeBack, nCurMapID ~= nMapID)
        UIHelper.LayoutDoLayout(self.LayoutTab)
    end)
end

function UIMiddleMapLikeList:UnRegEvent()
   
end

function UIMiddleMapLikeList:Init()
    self.nodeBack, self.scriptBack = self.cellMidCityLike:Allocate(self.LayoutTab, nil)
    UIHelper.SetLocalZOrder(self.nodeBack, 50)
    UIHelper.SetVisible(self.nodeBack, false)

    self:UpdateInfo()
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiddleMapLikeList:UpdateInfo()
    local tbLikeList = MapMgr.GetLikeMapList()
    local nCount = #tbLikeList
    local nMaxCount = MapMgr.GetMaxLikeMapCount()
    local szContent = string.format("(%s/%s)", tostring(nCount), tostring(nMaxCount))
    UIHelper.SetString(self.LabelNum, szContent)
    UIHelper.SetVisible(self.LabelTip, nCount == 0)

    self:RemoveAllChildren()

    for nIndex, nMapID in ipairs(tbLikeList) do
        local node, scriptView = self.cellMidCityLike:Allocate(self.LayoutTab, nMapID)
        table.insert(self.tbScript, {node = node, script = scriptView})

    end
    UIHelper.LayoutDoLayout(self.LayoutTab)
    UIHelper.SetVisible(self.TogSetting, #tbLikeList ~= 0)
end

function UIMiddleMapLikeList:SetBtnDelVisible(bShow)
    if self.tbScript then
        for index, tbInfo in ipairs(self.tbScript) do
            tbInfo.script:SetBtnDelVisible(bShow)
        end
    end
end
    
function UIMiddleMapLikeList:RemoveAllChildren()
    if self.tbScript then
        for index, tbInfo in ipairs(self.tbScript) do
            self.cellMidCityLike:Recycle(tbInfo.node)
        end
    end
    self.tbScript = {}
end

return UIMiddleMapLikeList