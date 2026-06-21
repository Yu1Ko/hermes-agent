-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandFlowerPriceView
-- Date: 2024-07-02 11:08:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandFlowerPriceView = class("UIHomelandFlowerPriceView")

local TogType = {
    Flower = 1,
    Plant = 2,
}

function UIHomelandFlowerPriceView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:Init()
end

function UIHomelandFlowerPriceView:OnExit()
    self.bInit = false
end

function UIHomelandFlowerPriceView:Init()
    self.nTogType = TogType.Flower
    self.tPriceInfo = HomelandFlowerPriceData.GetRankPriceInfo()

    UIHelper.SetVisible(self.WidgetEmpty, true)
    UIHelper.SetString(self.LabelEmpty, "正在加载数据，请稍等")
    self.nLoadDataTimerID = Timer.Add(self, 3, function()
        self:UpdateInfo()
        self.nLoadDataTimerID = nil
    end)
end

function UIHomelandFlowerPriceView:BindUIEvent()
    self.scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetScrollTree)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogAuto, EventType.OnClick, function(btn)
        Storage.HomeLand.bFlowerPriceFilterOwner = UIHelper.GetSelected(self.TogAuto)
        Storage.HomeLand.Dirty()
        self:UpdateListInfo()
    end)
    UIHelper.SetSelected(self.TogAuto, Storage.HomeLand.bFlowerPriceFilterOwner)

    UIHelper.BindUIEvent(self.TogType1, EventType.OnClick, function(btn)
        self.nTogType = TogType.Flower
        self:UpdateListInfo()
    end)

    UIHelper.BindUIEvent(self.TogType2, EventType.OnClick, function(btn)
        self.nTogType = TogType.Plant
        self:UpdateListInfo()
    end)

    UIHelper.ToggleGroupAddToggle(self.ToggleGroupType, self.TogType1)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupType, self.TogType2)
end

function UIHomelandFlowerPriceView:RegEvent()
    Event.Reg(self, "UPDATE_FLOWER_PRICE_DATA", function ()
        if self.nLoadDataTimerID then
            Timer.DelTimer(self, self.nLoadDataTimerID)
            self.nLoadDataTimerID = Timer.Add(self, 3, function()
                self:UpdateInfo()
                self.nLoadDataTimerID = nil
            end)
            return
        end

        if self.nDelayUpdateListTimerID then
            Timer.DelTimer(self, self.nDelayUpdateListTimerID)
            self.nDelayUpdateListTimerID = nil
        end

        self.nDelayUpdateListTimerID = Timer.Add(self, 1, function()
            self.tPriceInfo = HomelandFlowerPriceData.GetRankPriceInfo()
            self:UpdateListInfo()
        end)
	end)
end
function UIHomelandFlowerPriceView:UpdateInfo()
    self:UpdateListInfo()
end

function UIHomelandFlowerPriceView:UpdateListInfo()
    local tbData = {}
    local tChengPin = HomelandFlowerPriceData.tChengPin
    local tSeed, tFlower, tPlant = HomelandFlowerPriceData.LoadSeedInfo() -- 种子、成品信息
    local tInfo = self.nTogType == TogType.Flower and tFlower or tPlant

    local bOwner = Storage.HomeLand.bFlowerPriceFilterOwner
    local player = GetClientPlayer()
    if not player then
        return
    end
    for i = 1, #tInfo do
        local nIndex = tInfo[i] -- 种子ID
        local nType = tSeed[nIndex].nType -- 1花卉，2作物
        local bAdd = true
        if tChengPin[nIndex] then
            local nSumAmount = 0
            local nSumPrice = 0
            local tProduct = {} -- 所有产物的详细信息
            local nMaxNameLen = 0
            local nPrice = (tSeed[nIndex].nPrice / 50) * 1.5
            for j = 1, #tChengPin[nIndex] do
                local dwSonItemIndex = tChengPin[nIndex][j].dwIndex
                if nType == 2 and tChengPin[nIndex][j].nPrice then
                    nPrice = (tChengPin[nIndex][j].nPrice / 50) * 1.5
                end
                local nAmountBag = player.GetItemAmount(5, dwSonItemIndex)
                local nAmountRemote = HomelandBuildData.GetLockerItemNum(dwSonItemIndex)
                local nAmount = nAmountBag + nAmountRemote
                if nAmount > 0 then
                    nSumAmount = nSumAmount + nAmount
                    nSumPrice = nSumPrice + math.floor(nPrice * nAmount + 0.000001) -- 精度问题
                end
                local _itemInfo = GetItemInfo(5, dwSonItemIndex)
                if _itemInfo then
                    nMaxNameLen = math.max(nMaxNameLen, string.len(_itemInfo.szName))
                    table.insert(tProduct, {szName = UIHelper.GBKToUTF8(_itemInfo.szName), dwIndex = dwSonItemIndex, nAmountBag = nAmountBag, nAmountRemote = nAmountRemote})
                end
            end
            if bOwner and nSumAmount == 0 then
                bAdd = false
            end
            if bAdd then
                local tList = {}
                for i, tbInfo in ipairs(tProduct) do
                    table.insert(tList, tbInfo)
                end

                local tItemList = {}
                for nMapID, tSeedInfos in pairs(self.tPriceInfo) do
                    local tSeedInfo = tSeedInfos[nIndex]
                    if tSeedInfo and #tSeedInfo > 0 then
                        for i = 1, #tSeedInfo do
                            local nCenterID = tSeedInfo[i].nCenterID
                            local nLineID = tSeedInfo[i].nLineID
                            local nCopyIndex = tSeedInfo[i].nCopyIndex
                            table.insert(tItemList, {
                                tArgs = {
                                    tbInfo = {nMapID = nMapID, nCopyIndex = nCopyIndex, nCenterID = nCenterID, nLineID = nLineID, nTogType = self.nTogType}
                                }
                            })
                        end
                    end
                end

                local itemInfo = GetItemInfo(5, nIndex)
                if itemInfo then
                    local szName = ItemData.GetItemNameByItemInfo(itemInfo)
                    szName = UIHelper.GBKToUTF8(szName)
                    szName = string.gsub(szName, "(.+)·(.+)", function (a, b)
                        return b .. a
                    end)

                    szName = string.gsub(szName, "孢子", "")
                    szName = string.gsub(szName, "种子", "")
                    local tArgs = { szTitle = szName, nIndex = nIndex, nSumPrice = nSumPrice, nSumAmount = nSumAmount, tList = tList}
                    table.insert(tbData, {
                        tArgs = tArgs,
                        tItemList = tItemList,
                        fnSelectedCallback = function(bSelected, scriptContainer)
                            self:ShowTips(bSelected, tArgs.tList)
                        end,
                    })
                end
            end
        end
    end

    local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelTitle02, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelTitle03, tArgs.szTitle)

        local szPrice = string.format("总价：%d", tArgs.nSumPrice)
        local szCount = string.format("拥有：%d", tArgs.nSumAmount)
        UIHelper.SetString(scriptContainer.LabelPrice, szPrice)
        UIHelper.SetString(scriptContainer.LabelPrice_Select, szPrice)
        UIHelper.SetString(scriptContainer.LabelGetNum, szCount)
        UIHelper.SetString(scriptContainer.LabelGetNum_Select, szCount)
		UIHelper.LayoutDoLayout(scriptContainer.LayoutPrice)
		UIHelper.LayoutDoLayout(scriptContainer.LayoutPrice_Select)
        UIHelper.LayoutDoLayout(scriptContainer.LayoutPriceNum)
		UIHelper.LayoutDoLayout(scriptContainer.LayoutPriceNum_Select)
		UIHelper.LayoutDoLayout(scriptContainer.LayoutFlowerPrice)
    end

    self.scriptScrollViewTree:ClearContainer()
    self.scriptScrollViewTree:SetOuterInitSelect()
    UIHelper.SetupScrollViewTree(self.scriptScrollViewTree,
        PREFAB_ID.WidgetFlowerPriceCell,
        PREFAB_ID.WidgetFlowerCommunityCell,
        func, tbData, true)

    UIHelper.SetVisible(self.WidgetEmpty, #tbData == 0)
    if #tbData == 0 then
        self:ShowTips(false)
    end

    if self.nTogType == TogType.Flower then
        UIHelper.SetString(self.LabelEmpty, "暂无拥有的鲜花")
    else
        UIHelper.SetString(self.LabelEmpty, "暂无拥有的作物")
    end
end

function UIHomelandFlowerPriceView:ShowTips(bShow, tList)
    if bShow then
        self.tCurList = tList
        UIHelper.SetTabVisible(self.tbWidgetTipsCell, false)

        if #tList > #self.tbWidgetTipsCell then
            LOG.ERROR("UIHomelandFlowerPriceView:ShowTips ERROR! #tList > #self.tbWidgetTipsCell")
        end

        for i, widget in ipairs(self.tbWidgetTipsCell) do
            local tInfo = self.tCurList[i]

            if tInfo then
                UIHelper.SetVisible(widget, true)
                local script = UIHelper.GetBindScript(widget)
                UIHelper.SetString(script.LabelName, string.format("%s（%d）", tInfo.szName, tInfo.nAmountRemote + tInfo.nAmountBag))
            end
        end

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTips)
    end
    UIHelper.SetVisible(self.WidgetAnchorTip, bShow)
end

return UIHomelandFlowerPriceView