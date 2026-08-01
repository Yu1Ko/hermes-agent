-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBuildFaceAdjustCell
-- Date: 2023-09-11 11:29:41
-- Desc: ?
-- ---------------------------------------------------------------------------------
local PageType = {
    ["Face"]        = 1,
    ["Makeup"]      = 2,
    ["Hair"]        = 3,
    ["Body"]        = 4,
    ["Prefab"]      = 5,
    ["FaceOld"]     = 6,
    ["MakeupOld"]   = 7,
    ["CustomPendant"] = 8,
    ["HairDye"]     = 9,
}

local UIBuildFaceAdjustCell = class("UIBuildFaceAdjustCell")

function UIBuildFaceAdjustCell:OnEnter(nPageIndex, tbInfo, nCurCount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.nImgSize = 250
    end

    self.nPageIndex = nPageIndex
    self.nCurCount = nCurCount or 0
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIBuildFaceAdjustCell:OnExit()
    self.bInit = false
end

function UIBuildFaceAdjustCell:BindUIEvent()
    UIHelper.SetNodeSwallowTouches(self.SliderCount, false)
    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        local fnCallback = self.tbInfo.fnCallback
        local nStep = self.tbInfo.nStep or 1

        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true

            if IsFunction(fnCallback) then
                fnCallback(self.tbInfo, self.nCurCount)
            else
                Event.Dispatch(EventType.OnChangeBuildFaceAttribSliderValueBegin, self.tbInfo, self.nCurCount)
            end
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            local fPerc = (self.nCurCount - self.nMinCount) / self.nTotalCount * 100
            UIHelper.SetProgressBarPercent(self.SliderCount, fPerc)
            fPerc = fPerc / 100.0

            self:UpdateSliderInfo(fPerc)

            if IsFunction(fnCallback) then
                fnCallback(self.tbInfo, self.nCurCount)
            else
                Event.Dispatch(EventType.OnChangeBuildFaceAttribSliderValue, self.tbInfo, self.nCurCount)
                Event.Dispatch(EventType.OnChangeBuildFaceAttribSliderValueEnd, self.tbInfo, self.nCurCount)
            end
        end

        if self.bSliding then
            local fPerc = UIHelper.GetProgressBarPercent(self.SliderCount)/100
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
            else
                Event.Dispatch(EventType.OnChangeBuildFaceAttribSliderValue, self.tbInfo, self.nCurCount)
            end
        end
    end)

    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function ()
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
        else
            Event.Dispatch(EventType.OnChangeBuildFaceAttribSliderValue, self.tbInfo, self.nCurCount)
        end
    end)

    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function ()
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
        else
            Event.Dispatch(EventType.OnChangeBuildFaceAttribSliderValue, self.tbInfo, self.nCurCount)
        end
    end)
end

function UIBuildFaceAdjustCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBuildFaceAdjustCell:UpdateInfo()
    if self.nPageIndex == PageType.Face then
        self:UpdateFaceInfo()
    elseif self.nPageIndex == PageType.Makeup then
        self:UpdateMakeupInfo()
    elseif self.nPageIndex == PageType.FaceOld then
        self:UpdateOldFaceInfo()
    elseif self.nPageIndex == PageType.MakeupOld then
        self:UpdateOldMakeupInfo()
    elseif self.nPageIndex == PageType.Body then
        self:UpdateBodyInfo()
    else
        self:UpdateCustomInfo()
    end

    self.nMaxCount = self.tbBoneInfo.nValueMax
    self.nMinCount = self.tbBoneInfo.nValueMin
    self.nCurCount = math.max(self.nCurCount, self.nMinCount)
    self.nCurCount = math.min(self.nCurCount, self.nMaxCount)
    self.nTotalCount = self.tbBoneInfo.nValueMax - self.tbBoneInfo.nValueMin
    UIHelper.SetString(self.LabelCountTittle, UIHelper.GBKToUTF8(self.tbInfo.szBoneName or self.tbInfo.szBodyName or self.tbInfo.szName or self.tbInfo[2]))
    UIHelper.LayoutDoLayout(self.LayoutCount)

    local fPerc = (self.nCurCount - self.nMinCount) / self.nTotalCount * 100
    UIHelper.SetProgressBarPercent(self.SliderCount, fPerc)
    self:UpdateSliderInfo(fPerc / 100.0)
end

function UIBuildFaceAdjustCell:UpdateFaceInfo()
    local tbBoneInfo = BuildFaceData.GetAllBoneInfo()
    self.tbBoneInfo = tbBoneInfo[self.tbInfo.nBoneType]
end

function UIBuildFaceAdjustCell:UpdateMakeupInfo()
    self.tbBoneInfo = {
        nValueMin = self.tbInfo.nValueMin,
        nValueMax = self.tbInfo.nValueMax,
    }
end

function UIBuildFaceAdjustCell:UpdateOldFaceInfo()
    local tbBoneInfo = BuildFaceData.GetOldAllBoneInfo()
    self.tbBoneInfo = tbBoneInfo[self.tbInfo[1]]
end

function UIBuildFaceAdjustCell:UpdateOldMakeupInfo()
    self.tbBoneInfo = {
        nValueMin = self.tbInfo.nValueMin,
        nValueMax = self.tbInfo.nValueMax,
    }
end

function UIBuildFaceAdjustCell:UpdateBodyInfo()
    local tbBoneInfo = BuildBodyData.GetAllBoneInfo()
    self.tbBoneInfo = tbBoneInfo[self.tbInfo.nBodyType]
end

function UIBuildFaceAdjustCell:UpdateCustomInfo()
    self.tbBoneInfo = {
        nValueMin = self.tbInfo.nValueMin,
        nValueMax = self.tbInfo.nValueMax,
    }
end

function UIBuildFaceAdjustCell:UpdateSliderInfo(fPerc)
    local nMiddleValue = 0
    if self.nMaxCount and self.nMinCount then
        nMiddleValue = (self.nMaxCount - self.nMinCount) / 2 + self.nMinCount
    end

    if self.nCurCount >= nMiddleValue then
        UIHelper.SetScaleX(self.ImgFg, 1)
        UIHelper.SetWidth(self.ImgFg, (fPerc - 0.5) * self.nImgSize)
    else
        UIHelper.SetScaleX(self.ImgFg, -1)
        UIHelper.SetWidth(self.ImgFg, (1 - fPerc - 0.5) * self.nImgSize)
    end

    if self.nCurCount >= 0 then
        if self.nPageIndex == PageType.CustomPendant then
            UIHelper.SetString(self.LabelCount, "+" .. self.nCurCount)
        else
            UIHelper.SetString(self.LabelCount, string.format("+%d", self.nCurCount))
        end
    else
        if self.nPageIndex == PageType.CustomPendant then
            UIHelper.SetString(self.LabelCount, self.nCurCount)
        else
            UIHelper.SetString(self.LabelCount, string.format("%d", self.nCurCount))
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutCount)
end

function UIBuildFaceAdjustCell:SetCurCount(nCurCount)
    self.nCurCount = nCurCount
    self:UpdateInfo()
end

return UIBuildFaceAdjustCell