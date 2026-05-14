-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHouseKeeperSkillInfoCell
-- Date: 2023-08-09 10:00:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHouseKeeperSkillInfoCell = class("UIHouseKeeperSkillInfoCell")

function UIHouseKeeperSkillInfoCell:OnEnter(nIndex, nItemType, nItemIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.nItemType = nItemType
    self.nItemIndex = nItemIndex

    UIHelper.SetSelected(self.ToggleSelect, false)

    self:UpdateInfo()
end

function UIHouseKeeperSkillInfoCell:OnExit()
    self.bInit = false
end

function UIHouseKeeperSkillInfoCell:BindUIEvent()
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        -- local nSkillID = HouseKeeperData.GetSkillIDByItemInfo(self.nItemType, self.nItemIndex)
        Event.Dispatch(EventType.OnSelectedHouseKeeperChangeSkillCell, self.nIndex, self.nItemType, self.nItemIndex)
    end)
end

function UIHouseKeeperSkillInfoCell:RegEvent()
    Event.Reg(self, EventType.OnSelectedHouseKeeperChangeSkillCell, function (nIndex, nItemType, nItemIndex)
        if self.nItemType ~= nItemType or self.nItemIndex ~= nItemIndex then
            UIHelper.SetSelected(self.ToggleSelect, false)
        end
    end)
end

function UIHouseKeeperSkillInfoCell:UpdateInfo()
    local item = ItemData.GetItemInfo(self.nItemType, self.nItemIndex)

    local bResult = UIHelper.SetItemIconByItemInfo(self.ImgSkillIcon, item)
    if not bResult then
        UIHelper.ClearTexture(self.ImgSkillIcon)
    end
    UIHelper.SetString(self.LabelSkillName, UIHelper.GBKToUTF8(Table_GetItemName(item.nUiId)))
    UIHelper.SetString(self.LabelSkillContent, UIHelper.GBKToUTF8(ParseTextHelper.ParseNormalText(Table_GetItemDesc(item.nUiId), true)))
end


return UIHouseKeeperSkillInfoCell