-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSettingsFoldTitle
-- Date: 2022-12-20 14:50:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSettingsFoldTitle = class("UIWidgetSettingsFoldTitle")

function UIWidgetSettingsFoldTitle:OnEnter(szTitle, szDesc, tIDList, dwTotalSize)
    self.tIDList = tIDList
    self.dwTotalSize = dwTotalSize

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
        self.scriptResources = UIMgr.GetViewScript(VIEW_ID.PanelResourcesDownload)
    end

    UIHelper.SetSwallowTouches(self.BtnHelp, true)
    UIHelper.SetSwallowTouches(self.BtnCancel, true)
    UIHelper.SetSwallowTouches(self.ToggleMultiSelect, true)

    self.tPackIDList = nil
    Timer.DelAllTimer(self)

    if tIDList then
        self.tPackIDList = {}
        for _, nID in ipairs(tIDList) do
            if PakDownloadMgr.GetPackInfo(nID) then
                table.insert(self.tPackIDList, nID)
            else
                local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(nID)
                for _, nPackID in ipairs(tPackIDList) do
                    table.insert(self.tPackIDList, nPackID)
                end
            end
        end

        self.scriptDownload:OnInitWithPackIDList(self.tPackIDList,
        {
            bCell = true,
            szGroupName = szTitle,
            fnGetProgressText = function()
                return self:GetProgressText()
            end
        })

        --若正在下载，固定每0.1s更新一次
        Timer.AddCycle(self, 0.1, function()
            if not PakDownloadMgr.IsUIUpdateEnabled() then
                return
            end

            for _, nPackID in pairs(self.tPackIDList) do
                local tDownloadInfo = PakDownloadMgr.GetDownloadingInfo(nPackID)
                if tDownloadInfo and tDownloadInfo.nState ~= DOWNLOAD_STATE.COMPLETE then
                    self:UpdateStateInfo()
                    return
                end
            end
        end)
    end

    self:SetRecommend(false)
    self:UpdateInfo(szTitle, szDesc)
end

function UIWidgetSettingsFoldTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSettingsFoldTitle:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSettingsMultipleChoice, EventType.OnSelectChanged, function (_, bSelected)
        self.fCallBack(bSelected)
    end)
    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp, self.szDesc)
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        for _, nPackID in ipairs(self.tPackIDList or {}) do
            PakDownloadMgr.CancelPack(nPackID)
        end
    end)
    UIHelper.BindUIEvent(self.ToggleMultiSelect, EventType.OnSelectChanged, function(_, bSelected)
        for _, nPackID in ipairs(self.tPackIDList or {}) do
            local nDelState = PakDownloadMgr.GetDeleteState(nPackID)
            if nDelState == RESOURCE_DELETE_STATE.CAN_DELETE or not bSelected then
                Event.Dispatch(EventType.OnGameSettingDiscardResSelected, nPackID, bSelected)
            end
        end

        --删除时当前资源包处于下载/等待状态
        if bSelected then
            local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
            if tStateInfo.nState == DOWNLOAD_STATE.DOWNLOADING or tStateInfo.nState == DOWNLOAD_STATE.QUEUE then
                local szGroupName = UIHelper.GetString(self.LabelTitle)
                UIHelper.ShowConfirm(string.format("[%s]中资源正在下载，是否暂停下载？", szGroupName or "当前分类"), function()
                    PakDownloadMgr.PausePackInPackIDList(self.tPackIDList)
                end)
            end
        end
    end)
end

function UIWidgetSettingsFoldTitle:RegEvent()
    Event.Reg(self, EventType.PakDownload_OnStateUpdate, function(nPackID)
        if self.tPackIDList and table.contain_value(self.tPackIDList, nPackID) then
            self:UpdateStateInfo()
        end
    end)
    Event.Reg(self, EventType.OnGameSettingDiscardRes, function(bDiscard)
        self:SetDiscard(bDiscard)
    end)
end

function UIWidgetSettingsFoldTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetSettingsFoldTitle:UpdateInfo(szTitle, szDesc)
    UIHelper.SetString(self.LabelTitle, szTitle)

    if szDesc and szDesc ~= "" then
        self.szDesc = szDesc
        UIHelper.SetVisible(self.BtnHelp, true)
    else
        UIHelper.SetVisible(self.BtnHelp, false)
    end

    if self.tIDList and self.tPackIDList then
        UIHelper.SetVisible(self.LayoutBtn, true)
        UIHelper.SetVisible(self.LabelCapacity, true)
        UIHelper.SetString(self.LabelCapacity, "（正在计算大小...）")
        self:UpdateStateInfo()
    else
        UIHelper.SetVisible(self.LayoutBtn, false)
        UIHelper.SetVisible(self.LabelCapacity, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIWidgetSettingsFoldTitle:GetProgressText()
    local nDownloadedCount = 0
    local nTotalCount = 0
    for _, nPackID in ipairs(self.tPackIDList) do
        nTotalCount = nTotalCount + 1
        local nState, _, _ = PakDownloadMgr.GetPackState(nPackID)
        if nState == DOWNLOAD_OBJECT_STATE.DOWNLOADED then
            nDownloadedCount = nDownloadedCount + 1
        end
    end
    return nDownloadedCount .. "/" .. nTotalCount
end

function UIWidgetSettingsFoldTitle:UpdateStateInfo()
    local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
    local nState = tStateInfo.nState
    --print_table(tStateInfo)

    local szTitle = ""
    -- if nState == DOWNLOAD_STATE.NONE or (tStateInfo.dwTotalSize > 0 and tStateInfo.dwDownloadedSize <= 0) then
    --     szTitle = "（" .. PakDownloadMgr.FormatSize(tStateInfo.dwTotalSize) .. "）"
    --     UIHelper.SetVisible(self.WidgetDownload, not self.bDiscard)
    --     --UIHelper.SetVisible(self.BtnCancel, false)
    -- elseif nState == DOWNLOAD_STATE.DOWNLOADING or nState == DOWNLOAD_STATE.QUEUE or nState == DOWNLOAD_STATE.PAUSE then
    --     szTitle = "（" .. PakDownloadMgr.FormatSize(tStateInfo.dwTotalSize) .. "，已下载" .. PakDownloadMgr.FormatSize(tStateInfo.dwDownloadedSize) .. "）"
    --     UIHelper.SetVisible(self.WidgetDownload, not self.bDiscard)
    --     --UIHelper.SetVisible(self.BtnCancel, nState == DOWNLOAD_STATE.PAUSE and tStateInfo.nTotalTask > 0)
    -- elseif nState == DOWNLOAD_STATE.COMPLETE then
    --     szTitle = tStateInfo.nTotalPack > 0 and "（下载完成）" or ""
    --     UIHelper.SetVisible(self.WidgetDownload, false)
    --     --UIHelper.SetVisible(self.BtnCancel, false)
    -- end

    if nState == DOWNLOAD_STATE.COMPLETE then
        szTitle = tStateInfo.nTotalPack > 0 and "（下载完成）" or ""
        UIHelper.SetString(self.LabelCapacity, szTitle)
    elseif self.dwTotalSize then
        szTitle = "（预计：" .. PakDownloadMgr.FormatSize(self.dwTotalSize, 0) .. "）"
        UIHelper.SetString(self.LabelCapacity, szTitle)
    end

    self:UpdateDelTogState()

    --UIHelper.SetString(self.LabelCapacity, szTitle)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIWidgetSettingsFoldTitle:SetSelectChangeCallback(fCallBack)
    self.fCallBack = fCallBack
end

function UIWidgetSettingsFoldTitle:SetSelected(bSelected, bCallback)
    UIHelper.SetSelected(self.TogSettingsMultipleChoice, bSelected, bCallback)
end

function UIWidgetSettingsFoldTitle:SetDiscard(bDiscard)
    self.bDiscard = bDiscard

    self:UpdateDelTogState()
    self.scriptDownload:SetDiscard(bDiscard)
    UIHelper.SetVisible(self.WidgetDownload, not bDiscard)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.LayoutDoLayout(self.LayoutTitle)
end

function UIWidgetSettingsFoldTitle:SetRecommend(bRecommend)
    UIHelper.SetVisible(self.ImgRecommend, bRecommend)
end

function UIWidgetSettingsFoldTitle:UpdateDelTogState()
    UIHelper.SetVisible(self.WidgetDelCheckBox, self.bDiscard)
    if not self.bDiscard or not self.tPackIDList then
        return
    end

    local bEnableTog = false
    for _, nPackID in ipairs(self.tPackIDList) do
        local nDelState = PakDownloadMgr.GetDeleteState(nPackID)
        if nDelState == RESOURCE_DELETE_STATE.CAN_DELETE then
            bEnableTog = true
            break
        end
    end

    UIHelper.SetEnable(self.ToggleMultiSelect, bEnableTog)
    UIHelper.SetVisible(self.ImgCheckForbidden, not bEnableTog)

    if bEnableTog then
        local nSelState = self.scriptResources and self.scriptResources:GetSelectState(self.tPackIDList)
        UIHelper.SetSelected(self.ToggleMultiSelect, nSelState ~= MultiSelectState.None, false)
        UIHelper.SetVisible(self.ImgCheckAll, nSelState == MultiSelectState.All)
        UIHelper.SetVisible(self.ImgCheckPart, nSelState == MultiSelectState.Part)
    else
        UIHelper.SetSelected(self.ToggleMultiSelect, true, false)
        UIHelper.SetVisible(self.ImgCheckAll, false)
        UIHelper.SetVisible(self.ImgCheckPart, false)
    end
end

return UIWidgetSettingsFoldTitle