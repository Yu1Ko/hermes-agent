-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopDyeingCasePage
-- Date: 2023-11-21 20:09:49
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_CASE_NUM = 5
local UICoinShopDyeingCasePage = class("UICoinShopDyeingCasePage")

function UICoinShopDyeingCasePage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

end

function UICoinShopDyeingCasePage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopDyeingCasePage:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.ScrollViewDyeingCaseDefault, false)
    UIHelper.SetTouchDownHideTips(self.BtnUseCase, false)

    UIHelper.BindUIEvent(self.BtnUseCase, EventType.OnClick, function()
        self:EquipHairDyeing()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
end

function UICoinShopDyeingCasePage:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetVisible(self._rootNode) then
            self:Close()
        end
    end)

    Event.Reg(self, "ON_EQUIP_HAIR_CUSTOM_DYEING_NOTIFY", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_CHANGE_HAIR_CUSTOM_DYEING_NOTIFY", function ()
        if arg2 == HAIR_CUSTOM_DYEING_OPERATE_METHOD.DELETE then
            self:UpdateInfo()
        end
    end)
end

function UICoinShopDyeingCasePage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopDyeingCasePage:UpdateInfo()
    UIHelper.ToggleGroupRemoveAllToggle(self.TogGroupCell)
    UIHelper.RemoveAllChildren(self.ScrollViewDyeingCaseDefault)
    local hPlayer = GetClientPlayer()
    if not hPlayer or not self.nHairID then
        return
    end

    self:AddDefaultCase()
    local tList = hPlayer.GetHairCustomDyeingList(self.nHairID)
    if not tList then
        UIHelper.SetToggleGroupSelected(self.TogGroupCell, 0)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDyeingCaseDefault)
        return
    end

    local nNowDyeingIndex = hPlayer.GetEquippedHairCustomDyeingIndex(self.nHairID) --玩家当前装备的方案
    for nIndex, tInfo in pairs(tList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgeDyeingCaseCell, self.ScrollViewDyeingCaseDefault)
        script:OnEnter(self.nHairID, nIndex)
        UIHelper.ToggleGroupAddToggle(self.TogGroupCell, script.TogHair)
        script:SetOnSelectChanged(function(_, bSelected)
            if bSelected then
                self.nNowChoiceDyeingIndex = nIndex
                self:UpdateEquipBtn()
            end
        end)
    end

    self:UpdateCaseNum()
    self:UpdateEquipBtn()
    UIHelper.SetToggleGroupSelected(self.TogGroupCell, nNowDyeingIndex)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDyeingCaseDefault)
end

function UICoinShopDyeingCasePage:AddDefaultCase()
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgeDyeingCaseCell, self.ScrollViewDyeingCaseDefault)
    if not script then
        return
    end
    script:OnEnter(self.nHairID, 0)
    script:SetOnSelectChanged(function(_, bSelected)
        if bSelected then
            self.nNowChoiceDyeingIndex = 0
            self:UpdateEquipBtn()
        end
    end)
    UIHelper.ToggleGroupAddToggle(self.TogGroupCell, script.TogHair)
    self:UpdateCaseNum()
end

function UICoinShopDyeingCasePage:UpdateCaseNum()
    local nCount = UIHelper.GetChildrenCount(self.ScrollViewDyeingCaseDefault)
    UIHelper.SetString(self.LabelMycaseTitle, "我的方案（" .. nCount .. "/" .. MAX_CASE_NUM .. "）")
    UIHelper.LayoutDoLayout(self.LayoutMycaseTitle)
end

function UICoinShopDyeingCasePage:UpdateEquipBtn()
    local hPlayer = GetClientPlayer()
    if not hPlayer or not self.nHairID then
        return
    end

    local nNowDyeingIndex = hPlayer.GetEquippedHairCustomDyeingIndex(self.nHairID) --玩家当前装备的方案
    local bEnable = self.nNowChoiceDyeingIndex and self.nNowChoiceDyeingIndex ~= nNowDyeingIndex
    UIHelper.SetButtonState(self.BtnUseCase, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UICoinShopDyeingCasePage:EquipHairDyeing()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hHairCustomDyeingManager = GetHairCustomDyeingManager()
    if not hHairCustomDyeingManager then
        return
    end
    local nCode = hHairCustomDyeingManager.Equip(self.nHairID, self.nNowChoiceDyeingIndex)
    if nCode ~= HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS then
        local szMsg = g_tStrings.tHairDyeingEquipNotify[nCode]
        TipsHelper.ShowNormalTip(szMsg)
        return
    end
end

function UICoinShopDyeingCasePage:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UICoinShopDyeingCasePage:GetVisible()
    UIHelper.GetVisible(self._rootNode)
end

function UICoinShopDyeingCasePage:Open(nHairID)
    self.nHairID = nHairID
    self:SetVisible(true)
    self:UpdateInfo()
    Event.Dispatch(EventType.OnCoinShopHairDyeCaseOpenClose, true)
end

function UICoinShopDyeingCasePage:Close()
    self.nHairID = nil
    self:SetVisible(false)
    Event.Dispatch(EventType.OnCoinShopHairDyeCaseOpenClose, false)
end

return UICoinShopDyeingCasePage