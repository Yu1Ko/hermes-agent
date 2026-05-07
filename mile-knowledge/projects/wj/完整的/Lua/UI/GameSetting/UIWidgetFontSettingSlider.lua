-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIWidgetFontSettingSlider
-- Date: 2024-07-16 11:29:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetFontSettingSlider = class("UIWidgetFontSettingSlider")

function UIWidgetFontSettingSlider:OnEnter(nCurCount, tbInfo, fnSlideEndCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nImgSize = UIHelper.GetWidth(self.ImgFg)
    self.nCurCount = nCurCount or 0
    self.tbInfo = tbInfo
    self.fnSlideEndCallback = fnSlideEndCallback
    self:UpdateInfo()
end

function UIWidgetFontSettingSlider:OnExit()
    self.bInit = false
end

function UIWidgetFontSettingSlider:BindUIEvent()
    UIHelper.SetNodeSwallowTouches(self.SliderCount, false)
    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        local fnCallback = self.tbInfo.fnCallback
        local nStep = self.tbInfo.nStep or 1

        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
            
            --if IsFunction(fnCallback) then
            --    fnCallback(self.tbInfo, self.nCurCount)
            --end
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            local fPerc = (self.nCurCount - self.nMinCount) / self.nTotalCount * 100
            UIHelper.SetProgressBarPercent(self.SliderCount, fPerc)
            fPerc = fPerc / 100.0
            
            self:UpdateSliderInfo(fPerc)

            if IsFunction(fnCallback) then
                fnCallback(self.tbInfo, self.nCurCount)
            end
        end

        if self.bSliding then
            local fPerc = UIHelper.GetProgressBarPercent(self.SliderCount) / 100
            local fMul = fPerc * self.nTotalCount / nStep
            if fMul - math.floor(fMul) < math.ceil(fMul) - fMul then
                fMul = math.floor(fMul)
            else
                fMul = math.ceil(fMul)
            end
            self.nCurCount = fMul * nStep + self.nMinCount
            if self.nCurCount <= self.nMinCount then
                self.nCurCount = self.nMinCount
            elseif self.nCurCount >= self.nMaxCount then
                self.nCurCount = self.nMaxCount
            end

            self:UpdateSliderInfo(fPerc)

            if IsFunction(fnCallback) then
                fnCallback(self.tbInfo, self.nCurCount)
            end
        end
    end)

    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function()
        local nStep = self.tbInfo.nStep or 1
        local fnCallback = self.tbInfo.fnCallback

        self.nCurCount = self.nCurCount + nStep
        if self.nCurCount <= self.nMinCount then
            self.nCurCount = self.nMinCount
        elseif self.nCurCount >= self.nMaxCount then
            self.nCurCount = self.nMaxCount
        end

        local fPerc = (self.nCurCount - self.nMinCount) / self.nTotalCount * 100
        UIHelper.SetProgressBarPercent(self.SliderCount, fPerc)
        fPerc = fPerc / 100.0

        self:UpdateSliderInfo(fPerc)

        if IsFunction(fnCallback) then
            fnCallback(self.tbInfo, self.nCurCount)
        end
    end)

    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function()
        local nStep = self.tbInfo.nStep or 1
        local fnCallback = self.tbInfo.fnCallback

        self.nCurCount = self.nCurCount - nStep
        if self.nCurCount <= self.nMinCount then
            self.nCurCount = self.nMinCount
        elseif self.nCurCount >= self.nMaxCount then
            self.nCurCount = self.nMaxCount
        end

        local fPerc = (self.nCurCount - self.nMinCount) / self.nTotalCount * 100
        UIHelper.SetProgressBarPercent(self.SliderCount, fPerc)
        fPerc = fPerc / 100.0

        self:UpdateSliderInfo(fPerc)

        if IsFunction(fnCallback) then
            fnCallback(self.tbInfo, self.nCurCount)
        end
    end)
end

function UIWidgetFontSettingSlider:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetFontSettingSlider:UpdateInfo()
    self.nMaxCount = self.tbInfo.nMax or 10
    self.nMinCount = self.tbInfo.nMin or 1
    self.nCurCount = math.max(self.nCurCount, self.nMinCount)
    self.nCurCount = math.min(self.nCurCount, self.nMaxCount)

    self.nTotalCount = self.nMaxCount - self.nMinCount

    UIHelper.SetString(self.LabelCountTittle, self.tbInfo.szTitle)
    UIHelper.LayoutDoLayout(self.LayoutCount)

    local fPerc = (self.nCurCount - self.nMinCount) / self.nTotalCount * 100
    UIHelper.SetProgressBarPercent(self.SliderCount, fPerc)
    self:UpdateSliderInfo(fPerc / 100.0)
end

function UIWidgetFontSettingSlider:UpdateSliderInfo(fPerc)
    UIHelper.SetScaleX(self.ImgFg, 1)
    UIHelper.SetWidth(self.ImgFg, fPerc * self.nImgSize)

    UIHelper.SetString(self.LabelCount, string.format("%d", self.nCurCount))
    UIHelper.LayoutDoLayout(self.LayoutCount)
end

function UIWidgetFontSettingSlider:SetCurCount(nCurCount)
    self.nCurCount = nCurCount
    self:UpdateInfo()
end

return UIWidgetFontSettingSlider