-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetRightEvent
-- Date: 2026-04-24 15:43:42
-- Desc: 大富翁 右侧面板（选方向/选玩家/买空地/拍卖/换地/手牌使用[无目标]） WidgetRightEvent
-- ---------------------------------------------------------------------------------

local UIWidgetRightEvent = class("UIWidgetRightEvent")

local DataModel = nil

function UIWidgetRightEvent:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetRightEvent:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self:Clear()
end

function UIWidgetRightEvent:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
    --SelectDirection
    UIHelper.BindUIEvent(self.BtnDirClockwise, EventType.OnClick, function()
        self:SubmitDirection(DFW_PLAYER_DIR.INIT)
    end)
    UIHelper.BindUIEvent(self.BtnDirCounterClockwise, EventType.OnClick, function()
        self:SubmitDirection(DFW_PLAYER_DIR.CLOCKWISE)
    end)
    --LandPurchase
    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        self:ReplyAccept()
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self:ReplyCancel()
    end)
    --TargetSelect
    UIHelper.BindUIEvent(self.BtnSelectCenter, EventType.OnClick, function()
        self:ConfirmSelect()
    end)
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        self:CancelSelect()
    end)
    --AuctionInfo
    UIHelper.BindUIEvent(self.BtnMyBid, EventType.OnClick, function()
        self:ReplyBid()
    end)
    UIHelper.BindUIEvent(self.BtnGiveUp, EventType.OnClick, function()
        self:ReplyGiveUp()
    end)
    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function()
        self:AdjustBidByDelta(1)
    end)
    UIHelper.BindUIEvent(self.BtnLess, EventType.OnClick, function()
        self:AdjustBidByDelta(-1)
    end)
    UIHelper.BindUIEvent(self.BtnMax, EventType.OnClick, function()
        self:SetBidToMaxMoney()
    end)
end

function UIWidgetRightEvent:RegEvent()
    Event.Reg(self, EventType.OnMonopolyRightEventOpen, function(szRightEvent)
        self:Open(szRightEvent)
    end)
    Event.Reg(self, EventType.OnMonopolyRightEventClose, function(szRightEvent)
        self:Close(szRightEvent)
    end)
    Event.Reg(self, EventType.OnMonopolySetAuctionState, function(nState)
        self:Open(MonopolyRightEventType.AuctionInfo)
        self:SetAuctionState(nState)
    end)
end

function UIWidgetRightEvent:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetRightEvent:UpdateInfo(...)
    if not self.szRightEvent or not DataModel then
        return
    end

    local szRightEventType = table.get_key(MonopolyRightEventType, self.szRightEvent)
    if not szRightEventType then
        return
    end

    -- e.g.: MonopolyRightEventType.SelectDirection -> self:UpdateSelectDirection(...)
    local szFuncName = "Update" .. szRightEventType
    if self[szFuncName] then
        self[szFuncName](self, ...)
    end
end

-- szRightEvent: MonopolyRightEventType
function UIWidgetRightEvent:Open(szRightEvent, ...)
    if not self:CheckOpenCondition(szRightEvent) then
        return
    end

    self:RemoveEvent(szRightEvent)
    self:AddEvent(szRightEvent, ...)
    self:UpdateNextEvent()
end

function UIWidgetRightEvent:Close(szRightEvent)
    if szRightEvent then
        self:RemoveEvent(szRightEvent)
    else
        self.tRightEventQueue = {}
    end
    self:UpdateNextEvent()
end

function UIWidgetRightEvent:AddEvent(szRightEvent, ...)
    self.tRightEventQueue = self.tRightEventQueue or {}
    local tInfo = {
        szRightEvent = szRightEvent,
        tArgs = {...},
    }
    table.insert(self.tRightEventQueue, tInfo)
end

function UIWidgetRightEvent:RemoveEvent(szRightEvent)
    if not self.tRightEventQueue then
        return
    end
    for nIndex, tInfo in ipairs(self.tRightEventQueue) do
        if tInfo.szRightEvent == szRightEvent then
            table.remove(self.tRightEventQueue, nIndex)
            return
        end
    end
end

function UIWidgetRightEvent:UpdateNextEvent()
    self:Clear()

    local tInfo = self.tRightEventQueue and self.tRightEventQueue[#self.tRightEventQueue]
    if not tInfo then
        UIHelper.SetVisible(self._rootNode, false)
        return
    end

    UIHelper.SetVisible(self._rootNode, true)
    local szRightEvent = tInfo.szRightEvent
    local tArgs = tInfo.tArgs
    DataModel = MonopolyRightEvent.GetDataModel(szRightEvent)
    if not DataModel then
        LOG.INFO("[MonopolyRightEvent] Invalid MonopolyRightEventType: %s", tostring(szRightEvent))
        return
    end

    self.szRightEvent = szRightEvent
    if DataModel.Init then
        DataModel.Init(unpack(tArgs))
    end

    self:UpdateInfo(unpack(tArgs))
end

function UIWidgetRightEvent:CheckOpenCondition(szRightEvent)
    if not table.contain_value(MonopolyRightEventType, szRightEvent) then
        return false
    end
    if szRightEvent == MonopolyRightEventType.SelectDirection then
        if not MonopolyData.IsMyRound() then
            return false
        end
    end
    return true
end

-- 各个View的临时数据分开存
function UIWidgetRightEvent:GetViewDataTable(szRightEvent)
    szRightEvent = szRightEvent or self.szRightEvent
    if not szRightEvent then
        return
    end
    self.tViewData = self.tViewData or {}
    self.tViewData[szRightEvent] = self.tViewData[szRightEvent] or {}
    return self.tViewData[szRightEvent]
end

function UIWidgetRightEvent:Clear()
    Timer.DelAllTimer(self)
    if DataModel then
        if DataModel.UnInit then
            DataModel.UnInit()
        end
        DataModel = nil
    end
    self.szRightEvent = nil
end

-- SelectDirection = 1, -- 选择方向
-----------------------------SelectDirection------------------------------
function UIWidgetRightEvent:UpdateSelectDirection()
    self:UpdateBtnState()
    self:UpdateClockwiseText()

    Timer.DelAllTimer(self)
    Timer.AddFrameCycle(self, 1, function()
        if DataModel.bSubmitted then
            return
        end

        self:UpdateClockwiseText()

        if DataModel.GetLeftTime() > 0 then
            return
        end
    
        self:Close()
    end)
end

function UIWidgetRightEvent:UpdateBtnState()
    local nState = DataModel.bSubmitted and BTN_STATE.Disable or BTN_STATE.Normal
    UIHelper.SetButtonState(self.BtnDirCounterClockwise, nState) -- TODO
    UIHelper.SetButtonState(self.BtnDirClockwise, nState) -- TODO
end

function UIWidgetRightEvent:UpdateClockwiseText()
    local nLeftTime = DataModel.GetLeftTime()
    if DataModel.nLastLeftTime == nLeftTime then
        return
    end

    DataModel.nLastLeftTime = nLeftTime
    UIHelper.SetString(self.LabelText, g_tStrings.STR_MONOPOLY_SELECT_DIRECTION_CW .. "(" .. nLeftTime .. ")")
end

function UIWidgetRightEvent:SubmitDirection(nDirection)
    if DataModel.bSubmitted then
        return
    end

    DataModel.SetSubmitted(true)
    self:UpdateBtnState()

    MonopolyData.SendServerOperate(
        MINI_GAME_OPERATE_TYPE.SERVER_OPERATE,
        DFW_OPERATE_UP_PLAYER_DIRECTION,
        nDirection
    )

    self:Close()
end

-- CardCast = 2, -- 手牌使用[无目标]
-----------------------------CardCast------------------------------
function UIWidgetRightEvent:UpdateCardCast()
    local tCardInfo = DataModel.tCardInfo
    if not tCardInfo then
        return
    end
    -- hCardContent:Lookup("Image_CardContent"):FromUITex(tCardInfo.szBigPath, tCardInfo.nBigFrame)
    -- hCardContent:Lookup("Text_CardName"):SetText(tCardInfo.szName)
end

-- LandPurchase = 3, -- 购买空地
-----------------------------LandPurchase------------------------------
function UIWidgetRightEvent:UpdateLandPurchase(nGridIndex, nType)
    DataModel.SetData({
        nGridIndex = nGridIndex or 0,
        nType      = nType or 0,
    })

    local tData = DataModel.GetData()
    local szTitle  = g_tStrings.STR_MONOPOLY_LAND_TITLE_BUY
    local szBtnBuy = g_tStrings.STR_MONOPOLY_LAND_BTN_BUY
    if tData.nType == 2 then
        szTitle  = g_tStrings.STR_MONOPOLY_LAND_TITLE_UPGRADE
        szBtnBuy = g_tStrings.STR_MONOPOLY_LAND_BTN_UPGRADE
    end

    -- m_tUI.txtTitle:SetText(szTitle)
    -- m_tUI.txtBuyBtn:SetText(szBtnBuy)
    -- m_tUI.txtCancelBtn:SetText(g_tStrings.STR_CANCEL)
    
    local szLandName = self:GetGridName(tData.nGridIndex)
    -- m_tUI.txtLandType:SetText(szLandName)
    
    local tGridData = DFW_GetGridData(tData.nGridIndex) or {}
    local nPrice    = tGridData[4] or 0
    tData.nPrice    = nPrice
    -- m_tUI.txtPriceValue:SetText(tostring(nPrice))
    -- m_tUI.hPrice:FormatAllItemPos()
    
    local nClientIdx = MonopolyData.GetClientPlayerIndex() or 0
    local nCash      = 0
    if nClientIdx > 0 then
        nCash = DFW_GetPlayerMoney(nClientIdx) or 0
    end
    tData.nCash = nCash
    
    -- if nCash < nPrice then
    --     m_tUI.btnBuy:Enable(false)
    -- else
    --     m_tUI.btnBuy:Enable(true)
    -- end
end

function UIWidgetRightEvent:GetGridName(nGridIndex)
    local tGridConfig = Table_GetMonopolyGridConfigByID(nGridIndex)
    if tGridConfig and tGridConfig.szName then
        return tGridConfig.szName
    end
    return tostring(nGridIndex or 0)
end

function UIWidgetRightEvent:ReplyAccept()
    local tData = DataModel.GetData()
    if tData.bReplied then
        return
    end
    
    DataModel.SetReplied(true)
    -- m_tUI.btnBuy:Enable(false)
    -- m_tUI.btnCancel:Enable(false)
    
    MonopolyData.SendServerOperate(
        MINI_GAME_OPERATE_TYPE.SERVER_OPERATE,
        DFW_OPERATE_UP_BUILDGRID_CONFIRM
    )
    -- 确认购买等服务器下发广播后再关闭
end

function UIWidgetRightEvent:ReplyCancel()
    local tData = DataModel.GetData()
    if tData.bReplied then
        return
    end
    
    DataModel.SetReplied(true)
    -- m_tUI.btnBuy:Enable(false)
    -- m_tUI.btnCancel:Enable(false)
    
    MonopolyData.SendServerOperate(
        MINI_GAME_OPERATE_TYPE.SERVER_OPERATE,
        DFW_OPERATE_UP_BUILDGRID_CANCEL
    )
    -- 取消购买立即关闭
    self:Close()
end

-- TargetSelect = 4, -- 选择玩家
-----------------------------TargetSelect------------------------------
function UIWidgetRightEvent:UpdateTargetSelect(nCardID)
    self:BuildPlayerCards()
    self:UpdateConfirmBtn()
end

function UIWidgetRightEvent:FillPlayerCard(hItem, nDfwIndex)
    local dwPlayerID = DFW_GetPlayerDWID(nDfwIndex)

    local szName = ""
    local dwForceID = 0
    local nRoleType = 0
    local dwMiniAvatarID = 0

    local tTeamInfo = GetClientTeam().GetMemberInfo(dwPlayerID)
    if tTeamInfo then
        szName = tTeamInfo.szName or ""
        dwForceID = tTeamInfo.dwForceID
        nRoleType = tTeamInfo.nRoleType
        dwMiniAvatarID = tTeamInfo.dwMiniAvatarID
    end

    -- hItem:Lookup("Text_Name"):SetText(szName)

    local nBgID = 1
    local tIdentityInfo = MonopolyData.GetIdentityInfoByDfwIndex(nDfwIndex)
    if tIdentityInfo and tIdentityInfo.nBgID then
        nBgID = tIdentityInfo.nBgID
    end
    -- local szBgPath = CARD_BG_PATH_MAP[nBgID]
    -- if szBgPath then
    --     hItem:Lookup("Image_TargetCardBg_1"):FromTextureFile(szBgPath)
    -- end

    local nRank = MonopolyData.GetPlayerMoneyRankByDfwIndex(nDfwIndex)
    -- local nRankFrame = RANK_ICON_FRAME_MAP[nRank]
    -- if nRankFrame then
    --     local imgRank = hItem:Lookup("Image_Rank1_S")
    --     imgRank:FromUITex("ui/Image/UITga/DesertStorm.UITex", nRankFrame)
    --     imgRank:Show()
    -- end

    -- local hAvatarC = hItem:Lookup("Handle_People/Handle_AvatarC")
    -- RoleChangeNew.UpdateAvatar(
    --     hAvatarC,
    --     {
    --         nRoleType      = nRoleType,
    --         dwMiniAvatarID = dwMiniAvatarID,
    --         dwForceID      = dwForceID,
    --     },
    --     true, nil, true
    -- )

    local nMyIndex = MonopolyData.GetClientPlayerIndex()
    -- local imgMe = hItem:Lookup("Handle_People/Image_Me")
    -- imgMe:Show(nDfwIndex == nMyIndex)

    -- hItem.imgHover:Hide()
end

function UIWidgetRightEvent:BuildPlayerCards()
    local tViewData = self:GetViewDataTable()
    if not tViewData then
        return
    end

    UIHelper.RemoveAllChildren(self.LayoutContent)
    tViewData.tPlayerItems = {}

    local nMyIndex = MonopolyData.GetClientPlayerIndex()
    local tPlayablePlayerFlags = DFW_GetPlayerPlayCardPlayer(nMyIndex)
    local tData = DataModel.GetData()

    -- LOG.INFO("[大富翁-目标选择] 构建玩家列表 卡牌ID=" .. tostring(tData.nCardID) .. " 可选标记=")
    -- LOG.TABLE(tPlayablePlayerFlags)

    for i = 1, DFW_PLAYERNUM do
        local dwPlayerID = DFW_GetPlayerDWID(i)
        if dwPlayerID and dwPlayerID ~= 0 then
            local bCanSelect = false
            if type(tPlayablePlayerFlags) == "table" then
                bCanSelect = (tPlayablePlayerFlags[i] == 1)
            end

            if bCanSelect then
                -- local hItem = m_tUI.hContent:AppendItemFromIni(INI_PATH, "Handle_TargetCard_1")
                -- hItem.nDfwIndex = i
                -- hItem.imgHover = hItem:Lookup("Image_Hover_pic_1")
                -- self:FillPlayerCard(hItem, i)
                -- table.insert(tViewData.tPlayerItems, hItem)
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UIWidgetRightEvent:UpdateSelection()
    local tViewData = self:GetViewDataTable()
    if not tViewData then
        return
    end

    local tData = DataModel.GetData()
    -- for _, hItem in ipairs(tViewData.tPlayerItems or {}) do
    --     hItem.imgHover:Show(hItem.nDfwIndex == tData.nSelectedIndex)
    -- end
end

function UIWidgetRightEvent:UpdateConfirmBtn()
    local tData = DataModel.GetData()
    UIHelper.SetButtonState(self.BtnSelect, tData.nSelectedIndex > 0 and BTN_STATE.Normal or BTN_STATE.Disable) -- TODO
end

function UIWidgetRightEvent:OnPlayerCardClick(nDfwIndex)
    if not nDfwIndex then
        return
    end

    local tData = DataModel.GetData()

    if tData.nSelectedIndex == nDfwIndex then
        DataModel.SetSelected(0)
    else
        DataModel.SetSelected(nDfwIndex)
    end

    self:UpdateSelection()
    self:UpdateConfirmBtn()
end

function UIWidgetRightEvent:DoConfirmSelect()
    local tData = DataModel.GetData()
    if tData.nSelectedIndex <= 0 then
        return
    end
    MonopolyData.SendServerOperate(
        MINI_GAME_OPERATE_TYPE.SERVER_OPERATE,
        DFW_OPERATE_UP_ACTION_PLAYCARDTOPLAYER,
        tData.nCardID,
        tData.nSelectedIndex
    )
end

function UIWidgetRightEvent:DoCancelSelect()
	local tData = DataModel.GetData()
	if tData.nCardID > 0 then
		Event.Dispatch(EventType.OnMonopolyCardListUpdateSelectCard, 0)
		MonopolyData.SendServerOperate(
			MINI_GAME_OPERATE_TYPE.SERVER_OPERATE,
			DFW_OPERATE_UP_ACTION_CANCELCARD,
			tData.nCardID
		)
	end
end

function UIWidgetRightEvent:ConfirmSelect()
    self:DoConfirmSelect()
    self:Close()
end

function UIWidgetRightEvent:CancelSelect()
    self:DoCancelSelect()
    self:Close()
end

-- AuctionInfo = 5, -- 拍卖卡
-----------------------------AuctionInfo------------------------------
function UIWidgetRightEvent:UpdateAuctionInfo()
    self:UpdateCommonInfo()
    self:ShowAuctionState(DataModel.nState)
    if DataModel.nState == MONOPOLY_AUCTION_STATE.RESULT then
        self:UpdateResultState()
    end
end

function UIWidgetRightEvent:SetEditBidPrice(nPrice)
    UIHelper.SetString(self.EditBoxBid, nPrice)
end

function UIWidgetRightEvent:GetEditBidPrice()
    local szText = UIHelper.GetString(self.EditBoxBid) or "0"
    local nPrice = tonumber(szText) or 0
    nPrice = math.floor(nPrice)
    if nPrice < 0 then
        nPrice = 0
    end
    return nPrice
end

function UIWidgetRightEvent:UpdateCommonInfo()
    -- 公共区信息需要同时驱动出价页和旁观页，避免两边显示不一致。
    local nInitPrice = DataModel.CalcInitPrice()
    local nLevel = DataModel.GetGridLevel()

    -- hTextRentValue:SetText(tostring(nInitPrice))
    -- hTextShopLevel:SetText(FormatString(g_tStrings.STR_MONOPOLY_AUCTION_HOUSE_LEVEL, nLevel))

    local tGridInfo = Table_GetMonopolyGridInfo(nLevel)
    -- if hImgHeader and tGridInfo then
    --     local szPath = tGridInfo.szPath
    --     local nFrame = tGridInfo.nFrame
    --     if nFrame ~= -1 then
    --         hImgHeader:FromUITex(szPath, nFrame)
    --     else
    --         hImgHeader:FromTextureFile(szPath)
    --     end
    -- end

    -- if hTextBidInitPrice then
    --     hTextBidInitPrice:SetText(tostring(nInitPrice))
    -- end

    -- if hTextWatchPrice then
    --     hTextWatchPrice:SetText(tostring(nInitPrice))
    -- end

    if self:GetEditBidPrice() <= 0 then
        self:SetEditBidPrice(nInitPrice)
    end
end

function UIWidgetRightEvent:ShowAuctionState(nState)
    -- 同一时刻只显示一个状态页，避免多个状态窗口重叠。
    local bMyBid = nState == MONOPOLY_AUCTION_STATE.MY_BID
    local bWaiting = nState == MONOPOLY_AUCTION_STATE.WAITING
    local bWatch = nState == MONOPOLY_AUCTION_STATE.WATCH
    local bResult = nState == MONOPOLY_AUCTION_STATE.RESULT

    -- if hWndMyBid then
    --     hWndMyBid:Show(bMyBid)
    -- end
    -- if hWndWaiting then
    --     hWndWaiting:Show(bWaiting)
    -- end
    -- if hWndWatch then
    --     hWndWatch:Show(bWatch)
    -- end
    -- if hWndResult then
    --     hWndResult:Show(bResult)
    -- end
end

function UIWidgetRightEvent:UpdateResultState()
    -- 结果页进入时再拉一次结算数据，保证展示的是最新拍卖结果。
    DataModel.PullAuctionResult()

    -- if hTextResultPrice then
    --     hTextResultPrice:SetText(tostring(DataModel.nFinalBid or 0))
    -- end

    -- if hTextResultName then
    --     local szName = MonopolyData.GetNameByDfwIndex(DataModel.nWinnerIndex)
    --     hTextResultName:SetText(szName or "")
    -- end
end

function UIWidgetRightEvent:AdjustBidByDelta(nDelta)
    local nPrice = self:GetEditBidPrice()
    nPrice = nPrice + (nDelta or 0)
    if nPrice < 0 then
        nPrice = 0
    end
    self:SetEditBidPrice(nPrice)
end

function UIWidgetRightEvent:SetBidToMaxMoney()
    local nPlayerIndex = MonopolyData.GetClientPlayerIndex() or 0
    local nMoney = 0
    if nPlayerIndex > 0 then
        nMoney = DFW_GetPlayerMoney(nPlayerIndex) or 0
    end
    if nMoney < 0 then
        nMoney = 0
    end
    self:SetEditBidPrice(nMoney)
end

function UIWidgetRightEvent:ReplyBid()
    local nPrice = self:GetEditBidPrice()
    -- 发出出价请求后，本地立即切到等待态，和服务器回包前的交互保持一致。
    MonopolyData.SendServerOperate(
        MINI_GAME_OPERATE_TYPE.SERVER_OPERATE,
        DFW_OPERATE_UP_AUCTION_BID,
        nPrice
    )
    self:SetAuctionState(MONOPOLY_AUCTION_STATE.WAITING)
end

function UIWidgetRightEvent:ReplyGiveUp()
    -- 弃拍后直接进入旁观态，等待最终拍卖结果下发。
    MonopolyData.SendServerOperate(
        MINI_GAME_OPERATE_TYPE.SERVER_OPERATE,
        DFW_OPERATE_UP_AUCTION_FALL
    )
    self:SetAuctionState(MONOPOLY_AUCTION_STATE.WATCH)
end

function UIWidgetRightEvent:SetAuctionState(nState)
    DataModel.SetState(nState)
    self:UpdateAuctionInfo()
end

-- LandExchange = 6, -- 换地卡
-----------------------------LandExchange------------------------------
function UIWidgetRightEvent:UpdateLandExchange()
    
end

return UIWidgetRightEvent