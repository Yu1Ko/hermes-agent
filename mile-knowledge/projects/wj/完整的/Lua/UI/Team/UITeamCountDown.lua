-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamCountDown
-- Date: 2024-12-30 15:04:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamCountDown = class("UITeamCountDown")

local MAX = 10
local MIN = 1

function UITeamCountDown:OnEnter(nNum, fnOk)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nNum = nNum
    self.fnOk = fnOk
    self:UpdateInfo()
end

function UITeamCountDown:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamCountDown:BindUIEvent()
    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
            local szNum = UIHelper.GetString(self.EditPaginate)
            local nNum = tonumber(szNum) or 1
            self.nNum = nNum
            self:UpdateInfo()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function ()
            local szNum = UIHelper.GetString(self.EditPaginate)
            local nNum = tonumber(szNum) or 1
            self.nNum = nNum
            self:UpdateInfo()
        end)

        Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
            if editbox ~= self.EditPaginate then return end
            UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginate, MIN, MAX)
        end)

        Event.Reg(self, EventType.OnGameNumKeyboardChanged, function (editBox, nCurNum)
            if editBox ~= self.EditPaginate then return end
            local szNum = UIHelper.GetString(self.EditPaginate)
            local nNum = tonumber(szNum) or 1
            self.nNum = nNum
            self:UpdateInfo()
        end)
    end

    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function()
        self.nNum = self.nNum + 1
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function()
        self.nNum = self.nNum - 1
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            self:UpdateInfo()
        end

        if self.bSliding then
            local nProgress = UIHelper.GetProgressBarPercent(self.SliderCount)
            UIHelper.SetWidth(self.ImgFg, UIHelper.GetWidth(self.ImgBg)*nProgress/100.0)
            self.nNum = (MAX - MIN) * nProgress / 100.0 + MIN
            self:UpdateNumber()
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.fnOk then
            self.fnOk(self.nNum)
        end
        UIMgr.Close(self)
    end)
end

function UITeamCountDown:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamCountDown:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamCountDown:UpdateInfo()
    self:UpdateNumber()
    self:UpdateProgress()
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UITeamCountDown:UpdateNumber()
    self.nNum = math.floor(self.nNum + 0.499)
    self.nNum = math.max(math.min(self.nNum, 10), 0)
    UIHelper.SetString(self.EditPaginate, self.nNum)
end

function UITeamCountDown:UpdateProgress()
    local nProgress = (self.nNum - MIN) * 1.0 / (MAX - MIN) * 100.0
    UIHelper.SetProgressBarPercent(self.SliderCount, nProgress)
    UIHelper.SetWidth(self.ImgFg, UIHelper.GetWidth(self.ImgBg)*nProgress/100.0)
end

return UITeamCountDown