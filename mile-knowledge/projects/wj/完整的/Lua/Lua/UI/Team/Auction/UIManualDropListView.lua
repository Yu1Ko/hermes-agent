-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIManualDropListView
-- Date: 2023-02-14 20:15:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIManualDropListView = class("UIManualDropListView")

local Key2CurrencyType = {
    ["nExp"] = CurrencyType.Experience,
    ["nMoney"] = CurrencyType.Money,
    ["nJustice"] = CurrencyType.Justice,
    ["nContribution"] = CurrencyType.Contribution,
    --["nExamPrint"] = 监文已经被干掉了
    ["nTrain"] = CurrencyType.Train,
    ["nPrestige"] = CurrencyType.TitlePoint,
    ["nArenaAward"] = CurrencyType.FeiShaWand,
}

function UIManualDropListView:OnEnter(nDropID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nDropID = nDropID
    self:UpdateInfo()
end

function UIManualDropListView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIManualDropListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCollectAll, EventType.OnClick, function ()
        local nRoom = g_pClientPlayer.GetFreeRoomSize()
        if nRoom >= self.nItemCount then -- 将错就错，服务器目前就是这么判的
            g_pClientPlayer.LootManualDrop(self.nDropID)
            UIMgr.Close(self)
        else
            TipsHelper.ShowImportantBlueTip("背包已满")
        end
    end)
    
    UIHelper.BindUIEvent(self.BtnCloseAll, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIManualDropListView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIManualDropListView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIManualDropListView:UpdateInfo()
    if not g_pClientPlayer then return end

    UIHelper.RemoveAllChildren(self.LayoutContent)
    local tDropList = g_pClientPlayer.GetManualDropInfo(self.nDropID)
    for key, szCurrencyType in pairs(Key2CurrencyType) do
        local nValue = tDropList[key]
        if nValue and nValue > 0 then 
            UIHelper.AddPrefab(PREFAB_ID.WidgetSpecialDropItem, self.ScrollViewContent, szCurrencyType, nValue, function (scriptDropItem)
                UIHelper.RemoveAllChildren(self.WidgetItemTipsShell)
                local scriptItemTips = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsShell)
                scriptItemTips:OnInitCurrency(szCurrencyType, nValue)
                local nPosX = UIHelper.GetWorldPositionX(self.WidgetItemTipsShell)
                local nPosY = UIHelper.GetWorldPositionY(scriptDropItem._rootNode)
                UIHelper.SetWorldPosition(self.WidgetItemTipsShell, nPosX, nPosY)
                UIHelper.SetAnchorPoint(scriptItemTips._rootNode, 0.5, 1)
            end)
        end
    end

    self.nItemCount = 0
    for _, tDropInfo in pairs(tDropList.tItem or {}) do 
        self.nItemCount = self.nItemCount + 1 
        UIHelper.AddPrefab(PREFAB_ID.WidgetSpecialDropItem, self.ScrollViewContent, tDropInfo, nil, function (scriptDropItem)
            UIHelper.RemoveAllChildren(self.WidgetItemTipsShell)
            local scriptItemTips = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTipsShell)
            scriptItemTips:OnInitWithTabID(tDropInfo.dwType, tDropInfo.dwIndex)
            local nPosX = UIHelper.GetWorldPositionX(self.WidgetItemTipsShell)
            local nPosY = UIHelper.GetWorldPositionY(scriptDropItem._rootNode)
            UIHelper.SetWorldPosition(self.WidgetItemTipsShell, nPosX, nPosY)
            UIHelper.SetAnchorPoint(scriptItemTips._rootNode, 0.5, 1)
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)

    UIHelper.SetSwallowTouches(self.BtnCloseAll, false)
end

return UIManualDropListView