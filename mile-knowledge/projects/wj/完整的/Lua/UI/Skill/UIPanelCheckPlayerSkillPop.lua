-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelCheckPlayerSkillPop
-- Date: 2024-5-14 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIPanelCheckPlayerSkillPop
local UIPanelCheckPlayerSkillPop = class("UIPanelCheckPlayerSkillPop")

function UIPanelCheckPlayerSkillPop:OnEnter(dwTargetID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local hPlayer = GetPlayer(dwTargetID)
    if not hPlayer then
        return
    end

    local szName = UIHelper.GBKToUTF8(hPlayer.szName)
    local dwSkillID = hPlayer.GetActualKungfuMountID()
    if not dwSkillID then
        return
    end

    local szKungFuName = Table_GetSkillName(dwSkillID, 1)
    local szKungFuImgPath = PlayerKungfuImg[dwSkillID]
    UIHelper.SetString(self.LabelPlayerName, szName)
    UIHelper.SetString(self.LabelPlayerSkill, UIHelper.GBKToUTF8(szKungFuName))
    if szKungFuImgPath then
        UIHelper.SetSpriteFrame(self.ImgKungFu, szKungFuImgPath)
    end

    self.hPlayer = hPlayer
    self.dwTargetID = dwTargetID
    self:UpdateInfo(hPlayer)
end

function UIPanelCheckPlayerSkillPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelCheckPlayerSkillPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelCheckPlayerSkillPop:RegEvent()
    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if string.is_nil(szUrl) then
            return
        end

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillAttributeTips)
        local tCursor = Platform.IsWindows() and GetViewCursorPoint() or GetCursorPoint()
        TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetSkillAttributeTips, tCursor.x, tCursor.y, szUrl, SkillData.tTotalNoun)
    end)

    --Event.Reg(self, "UPDATE_TALENT_SET_SLOT_SKILL", function()
    --    if self.hPlayer then
    --        self:UpdateNormalSkill(self.LayoutSkill2, self.hPlayer)
    --    end
    --end)
end

function UIPanelCheckPlayerSkillPop:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelCheckPlayerSkillPop:UpdateInfo(hPlayer)
    local dwForceID = hPlayer.dwForceID
    local tKungFu = hPlayer.GetActualKungfuMount()
    local nCurrentKungFuID = tKungFu.dwSkillID
    local nCurrentSetID = hPlayer.GetTalentCurrentSet(dwForceID, nCurrentKungFuID)
    local layout = self.LayoutSkill

    local tList = hPlayer.GetTalentInfo(dwForceID, nCurrentKungFuID, nCurrentSetID)
    local bIsMobile = SkillData.IsMobileKungFu(tKungFu, hPlayer)

    if not bIsMobile then
        layout = self.LayoutSkillPc
        UIHelper.SetVisible(self.WidgetSkillVk, false)
        UIHelper.SetVisible(self.WidgetSkillPc, true)
        UIHelper.SetVisible(self.ImgPc, true)
        UIHelper.LayoutDoLayout(self.LayoutName, true)
    end

    Timer.AddFrame(self, 0.01, function()
        self.tEquippedSkillList = {}
        if bIsMobile then
            self:UpdateNormalSkill(self.LayoutSkill2, hPlayer)
        end
        for _, tQixue in ipairs(tList) do
            self:UpdateQixueSkill(tQixue, layout, hPlayer)
        end
    end)
end

local JIANG_HU_TYPE = 11
local MountRequestTypeDict = {
    [0] = 1,
    [JIANG_HU_TYPE] = 1
}

function UIPanelCheckPlayerSkillPop:UpdateNormalSkill(layout, hPlayer)
    local nSetID
    local nCurrentKungFuID = hPlayer.GetActualKungfuMountID()
    if nCurrentKungFuID then
        nSetID = hPlayer.GetTalentCurrentSet(hPlayer.dwForceID, nCurrentKungFuID)
    end
    local tKungfu = nCurrentKungFuID and nCurrentKungFuID > 0 and GetSkill(nCurrentKungFuID, 1)
    local nKungfuMountType = tKungfu and tKungfu.dwMountType

    local slotSkills = hPlayer.GetSlotToSkillList(nSetID)
    -- 1-5 为普通招式槽位 策划说还想看小轻功 将相关数据放在第六槽位
    slotSkills[6] = SkillData.GetForceSpecialSprintID(hPlayer.dwSchoolID)

    for i = 1, 6 do
        local tSkill = slotSkills[i]
        local nSkillID = nil
        for _, nID in ipairs(tSkill) do
            if nID > 0 then
                local skill = GetSkill(nID, 1)
                if skill and skill.dwMountRequestDetail == nCurrentKungFuID or (skill.dwMountRequestDetail == 0 and
                        (skill.dwMountRequestType == nKungfuMountType or MountRequestTypeDict[skill.dwMountRequestType] == 1)) then
                    nSkillID = nID
                    table.insert(self.tEquippedSkillList, nSkillID)
                end
            end
        end

        if not nSkillID then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, layout)
            script:ShowEmptyState()
        else
            local tRecipe = SkillData.GetFinalRecipeList(nSkillID, hPlayer)
            local nFakeMijiIndex = nil
            if tRecipe then
                for i = 1, #tRecipe do
                    if tRecipe[i].active then
                        nFakeMijiIndex = i
                    end
                end
            end

            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, layout, nSkillID, 1)
            local toggle = script:GetToggle()
            script:ShowName(true, 5)
            script:BindSelectFunction(function()
                local fnClose = function()
                    UIHelper.SetSelected(toggle, false)
                end

                local hPlayer = GetPlayer(self.dwTargetID)
                if not hPlayer then
                    return TipsHelper.ShowImportantYellowTip("玩家已下线")
                end

                local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, toggle, TipsLayoutDir.LEFT_CENTER)
                script:InitDisplayOnly(nSkillID, nCurrentKungFuID, nFakeMijiIndex, hPlayer)
                script:BindExitFunc(fnClose)
                if not nFakeMijiIndex then
                    script:HideMiji()
                end
            end)
        end
    end

    --local tSkills = slotSkills[nSlotID]
end

function UIPanelCheckPlayerSkillPop:UpdateQixueSkill(tQixue, layout, hPlayer)
    local nSelectIndex = tQixue.nSelectIndex
    local tSkillArray = tQixue.SkillArray

    local dwID, dwLevel
    if nSelectIndex > 0 then
        local tSkill = tSkillArray[nSelectIndex]
        dwID = tSkill.dwSkillID
        dwLevel = tSkill.dwSkillLevel
    end

    local tSkill
    if dwID and dwLevel and dwID ~= 0 then
        tSkill = GetSkill(dwID, dwLevel)
    end

    if tSkill then
        local bIsPassiveSkill = tSkill.bIsPassiveSkill
        local script = UIHelper.AddPrefab(bIsPassiveSkill and PREFAB_ID.WidgetSkillPassiveCell or PREFAB_ID.WidgetSkillCell1, layout, dwID, dwLevel)
        local toggle = script:GetToggle()
        script:ShowName(true)
        script:BindSelectFunction(function()
            local fnClose = function()
                UIHelper.SetSelected(toggle, false)
            end

            local hPlayer = GetPlayer(self.dwTargetID)
            if not hPlayer then
                return TipsHelper.ShowImportantYellowTip("玩家已下线")
            end
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip, toggle, TipsLayoutDir.LEFT_CENTER)
            script:SetPlayer(hPlayer)
            script:Init(tSkillArray[nSelectIndex], false, nil, fnClose, self.tEquippedSkillList)
            script:HideButton()
        end)

        if not bIsPassiveSkill then
            table.insert(self.tEquippedSkillList, dwID) -- 触发技能放已装备队列
        end
    else
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, layout)
        script:ShowEmptyState()
        script:SetSelectEnable(false)
    end

    UIHelper.LayoutDoLayout(layout)
end

return UIPanelCheckPlayerSkillPop