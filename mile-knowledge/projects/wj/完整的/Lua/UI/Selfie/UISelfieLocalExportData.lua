-- ---------------------------------------------------------------------------------
-- Author: yuminqian
-- Name: UISelfieLocalExportData
-- Date: 2025-10-21 16:59:28
-- Desc: 幻境云图导入详情界面
-- ---------------------------------------------------------------------------------

local UISelfieLocalExportData = class("UISelfieLocalExportData")

function UISelfieLocalExportData:OnEnter(tData, fnBackExport, OnHideCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self.fnBackExport = fnBackExport
    self.tSelfieTitle = g_tStrings.tSelfieTitle
    self.tSelfieParam = g_tStrings.tSelfieParam
    self.tPlayerTitle = g_tStrings.tPlayerTitle
    self.tPlayerParam = g_tStrings.tPlayerParam
    self.OnHideCallback = OnHideCallback
    self:Hide()
end

function UISelfieLocalExportData:Open(szFileName, bPlayer)
    if not self.bIsOpen then
        self.szFileName = szFileName
        self.bPlayer = bPlayer
        self.tSelfieContent = {}
        self.tPlayerContent = {}
        self:UpdateInfo()
        self:UpdateEdit()
        self.bIsOpen = true
    end
    self:Show()
end

function UISelfieLocalExportData:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.OnHideCallback then
        self.OnHideCallback()
    end
end

function UISelfieLocalExportData:Show()
    self.bIsOpen = true
    UIHelper.SetVisible(self._rootNode , true)
end

function UISelfieLocalExportData:Hide(bForce)
    self.bIsOpen = false
    UIHelper.SetVisible(self._rootNode , false)
    if not bForce and self.fnBackExport then
        self.fnBackExport()
    elseif bForce then 
        if self.OnHideCallback then
            self.OnHideCallback()
        end
    end
end

function UISelfieLocalExportData:IsOpen()
    return self.bIsOpen
end

function UISelfieLocalExportData:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnRightClose, EventType.OnClick, function(btn)
        UIHelper.RemoveAllChildren(self.LayoutData)
        self:Hide()
    end)

    UIHelper.BindUIEvent(self.TogSelfieSetting , EventType.OnClick , function ()
        UIHelper.SetSelected(self.TogPlayerSetting , false)
        self:TogSwitch(false)
    end)

    UIHelper.BindUIEvent(self.TogPlayerSetting , EventType.OnClick , function ()
        UIHelper.SetSelected(self.TogSelfieSetting , false)
        self:TogSwitch(true)
    end)

    UIHelper.BindUIEvent(self.BtnApplication, EventType.OnClick, function(btn)
        local pPlayer = GetClientPlayer()
        if not pPlayer then
            return
        end
        local bIsPortrait = UIHelper.GetScreenPortrait()
        local bSucc, szMsg
        bSucc, szMsg = SelfieTemplateBase.ExportData(self.szFileName, self.tData, Player_GetRoleType(pPlayer), bIsPortrait)
        if not bSucc and szMsg then
            TipsHelper.ShowNormalTip(szMsg)
        end
        self:Hide(true)
    end)
end

function UISelfieLocalExportData:TogSwitch(bPlayer)
    local bPlayer = bPlayer or false
    for _, cell in pairs(self.tSelfieContent) do
        cell:Show(not bPlayer)
    end
    for _, cell in pairs(self.tPlayerContent) do
        cell:Show(bPlayer)
    end

    UIHelper.LayoutDoLayout(self.LayoutData)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewData)
end

function UISelfieLocalExportData:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieLocalExportData:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ������
-- ----------------------------------------------------------

function UISelfieLocalExportData:UpdateInfo()
    self:UpdateData()
    self:UpdatePlayerParam()
    self:UpdateSelfieParam()
    self:TogSwitch(self.bPlayer)
    UIHelper.SetSelected(self.TogSelfieSetting , not self.bPlayer)
    UIHelper.SetSelected(self.TogPlayerSetting , self.bPlayer)
end

function UISelfieLocalExportData:UpdateSelfieParam()
    local tTitle = {
        [1] = "tBase",
        [2] = "tWind",
        [3] = "tLight",
        [4] = "tFilter",
    }

    for _, szTitle in ipairs(tTitle) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataContent, self.LayoutData)
        self.tSelfieContent[szTitle] = cell   
        cell:OnEnter(szTitle)
    end
    UIHelper.LayoutDoLayout(self.LayoutData)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewData)
end

function UISelfieLocalExportData:UpdatePlayerParam()
    local tTitle = {
        [1] = "tAction",
        [2] = "tFaceAction",
        [3] = "tExterior",
        [4] = "tPendant",
        [5] = "tSFXPendant",
        [6] = "tFace",
        [7] = "tBody",
    }

    for _, szTitle in pairs(tTitle) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataContent, self.LayoutData)
        self.tPlayerContent[szTitle] = cell   
        -- cell:OnEnter(szTitle)

        if self.tExteriorType[szTitle] then
            cell:OnEnter(szTitle, self.tItemInfo, self.tExteriorType[szTitle], self.tExteriorAll, self.tExteriorAll)
        else
            cell:OnEnter(szTitle, nil, nil, self.tData.tPlayerParam[szTitle], self.tExteriorAll)
        end

    end

    UIHelper.LayoutDoLayout(self.LayoutData)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewData)
end


function UISelfieLocalExportData:UpdateData()
    self.tExteriorAll = self.tData.tPlayerParam.tExterior
    if not self.tExteriorType then
        self:UpdateExteriorTypeList()
    end
    if not self.tItemInfo then
        self:UpdateItemInfo()
    end
end

function UISelfieLocalExportData:UpdateExteriorTypeList()
    self.tExteriorType = {
        ["tPendant"] = {},
        ["tSFXPendant"] = {},
        ["tExterior"] = {},
    }
    if self.tExteriorAll and not IsTableEmpty(self.tExteriorAll) then
        local tExteriorID = self.tExteriorAll.tExteriorID
        if not tExteriorID then
            return
        end
        for nResSub, v in pairs(g_tStrings.tPlayerParam) do
            local dwID = tExteriorID[nResSub]
            if dwID and dwID > 0 then
                if SelfieTemplateBase.IsSelfiePendant(nResSub) or nResSub == EQUIPMENT_REPRESENT.PENDENT_PET_STYLE then
                    self.tExteriorType.tPendant[nResSub] = dwID
                elseif SelfieTemplateBase.IsSelfieSFXPendant(nResSub) then
                    self.tExteriorType.tSFXPendant[nResSub] = dwID
                else
                    self.tExteriorType.tExterior[nResSub] = dwID
                end
            end

        end
    end
end

function UISelfieLocalExportData:UpdateItemInfo()
    self.tItemInfo = {}

    if not IsTableEmpty(self.tExteriorAll) then
        local tSort = ShareExteriorData.GetSortDataByExteriorData(self.tExteriorAll)
        for nSort = 1, 5 do
            local tList = tSort[nSort]
            for _, tInfo in ipairs(tList) do
                self.tItemInfo[tInfo.nSub] = tInfo
            end
        end
    end
end

function UISelfieLocalExportData:UpdateEdit()
    if not string.is_nil(self.szFileName) then
        UIHelper.SetButtonState(self.BtnApplication, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnApplication, BTN_STATE.Disable, "请先输入文件名")
    end
end

return UISelfieLocalExportData