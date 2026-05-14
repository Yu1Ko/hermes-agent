-- ---------------------------------------------------------------------------------
-- Author: Liu yu min
-- Name: CrossingSelectReward
-- Date: 2023-03-21 16:46:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local CrossingSelectReward = class("CrossingSelectReward")
local CARD_TYPE = {
    FIRST = 1, --首通翻牌
    WEEK = 2,  --周翻牌
}

local ImageCardBackPath = 
{
    [1] = "UIAtlas2_TestPlace_TestPlace_Img_Card_Back_Bg.png",
    [2] = "UIAtlas2_TestPlace_TestPlace_Img_Card_Back_Bg2.png",
}

local ImageCardSelectPath = 
{
    [1] = "UIAtlas2_TestPlace_TestPlace_Img_Card_Front_Bg.png",
    [2] = "UIAtlas2_TestPlace_TestPlace_Img_Card_Front_Bg03.png",
}

function CrossingSelectReward:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function CrossingSelectReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    Event.Dispatch(EventType.HideAllHoverTips)
end

function CrossingSelectReward:BindUIEvent()

    -- UIHelper.BindUIEvent(self.BtnSwitchWeek, EventType.OnClick , function ()
    --     self:UpdateSwitchCard(CARD_TYPE.WEEK)
    -- end)
    
    -- UIHelper.BindUIEvent(self.BtnSwitchFrist, EventType.OnClick , function ()
    --     self:UpdateSwitchCard(CARD_TYPE.FIRST)
    -- end)

    UIHelper.BindUIEvent(self.BtnGoNext, EventType.OnClick , function ()
        --self:CloseReward()
        if CrossingData.tbResultInfo ~= nil then
            CrossingData.CallFinishedFunction()
        else
            UIMgr.Close(self)
        end

    end)

    -- local labelReStart = UIHelper.GetChildByName(self.BtnGoNext, "LabelReStart")
    -- UIHelper.SetString(labelReStart,"下一页")

    local btnMask = UIHelper.GetChildByName(UIHelper.GetParent(UIHelper.GetParent(self.BtnGoNext)), "btnMask")
    local tbScreenSize = UIHelper.DeviceScreenSize()
    UIHelper.SetContentSize(btnMask, tbScreenSize.width, tbScreenSize.height)

    if not CrossingData.tbResultInfo then
        UIHelper.BindUIEvent(btnMask, EventType.OnClick , function ()
            if self.bIsCloseMask then
                CrossingData.CloseFlopCard()
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnContinueFlip, EventType.OnClick, function()
        UIHelper.SetVisible(self.BtnContinueFlip, false)
        UIHelper.SetVisible(self.LabelContinueFlip, false)
        UIHelper.LayoutDoLayout(self.LayoutButton)
        RemoteCallToServer("On_Trial_RequestContinueFlop")
    end)
end

function CrossingSelectReward:RegEvent()
    Event.Reg(self, EventType.On_Activity_FlopCardReturn , function(tbData , nID)
        if nID ~= CrossingData.nFlopCardID then
            CrossingData.CloseFlopCard()
            return
        end
        if tbData then
            self:UpdateCardContent(tbData[1])
            local dataIndex = 2
            for k, card in pairs(self.tbCardList) do
                if k ~= CrossingData.nPreClickCardIndex then
                    local awardScript = UIHelper.GetBindScript(card)
                    if awardScript then
                        awardScript:UpdateCardAwardInfo(tbData[dataIndex] , true)
                        dataIndex = dataIndex + 1
                    end
                end
            end
        end
    end)
-- nWeekRemainCard = 0, --本周剩余周翻牌次数
-- bFirstPass = false, --本层是否还能领取首通奖励，true表示已经领过了，false表示还能领
-- nLevelRemainCard = 0, --本次通关是否已经翻过周翻牌，0表示没翻过，1表示翻过了
    Event.Reg(self, EventType.On_Trial_FlopCardReturn , function(tbData, nWeekRemainCard, bFirstPass, nLevelRemainCard)
        CrossingData.tbResultInfo.tbData.nWeekRemainCard = nWeekRemainCard
        CrossingData.tbResultInfo.tbData.bFirstPass = bFirstPass
        CrossingData.tbResultInfo.tbData.nLevelRemainCard = nLevelRemainCard
        if tbData then
            self:UpdateCardContent(tbData[1] , function ()
                if not self.bIsShowFinished then
                    CrossingData.CallFinishedFunction()
                end
            end)
            local dataIndex = 2
            for k, card in pairs(self.tbCardList) do
                if k ~= CrossingData.nPreClickCardIndex then
                    local awardScript = UIHelper.GetBindScript(card)
                    if awardScript then
                        awardScript:UpdateCardAwardInfo(tbData[dataIndex] , true)
                        dataIndex = dataIndex + 1
                    end
                end
            end
        end
        self:UpdateRestFlopCount()
        self:UpdateContinueFlipBtnStatus()
    end)

    Event.Reg(self, "On_Trial_ContinueFlopReturn", function()
        self:ResetToWaitFlop()
    end)
end

function CrossingSelectReward:UnRegEvent()
    Event.UnRegAll()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function CrossingSelectReward:UpdateInfo()
    self.bIsShowFinished = false
    self.bIsCloseMask = false
    self.bEnableFlop = true
    UIHelper.SetActiveAndCache(self, self.LabelHint, true)
    self:UpdateCardAwardInfo()
    UIHelper.SetActiveAndCache(self, self.LabelTime, not CrossingData.tbResultInfo)
    UIHelper.SetActiveAndCache(self, self.LabelTimeHint, not CrossingData.tbResultInfo)
    UIHelper.SetVisible(self.BtnContinueFlip, false)
    UIHelper.SetVisible(self.LabelContinueFlip, false)
    UIHelper.LayoutDoLayout(self.LayoutButton)
    local labelReStart = UIHelper.GetChildByName(self.BtnGoNext, "LabelReStart")

    if CrossingData.tbResultInfo then
        if not CrossingData.tbResultInfo.tbData.bFirstPass then
           self.nSelCardType = CARD_TYPE.FIRST
        else
           self.nSelCardType = CARD_TYPE.WEEK
        end
        self:UpdateRestFlopCount()
        self:UpdateSwitchCard(self.nSelCardType)
        UIHelper.SetString(labelReStart,"下一页")
    else
        UIHelper.SetVisible(self.BtnSwitchWeek, false)
        UIHelper.SetVisible(self.BtnSwitchFrist, false)  
        UIHelper.SetString(labelReStart,"继续挑战")
        
        UIHelper.SetString(self.LabelTitle, string.format("第%s层第%s关   翻牌奖励", UIHelper.NumberToChinese(CrossingData.nCurrentLevel), UIHelper.NumberToChinese(CrossingData.nCurrentMission)))   
        self:UpdateTimerInfo()
        UIHelper.SetString(self.LabelTimeHint, "后将跳过翻牌奖励自动进入下一关")
    end
end

function CrossingSelectReward:UpdateRestFlopCount()
    self.bGetFirstPassGift =  CrossingData.tbResultInfo.tbData.bFirstPass
    self.nWeekRemainCard = CrossingData.tbResultInfo.tbData.nWeekRemainCard or 0
    self.bGetWeekRewards = CrossingData.tbResultInfo.tbData.nLevelRemainCard and CrossingData.tbResultInfo.tbData.nLevelRemainCard == 1
    UIHelper.SetString(self.LabelFristCount , string.format(g_tStrings.STR_CROSSING_FIRST_FLOP, self.bGetFirstPassGift and 0 or 1) )
    UIHelper.SetString(self.LabelWeekCount , string.format("周翻牌剩余%d次",self.nWeekRemainCard) )
end

function CrossingSelectReward:UpdateSwitchCard(cardType)
    self.nSelCardType = cardType
    for k, v in pairs(self.tbImgCardSelect) do
        UIHelper.SetSpriteFrame(v, ImageCardSelectPath[cardType])
    end
    for k, v in pairs(self.tbImgCardBack) do
        UIHelper.SetSpriteFrame(v, ImageCardBackPath[cardType])
    end
    UIHelper.SetVisible(self.BtnSwitchWeek , true)--self.nSelCardType == CARD_TYPE.FIRST)
    UIHelper.SetVisible(self.BtnSwitchFrist , false)-- self.nSelCardType == CARD_TYPE.WEEK)
    local szCardName = self.nSelCardType == CARD_TYPE.WEEK and "周" or "首通"
    UIHelper.SetString(self.LabelTitle, string.format("第%s层  %s翻牌奖励", UIHelper.NumberToChinese(CrossingData.tbResultInfo.tbData.nLevel), szCardName))
    self:UpdateCardAwardInfo()
end


function CrossingSelectReward:UpdateCardAwardInfo()
    local _onSelectCallback = function(nIndex)
        if not self.bEnableFlop then
            return
        end
        CrossingData.nPreClickCardIndex = nIndex
        if CrossingData.tbResultInfo then
            if self.nSelCardType == CARD_TYPE.FIRST then
                if self.bGetFirstPassGift then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CROSSING_FIRST_FLOP_NOT_ENOUGH)
                    return
                end
            elseif self.nSelCardType == CARD_TYPE.WEEK then
                if not self.nWeekRemainCard or self.nWeekRemainCard < 1 then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_CROSSING_WEEK_FLOP_NOT_ENOUGH)
                    return
                end
            else
                return
            end
            self.bEnableFlop = false
            RemoteCallToServer("On_Trial_FlopCard",self.nSelCardType)
        else
            self.bEnableFlop = false
            RemoteCallToServer("On_Activity_FlopReturn", CrossingData.nFlopCardID)
        end
    end
    for index, value in ipairs(self.tbCardList) do
        local awardScript = UIHelper.GetBindScript(value)
        if awardScript then
            awardScript:OnEnter(index, _onSelectCallback)
        end
    end
end

function CrossingSelectReward:CloseReward()
    UIMgr.Close(VIEW_ID.PanelTestPlaceRewardSelect)
end

function CrossingSelectReward:UpdateTimerInfo()
    UIHelper.SetString(self.LabelTime, string.format("%d秒", CrossingData.nFlopCardTime))
    self.nTimerID = Timer.AddCountDown(self, CrossingData.nFlopCardTime, function(deltaTime)
        UIHelper.SetString(self.LabelTime, string.format("%d秒", deltaTime))
    end,
    function()
        self.bIsShowFinished = true
        CrossingData.CallFinishedFunction()
        if CrossingData.tbResultInfo == nil then
            self:CloseReward()
        end
    end)
end

function CrossingSelectReward:UpdateCardContent(tCardContentData , finishCallback)
    Timer.DelTimer(self, self.nTimerID)
    local awardScript = UIHelper.GetBindScript(self.tbCardList[CrossingData.nPreClickCardIndex])
    if awardScript then
        awardScript:UpdateCardAwardInfo(tCardContentData)
    end
    if not CrossingData.tbResultInfo then
        Timer.Add(self, 5, function ()
            if finishCallback then
                finishCallback()
            end
            CrossingData.CloseFlopCard()
        end)
        -- Timer.Add(self, 2, function ()
        --     UIHelper.SetActiveAndCache(self, self.LabelTimeHint, true)
        --     UIHelper.SetString(self.LabelTimeHint, "点击任意空白处关闭")
        --     self.bIsCloseMask = true
        -- end)
    end

    UIHelper.SetActiveAndCache(self, self.LabelHint, false)
    UIHelper.SetActiveAndCache(self, self.LabelTime, false)
    UIHelper.SetActiveAndCache(self, self.LabelTimeHint, false)
end

function CrossingSelectReward:UpdateContinueFlipBtnStatus()
    local bCanContinueFlop = false
    
    if CrossingData.tbResultInfo and CrossingData.tbResultInfo.tbData then
        local tbData = CrossingData.tbResultInfo.tbData
        bCanContinueFlop = (not tbData.bFirstPass) or (tbData.nWeekRemainCard and tbData.nWeekRemainCard > 0)
    end

    UIHelper.SetVisible(self.BtnContinueFlip, bCanContinueFlop)
    UIHelper.SetVisible(self.LabelContinueFlip, bCanContinueFlop)
    UIHelper.LayoutDoLayout(self.LayoutButton)
end

function CrossingSelectReward:ResetToWaitFlop()
    UIHelper.SetVisible(self.BtnContinueFlip, false)
    UIHelper.SetVisible(self.LabelContinueFlip, false)
    UIHelper.LayoutDoLayout(self.LayoutButton)
    if not CrossingData.tbResultInfo or not CrossingData.tbResultInfo.tbData then return end

    if not CrossingData.tbResultInfo.tbData.bFirstPass then
        self.nSelCardType = CARD_TYPE.FIRST
    else
        self.nSelCardType = CARD_TYPE.WEEK
    end

    CrossingData.nPreClickCardIndex = nil
    Timer.DelAllTimer(self)
    
    self.bIsShowFinished = false
    self.bIsCloseMask = false
    self.bEnableFlop = true
    
    UIHelper.SetActiveAndCache(self, self.LabelHint, true)
    
    self:UpdateRestFlopCount()
    self:UpdateSwitchCard(self.nSelCardType)
end

return CrossingSelectReward
