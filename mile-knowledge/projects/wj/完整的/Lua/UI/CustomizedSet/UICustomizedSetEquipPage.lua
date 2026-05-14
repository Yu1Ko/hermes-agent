-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetEquipPage
-- Date: 2024-07-15 14:54:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetEquipPage = class("UICustomizedSetEquipPage")

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
    FORCE_TYPE.WU_XIANG,
}

local function CheckEquipLegal(tEquipInfo)

    --唯一装备
    if tEquipInfo and tEquipInfo.item and tEquipInfo.item.nMaxExistAmount == 1 then
        local bHasSameEquip = false
        local tAllEquip = EquipCodeData.tCurEquip or {}
        for _, v in pairs(tAllEquip) do
            if v.tEquip and v.tEquip.dwTabType == tEquipInfo.dwTabType and v.tEquip.dwIndex == tEquipInfo.dwIndex and v.tEquip.item.nMaxExistAmount == 1 then
                bHasSameEquip = true
                break
            end
        end
        if bHasSameEquip then
            TipsHelper.ShowNormalTip("该装备为唯一装备，仅能装备一件")
            return false
        end
    end
    return true
end

function UICustomizedSetEquipPage:OnEnter(nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self:InitFilter()
    end

    self.nType = nType
    self:UpdateInfo()
end

function UICustomizedSetEquipPage:OnExit()
    self.bInit = false
end

function UICustomizedSetEquipPage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function()
        local _, scriptFilter = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.TOP_CENTER, FilterDef.CustomizedSetEquipType)
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

function UICustomizedSetEquipPage:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSetEquipFilterItemCell, function (nFilterType, nID)
        local dwOldKungfuID = EquipCodeData.dwCurKungfuID
        if nFilterType == 1 then
            EquipCodeData.dwCurForceID = nID
            EquipCodeData.dwCurKungfuID = nil
            self:UpdateFilter()
        elseif nFilterType == 2 then
            EquipCodeData.dwCurKungfuID = nID
            self:UpdateXinFaFilter()
        end
        self:UpdateListInfo()
        self:ClearSelect()

        if dwOldKungfuID ~= EquipCodeData.dwCurKungfuID then
            EquipCodeData.CreateNewSet()
        end
    end)

    Event.Reg(self, EventType.OnSelectedEquipCompareToggle, function (tbInfo)
        if not CheckEquipLegal(tbInfo) then
            return
        end
        self.dwTabType = tbInfo and tbInfo.dwTabType
        self.dwIndex = tbInfo and tbInfo.dwIndex
        self.tbSelectedInfo = tbInfo
        self:UpdateItemTips()
    end)

    Event.Reg(self, EventType.OnUpdateCustomizedSetEquipList, function(nType)
        if not nType then
            self:UpdateListInfo()
        end
    end)

    Event.Reg(self, EventType.OnUpdateCustomizedSetEquipFilter, function()
        self:UpdateFilter()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.CustomizedSetEquipType.Key then
            self:UpdateFilter()
            self:UpdateListInfo()
        end
    end)
end

function UICustomizedSetEquipPage:InitFilter()
    if not EquipCodeData.dwCurForceID or not EquipCodeData.dwCurKungfuID then
        EquipCodeData.dwCurForceID = PlayerData.GetPlayerForceID(nil, true)
        EquipCodeData.dwCurKungfuID = PlayerData.GetPlayerMountKungfuID()
    end

    self:UpdateFilter()
end

function UICustomizedSetEquipPage:UpdateFilter()
    local tbFilterConfig = FilterDef.CustomizedSetEquipType.GetRunTime()
    if tbFilterConfig and tbFilterConfig[1][1] ~= 1 then
        UIHelper.SetVisible(self.ImgFilterNormal, false)
        UIHelper.SetVisible(self.ImgFiltered, true)
    else
        UIHelper.SetVisible(self.ImgFilterNormal, true)
        UIHelper.SetVisible(self.ImgFiltered, false)
    end

    self:UpdateSchoolFilter()
    self:UpdateXinFaFilter()
end
function UICustomizedSetEquipPage:UpdateSchoolFilter()
    UIHelper.RemoveAllChildren(self.ScrollViewSchoolList)
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupSchoolList)
    for _, dwForceID in ipairs(tKungFuIDOrder) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSchoolXinFaFilterItem, self.ScrollViewSchoolList)
        cell:OnEnter(1, dwForceID)
        UIHelper.ToggleGroupAddToggle(self.TogGroupSchoolList, cell.TogType)
    end

    local nIndex = table.get_key(tKungFuIDOrder, EquipCodeData.dwCurForceID)
    UIHelper.SetToggleGroupSelected(self.TogGroupSchoolList,  nIndex - 1)

    local dwBelongSchoolID = Table_ForceToSchool(EquipCodeData.dwCurForceID)
    local szSchoolName     = Table_GetSkillSchoolName(dwBelongSchoolID, true)
    UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[EquipCodeData.dwCurForceID] or "")
    UIHelper.SetString(self.LabelSchoolName1, szSchoolName or "")
    UIHelper.SetString(self.LabelSchoolName2, szSchoolName or "")

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSchoolList)
    UIHelper.SetTouchDownHideTips(self.ScrollViewSchoolList, false)
end

function UICustomizedSetEquipPage:UpdateXinFaFilter()
    UIHelper.RemoveAllChildren(self.WidgetXinFaFilterList)
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupXinFaList)

    local tKungFuList = ForceIDToKungfuIDs(EquipCodeData.dwCurForceID)
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
            if not EquipCodeData.dwCurKungfuID then
                EquipCodeData.dwCurKungfuID = nHDSkillID
            end

            if EquipCodeData.dwCurKungfuID == nHDSkillID then
                nSelectIndex = i
            end

            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSchoolXinFaFilterItem, self.WidgetXinFaFilterList)
            cell:OnEnter(2, nHDSkillID)
            UIHelper.ToggleGroupAddToggle(self.TogGroupXinFaList, cell.TogType)
        end
    end

    UIHelper.SetToggleGroupSelected(self.TogGroupXinFaList,  nSelectIndex - 1)

    local nKungfuID = TabHelper.GetMobileKungfuID(EquipCodeData.dwCurKungfuID)
    local tSkillInfo = TabHelper.GetUISkill(nKungfuID)

    UIHelper.SetSpriteFrame(self.ImgXinFa, PlayerKungfuImg[EquipCodeData.dwCurKungfuID] or "")
    UIHelper.SetString(self.LabelXinFaName1, tSkillInfo and tSkillInfo.szName or "")
    UIHelper.SetString(self.LabelXinFaName2, tSkillInfo and tSkillInfo.szName or "")
end

function UICustomizedSetEquipPage:UpdateInfo()
    self:UpdateListInfo()
end

local function SortRecommendEquipFunc(a, b)
    if a.item.nBaseScore ~= b.item.nBaseScore then
        return a.item.nBaseScore > b.item.nBaseScore
    elseif a.dwIndex ~= b.dwIndex then
        return a.dwIndex < b.dwIndex
    else
        return false
    end
end

function UICustomizedSetEquipPage:UpdateListInfo()
    local player = PlayerData.GetClientPlayer()
    if not player then
        UIMgr.Close(self)
        return
    end

    Event.Dispatch(EventType.OnSelectedEquipCompareToggle, nil)

    local nEquipUsageFilterType = -1
    local tbFilterConfig = FilterDef.CustomizedSetEquipType.GetRunTime()
    if tbFilterConfig then
        if tbFilterConfig[1][1] == 1 then
            -- 全部
            nEquipUsageFilterType = -1
        elseif tbFilterConfig[1][1] == 2 then
            -- 竞技对抗
            nEquipUsageFilterType = 0
        elseif tbFilterConfig[1][1] == 3 then
            -- 秘境挑战
            nEquipUsageFilterType = 1
        elseif tbFilterConfig[1][1] == 4 then
            -- 休闲
            nEquipUsageFilterType = 2
        end
    end

    self.tbRecommendEquips = Table_GetAllRecommendEquipInfo(EquipCodeData.dwCurKungfuID)
    local tbEquipInfo = {}
    for _, tbInfo in ipairs(self.tbRecommendEquips) do
        local nBox, nPos = ItemData.GetEquipItemEquiped(player, tbInfo.itemInfo.nSub, tbInfo.itemInfo.nDetail)
        if nPos == self.nType then
            if nEquipUsageFilterType == -1 or (tbInfo.tbConfig and (nEquipUsageFilterType == tbInfo.tbConfig.nEquipUsage or EQUIPMENT_USAGE_TYPE.IS_GENERAL_EQUIP == tbInfo.tbConfig.nEquipUsage)) then
                table.insert(tbEquipInfo, {
                    item = tbInfo.itemInfo,
                    tbConfig = tbInfo.tbConfig,
                    dwTabType = tbInfo.tbConfig.dwTabType,
                    dwIndex = tbInfo.tbConfig.dwIndex,
                })
            end

        elseif nPos == EQUIPMENT_INVENTORY.LEFT_RING or nPos == EQUIPMENT_INVENTORY.RIGHT_RING then
            if EQUIPMENT_INVENTORY.RIGHT_RING == self.nType or EQUIPMENT_INVENTORY.LEFT_RING == self.nType then
                if nEquipUsageFilterType == -1 or (tbInfo.tbConfig and (nEquipUsageFilterType == tbInfo.tbConfig.nEquipUsage or EQUIPMENT_USAGE_TYPE.IS_GENERAL_EQUIP == tbInfo.tbConfig.nEquipUsage)) then
                    table.insert(tbEquipInfo, {
                        item = tbInfo.itemInfo,
                        tbConfig = tbInfo.tbConfig,
                        dwTabType = tbInfo.tbConfig.dwTabType,
                        dwIndex = tbInfo.tbConfig.dwIndex,
                    })
                end
            end
        end
    end

    UIHelper.HideAllChildren(self.ScrollViewEquipList)
    table.sort(tbEquipInfo, SortRecommendEquipFunc)

    self.tbShellCells = self.tbShellCells or {}
    self.tbCells = self.tbCells or {}

    for _, cell in ipairs(self.tbCells) do
        UIHelper.SetVisible(cell._rootNode, false)
    end

    for i, tbInfo in ipairs(tbEquipInfo) do
        local nShellIndex = math.ceil(i / 2)
        local nShellSubIndex = (i + 1) % 2 + 1
        if not self.tbShellCells[nShellIndex] then
            self.tbShellCells[nShellIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomEquipDoubleCell, self.ScrollViewEquipList)
        end

        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipCompareItemCell, self.tbShellCells[nShellIndex].tbWidgetShell[nShellSubIndex])
        end

        UIHelper.SetVisible(self.tbShellCells[nShellIndex]._rootNode, true)
        UIHelper.SetVisible(self.tbCells[i]._rootNode, true)
        self.tbCells[i]:OnInit(tbInfo, false)
        self.tbCells[i]:HideRecommend()
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewEquipList)
end

function UICustomizedSetEquipPage:UpdateItemTips()
    if not self.scriptItemTip then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTips)
        self.scriptItemTip:SetPlayerID(PlayerData.GetPlayerID())
        self.scriptItemTip:SetForbidShowEquipCompareBtn(true)
        self.scriptItemTip:SetForbidAutoShortTip(true)
        UIHelper.SetAnchorPoint(self.scriptItemTip._rootNode, 0, 1)
        UIHelper.SetPositionY(self.scriptItemTip._rootNode, 0)
    end
    if not self.dwTabType then
        UIHelper.SetVisible(self.WidgetItemTips, false)
    else
        UIHelper.SetVisible(self.WidgetItemTips, true)
        self.scriptItemTip:SetScrollGuildArrowType(2)

        local tbButton = {}
        -- if OutFitPreviewData.CanPreview(self.dwTabType, self.dwIndex) then
        --     local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(self.dwTabType, self.dwIndex)
        --     if not table.is_empty(tbPreviewBtn) then
        --         table.insert(tbButton, tbPreviewBtn[1])
        --     end
        -- end

        local tbCurData = EquipCodeData.GetCustomizedSetEquip(self.nType)
        local tPowerUpInfo = EquipCodeData.GetCustomizedSetEquipPowerUpInfo(self.nType)
        if tbCurData and tbCurData.dwTabType == self.dwTabType and tbCurData.dwIndex == self.dwIndex then
            table.insert(tbButton, {
                szName = "卸下",
                OnClick = function()
                    EquipCodeData.SetCustomizedSetEquip(self.nType, nil)
                    self:ClearSelect()
                end
            })
        -- else
        --     table.insert(tbButton, {
        --         szName = "选择",
        --         OnClick = function()
        --             EquipCodeData.SetCustomizedSetEquip(self.nType, self.tbSelectedInfo)
        --         end
        --     })
        end

        self.scriptItemTip:SetFunctionButtons(tbButton)
        self.scriptItemTip:SetPlayerID(0)
        self.scriptItemTip:SetCustomizedSetEquipPowerUpInfo(tPowerUpInfo)
        self.scriptItemTip:OnInitWithTabID(self.dwTabType, self.dwIndex)

        EquipCodeData.SetCustomizedSetEquip(self.nType, self.tbSelectedInfo)
    end
end

function UICustomizedSetEquipPage:ClearSelect()
    self.bShowTogSchool = false
    self.bShowTogXinFa = false
    UIHelper.SetSelected(self.TogSchool, false)
    UIHelper.SetSelected(self.TogXinFa, false)

    self.dwTabType = nil
    self.dwIndex = nil
    self:UpdateItemTips()
end


return UICustomizedSetEquipPage