-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAutoShoutForbidView
-- Date: 2025-03-06 10:20:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAutoShoutForbidView = class("UIAutoShoutForbidView")

function UIAutoShoutForbidView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init()
    self:UpdateInfo()
end

function UIAutoShoutForbidView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAutoShoutForbidView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        for key, v in pairs(self.tbRuntimeMap) do
            self.tbRuntimeMap[key] = {}
        end
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        AutoShoutForbidData.SaveShoutFilter(self.tbRuntimeMap)
        UIMgr.Close(self)
    end)
end

function UIAutoShoutForbidView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAutoShoutForbidView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIAutoShoutForbidView:Init()
    self.tbRuntimeMap = {}
    self.tbRuntimeMap.tbForbidChannel = clone(Storage.ShoutFilter.tbForbidChannel) or {}
    self.tbRuntimeMap.tbForbidType = clone(Storage.ShoutFilter.tbForbidType) or {}
    self.tbRuntimeMap.tbForbidMap = clone(Storage.ShoutFilter.tbForbidMap) or {}
end

function UIAutoShoutForbidView:UpdateForbidInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewList)

    self:UpdateForbShoutChannel()
    self:UpdateForbShoutType()
    self:UpdateForbWhiteListMap()

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewList, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
end

local fnApplyForbChannelTable = function(tbApplyList, tbChannelList, bSelected)
    for index, nID in ipairs(tbChannelList) do
        if bSelected and not table.contain_value(tbApplyList, nID) then
            table.insert(tbApplyList, nID)
        elseif not bSelected then
            table.remove_value(tbApplyList, nID)
        end
    end
    return tbApplyList
end

function UIAutoShoutForbidView:UpdateForbShoutChannel()
    local scriptContent = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewList)
    scriptContent:OnInitWithTitle("屏蔽的频道", true)

    local tbChannelList = AutoShoutForbidData.GetChannelConfig()
    local tbApplyChannelList = self.tbRuntimeMap.tbForbidChannel
    for i = 1, #tbChannelList, 1 do
        local tbInfo = tbChannelList[i]
        local tbChannelID = tbInfo.tbChannelID
        local scriptCell = scriptContent:AddTag(i)
        self:InitCell(i, tbInfo, scriptCell, function (bSelected)
            fnApplyForbChannelTable(tbApplyChannelList, tbChannelID, bSelected)
        end)

        for _, nID in ipairs(tbChannelID) do
            if table.contain_value(tbApplyChannelList, nID) then
                scriptCell:SetSelected(true, false)
                break
            end
        end
    end
end

local fnApplyForbTypeTable = function(tbApplyList, nType, bSelected)
    if bSelected then
        tbApplyList[nType] = true
    else
        tbApplyList[nType] = nil
    end
end

function UIAutoShoutForbidView:UpdateForbShoutType()
    local scriptContent = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewList)
    scriptContent:OnInitWithTitle("屏蔽的喊话类型", true)

    local tbShoutTypeList = AutoShoutForbidData.GetShoutTypeConfig()
    local tbApplyList = self.tbRuntimeMap.tbForbidType
    for nIndex = 1, #tbShoutTypeList, 1 do
        local tbInfo = tbShoutTypeList[nIndex]
        local scriptCell = scriptContent:AddTag(nIndex)
        self:InitCell(nIndex, tbInfo, scriptCell, function (bSelected)
            fnApplyForbTypeTable(tbApplyList, nIndex, bSelected)
        end)

        if tbApplyList[nIndex] then
            scriptCell:SetSelected(true, false)
        end
    end
end

function UIAutoShoutForbidView:UpdateForbWhiteListMap()
    local scriptContent = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewList)
    scriptContent:OnInitWithTitle("以下地图不屏蔽", true)

    local tbWhiteListConfig = AutoShoutForbidData.GetWhiteListConfig()
    local tbApplyList = self.tbRuntimeMap.tbForbidMap
    for nIndex = 1, #tbWhiteListConfig, 1 do
        local tbInfo = tbWhiteListConfig[nIndex]
        local scriptCell = scriptContent:AddTag(nIndex)
        self:InitCell(nIndex, tbInfo, scriptCell, function (bSelected)
            fnApplyForbTypeTable(tbApplyList, nIndex, bSelected)
        end)

        if tbApplyList[nIndex] then
            scriptCell:SetSelected(true, false)
        end
    end
end

function UIAutoShoutForbidView:InitCell(nIndex, tbInfo, scriptCell, fnOnSelectChanged)
    local szTitle = tbInfo.szTitle
    scriptCell:OnEnter(true)
    scriptCell:SetTitle(szTitle)
    scriptCell:BindOnSelectChanged(fnOnSelectChanged)
end

return UIAutoShoutForbidView
