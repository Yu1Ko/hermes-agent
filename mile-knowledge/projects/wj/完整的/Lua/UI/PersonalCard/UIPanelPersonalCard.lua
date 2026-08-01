-- ---------------------------------------------------------------------------------
-- Name: UIPanelPersonalCard
-- Desc: 名片形象
-- ---------------------------------------------------------------------------------

local UIPanelPersonalCard = class("UIPanelPersonalCard")
local m_MaxCountOnPage = 9

local function GetMaxIndex()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return 0
    end
    return hPlayer.GetShowCardBoxSize() - 1
end

local function GetPageByIndex(nIndex)
    return math.max(1, math.ceil(nIndex/ m_MaxCountOnPage))
end

local function GetTotalPage()
    local nMaxIndex = GetMaxIndex() + 1
    return GetPageByIndex(nMaxIndex)
end

function UIPanelPersonalCard:OnEnter(fnCallBackCloseView)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self.fnCallBackCloseView = fnCallBackCloseView
    self.scriptSmallCard = {} -- 备用名片页面预制; index从1开始，使用需要加1
    if g_pClientPlayer then
        self.nSelectedIndex = g_pClientPlayer.GetSelectedShowCardDecorationPresetIndex()
    else
        self.nSelectedIndex = 0
    end
    self:UpdateInfo()
    self:ApplyImageData()
end

function UIPanelPersonalCard:OnExit()
    self.bInit = false
    self.scriptSmallCard = {}
    self:UnRegEvent()
    PersonalCardData.CleanSelfImage()

    if ShareStationData.szImportPhotoCode then
        ShareStationData.szImportPhotoCode = nil
    end
end

function UIPanelPersonalCard:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick , function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBug, EventType.OnClick, function ()
        self:OnBuyCard()
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function ()
        if self.nCurPage > 1 then
            self.nCurPage = self.nCurPage - 1
            self:UpdatePage()
            self:ApplyImageData()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function ()
        if self.nCurPage < self.nMaxPage then
            self.nCurPage = self.nCurPage + 1
            self:UpdatePage()
            self:ApplyImageData()
        end
    end)

    local _EditNumHandler = function()
        local szNum = UIHelper.GetString(self.EditPaginate)
        local nNum = tonumber(szNum)
        if not nNum or nNum < 1 then
            nNum = 1
        end
        self.nMaxPage = GetTotalPage()
        if nNum > self.nMaxPage then
            nNum = self.nMaxPage
        end
        self.nCurPage = nNum
        self:UpdatePage()
        self:ApplyImageData()
    end
    self.EditPaginate:registerScriptEditBoxHandler(function(szType, _editbox)
        if szType == "ended" then
            if Platform.IsWindows() or Platform.IsMac() then
                _EditNumHandler()
            end
        elseif szType == "return" then
            if not Platform.IsWindows() then
                _EditNumHandler()
            end
        end
    end)
end

function UIPanelPersonalCard:RegEvent()
    Event.Reg(self, "DOWNLOAD_SHOW_IMAGE_RESPOND", function(uGlobalID, bSuccess, dwImageIndex)

        --LOG.INFO("DOWNLOAD_SHOW_IMAGE_RESPOND  %s,%s,%s",tostring(uGlobalID),tostring(bSuccess),tostring(dwImageIndex))

        if g_pClientPlayer.GetGlobalID() == uGlobalID then
            if bSuccess == 1 then
                if PersonalCardData.tSelfImageData[dwImageIndex] then
                    PersonalCardData.CleanSelfImage(dwImageIndex)
                end
                PersonalCardData.tSelfImageData[dwImageIndex] = {}
                PersonalCardData.tSelfImageData[dwImageIndex].bHave = true
                self:DownloadImageDataNotSaveAndShow(dwImageIndex)
                self:UpdateCardCount()
            else
                PersonalCardData.tSelfImageData[dwImageIndex] = {}
                PersonalCardData.tSelfImageData[dwImageIndex].bHave = false
                self:UpdateImage(dwImageIndex)
            end
        end
    end)

    Event.Reg(self, "ON_UPDATE_SHOW_CARD_BOX_SIZE_NOTIFY", function()
        self.nCurPage = GetPageByIndex(arg0)
        self:UpdateBuyBtn()
        self:UpdatePage()
        self:UpdateCardCount()
        self:ApplyImageData()
    end)
end

function UIPanelPersonalCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- image data
-- ----------------------------------------------------------
function UIPanelPersonalCard:ApplyImageData()
    if g_pClientPlayer then
        local hManager = GetShowCardCacheManager()
        local uGlobalID = g_pClientPlayer.GetGlobalID()
        if hManager then
            for nStartIndex = 0, m_MaxCountOnPage - 1 do
                local dataIndex = (self.nCurPage -1) * m_MaxCountOnPage + nStartIndex
        
                if dataIndex < self.nPlayerCardMaxCount then
                    if PersonalCardData.tSelfImageData[dataIndex] then
                        self:UpdateImage(dataIndex)
                    else
                        if PersonalCardData.GetShowCardPresetState(dataIndex, SHOW_CARD_PRESET_STATE_TYPE.UPLOAD_IMAGE) then
                            LOG.INFO("DownloadShowCardImage %d",dataIndex)
                            hManager.DownloadShowCardImage(uGlobalID, nStartIndex)
                            self:UpdateLoadState(dataIndex)
                        else
                            PersonalCardData.tSelfImageData[dataIndex] = {}
                            PersonalCardData.tSelfImageData[dataIndex].bHave = false
                            self:UpdateImage(dataIndex)
                        end
                    end
                end
            end
        end
        self:SetCellVisible()
    end
end

function UIPanelPersonalCard:DownloadImageDataAndShow(nIndex)
    local hManager = GetShowCardCacheManager()
    if hManager and g_pClientPlayer then
        local pdata, nsize = hManager.GetImageDataForMobile(g_pClientPlayer.GetGlobalID(), nIndex, 1)
        if pdata and nsize then
            local folder = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("personalcard/")))
            CPath.MakeDir(folder)
            local fileName = folder.. string.format("selfof%02d.png",nIndex)
            local img = cc.Image:new()
            img:retain()
            img:initWithImageData(pdata, nsize)
            UIHelper.SaveImageToLocalFile(fileName, img, function()
                local fileName = "personalcard/" .. string.format("selfof%02d.png",nIndex)
                PersonalCardData.tSelfImageData[nIndex].fileName = fileName
                self:UpdateImage(nIndex)
                img:release()
                UIHelper.LayoutDoLayout(self.LayoutEdit)
            end)
        end
    end
end

function UIPanelPersonalCard:DownloadImageDataNotSaveAndShow(nIndex)
    local hManager = GetShowCardCacheManager()
    if hManager and g_pClientPlayer then
        local pdata, nsize = hManager.GetImageDataForMobile(g_pClientPlayer.GetGlobalID(), nIndex, 1)
        if pdata and nsize then
            UIHelper.GetImageFromPngData(function(pRetTexture, pImage)
                pRetTexture:retain()
                PersonalCardData.tSelfImageData[nIndex].pRetTexture = pRetTexture

                self:UpdateImage(nIndex)
                Timer.Add(self, 0.1, UIHelper.LayoutDoLayout(self.LayoutEdit))
            end, pdata, nsize)
        end
    end
end
-- ----------------------------------------------------------
-- page
-- ----------------------------------------------------------
function UIPanelPersonalCard:UpdateInfo()
    self.nCurPage = GetPageByIndex(self.nSelectedIndex)
    self.nMaxPage = 1
    self:UpdateCardCount()
    self:UpdatePage()
    self:InitEditCell()
    self:UpdateBuyBtn()
    local tInfo = {
        bEdit = true,
        bSetBirth = true,
        fnCallBackClose = function ()
            if self.fnCallBackCloseView then
                self.fnCallBackCloseView()
            end
            UIMgr.Close(self)
        end,
        fnCallBackOpenLeft = function(nPrefabID, fnCallBack, dwKey)
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EQUIP) then
                return
            end

            self:UpdateLeftPop(nPrefabID, fnCallBack, dwKey)
        end
    }
    self.scriptCard = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetPersonalCard, nil, tInfo)
    self.scriptCard:SetPlayerId(g_pClientPlayer.dwID)
end

function UIPanelPersonalCard:UpdateImage(nDataIndex)
    local bChoice = false

    local nCellIndex = nDataIndex - (self.nCurPage - 1) * m_MaxCountOnPage + 1

    if nDataIndex == self.nSelectedIndex then
        self.scriptCard:UpdateImageByPlayerData(nDataIndex, true)
        bChoice = true
    end
    if not self.scriptSmallCard[nCellIndex] then
        self:InitEditCell()
        self.scriptSmallCard[nCellIndex]:UpdateImageData(nDataIndex)
    else
        self.scriptSmallCard[nCellIndex]:UpdateImageData(nDataIndex)
    end
    if bChoice == true then
        self.scriptSmallCard[nCellIndex]:RawSetSelected(true)
    else
        self.scriptSmallCard[nCellIndex]:RawSetSelected(false)
    end
end

function UIPanelPersonalCard:UpdateLoadState(nDataIndex)
    local nCellIndex = nDataIndex - (self.nCurPage - 1) * m_MaxCountOnPage + 1
    if nDataIndex == self.nSelectedIndex then
        self.scriptCard:UpdateLoadState()
    end
    if not self.scriptSmallCard[nCellIndex] then
        self:InitEditCell()
        self.scriptSmallCard[nCellIndex]:UpdateLoadState()
    else
        self.scriptSmallCard[nCellIndex]:UpdateLoadState()
    end
end

-- 名片备用页
function UIPanelPersonalCard:InitEditCell()
    for nIndex = 1, m_MaxCountOnPage do
        self:GetEditScript(nIndex)
    end
    self:SetCellVisible()
    local nIndex = self.nSelectedIndex - (self.nCurPage - 1) * m_MaxCountOnPage
    --LOG.INFO(string.format("%d,%d",self.nSelectedIndex, nIndex))
    UIHelper.SetVisible(self.scriptSmallCard[nIndex + 1].ImgInUseTab, true)
end

function UIPanelPersonalCard:GetEditScript(nIndex)
    local fnCallBackSelected = function(nIndex)
        self:UpdateSelected(nIndex)
    end
    local fnCallBackClose = function ()
        if self.fnCallBackCloseView then
            self.fnCallBackCloseView()
        end
        UIMgr.Close(self)
    end
    if #self.scriptSmallCard < nIndex then
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetEditCell, self.LayoutEdit) assert(script)
        script:SetfnCallBackCloseView(fnCallBackClose)
        script:SetfnSelected(fnCallBackSelected)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupEdit, script.TogUse)
        table.insert(self.scriptSmallCard, script)
        UIHelper.SetVisible(self.scriptSmallCard[nIndex]._rootNode, false)
    end
    return self.scriptSmallCard[nIndex]
end


function UIPanelPersonalCard:SetCellVisible()
    local nNum = math.min(self.nPlayerCardMaxCount - (self.nCurPage -1) * m_MaxCountOnPage, m_MaxCountOnPage)
    for nIndex = 1, m_MaxCountOnPage do
        UIHelper.SetVisible(self.scriptSmallCard[nIndex]._rootNode, nIndex <= nNum)
    end
    UIHelper.LayoutDoLayout(self.LayoutEdit)
end

function UIPanelPersonalCard:UpdateSelected(nDataIndex)
    local nCellIndex = nDataIndex - (self.nCurPage -1)* m_MaxCountOnPage + 1
    for i = 1, m_MaxCountOnPage do
        if nCellIndex == i then
            self.scriptSmallCard[i]:RawSetSelected(true)
        else
            self.scriptSmallCard[i]:RawSetSelected(false)
        end
    end
    self.nSelectedIndex = nDataIndex
    self.scriptCard:UpdateImageByPlayerData(nCellIndex - 1)
    if g_pClientPlayer then
        g_pClientPlayer.SelectShowCardDecorationPreset(nCellIndex - 1)
        local sTip = "装备了第" .. nCellIndex .. "套名片"
        TipsHelper.ShowNormalTip(sTip)
    end
end

-- 左侧数据选择弹出框 称号 + 数据
function UIPanelPersonalCard:UpdateLeftPop(nPrefabID, fnCallBack, dwKey)
    UIHelper.RemoveAllChildren(self.WidgetPersonalCardLeftPop)
    self.scriptLeft = UIHelper.AddPrefab(nPrefabID, self.WidgetPersonalCardLeftPop, fnCallBack, dwKey)
end


function UIPanelPersonalCard:OnBuyCard()

    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tBoxMoney = Table_GetPersonalCardBoxMoney(hPlayer.GetShowCardBoxSize())
    if not tBoxMoney then
        return
    end
    local nIndex     = tBoxMoney.nIndex
    local nCostMoney = tBoxMoney.nCostMoney
    UIHelper.ShowConfirm(string.format(g_tStrings.STR_PERSONAL_CARD_BUY_BOX, nCostMoney), function ()
        RemoteCallToServer("On_AddPersonalCardNum_Add", nIndex, nCostMoney)
    end)
end

function UIPanelPersonalCard:GetCount()
    local nTotalCount   = 0
    local tList         = PersonalCardData.GetAllShowCardDecorationPreset()
    local nMaxIndex     = GetMaxIndex()
    for i = 0, nMaxIndex do
        local tInfo = tList[i]
        local bState = PersonalCardData.GetShowCardPresetState(i, SHOW_CARD_PRESET_STATE_TYPE.UPLOAD_IMAGE)
        if (tInfo and not IsTableEmpty(tInfo)) or bState then
            nTotalCount = nTotalCount + 1
        end
    end
    return nTotalCount
end


function UIPanelPersonalCard:UpdateCardCount()
    self.nPlayerCardCount = self:GetCount()
    self.nPlayerCardMaxCount = GetMaxIndex() + 1
    UIHelper.SetString(self.LabelNum, string.format("%d/%d",self.nPlayerCardCount, self.nPlayerCardMaxCount))
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIPanelPersonalCard:UpdatePage()
    self.nMaxPage = GetTotalPage()
    UIHelper.SetVisible(self.WidgetPaginate, self.nMaxPage > 1)
    UIHelper.SetText(self.EditPaginate, self.nCurPage)
    UIHelper.SetString(self.LabelPaginate, "/"..self.nMaxPage)
end

function UIPanelPersonalCard:UpdateBuyBtn()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tBoxMoney = Table_GetPersonalCardBoxMoney(hPlayer.GetShowCardBoxSize())
    UIHelper.SetEnable(self.BtnBug, tBoxMoney ~= nil)
    UIHelper.SetNodeGray(self.BtnBug, tBoxMoney == nil, true)
end

return UIPanelPersonalCard