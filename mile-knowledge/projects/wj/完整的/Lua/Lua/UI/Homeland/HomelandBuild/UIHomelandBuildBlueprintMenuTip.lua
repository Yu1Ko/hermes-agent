-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintMenuTip
-- Date: 2023-06-06 10:26:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintMenuTip = class("UIHomelandBuildBlueprintMenuTip")

function UIHomelandBuildBlueprintMenuTip:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildBlueprintMenuTip:OnExit()
    self.bInit = false
end

function UIHomelandBuildBlueprintMenuTip:BindUIEvent()
    -- 查看官网
    UIHelper.BindUIEvent(self.BtnOper1, EventType.OnClick, function ()
        Homeland_VisitWebBlps()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetConstructBluePrintTip)
    end)

    -- 官网导入
    UIHelper.BindUIEvent(self.BtnOper2, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelBluePrintInputPop)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetConstructBluePrintTip)
    end)

    -- 本地导入
    UIHelper.BindUIEvent(self.BtnOper3, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelBluePrintLocal)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetConstructBluePrintTip)
    end)

    -- 查看我的
    UIHelper.BindUIEvent(self.BtnOper4, EventType.OnClick, function ()
        self:GotoMyBlueprint()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetConstructBluePrintTip)
    end)

    -- 上传官网
    UIHelper.BindUIEvent(self.BtnOper5, EventType.OnClick, function ()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetConstructBluePrintTip)

        local szScreenShotSaveFolder = Homeland_GetExportedBlpFolder() .. "ScreenShot/"
        local szFileName = "HomelandScreenShot"
        CPath.MakeDir(szScreenShotSaveFolder)

        local tTime = TimeToDate(GetCurrentTime())
        local szTime = string.format("%d%02d%02d-%02d%02d%02d", tTime.year, tTime.month, tTime.day, tTime.hour, tTime.minute, tTime.second)
        local szFilePath = szScreenShotSaveFolder .. szFileName .. "_" .. szTime
        szFilePath = Homeland_AdjustFilePath(szFilePath, ".png")

        UIMgr.HideAllLayer()
        Timer.AddFrame(self, 4, function ()
            UIHelper.CaptureScreenToFile(szFilePath, 0.3, function(szFilePath, pRetTexture)
                UIMgr.ShowAllLayer()
                UIMgr.Open(VIEW_ID.PanelBluePrintUploadPop, szFilePath, pRetTexture)
            end)
        end)
    end)

    -- 导出本地
    UIHelper.BindUIEvent(self.BtnOper6, EventType.OnClick, function ()
        if not HLBOp_Check.Check() then
			return
		end

        UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_EXPORT_LAND_BLUEPRINT_CONFIRM, function ()
            HLBOp_Blueprint.ExportBlueprint(false)
        end)

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetConstructBluePrintTip)
    end)
end

function UIHomelandBuildBlueprintMenuTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildBlueprintMenuTip:UpdateInfo()

end

function UIHomelandBuildBlueprintMenuTip:GotoMyBlueprint()
    local nUrlID
    if IsDebugClient() or IsVersionExp() then
        nUrlID = WEBURL_ID.SELF_BLUEPRINT_TEST
    else
        nUrlID = WEBURL_ID.SELF_BLUEPRINT
    end

    local tInfo
    local nCount = g_tTable.WebUrlData:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.WebUrlData:GetRow(i)
        if tLine.dwID == nUrlID then
            tInfo = tLine
            break
        end
    end

    if tInfo and tInfo.szUrl then
        UIHelper.OpenWebWithDefaultBrowser(tInfo.szUrl)
    end
end

return UIHomelandBuildBlueprintMenuTip