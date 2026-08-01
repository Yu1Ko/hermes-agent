-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetEquipFilterItemCell
-- Date: 2024-07-17 16:06:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetEquipFilterItemCell = class("UICustomizedSetEquipFilterItemCell")

local FilterType = {
    School = 1,
    XinFa = 2,
}
function UICustomizedSetEquipFilterItemCell:OnEnter(nFilterType, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nFilterType = nFilterType or FilterType.School
    self.nID = nID

    self:UpdateInfo()
end

function UICustomizedSetEquipFilterItemCell:OnExit()
    self.bInit = false
end

function UICustomizedSetEquipFilterItemCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogType, EventType.OnClick, function(btn)
        if EquipCodeData.CheckCurCustomizedSetIsChanged() and UIMgr.IsViewOpened(VIEW_ID.PanelCustomizedSet) then
            UIHelper.SetSelected(self.TogType, false)
            local dialog = UIHelper.ShowConfirm("当前配装存在修改尚未保存，是否保存修改后继续操作？", function()
                EquipCodeData.SaveCustomizedSet()
            end, function ()
                Event.Dispatch(EventType.OnSelectCustomizedSetEquipFilterItemCell, self.nFilterType, self.nID)
            end)

            dialog:SetConfirmButtonContent("保存")
            dialog:SetCancelButtonContent("不保存")
        else
            Event.Dispatch(EventType.OnSelectCustomizedSetEquipFilterItemCell, self.nFilterType, self.nID)
        end
    end)
    UIHelper.SetTouchDownHideTips(self.TogType, false)
end

function UICustomizedSetEquipFilterItemCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICustomizedSetEquipFilterItemCell:UpdateInfo()
    if self.nFilterType == FilterType.School then
        self:UpdateSchoolInfo()
    elseif self.nFilterType == FilterType.XinFa then
        self:UpdateXinFaInfo()
    end
end

function UICustomizedSetEquipFilterItemCell:UpdateSchoolInfo()
    local dwBelongSchoolID = Table_ForceToSchool(self.nID)
    UIHelper.SetSpriteFrame(self.ImgIcon, PlayerForceID2SchoolImg2[self.nID] or "")
    UIHelper.SetString(self.LabelName, Table_GetSkillSchoolName(dwBelongSchoolID, true) or "")
end

function UICustomizedSetEquipFilterItemCell:UpdateXinFaInfo()
    UIHelper.SetSpriteFrame(self.ImgIcon, PlayerKungfuImg[self.nID] or "")

    local nKungfuID = TabHelper.GetMobileKungfuID(self.nID)
    local tSkillInfo = TabHelper.GetUISkill(nKungfuID)
    UIHelper.SetString(self.LabelName, tSkillInfo and tSkillInfo.szName or "")
end

return UICustomizedSetEquipFilterItemCell