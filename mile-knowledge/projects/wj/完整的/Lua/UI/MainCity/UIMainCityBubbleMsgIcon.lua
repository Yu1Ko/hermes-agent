-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMainCityBubbleMsgIcon
-- Date: 2023-11-28 10:52:55
-- Desc: ?
-- Prefab: WidgetBubbleInfomationBtn
-- ---------------------------------------------------------------------------------
local colorRed = cc.c3b(255, 133, 125)
local nNeutralActivityID = 885  --的卢拍卖活动

local UIMainCityBubbleMsgIcon = class("UIMainCityBubbleMsgIcon")

function UIMainCityBubbleMsgIcon:OnEnter(tbMgr)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbMgr = tbMgr
    self.bAuction = false   --拍卖
    self:UpdateInfo()
    self:UpdateTimerInfo()
end

function UIMainCityBubbleMsgIcon:OnExit()
    self.bInit = false
    self:UnRegEvent()

    RedpointMgr.UnRegisterRedpoint(self.ImgRedPoint)
end

function UIMainCityBubbleMsgIcon:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBubbleInfomation, EventType.OnClick, function()
        local tMsg = self.tbMgr
        assert(tMsg)
        local szAction = tMsg.szAction

        if IsFunction(szAction) then
            szAction()
        elseif IsString(szAction) then
            if not string.is_nil(szAction) then
                local bResult = string.execute(szAction)
            end
        end
    end)
end

function UIMainCityBubbleMsgIcon:RegEvent()
    Event.Reg(self, "BM_LOOKUP_RESPOND", function(nRespondCode, nCamp)
        if not self.bAuction then return end
        if nRespondCode == AUCTION_RESPOND_CODE.SUCCEED then
            local nEndTime = GetAuctionClient().GetBMOverTime(nCamp)
            self.tbCamp[nCamp] = {nEndTime = nEndTime}
            self:UpdateCommandAuctionTimer()
        elseif nRespondCode == AUCTION_RESPOND_CODE.BM_CLOSEID then
            self:UpdateCommandAuctionTimer()
		end
    end)

    Event.Reg(self, EventType.OnAuctionStateChanged, function()
        if self.bAuction then
            self.tbCamp = {}
            self.bAuction = true
            local tbAuctionList = TradingData.GetActivityList()
            for _, nActivityID in ipairs(tbAuctionList) do
                local nCamp = nActivityID == nNeutralActivityID and BLACK_MARKET_TYPE.ACTIVITY or GetClientPlayer().nCamp
                TradingData.BMLookup(nil, nCamp)
            end
        end
    end)

    Event.Reg(self, EventType.OnAuctionLootListRedPointChanged, function ()
        self:UpdateAuctionOpeningInfo()
    end)
end

function UIMainCityBubbleMsgIcon:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMainCityBubbleMsgIcon:UpdateInfo()
    local tbMgr = self.tbMgr
    assert(tbMgr)
    UIHelper.SetSpriteFrame(self.imgBubbleInfomation, tbMgr.szMainCityIcon)

    RedpointMgr.UnRegisterRedpoint(self.ImgRedPoint)
    if tbMgr.nRedPointID and tbMgr.nRedPointID > 0 then
        RedpointMgr.RegisterRedpoint(self.ImgRedPoint, nil, {tbMgr.nRedPointID})
    end

    self:UpdateAuctionOpeningInfo()
end

function UIMainCityBubbleMsgIcon:UpdateAuctionOpeningInfo()
    local tbMgr = self.tbMgr
    assert(tbMgr)
    if tbMgr.szType ~= "AuctionOpening" then return end
    UIHelper.SetVisible(self.ImgRedPoint, RedpointHelper.AuctionLootList_HasRedPoint())
end

function UIMainCityBubbleMsgIcon:UpdateTimerInfo()
    Timer.DelAllTimer(self)
    UIHelper.SetVisible(self.LabelBubbleList, false)
    UIHelper.SetVisible(self.imgBubbleListbg, false)
    UIHelper.SetVisible(self.SilderTimely, false)

    local tbMgr = self.tbMgr
    assert(tbMgr)
    local szBubbleType = tbMgr and tbMgr.szType

    if szBubbleType == "CommandAuctionOpening" or szBubbleType == "ActivityAuctionOpening" then
        self.tbCamp = {}
        self.nEndTime = 0
        self.bAuction = true
        local tbAuctionList = TradingData.GetActivityList()
        for _, nActivityID in ipairs(tbAuctionList) do
            local nCamp = nActivityID == nNeutralActivityID and BLACK_MARKET_TYPE.ACTIVITY or GetClientPlayer().nCamp
            self.tbCamp[nCamp] = {}
            TradingData.BMLookup(nil, nCamp)
        end
    elseif szBubbleType == "ArenaQueueTips" then
        self:UpdateArenaQueueTimer()
    elseif szBubbleType == "BattleFieldQueueTips" then
        self:UpdateBattleFieldQueueTimer()
    elseif szBubbleType == "TongBattleFieldQueueTips" then
        self:UpdateTongBattleFieldQueueTimer()
    elseif szBubbleType == "TongDiplomacy" then
        self:UpdateTongDiplomacyTimer()
    elseif szBubbleType == "AIBodyGenerateWatingTips" then
        self:UpdateAIGenerateTimer()
    elseif tbMgr.nLifeTime then
        self:UpdateNormalTimer(tbMgr.nLifeTime)
    elseif tbMgr.nEndTime and tbMgr.nStartTime then
        self:UpdateTimerWithEndTime(tbMgr)
    elseif tbMgr.nTotalTime then
        self:UpdateTimerWithTotalTime(tbMgr)
    end
end

function UIMainCityBubbleMsgIcon:UpdateCommandAuctionTimer()
    local function func()
        local nEndTime = 0
        local nCurrentTime = GetGSCurrentTime()
        for nCamp, tbInfo in pairs(self.tbCamp) do
            if tbInfo.nEndTime > nCurrentTime then
                -- 取最小时间
                nEndTime = nEndTime > 0 and math.min(nEndTime, tbInfo.nEndTime) or tbInfo.nEndTime
            end
        end
        UIHelper.SetVisible(self.LabelBubbleList, false)
        UIHelper.SetVisible(self.imgBubbleListbg, false)
        UIHelper.SetTextColor(self.LabelBubbleList, colorRed)
        if nEndTime ~= 0 then
            local nTime  = math.max(0, (nEndTime - nCurrentTime))
            if nTime > 0 then
                local szEndTime = self.GetTimeText(nTime)
                UIHelper.SetString(self.LabelBubbleList, szEndTime)
                UIHelper.SetVisible(self.LabelBubbleList, true)
                UIHelper.SetVisible(self.imgBubbleListbg, true)
            else
                UIHelper.SetVisible(self.LabelBubbleList, false)
                UIHelper.SetVisible(self.imgBubbleListbg, false)
            end
        else
            UIHelper.SetVisible(self.LabelBubbleList, false)
            UIHelper.SetVisible(self.imgBubbleListbg, false)
        end
    end
    func()

    Timer.AddCycle(self, 1, func)
end

function UIMainCityBubbleMsgIcon:UpdateArenaQueueTimer()
    local function func()
        local nPassTime, _ = ArenaData.GetQueueTime()
        if nPassTime > 0 then
            local szPassTime = self.GetTimeText(nPassTime)
            UIHelper.SetString(self.LabelBubbleList, szPassTime)
            UIHelper.SetVisible(self.LabelBubbleList, true)
            UIHelper.SetVisible(self.imgBubbleListbg, true)
        end
    end
    func()

    Timer.AddCycle(self, 1, func)
end

function UIMainCityBubbleMsgIcon:UpdateAIGenerateTimer()
    local function func()
        local nTime= GetCurrentTime() - (AiBodyMotionData.GetAIGenerateStartTick() or GetCurrentTime())
        if nTime > 0 then
            local szTime = self.GetTimeText(nTime)
            UIHelper.SetString(self.LabelBubbleList, szTime)
            UIHelper.SetVisible(self.LabelBubbleList, true)
            UIHelper.SetVisible(self.imgBubbleListbg, true)
        end
    end
    func()

    Timer.AddCycle(self, 1, func)
end

function UIMainCityBubbleMsgIcon:UpdateBattleFieldQueueTimer()
    local function func()
        local nPassTime, _ = BattleFieldQueueData.GetQueueTime()
        if nPassTime > 0 then
            local szPassTime = self.GetTimeText(nPassTime)
            UIHelper.SetString(self.LabelBubbleList, szPassTime)
            UIHelper.SetVisible(self.LabelBubbleList, true)
            UIHelper.SetVisible(self.imgBubbleListbg, true)
        end
    end
    func()

    Timer.AddCycle(self, 1, func)
end

function UIMainCityBubbleMsgIcon:UpdateTongBattleFieldQueueTimer()
    local function func()
        local nPassTime = BattleFieldQueueData.GetTongBattleFieldQueueTime()
        if nPassTime > 0 then
            local szPassTime = self.GetTimeText(nPassTime)
            UIHelper.SetString(self.LabelBubbleList, szPassTime)
            UIHelper.SetVisible(self.LabelBubbleList, true)
            UIHelper.SetVisible(self.imgBubbleListbg, true)
        end
    end
    func()

    Timer.AddCycle(self, 0.5, func)
end

function UIMainCityBubbleMsgIcon:UpdateTongDiplomacyTimer()
    local function func()
        local nCDEndTime
        local tbDiplocacyList = TongData.GetAllDiplomacyRelationList()
        for _, tbDiplocacy in ipairs(tbDiplocacyList) do
            for _, tbInfo in ipairs(tbDiplocacy) do
                if tbInfo and tbInfo.nCDEndTime then
                    nCDEndTime = nCDEndTime and math.min(nCDEndTime, tbInfo.nCDEndTime) or tbInfo.nCDEndTime
                end
            end
        end
        if not nCDEndTime then return end
        local nPassTime = nCDEndTime - GetCurrentTime()
        if nPassTime > 0 then
            local szPassTime = self.GetTimeText(nPassTime)
            UIHelper.SetString(self.LabelBubbleList, szPassTime)
            UIHelper.SetVisible(self.LabelBubbleList, true)
            UIHelper.SetVisible(self.imgBubbleListbg, true)
            UIHelper.SetTextColor(self.LabelBubbleList, colorRed)
        end
    end
    func()

    Timer.AddCycle(self, 1, func)
end

function UIMainCityBubbleMsgIcon:UpdateNormalTimer(nLifeTime)
    if nLifeTime < 0 then
        return
    end

    local nEndTime = GetCurrentTime() + nLifeTime
    local function func()
        local nCurTime = GetCurrentTime()
        UIHelper.SetVisible(self.SilderTimely, true)
        local fPercent = (nLifeTime - (nEndTime - nCurTime)) / nLifeTime
        UIHelper.SetProgressBarStarPercentPt(self.SilderTimely, 0.5 , 0)
        UIHelper.SetProgressBarPercent(self.SilderTimely, fPercent * 100)
    end
    func()
    Timer.AddFrameCycle(self, 3, func)
end

function UIMainCityBubbleMsgIcon:UpdateTimerWithTotalTime(tbMgr)
    local nStarTime = tbMgr.nLeftTime + GetCurrentTime()
    local nEndTime = tbMgr.nTotalTime
    local bShowTimeLabel = tbMgr.bShowTimeLabel
    local bHideTimeSilder = tbMgr.bHideTimeSilder
    local function func()
        UIHelper.SetVisible(self.SilderTimely, not bHideTimeSilder)
        local nCurTime = GetCurrentTime()
        local fPercent = (nStarTime - nCurTime) / nEndTime
        UIHelper.SetProgressBarStarPercentPt(self.SilderTimely, 0.5 , 0)
        UIHelper.SetProgressBarPercent(self.SilderTimely, fPercent * 100)
        if fPercent <= 0 then
            BubbleMsgData.RemoveMsg(tbMgr.szType)
        end

        local nLeftTime = nStarTime - nCurTime
        local szPassTime = self.GetTimeText(nLeftTime)
        UIHelper.SetString(self.LabelBubbleList, szPassTime)
        UIHelper.SetVisible( self.LabelBubbleList, bShowTimeLabel)
        UIHelper.SetVisible(self.imgBubbleListbg, bShowTimeLabel)
    end
    func()
    Timer.AddFrameCycle(self, 3, func)
end

function UIMainCityBubbleMsgIcon:UpdateTimerWithEndTime(tbMgr)
    local nStarTime = tbMgr.nStartTime
    local nEndTime = tbMgr.nEndTime
    local nTotalTime = tbMgr.nTotalTime
    local bShowTimeLabel = tbMgr.bShowTimeLabel
    local bHideTimeSilder = tbMgr.bHideTimeSilder
    local function func()
        UIHelper.SetVisible(self.SilderTimely, not bHideTimeSilder)
        local nCurTime = GetCurrentTime()
        local fPercent = (nEndTime - nCurTime) / nTotalTime
        UIHelper.SetProgressBarStarPercentPt(self.SilderTimely, 0.5 , 0)
        UIHelper.SetProgressBarPercent(self.SilderTimely, fPercent * 100)
        if fPercent <= 0 then
            BubbleMsgData.RemoveMsg(tbMgr.szType)
        end

        local nLeftTime = nEndTime - nCurTime
        local szPassTime = self.GetTimeText(nLeftTime)
        UIHelper.SetString(self.LabelBubbleList, szPassTime)
        UIHelper.SetVisible( self.LabelBubbleList, bShowTimeLabel)
        UIHelper.SetVisible(self.imgBubbleListbg, bShowTimeLabel)
    end
    func()
    Timer.AddFrameCycle(self, 3, func)
end

function UIMainCityBubbleMsgIcon.GetTimeText(nTime, bFrame, bCeil)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end

    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60

    local szH = nH > 0 and string.format("%02d:", nH) or ""
    local szM = string.format("%02d:", nM)
    local szS = string.format("%02d", nS)

    if bCeil then
        nS = math.ceil(nS)
    else
        nS = math.floor(nS)
    end

    return szH..szM..szS
end

function UIMainCityBubbleMsgIcon:SetDestroy(bDestroy)
    self._donotdestroy = not bDestroy
end

return UIMainCityBubbleMsgIcon