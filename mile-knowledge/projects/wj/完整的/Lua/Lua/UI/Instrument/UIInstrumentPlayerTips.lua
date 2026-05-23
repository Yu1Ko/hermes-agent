-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentPlayerTips
-- Date: 2025-07-08 10:26:41
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nMaxCount = 30
local UIInstrumentPlayerTips = class("UIInstrumentPlayerTips")

function UIInstrumentPlayerTips:OnEnter(tbInstrumentData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.InstrumentData = tbInstrumentData
    UIHelper.SetVisible(self._rootNode, false)
end

function UIInstrumentPlayerTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInstrumentPlayerTips:BindUIEvent()
    if Platform.IsWindows() or Platform.IsMac() then
		UIHelper.RegisterEditBoxEnded(self.EditBox, function()
			local szSearchText = UIHelper.GetString(self.EditBox)
			self.szFilter = szSearchText
            self:UpdateInfo(self.bShowLocal)
		end)
	else
		UIHelper.RegisterEditBoxReturn(self.EditBox, function()
			local szSearchText = UIHelper.GetString(self.EditBox)
			self.szFilter = szSearchText
            self:UpdateInfo(self.bShowLocal)
		end)
	end

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        if not self.tbCurSelected or table.is_empty(self.tbCurSelected) then
            return
        end

        self.InstrumentData.SelecterInstrument(self.tbCurSelected)
        UIHelper.SetVisible(self._rootNode, false)
    end)

    UIHelper.BindUIEvent(self.TogAllCheck, EventType.OnSelectChanged, function(_, bSelected)
        for _, cell in pairs(self.tbCells_Cloud) do
            if cell and cell.ToggleSelectMusic then
                UIHelper.SetSelected(cell.ToggleSelectMusic, bSelected)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        if not self.tbBatchDeleted or table.is_empty(self.tbBatchDeleted) then
            return
        end

        local tbInstrumentData = self.InstrumentData
        if not tbInstrumentData then
            return
        end


        UIHelper.ShowConfirm("是否从云端删除选中的曲谱?", function ()
            MusicCodeData.DeletBatchInstrument(self.tbBatchDeleted)
            UIHelper.SetVisible(self._rootNode, false)
        end)
    end)

    UIHelper.BindUIEvent(self.TogSelectBg, EventType.OnSelectChanged, function(_, bSelected)
        self.bFilterCurType = bSelected
        self:UpdateInfo(self.bShowLocal)
    end)
end

function UIInstrumentPlayerTips:RegEvent()
    Event.Reg(self, EventType.OnSceneTouchNothing, function ()
        UIHelper.SetVisible(self._rootNode, false)
    end)

    Event.Reg(self, EventType.OnShowInstrumentList, function (bShowLocal)
        UIHelper.SetVisible(self._rootNode, true)
        self:UpdateInfo(bShowLocal)
    end)

    Event.Reg(self, EventType.OnDownloadMusicCodeData, function ()
        self.nUpdateTimer = self.nUpdateTimer or Timer.AddFrame(self, 5, function ()
            self:UpdateInfo(false)
            self.nUpdateTimer = nil
        end)
    end)

    Event.Reg(self, EventType.OnInstrumentCodeRsp, function (szKey, tInfo)
        if szKey == "DEL_BATCH_INSTRUMENT" or szKey == "GET_INSTRUMENT_LIST" then
            self:UpdateCloudList()
        end
    end)
end

function UIInstrumentPlayerTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInstrumentPlayerTips:UpdateInfo(bShowLocal)
    if self.bShowLocal ~= bShowLocal then
        self.bShowLocal = bShowLocal
        self.szFilter = ""
        self.bFilterCurType = true
        UIHelper.SetSelected(self.TogSelectBg, true, false)
    end

    UIHelper.SetVisible(self.ScrollViewType, false)
    UIHelper.SetVisible(self.ScrollViewType2, true)
    UIHelper.SetVisible(self.WidgetInfo01, true)

    local szTitle = bShowLocal and "导入曲谱" or "我的云端"
    UIHelper.SetString(self.LabelTitle, szTitle)
    UIHelper.SetVisible(self.LayoutBtn, bShowLocal)
    UIHelper.SetVisible(self.WidgetCloudDelete, not bShowLocal)
    if bShowLocal then
        self:UpdateLocalList()
    else
        self:UpdateCloudList()
    end
    self:UpdateBtnState()
end

local function _fnCheckFilter(tbData, szFilter, szCode, bFilterCurType, szCurType)
    local bShow = true
    local szType = tbData.szType or "sanxian"
    if bFilterCurType then
        bShow = bFilterCurType and szType == szCurType
    end

    if szFilter and szFilter ~= "" then
        if string.is_nil(tbData.szFileName) then
            bShow = false
        else
            bShow = string.find(tbData.szFileName, szFilter) ~= nil
        end
    end

    if not bShow and szCode then
        bShow = szCode == szFilter
    end

    return bShow
end

function UIInstrumentPlayerTips:UpdateLocalList()
    local tbInstrumentData = self.InstrumentData
    if not tbInstrumentData then
        return
    end

    self.tbCurSelected = {}
    self.szLocalDir = tbInstrumentData.ExportedFolder()
    self.tbFilePaths = Lib.ListFiles(self.szLocalDir) or {}

    UIHelper.RemoveAllChildren(self.ScrollViewType2)
    self.tbCells = {}
    for i, szPath in ipairs(self.tbFilePaths) do
        local tbData = MusicCodeData.FileProcess(szPath)
        if tbData and _fnCheckFilter(tbData, self.szFilter, nil, self.bFilterCurType, self.InstrumentData.szType) then
            if not self.tbCells[i] then
                self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetPresetMusicListTog, self.ScrollViewType2)
            end
            self.tbCells[i]:OnEnter(tbData)
            self.tbCells[i]:SetToggleGroupIndex(ToggleGroupIndex.TipEquipItem)
            self.tbCells[i]:SetSelectedCallback(function (bSelected)
                if not bSelected then
                    return
                end

                self.tbCurSelected = tbData
            end)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewType2)
end

function UIInstrumentPlayerTips:UpdateCloudList()
    local tbInstrumentData = self.InstrumentData
    if not tbInstrumentData then
        return
    end

    self.tbBatchDeleted = {}
    self.tbCloudData = self.InstrumentData.GetCloudList() or {}

    local szTitle = "云端曲谱（%d/%d）"
    UIHelper.RemoveAllChildren(self.ScrollViewType2)
    local nCount = 0
    self.tbCells_Cloud = {}
    for i, tData in ipairs(self.tbCloudData) do
        local szCode = tData.share_id
        local tbData = InstrumentData.GetMusicByCode(szCode, true) or {szCode = tData.share_id}
        nCount = nCount + ( tbData and 1 or 0 )
        if tbData and _fnCheckFilter(tbData, self.szFilter, szCode, self.bFilterCurType, self.InstrumentData.szType) then
            if not self.tbCells_Cloud[i] then
                self.tbCells_Cloud[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetLocalCloudMusicListTog, self.ScrollViewType2)
            end

            self.tbCells_Cloud[i]:OnEnter(tbData, tData.share_id)
            self.tbCells_Cloud[i]:SetImportCallBack(function ()
                UIHelper.ShowConfirm("是否从云端导入选中的曲谱?", function ()
                    MusicCodeData.FileDownload(tData.share_id, true)
                    UIHelper.SetVisible(self._rootNode, false)
                end)
            end)

            self.tbCells_Cloud[i]:SetSelectedCallback(function (bSelected)
                self.tbBatchDeleted = self.tbBatchDeleted or {}

                if bSelected then
                    table.insert(self.tbBatchDeleted, tData.share_id)
                else
                    table.remove_value(self.tbBatchDeleted, tData.share_id)
                end
                UIHelper.SetSelected(self.TogAllCheck, table.get_len(self.tbCells_Cloud) == #self.tbBatchDeleted, false)
                self:UpdateBtnState()
            end)
        end
    end
    UIHelper.SetString(self.LabelTitle, string.format(szTitle, nCount, nMaxCount))
    UIHelper.ScrollViewDoLayout(self.ScrollViewType2)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewType2)
    UIHelper.SetVisible(self.ScrollViewType2, nCount ~= 0)
end

function UIInstrumentPlayerTips:UpdateBtnState()
    local bEnable = table.get_len(self.tbBatchDeleted) > 0
    UIHelper.SetButtonState(self.BtnDelete, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
end


return UIInstrumentPlayerTips