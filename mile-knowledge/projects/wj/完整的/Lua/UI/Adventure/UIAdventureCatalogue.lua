-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdventureCatalogue
-- Date: 2023-05-06 10:31:35
-- Desc: ?
-- ---------------------------------------------------------------------------------

local ONE_PAGE_ADVENTURES = 5

local UIAdventureCatalogue = class("UIAdventureCatalogue")

function UIAdventureCatalogue:OnEnter(tAdventureList, tFinishAdventure, nOpenCurrID, tCurrentAdv, fnClickCallback, nFlag, fnAction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tAdventureList = tAdventureList
    self.tFinishAdventure = tFinishAdventure
    self.nOpenCurrID = nOpenCurrID
    self.tCurrentAdv = tCurrentAdv
    self.fnClickCallback = fnClickCallback

    self.tAdvList = {}
    self.tPageAdventure = {}

    self.nFlag = nFlag
    self.fnAction = fnAction
    UIHelper.SetVisible(self.ImgTittle, self.nFlag == 0)
    UIHelper.SetVisible(self.WidgetPaginate, self.nFlag == 1)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
end

function UIAdventureCatalogue:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAdventureCatalogue:BindUIEvent()
    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
            local szPage = UIHelper.GetString(self.EditPaginate)
            local nPage = tonumber(szPage) or 1
            nPage = math.max(nPage, 1)
            nPage = math.min(nPage, self.nTotalPage)
            if self.fnAction then
                self.fnAction(nPage)
            end
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function ()
            local szPage = UIHelper.GetString(self.EditPaginate)
            local nPage = tonumber(szPage) or 1
            nPage = math.max(nPage, 1)
            nPage = math.min(nPage, self.nTotalPage)
            if self.fnAction then
                self.fnAction(nPage)
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function ()
        local nPage = self.nCurPage - 1
        nPage = math.max(nPage, 1)
        nPage = math.min(nPage, self.nTotalPage)
        if self.fnAction then
            self.fnAction(nPage)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function ()
        local nPage = self.nCurPage + 1
        nPage = math.max(nPage, 1)
        nPage = math.min(nPage, self.nTotalPage)
        if self.fnAction then
            self.fnAction(nPage)
        end
    end)

    for k, widget in ipairs(self.tbWidgetCatalogue) do
        UIHelper.BindUIEvent(widget, EventType.OnClick, function ()
            self.fnClickCallback(self.tPageAdventure[k].dwID)
        end)
    end
end

function UIAdventureCatalogue:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAdventureCatalogue:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdventureCatalogue:UpdateAllList(tAdvList, nPage)
    self.tAdvList = tAdvList
    if self.nOpenCurrID then
        for k, dwID in ipairs(self.tAdvList) do
            if dwID == self.tCurrentAdv.nAdID then
                nPage = math.max(math.ceil(k / (ONE_PAGE_ADVENTURES * 2)), 1)
            end
        end
    end
    self:UpdateInfo(nPage)
end


function UIAdventureCatalogue:UpdateInfo(nPage)
    local nAllNum = #self.tAdvList
	local nStartNum = (nPage - 1) * ONE_PAGE_ADVENTURES * 2 + 1
    local nTotalPage = math.ceil(nAllNum * 1.0 / (ONE_PAGE_ADVENTURES * 2))
    self.nCurPage = nPage
    self.nTotalPage = nTotalPage

    if self.nFlag == 1 then
        nStartNum = nStartNum + ONE_PAGE_ADVENTURES
        UIHelper.SetString(self.EditPaginate, nPage)
        UIHelper.SetString(self.LabelPaginate, "/" .. nTotalPage)
    end

	local nEndNum = nStartNum + ONE_PAGE_ADVENTURES - 1
    if nEndNum > nAllNum then
        nEndNum = nAllNum
    end
    local nIndex = 1
    for i = nStartNum, nEndNum do
        local nAdventureID = self.tAdvList[i]
		local tLine = self:GetOneKindAdvLine(nAdventureID) or {}
        self:UpdateAdvInfo(nIndex, tLine, self.tFinishAdventure[nAdventureID])
        nIndex = nIndex + 1
    end
    for i = nIndex, ONE_PAGE_ADVENTURES do
        self:UpdateAdvInfo(i, nil)
    end
    self:UpdatePaginate()

    if self.nOpenCurrID then
        for _, v in ipairs(self.tPageAdventure) do
            if v.dwID == self.tCurrentAdv.nAdID then
                self.fnClickCallback(v.dwID)
            end
        end
        self.nOpenCurrID = nil
    end
end

function UIAdventureCatalogue:UpdateAdvInfo(nIndex, tLine, bFinish)
    LOG.INFO("%d", nIndex)
    self.tPageAdventure[nIndex] = tLine
    local widget = self.tbWidgetCatalogue[nIndex]
    if not tLine then
        UIHelper.SetVisible(widget, false)
        return
    end
    UIHelper.SetVisible(widget, true)
    local imgQiyu = widget:getChildByName("ImgQiYuIcon")
    local imgSpecial = widget:getChildByName("ImgSpecial")
    local imgState = widget:getChildByName("WidgetState")
    UIHelper.SetVisible(imgSpecial, tLine.bPerfect)
    UIHelper.SetVisible(imgState, bFinish)
    -- UIHelper.SetSpriteFrame(imgGet, "UIAtlas2_Public_PublicIcon_PublicIcon1_img_seal_04")
    UIHelper.SetTexture(imgQiyu, tLine.szMobileNamePath, false)
    UIHelper.LayoutDoLayout(self.LayoutCatalog)
end

function UIAdventureCatalogue:UpdatePaginate()
    local nPage = self.nCurPage
    local nTotalPage = self.nTotalPage
    -- UIHelper.SetVisible(self.WidgetPaginate, nTotalPage > 1)
    UIHelper.SetString(self.LabelPaginate, "/" .. nTotalPage)
    UIHelper.SetString(self.EditPaginate, nPage)
    UIHelper.SetVisible(self.BtnLeft, nPage > 1)
    UIHelper.SetVisible(self.BtnRight, nPage < nTotalPage)
end

function UIAdventureCatalogue:GetOneKindAdvLine(nID)
	for k, v in pairs(self.tAdventureList) do
		if v.dwID == nID then
			return v
		end
	end

	return nil
end

function UIAdventureCatalogue:SetOpenCurrID(nOpenCurrID)
    self.nOpenCurrID = nOpenCurrID
end

return UIAdventureCatalogue