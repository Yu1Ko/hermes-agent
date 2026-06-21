-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMainCityTimelyMessagesBtn
-- Date: 2023-03-20 11:25:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMainCityTimelyMessagesBtn = class("UIMainCityTimelyMessagesBtn")

function UIMainCityTimelyMessagesBtn:OnEnter(nType)
    self.nType = nType
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIMainCityTimelyMessagesBtn:OnExit()
    self.bInit = false
end

function UIMainCityTimelyMessagesBtn:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMessage, EventType.OnClick, function ()
        if not self.nType then
            return
        end
        TimelyMessagesBtnData.OnClickBtn(self.nType)
    end)
end

function UIMainCityTimelyMessagesBtn:RegEvent()
    Event.Reg(self, EventType.OnUpdateMessageBtnInfo, function (nType)
        if nType ~= self.nType then
            return
        end

        self:UpdateInfo()
    end)

end

function UIMainCityTimelyMessagesBtn:UpdateInfo()
    if not self.nType then
        UIHelper.SetVisible(self._rootNode, false)
        return
    end

    local tbInfos = TimelyMessagesBtnData.GetBtnInfos(self.nType)
    UIHelper.SetVisible(self._rootNode, #tbInfos > 0)

    UIHelper.SetString(self.LabelMessageCount, #tbInfos)

    if self.nCountDownTimerID then
        Timer.DelTimer(self, self.nCountDownTimerID)
        self.nCountDownTimerID = nil
    end

    if #tbInfos > 0 then
        local nLeftTime, nTotalTime = self:GetLeftTime()
        UIHelper.SetProgressBarPercent(self.SilderTime, nLeftTime / nTotalTime)
        self.nCountDownTimerID = Timer.AddFrameCycle(self, 1, function ()
            nLeftTime, nTotalTime = self:GetLeftTime()
            UIHelper.SetProgressBarPercent(self.SilderTime, nLeftTime / nTotalTime * 100)
        end)
    end
end

function UIMainCityTimelyMessagesBtn:GetLeftTime()
    local nLeftTime = 0
    local nTotalTime = 0

    local tbInfos = TimelyMessagesBtnData.GetBtnInfos(self.nType)
    for i, tbInfo in ipairs(tbInfos) do
        local nTempLeftTime = (tbInfo.nTotalTime - (GetTickCount() - tbInfo.nTimestamp) / 1000)
        if nTempLeftTime > nLeftTime then
            nLeftTime = nTempLeftTime
            nTotalTime = tbInfo.nTotalTime
        end
    end

    return nLeftTime, nTotalTime
end


return UIMainCityTimelyMessagesBtn