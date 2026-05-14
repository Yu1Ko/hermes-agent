-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureBreakView
-- Date: 2023-12-18 16:46:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureBreakView = class("UIHomelandBuildFurnitureBreakView")

local MAX_NUM = 999

function UIHomelandBuildFurnitureBreakView:OnEnter(dwFurnitureID, nNum)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurCount = 1
    self.nMinCount = 1
    self.nMaxCount = math.min(nNum or MAX_NUM, MAX_NUM)
	self.nTotalCount = self.nMaxCount - self.nMinCount

    self.dwFurnitureID = dwFurnitureID

    self:UpdateInfo()
end

function UIHomelandBuildFurnitureBreakView:OnExit()
    self.bInit = false
end

function UIHomelandBuildFurnitureBreakView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        FurnitureBuy.RecycleFurniture(self.dwFurnitureID, self.nCurCount)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.ButtonAdd, EventType.OnClick, function(btn)
        self.nCurCount = self.nCurCount + 1
        self.nCurCount = math.min(self.nCurCount, self.nMaxCount)
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.ButtonDecrease, EventType.OnClick, function(btn)
        self.nCurCount = self.nCurCount - 1
        self.nCurCount = math.max(self.nCurCount, self.nMinCount)
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.SliderCount, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false
            -- 强制修正滑块进度
            self:UpdateInfo()
        end

        if self.bSliding then
            local fPerc = UIHelper.GetProgressBarPercent(self.SliderCount)/100
            self.nCurCount = fPerc * self.nTotalCount + self.nMinCount
            self.nCurCount = math.ceil(self.nCurCount)
            if self.nCurCount <= self.nMinCount then
                self.nCurCount = self.nMinCount
            elseif self.nCurCount >= self.nMaxCount then
                self.nCurCount = self.nMaxCount
            end

            self:UpdateInfo()
        end
    end)

    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
	if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
			local nNewCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
			self.nCurCount = nNewCount
            self.nCurCount = math.min(self.nCurCount, self.nMaxCount)
            self.nCurCount = math.max(self.nCurCount, self.nMinCount)
            self:UpdateInfo()
		end)
    else
		UIHelper.RegisterEditBoxReturn(self.EditPaginate, function ()
			local nNewCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
			self.nCurCount = nNewCount
            self.nCurCount = math.min(self.nCurCount, self.nMaxCount)
            self.nCurCount = math.max(self.nCurCount, self.nMinCount)
            self:UpdateInfo()
		end)
    end

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function (editBox, nCurNum)
        if editBox == self.EditPaginate then
            local nNewCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
			self.nCurCount = nNewCount
            self.nCurCount = math.min(self.nCurCount, self.nMaxCount)
            self.nCurCount = math.max(self.nCurCount, self.nMinCount)
            self:UpdateInfo()
        end
    end)
end

function UIHomelandBuildFurnitureBreakView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildFurnitureBreakView:UpdateInfo()
    local pHomelandMgr = GetHomelandMgr()
	local tConfig = pHomelandMgr.GetFurnitureConfig(self.dwFurnitureID)
    local nItemUiId = pHomelandMgr.MakeFurnitureUIID(HS_FURNITURE_TYPE.FURNITURE, self.dwFurnitureID)
	local tInfo =  FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, self.dwFurnitureID)
	local tAddInfo = FurnitureData.GetFurnAddInfo(nItemUiId)
    local bSpecialBuy = FurnitureBuy.IsSpecialFurnitrueCanBuy(self.dwFurnitureID)
	local szPath = tAddInfo.szPath or ""

    local nRecycleArc = bSpecialBuy and tConfig.nReBuyCost or tConfig.nArchitecture
    local nMoney = nRecycleArc * self.nCurCount
	local nRate = pHomelandMgr.GetConfig().nRecycleFurnitureRate / 100
	nMoney = math.floor(nMoney * nRate)
	local szTextMoney = GetFormatText(nMoney)

	local szTextName = GetFormatText("[" .. UIHelper.GBKToUTF8(tInfo.szName) .. "]", nil, GetItemFontColorByQuality(tInfo.nQuality))

    local szFormatText = string.format(g_tStrings.STR_HOMELAND_BUILDING_DISMANTLE_ENSURE1, self.nCurCount, szTextName, szTextMoney)

    UIHelper.SetTexture(self.ImgItemIcon, UIHelper.FixDXUIImagePath(szPath))

    UIHelper.SetString(self.LabelItemName, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.SetString(self.LabelCount, string.format("%d/%d", self.nCurCount, self.nMaxCount))
    UIHelper.SetString(self.EditPaginate, self.nCurCount)
    UIHelper.LayoutDoLayout(self.LayoutCount)

    UIHelper.SetRichText(self.RichTextDesc, szFormatText)

    local fPerc = (self.nCurCount - self.nMinCount) / self.nTotalCount * 100
    UIHelper.SetProgressBarPercent(self.SliderCount, fPerc)
end


return UIHomelandBuildFurnitureBreakView