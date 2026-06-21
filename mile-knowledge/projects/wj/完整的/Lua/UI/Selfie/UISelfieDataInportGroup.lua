-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfieDataInportGroup
-- Date: 2025-10-23 09:52:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfieDataInportGroup = class("UISelfieDataInportGroup")

local tDefault = {
    ["tAction"] = true,
    ["tFaceAction"] = true,
    ["tFace"] = true,
    ["tBody"] = true,
}

local ITEM_SORT = {
    [1] = "tAll",
    [2] = "tHave", -- 
    [3] = "tBagHave", -- 可交易/不可交易
    [4] = "tCoinShop",
    [5] = "tOther",
}

local nDefaultSort = 1

local SELECT_TYPE =
{
	["tBase"]       = {fnSet=function(tBase) SelfieTemplateBase.SetBaseData(tBase) end, bPlayer = false},
	["tWind"]       = {fnSet=function(tWind) SelfieTemplateBase.SetWindData(tWind) end, bPlayer = false},
	["tLight"]      = {fnSet=function(tLight) SelfieTemplateBase.SetLightData(tLight) end, bPlayer = false},
	["tFilter"]     = {fnSet=function(tFilter) SelfieTemplateBase.SetFilterData(tFilter) end, bPlayer = false}, 

    ["tAction"]     = {fnSet = function(tAction) SelfieTemplateBase.SetActionData(tAction) end, bPlayer = true},
    ["tFaceAction"] = {fnSet = function(tFaceAction) SelfieTemplateBase.SetFaceActionData(tFaceAction) end, bPlayer = true},
    ["tFace"]       = {fnSet = function(tFace) SelfieTemplateBase.SetFaceData(tFace) end, bPlayer = true}, 
    ["tBody"]       = {fnSet = function(tBody) SelfieTemplateBase.SetBodyData(tBody) end, bPlayer = true}, 
    ["tExterior"]   = {fnSet = function(tExterior) SelfieTemplateBase.SetPlayerExteriorRes(tExterior) end, bPlayer = true}, 
    ["tPendant"]    = {fnSet = function(tExterior) SelfieTemplateBase.SetPlayerPendantRes(tExterior) end, bPlayer = true}, 
    ["tSFXPendant"] = {fnSet = function(tExterior) SelfieTemplateBase.SetPlayerSFXPendantRes(tExterior) end, bPlayer = true}, 
}

local PLAY_ACTION_FILE = {
    [3] = true
}

function UISelfieDataInportGroup:OnEnter(szTitle, tItemInfo, tItemList, tGroupData, tSort, bCanUse, fnUseCallBack, fnSelectCallBack)
    if not szTitle then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szTitle = szTitle
    self.tItemInfo = tItemInfo
    self.tItemList = tItemList
    self.tSort = tSort
    self.bDefault = tDefault[szTitle]
    if self.bDefault then
        self.tPlayerParam = tGroupData
        self.tGroupData = self.tPlayerParam[szTitle]
    else
        self.tGroupData = tGroupData
    end
    self.bCanUse = bCanUse or false
    if not SELECT_TYPE[self.szTitle] then
        return
    end
    if fnUseCallBack then
        self.fnUseCallBack = fnUseCallBack
    end
    if fnSelectCallBack then
        self.fnSelectCallBack = fnSelectCallBack
    end
    self.bPlayerTitle = SELECT_TYPE[self.szTitle].bPlayer
    self.bSelfieTitle = not self.bPlayerTitle
    self:UpdateInfo()
end

function UISelfieDataInportGroup:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieDataInportGroup:OnTogTitle(bShow)
    if self.bPlayerTitle then
        if self.bDefault and self.cell then
            self.cell:SetSelectState(bShow, self.bDefault)
        else
            for _, cell in pairs(self.tItemCell) do
                cell:SetSelectState(bShow)
            end
        end
    end
end

function UISelfieDataInportGroup:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTypeTitle, EventType.OnClick , function ()
        local bSelected = UIHelper.GetSelected(self.TogTypeTitle)
        UIHelper.SetVisible(self.ImgCheck , bSelected)
        self:OnTogTitle(bSelected)
        if self.fnSelectCallBack then
            self.fnSelectCallBack(bSelected)
        end

    end)

    UIHelper.BindUIEvent(self.BtnShaiXuan, EventType.OnClick , function ()
        self.bFilter = true
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnShaiXuan, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.PhotoExteriorData)
    end)
    
    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick , function ()
        -- 应用分类
        UIHelper.SetSelected(self.TogTypeTitle, true)
        UIHelper.SetVisible(self.ImgCheck , true)
        self:OnTogTitle(true)
        self:SetGroup()
    end)

    UIHelper.BindUIEvent(self.BtnPlay, EventType.OnClick , function ()
        -- 播放动作
        local pPlayer = GetClientPlayer()
        if not pPlayer then
            return
        end
        if self.szTitle == "tAction" then
            if pPlayer.bOnHorse then -- 马上不能应用动作，暂时
                OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_SELFIE_PHOTO_TITLE_CANNOT_ON_HORSE)
                return
            end
            SelfieTemplateBase.SetActionData(self.tGroupData, 1)
            UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Disable, "请先取消播放")
        elseif self.szTitle == "tFaceAction" then
            self:UseGroupData(self.tGroupData)
            UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Disable, "请先取消播放")
        end
    end)
    
    UIHelper.BindUIEvent(self.BtnCancelPlay, EventType.OnClick , function ()
        -- 取消动作
        if self.szTitle == "tAction" then
            SelfieTemplateBase.CancelPhotoActionDataUse()
            SelfieTemplateBase.SetPlayActionAgainState(false)
            SelfieTemplateBase.SetPhotoActionFreezeState(false)
        elseif self.szTitle == "tFaceAction" then
            SelfieTemplateBase.CancelFaceActionUse()
        end
        UIHelper.SetButtonState(self.BtnPlay, BTN_STATE.Normal)
        UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Normal)
    end)
end

function UISelfieDataInportGroup:RegEvent()

    Event.Reg(self, EventType.OnFinishLinkToFace, function ()
        if (not self.bNeedBuyFace and not self.bNeedBuyBody) or not self.tGroupData or IsTableEmpty(self.tGroupData) then
            return
        end
        Timer.Add(self, 0.5, function ()
            if self.bNeedBuyBody then
                BuildBodyData.tNowBodyData = self.tGroupData
                local nBodyPage = 4
                Event.Dispatch(EventType.OnUpdateBuildBodyModle, nBodyPage)
                self.bNeedBuyBody = nil
                Event.Dispatch(EventType.OnCoinShopClickBuyBtn)
            end
            if self.bNeedBuyFace then
                BuildFaceData.tNowFaceData = self.tGroupData
                Event.Dispatch(EventType.OnUpdateBuildFaceModle)
                self.bNeedBuyFace = nil
                Event.Dispatch(EventType.OnCoinShopClickBuyBtn)
            end
        end)
    end)

    Event.Reg(self, EventType.OnApplyToSetActionByFile, function ()
        if self.szTitle == "tAction" then
            local tAction = clone(self.tGroupData)
            local nType = SelfieTemplateBase.GetActionType(tAction.dwAnimationID)
            if PLAY_ACTION_FILE[nType] then
                tAction.dwAnimationID = 0
                SelfieTemplateBase.SetActionData(tAction)
            else
                SelfieTemplateBase.SetPlayActionAgainState(false)
                OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SELFIE_PHOTO_ACTION_USE_FAILED)
            end
        end
    end)

    Event.Reg(self, EventType.OnFilter, function (szKey, tbSelected)
        local tbFilter = tbSelected[1] -- {1}
        if szKey ~= FilterDef.PhotoExteriorData.Key then
            return 
        end
        if not self.bFilter then
            return
        end
        local nFilter = tbFilter[1]
        self:UpdateExteriorFilterList(nFilter)
        self.bFilter = false
        UIHelper.LayoutDoLayout(self._rootNode)
    end)

    Event.Reg(self, EventType.OnSelfieFrameFreezeState, function(bIsFreeze)
        if self.szTitle ~= "tAction" then
            return
        end
        UIHelper.SetButtonState(self.BtnPlay, bIsFreeze and BTN_STATE.Disable or BTN_STATE.Normal, "请先取消角色定格")
        UIHelper.SetButtonState(self.BtnApply, bIsFreeze and BTN_STATE.Disable or BTN_STATE.Normal, "请先取消角色定格")
        UIHelper.SetButtonState(self.BtnCancelPlay, bIsFreeze and BTN_STATE.Disable or BTN_STATE.Normal, "请先取消角色定格")
    end)
end

function UISelfieDataInportGroup:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UISelfieDataInportGroup:Show(bShow)
    local bShow = bShow or false
    UIHelper.SetVisible(self._rootNode , bShow)
end

function UISelfieDataInportGroup:Hide()
    UIHelper.SetVisible(self._rootNode , false)
end

function UISelfieDataInportGroup:UseGroupData(tData)
    local tFunInfo = SELECT_TYPE[self.szTitle]
    local tData = clone(tData)
    if tFunInfo then
        tFunInfo.fnSet(tData)
    end
    if self:IsActionData() then
        UIHelper.SetButtonState(self.BtnPlay, BTN_STATE.Disable, "请先取消应用")
    end
    if self.fnUseCallBack then
        self.fnUseCallBack() -- 主要是写一些应用的时候需要用到非本group数据的情况
    end
end

function UISelfieDataInportGroup:IsActionData()
    if self.szTitle == "tAction" or self.szTitle == "tFaceAction" then
        return true
    end
    return false
end

function UISelfieDataInportGroup:IsGroupDataSelected()
    local bSelected = UIHelper.GetSelected(self.TogTypeTitle)
    if bSelected then
        return true
    else
        return false
    end
end

-- ----------------------------------------------------------
-- Please write your own code below  ������
-- ----------------------------------------------------------

function UISelfieDataInportGroup:UpdateInfo()
    if self.bSelfieTitle then
        self:UpdateSelfieParam()
    elseif self.bPlayerTitle then 
        self:UpdatePlayerParam()
    end
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UISelfieDataInportGroup:UpdateGroupTogState(bPlayer)
    UIHelper.SetSelected(self.TogTypeTitle, self.bCanUse and not bPlayer)
    UIHelper.SetVisible(self.ImgCheck , self.bCanUse and not bPlayer)
    local szMsg
    if bPlayer then
        szMsg = "体型不一致或角色数据为空，角色参数不可用"
    else
        szMsg = "非移动端数据，幻境云图参数不可用"
    end
    UIHelper.SetCanSelect(self.TogTypeTitle, self.bCanUse, szMsg)
    UIHelper.SetButtonState(self.BtnApply, self.bCanUse and BTN_STATE.Normal or BTN_STATE.Disable, szMsg)
end

function UISelfieDataInportGroup:UpdateSelfieParam()
    UIHelper.SetString(self.LabelTitle, g_tStrings.tSelfieTitle[self.szTitle])
    UIHelper.SetVisible(self.BtnApply , true)
    UIHelper.SetVisible(self.BtnPlay , false)
    UIHelper.SetVisible(self.BtnShaiXuan, false)
    local tParam = g_tStrings.tSelfieParam[self.szTitle]
    
    for i = 1, 2 do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataInportCellLabel, self.LayoutDataInportCellGroup)
        cell:OnEnter(tParam, i)
    end
    self:UpdateGroupTogState()
    UIHelper.LayoutDoLayout(self.LayoutDataInportCellGroup)
    UIHelper.LayoutDoLayout(self.LayoutDataInport)
end

function UISelfieDataInportGroup:UpdatePlayerParam()
    UIHelper.SetString(self.LabelTitle, g_tStrings.tPlayerTitle[self.szTitle])
    UIHelper.SetVisible(self.BtnPlay , self.szTitle == "tAction")
    UIHelper.SetButtonState(self.BtnPlay, self.bCanUse and BTN_STATE.Normal or BTN_STATE.Disable, "体型不一致或角色数据为空，角色参数不可用")
    UIHelper.SetVisible(self.BtnCancelPlay , self:IsActionData())
    UIHelper.SetButtonState(self.BtnCancelPlay, self.bCanUse and BTN_STATE.Normal or BTN_STATE.Disable, "体型不一致或角色数据为空，角色参数不可用")
    self:UpdateGroupTogState(true)
    UIHelper.SetVisible(self.BtnShaiXuan, not self.bDefault)

    if self.bDefault then
        if self.szTitle == "tFaceAction" then
            local tInfo = EmotionData.GetFaceMotion(self.tGroupData.dwFaceMotionID)
            if not tInfo then
                self:UpdateEmptyGroup()
                return
            end
        elseif self.szTitle == "tAction" then
            if self.tGroupData.dwAnimationID <= 0 then
                self:UpdateEmptyGroup()
                return
            end
        end
        self.cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataInportCellItem, self.LayoutDataInportCellGroup)

        local bHave = self:GetDefaultItemHaveState()

        local tInfo = {
            szTitle = self.szTitle,
            bDefault = true,
            bImport = true,
            bHave = bHave,
            bCanUse = self.bCanUse,
        }

        self.cell:OnEnter(tInfo, self.tGroupData, self.tPlayerParam.tExterior.tExteriorID, function () 
            local bSelect = self.cell:GetSelectState() or false
            UIHelper.SetSelected(self.TogTypeTitle , bSelect)
            UIHelper.SetVisible(self.ImgCheck , bSelect)
        end)
    else
        self:UpdateExteriorFilterList()
    end
    if self.szTitle == "tAction" and self.bCanUse then
        UIHelper.SetSelected(self.TogTypeTitle, true)
        UIHelper.SetVisible(self.ImgCheck , true)
        self:OnTogTitle(true)
    end
    UIHelper.LayoutDoLayout(self.LayoutDataInportCellGroup)
    UIHelper.LayoutDoLayout(self.LayoutDataInport)
end

function UISelfieDataInportGroup:UpdateExteriorFilterList(nFilter)
    self.tItemCell = {}
    UIHelper.RemoveAllChildren(self.LayoutDataInportCellGroup)

    local szFilter = nFilter and ITEM_SORT[nFilter]
    local tFilter
    if nFilter and nFilter ~= nDefaultSort then
        tFilter = self.tSort[szFilter]
    end

    for nResSub, v in pairs(self.tItemList) do
        if not nFilter or nFilter == nDefaultSort or tFilter[nResSub] then
            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetDataInportCellItem, self.LayoutDataInportCellGroup)
            local tInfo = {
                szTitle = self.szTitle,
                nResSub = nResSub,
                bDefault = false,
                bImport = true,
                bHave = self.tSort.tHave[nResSub],
                bCanUse = self.bCanUse,
            }
            self.tItemCell[nResSub] = cell   
            cell:OnEnter(tInfo, self.tItemInfo[nResSub], self.tGroupData, function () 
                local bAllSel = true
                local bAllCal = true
                for _, cell in pairs(self.tItemCell) do
                    local bSelect = cell:GetSelectState()
                    if bSelect then
                        bAllCal = false
                    end
                    if not bSelect then
                        bAllSel = false
                    end
                end
                if bAllSel then
                    UIHelper.SetSelected(self.TogTypeTitle , true)
                    UIHelper.SetVisible(self.ImgCheck , true)
                end
                if bAllCal then
                    UIHelper.SetSelected(self.TogTypeTitle , false)
                    UIHelper.SetVisible(self.ImgCheck , false)
                end
            end) 
        end 
    end
    -- if IsTableEmpty(self.tItemCell) then
    --     self:Hide()
    -- end

    UIHelper.LayoutDoLayout(self.LayoutDataInportCellGroup)
    UIHelper.LayoutDoLayout(self.LayoutDataInport)
end

function UISelfieDataInportGroup:GetDefaultItemHaveState()
    local bHave = false 
    if self.szTitle == "tFace" then
        bHave = self:CheckIsHaveFace()
    elseif self.szTitle == "tBody" then
        bHave = self:CheckIsHaveBody()
    elseif self:IsActionData() then
        if self.tGroupData and not IsTableEmpty(self.tGroupData) then
            bHave = (self.tGroupData.dwAnimationID and self.tGroupData.dwAnimationID > 0) or (self.tGroupData.dwFaceMotionID and self.tGroupData.dwFaceMotionID > 0)
        end
    end
    return bHave
end

function UISelfieDataInportGroup:UpdateEmptyGroup()
    UIHelper.SetVisible(self.BtnApply , false)
    UIHelper.SetVisible(self.BtnPlay , false)
    UIHelper.SetVisible(self.BtnShaiXuan, false)
    UIHelper.SetVisible(self.BtnCancelPlay , false)
    -- UIHelper.LayoutDoLayout(self.LayoutDataInport)
    UIHelper.SetCanSelect(self.TogTypeTitle, false, "数据为空，参数不可应用")
    UIHelper.SetVisible(self.LayoutDataInport , false)
end

function UISelfieDataInportGroup:CheckIsHaveBody()
    local tBodyData = self.tGroupData
    if not tBodyData then
        return
    end

    local hManager = GetBodyReshapingManager()
    local bHave, nIndex = hManager.IsAlreadyHave(tBodyData)
    if not bHave or not nIndex then
        return false
    else
        return true
    end
end

function UISelfieDataInportGroup:CheckIsHaveFace()
    local tFaceData = self.tGroupData
    if not tFaceData then
        return
    end

    local hManager = GetFaceLiftManager()
    local bHave, nIndex = hManager.IsAlreadyHave(tFaceData) -- 新老脸型兼容
    if not bHave or not nIndex then
        return false
    else
        return true
    end
end

function UISelfieDataInportGroup:GoBuyBody()
    local script = UIHelper.ShowConfirm("您未拥有该体型数据，请问是否要立刻前往商城购买？", function() -- confirm
        self.bNeedBuyBody = true
        CoinShopData.LinkFace() -- 体型和脸型走一个link流程

        -- 等回调
    end, 
    function() -- cancle
        UIHelper.SetSelected(self.TogTypeTitle, false)
        UIHelper.SetVisible(self.ImgCheck , false)
        self:OnTogTitle(false)
    end)
    script:SetButtonContent("Cancel", "取消")
    script:SetButtonContent("Confirm", "确定")
end

function UISelfieDataInportGroup:GoBuyFace()
    local script = UIHelper.ShowConfirm("您未拥有该脸型数据，请问是否要立刻前往商城购买？", function() -- confirm
        self.bNeedBuyFace = true
        CoinShopData.LinkFace()
        -- 等回调
    end, 
    function() -- cancle
        UIHelper.SetSelected(self.TogTypeTitle, false)
        UIHelper.SetVisible(self.ImgCheck , false)
        self:OnTogTitle(false)
    end)
    script:SetButtonContent("Cancel", "取消")
    script:SetButtonContent("Confirm", "确定")
end

function UISelfieDataInportGroup:SetGroup()
    if self.bSelfieTitle then
        local bSelect = UIHelper.GetVisible(self.ImgCheck)
        if not bSelect then
            return
        end
        self:UseGroupData(self.tGroupData)
    elseif self.bPlayerTitle then 
        if self.bDefault then
            local bSelect = UIHelper.GetVisible(self.ImgCheck)
            if not bSelect then
                return
            end
            if self.szTitle == "tFace" then
                if not self:CheckIsHaveFace() then
                    self:GoBuyFace()
                    return
                end
            elseif self.szTitle == "tBody" then
                if not self:CheckIsHaveBody() then
                    self:GoBuyBody()
                    return
                end
            elseif not self:GetDefaultItemHaveState() then
                return
            elseif self.szTitle == "tAction" or self.szTitle == "tFaceAction" then
                Timer.Add(self, 1, function()
                    self:UseGroupData(self.tGroupData)
                end)
            else
                self:UseGroupData(self.tGroupData)
            end
        else
            local tList = clone(self.tItemList)
            for nResSub, dwID in pairs(tList) do
                local bCollect = self.tSort.tHave[nResSub]
                local bSelected = self.tItemCell[nResSub]:GetSelectState()
                if not bCollect or not bSelected then
                    tList[nResSub] = nil
                end
            end
            local tTrueGroup = clone(self.tGroupData)
            if tTrueGroup and not IsTableEmpty(tTrueGroup) then
                tTrueGroup.tExteriorID = tList
                self:UseGroupData(tTrueGroup)
            end
        end    
    end

end

return UISelfieDataInportGroup