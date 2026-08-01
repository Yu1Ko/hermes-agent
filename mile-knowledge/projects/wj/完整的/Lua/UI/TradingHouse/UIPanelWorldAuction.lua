-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelWorldAuction
-- Date: 2023-05-24 16:09:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

-- {
--     szOption = "阵营拍卖·开启",
--     fnAction = function()
--         SendGMCommand([[
--             GCCommand("SendToPlayerGmAnnounce('"..player.szName.."', '阵营拍卖·开启，执行结果：'..tostring(StartBMSell(GetCurrentTime(), 1)), 1)")
--         ]])
--     end
-- },
-- {
--     szOption = "阵营拍卖·关闭",
--     fnAction = function()
--         SendGMCommand([[
--             GCCommand("SendToPlayerGmAnnounce('"..player.szName.."', '阵营拍卖·关闭，执行结果：'..tostring(FinishBMSell(GetCurrentTime(), 1)), 1)")
--         ]])
--     end
-- },
local nNeutralActivityID = 885

local UIPanelWorldAuction = class("UIPanelWorldAuction")

function UIPanelWorldAuction:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init()
end

function UIPanelWorldAuction:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelWorldAuction:BindUIEvent()
    UIHelper.BindUIEvent(self.TogNavigationBuy, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            local nCampActivityID = self:GetCampActivityID()
            self:SetCurActivityID(nCampActivityID)
            self:SetCamp(BLACK_MARKET_TYPE.GOOD)
        end
    end)

    UIHelper.BindUIEvent(self.TogNavigationSell, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            local nCampActivityID = self:GetCampActivityID()
            self:SetCurActivityID(nCampActivityID)
            self:SetCamp(BLACK_MARKET_TYPE.EVIL)
        end
    end)

    UIHelper.BindUIEvent(self.TogNavigationNeuter, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self:SetCurActivityID(nNeutralActivityID)
            self:SetCamp(BLACK_MARKET_TYPE.ACTIVITY)
        end
    end)


    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function()
        TradingData.BMLookup(self.nCamp)
    end)

end

function UIPanelWorldAuction:RegEvent()
    Event.Reg(self, EventType.OnAuctionStateChanged, function()
        self:UpdateActivityIDList()
    end)
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        UIHelper.SetSelected(self.TogPriceTips, false, false)
    end)
end

function UIPanelWorldAuction:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelWorldAuction:Init()
    self:UpdateActivityIDList()
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelWorldAuction:UpdateTogNavigation()

    --的卢拍卖是否开启
    local bNeuterOpen = self:IsActivityIDExist(nNeutralActivityID)
    -- UIHelper.SetVisible(self.TogNavigationNeuter, bNeuterOpen)

    local nCampActivityID = self:GetCampActivityID()
    UIHelper.SetVisible(self.TogNavigationNeuter, bNeuterOpen and nCampActivityID ~= nil)
    UIHelper.SetVisible(self.TogNavigationBuy, nCampActivityID ~= nil)
    UIHelper.SetVisible(self.TogNavigationSell, nCampActivityID ~= nil)

    if self.nCamp == BLACK_MARKET_TYPE.GOOD then
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigationBuy)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigationSell)
    else
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigationSell)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigationBuy)
    end

    UIHelper.ToggleGroupAddToggle(self.ToggleGroupNavigation, self.TogNavigationNeuter)


    local tbAuctionInfo = self.tbAuctionInfoList[nCampActivityID]
    local szCategoryGood = tbAuctionInfo and UIHelper.GBKToUTF8(tbAuctionInfo.CategoryGood) or nil
    local szCategoryEvil = tbAuctionInfo and UIHelper.GBKToUTF8(tbAuctionInfo.CategoryEvil) or nil

    if not string.is_nil(szCategoryGood) then 
        UIHelper.SetString(self.LabelNavigationBuy, szCategoryGood)
        UIHelper.SetString(self.LabelSelectNavigationBuy, szCategoryGood)
    end

    if not string.is_nil(szCategoryEvil) then 
        UIHelper.SetString(self.LabelNavigationSell, szCategoryEvil)
        UIHelper.SetString(self.LabelSelectNavigationSell, szCategoryEvil)
    end

    local nCampActivityID = self:GetCampActivityID()
    if self.nCamp == BLACK_MARKET_TYPE.GOOD and nCampActivityID then 
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupNavigation, self.TogNavigationBuy)
    elseif self.nCamp == BLACK_MARKET_TYPE.EVIL and nCampActivityID then
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupNavigation, self.TogNavigationSell)
    else
        UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroupNavigation, self.TogNavigationNeuter)
    end

    UIHelper.LayoutDoLayout(self.LayoutNavigation)
end

function UIPanelWorldAuction:UpdateActivityInfo()
    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(self.tbAuctionInfo.szTitle))
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    UIHelper.SetString(self.LabelTips01, ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(self.tbAuctionInfo.szTip)))
end

function UIPanelWorldAuction:UpdateInfo()
    local scriptBlackMarket = UIHelper.GetBindScript(self.WidgetTradeAuction)

    local bWorldBossActivity = false 
    if self:IsWordBoss(self.nActivityID) then
        bWorldBossActivity = true
    end

    local bNeuterActivity = false 
    if self.tbAuctionInfo.bNeuter then 
        bNeuterActivity = true
    end
    
    scriptBlackMarket:OnEnter(self.nCamp, bWorldBossActivity, bNeuterActivity)
end



function UIPanelWorldAuction:UpdateActivityIDList()
    
    --tbActivityID最多存在的卢和其它的两个活动
    self.tbActivityID = TradingData.GetActivityList()

    if not self.tbAuctionInfoList then self.tbAuctionInfoList = {} end
    for nIndex, nActivityID in ipairs(self.tbActivityID) do
        self.tbAuctionInfoList[nActivityID] = Table_GetAuctionActivityInfo(nActivityID)
    end

    self:UpdateCurActivityID()
    self:UpdateTogNavigation()
end

function UIPanelWorldAuction:UpdateCurActivityID()
    local nCamp = g_pClientPlayer.nCamp 
    
    local nCampActivityID = self:GetCampActivityID()
    if nCamp ~= BLACK_MARKET_TYPE.NEUTRAL and nCampActivityID ~= nil then 
        self:SetCurActivityID(nCampActivityID)
        local nCamp = self:IsWordBoss(nCampActivityID) and BLACK_MARKET_TYPE.GOOD or nCamp
        self:SetCamp(nCamp)
    else
        self:SetCurActivityID(nNeutralActivityID)
        self:SetCamp(BLACK_MARKET_TYPE.ACTIVITY)
    end

end


function UIPanelWorldAuction:SetCurActivityID(nActivityID)
    if not nActivityID or self.nActivityID == nActivityID then return end
    self.nActivityID = nActivityID
    self.tbAuctionInfo = self.tbAuctionInfoList[nActivityID]
    self:UpdateActivityInfo()
end

function UIPanelWorldAuction:SetCamp(nCamp)
    self.nCamp = nCamp
    self:UpdateInfo()
end

function UIPanelWorldAuction:IsActivityIDExist(nActivityID)
    return self.tbActivityID and table.contain_value(self.tbActivityID, nActivityID)
end

function UIPanelWorldAuction:GetCampActivityID()
    local dwActivityID = nil
    for nIndex, nActivityID in ipairs(self.tbActivityID) do--取最新打开的阵营活动
        if nActivityID ~= nNeutralActivityID then 
            dwActivityID = nActivityID
        end
    end
    return dwActivityID
end

function UIPanelWorldAuction:IsWordBoss(nActivityID)
    return nActivityID == CAMP_AUCTION.ACTIVITY_ID_OF_WORLD_BOSS or nActivityID == CAMP_AUCTION.ACTIVITY_ID_OF_TEMP
end

return UIPanelWorldAuction