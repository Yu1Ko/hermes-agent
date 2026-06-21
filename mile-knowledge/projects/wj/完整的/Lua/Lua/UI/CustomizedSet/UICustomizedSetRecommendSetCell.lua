-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetRecommendSetCell
-- Date: 2024-07-19 15:56:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetRecommendSetCell = class("UICustomizedSetRecommendSetCell")

local EquipType2ParentInfo = {
    -- 头部
    [EQUIPMENT_INVENTORY.HELM] = {"tbWidgetEquip1", 1},
    -- 护腕
    [EQUIPMENT_INVENTORY.BANGLE] = {"tbWidgetEquip1", 4},
    -- 上衣
    [EQUIPMENT_INVENTORY.CHEST] = {"tbWidgetEquip1", 2},
    -- 下装
    [EQUIPMENT_INVENTORY.PANTS] = {"tbWidgetEquip1", 5},
    -- 腰带
    [EQUIPMENT_INVENTORY.WAIST] = {"tbWidgetEquip1", 3},
    -- 鞋子
    [EQUIPMENT_INVENTORY.BOOTS] = {"tbWidgetEquip1", 6},

    -- 项链
    [EQUIPMENT_INVENTORY.AMULET] = {"tbWidgetEquip2", 1},
    -- 腰坠
    [EQUIPMENT_INVENTORY.PENDANT] = {"tbWidgetEquip2", 2},
    -- 戒指
    [EQUIPMENT_INVENTORY.LEFT_RING] = {"tbWidgetEquip2", 3},
    -- 戒指
    [EQUIPMENT_INVENTORY.RIGHT_RING] = {"tbWidgetEquip2", 4},

    -- 普通近战武器
    [EQUIPMENT_INVENTORY.MELEE_WEAPON] = {"tbWidgetWeapon", 1},
    -- 重剑
    [EQUIPMENT_INVENTORY.BIG_SWORD] = {"tbWidgetWeapon", 2},
    -- 远程武器
    [EQUIPMENT_INVENTORY.RANGE_WEAPON] = {"tbWidgetWeapon", 3},
}

local EquipType2Sort = {
    -- 头部
    EQUIPMENT_INVENTORY.HELM,
    -- 护腕
    EQUIPMENT_INVENTORY.BANGLE,
    -- 上衣
    EQUIPMENT_INVENTORY.CHEST,
    -- 下装
    EQUIPMENT_INVENTORY.PANTS,
    -- 腰带
    EQUIPMENT_INVENTORY.WAIST,
    -- 鞋子
    EQUIPMENT_INVENTORY.BOOTS,
    -- 项链
    EQUIPMENT_INVENTORY.AMULET,
    -- 腰坠
    EQUIPMENT_INVENTORY.PENDANT,
    -- 戒指
    EQUIPMENT_INVENTORY.LEFT_RING,
    -- 戒指
    EQUIPMENT_INVENTORY.RIGHT_RING,
    -- 普通近战武器
    EQUIPMENT_INVENTORY.MELEE_WEAPON,
    -- 重剑
    EQUIPMENT_INVENTORY.BIG_SWORD,
    -- 远程武器
    EQUIPMENT_INVENTORY.RANGE_WEAPON,
}

function UICustomizedSetRecommendSetCell:OnEnter(nIndex, tbData, bRoleData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.tbData = tbData
    self.bRoleData = bRoleData
    self.bInitEquipListInfo = false
    self:UpdateInfo()
end

function UICustomizedSetRecommendSetCell:OnExit()
    self.bInit = false
end

function UICustomizedSetRecommendSetCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCell, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnSelectCustomizedSetRecommendCell, self.nIndex, self.tbData, self.bRoleData)
        Event.Dispatch(EventType.OnSelectCustomizedSetRecommendCellEnd, self.bRoleData)
    end)

    UIHelper.BindUIEvent(self.TogCell, EventType.OnSelectChanged, function(btn, bSelected)
        if bSelected then
            self:UpdateEquipListInfo()
        end
    end)
    UIHelper.SetSwallowTouches(self.TogCell, false)
end

function UICustomizedSetRecommendSetCell:RegEvent()
    Event.Reg(self, EventType.OnSelectCustomizedSetRecommendCell, function (nIndex, tbData, bRoleData)
        if bRoleData ~= self.bRoleData then
            return
        end

        UIHelper.LayoutDoLayout(self._rootNode)
    end)

    Event.Reg(self, EventType.OnDoSelectCustomizedSetRecommendCell, function (nIndex, bRoleData)
        if self.nIndex == nIndex and self.bRoleData == bRoleData then
            Event.Dispatch(EventType.OnSelectCustomizedSetRecommendCell, self.nIndex, self.tbData, self.bRoleData)
            Event.Dispatch(EventType.OnSelectCustomizedSetRecommendCellEnd, self.bRoleData)
            self:UpdateEquipListInfo()
        end
    end)
end

function UICustomizedSetRecommendSetCell:UpdateInfo()
    self:UpdateBaseInfo()
    self:UpdateTagsInfo()

    if UIHelper.GetSelected(self.TogCell) then
        self:UpdateEquipListInfo()
    end
end

function UICustomizedSetRecommendSetCell:UpdateBaseInfo()
    local dwForceID = PlayerData.GetPlayerForceID(nil, true)
    if self.tbData.force then
        local dwBelongSchoolID = Table_GetSkillSchoolIDByName(UIHelper.UTF8ToGBK(self.tbData.force))
        dwForceID = Table_SchoolToForce(dwBelongSchoolID)
        -- dwForceID = table.get_key(PlayerForceIDToName, self.tbData.force)
    end

    local dwKungfuID = tonumber(self.tbData.kungfu_id or PlayerData.GetPlayerMountKungfuID())
    local szKungFu = PlayerKungfuName[dwKungfuID]
    local nScore = 0

    if not self.tbData.kungfu_id and self.tbData.kungfu_name then
        dwKungfuID = table.get_key(PlayerKungfuChineseName, self.tbData.kungfu_name)
        szKungFu = PlayerKungfuName[dwKungfuID]
    end

    if not string.is_nil(self.tbData.equips) then
        local tbEquipData, szErrMsg = JsonDecode(self.tbData.equips)
        if not tbEquipData or type(tbEquipData) ~= "table" then
            return
        end

        local bPVE = true
        if not string.is_nil(self.tbData.tags) and string.find(self.tbData.tags, "PVP", 1, true) then
            bPVE = false
        end

        local tShowAttr = CalculateKungfuPanel(szKungFu, Lib.copyTab(tbEquipData), bPVE)
        nScore = CalculateTotalEquipsScore(szKungFu, Lib.copyTab(tbEquipData))

        if tShowAttr then
            self.tbAttrCell = self.tbAttrCell or {}
            for i = 1, 4, 1 do
                if not self.tbAttrCell[i] then
                    self.tbAttrCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetExpertSetAttriCellNew, self.WidgetAttriList)
                end

                local tInfo = tShowAttr[i] or {}
                if tInfo.Percent then
                    self.tbAttrCell[i]:OnEnter(g_tStrings.tAttributeName[tInfo.Key or ""], string.format("%d%%", tInfo.Value))
                else
                    self.tbAttrCell[i]:OnEnter(g_tStrings.tAttributeName[tInfo.Key or ""], tInfo.Value or "")
                end
            end

            UIHelper.LayoutDoLayout(self.WidgetAttriList)
        end
    end


    UIHelper.SetString(self.LabelTitle, self.tbData.title)
    UIHelper.SetString(self.LabelAuthor, self.tbData.role_name)
    UIHelper.SetString(self.LabelRankNum, nScore)
    UIHelper.SetSpriteFrame(self.ImgXinFaIcon, PlayerKungfuImg[dwKungfuID])

    UIHelper.SetVisible(self.WidgetWeaponSecondary, dwForceID == FORCE_TYPE.CANG_JIAN)
    UIHelper.LayoutDoLayout(self.LayoutEquipWeapons)
    UIHelper.LayoutDoLayout(self.LayoutName)
end


function UICustomizedSetRecommendSetCell:UpdateEquipListInfo()
    if not self.bRoleData and self.bInitEquipListInfo then
        return
    end
    self.bInitEquipListInfo = true

    UIHelper.SetTabVisible(self.tbWidgetEquip1, false)
    UIHelper.SetTabVisible(self.tbWidgetEquip2, false)
    UIHelper.SetTabVisible(self.tbWidgetWeapon, false)

    self.tbEquipCells = self.tbEquipCells or {}
    local tbSetData = self.tbData
    local tbImportEquipDatas = EquipCodeData.DoImportEquip(tbSetData, self.bRoleData)

    if not string.is_nil(tbSetData.equips) then
        local tbEquipData, szErrMsg = JsonDecode(tbSetData.equips)
        local tEquips = {}

        for i, tbInfo in pairs(tbEquipData.Equips) do
            table.insert(tEquips, tbInfo)
        end

        table.sort(tEquips, function(a, b)
            local nPosTypeA = tonumber(a.UcPos)
            local nPosTypeB = tonumber(b.UcPos)

            local nSortIndexA = table.get_key(EquipType2Sort, nPosTypeA)
            local nSortIndexB = table.get_key(EquipType2Sort, nPosTypeB)

            return nSortIndexA < nSortIndexB
        end)

        for i, tbInfo in ipairs(tEquips) do
            local nIndex = i
            local nPosType = tonumber(tbInfo.UcPos)
            local nTabID = tonumber(tbInfo.ID)

            local nStrengthLevel = tonumber(tbInfo.StrengthLevel) or 0
            local nMaxStrengthLevel = tonumber(tbInfo.MaxStrengthLevel) or 0

            local tbParentInfo = EquipType2ParentInfo[nPosType]
            if not self.tbEquipCells[nIndex] then
                self.tbEquipCells[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self[tbParentInfo[1]][tbParentInfo[2]])
                self.tbEquipCells[nIndex]:SetClickNotSelected(true)
            end

            UIHelper.SetVisible(self[tbParentInfo[1]][tbParentInfo[2]], true)
            self.tbEquipCells[nIndex]:OnInitWithTabID(EquipType2ItemType[nPosType], nTabID)
            self.tbEquipCells[nIndex]:SetClickCallback(function(nItemType, nItemIndex)
                Timer.AddFrame(self, 1, function()
                    local tbImportEquipData = tbImportEquipDatas[nPosType] or {}
                    local tPowerUpInfo = tbImportEquipData.tPowerUpInfo or {}
                    local _, scriptItemTip = TipsHelper.ShowItemTips(self.tbEquipCells[nIndex]._rootNode, EquipType2ItemType[nPosType], nTabID, false)
                    -- UIMgr.AddPrefab(PREFAB_ID.WidgetTouchBackGround, scriptItemTip._rootNode, true, scriptItemTip)
                    scriptItemTip:SetPlayerID(0)
                    scriptItemTip:SetCustomizedSetEquipPowerUpInfo(tPowerUpInfo)
                    scriptItemTip:OnInitWithTabID(EquipType2ItemType[nPosType], nTabID, false)
                    UIHelper.SetVisible(scriptItemTip.WidgetEquipCompare, false)
                end)
            end)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutEquipWearings)
    UIHelper.LayoutDoLayout(self.LayoutEquipDecos)
    UIHelper.LayoutDoLayout(self.LayoutEquipWeapons)
    UIHelper.LayoutDoLayout(self.LayoutEquipAll)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UICustomizedSetRecommendSetCell:UpdateTagsInfo()
    local szTags = self.tbData.tags
    local tbTags = string.split(szTags, ",")

    UIHelper.HideAllChildren(self.LayoutExpertRecTagsShell)

    self.tbTagCell = self.tbTagCell or {}
    for i, szTag in ipairs(tbTags) do
        if not self.tbTagCell[i] then
            self.tbTagCell[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetExpertRecTagsCell, self.LayoutExpertRecTagsShell)
        end

        UIHelper.SetVisible(self.tbTagCell[i]._rootNode, true)
        UIHelper.SetString(self.tbTagCell[i].LabelTag, PlayerEquipTags2Chinese[szTag] or szTag)
        UIHelper.LayoutDoLayout(self.tbTagCell[i].WidgetExpertRecTagsCell)
    end

    UIHelper.LayoutDoLayout(self.LayoutExpertRecTagsShell)
    UIHelper.LayoutDoLayout(self.LayoutName)
end

return UICustomizedSetRecommendSetCell