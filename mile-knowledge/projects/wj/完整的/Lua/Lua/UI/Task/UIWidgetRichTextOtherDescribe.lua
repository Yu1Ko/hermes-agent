-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetRichTextOtherDescribe
-- Date: 2023-02-24 14:30:46
-- Desc: ?
-- ---------------------------------------------------------------------------------
local function GetTimeToHourMinuteSecond(nTime, bFrame)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end
    local nHour = math.floor(nTime / 3600)
    nTime = nTime - nHour * 3600
    local nMinute = math.floor(nTime / 60)
    nTime = nTime - nMinute * 60
    local nSecond = math.floor(nTime)
    return nHour, nMinute, nSecond
end

local function GetszTime(szText, nTime)
    local h, m, s = GetTimeToHourMinuteSecond(nTime)
    local szTime = szText .. string.format("%02d：%02d", h*60 + m, s)
    return szTime
end

---@class UIWidgetRichTextOtherDescribe
local UIWidgetRichTextOtherDescribe = class("UIWidgetRichTextOtherDescribe")

function UIWidgetRichTextOtherDescribe:OnEnter(szText, nTime, nFontSize, bTimeStamp)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self._aniMgr = nil
        self._widgetMgr = nil
    end
    if szText then

        local szUseText = szText

        if IsNumber(nTime) then
            if bTimeStamp then
                nTime = nTime - GetCurrentTime()
            end
            szUseText = GetszTime(szText, nTime)
            Timer.DelAllTimer(self)
            if nTime > 0 then
                Timer.AddCountDown(self, nTime, function (nRemain)
                    szUseText = GetszTime(szText, nRemain)
                    self:UpdateInfo(szUseText)
                end, function ()
                    szUseText = GetszTime(szText, 0)
                    self:UpdateInfo(szUseText)
                end)
            end
        end

        self.nFontSize = nFontSize or 20
        self:UpdateInfo(szUseText)
    end
end

function UIWidgetRichTextOtherDescribe:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetRichTextOtherDescribe:BindUIEvent()

end

function UIWidgetRichTextOtherDescribe:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetRichTextOtherDescribe:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetRichTextOtherDescribe:UpdateInfo(szText)
    UIHelper.SetFontSize(self._rootNode, self.nFontSize)
    UIHelper.SetRichText(self._rootNode, szText)
end

function UIWidgetRichTextOtherDescribe:SetFontSize(nFontSize)
    UIHelper.SetFontSize(self._rootNode, nFontSize)
end

return UIWidgetRichTextOtherDescribe