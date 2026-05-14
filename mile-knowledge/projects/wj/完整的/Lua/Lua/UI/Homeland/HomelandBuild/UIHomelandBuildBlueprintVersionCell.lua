-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintVersionCell
-- Date: 2023-11-29 14:45:19
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintVersionCell = class("UIHomelandBuildBlueprintVersionCell")

function UIHomelandBuildBlueprintVersionCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIHomelandBuildBlueprintVersionCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildBlueprintVersionCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBlueprintVersionCell, EventType.OnClick, function(btn)
        if self.tbInfo.bNeedUnloadOther then
            TipsHelper.ShowNormalTip("正在使用其他蓝图，请先卸载后再使用本蓝图")
            return
        end

        if self.tbInfo.bNotExistReplica then
            TipsHelper.ShowNormalTip("暂无该蓝图副本，请先使用默认版本后导出可创建")
            return
        end

        if self.tbInfo.bForbidden then
            return
        end

        local szCode = self.tbInfo.szCode
        if self.tbInfo.szDLCCode then
            local szDLCCode = self.tbInfo.szDLCCode
            Homeland_Log("DownloadDigitalBlp szCode DLC", szDLCCode, szCode)
            GetHomelandMgr().DownloadDigitalBlp(szCode, szDLCCode)
        elseif self.tbInfo.bDefault then
            Homeland_Log("DownloadDigitalBlp szCode 1", szCode)
            GetHomelandMgr().DownloadDigitalBlp(szCode, 1)
        else
            Homeland_Log("DownloadDigitalBlp szCode 2", szCode)
            GetHomelandMgr().DownloadDigitalBlp(szCode, 2)
        end

        UIMgr.Close(VIEW_ID.PanelBlueprintVersionPop)
        UIMgr.Close(VIEW_ID.PanelBluePrintManagePop)
    end)

end

function UIHomelandBuildBlueprintVersionCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildBlueprintVersionCell:UpdateInfo()
    UIHelper.SetVisible(self.ImgBgNormal, true)
    UIHelper.SetVisible(self.ImgBgUsing, false)

    UIHelper.SetString(self.LabelVersionNormal, self.tbInfo.szName)
    UIHelper.SetString(self.LabelVersionUsing, self.tbInfo.szName)
end


return UIHomelandBuildBlueprintVersionCell