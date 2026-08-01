-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationLeftList
-- Date: 2025-07-19 21:36:31
-- Desc: ?
-- ---------------------------------------------------------------------------------
local FACE_LIST_PAGE_SIZE = 12 --每一页最多显示捏脸的数量
local MAX_FACE_STATION_PAGE = 99 --捏脸站最多显示99页
local MAX_COLLECT_COUNT = 50 --最多收藏捏脸的个数
local Page2EmptyLabel = {
    ["Rank"] = "暂无符合条件的作品",
    ["Like"] = "暂无收藏的作品",
    ["Self"] = "暂无上传的作品",
    ["Author"] = "暂无符合条件的作者",
}
local UIShareStationLeftList = class("UIShareStationLeftList")

function UIShareStationLeftList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetVisible(self.WidgetEmpty, true)
end

function UIShareStationLeftList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationLeftList:BindUIEvent()
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
    UIHelper.SetEditBoxInputMode(self.EditPaginate, cc.EDITBOX_INPUT_MODE_NUMERIC)
    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function(btn)
        local nPage = self.nCurPage - 1
        if nPage < 1 then
            nPage = 1
        end
        if self.nCurPage ~= nPage then
            self.nCurPage = nPage
            UIHelper.SetText(self.EditPaginate, self.nCurPage)
            self:OnChangePage()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function(btn)
        local nPage = self.nCurPage + 1
        if nPage > self.nMaxPage then
            nPage = self.nMaxPage
        end
        if self.nCurPage ~= nPage then
            self.nCurPage = nPage
            UIHelper.SetText(self.EditPaginate, self.nCurPage)
            self:OnChangePage()
        end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
            local szPage = UIHelper.GetText(self.EditPaginate) or "0"
            local nPage = tonumber(szPage)
            if nPage > self.nMaxPage then
                nPage = self.nMaxPage
            elseif nPage < 1 then
                nPage = 1
            end
            if self.nCurPage ~= nPage then
                self.nCurPage = nPage
                self:OnChangePage()
            end
            UIHelper.SetText(self.EditPaginate, self.nCurPage)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditPaginate, function ()
            local szPage = UIHelper.GetText(self.EditPaginate) or "0"
            local nPage = tonumber(szPage)
            if nPage > self.nMaxPage then
                nPage = self.nMaxPage
            elseif nPage < 1 then
                nPage = 1
            end
            if self.nCurPage ~= nPage then
                self.nCurPage = nPage
                self:OnChangePage()
            end
            UIHelper.SetText(self.EditPaginate, self.nCurPage)
        end)
    end

    UIHelper.BindUIEvent(self.BtnComfirm, EventType.OnClick, function(btn)
        self:EndBatchDel(false)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        self:EndBatchDel(true)
    end)

    UIHelper.BindUIEvent(self.TogAllSelect, EventType.OnSelectChanged, function(tog, bSelected)
        for index, script in ipairs(ShareStationData.tbScriptList) do
            if script:GetSelected() ~= bSelected then
                script:SetSelected(bSelected)
            end
        end
    end)
end

function UIShareStationLeftList:RegEvent()
    Event.Reg(self, EventType.OnStartBatchDelShareCode, function ()
        self:StartBatchDel()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.Add(self, 0.1, function ()
            UIHelper.SetText(self.EditPaginate, "") -- 刷新一下防止对齐问题
            UIHelper.SetText(self.EditPaginate, self.nCurPage)
        end)
    end)
end

function UIShareStationLeftList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShareStationLeftList:UpdateInfo(szPage, nTotalCount, tRankList)
    local nCurDataType = ShareStationData.nDataType
    if not self.nDataType or self.nDataType ~= nCurDataType then
        self.nCurPage = ShareStationData.nViewPage
        self.nDataType = nCurDataType

        if ShareStationData.bDelMode then
            ShareStationData.bDelMode = false
            ShareStationData.tDelShare = {}
            Event.Dispatch(EventType.OnEndBatchDelShareCode)
        end
    end

    if not self.szPage or self.szPage ~= szPage then
        self.szPage = szPage
        ShareStationData.SetViewPage(self.nCurPage)

        if szPage ~= "self" and ShareStationData.bDelMode then
            ShareStationData.bDelMode = false
            ShareStationData.tDelShare = {}
            Event.Dispatch(EventType.OnEndBatchDelShareCode)
        end

        if ShareStationData.IsInFilter() then
            UIHelper.SetString(self.LabelEmpty, "暂无符合条件的作品")
        end
        UIHelper.SetString(self.LabelEmpty, Page2EmptyLabel[self.szPage] or "")
    end

    if tRankList and not table.deepCompare(tRankList, self.tRankList) then
        nTotalCount = nTotalCount or 1
        self.tRankList = tRankList
        self.nMaxPage = math.ceil(nTotalCount / FACE_LIST_PAGE_SIZE)
        self.nMaxPage = math.max(self.nMaxPage, 1)
    end

    ShareStationData.tbScriptList = {}
    UIHelper.RemoveAllChildren(self.ScrollCardList)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupCard)
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupCard, self.nDataType ~= SHARE_DATA_TYPE.PHOTO)
    UIHelper.SetVisible(self.WidgetManageShare, ShareStationData.bDelMode)

    local bEmpty = true
    local nStartIndex
    local tFilterShareData = self.tRankList or {}
    if szPage == "Rank" then
        nStartIndex = 1
        self.nMaxPage = self.nMaxPage or 1
    else
        tFilterShareData = ShareStationData.GetFilterShareData(self.nDataType, self.tRankList) or {}
        nStartIndex = (self.nCurPage - 1) * FACE_LIST_PAGE_SIZE + 1
        self.nMaxPage = math.ceil(#tFilterShareData / FACE_LIST_PAGE_SIZE)
        self.nMaxPage = math.max(self.nMaxPage, 1)
    end

    if #tFilterShareData > 0 then
        for i = 1, FACE_LIST_PAGE_SIZE do
            local tData = tFilterShareData[nStartIndex + i - 1]
            if tData then
                local nPrefabID = PREFAB_ID.WidgetFaceStationFaceCell
                if tData.nPhotoSizeType and tData.nPhotoSizeType == SHARE_PHOTO_SIZE_TYPE.HORIZONTAL then
                    nPrefabID = PREFAB_ID.WidgetFaceStationFaceLandscapeCell
                elseif self.szPage == "Author" then
                    nPrefabID = PREFAB_ID.WidgeShareStationAuthorCell
                end

                local script = UIHelper.AddPrefab(nPrefabID, self.ScrollCardList)
                script:OnEnter(self.nDataType, tData)
                UIHelper.SetVisible(script.WidgetPublic, self.szPage == "Self")

                if self.szPage ~= "Author" then
                    script:UpdateInvisible(self.szPage)
                end

                if not ShareStationData.bDelMode then
                    UIHelper.ToggleGroupAddToggle(self.ToggleGroupCard, script.TogFaceCell)
                    script:SetBatchSelecte(false)
                else
                    UIHelper.SetSelected(script.TogFaceCell, table.contain_value(ShareStationData.tDelShare, tData.szShareCode), false)
                    script:SetBatchSelecte(true)
                end
                UIHelper.SetVisible(script.WidgetPublic, self.szPage == "Self")
                table.insert(ShareStationData.tbScriptList, script)
                bEmpty = false
            end
        end
    end

    UIHelper.SetText(self.EditPaginate, self.nCurPage)
    UIHelper.SetString(self.LabelPaginate, string.format("/%d", self.nMaxPage))
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollCardList)
    UIHelper.ScrollViewSetupArrow(self.ScrollCardList, self.WidgetArrowDown)
    Event.Dispatch(EventType.OnSelectShareStationCell, nil)

    if (self.nDataType == SHARE_DATA_TYPE.PHOTO or not string.is_nil(ShareStationData.szSearch)) and not ShareStationData.bDelMode then
        local tbData = ShareStationData.tbScriptList[1] and ShareStationData.tbScriptList[1].tbData
        if tbData then
            Timer.AddFrame(self, 1, function ()
                UIHelper.SetToggleGroupSelected(self.ToggleGroupCard, 0)
                Event.Dispatch(EventType.OnSelectShareStationCell, tbData, true)
            end)
        end
    end
    ShareStationData.OnUpdateDelManager()
end

function UIShareStationLeftList:OnChangePage()
    if self.szPage == "Rank" then
        ShareStationData.SetViewPage(self.nCurPage)
        if ShareStationData.szFilterAccount then
            ShareStationData.ApplySearchUser()
        else
            ShareStationData.ApplyShareStationData(ShareStationData.bIsLogin)
        end
    else
        self:UpdateInfo(self.szPage, nil, self.tRankList)
    end
end

function UIShareStationLeftList:StartBatchDel()
    ShareStationData.bDelMode = true
    ShareStationData.tDelShare = {}
    UIHelper.SetVisible(self.WidgetManageShare, true)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupCard)

    ShareStationData.BindBatchDelManager(self.LabelSelectedNum, self.TogAllSelect)
end

function UIShareStationLeftList:EndBatchDel(bReturn)
    ShareStationData.bDelMode = false
    if bReturn then
        ShareStationData.tDelShare = {}
    end

    self:UpdateInfo(self.szPage, nil, self.tRankList)
    if table.GetCount(ShareStationData.tDelShare) <= 0 then
        UIHelper.SetVisible(self.WidgetManageShare, false)
        Event.Dispatch(EventType.OnEndBatchDelShareCode)
        return
    end

    UIHelper.ShowConfirm(g_tStrings.STR_SHARE_STATION_DELETE_CONFIRM, function ()
        ShareCodeData.ApplyDelDataList(ShareStationData.bIsLogin, self.nDataType, ShareStationData.tDelShare)
        Event.Dispatch(EventType.OnEndBatchDelShareCode)
    end, function ()
        Event.Dispatch(EventType.OnEndBatchDelShareCode)
    end)
end

return UIShareStationLeftList