-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetPage
-- Date: 2024-08-23 15:45:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetPage = class("UICustomizedSetPage")
local MAX_ITEM_COUNT = 30
function UICustomizedSetPage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurIndex = 1
    EquipCodeData.LoginAccount(false)
    self:UpdateInfo()
end

function UICustomizedSetPage:OnExit()
    self.bInit = false
end

function UICustomizedSetPage:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPreview, EventType.OnClick, function(btn)
        local tbRoleEquipData = EquipCodeData.GetRoleEquipData() or {}
        local tbSetData = tbRoleEquipData[self.nCurIndex]
        if tbSetData then
            local tEquip, tInfo, dwForceID, dwKungfuID = EquipCodeData.DoImportEquip(tbSetData, true)
            UIMgr.Open(VIEW_ID.PanelCustomizedSetSharePic, true, tEquip, tInfo, dwForceID, dwKungfuID)
        else
            TipsHelper.ShowNormalTip("请先选择需要预览的配装")
        end
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function(btn)
        local tbRoleEquipData = EquipCodeData.GetRoleEquipData() or {}
        local tbSetData = tbRoleEquipData[self.nCurIndex]
        if tbSetData then
            EquipCodeData.ImportCustomizedSetEquip(tbSetData, true)
            UIMgr.Open(VIEW_ID.PanelCustomizedSet)
        end
    end)

    UIHelper.BindUIEvent(self.BtnCloudManage, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelSideCloudSetCodeList)
    end)
end

function UICustomizedSetPage:RegEvent()
    Event.Reg(self, EventType.OnUpdateCustomizedSetList, function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSetRecommendCell, function (nIndex, tbData, bRoleData)
        if not bRoleData then
            return
        end
        self.nCurIndex = nIndex
        EquipCodeData.ImportCustomizedSetEquip(tbData, true)
        self:UpdateEquipAttrInfo()
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSetRecommendCellEnd, function (bRoleData)
        if not bRoleData then
            return
        end

        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewExpertSetList)
        -- UIHelper.ScrollLocateToPreviewItem(self.ScrollViewExpertSetList, self.tbSetCells[self.nCurIndex]._rootNode, Locate.TO_CENTER)
    end)

    Event.Reg(self, EventType.OnDoSelectCustomizedSetRecommendCell, function (nIndex, bRoleData)
        if not bRoleData then
            return
        end

        UIHelper.SetToggleGroupSelected(self.TogGroupSetCell, nIndex - 1)
    end)

end

function UICustomizedSetPage:UpdateInfo()
    self:UpdateSetListInfo()
    self:UpdateEquipAttrInfo()
end

function UICustomizedSetPage:UpdateSetListInfo()
    self.tbSetCells = self.tbSetCells or {}
    UIHelper.HideAllChildren(self.ScrollViewExpertSetList)

    UIHelper.SetButtonState(self.BtnEdit, BTN_STATE.Normal)
    local tbRoleEquipData = EquipCodeData.GetRoleEquipData() or {}
    if table.is_empty(tbRoleEquipData) then
        UIHelper.SetVisible(self.WidgetTipsEmpty, true)
        UIHelper.SetButtonState(self.BtnEdit, BTN_STATE.Disable)
    else
        UIHelper.SetVisible(self.WidgetTipsEmpty, false)
        for i, tbSetData in ipairs(tbRoleEquipData) do
            if not self.tbSetCells[i] then
                self.tbSetCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetExpertRecSetItemCellNew, self.ScrollViewExpertSetList)
                UIHelper.ToggleGroupAddToggle(self.TogGroupSetCell, self.tbSetCells[i].TogCell)
            end

            UIHelper.SetVisible(self.tbSetCells[i]._rootNode, true)
            self.tbSetCells[i]:OnEnter(i, tbSetData, true)
        end
    end

    if table.is_empty(tbRoleEquipData) or #tbRoleEquipData < EquipCodeData.nMaxRoleSetCount then
        local nIndex = EquipCodeData.nMaxRoleSetCount + 1
        if self.tbSetCells[nIndex] then
            UIHelper.RemoveFromParent(self.tbSetCells[nIndex]._rootNode)
            self.tbSetCells[nIndex] = nil
        end

        self.tbSetCells[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetExpertRecAddSetItem, self.ScrollViewExpertSetList)
        UIHelper.BindUIEvent(self.tbSetCells[nIndex].BtnAdd, EventType.OnClick, function(btn)
            EquipCodeData.CreateNewSet()
            UIMgr.Open(VIEW_ID.PanelCustomizedSet)
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewExpertSetList)
end

function UICustomizedSetPage:UpdateEquipAttrInfo()
    self.scriptEquipAttributePage = self.scriptEquipAttributePage or UIHelper.GetBindScript(self.WidgetAnchorAttri)

    local tbRoleEquipData = EquipCodeData.GetRoleEquipData() or {}
    local tbSetData = tbRoleEquipData[self.nCurIndex]
    if tbSetData then
        if tbSetData and not string.is_nil(tbSetData.equips) then
            local dwKungfuID = tonumber(tbSetData.kungfu_id or EquipCodeData.dwCurKungfuID)
            if not dwKungfuID then
                if tbSetData.kungfu_name then
                    dwKungfuID = table.get_key(PlayerKungfuChineseName, tbSetData.kungfu_name)
                else
                    dwKungfuID = PlayerData.GetPlayerMountKungfuID()
                end
            end
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


return UICustomizedSetPage