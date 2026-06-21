-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintCell
-- Date: 2023-11-27 16:04:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintCell = class("UIHomelandBuildBlueprintCell")

function UIHomelandBuildBlueprintCell:OnEnter(tbInfo, bIsLocal)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self.bIsLocal = bIsLocal
    self:UpdateInfo()
end

function UIHomelandBuildBlueprintCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildBlueprintCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBlurPrintCell, EventType.OnClick, function(btn)
        if self.bIsLocal then
            local dialog = UIHelper.ShowConfirm(g_tStrings.STR_HOMELAND_LOAD_LAND_BLUEPRINT_CONFIRM, function ()
                HLBOp_Blueprint.LoadUIFileBlueprint(self.tbInfo.szFilepath)
                UIMgr.Close(VIEW_ID.PanelBluePrintManagePop)
            end)

            dialog:SetButtonContent("Confirm", g_tStrings.STR_HOMELAND_LOAD_LAND_BLUEPRINT_SURE)
        else
            UIMgr.Open(VIEW_ID.PanelBlueprintVersionPop, self.tbInfo)
        end
    end)
end

function UIHomelandBuildBlueprintCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildBlueprintCell:UpdateInfo()
    if self.bIsLocal then
        self:UpdateLocalInfo()
    else
        self:UpdateWebInfo()
    end
end

function UIHomelandBuildBlueprintCell:UpdateLocalInfo()
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(self.tbInfo.szName))
    UIHelper.SetString(self.LabelAuthor, UIHelper.GBKToUTF8(self.tbInfo.szAuthor))

    UIHelper.SetRichText(self.RichtextLevel, string.format("<color=#95ff95>%d级</c><color=#0fffff></color>", self.tbInfo.nRequiredLevel))

    UIHelper.SetTexture(self.ImgBlueprintBg, UIHelper.FixDXUIImagePath(self.tbInfo.szTipImgPath), false)
    UIHelper.UpdateMask(self.MaskBg)

    local nProgress = GDAPI_GetBlueprintMatchRate(self.tbInfo.nRemoteOffset)
    UIHelper.SetString(self.LabelProcedure, string.format("%d%%实装", nProgress))
    UIHelper.SetProgressBarPercent(self.ImgProcedureBar, nProgress)
    UIHelper.LayoutDoLayout(self.LayoutProcedure)

    UIHelper.SetVisible(self.WidgetUsing, false)
    UIHelper.SetVisible(self.ImgPrivate, self.tbInfo.nCatg == 7)
    UIHelper.SetVisible(self.ImgEstate, self.tbInfo.nCatg ~= 7)
    UIHelper.LayoutDoLayout(self.LayoutUsingStatus)
end

function UIHomelandBuildBlueprintCell:UpdateWebInfo()
    UIHelper.SetString(self.LabelName, self.tbInfo.szTitle)
    UIHelper.SetString(self.LabelAuthor, self.tbInfo.szAuthor)

    UIHelper.SetRichText(self.RichtextLevel, "")

    local szFileName = HLWebBlueprintData.GetPicName(self.tbInfo.szDownloadPic)
    local szLocalFile = Homeland_GetDownloadPath(szFileName)
    UIHelper.ClearTexture(self.ImgBlueprintBg)
    UIHelper.SetTexture(self.ImgBlueprintBg, szLocalFile, false)
    UIHelper.UpdateMask(self.MaskBg)

    local nProgress = self.tbInfo.nMatchRate
    UIHelper.SetString(self.LabelProcedure, string.format("%d%%实装", nProgress))
    UIHelper.SetProgressBarPercent(self.ImgProcedureBar, nProgress)
    UIHelper.LayoutDoLayout(self.LayoutProcedure)

    UIHelper.SetVisible(self.WidgetUsing, self.tbInfo.bInUse)
    UIHelper.SetVisible(self.ImgPrivate, self.tbInfo.eUseMap == 2 or self.tbInfo.eUseMap == 3)
    UIHelper.SetVisible(self.ImgEstate, self.tbInfo.eUseMap == 1 or self.tbInfo.eUseMap == 3)
    UIHelper.LayoutDoLayout(self.LayoutUsingStatus)
end

return UIHomelandBuildBlueprintCell