-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIOperationCenterRightTop
-- Date: 2026-04-09 20:54:16
-- Desc: 江湖快报 右上角一堆按钮相关处理
-- ---------------------------------------------------------------------------------

local UIOperationCenterRightTop = class("UIOperationCenterRightTop")

function UIOperationCenterRightTop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIOperationCenterRightTop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationCenterRightTop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPurchase,EventType.OnClick,function ()
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
    end)

    UIHelper.BindUIEvent(self.BtnHotSpot,EventType.OnClick,function ()
        UIMgr.Open(VIEW_ID.PanelHotSpotBanner)
    end)

    UIHelper.BindUIEvent(self.BtnQA, EventType.OnClick, function()
        QuestionnaireData.OpenQuestionnaire()
    end)

    UIHelper.BindUIEvent(self.BtnPlayerLetter, EventType.OnClick, function()
        -- 打开网页
        WebUrl.OpenByID(WEBURL_ID.PRODUCER_LETTER)

        -- 标记下
        APIHelper.Do(HuaELouData.szDidKeyProducerLetter)

        -- 刷新 花萼楼内的信封红点、 主城的花萼楼的信封气泡和红点
        UIHelper.SetVisible(self.ImgRedPointPlayerLetter, false)
        Event.Dispatch("OnUpdateHuaELouRedPoint")
    end)

    UIHelper.BindUIEvent(self.BtnTicket, EventType.OnClick, function()
        if Platform.IsMobile() then
            WebUrl.OpenByID(WEBURL_ID.TICKETS_PURCHASE_ELIGIBILITY_MOBILE)
        else
            WebUrl.OpenByID(WEBURL_ID.TICKETS_PURCHASE_ELIGIBILITY)
        end

        APIHelper.Do(HuaELouData.szTicketPurchaseEligibility)

        UIHelper.SetVisible(self.ImgRedPointTicket, false)
        Event.Dispatch("OnUpdateHuaELouRedPoint")
    end)

    UIHelper.BindUIEvent(self.BtnGuessing, EventType.OnClick, function()
        BattleFieldData.OpenTongWarGuessing()
    end)

    UIHelper.BindUIEvent(self.Btn15Anni, EventType.OnClick, function()
        if Platform.IsMobile() then
            WebUrl.OpenByID(WEBURL_ID.FIFTEEN_Anni_LIVE_STREAMING_MOBILE)
        else
            WebUrl.OpenByID(WEBURL_ID.FIFTEEN_Anni_LIVE_STREAMING)
        end

        APIHelper.Do(HuaELouData.sz15AnniLiveStreaming)

        UIHelper.SetVisible(self.ImgRedPoint15Anni, false)
        Event.Dispatch("OnUpdateHuaELouRedPoint")
    end)

    UIHelper.BindUIEvent(self.BtnTianXuan, EventType.OnClick, function()
        if Platform.IsMobile() then
            WebUrl.OpenByID(WEBURL_ID.TIAN_XUAN_VOTE_MOBILE)
        else
            WebUrl.OpenByID(WEBURL_ID.TIAN_XUAN_VOTE)
        end

        APIHelper.Do(HuaELouData.szTianXuan)

        UIHelper.SetVisible(self.ImgRedPointTianXuan, false)
        Event.Dispatch("OnUpdateHuaELouRedPoint")
    end)

    UIHelper.BindUIEvent(self.BtnWaizhuang, EventType.OnClick, function()
        WebUrl.OpenByID(WEBURL_ID.TONG_REN_EXTERIOR)

        APIHelper.Do(HuaELouData.szTongRenExterior)

        UIHelper.SetVisible(self.ImgRedPointWaizhuang, false)
        Event.Dispatch("OnUpdateHuaELouRedPoint")
    end)

    UIHelper.BindUIEvent(self.BtnEffect, EventType.OnClick, function()
        WebUrl.OpenByID(WEBURL_ID.WEB_EFFECT)

        APIHelper.Do(HuaELouData.szEffectDailyRedPoint)

        UIHelper.SetVisible(self.ImgRedPointEffect, false)
        Event.Dispatch("OnUpdateHuaELouRedPoint")
    end)

    UIHelper.BindUIEvent(self.BtnWuqi, EventType.OnClick, function()
        WebUrl.OpenByID(WEBURL_ID.TONG_REN_WEAPON)

        APIHelper.Do(HuaELouData.szTongRenWeapon)

        UIHelper.SetVisible(self.ImgRedPointWuqi, false)
        Event.Dispatch("OnUpdateHuaELouRedPoint")
    end)

    UIHelper.BindUIEvent(self.BtnBaoming, EventType.OnClick, function()
        WebUrl.OpenByID(WEBURL_ID.COMPETITIVE_MATCH)

        APIHelper.Do(HuaELouData.szDidKeyCompetitiveMatch2025)

        UIHelper.SetVisible(self.ImgBaoMingRedPoint, false)
        Event.Dispatch("OnUpdateHuaELouRedPoint")
    end)

    UIHelper.BindUIEvent(self.BtnJingcaiQunying, EventType.OnClick, function()
        WebUrl.OpenByID(WEBURL_ID.COMPETITIVE_MATCH_GUESS)

        APIHelper.Do(HuaELouData.szDidKeyCompetitiveMatchGuess2025)

        UIHelper.SetVisible(self.ImgJingCaiRedPoint, false)
        Event.Dispatch("OnUpdateHuaELouRedPoint")
    end)

    UIHelper.BindUIEvent(self.BtnShop, EventType.OnClick, function()
        if self.fnClickShop then
            self.fnClickShop()
        end
    end)

end

function UIOperationCenterRightTop:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.Add(self, 0.1, function ()
            UIHelper.CascadeDoLayoutDoWidget(self.LayoutRightTop, true, true)
        end)
    end)
end

function UIOperationCenterRightTop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationCenterRightTop:UpdateInfo()
    UIHelper.SetVisible(self.WidgetAnchorQA, QuestionnaireData.bHasNew and not AppReviewMgr.IsReview())

    local nImgCount = HotSpotData.GetImageCountByPopID(HotSpotData.GetDefaultPopID()) or 0
    UIHelper.SetVisible(self.WidgetAnchorHotSpot, nImgCount >= 1 and g_pClientPlayer.nLevel >= 106 and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetPlayerLetter, WebUrl.CanShow(WEBURL_ID.PRODUCER_LETTER) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointPlayerLetter, HuaELouData.GetProducerLetterRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorTicket, WebUrl.CanShow(WEBURL_ID.TICKETS_PURCHASE_ELIGIBILITY) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointTicket, HuaELouData.GetTicketRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorGuessing, WebUrl.CanShow(WEBURL_ID.TONG_WAR_GUESSING) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointGuessing, HuaELouData.GetTongWarGuessingRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchor15Anni, WebUrl.CanShow(WEBURL_ID.FIFTEEN_Anni_LIVE_STREAMING) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPoint15Anni, HuaELouData.Get15AnniRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorTianXuan, WebUrl.CanShow(WEBURL_ID.TIAN_XUAN_VOTE) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointTianXuan, HuaELouData.GetTianXuanRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorWaizhuang, WebUrl.CanShow(WEBURL_ID.TONG_REN_EXTERIOR) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointWaizhuang, HuaELouData.GetTongRenExteriorRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorEffect, WebUrl.CanShow(WEBURL_ID.WEB_EFFECT) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointEffect, HuaELouData.GetEffectDailyRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorWuqi, WebUrl.CanShow(WEBURL_ID.TONG_REN_WEAPON) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointWuqi, HuaELouData.GetTongRenWeaponRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorBaoming, WebUrl.CanShow(WEBURL_ID.COMPETITIVE_MATCH) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgBaoMingRedPoint, HuaELouData.GetCompetitiveMatch2025RedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorJingcaiQunying, WebUrl.CanShow(WEBURL_ID.COMPETITIVE_MATCH_GUESS) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgJingCaiRedPoint, HuaELouData.GetCompetitiveMatchGuess2025RedPoint() and not AppReviewMgr.IsReview())

    UIHelper.LayoutDoLayout(self.LayoutRightTopContent)
end



function UIOperationCenterRightTop:UpdateJJCBtnBright()
    if AppReviewMgr.IsReview() then
        return
    end

    if IsVersionTW() then
        return
    end

    local nTime = GetCurrentTime()

    local function ReturnDateToTime(szTime)
        local t = SplitString(szTime, ";")
        if #t >= 6 then
            return DateToTime(t[1], t[2], t[3], t[4], t[5], t[6])
        end
    end
    self.tPVPLinkDate = self.tPVPLinkDate or {}
    if IsTableEmpty(self.tPVPLinkDate) then
        self.tPVPLinkDate = Table_GetPVPLinkDate()
    end
    for _, tLine in pairs(self.tPVPLinkDate) do
        local nStartTime = tLine.nStartTime or ReturnDateToTime(tLine.szStart)
        local nEndTime = tLine.nEndTime or ReturnDateToTime(tLine.szEnd)
        tLine.nStartTime = nStartTime
        tLine.nEndTime = nEndTime
        if nStartTime and nEndTime and nTime > nStartTime and nTime < nEndTime then
            if not UIHelper.GetVisible(self.BtnQunYingStream) then
                UIHelper.SetVisible(self.BtnQunYingStream, true)
                UIHelper.BindUIEvent(self.BtnQunYingStream, EventType.OnClick, function ()
                    if Platform.IsMobile() then
                        UIHelper.OpenWeb(tLine.szPath)
                    else
                        UIHelper.OpenWebWithDefaultBrowser(tLine.szPath)
                    end
                    if UIHelper.GetVisible(self.ImgRedPointQunYingStream) then
                        APIHelper.Do(UIHelper.GBKToUTF8(tLine.szTip))
                        Event.Dispatch(EventType.OnUpdateHuaELouRedPoint)
                    end
                end)
            end

            local nStartShineTime = ReturnDateToTime(tLine.szStartShine)
			local nEndShineTime = ReturnDateToTime(tLine.szEndShine)

            local bRedPoint = false
            if nTime > nStartShineTime and nTime < nEndShineTime then
                bRedPoint = not APIHelper.IsDid(UIHelper.GBKToUTF8(tLine.szTip))
            end

            if bRedPoint and not UIHelper.GetVisible(self.ImgRedPointQunYingStream) then
                UIHelper.SetVisible(self.ImgRedPointQunYingStream, true)
                Event.Dispatch(EventType.OnUpdateHuaELouRedPoint)
            elseif not bRedPoint and UIHelper.GetVisible(self.ImgRedPointQunYingStream) then
                UIHelper.SetVisible(self.ImgRedPointQunYingStream, false)
                Event.Dispatch(EventType.OnUpdateHuaELouRedPoint)
            end

            return
        end
    end

    if UIHelper.GetVisible(self.WidgetAnchorQunYingStream) then
        UIHelper.SetVisible(self.WidgetAnchorQunYingStream, false)
    end
    if UIHelper.GetVisible(self.ImgRedPointQunYingStream) then
        UIHelper.SetVisible(self.ImgRedPointQunYingStream, false)
    end
end

function UIOperationCenterRightTop:InitCurrency(szCurrency, szItemCurrency)
    UIHelper.RemoveAllChildren(self.LayoutCurrency)
    if szCurrency and szCurrency ~= "" then
        local tCurrencies = SplitString(szCurrency, ";")
        for _, szName in ipairs(tCurrencies) do
            if szName == "Money" then
                UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutCurrency, nil, true)
            else
                local scriptCurrency = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutCurrency, szName)
                scriptCurrency:SetCurrencyType(szName)
	            scriptCurrency:HandleEvent()
            end
        end
    end
    if szItemCurrency and szItemCurrency ~= "" then
        local tCurrencies = SplitString(szItemCurrency, ";")
        for _, szName in ipairs(tCurrencies) do
            local tParts = SplitString(szName, "_")
            local nTabType = tonumber(tParts[1])
            local nIndex = tonumber(tParts[2])
            if nTabType and nIndex then
                UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutCurrency, nTabType, nIndex, true)
            end
        end
    end
    UIHelper.SetVisible(self.LayoutCurrency, true)
    UIHelper.LayoutDoLayout(self.LayoutCurrency)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UIOperationCenterRightTop:InitShop(fnClickShop)
    self.fnClickShop = fnClickShop
    UIHelper.SetVisible(self.WidgetAnchorShop, true)
    UIHelper.LayoutDoLayout(self.LayoutRightTopContent)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UIOperationCenterRightTop:Reset()
    UIHelper.RemoveAllChildren(self.LayoutCurrency)
    UIHelper.SetVisible(self.LayoutCurrency, false)

    self.fnClickShop = nil
    UIHelper.SetVisible(self.WidgetAnchorShop, false)

    UIHelper.LayoutDoLayout(self.LayoutRightTopContent)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

return UIOperationCenterRightTop