local UIWidgetHeadBuffCell = class("UIWidgetHeadBuffCell")

local function GetHeightestTimeText(nTime, bFrame)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end
    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60
    nS = math.floor(nS)
    local szText = ""
    if nD > 0 then
        szText = tostring(nD) .. g_tStrings.STR_BUFF_H_TIME_D_SHORT
        return szText
    end
    if nH > 0 then
        szText = szText .. tostring(nH) .. g_tStrings.STR_BUFF_H_TIME_H_SHORT
        return szText
    end
    if nM > 0 then
        szText = szText .. tostring(nM) .. g_tStrings.STR_BUFF_H_TIME_M_SHORT
        return szText
    end
    if nS > 0 then
        szText = szText .. tostring(nS) .. g_tStrings.STR_BUFF_H_TIME_S_SHORT
        return szText
    end
    szText = "0" .. g_tStrings.STR_BUFF_H_TIME_S
    return szText
end
function UIWidgetHeadBuffCell:OnEnter()
end

function UIWidgetHeadBuffCell:OnExit()
end

function UIWidgetHeadBuffCell:UpdateBuffImage(dwBufferID, nLevel, nStackNum, nEndFrame)
    if self.dwBufferID ~= dwBufferID or self.nLevel ~= nLevel or self.nStackNum ~= nStackNum or self.nEndFrame ~= nEndFrame then
        local szIcon = TabHelper.GetBuffIconPath(dwBufferID, nLevel)
        local szPath = szIcon and string.format("Resource/icon/%s", szIcon)
        if szPath then
            UIHelper.SetTexture(self.ImgBuffIcon, szPath)
        end

        UIHelper.SetVisible(self.LabelBuffLevel, true)
        UIHelper.SetString(self.LabelBuffLevel, nStackNum)

        self.nEndFrame = nEndFrame
        self:UpdateCdLabel()

        self:Stop()
        self.nCycleTimeID = Timer.AddFrameCycle(self, 2, function()
            self:UpdateCdLabel()
        end)
        self.dwBufferID = dwBufferID
        self.nLevel = nLevel
        self.nStackNum = nStackNum
    end
end

function UIWidgetHeadBuffCell:UpdateCdLabel()
    local nLeft = self.nEndFrame - GetLogicFrameCount()
    if nLeft >= 0 then
        local nNumber = nLeft / GLOBAL.GAME_FPS

        UIHelper.SetVisible(self.CdLabel, nNumber < 24 * 60)

        if nNumber >= 1 then
            local szText = GetHeightestTimeText(nLeft, true)
            UIHelper.SetString(self.CdLabel, szText)
        else
            UIHelper.SetString(self.CdLabel, string.format("%0.1f", nNumber))
        end
    end
end

function UIWidgetHeadBuffCell:Stop()
    if self.nCycleTimeID then
        Timer.DelTimer(self, self.nCycleTimeID)
        self.nCycleTimeID = nil
    end
end

function UIWidgetHeadBuffCell:UpdateTopBuff(szIconPath, szTime)
    UIHelper.SetVisible(self.WidgetMainCityHeadBuff1, false)
    UIHelper.SetVisible(self.WidgetMainCityHeadBuff2, true)
    UIHelper.SetSpriteFrame(self.ImgBuffIcon2, szIconPath)
    UIHelper.SetString(self.LabelTime, szTime)
end

function UIWidgetHeadBuffCell:SetTime(szTime)
    UIHelper.SetString(self.LabelTime, szTime)
end

return UIWidgetHeadBuffCell