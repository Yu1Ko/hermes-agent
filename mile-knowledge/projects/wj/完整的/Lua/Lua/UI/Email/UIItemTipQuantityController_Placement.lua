-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipQuantityController_Placement
-- Date: 2022-11-30 19:44:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipQuantityController_Placement = class("UIItemTipQuantityController_Placement")

function UIItemTipQuantityController_Placement:OnEnter(nBox, nIndex, nCount, nCurCount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nBox = nBox
    self.nIndex = nIndex
    self.nCount = nCount or 1
    self.nCurCount = nCurCount or 1
    self.nImgSize = UIHelper.GetWidth(self.ImgBg)
    UIHelper.SetTouchDownHideTips(self.BtnConfirm, false)
    UIHelper.SetTouchDownHideTips(self.ButtonAdd, false)
    UIHelper.SetTouchDownHideTips(self.ButtonDecrease, false)
    UIHelper.SetTouchDownHideTips(self.SliderCount, false)
    self:UpdateInfo()
end

function UIItemTipQuantityController_Placement:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemTipQuantityController_Placement:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.fnCallback then
            self.fnCallback(self.nCurCount, self.nBox, self.nIndex)
        end
        Event.Dispatch(EventType.EmailBagItemSelected, self.nBox, self.nIndex, self.nCurCount)
    end)
    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function()
        if self.nCurCount == self.nCount then
            return
        end
        self.nCurCount = self.nCurCount + 1

        UIHelper.SetString(self.EditPaginate, tostring(self.nCurCount))
        UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
        UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
    end)
    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function()
        if self.nCurCount == 1 then
            return
        end
        self.nCurCount = self.nCurCount - 1

        UIHelper.SetString(self.EditPaginate, tostring(self.nCurCount))
        UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
        UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)

    end)
    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            self.nCurCount = math.ceil(self.nCurCount)
            UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
            UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
        end

        if self.bSliding then
            local percent = UIHelper.GetProgressBarPercent(self.SliderCount) / 100
            self.nCurCount = percent * self.nCount
            -- self.nCurCount = math.ceil(self.nCurCount)
            if self.nCurCount <= 1 then
                self.nCurCount = 1
            elseif self.nCurCount >= self.nCount then
                self.nCurCount = self.nCount
            end
            UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
            UIHelper.SetString(self.EditPaginate, tostring(math.ceil(self.nCurCount)))
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
        local nInput = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
        nInput = math.min(nInput, self.nCount)
        nInput = math.max(nInput, 1)
        self.nCurCount = nInput
        UIHelper.SetString(self.EditPaginate, nInput)
        UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
        UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
    end)
end

function UIItemTipQuantityController_Placement:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox ~= self.EditPaginate then return end
        UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginate, 1, self.nCount)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then return end

        local nInput = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
        nInput = math.min(nInput, self.nCount)
        nInput = math.max(nInput, 1)
        self.nCurCount = nInput
        UIHelper.SetString(self.EditPaginate, nInput)
        UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
        UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
    end)
end

function UIItemTipQuantityController_Placement:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIItemTipQuantityController_Placement:UpdateInfo()
    UIHelper.SetTouchDownHideTips(self.EditPaginate, false)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
    UIHelper.SetString(self.EditPaginate, self.nCurCount)
    UIHelper.SetProgressBarPercent(self.SliderCount, self.nCurCount * 100 / self.nCount)
    UIHelper.SetWidth(self.ImgFg, self.nCurCount * self.nImgSize / self.nCount)
end

function UIItemTipQuantityController_Placement:SetConfirmBtnText(szText)
    UIHelper.SetString(self.LabelConfirm, szText)
end

function UIItemTipQuantityController_Placement:SetCountTitleText(szText)
    UIHelper.SetString(self.LabelCountTittle, szText)
end

function UIItemTipQuantityController_Placement:SetCallback(fnCallback)
    self.fnCallback = fnCallback
end

return UIItemTipQuantityController_Placement