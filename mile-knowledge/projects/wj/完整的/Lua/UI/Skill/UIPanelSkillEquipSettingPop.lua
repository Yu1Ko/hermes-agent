-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tEquipSetNameList = {
    [1] = "装备1",
    [2] = "装备2",
    [3] = "装备3",
    [4] = "装备4"
}

---@class UIPanelSkillEquipSettingPop
local UIPanelSkillEquipSettingPop = class("UIPanelSkillEquipSettingPop")

function UIPanelSkillEquipSettingPop:OnEnter(dwKungFuID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.nCurrentKungFuID = dwKungFuID
        self.nCurrentSetID = g_pClientPlayer.GetTalentCurrentSet(g_pClientPlayer.dwForceID, self.nCurrentKungFuID)
        self.bIsHD = TabHelper.IsHDKungfuID(dwKungFuID)

        local szTitle = self.bIsHD and "武学方案绑定设置" or "武学分页绑定设置"
        UIHelper.SetLabel(self.LabelTitle, szTitle)
    end
    self:UpdateInfo()
end

function UIPanelSkillEquipSettingPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSkillEquipSettingPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnEquip, EventType.OnClick, function()
        UIMgr.Close(self)
        if UIMgr.GetView(VIEW_ID.PanelSkillNew) then
            UIMgr.Close(VIEW_ID.PanelSkillNew)
            UIMgr.Open(VIEW_ID.PanelCharacter)
        elseif UIMgr.GetView(VIEW_ID.PanelCharacter) then
            UIMgr.Close(VIEW_ID.PanelCharacter)
            UIMgr.Open(VIEW_ID.PanelSkillNew)
        end
    end)
end

function UIPanelSkillEquipSettingPop:RegEvent()

end

function UIPanelSkillEquipSettingPop:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSkillEquipSettingPop:UpdateInfo()
    local fnSetBinding = self.bIsHD and SkillData.SetSkillEquipBindingDX or SkillData.SetSkillEquipBinding
    local fnGetBinding = self.bIsHD and SkillData.GetSkillEquipBindingDX or SkillData.GetSkillEquipBinding
    local fnGetSetName = SkillData.GetSkillSetName

    local nNumOfTogs = 4
    for nSet = 1, 5 do
        local nSetStartWithZero = nSet - 1
        local tLabel = self.tSkillSetNames[nSet]
        local tLayout = self.tLayouts[nSet]
        local toggleGroup = self.tToggleGroups[nSet]
        local nEquipBindIndex = fnGetBinding(self.nCurrentKungFuID, nSet)
        local szSetName = fnGetSetName(self.nCurrentKungFuID, nSetStartWithZero)
        UIHelper.SetString(tLabel, "【武学】" .. szSetName)

        for nTogIndex = 1, nNumOfTogs do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipTog, tLayout)
            UIHelper.SetString(script.LabelOption, tEquipSetNameList[nTogIndex])
            UIHelper.SetSwallowTouches(script.ToggleEquip, false)
            UIHelper.ToggleGroupAddToggle(toggleGroup, script.ToggleEquip)
            UIHelper.BindUIEvent(script.ToggleEquip, EventType.OnSelectChanged, function(tog, bSelected)
                if bSelected then
                    fnSetBinding(self.nCurrentKungFuID, nSet, nTogIndex)
                    if self.nCurrentSetID == nSetStartWithZero then
                        EquipData.SwitchEquip(nTogIndex)
                    end
                else
                    local nCurrentBindIndex = fnGetBinding(self.nCurrentKungFuID, nSet)
                    if nCurrentBindIndex == nTogIndex then
                        fnSetBinding(self.nCurrentKungFuID, nSet, nil)
                    end
                end
                Storage.PanelSkill.Flush()
            end)
        end
        if nEquipBindIndex and nEquipBindIndex >= 1 and nEquipBindIndex <= nNumOfTogs then
            UIHelper.SetToggleGroupSelected(toggleGroup, nEquipBindIndex - 1)
        end
    end

    if UIMgr.GetView(VIEW_ID.PanelSkillNew) then
        UIHelper.SetString(self.LabelEquip, "查看装备")
    elseif UIMgr.GetView(VIEW_ID.PanelCharacter) then
        UIHelper.SetString(self.LabelEquip, "查看武学")
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScollViewEquipBinding)
end

return UIPanelSkillEquipSettingPop