-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHuaELouView
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- Prefab: PanelHuaELou
-- ---------------------------------------------------------------------------------

---@class UIHuaELouView
local UIHuaELouView = class("UIHuaELouView")

local GONGZHAN_BUFF = 3219
local EX_PLAYER_RETURN = 403
local SIGN_IN_ID = 16
local szBattlePassRule = "<text>text=\"1.每赛季历练等级重置，奖励更新。本赛季的奖励只能在本赛季结束之前领取，未在本赛季领取的奖励将在赛季结束时失效、无法领取，也无法累计到下一赛季，建议及时领取奖励。 \n2.活动期间，通过完成任务面板内玩法获得历练值，每满1000可提升一级历练等级，历练等级不会超过本周历练等级上限。\n3.每赛季有60级的奖励。升级后可领取对应等级奖励。\n4.每级的奖励分江湖档和豪侠档，豪侠档的奖励需要消耗通宝来解锁。解锁后可领取该档奖励。\n5.同账号内不同角色的江湖行记互不影响。\" font=162</text>"

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIHuaELouView:_LuaBindList()
    -- 制作人的一封信
    self.WidgetPlayerLetter      = self.WidgetPlayerLetter --- 上层组件
    self.BtnPlayerLetter         = self.BtnPlayerLetter --- 按钮
    self.ImgRedPointPlayerLetter = self.ImgRedPointPlayerLetter --- 红点图片

    -- 帮会联赛竞猜
    self.WidgetGuessing          = self.WidgetGuessing --- 上层组件
    self.BtnGuessing             = self.BtnGuessing --- 按钮
    self.ImgRedPointGuessing     = self.ImgRedPointGuessing --- 红点图片

    self.LayoutRightTopContent   = self.LayoutRightTopContent --- 右上角按钮区域的layout

    -- 天选系列外观票选
    self.WidgetAnchorTianXuan    = self.WidgetAnchorTianXuan --- 上层组件
    self.BtnTianXuan             = self.BtnTianXuan --- 按钮
    self.ImgRedPointTianXuan     = self.ImgRedPointTianXuan --- 红点图片

    -- 同人外装评选
    self.WidgetAnchorWaizhuang   = self.WidgetAnchorWaizhuang --- 上层组件
    self.BtnWaizhuang            = self.BtnWaizhuang --- 按钮
    self.ImgRedPointWaizhuang    = self.ImgRedPointWaizhuang --- 红点图片

    -- 特效
    self.WidgetAnchorEffect      = self.WidgetAnchorEffect --- 上层组件
    self.BtnEffect               = self.BtnEffect --- 按钮
    self.ImgRedPointEffect       = self.ImgRedPointEffect --- 红点图片

    -- 同人武器评选
    self.WidgetAnchorWuqi        = self.WidgetAnchorWuqi --- 上层组件
    self.BtnWuqi                 = self.BtnWuqi --- 按钮
    self.ImgRedPointWuqi         = self.ImgRedPointWuqi --- 红点图片
end

function UIHuaELouView:OnEnter(nCurAvtiveID)
    if CheckPlayerIsRemote(nil, g_tStrings.STR_REMOTE_NOT_TIP1) then
        return
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        UIMgr.Open(VIEW_ID.PanelUID)
        self.bInit = true
    end

    self.nCurAvtiveID = nCurAvtiveID or SIGN_IN_ID
    self.nCurAvtiveIndex = 1
    self.nSelAvtiveIndex = 0
    self.tbNavList = {}
    self.bWidgetArrow = true

    self:InitHuaELouActivityTab()
    self:UpdateInfo()
    self:UpdateNavRedpoint()
    HuaELouData.GetAllCheckActive()
    self:UpdateJJCBtnBright()
    Timer.AddCycle(self,1,function ()
        self:UpdateJJCBtnBright()
    end)

    Global.SetShowRewardListEnable(VIEW_ID.PanelHuaELou, true)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelHuaELou, false)
end

function UIHuaELouView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    Global.SetShowRewardListEnable(VIEW_ID.PanelHuaELou, false)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelHuaELou, true)
    Global.RemovetBlackListForShowRewardList("PanelHuaELou")
    UIMgr.Close(VIEW_ID.PanelUID)
end

function UIHuaELouView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPurchase,EventType.OnClick,function ()
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
    end)

    UIHelper.BindUIEvent(self.BtnHotSpot,EventType.OnClick,function ()
        UIMgr.Open(VIEW_ID.PanelHotSpotBanner)
    end)

    UIHelper.BindUIEvent(self.BtnDetail,EventType.OnClick,function ()
        local tActivity = self.tbHuaELouActivityTab[self.nCurAvtiveIndex]
        if tActivity then
            local szTitle = Table_GetOperActyTitle(tActivity.dwOperatActID)
            UIMgr.Open(VIEW_ID.PanelHuaELouHelpPop, tActivity.dwOperatActID, UIHelper.GBKToUTF8(szTitle), self.szActivityExplain)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick,function ()
        local tActivity = self.tbHuaELouActivityTab[self.nCurAvtiveIndex]
        if tActivity then
            local tLine = Table_GetOperActyInfo(tActivity.dwOperatActID) or {}
            local szName = UIHelper.GBKToUTF8(tLine.szName)
            local szLinkInfo = string.format("OperationActivity/%d", tActivity.dwOperatActID)
            ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
        end
    end)

    UIHelper.BindUIEvent(self.BtnQuestionnaire, EventType.OnClick, function()
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

    UIHelper.BindUIEvent(self.BtnGuessing, EventType.OnClick, function()
        BattleFieldData.OpenTongWarGuessing()
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

    UIHelper.BindUIEvent(self.ScrollViewToggle, EventType.OnTouchEnded, function()
        local nPercent = UIHelper.GetScrollPercent(self.ScrollViewToggle)
        if nPercent >= 100 then
            self.bWidgetArrow = false
            UIHelper.SetVisible(self.WidgetArrow, self.bWidgetArrow)
            UIHelper.UnBindUIEvent(self.ScrollViewToggle, EventType.OnTouchEnded)
        end
    end)

    UIHelper.BindUIEvent(self.ScrollViewToggle, EventType.OnScrollingScrollView, function (_, eventType)
        if eventType == ccui.ScrollviewEventType.containerMoved then
            self:UpdateWidgetArrow()
            self:UpdateRedPointArrow()
        end
    end)

end

function UIHuaELouView:RegEvent()
    Event.Reg(self, EventType.OnQuestionnaireInfoChanged, function()
        self:UpdateQuestionnaireInfo()
    end)

    Event.Reg(self, EventType.OnDoSomething, function(szKey)
        if szKey == HuaELouData.szDidKeyTongWarGuessing then
            --- 在帮会联赛匹配界面点竞猜按钮时，也要刷新这边的红点
            UIHelper.SetVisible(self.ImgRedPointGuessing, HuaELouData.GetTongWarGuessingRedPoint() and not AppReviewMgr.IsReview())
        end
    end)

    Event.Reg(self, "DO_SKILL_PREPARE_PROGRESS", function(arg0, arg1, arg2, arg3, arg4)
        local skillName = Table_GetSkillName(arg1, arg2)
        skillName = UIHelper.GBKToUTF8(skillName)

        if skillName == "神行千里" then
            UIMgr.Close(self)
        end
    end)

    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function()
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelSystemMenu)
    end)

    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if UIMgr.GetLayerTopViewID(UILayer.Page) ~= VIEW_ID.PanelHuaELou then
            return
        end

        APIHelper.HandleRichTextLink(szUrl, node)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        UIHelper.LayoutDoLayout(self.LayoutRightTopContent)
        UIHelper.ScrollViewDoLayout(self.ScrollViewToggle)
        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollToIndex(self.ScrollViewToggle, self.nCurAvtiveIndex -1 )
            self:UpdateWidgetArrow()
            self:UpdateRedPointArrow()
        end)
    end)

    Event.Reg(self, EventType.OnWindowsMouseWheel, function()
        local nPercent = UIHelper.GetScrollPercent(self.ScrollViewToggle)
        if nPercent >= 100 then
            self.bWidgetArrow = false
            UIHelper.SetVisible(self.WidgetArrow, self.bWidgetArrow)
            Event.UnReg(self, EventType.OnWindowsMouseWheel)
        end
    end)
end

function UIHuaELouView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHuaELouView:InitHuaELouActivityTab()
    local tbHuaELouActivityTab = clone(UIHuaELouActivityTab) or {}
    self.tbHuaELouActivityTab = {}
    for _, tActivity in ipairs(tbHuaELouActivityTab) do
        local bShow = HuaELouData.CheackActivityOpen(tActivity.dwOperatActID, tActivity.nID)
        local tLine = Table_GetOperActyInfo(tActivity.dwOperatActID)
        if bShow and tLine then
            table.insert(self.tbHuaELouActivityTab, tActivity)
        end
    end

    table.sort(self.tbHuaELouActivityTab,function (left,right)
        if left.nPriority == right.nPriority then
            return left.nID > right.nID
        end
        return left.nPriority < right.nPriority
    end)
end

function UIHuaELouView:UpdateInfo()
    UIHelper.AddPrefab(PREFAB_ID.WidgetArrow, self.WidgetArrow)

    UIHelper.RemoveAllChildren(self.ScrollViewToggle)
    for nNavIndex, tActivity in ipairs(self.tbHuaELouActivityTab) do
        local nPrefabID = PREFAB_ID[tActivity.szPrefab]
        if self.nCurAvtiveID and tActivity.dwOperatActID == self.nCurAvtiveID then
            self.nCurAvtiveIndex = nNavIndex
        end

        tActivity.nPrefabID = nPrefabID or 0
        local tLine = Table_GetOperActyInfo(tActivity.dwOperatActID) or {}
        local scriptToggle = UIHelper.AddPrefab(PREFAB_ID.WidgetHuaELouNavigation, self.ScrollViewToggle, UIHelper.GBKToUTF8(tLine.szName), nil, tActivity.nRedPointID)
        if scriptToggle then
            UIHelper.SetName(scriptToggle._rootNode, "WidgetHuaELouNavigation"..nNavIndex)

            UIHelper.BindUIEvent(scriptToggle.ToggleNavigation,EventType.OnSelectChanged,function (_, bSelected)
                if bSelected and self.nSelAvtiveIndex ~= nNavIndex then
                    UIHelper.RemoveAllChildren(self.WidgetAnchorRight)
                    UIHelper.AddPrefab(tActivity.nPrefabID, self.WidgetAnchorRight, tActivity.dwOperatActID, tActivity.nID)
                    self.nSelAvtiveIndex = nNavIndex
                    self.nCurAvtiveIndex = self.nSelAvtiveIndex

                    self:UpdateDetailedInfo(tActivity.dwOperatActID)
                    self:SetRwardBlackList(tActivity.dwOperatActID)

                    local szKey = tLine.szActivityExplain
                    if tActivity.dwOperatActID == OPERACT_ID.CHARGE_MONTHLY then
                        local tChongXiaoMon, nMaxIssue = Table_GetChongXiaoMonthly()
                        table.sort(tChongXiaoMon, function(tLeft, tRight)
                            return tLeft[1].nEndTime < tRight[1].nStartTime
                        end)

                        local _, tCurPageInfos = HuaELouData.GetDisplayPageInfo(tChongXiaoMon, nMaxIssue)
                        szKey = tCurPageInfos[1].szTitle
                    end
                    if tActivity.dwOperatActID == OPERACT_ID.NEW_YEAR then
                        APIHelper.DoToday(szKey)
                    else
                        if not APIHelper.IsDid(szKey) then
                            APIHelper.Do(szKey)
                        end
                    end

                    UIHelper.SetVisible(scriptToggle.ImgRedPointNew, false)
                    Event.Dispatch(EventType.OnUpdateHuaELouRedPoint)
                end
            end)
            table.insert(self.tbNavList,scriptToggle)
        end
    end

    local nImgCount = HotSpotData.GetImageCountByPopID(HotSpotData.GetDefaultPopID()) or 0

    UIHelper.SetVisible(UIHelper.GetParent(self.BtnHotSpot), nImgCount >= 1 and g_pClientPlayer.nLevel >= 106)
    UIHelper.ScrollViewDoLayout(self.ScrollViewToggle)
    UIHelper.SetSelected(self.tbNavList[self.nCurAvtiveIndex].ToggleNavigation,true)
    Timer.AddFrame(self, 1, function ()
        UIHelper.ScrollToIndex(self.ScrollViewToggle, self.nCurAvtiveIndex -1 )
    end)

    self:UpdateQuestionnaireInfo()
    self:UpdateWidgetArrow()
    self:UpdateRedPointArrow()

    UIHelper.SetVisible(self.WidgetPlayerLetter, WebUrl.CanShow(WEBURL_ID.PRODUCER_LETTER) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointPlayerLetter, HuaELouData.GetProducerLetterRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorTicket, WebUrl.CanShow(WEBURL_ID.TICKETS_PURCHASE_ELIGIBILITY) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointTicket, HuaELouData.GetTicketRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchor15Anni, WebUrl.CanShow(WEBURL_ID.FIFTEEN_Anni_LIVE_STREAMING) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPoint15Anni, HuaELouData.Get15AnniRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetGuessing, WebUrl.CanShow(WEBURL_ID.TONG_WAR_GUESSING) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointGuessing, HuaELouData.GetTongWarGuessingRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorBaoming, WebUrl.CanShow(WEBURL_ID.COMPETITIVE_MATCH) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgBaoMingRedPoint, HuaELouData.GetCompetitiveMatch2025RedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorJingcaiQunying, WebUrl.CanShow(WEBURL_ID.COMPETITIVE_MATCH_GUESS) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgJingCaiRedPoint, HuaELouData.GetCompetitiveMatchGuess2025RedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorTianXuan, WebUrl.CanShow(WEBURL_ID.TIAN_XUAN_VOTE) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointTianXuan, HuaELouData.GetTianXuanRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorWaizhuang, WebUrl.CanShow(WEBURL_ID.TONG_REN_EXTERIOR) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointWaizhuang, HuaELouData.GetTongRenExteriorRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorEffect, WebUrl.CanShow(WEBURL_ID.WEB_EFFECT) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointEffect, HuaELouData.GetEffectDailyRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.SetVisible(self.WidgetAnchorWuqi, WebUrl.CanShow(WEBURL_ID.TONG_REN_WEAPON) and not AppReviewMgr.IsReview())
    UIHelper.SetVisible(self.ImgRedPointWuqi, HuaELouData.GetTongRenWeaponRedPoint() and not AppReviewMgr.IsReview())

    UIHelper.LayoutDoLayout(self.LayoutRightTopContent)
end

function UIHuaELouView:UpdateWidgetArrow()
    local nHeight = UIHelper.GetHeight(self.ScrollViewToggle)
    local _nWorldY = UIHelper.GetPositionY(self.tbNavList[1]._rootNode)
    local bHasRedPointBelow, bHasRedPointTop = self:HasRedPointBelow()

    UIHelper.SetVisible(self.WidgetArrow, _nWorldY > nHeight and self.bWidgetArrow and not bHasRedPointBelow)
end

function UIHuaELouView:UpdateRedPointArrow()
    local bHasRedPointBelow, bHasRedPointTop = self:HasRedPointBelow()
    UIHelper.SetVisible(self.ImgRedPointArrowBottom, bHasRedPointBelow)
    UIHelper.SetVisible(self.ImgRedPointArrowTop, bHasRedPointTop)
end

function UIHuaELouView:HasRedPointBelow()
    local bHasRedPointBelow = false
    local bHasRedPointTop = false
    local nRedPointCount = 0

    if not self.nScrollViewY then
        local nWorldX, nWorldY = UIHelper.ConvertToWorldSpace(self.ScrollViewToggle, 0, 0)
        self.nScrollViewY = nWorldY
    end

    for k, v in ipairs(self.tbNavList) do
        if UIHelper.GetVisible(v.ImgRedPoint) or UIHelper.GetVisible(v.ImgRedPointNew) then
            local nHeight = UIHelper.GetHeight(v.ImgRedPoint)
            local _nWorldX, _nWorldY = UIHelper.ConvertToWorldSpace(v.ImgRedPoint, 0, nHeight)
            if _nWorldY < self.nScrollViewY then
                bHasRedPointBelow = true
                -- nRedPointCount = nRedPointCount + 1
                -- if nRedPointCount == 99 then
                    break
                -- end
            elseif _nWorldY > self.nScrollViewY + UIHelper.GetHeight(self.ScrollViewToggle) then
                bHasRedPointTop = true
            end
        end
    end
    return bHasRedPointBelow, bHasRedPointTop
end

function UIHuaELouView:UpdateNavRedpoint()
    for nNavIndex, tActivity in ipairs(self.tbHuaELouActivityTab) do
        local tLine = Table_GetOperActyInfo(tActivity.dwOperatActID) assert(tLine)
        local szKey = tLine.szActivityExplain
        if tActivity.nRedPointID ~= 0 then
            local szActionFunc = "RedpoingConditions.Excute_"..tostring(tActivity.nRedPointID).."()"
            local bResult = string.execute(szActionFunc) or false
            if not bResult then
                if tActivity.dwOperatActID == OPERACT_ID.CHARGE_MONTHLY then
                    local tChongXiaoMon, nMaxIssue = Table_GetChongXiaoMonthly()
                    table.sort(tChongXiaoMon, function(tLeft, tRight)
                        return tLeft[1].nEndTime < tRight[1].nStartTime
                    end)

                    local _, tCurPageInfos = HuaELouData.GetDisplayPageInfo(tChongXiaoMon, nMaxIssue)
                    szKey = tCurPageInfos[1].szTitle
                end
                bResult = not APIHelper.IsDid(szKey)
                UIHelper.SetVisible(self.tbNavList[nNavIndex].ImgRedPointNew, bResult)
            end
        else
            local bResult
            if tActivity.dwOperatActID == OPERACT_ID.NEW_YEAR then
                bResult = not APIHelper.IsDidToday(szKey)
            else
                bResult= not APIHelper.IsDid(szKey)
            end

            UIHelper.SetVisible(self.tbNavList[nNavIndex].ImgRedPointNew, bResult)
        end
    end
end

function UIHuaELouView:UpdateQuestionnaireInfo()
    UIHelper.SetVisible(self.WidgetAnchorQA,  QuestionnaireData.bHasNew and not AppReviewMgr.IsReview())
    UIHelper.LayoutDoLayout(self.LayoutRightTopContent)
end

function UIHuaELouView:SetRwardBlackList(dwOperatActID)
    if dwOperatActID == OPERACT_ID.DAILY_SIGN then
        Global.AddtBlackListForShowRewardList("PanelHuaELou")
    else
        Global.RemovetBlackListForShowRewardList("PanelHuaELou")
    end
end


function UIHuaELouView:UpdateDetailedInfo(dwOperatActID)
    local tLine = Table_GetOperActyInfo(dwOperatActID)

    if tLine and dwOperatActID > 0 then
        UIHelper.SetVisible(self.WidgetAnchorSubTitle, tLine.szTitle and true or false)
        if tLine.szTitle then
            UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
        end
        UIHelper.SetVisible(self.BtnDetail, tLine.szActivityExplain ~= "" and true or false)
        self.szActivityExplain = tLine.szActivityExplain
    elseif dwOperatActID == 0 then -- 目前只有江湖行记没有活动ID
        self.szActivityExplain = UIHelper.UTF8ToGBK(szBattlePassRule)
        UIHelper.SetVisible(self.WidgetAnchorSubTitle, true)
        UIHelper.SetString(self.LabelNormalName1, "江湖行记")
        UIHelper.SetVisible(self.BtnDetail, true)
    end

    UIHelper.SetVisible(self.BtnSendToChat, dwOperatActID > 0)
    Timer.AddFrame(self, 1, function ()
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutContent, true, true)
    end)
end

function UIHuaELouView:UpdateJJCBtnBright()
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

return UIHuaELouView