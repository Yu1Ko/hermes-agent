-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIBuildFacePreviewCell
-- Date: 2024-04-10 20:31:55
-- Desc: 创角捏脸预览左侧子节点
-- ---------------------------------------------------------------------------------

local UIBuildFacePreviewCell = class("UIBuildFacePreviewCell")

function UIBuildFacePreviewCell:OnEnter(nPageType , nIndex , tbInfo, fnSelectCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nPageType = nPageType
    self.nIndex = nIndex
    self.tbInfo = tbInfo
    self.fnSelectCallback = fnSelectCallback
    self:UpdateInfo()
end

function UIBuildFacePreviewCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBuildFacePreviewCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect , EventType.OnClick , function ()
        if self.bSelected then
            return
        end

        if GetTickCount() - (BuildPresetData.nToggleClickTime or 0) < 1000 then
            TipsHelper.ShowNormalTip(g_tStrings.AuctionString.STR_CD_ERROR)
            return
        end
        BuildPresetData.nToggleClickTime = GetTickCount()
        self:OnInvokeSelect(not self.bSelected)
        Event.Dispatch(EventType.OnBuildFacePresetToggleSelect , self.nPageType , self.nIndex)
    end)

    Event.Reg(self, EventType.OnBuildFacePresetToggleSelect , function (nPageType , nIndex , bAllFlag)
        if nPageType == self.nPageType then
            if self.bSelected or bAllFlag then
                self:UpdateToggleSelect(nIndex == self.nIndex)
            end
        end
    end)
end

function UIBuildFacePreviewCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBuildFacePreviewCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBuildFacePreviewCell:UpdateInfo()
    local bShowIcon = false
    if self.nPageType == BuildPresetData.PageType.FACE then
        if self.tbInfo.tbData.dwIconID and self.tbInfo.tbData.dwIconID > 0 then
            UIHelper.SetItemIconByIconID(self.ImgIcon, self.tbInfo.tbData.dwIconID)
            bShowIcon = true
        end
    else

        local szIocnPath = self.tbInfo.tbData and self.tbInfo.tbData.szIconPath or self.tbInfo.szIconPath
        UIHelper.SetTexture(self.ImgIcon, szIocnPath)
        bShowIcon = true
    end

    UIHelper.SetVisible(self.ImgIcon, bShowIcon)

    local szFramePath = self.tbInfo.tbData and self.tbInfo.tbData.szFrameIconPath or self.tbInfo.szFrameIconPath
    if szFramePath then
        UIHelper.SetTexture(self.ImgFrame, szFramePath)
    end
    self:UpdateToggleSelect(false)

    UIHelper.SetVisible(self.WidgetTestOnly , self.nPageType == BuildPresetData.PageType.Clothes and self.nIndex > 1)

    if self.nPageType == BuildPresetData.PageType.DEFAULT then
        self:SetGetDesc(self.tbInfo.szGetDesc)
    end
end

function UIBuildFacePreviewCell:OnInvokeSelect(bSelected)
    self:UpdateToggleSelect(bSelected)
    if self.fnSelectCallback then
        self.fnSelectCallback(self.tbInfo and self.tbInfo.nType or self.nPageType , self.nIndex , self , bSelected)
    end
end

function UIBuildFacePreviewCell:UpdateToggleSelect(bSelected)
    self.bSelected = bSelected
    --if not bSelected then
        --UIHelper.SetVisible(self.WidgetDownloadShell , false)
    --end
    UIHelper.SetSelected(self.ToggleSelect , bSelected)
    UIHelper.SetVisible(self.WidgetSelectBG , bSelected)

end

function UIBuildFacePreviewCell:SetGetDesc(szGetDesc)
    UIHelper.SetVisible(self.WidgetWays , not AppReviewMgr.IsReview())
    --UIHelper.SetString(self.LabelGetWays, szGetDesc)

    UIHelper.SetSpriteFrame(self.ImgWays , szGetDesc)
end



return UIBuildFacePreviewCell