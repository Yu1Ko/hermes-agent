-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILiveSelectDungeonPop
-- Date: 2026-03-11 17:32:07
-- Desc: 副本观战直播地图选择弹窗
-- ---------------------------------------------------------------------------------

local UILiveSelectDungeonPop = class("UILiveSelectDungeonPop")

function UILiveSelectDungeonPop:OnEnter(nCurrentMapID, fnFilterConfirmCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbFilterCells = {}
    self.fnFilterConfirmCallback = fnFilterConfirmCallback

    if self.fnFilterConfirmCallback then
        -- 筛选模式：多选，tbSelectedMapIDs 为地图 ID 集合
        self.tbSelectedMapIDs = type(nCurrentMapID) == "table" and nCurrentMapID or {}
        -- 筛选模式：修改标题和按钮
        self:BuildMenu()
        self:LoadBreadNavi()
        self:LoadFilterList()
        UIHelper.SetString(self.LabelTitle, "筛选直播间")
        UIHelper.SetString(self.LabelConfirm, "确认")
        UIHelper.SetVisible(self.BtnCancel, false)
        UIHelper.SetVisible(self.BtnConfirm, true)
    else
        -- 直播模式：单选
        self.nSelectMapID = nCurrentMapID or 0
        self:BuildMenu()
        self:LoadBreadNavi()
        self:LoadFilterList()
        -- 恢复默认标题和按钮
        UIHelper.SetString(self.LabelTitle, "创建直播间")
        UIHelper.SetString(self.LabelConfirm, "开启")
        -- 已设置地图：隐藏确认按钮，显示取消按钮；反之隐藏取消按钮，显示确认按钮
        local bHasMap = RoomVoiceData.IsLiveStreamActive()
        UIHelper.SetVisible(self.BtnConfirm, not bHasMap)
        UIHelper.SetVisible(self.BtnCancel, bHasMap)
    end
end

function UILiveSelectDungeonPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILiveSelectDungeonPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelLiveBroadcastPop)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        -- 取消直播：清除已设置的地图
        RoomVoiceData.SetLiveStreamMap(0)
        UIMgr.Close(VIEW_ID.PanelLiveBroadcastPop)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.fnFilterConfirmCallback then
            -- 筛选模式：回调传入选中的地图 ID 集合
            self.fnFilterConfirmCallback(self.tbSelectedMapIDs)
        else
            -- 直播模式：设置直播地图
            RoomVoiceData.SetLiveStreamMap(self.nSelectMapID)
        end
        UIMgr.Close(VIEW_ID.PanelLiveBroadcastPop)
    end)
end

function UILiveSelectDungeonPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UILiveSelectDungeonPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

-- 从 OBDungeon 配置表构建菜单数据
function UILiveSelectDungeonPop:BuildMenu()
    local tbDungeonList = OBDungeonData.GetOBDungeonList()
    self.tbRootMenu = {szOption = "全部副本"}
    for _, tLine in ipairs(tbDungeonList) do
        table.insert(self.tbRootMenu, {
            szOption = UIHelper.GBKToUTF8(tLine.szName),
            nMapID   = tLine.nMapID,
        })
    end
end

-- 加载面包屑导航：固定显示根节点"全部副本"
function UILiveSelectDungeonPop:LoadBreadNavi()
    UIHelper.RemoveAllChildren(self.ScrollViewBreadNaviScreen)
    local naviCell = UIHelper.AddPrefab(PREFAB_ID.WidgetBreadNaviCell, self.ScrollViewBreadNaviScreen)
    naviCell:OnEnter(self.tbRootMenu, true, function() end)
    naviCell:SetChecked(true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBreadNaviScreen)
end

-- 加载过滤列表：用 WidgetMapFilterItem 逐条展示副本
function UILiveSelectDungeonPop:LoadFilterList()
    UIHelper.RemoveAllChildren(self.ScrollViewFilterList)
    self.tbFilterCells = {}
    local bHasMap = RoomVoiceData.IsLiveStreamActive()
    local bFilterMode = self.fnFilterConfirmCallback ~= nil
    for _, tbItem in ipairs(self.tbRootMenu) do
        local bSelected
        if bFilterMode then
            -- 筛选模式：多选判断
            bSelected = tbItem.nMapID and self.tbSelectedMapIDs[tbItem.nMapID] or false
        else
            -- 直播模式：单选判断
            bSelected = (tbItem.nMapID == self.nSelectMapID)
        end
        local filterCell = UIHelper.AddPrefab(PREFAB_ID.WidgetMapFilterItem, self.ScrollViewFilterList)
        local nMapID = tbItem.nMapID
        filterCell:OnEnter(tbItem.szOption, bSelected, false)
        filterCell:SetClickCallback(function()
            self:OnSelectDungeon(nMapID)
        end)
        if bHasMap and not bFilterMode then
            UIHelper.SetButtonState(filterCell.BtnFilterItem, BTN_STATE.Disable)
        end
        table.insert(self.tbFilterCells, {cell = filterCell, nMapID = nMapID})
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFilterList)
end

-- 选中某个副本；筛选模式下多选切换，直播模式下单选
function UILiveSelectDungeonPop:OnSelectDungeon(nMapID)
    if self.fnFilterConfirmCallback then
        -- 筛选模式：多选切换
        if self.tbSelectedMapIDs[nMapID] then
            self.tbSelectedMapIDs[nMapID] = nil
        else
            self.tbSelectedMapIDs[nMapID] = true
        end
        for _, tbCell in ipairs(self.tbFilterCells) do
            tbCell.cell:SetSelected(self.tbSelectedMapIDs[tbCell.nMapID] or false)
        end
    else
        -- 直播模式：单选
        self.nSelectMapID = nMapID
        for _, tbCell in ipairs(self.tbFilterCells) do
            tbCell.cell:SetSelected(tbCell.nMapID == nMapID)
        end
    end
end


return UILiveSelectDungeonPop