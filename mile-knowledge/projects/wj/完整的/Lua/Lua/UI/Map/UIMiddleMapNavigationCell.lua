local UIMiddleMapNavigationCell = class("UIMiddleMapNavigationCell")

local function SetIndies(tbIndex, nType, nNavigation, nCell)
    tbIndex.nType = nType
    tbIndex.nNavigation = nNavigation
    tbIndex.nCell = nCell
end

function UIMiddleMapNavigationCell:RegisterEvent()
    Event.Reg(self, "ON_MIDDLE_MAP_NAV_CELL_TOGGLE", function(obj, bSelected)
        if bSelected and obj ~= self then
            UIHelper.SetSelected(self.TogSelectNpc, false, false)
        end
    end)
    UIHelper.BindUIEvent(self.TogTrace, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            MapMgr.SetTracePoint(self.szName, self.nMapID, self.tbInfo.tPoint[1])
        else
            MapMgr.ClearTracePoint()
        end
        if self.fnTrace then
            self.fnTrace(bSelected)
        end
    end)
    UIHelper.BindUIEvent(self.TogSelectNpc, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            SetIndies(self.tbIndex, self.nType, self.nNavigation, self.nCell)
        else
            SetIndies(self.tbIndex, nil, nil, nil)
        end
        Event.Dispatch('ON_MIDDLE_MAP_NAV_CELL_TOGGLE', self, bSelected)
        Event.Dispatch("ON_MIDDLE_MAP_MARK_SHOW", bSelected and self.tbInfo, self.nMiddleMap)
        --Event.Dispatch("ON_MIDDLE_MAP_MARK_HIGHLIGHT", self.tbInfo.nNpcID, bSelected)
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        if not UIHelper.GetSelected(self.TogSelectNpc) then
            UIHelper.SetSelected(self.TogSelectNpc, true)
        end
        Event.Dispatch("ON_MIDDLE_MAP_SHOW_DETAIL", self.tbInfo)
    end)
end

function UIMiddleMapNavigationCell:OnEnter(tbArg)
    self:RegisterEvent()
    UIHelper.SetNodeSwallowTouches(self._rootNode, false, true)
    UIHelper.SetNodeSwallowTouches(self.TogTrace, true, false)
    self:UpdateInfo(unpack(tbArg))
end

function UIMiddleMapNavigationCell:OnExit()
    
end


local function FormatName(szName, szKind, szOrder)
    local szResName = ""
    local tbStr = {}
    if szKind and szKind ~= "" then
        table.insert(tbStr, szKind)
    end

    if szName and szName ~= "" then
        table.insert(tbStr, szName)
    end

    if szOrder and szOrder ~= "" then
        table.insert(tbStr, szOrder)
    end

    for nIndex, szName in ipairs(tbStr) do
        if nIndex ~= 1 then
            szResName = szResName .. "·" .. szName
        else
            szResName = szName
        end
    end

    return UIHelper.LimitUtf8Len(szResName, 11)
end

function UIMiddleMapNavigationCell:UpdateInfo(nType, nNavigation, nCell, tbInfo, nMapID, tbIndex, nMiddleMap)
    self.nMapID = nMapID
    self.tbInfo = tbInfo
    self.nType = nType
    self.nNavigation = nNavigation
    self.nCell = nCell
    self.tbIndex = tbIndex
    self.nMiddleMap = nMiddleMap
    self.szName = GBKToUTF8(Table_GetNpcTemplateName(tbInfo.nNpcID))
    local szDisplay = FormatName(self.szName, tbInfo.szKind, tbInfo.szOrderName)
    self.Label1:setString(szDisplay)
    self.Label2:setString(szDisplay)

    if self.tbIndex.nType == nType and self.tbIndex.nNavigation == nNavigation and self.tbIndex.nCell == nCell then
        UIHelper.SetSelected(self.TogSelectNpc, true)
    end

    UIHelper.SetVisible(self.BtnDetail, #self.tbInfo.tPoint == 1)
    UIHelper.SetSwallowTouches(self.BtnDetail, true)
    self:UpdateTraceState()
end

function UIMiddleMapNavigationCell:SetSelectedWithCallBack(bSelected)
    UIHelper.SetSelected(self.TogSelectNpc, bSelected)
end

function UIMiddleMapNavigationCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogSelectNpc, bSelected, false)
end
UIMiddleMapNavigationCell.onlySetSelected = UIMiddleMapNavigationCell.SetSelected

function UIMiddleMapNavigationCell:UpdateTraceState()
    local bSelected = MapMgr.IsNodeTraced(self.nMapID, self.tbInfo.tPoint[1])
    UIHelper.SetSelected(self.TogTrace, bSelected, false)
end

return UIMiddleMapNavigationCell