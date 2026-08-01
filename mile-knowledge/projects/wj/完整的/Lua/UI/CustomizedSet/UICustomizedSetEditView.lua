-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetEditView
-- Date: 2024-07-15 14:38:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetEditView = class("UICustomizedSetEditView")
local Equip1Enum = {
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
}

local Equip2Enum = {
    -- 项链
    EQUIPMENT_INVENTORY.AMULET,
    -- 腰坠
    EQUIPMENT_INVENTORY.PENDANT,
    -- 戒指
    EQUIPMENT_INVENTORY.LEFT_RING,
    -- 戒指
    EQUIPMENT_INVENTORY.RIGHT_RING,
}

local WeaponEnum = {
    -- 普通近战武器
    EQUIPMENT_INVENTORY.MELEE_WEAPON,
    -- 重剑
    EQUIPMENT_INVENTORY.BIG_SWORD,
    -- 远程武器
    EQUIPMENT_INVENTORY.RANGE_WEAPON,
}

local MaxSetCount = 4

function UICustomizedSetEditView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurEquipType = EQUIPMENT_INVENTORY.HELM
    self:UpdateInfo()
end

function UICustomizedSetEditView:OnExit()
    self.bInit = false
end

function UICustomizedSetEditView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        if EquipCodeData.CheckCurCustomizedSetIsChanged() then
            local dialog = UIHelper.ShowConfirm("当前配装存在修改尚未保存，是否保存修改后继续操作？", function()
                EquipCodeData.SaveCustomizedSet()
            end, function ()
                UIMgr.Close(self)
            end)

            dialog:SetConfirmButtonContent("保存")
            dialog:SetCancelButtonContent("不保存")
        else
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.TogEquipChoose, EventType.OnClick, function(btn)
        self:UpdateEquipListPageInfo()
    end)

    UIHelper.BindUIEvent(self.TogPowerUpSet, EventType.OnClick, function(btn)
        self:UpdateEquipPowerUpPageInfo()
    end)

    UIHelper.BindUIEvent(self.BtnPowerUp, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelPowerUp)
    end)

    UIHelper.BindUIEvent(self.BtnCloudManage, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelSideCloudSetCodeList)
    end)

    UIHelper.BindUIEvent(self.BtnExpertRec, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelExpertRec)
    end)

    UIHelper.BindUIEvent(self.BtnImport, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelEnterSetCodePop)
    end)

    UIHelper.BindUIEvent(self.BtnGeneratePic, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelCustomizedSetSharePic)
    end)

    UIHelper.BindUIEvent(self.BtnShareSet, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelCustomSetOutputPop)
    end)

    UIHelper.BindUIEvent(self.BtnOutput, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelCustomSetOutputPop)
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function(btn)
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end

        local bForceLegal = EquipCodeData.dwCurForceID == PlayerData.GetPlayerForceID() or (EquipCodeData.dwCurForceID == FORCE_TYPE.WU_XIANG and hPlayer.GetSkillLevel(102393) > 0)
        if not bForceLegal then
            TipsHelper.ShowNormalTip("当前配装方案与自身门派不一致或未学习该流派，无法保存")
            return
        end
        EquipCodeData.SaveCustomizedSet()
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function(btn)
        local nX,nY = UIHelper.GetWorldPosition(self.BtnMore)
        local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnMore)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper, nX-nSizeW+40, nY+nSizeH+170)
        local tbBtnParams = {{
            szName = "删除配装",
            OnClick = function ()
                local tCurInfo = EquipCodeData.tCurInfo
                UIHelper.ShowConfirm(string.format("是否确认删除【%s】配装方案？", tCurInfo.szTitle), function ()
                    EquipCodeData.ReqDelRoleEquip(tCurInfo.nID)
                    UIMgr.Close(self)
                end)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        },{
            szName = "重命名",
            OnClick = function ()
                local scriptView = UIMgr.Open(VIEW_ID.PanelPromptPop, "", "请输入方案名", function (szTitle)
                    if not TextFilterCheck(UIHelper.UTF8ToGBK(szTitle)) then --过滤文字
                        TipsHelper.ShowNormalTip("您输入的方案名中含有敏感字词。")
                        return
                    end

                    local tCurInfo = EquipCodeData.tCurInfo
                    if tCurInfo then
                        tCurInfo.szTitle = szTitle
                        EquipCodeData.SaveCustomizedSet()
                        UIMgr.Close(self)
                    end
                end)
                scriptView:SetTitle("修改配装方案名")
                scriptView:SetPlaceHolder("字数不能超过4个字")
                scriptView:SetMaxLength(4)
                TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
            end
        }}

        scriptTips:OnEnter(tbBtnParams)
    end)

end

function UICustomizedSetEditView:RegEvent()
    Event.Reg(self, EventType.OnUpdateCustomizedSetList, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSet, function (nIndex, tData)
        EquipCodeData.ImportCustomizedSetEquip(tData, true)
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        self:ClearSelect()
    end)

    Event.Reg(self, EventType.OnUpdateCustomizedSetEquipList, function(nType)
        self:UpdateEquipAttributePageInfo()
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSetEquipFilterItemCell, function()
        Timer.AddFrame(self, 1, function ()
            self:UpdateEquipAttributePageInfo()
            self:UpdateBigSwordSlotState()
        end)
    end)

    Event.Reg(self, EventType.OnEquipCodeRsp, function (szKey, tInfo)
        if szKey == "ROLE_EQUIPS_UPLOAD" then
            if tInfo and tInfo.code and tInfo.code == 1 then
                UIMgr.Close(self)
            end
        end
    end)
end

function UICustomizedSetEditView:UpdateInfo()
    self:UpdateEquipSetInfo()
    self:UpdateEquipSlotInfo()
    self:UpdateEquipListPageInfo()
    self:UpdateEquipPowerUpPageInfo()
    self:UpdateEquipAttributePageInfo()
    self:UpdateButtonState()
    self:UpdateBigSwordSlotState()
end

function UICustomizedSetEditView:UpdateEquipSetInfo()
    local tRoleEquips = EquipCodeData.GetRoleEquipData() or {}
    local tCurInfo = EquipCodeData.tCurInfo
    if tCurInfo then
        UIHelper.SetString(self.LabelTitle, tCurInfo.szTitle)
        UIHelper.SetVisible(self.BtnMore, true)
    else
        UIHelper.SetString(self.LabelTitle, "配装方案")
        UIHelper.SetVisible(self.BtnMore, false)
    end

    UIHelper.SetString(self.LabelLimitNum, string.format("%d/%d", #tRoleEquips, MaxSetCount))

    -- WidgetCustomSetCell
    -- self.tbSetCells = self.tbSetCells or {}
    -- UIHelper.HideAllChildren(self.LayoutCustomSetList)
    -- for i, tData in ipairs(tRoleEquips) do
    --     if not self.tbSetCells[i] then
    --         self.tbSetCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomSetCell, self.LayoutCustomSetList)
    --         UIHelper.ToggleGroupAddToggle(self.TogGroupSet, self.tbSetCells[i].TogSet)
    --     end

    --     UIHelper.SetVisible(self.tbSetCells[i]._rootNode, true)
    --     self.tbSetCells[i]:OnEnter(i, tData)
    -- end

    -- if #tRoleEquips < 4 then
    --     local i = #tRoleEquips + 1
    --     if not self.tbSetCells[i] then
    --         self.tbSetCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomSetCell, self.LayoutCustomSetList)
    --     end

    --     UIHelper.SetVisible(self.tbSetCells[i]._rootNode, true)
    --     self.tbSetCells[i]:OnEnter()
    -- end

    -- UIHelper.LayoutDoLayout(self.LayoutCustomSetList)

    -- if EquipCodeData.IsNewEquipSet() then
    --     UIHelper.SetToggleGroupSelected(self.TogGroupSet, 0)
    --     for _, cell in ipairs(self.tbSetCells) do
    --         UIHelper.SetSelected(cell.TogSet, false)
    --     end
    -- end
end

function UICustomizedSetEditView:UpdateEquipListPageInfo()
    self.scriptEquipListPage = self.scriptEquipListPage or UIHelper.GetBindScript(self.WidgetAnchorMiddleEquip)
    self.scriptEquipListPage:OnEnter(self.nCurEquipType)
end

function UICustomizedSetEditView:UpdateEquipPowerUpPageInfo()
    self.scriptEquipPowerUpPage = self.scriptEquipPowerUpPage or UIHelper.GetBindScript(self.WidgetAnchorMiddlePowerUp)
    self.scriptEquipPowerUpPage:OnEnter(self.nCurEquipType)
end

function UICustomizedSetEditView:UpdateEquipAttributePageInfo()
    self.scriptEquipAttributePage = self.scriptEquipAttributePage or UIHelper.GetBindScript(self.WidgetAnchorRight)

    local tEquipDatas = EquipCodeData.tCurEquip
    local szKungfu = PlayerKungfuName[EquipCodeData.dwCurKungfuID] or ""
    local tShowItem, tMatchDetail, nTotalScore = EquipCodeData.GetAttributeData(szKungfu, tEquipDatas, true)
    self.scriptEquipAttributePage:OnEnter(tShowItem, nTotalScore)
end

function UICustomizedSetEditView:UpdateEquipSlotInfo()
    self.tbEquipCell = {}
    UIHelper.RemoveAllChildren(self.LayoutEquipClothes)
    for i, nType in ipairs(Equip1Enum) do
		self.tbEquipCell[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomEquipSlotCell, self.LayoutEquipClothes)
        self.tbEquipCell[nType]:OnEnter(nType, function ()
            self.nCurEquipType = nType
            self:UpdateEquipListPageInfo()
            self:UpdateEquipPowerUpPageInfo()
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupEquipSlot, self.tbEquipCell[nType].TogSelect)
    end

    UIHelper.RemoveAllChildren(self.LayoutEquipHangings)
    for i, nType in ipairs(Equip2Enum) do
		self.tbEquipCell[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomEquipSlotCell, self.LayoutEquipHangings)
        self.tbEquipCell[nType]:OnEnter(nType, function ()
            self.nCurEquipType = nType
            self:UpdateEquipListPageInfo()
            self:UpdateEquipPowerUpPageInfo()
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupEquipSlot, self.tbEquipCell[nType].TogSelect)
    end

    UIHelper.RemoveAllChildren(self.LayoutEquipWeapons)
    for i, nType in ipairs(WeaponEnum) do
		self.tbEquipCell[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomEquipSlotCell, self.LayoutEquipWeapons)
        self.tbEquipCell[nType]:OnEnter(nType, function ()
            self.nCurEquipType = nType
            self:UpdateEquipListPageInfo()
            self:UpdateEquipPowerUpPageInfo()
        end)
        UIHelper.ToggleGroupAddToggle(self.TogGroupEquipSlot, self.tbEquipCell[nType].TogSelect)
    end

    UIHelper.LayoutDoLayout(self.LayoutEquipClothes)
    UIHelper.LayoutDoLayout(self.LayoutEquipHangings)
    UIHelper.LayoutDoLayout(self.LayoutEquipWeapons)
end

function UICustomizedSetEditView:UpdateButtonState()
    if EquipCodeData.IsNewEquipSet() then
        UIHelper.SetString(self.LabelSave, "新建配装")
    else
        UIHelper.SetString(self.LabelSave, "保存配装")
    end
end

function UICustomizedSetEditView:UpdateBigSwordSlotState()
    local bHadBigSword = EquipCodeData.dwCurForceID == FORCE_TYPE.CANG_JIAN
    UIHelper.SetVisible(self.tbEquipCell[EQUIPMENT_INVENTORY.BIG_SWORD]._rootNode, bHadBigSword)
    UIHelper.LayoutDoLayout(self.LayoutEquipWeapons)
end

function UICustomizedSetEditView:ClearSelect()
    -- UIHelper.SetSelected(self.TogSetSwitch, false)
end

return UICustomizedSetEditView