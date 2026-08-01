-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISetCodeListCell
-- Date: 2024-07-26 14:59:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISetCodeListCell = class("UISetCodeListCell")

function UISetCodeListCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UISetCodeListCell:OnExit()
    self.bInit = false
end

function UISetCodeListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function(btn)
        SetClipboard(self.tbInfo.share_id)
        TipsHelper.ShowNormalTip("已复制配装方案码")
    end)

    UIHelper.BindUIEvent(self.BtnSharePic, EventType.OnClick, function(btn)
        local tEquip, tInfo, dwForceID, dwKungfuID = EquipCodeData.DoImportEquip(self.tbInfo, false)
        local scriptView = UIMgr.Open(VIEW_ID.PanelCustomizedSetSharePic, false, tEquip, tInfo, dwForceID, dwKungfuID)
        scriptView:SetCode(self.tbInfo.share_id)
    end)

    UIHelper.BindUIEvent(self.TogCodeList, EventType.OnSelectChanged, function(btn, bSelected)
        Event.Dispatch(EventType.OnSelectEquipCodeListCell, bSelected, self.tbInfo.share_id)
    end)

    UIHelper.BindUIEvent(self.TogCodeList_Delete, EventType.OnClick, function(btn)
        local bSelected = UIHelper.GetSelected(self.TogCodeList_Delete)
        Event.Dispatch(EventType.OnSelectDelEquipCodeListCell, bSelected, self.tbInfo.share_id)
    end)

    UIHelper.SetSwallowTouches(self.TogCodeList, false)
    UIHelper.SetSwallowTouches(self.TogCodeList_Delete, false)
end

function UISetCodeListCell:RegEvent()
    Event.Reg(self, EventType.OnSelectEquipCodeListCell, function (bSelected, szCode)
        if self.tbInfo.share_id ~= szCode and bSelected then
            UIHelper.SetSelected(self.TogCodeList, false)
        end
    end)
end

function UISetCodeListCell:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, self.tbInfo.title)
    UIHelper.SetString(self.LabelCode, self.tbInfo.share_id)

    UIHelper.SetVisible(self.TogCodeList, not self.bEnterDelMode)
    UIHelper.SetVisible(self.TogCodeList_Delete, self.bEnterDelMode)
end

function UISetCodeListCell:SetEnterDelMode(bEnterDelMode)
    self.bEnterDelMode = bEnterDelMode
    self:UpdateInfo()
end


return UISetCodeListCell