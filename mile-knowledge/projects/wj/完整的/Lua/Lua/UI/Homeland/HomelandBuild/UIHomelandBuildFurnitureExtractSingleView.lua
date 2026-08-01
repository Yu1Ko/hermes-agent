-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureExtractSingleView
-- Date: 2023-12-19 10:47:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureExtractSingleView = class("UIHomelandBuildFurnitureExtractSingleView")

function UIHomelandBuildFurnitureExtractSingleView:OnEnter(nLandIndex, nFurnitureType, dwFurnitureID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurCount = 1
    self.nMinCount = 1
    self.nMaxCount = 1
	self.nTotalCount = 1

    self.m_nCurLandIndex = nLandIndex
	self.m_nFurnitureType = nFurnitureType
	self.m_dwFurnitureID = dwFurnitureID
    self:UpdateInfo()
end

function UIHomelandBuildFurnitureExtractSingleView:OnExit()
    self.bInit = false
end

function UIHomelandBuildFurnitureExtractSingleView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        GetHomelandMgr().ChangeWarehouse(self.m_nCurLandIndex, {
            {
                self.m_nFurnitureType,
                self.m_dwFurnitureID,
                -self.nCurCount
            }
        })
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
			self:OnEditBoxChanged()
		end)
    else
		UIHelper.RegisterEditBoxReturn(self.EditPaginate, function ()
			self:OnEditBoxChanged()
		end)
    end

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function (editBox, nCurNum)
        if editBox == self.EditPaginate then
            self:OnEditBoxChanged()
        end
    end)
end

function UIHomelandBuildFurnitureExtractSingleView:RegEvent()
    Event.Reg(self, "HOMELANDBUILDING_ON_CLOSE", function ()
        UIMgr.Close(self)
    end)
end

function UIHomelandBuildFurnitureExtractSingleView:UpdateInfo()
    local bOrdinaryFurniture = self.m_nFurnitureType == HS_FURNITURE_TYPE.FURNITURE
	local hlMgr = GetHomelandMgr()
	local nMyContributedCountInWarehouse = hlMgr.GetWareHouseCount(UI_GetClientPlayerID(), bOrdinaryFurniture, self.m_dwFurnitureID)
	local nTotalCountInWarehouse = self:GetOneModelAvailableCountInWarehouse()
    self.nMaxCount = math.min(nMyContributedCountInWarehouse, nTotalCountInWarehouse)
	self.nTotalCount = self.nMaxCount - self.nMinCount

	local dwItemUiId = hlMgr.MakeFurnitureUIID(self.m_nFurnitureType, self.m_dwFurnitureID)
	local tUiInfoEx = Table_GetFurnitureAddInfo(dwItemUiId)
	local szImgPath = tUiInfoEx.szPath

    local tUiInfo = FurnitureData.GetFurnInfoByTypeAndID(self.m_nFurnitureType, self.m_dwFurnitureID)
    if not tUiInfo then
        return
    end

	local szName  = UIHelper.GBKToUTF8(tUiInfo.szName)
	local szTextName = GetFormatText("[" .. szName .. "]", nil, GetItemFontColorByQuality(tUiInfo.nQuality))

	local szTextTotal = string.format("您确定从共居仓库中提取%s吗？\n宅邸仓库余量：%d\n我贡献的量：%d\t\t可提取数：%d", szTextName, nTotalCountInWarehouse, nMyContributedCountInWarehouse, self.nMaxCount)

    UIHelper.SetString(self.LabelItemName, szName)
    UIHelper.SetTexture(self.ImgItemIcon, UIHelper.FixDXUIImagePath(szImgPath))
    UIHelper.SetString(self.LabelCount, string.format("%d/%d", self.nCurCount, self.nMaxCount))
    UIHelper.SetRichText(self.RichTextDesc, szTextTotal)

    local fPerc = (self.nCurCount - self.nMinCount) / self.nTotalCount * 100
    UIHelper.SetProgressBarPercent(self.SliderCount, fPerc)
end

function UIHomelandBuildFurnitureExtractSingleView:GetOneModelAvailableCountInWarehouse()
	local hlMgr = GetHomelandMgr()
	if HLBOp_Enter.IsCohabit() then
		local tInfo = FurnitureData.GetFurnInfoByTypeAndID(self.m_nFurnitureType, self.m_dwFurnitureID)
		local nUsedCount = hlMgr.BuildGetOnLandFurniture(self.m_nFurnitureType, self.m_dwFurnitureID)
		local nCountInWarehouse = hlMgr.GetSumWareHouse(self.m_nFurnitureType == HS_FURNITURE_TYPE.FURNITURE, self.m_dwFurnitureID)
		return nCountInWarehouse - nUsedCount
	else
		return 0
	end
end

function UIHomelandBuildFurnitureExtractSingleView:OnEditBoxChanged()
	self.nCurCount = tonumber(UIHelper.GetText(self.EditPaginate)) or 1
    self.nCurCount = math.min(self.nCurCount, self.nMaxCount)
    self.nCurCount = math.max(self.nCurCount, self.nMinCount)
    self:UpdateInfo()
end

return UIHomelandBuildFurnitureExtractSingleView