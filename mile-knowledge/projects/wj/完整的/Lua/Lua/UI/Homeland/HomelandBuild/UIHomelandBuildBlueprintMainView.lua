-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintMainView
-- Date: 2023-11-24 16:42:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintMainView = class("UIHomelandBuildBlueprintMainView")

local FilterIndex2CatgIndex = {
    1, 4, 5, 6, 7
}

function UIHomelandBuildBlueprintMainView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        HLLocalBlueprintData.Init()
        HLWebBlueprintData.Init()

        self.tbFilterConfig = Lib.copyTab(FilterDef.HomelandBuildBlueprintType)
        self.tbFilterConfig.Key = FilterDef.HomelandBuildBlueprintType.Key
        self.tbFilterConfig[1].tbDefault[1] = table.get_key(FilterIndex2CatgIndex, HLLocalBlueprintData.nCurCatgIndex)

        self.tbDigitalFilterConfig = Lib.copyTab(FilterDef.HomelandBuildDigitalBlueprintType)
        self.tbDigitalFilterConfig.Key = FilterDef.HomelandBuildDigitalBlueprintType.Key
        self.tbDigitalFilterConfig[1].tbDefault[1] = HLWebBlueprintData.szSelectIndex + 1
        self.tbDigitalFilterConfig[2].tbDefault[1] = HLWebBlueprintData.nSearchType
    end

    self.nCurPage = 1
    self:UpdateInfo()
end

function UIHomelandBuildBlueprintMainView:OnExit()
    self.bInit = false

    HLLocalBlueprintData.UnInit()
    HLWebBlueprintData.UnInit()
end

function UIHomelandBuildBlueprintMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnInput, EventType.OnClick, function(btn)
        local nX,nY = UIHelper.GetWorldPosition(self.BtnInput)
        local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnInput)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper, nX-nSizeW-246, nY+nSizeH+170)
        scriptTips:OnEnter({{
            szName = "导入蓝图码",
            OnClick = function ()
                UIMgr.Close(self)
                UIMgr.Open(VIEW_ID.PanelBluePrintInputPop)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            --     szName = "查看藏品蓝图",
            --     OnClick = function ()

            --         TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            --     end
            -- }, {
                szName = "导入本地蓝图",
                OnClick = function ()
                    UIMgr.Close(self)
                    if Platform.IsWindows() and GetOpenFileName then
                        local szFolder = Homeland_GetExportedBlpFolder() .. "\0"
                        szFolder = string.gsub(szFolder, "\\", "/")

                        local szFile = GetOpenFileName(g_tStrings.STR_HOMELAND_CHOOSE_BLUEPRINT_FILE, g_tStrings.STR_HOMELAND_BLUEPRINT_FILE_NAME ..
        "\0*.blueprint;*.blueprintx*\0\0", szFolder)
                        if not string.is_nil(szFile) then
                            HLBOp_Blueprint.QueryIsGlobalBlueprint(szFile)
                        end
                    else
                        UIMgr.Open(VIEW_ID.PanelBluePrintLocal)
                    end
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
        }, {
            szName = "查看官网",
            OnClick = function ()
                Homeland_VisitWebBlps()
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, })
    end)

    UIHelper.BindUIEvent(self.BtnOutput, EventType.OnClick, function(btn)
        local nX,nY = UIHelper.GetWorldPosition(self.BtnOutput)
        local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnOutput)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper, nX-nSizeW-246, nY+nSizeH+170)
        local tbBtnParams = {{
            szName = "导出本地",
            OnClick = function ()
                if not HLBOp_Check.Check() then
                    return
                end

                UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_EXPORT_LAND_BLUEPRINT_CONFIRM, function ()
                    UIMgr.Close(self)
                    HLBOp_Blueprint.ExportBlueprint(false)
                end)

                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        -- }, {
        --     szName = "保存副本",
        --     OnClick = function ()
        --         TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)

        --     end
        }, {
            szName = "上传官网",
            OnClick = function ()
                local szScreenShotSaveFolder = Homeland_GetExportedBlpFolder() .. "ScreenShot/"
                local szFileName = "HomelandScreenShot"
                CPath.MakeDir(szScreenShotSaveFolder)

                local tTime = TimeToDate(GetCurrentTime())
                local szTime = string.format("%d%02d%02d-%02d%02d%02d", tTime.year, tTime.month, tTime.day, tTime.hour, tTime.minute, tTime.second)
                local szFilePath = szScreenShotSaveFolder .. szFileName .. "_" .. szTime
                szFilePath = Homeland_AdjustFilePath(szFilePath, ".png")

                szFilePath = string.gsub(szFilePath, "\\", "/")
                UIMgr.HideAllLayer()
                Timer.AddFrame(self, 4, function ()
                    UIMgr.Close(self)
                    UIHelper.CaptureScreenToFile(szFilePath, 0.3, function(szFilePath, pRetTexture)
                        UIMgr.ShowAllLayer()
                        UIMgr.Open(VIEW_ID.PanelBluePrintUploadPop, szFilePath, pRetTexture)
                    end)
                end)

                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }, {
            szName = "查看我的",
            OnClick = function ()
                Homeland_VisitWebSelfBlps()
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }}

        if HLBOp_Enter.IsDigitalBlueprint() then
            tbBtnParams = {{
                szName = "保存副本",
                OnClick = function ()
                    if not HLBOp_Enter.IsDigitalBlueprint() then
                        TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_BUILDING_UPLOAD_DIGITAL_BLUEPRINT_ERROR)
                    else
                        HLDigitalBlueprintExportData.Init()
                    end

                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            }, {
                szName = "查看我的",
                OnClick = function ()
                    Homeland_VisitWebSelfBlps()
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                end
            }}
        end

        scriptTips:OnEnter(tbBtnParams)
    end)

    UIHelper.BindUIEvent(self.TogSift, EventType.OnClick, function(btn)
        if self.nCurPage == 1 then
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSift, TipsLayoutDir.BOTTOM_LEFT, self.tbFilterConfig)
        elseif self.nCurPage == 2 then
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSift, TipsLayoutDir.BOTTOM_LEFT, self.tbDigitalFilterConfig)
        end
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function(btn)
        Homeland_VisitWanBaoLouBlpsWeb()
    end)

    for i, tog in ipairs(self.tbTogPage) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function(btn)
            self.nCurPage = i
            if self.nCurPage == 1 then
                HLLocalBlueprintData.szSearchKey = ""
            elseif self.nCurPage == 2 then
                HLWebBlueprintData.szKeyword = ""
            end
            self:UpdateInfo()
        end)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupTabLeft, tog)
    end

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function ()
            local szSearchKey = UIHelper.GetString(self.EditKindSearch)
            if self.nCurPage == 1 then
                HLLocalBlueprintData.szSearchKey = szSearchKey
                HLLocalBlueprintData.UpdateSearchItemList()
                self:UpdateLocalInfo()
            elseif self.nCurPage == 2 then
                HLWebBlueprintData.szKeyword = szSearchKey
                HLWebBlueprintData.ApplySign()
            end
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function ()
            local szSearchKey = UIHelper.GetString(self.EditKindSearch)
            if self.nCurPage == 1 then
                HLLocalBlueprintData.szSearchKey = szSearchKey
                HLLocalBlueprintData.UpdateSearchItemList()
                self:UpdateLocalInfo()
            elseif self.nCurPage == 2 then
                HLWebBlueprintData.szKeyword = szSearchKey
                HLWebBlueprintData.ApplySign()
            end
        end)
    end

end

function UIHomelandBuildBlueprintMainView:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.HomelandBuildBlueprintType.Key then
            local nSelectedIndex = tbSelected[1][1]
            self.tbFilterConfig[1].tbDefault[1] = nSelectedIndex
            UIHelper.SetString(self.EditKindSearch, "")
            HLLocalBlueprintData.nCurCatgIndex = FilterIndex2CatgIndex[nSelectedIndex]
            HLLocalBlueprintData.UpdateCurItemList()
            self:UpdateInfo()
        elseif szKey == FilterDef.HomelandBuildDigitalBlueprintType.Key then
            HLWebBlueprintData.szKeyword = ""
            self.tbDigitalFilterConfig[1].tbDefault[1] = tbSelected[1][1]
            self.tbDigitalFilterConfig[2].tbDefault[1] = tbSelected[2][1]
            HLWebBlueprintData.szSelectIndex = tbSelected[1][1] - 1
            HLWebBlueprintData.nSearchType = tbSelected[2][1]
            HLWebBlueprintData.nPage = 1
            UIHelper.SetString(self.EditKindSearch, "")
            HLWebBlueprintData.ApplySign()
        end
    end)

    Event.Reg(self, EventType.OnUpdateHLWebBlueprintList, function()
        if self.nCurPage == 2 then
            self:UpdateWebInfo()
        end
    end)

    Event.Reg(self, "HOMELANDBUILDING_ON_CLOSE", function ()
		UIMgr.Close(self)
	end)
end

function UIHomelandBuildBlueprintMainView:UpdateInfo()
    UIHelper.SetString(self.EditKindSearch, "")

    if self.nCurPage == 1 then
        HLLocalBlueprintData.szSearchKey = ""
        HLLocalBlueprintData.UpdateSearchItemList()
        self:UpdateLocalInfo()
    elseif self.nCurPage == 2 then
        HLWebBlueprintData.ApplySign()
    end

    local tConfig = Homeland_GetModeConfig(HLBOp_Main.GetBuildMode())
    UIHelper.SetVisible(self.tbTogPage[2], not tConfig.bDesign and not HLBOp_Enter.IsTenant())
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTabLeft)
end

function UIHomelandBuildBlueprintMainView:UpdateLocalInfo()
    local tbList = HLLocalBlueprintData.tCurItemList

    UIHelper.SetString(self.LabelEmpty, "暂无可用的蓝图")
    UIHelper.SetVisible(self.WidgetAnchorEmpty, #tbList <= 0)
    UIHelper.SetVisible(self.BtnBuy, false)
    UIHelper.HideAllChildren(self.ScrollViewBluePrintList)
    self.tbCells = self.tbCells or {}
    for i, tbInfo in ipairs(tbList) do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBlueprintCell, self.ScrollViewBluePrintList)
            UIHelper.SetName(self.tbCells[i]._rootNode, "WidgetBlueprintCell"..i)
        end

        UIHelper.SetVisible(self.tbCells[i]._rootNode, true)
        self.tbCells[i]:OnEnter(tbInfo, true)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBluePrintList)
end

function UIHomelandBuildBlueprintMainView:UpdateWebInfo()
    local tbList = HLWebBlueprintData.tList
    UIHelper.HideAllChildren(self.ScrollViewBluePrintList)

    UIHelper.SetString(self.LabelEmpty, "暂无可用的藏品蓝图")
    UIHelper.SetVisible(self.WidgetAnchorEmpty, #tbList <= 0)
    UIHelper.SetVisible(self.BtnBuy, Platform.IsWindows() or Platform.IsAndroid())
    self.tbCells = self.tbCells or {}
    for i, tbInfo in ipairs(tbList) do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBlueprintCell, self.ScrollViewBluePrintList)
        end

        UIHelper.SetVisible(self.tbCells[i]._rootNode, true)
        self.tbCells[i]:OnEnter(tbInfo, false)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBluePrintList)
end

return UIHomelandBuildBlueprintMainView