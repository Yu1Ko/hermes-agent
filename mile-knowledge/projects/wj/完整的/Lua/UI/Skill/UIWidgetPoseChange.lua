-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UIWidgetPoseChange
-- Date: 2025-07-28 10:01:29
-- Desc: 
-- ---------------------------------------------------------------------------------

local tShortcutDict = {
    [10026] = { 1, 2 },
    [10062] = { 3, 4 }, -- 天策

    [10698] = { 1, 2 }, -- 刀宗
    [10533] = { 1, 2 }, -- 蓬莱

    [10389] = { 1, 2 },
    [10390] = { 3, 4 }, -- 苍云
}

local tIconDict = {
    [10026] = { "Resource/icon/skill/Tiance/skill_25_4_16_12.png", "Resource/icon/skill/Tiance/skill_22_4_27_6.png" },
    [10062] = { "Resource/icon/skill/Tiance/skill_25_4_16_12.png", "Resource/icon/skill/Tiance/skill_22_4_27_6.png" }, -- 天策

    [10698] = { "Resource/icon/skill/DaoZong/item_22_8_26_6.png", "Resource/icon/skill/DaoZong/item_22_8_26_9.png" }, -- 刀宗

    [10533] = { "Resource/icon/skill/PengLai/JNPL_18_10_30_105.png", "Resource/icon/skill/PengLai/JNPL_18_10_30_45.png" }, -- 蓬莱

    [10389] = { "Resource/icon/skill/CangYun/skill_cangy_98.png", "Resource/icon/skill/CangYun/skill_cangy_97.png" },
    [10390] = { "Resource/icon/skill/CangYun/skill_cangy_98.png", "Resource/icon/skill/CangYun/skill_cangy_97.png" }, -- 苍云

    [10144] = "Resource/icon/skill/CangJian/cangjian_neigong_1.png", -- 藏剑
    [10145] = "Resource/icon/skill/CangJian/cangjian_neigong_2.png", -- 藏剑
}

---@class UIWidgetPoseChange
local UIWidgetPoseChange = class("UIWidgetPoseChange")

function UIWidgetPoseChange:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true

        self:InitPoseTog()
    end
end

function UIWidgetPoseChange:OnExit()
    self:UnRegEvent()
end

function UIWidgetPoseChange:BindUIEvent()
end

function UIWidgetPoseChange:RegEvent()
    Event.Reg(self, "OnDxSkillBarIndexChange", function()
        self:UpdatePlayerPose()
    end)

    Event.Reg(self, EventType.OnPoseChange, function(nIndex)
        self:UpdatePlayerPose(nIndex)
    end)

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function()
        self:InitPoseTog()
    end)


end

function UIWidgetPoseChange:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

-----------------------------------端游体态--------------------------------------------

function UIWidgetPoseChange:InitPoseTog()
    local player = g_pClientPlayer
    if not SkillData.IsUsingHDKungFu() or not g_pClientPlayer then
        self:Hide()
        return
    end
    local tKungFu = player.GetActualKungfuMount()
    local nSchoolID = player.dwSchoolID
    self.nKungFuID = tKungFu.dwSkillID
    self.tPoseTogScripts = {}

    if nSchoolID == SCHOOL_TYPE.BA_DAO then
        self:InitBaDaoPoseTog()
    elseif (nSchoolID == SCHOOL_TYPE.TIAN_CE or nSchoolID == SCHOOL_TYPE.DAO_ZONG or nSchoolID == SCHOOL_TYPE.CANG_YUN
            or nSchoolID == SCHOOL_TYPE.PENG_LAI) then
        self:InitTwoPoseTog(player.dwForceID)
    elseif nSchoolID == SCHOOL_TYPE.CANG_JIAN_SHAN_JU or nSchoolID == SCHOOL_TYPE.CANG_JIAN_WEN_SHUI then
        self:InitCangJianTog(player.dwForceID)
    else
        self:Hide()
    end

    UIHelper.LayoutDoLayout(self._rootNode)
end

-- 霸刀
local name_badaoposeskill = {
    [POSE_TYPE.BROADSWORD] = "大刀",
    [POSE_TYPE.DOUBLE_BLADE] = "双刀",
    [POSE_TYPE.SHEATH_KNIFE] = "鞘刀",
}

local tName = {
    [FORCE_TYPE.TIAN_CE] = { "下马", "上马" },
    [FORCE_TYPE.DAO_ZONG] = { "流云", "破浪" },
    [FORCE_TYPE.CANG_JIAN] = { "问水", "山居" },
    [FORCE_TYPE.CANG_YUN] = { "擎刀", "擎盾" },
    [FORCE_TYPE.PENG_LAI] = { "地面", "浮空" },
}

function UIWidgetPoseChange:InitBaDaoPoseTog()
    local player = g_pClientPlayer
    local tOrder = { POSE_TYPE.DOUBLE_BLADE, POSE_TYPE.SHEATH_KNIFE, POSE_TYPE.BROADSWORD }
    local tImgPath = { "Resource/icon/skill/BaDao/daoj_16_10_17_73.png", "Resource/icon/skill/BaDao/daoj_16_10_17_74.png",
                       "Resource/icon/skill/BaDao/daoj_16_10_17_75.png" }
    for togIndex, i in ipairs(tOrder) do
        local nActionBarIndex = i
        local szImgPath = tImgPath[i]
        local script = UIHelper.GetBindScript(self.positionWidgets[togIndex])
        script.nActionBarIndex = nActionBarIndex
        local dwSkillID = l_badaoposeskill[i]
        local nLevel = player.GetSkillLevel(dwSkillID)
        UIHelper.BindUIEvent(script.BtnClick, EventType.OnClick, function()
            OnUseSkill(dwSkillID)
        end)

        UIHelper.SetTexture(script.ImgIcon, szImgPath, true, function()
            UIHelper.UpdateMask(script.MaskSkill)
        end)
        UIHelper.SetTexture(script.ImgIconUp, szImgPath, true, function()
            UIHelper.UpdateMask(script.MaskSkillUp)
        end)
        UIHelper.SetString(script.LabelTitleNormal, name_badaoposeskill[i])
        UIHelper.SetString(script.LabelTitleSelect, name_badaoposeskill[i])
        UIHelper.SetSelected(script.TogSpecialPage, SkillData.GetCurrentDxSkillBarIndex() == nActionBarIndex)
        UIHelper.SetVisible(self.positionWidgets[togIndex], true)
        self.tPoseTogScripts[i] = script
    end
end

function UIWidgetPoseChange:InitTwoPoseTog(dwForceID)
    for i = 1, 2 do
        local nActionBarIndex = tShortcutDict[self.nKungFuID][i]
        local szImgPath = tIconDict[self.nKungFuID][i]
        local script = UIHelper.GetBindScript(self.positionWidgets[i])
        script.nActionBarIndex = nActionBarIndex
        UIHelper.BindUIEvent(script.BtnClick, EventType.OnClick, function()
            PanelSkillDX.nLocalSelected = nActionBarIndex
            Event.Dispatch(EventType.OnPoseChange, nActionBarIndex)
        end)

        UIHelper.SetTexture(script.ImgIcon, szImgPath, true, function()
            UIHelper.UpdateMask(script.MaskSkill)
        end)
        UIHelper.SetTexture(script.ImgIconUp, szImgPath, true, function()
            UIHelper.UpdateMask(script.MaskSkillUp)
        end)
        UIHelper.SetString(script.LabelTitleNormal, tName[dwForceID][i])
        UIHelper.SetString(script.LabelTitleSelect, tName[dwForceID][i])
        UIHelper.SetSelected(script.TogSpecialPage, (PanelSkillDX.nLocalSelected or SkillData.GetCurrentDxSkillBarIndex()) == nActionBarIndex)
        UIHelper.SetVisible(self.positionWidgets[i], true)
        self.tPoseTogScripts[i] = script
    end

    UIHelper.SetVisible(self.positionWidgets[3], false)
end

function UIWidgetPoseChange:InitCangJianTog(dwForceID)
    local tKungFu = { 10144, 10145 }
    for i = 1, 2 do
        local nKungFu = tKungFu[i]
        local szImgPath = tIconDict[nKungFu]
        local script = UIHelper.GetBindScript(self.positionWidgets[i])

        UIHelper.BindUIEvent(script.BtnClick, EventType.OnClick, function()
            local dwSkillID = 1656
            OnUseSkill(dwSkillID)
        end)

        UIHelper.SetTexture(script.ImgIcon, szImgPath, true, function()
            UIHelper.UpdateMask(script.MaskSkill)
        end)
        UIHelper.SetTexture(script.ImgIconUp, szImgPath, true, function()
            UIHelper.UpdateMask(script.MaskSkillUp)
        end)
        UIHelper.SetString(script.LabelTitleNormal, tName[dwForceID][i])
        UIHelper.SetString(script.LabelTitleSelect, tName[dwForceID][i])
        UIHelper.SetSelected(script.TogSpecialPage, self.nKungFuID == nKungFu)
        UIHelper.SetVisible(self.positionWidgets[i], true)
        self.tPoseTogScripts[i] = script
    end

    UIHelper.SetVisible(self.positionWidgets[3], false)
end

function UIWidgetPoseChange:UpdatePlayerPose(nSkillBarIndex)
    if self.tPoseTogScripts then
        nSkillBarIndex = nSkillBarIndex or SkillData.GetCurrentDxSkillBarIndex()
        for i = 1, 3 do
            local script = self.tPoseTogScripts[i]
            if script then
                UIHelper.SetSelected(script.TogSpecialPage, nSkillBarIndex == script.nActionBarIndex)
            end
        end
    end
end

function UIWidgetPoseChange:Hide()
    for i = 1, 3 do
        local node = self.positionWidgets[i]
        UIHelper.SetVisible(node, false)
    end
end

return UIWidgetPoseChange