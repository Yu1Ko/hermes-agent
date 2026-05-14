-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetRecommendPage
-- Date: 2024-08-23 15:45:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetRecommendPage = class("UICustomizedSetRecommendPage")
local MAX_ITEM_COUNT = 30

local tKungFuIDOrder = {
    FORCE_TYPE.CHUN_YANG,
    FORCE_TYPE.QI_XIU,
    FORCE_TYPE.WAN_HUA,
    FORCE_TYPE.TIAN_CE,
    FORCE_TYPE.SHAO_LIN,
    FORCE_TYPE.CANG_JIAN,
    FORCE_TYPE.WU_DU,
    FORCE_TYPE.TANG_MEN,
    FORCE_TYPE.MING_JIAO,
    FORCE_TYPE.GAI_BANG,
    FORCE_TYPE.CANG_YUN,
    FORCE_TYPE.CHANG_GE,
    FORCE_TYPE.BA_DAO,
    FORCE_TYPE.PENG_LAI,
    FORCE_TYPE.LING_XUE,
    FORCE_TYPE.YAN_TIAN,
    FORCE_TYPE.YAO_ZONG,
    FORCE_TYPE.DAO_ZONG,
    FORCE_TYPE.WAN_LING,
    FORCE_TYPE.DUAN_SHI,
    FORCE_TYPE.WU_XIANG
}

local PlayerKungfuPosition2FilterDef = {
    [KUNGFU_POSITION.DPS] = FilterDef.CustomizedSetEquipType_DPS,
    [KUNGFU_POSITION.T] = FilterDef.CustomizedSetEquipType_T,
    [KUNGFU_POSITION.Heal] = FilterDef.CustomizedSetEquipType_Heal,
}

function UICustomizedSetRecommendPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurIndex = 1
    self:InitFilter()
    EquipCodeData.LoginAccount(false)
    self:UpdateInfo()
end

function UICustomizedSetRecommendPage:OnExit()
    self.bInit = false
end

function UICustomizedSetRecommendPage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPreview, EventType.OnClick, function(btn)
        if EquipCodeData.tRecommendEquips and EquipCodeData.tRecommendEquips[self.nCurIndex] then
            local tbSetData = EquipCodeData.tRecommendEquips[self.nCurIndex]
            local tEquip, tInfo, dwForceID, dwKungfuID = EquipCodeData.DoImportEquip(tbSetData, false)
            UIMgr.Open(VIEW_ID.PanelCustomizedSetSharePic, true, tEquip, tInfo, dwForceID, dwKungfuID)
        else
            TipsHelper.ShowNormalTip("请先选择需要预览的配装")
        end
    end)

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function(btn)
        local tbSetData1 = EquipCodeData.tRecommendEquips and EquipCodeData.tRecommendEquips[self.nCurIndex]
        if not tbSetData1 then
            return
        end

        local tEquip, tInfo, dwForceID, dwKungfuID = EquipCodeData.DoImportEquip(tbSetData1, false)
        local tbSetData = EquipCodeData.ExportCustomizedSetEquip(tEquip, dwKungfuID)
        if not tbSetData then
            return
        end

        local hPlayer = GetClientPlayer()
        local bForceLegal = dwForceID == PlayerData.GetPlayerForceID() or (dwForceID == FORCE_TYPE.WU_XIANG and hPlayer.GetSkillLevel(102393) > 0)
        if not bForceLegal then
            TipsHelper.ShowNormalTip("当前配装方案与自身门派不一致或未学习该流派，无法保存")
            return
        end

        UIMgr.Open(VIEW_ID.PanelCustomSetInputPop, dwKungfuID, tbSetData)
    end)

    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function()
        local _, scriptFilter = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.TOP_CENTER, self.curFilterDef)
    end)

    UIHelper.BindUIEvent(self.TogSchool, EventType.OnClick, function()
        self.bShowTogXinFa = false
        self.bShowTogSchool = not self.bShowTogSchool
        UIHelper.SetSelected(self.TogSchool, self.bShowTogSchool)
    end)

    UIHelper.BindUIEvent(self.TogXinFa, EventType.OnClick, function()
        self.bShowTogSchool = false
        self.bShowTogXinFa = not self.bShowTogXinFa
        UIHelper.SetSelected(self.TogXinFa, self.bShowTogXinFa)
    end)
    UIHelper.SetTouchDownHideTips(self.TogSchool, false)
    UIHelper.SetTouchDownHideTips(self.TogXinFa, false)
end

function UICustomizedSetRecommendPage:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, EventType.OnEquipCodeRsp, function (szKey, tInfo)
        if szKey == "LOGIN_ACCOUNT_EQUIPCODE" then
            if EquipCodeData.szSessionID then
                self.bLoginWeb = true
                local dwCurForceID, dwCurKungfuID = self:GetCurForceIDAndKungfuID()
                local dwBelongSchoolID = Table_ForceToSchool(dwCurForceID)
                local szSchoolName = Table_GetSkillSchoolName(dwBelongSchoolID, true)
                EquipCodeData.ReqGetRecommendEquipList(nil, szSchoolName, dwCurKungfuID, self.nCurTag, 30)
                self:UpdateInfo()
            else
                TipsHelper.ShowNormalTip("连接云端服务器失败，请稍候重试")
                UIMgr.Close(self)
            end
        elseif szKey == "EQUIPS_LIST" then
            if tInfo and tInfo.code and tInfo.code == 1 then
                self:UpdateInfo()
            end
        end
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSetRecommendCell, function (nIndex, tbData, bRoleData)
        if bRoleData then
            return
        end

        self.nCurIndex = nIndex
        self:UpdateEquipAttrInfo()
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSetRecommendCellEnd, function (bRoleData)
        if bRoleData then
            return
        end

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewExpertSetList)
        if EquipCodeData.tRecommendEquips and #EquipCodeData.tRecommendEquips > 4 then
            UIHelper.ScrollLocateToPreviewItem(self.ScrollViewExpertSetList, self.tbSetCells[self.nCurIndex]._rootNode, Locate.TO_CENTER)
        end
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSetEquipFilterItemCell, function (nFilterType, nID)
        local dwOldKungfuID = self.dwCurKungfuID
        if nFilterType == 1 then
            self.dwCurForceID = nID
            self.dwCurKungfuID = nil
        elseif nFilterType == 2 then
            self.dwCurKungfuID = nID
        end
        self:UpdateFilter()

        local dwCurForceID, dwCurKungfuID = self:GetCurForceIDAndKungfuID()
        local dwBelongSchoolID = Table_ForceToSchool(dwCurForceID)
        local szSchoolName = Table_GetSkillSchoolName(dwBelongSchoolID, true)
        EquipCodeData.ReqGetRecommendEquipList(nil, szSchoolName, dwCurKungfuID, self.nCurTag, 30)

        self:ClearSelect()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == self.curFilterDef.Key then
            self:UpdateTagsInfo()
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewExpertSetList)
    end)
end

function UICustomizedSetRecommendPage:InitFilter()
    self.dwCurForceID = FORCE_TYPE.CHUN_YANG
    self.dwCurKungfuID = nil

    local player = PlayerData.GetClientPlayer()
    if player then
        self.dwCurForceID = PlayerData.GetPlayerForceID(player, true)
        self.dwCurKungfuID = PlayerData.GetPlayerMountKungfuID(player)
    end

    self:UpdateFilter()
end

function UICustomizedSetRecommendPage:UpdateInfo()
    self:UpdateSetListInfo()
    self:UpdateEquipAttrInfo()
end

function UICustomizedSetRecommendPage:UpdateFilter()
    local nPosType = PlayerKungfuPosition[self.dwCurKungfuID] or KUNGFU_POSITION.DPS

    self:UpdateSchoolFilter()
    self:UpdateXinFaFilter()
    self:UpdateTagsInfo()
end
function UICustomizedSetRecommendPage:UpdateSchoolFilter()
    UIHelper.RemoveAllChildren(self.ScrollViewSchoolList)
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupSchoolList)
    for _, dwForceID in ipairs(tKungFuIDOrder) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSchoolXinFaFilterItem, self.ScrollViewSchoolList)
        cell:OnEnter(1, dwForceID)
        UIHelper.ToggleGroupAddToggle(self.TogGroupSchoolList, cell.TogType)
    end

    local nIndex = table.get_key(tKungFuIDOrder, self.dwCurForceID)
    UIHelper.SetToggleGroupSelected(self.TogGroupSchoolList,  nIndex - 1)

    local dwBelongSchoolID = Table_ForceToSchool(self.dwCurForceID)
    local szSchoolName     = Table_GetSkillSchoolName(dwBelongSchoolID, true)
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[self.dwCurForceID] or "")
    UIHelper.SetString(self.LabelSchoolName1, szSchoolName or "")
    UIHelper.SetString(self.LabelSchoolName2, szSchoolName or "")

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSchoolList)
    UIHelper.SetTouchDownHideTips(self.ScrollViewSchoolList, false)
end

function UICustomizedSetRecommendPage:UpdateXinFaFilter()
    UIHelper.RemoveAllChildren(self.WidgetXinFaFilterList)
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupXinFaList)

    local tKungFuList = ForceIDToKungfuIDs(self.dwCurForceID)
    -- table.sort(tKungFuList, function(a, b)
    --     local nSkillIDA = a
    --     local nSkillIDB = b
    --     local tbOrderA = TabHelper.GetUISkill(nSkillIDA).tbOrder or { [1] = 99 }
    --     local tbOrderB = TabHelper.GetUISkill(nSkillIDB).tbOrder or { [1] = 99 }
    --     return tbOrderA[1] < tbOrderB[1]  --根据技能类型和order进行相应的排序
    -- end)

    local nSelectIndex = 1
    for i = 1, 2 do
        local nSkillID = tKungFuList[i]
        if nSkillID then
            local nHDSkillID = TabHelper.GetHDKungfuID(nSkillID)
            if not self.dwCurKungfuID then
                self.dwCurKungfuID = nHDSkillID
            end

            if self.dwCurKungfuID == nHDSkillID then
                nSelectIndex = i
            end

            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSchoolXinFaFilterItem, self.WidgetXinFaFilterList)
            cell:OnEnter(2, nHDSkillID)
            UIHelper.ToggleGroupAddToggle(self.TogGroupXinFaList, cell.TogType)
        end
    end

    UIHelper.SetToggleGroupSelected(self.TogGroupXinFaList,  nSelectIndex - 1)

    local nKungfuID = TabHelper.GetMobileKungfuID(self.dwCurKungfuID)
    local tSkillInfo = TabHelper.GetUISkill(nKungfuID)

    UIHelper.SetSpriteFrame(self.ImgXinFa, PlayerKungfuImg[self.dwCurKungfuID] or "")
    UIHelper.SetString(self.LabelXinFaName1, tSkillInfo and tSkillInfo.szName or "")
    UIHelper.SetString(self.LabelXinFaName2, tSkillInfo and tSkillInfo.szName or "")
end

function UICustomizedSetRecommendPage:UpdateSetListInfo()
    UIHelper.HideAllChildren(self.ScrollViewExpertSetList)
    for _, shellCell in pairs(self.tbSetShellCells) do
        for _, widget in pairs(shellCell.tbWidgetShell) do
            UIHelper.SetVisible(widget, false)
        end
    end

    UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Normal)
    if not EquipCodeData.tRecommendEquips or table.is_empty(EquipCodeData.tRecommendEquips) then
        UIHelper.SetVisible(self.WidgetTipsEmpty, true)
        UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Disable)
    else
        UIHelper.SetVisible(self.WidgetTipsEmpty, false)
        self.tbSetShellCells = self.tbSetShellCells or {}
        self.tbSetCells = self.tbSetCells or {}

        for i, tbSetData in ipairs(EquipCodeData.tRecommendEquips) do
            if not self.tbSetCells[i] then
                self.tbSetCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetExpertRecSetItemCellNew, self.ScrollViewExpertSetList)
                UIHelper.ToggleGroupAddToggle(self.TogGroupSetCell, self.tbSetCells[i].TogCell)
            end

            UIHelper.SetVisible(self.tbSetCells[i]._rootNode, true)
            self.tbSetCells[i]:OnEnter(i, tbSetData, false)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewExpertSetList)
end

function UICustomizedSetRecommendPage:UpdateEquipAttrInfo()
    self.scriptEquipAttributePage = self.scriptEquipAttributePage or UIHelper.GetBindScript(self.WidgetAnchorAttri)

    if EquipCodeData.tRecommendEquips and EquipCodeData.tRecommendEquips[self.nCurIndex] then
        local tbSetData = EquipCodeData.tRecommendEquips[self.nCurIndex]
        if tbSetData and not string.is_nil(tbSetData.equips) then
            local dwKungfuID = tonumber(tbSetData.kungfu_id)
            local szKungFu = PlayerKungfuName[dwKungfuID]

            local bPVE = true
            local tbEquipData, szErrMsg = JsonDecode(tbSetData.equips)

            if not string.is_nil(tbSetData.tags) and string.find(tbSetData.tags, "PVP", 1, true) then
                bPVE = false
            end

            local tShowAttr = CalculateKungfuPanel(szKungFu, Lib.copyTab(tbEquipData), bPVE)
            local nTotalScore = CalculateTotalEquipsScore(szKungFu, Lib.copyTab(tbEquipData))
            self.scriptEquipAttributePage:OnEnter(tShowAttr, nTotalScore)
        end
    else
        self.scriptEquipAttributePage:OnEnter({}, 0)
    end
end

function UICustomizedSetRecommendPage:UpdateTagsInfo()
    local dwCurForceID, dwCurKungfuID = self:GetCurForceIDAndKungfuID()
    local nPosType = PlayerKungfuPosition[dwCurKungfuID] or KUNGFU_POSITION.DPS
    local tbTags = PlayerKungfuPosition2EquipTags[nPosType]
    self.curFilterDef = PlayerKungfuPosition2FilterDef[nPosType]

    local tbFilterConfig = self.curFilterDef.GetRunTime()
    if tbFilterConfig and (tbFilterConfig[1][1] ~= 1 or (tbFilterConfig[2] and not table.is_empty(tbFilterConfig[2]))) then
        UIHelper.SetVisible(self.ImgFilterNormal, false)
        UIHelper.SetVisible(self.ImgFiltered, true)
    else
        UIHelper.SetVisible(self.ImgFilterNormal, true)
        UIHelper.SetVisible(self.ImgFiltered, false)
    end

    local szNewTags = self:GetCurTagsString()
    self:SetCurTagsString(szNewTags)

    if not self.nCurTag then
        self:SetCurTagsString(tbTags["Default"])
    end
end

function UICustomizedSetRecommendPage:GetCurTagsString()
    local dwCurForceID, dwCurKungfuID = self:GetCurForceIDAndKungfuID()

    local nPosType = PlayerKungfuPosition[dwCurKungfuID] or KUNGFU_POSITION.DPS
    local tbTags = PlayerKungfuPosition2EquipTags[nPosType]
    local tbFilterConfig = self.curFilterDef.GetRunTime()

    local szTag = ""
    if nPosType == KUNGFU_POSITION.T then
        local tbTag = tbTags[2]
        if tbFilterConfig and tbFilterConfig[1] then
            for _, v in pairs(tbFilterConfig[1]) do
                local szName = tbTag[v]
                if szTag ~= "" then
                    szTag = szTag .. "," .. szName
                else
                    szTag = szName
                end
            end
        end
    else
        for i = 1, 2, 1 do
            local tbTag = tbTags[i]
            if i == 1 then
                if tbFilterConfig and tbFilterConfig[i] and tbFilterConfig[i][1] and tbTag[tbFilterConfig[i][1]] then
                    local szName = tbTag[tbFilterConfig[i][1]]
                    szTag = szName
                end
            elseif i == 2 then
                if tbFilterConfig and tbFilterConfig[i] and tbFilterConfig[i] then
                    for _, v in pairs(tbFilterConfig[i]) do
                        local szName = tbTag[v]
                        if szTag ~= "" then
                            szTag = szTag .. "," .. szName
                        else
                            szTag = szName
                        end
                    end
                end
            end
        end
    end

    return szTag
end

function UICustomizedSetRecommendPage:SetCurTagsString(szTags)
    if szTags == self.nCurTag then
        return
    end

    self.nCurTag = szTags
    if self.bLoginWeb then
        local dwCurForceID, dwCurKungfuID = self:GetCurForceIDAndKungfuID()
        local dwBelongSchoolID = Table_ForceToSchool(dwCurForceID)
        local szSchoolName = Table_GetSkillSchoolName(dwBelongSchoolID, true)
        EquipCodeData.ReqGetRecommendEquipList(nil, szSchoolName, dwCurKungfuID, self.nCurTag, MAX_ITEM_COUNT)
    end
end

function UICustomizedSetRecommendPage:GetCurForceIDAndKungfuID()
    if not self.dwCurForceID then
        self.dwCurForceID = PlayerData.GetPlayerForceID(nil, true)
    end

    if not self.dwCurKungfuID then
        self.dwCurKungfuID = PlayerData.GetPlayerMountKungfuID()
    end

    return self.dwCurForceID, self.dwCurKungfuID
end

function UICustomizedSetRecommendPage:ClearSelect()
    self.bShowTogSchool = false
    self.bShowTogXinFa = false
    UIHelper.SetSelected(self.TogSchool, false)
    UIHelper.SetSelected(self.TogXinFa, false)
end


return UICustomizedSetRecommendPage