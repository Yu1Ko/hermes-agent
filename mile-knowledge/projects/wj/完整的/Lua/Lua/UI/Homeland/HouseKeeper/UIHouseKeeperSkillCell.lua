-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHouseKeeperSkillCell
-- Date: 2023-08-09 09:55:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHouseKeeperSkillCell = class("UIHouseKeeperSkillCell")

function UIHouseKeeperSkillCell:OnEnter(nIndex, tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.tbInfo = tbInfo
    self.szSkillInfo = nil

    if tbInfo then
        self.szSkillInfo = tbInfo.szBoxInfo
    end

    self:UpdateInfo()
end

function UIHouseKeeperSkillCell:OnExit()
    self.bInit = false
end

function UIHouseKeeperSkillCell:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnAdd, false)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        if not self.szSkillInfo or self.szSkillInfo == "" then
            PlotMgr.ClosePanel(PLOT_TYPE.OLD)
        end

        -- 私宅管家的保护技能不生效，在策划脚本里面被拦了私宅的当前位置检测，不好改
        if self.tbInfo and self.tbInfo.nSkillID == 33 and HomelandData.IsNowPrivateHomeMap() then
            local dialog = UIHelper.ShowConfirm(g_tStrings.STR_PRIVATE_SERVANT_SKILL_PROTECT_LOCK)
            dialog:HideCancelButton()
            return
        end

        if UIHelper.GetSelected(self.ToggleSelect) then
            Event.Dispatch(EventType.OnSelectedHouseKeeperSkillCell, self.nIndex, self.tbInfo)
        else
            Event.Dispatch(EventType.OnSelectedHouseKeeperSkillCell, 0)
        end
    end)
end

function UIHouseKeeperSkillCell:RegEvent()
    Event.Reg(self, EventType.OnSelectedHouseKeeperSkillCell, function (nIndex, tbInfo)
        if self.nIndex == nIndex and self.tbInfo == tbInfo then

        else
            UIHelper.SetSelected(self.ToggleSelect, false)
        end
    end)
end

function UIHouseKeeperSkillCell:UpdateInfo()
    if self.szSkillInfo and self.szSkillInfo ~= "" then
        UIHelper.SetVisible(self.BtnAdd, false)
        UIHelper.SetVisible(self.ImgIcon, true)
        local tBoxInfo = string.split(self.szSkillInfo, "_")
	    local dwTabType, dwIndex, _ = tBoxInfo[1], tBoxInfo[2]

        local item = ItemData.GetItemInfo(dwTabType, dwIndex)
        local bResult = UIHelper.SetItemIconByItemInfo(self.ImgIcon, item)
        if not bResult then
            UIHelper.ClearTexture(self.ImgIcon)
        end

        UIHelper.SetString(self.LabelSkillName, UIHelper.GBKToUTF8(Table_GetItemName(item.nUiId)))

        if self.tbInfo.nMaxLevel and self.tbInfo.nSkillLevel and self.tbInfo.nMaxLevel > 1 then
            UIHelper.SetString(self.LabelSkillLevel, string.format("%d/%d", self.tbInfo.nSkillLevel, self.tbInfo.nMaxLevel))
            UIHelper.SetVisible(self.ImgLevelBg, true)
        else
            UIHelper.SetVisible(self.ImgLevelBg, false)
        end
    else
        UIHelper.SetVisible(self.BtnAdd, true)
        UIHelper.SetVisible(self.ImgIcon, false)
        UIHelper.SetVisible(self.ImgLevelBg, false)
        UIHelper.SetString(self.LabelSkillName, "待装备")
    end
end


return UIHouseKeeperSkillCell