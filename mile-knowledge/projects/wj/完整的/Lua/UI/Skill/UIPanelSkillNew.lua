-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

function NewSkillPanel_IsShowByRelayOn(tSkill)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tSkillRelyOnShow = tSkill.tSkillRelyOnShow
    if not tSkillRelyOnShow or #tSkillRelyOnShow <= 0 then
        return true
    end

    for _, dwID in ipairs(tSkillRelyOnShow) do
        local dwRelyOnShowLevel = hPlayer.GetSkillLevel(dwID)
        if dwRelyOnShowLevel > 0 then
            return true
        end
    end

    return false
end

function NewSkillPanel_IsShowByRelayOnNot(tSkill)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tSkillRelyOnNotShow = tSkill.tSkillRelyOnNotShow
    if not tSkillRelyOnNotShow or #tSkillRelyOnNotShow <= 0 then
        return true
    end

    for _, dwID in ipairs(tSkillRelyOnNotShow) do
        local dwRelyOnNotShowLevel = hPlayer.GetSkillLevel(dwID)
        if dwRelyOnNotShowLevel > 0 then
            return false
        end
    end

    return true
end

function NewSkillPanel_IsShowSkill(dwID, dwLevel)
    local nShowLevel = math.max(1, dwLevel)
    local tSkill = Table_GetSkill(dwID, nShowLevel)
    if not tSkill then
        return
    end

    local bShow = NewSkillPanel_IsShowByRelayOn(tSkill)
    if not bShow then
        return false
    end

    bShow = NewSkillPanel_IsShowByRelayOnNot(tSkill)
    if not bShow then
        return false
    end

    if not tSkill.IsShowNotLearn and dwLevel <= 0 then
        return false
    end

    return true
end

function NewSkillPanel_IsMatchSelectMount(tSkill, dwMKungfuID)
    if not tSkill then
        return false
    end

    if tSkill.dwMountRequestDetail == 0 then
        return true
    end

    if tSkill.dwMountRequestDetail == dwMKungfuID then
        return true
    end

    --藏剑特殊处理，藏剑两个内功都算当前内功
    --if (tSkill.dwMountRequestDetail == 10144 or tSkill.dwMountRequestDetail == 10145) and
    --        (dwMKungfuID == 10144 or dwMKungfuID == 10145)
    --then
    --    return true
    --end

    return false
end

function NewSkillPanel_GetKungFuList(bIsHD)
    local playerKungFuList = SkillData.GetKungFuList(bIsHD)
    local tLearnedKungFuSet = {}
    for _, tInfo in ipairs(playerKungFuList) do
        tLearnedKungFuSet[tInfo[1]] = true
    end

    table.sort(playerKungFuList, function(a, b)
        local nSkillIDA = a[1]
        local nSkillIDB = b[1]
        if bIsHD then
            local nTypeA = (PlayerKungfuPosition[nSkillIDA] or KUNGFU_POSITION.T) + (IsNoneSchoolKungfu(nSkillIDA) and 10000 or 0)
            local nTypeB = (PlayerKungfuPosition[nSkillIDB] or KUNGFU_POSITION.T) + (IsNoneSchoolKungfu(nSkillIDB) and 10000 or 0)
            return nTypeA < nTypeB or (nTypeA == nTypeB and nSkillIDA < nSkillIDB) --根据类型和ID进行相应的排序
        else
            local tbOrderA = TabHelper.GetUISkill(nSkillIDA).tbOrder or { [1] = 99 }
            local tbOrderB = TabHelper.GetUISkill(nSkillIDB).tbOrder or { [1] = 99 }
            return tbOrderA[1] < tbOrderB[1]  --根据技能类型和order进行相应的排序
        end
    end)

    local tList = bIsHD and { 10821 } or { 102393 }

    for _, nKungfuID in ipairs(tList) do
        if not tLearnedKungFuSet[nKungfuID] then
            table.insert(playerKungFuList, { nKungfuID }) -- 未学习流派心法时 加入心法列表
        end
    end

    return playerKungFuList
end

function NewSkillPanel_UnLockLiuPai(dwQuestID, bPreQuest, nHDKungfuID)
    if dwQuestID then
        if bPreQuest and g_pClientPlayer then
            local dwBelongSchoolID = GetSecondSchoolByKungfuID(nHDKungfuID)
            local szSchoolName = UIHelper.GBKToUTF8(Table_GetSkillSchoolName(dwBelongSchoolID))
            local szMessage = FormatString(g_tStrings.NEW_SKILL_MKUNGFU_PRE_QUEST_TIP, szSchoolName)
            
            UIHelper.ShowConfirm(szMessage, function()
                RemoteCallToServer("On_LiuPai_UnLock", nHDKungfuID)
            end)
        else
            MapMgr.TransferToNearestCity(dwQuestID)
        end
    end
end

---@class UIPanelSkillNew
local UIPanelSkillNew = class("UIPanelSkillNew")

function UIPanelSkillNew:OnEnter(nKungFuID)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
        self.bIsShowVK = true

        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.LayoutTrain)
        script:SetCurrencyType(CurrencyType.Train)
        script:HandleEvent()

        self:InitSwitchPlatform(nKungFuID)
        self:UpdatePlatformTag()
    end
end

function UIPanelSkillNew:OnExit()
    self:UnRegEvent()
end

function UIPanelSkillNew:InitSwitchPlatform(nKungFuID)
    local nKungFuID = nKungFuID or g_pClientPlayer.GetActualKungfuMountID()
    self.tDXScript = UIHelper.GetBindScript(self.WidgetSkillConfigurationDX)
    self.tVKScript = UIHelper.GetBindScript(self.WidgetSkillConfigurationVK)

    UIHelper.BindUIEvent(self.TogShowDX, EventType.OnSelectChanged, function(tog, bSelected)
        if bSelected then
            self.bIsShowVK = false
            self:SwitchPlatform()
        end
    end)

    UIHelper.BindUIEvent(self.TogShowVK, EventType.OnSelectChanged, function(tog, bSelected)
        if bSelected then
            self.bIsShowVK = true
            self:SwitchPlatform()
        end
    end)

    UIHelper.ToggleGroupAddToggle(self.TogGroupSwitchPlatform, self.TogShowVK)
    UIHelper.ToggleGroupAddToggle(self.TogGroupSwitchPlatform, self.TogShowDX)

    if TabHelper.IsHDKungfuID(nKungFuID) then
        self.bIsShowVK = false
        UIHelper.SetToggleGroupSelectedToggle(self.TogGroupSwitchPlatform, self.TogShowDX)
    end

    self:SwitchPlatform(nKungFuID)
end

function UIPanelSkillNew:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelSkillNew:RegEvent()
    Event.Reg(self, "DO_SKILL_PREPARE_PROGRESS", function(nTotalFrame, dwSkillID, dwSkillLevel, dwCasterID)
        local hPlayer = g_pClientPlayer
        local nChangeSkillID = 101164
        local nChangeSkillDXID = 9092
        if not (hPlayer and nTotalFrame > 0) or hPlayer.dwID ~= dwCasterID or (dwSkillID ~= nChangeSkillID and dwSkillID ~= nChangeSkillDXID) then
            return
        end

        local tParam = {
            szType = "Normal",
            szFormat = "切换配置",
            nDuration = nTotalFrame / GLOBAL.GAME_FPS,
            bNotShowDescribe = true,
            szIconPath = "UIAtlas2_MainCity_SystemMenu_IconSysteam15.png",
            fnCancel = function()
                GetClientPlayer().StopCurrentAction()
            end,
        }
        UIMgr.Open(VIEW_ID.PanelSystemPrograssBar, tParam)
    end)

    Event.Reg(self, "SKILL_MOUNT_KUNG_FU", function(arg0)
        self:UpdatePlatformTag()
        self.tDXScript:OnChangeKungFu(arg0)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.DelAllTimer(self)
        Timer.AddFrame(self, 3, function()
            UIHelper.LayoutDoLayout(self.LayoutRightTop)
        end)
    end)
end

function UIPanelSkillNew:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSkillNew:SwitchPlatform(nKungFuID)
    if self.bIsShowVK then
        self.tVKScript:OnEnter(nKungFuID)
        self.tDXScript:OnExit()
    else
        self.tDXScript:OnEnter(nKungFuID)
        self.tVKScript:OnExit()
    end

    UIHelper.SetVisible(self.BtnMacro, not self.bIsShowVK)
    UIHelper.SetVisible(self.WidgetSkillConfigurationDX, not self.bIsShowVK)
    UIHelper.SetVisible(self.WidgetDXLeftParent, not self.bIsShowVK)
    UIHelper.SetVisible(self.WidgetSkillConfigurationVK, self.bIsShowVK)
    UIHelper.SetVisible(self.WidgetVKLeftParent, self.bIsShowVK)
    UIHelper.LayoutDoLayout(self.LayoutRightTop)
end

function UIPanelSkillNew:UpdatePlatformTag()
    local bUsingDX = SkillData.IsUsingHDKungFu()
    UIHelper.SetVisible(self.ImgUsingDX, bUsingDX)
    UIHelper.SetVisible(self.ImgUsingVK, not bUsingDX)
end

return UIPanelSkillNew
