-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UICharacterWidgetEquipRefine
-- Date: 2022-12-06 14:39
-- Desc: UICharacterWidgetEquipRefine
-- ---------------------------------------------------------------------------------

---@class UIWidgetEnchantCell
local UIWidgetEnchantCell = class("UIWidgetEnchantCell")

function UIWidgetEnchantCell:OnEnter()
    if not self.bInit then
        self.script = UIHelper.AddPrefab(PREFAB_ID.WidgetRefineMaterial_80, self.WidgetItem) ---@type UICharacterRefineMaterialCell
        UIHelper.SetVisible(self.script._rootNode, false)
        --
        --self:RegEvent()
        --self.bInit = true
    end
end

function UIWidgetEnchantCell:OnExit()
    self.bInit = false
end

function UIWidgetEnchantCell:RegEvent()
end

function UIWidgetEnchantCell:BindCancelFunc(fnCancel)
    self.script:BindCancelFunc(fnCancel)
end

function UIWidgetEnchantCell:UpdateInfo(dwEnchantID, bTemporary)
    self:SetVisible(true)
    UIHelper.SetVisible(self.script._rootNode, dwEnchantID ~= nil)
    --UIHelper.SetVisible(self.LabelInactivated, dwEnchantID == nil)
    --UIHelper.SetVisible(self.WidgetActivated, dwEnchantID ~= nil)
    --UIHelper.SetVisible(self.WidgetLimitedTime, bTemporary)

    if dwEnchantID and dwEnchantID > 0 then
        local nBox, nIndex = ItemData.GetItemPos(dwEnchantID)
        local item = ItemData.GetItemByPos(nBox, nIndex)
        --local itemInfo = ItemData.GetItemInfo(dwTabType, dwTabIndex)

        self.script:RefreshInfo(EQUIP_REFINE_SLOT_TYPE.MATERIAL_CHOSEN, item.dwIndex, item.nUiId, item.nQuality, 1)

        --UIHelper.SetString(self.LabelActivated, UIHelper.GBKToUTF8(item.szName))
        UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
            local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.BtnDetail, TipsLayoutDir.LEFT_CENTER)
            scriptItemTip:OnInit(nBox, nIndex)
            scriptItemTip:SetBtnState({ })
        end)

        UIHelper.SetVisible(self.script.BtnAdd, false)
    end
end

function UIWidgetEnchantCell:SetVisible(bVisible)
    UIHelper.SetVisible(UIHelper.GetParent(self._rootNode), bVisible)
end
return UIWidgetEnchantCell