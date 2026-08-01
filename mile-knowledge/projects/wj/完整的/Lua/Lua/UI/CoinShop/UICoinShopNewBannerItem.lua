-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopNewBannerItem
-- Date: 2023-03-22 11:18:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopNewBannerItem = class("UICoinShopNewBannerItem")

local COUNT_DOWN_MOVIE_TIME = 5000
local COUNT_DOWN_NEXT_TIME = 5000

function UICoinShopNewBannerItem:OnEnter(tbInfo, nIndex, fnVideo, fnNext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self.nIndex = nIndex
    self.fnVideo = fnVideo
    self.fnNext = fnNext
    self:UpdateInfo()
end

function UICoinShopNewBannerItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UICoinShopNewBannerItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBannerCell, EventType.OnClick, function ()
        Event.Dispatch("EVENT_LINK_NOTIFY", self.tbInfo.szLink)
        UIMgr.Close(VIEW_ID.PanelActivityBanner)
    end)
end

function UICoinShopNewBannerItem:RegEvent()
end

function UICoinShopNewBannerItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopNewBannerItem:UpdateInfo()
    local szBgPath = self.tbInfo.szBgPath
    if szBgPath then
        szBgPath = string.gsub(szBgPath, "ui\\Image", "Resource")
        szBgPath = string.gsub(szBgPath, "ui/Image", "Resource")
        szBgPath = string.gsub(szBgPath, ".tga", ".png")
        UIHelper.SetTexture(self.ImgBanner, szBgPath)
    end
    local szLinkEvent, szLinkArg = self.tbInfo.szLink:match("(%w+)/(.*)")
    local nType, dwID = CoinShopData.ExtractLink(szLinkArg)
    if nType == HOME_TYPE.REWARDS then
        local tbVideoList = CoinShop_GetAllLimitVideo(dwID)
        if tbVideoList and #tbVideoList > 0 then
            self.szUrl = MovieMgr.ParseStaticUrl(tbVideoList[1].szUrl , true)
        end
    end
    UIHelper.SetActiveAndCache(self, self.WidgetTipBG, false)
end

function UICoinShopNewBannerItem:OnFocus(nCurIndex)
    self.bFocus = self.nIndex == nCurIndex
    if not self.bFocus then
        self:CancelCountdown()
        return
    end

    self:CancelCountdown()
    self.nStartTime = GetTickCount()
    self:Countdown()
    self.nTimer = Timer.AddCycle(self, 0.2, function ()
        self:Countdown()
    end)
end

function UICoinShopNewBannerItem:Countdown()
    local nDelta = GetTickCount() - self.nStartTime
    if not self.szUrl then
        UIHelper.SetActiveAndCache(self, self.WidgetTipBG, false)
        if COUNT_DOWN_NEXT_TIME - nDelta <= 0 then
            self:CancelCountdown()
            self.fnNext()
        end
        return
    end

    UIHelper.SetActiveAndCache(self, self.WidgetTipBG, true)
    UIHelper.SetString(self.LabelTip, string.format("%d秒后自动播放视频", math.ceil((COUNT_DOWN_MOVIE_TIME-nDelta) / 1000)))
    if COUNT_DOWN_MOVIE_TIME - nDelta <= 0 then
        self:CancelCountdown()
        self.fnVideo(self.szUrl)
    end
end

function UICoinShopNewBannerItem:CancelCountdown()
    Timer.DelTimer(self, self.nTimer)
    UIHelper.SetActiveAndCache(self, self.WidgetTipBG, false)
end

return UICoinShopNewBannerItem