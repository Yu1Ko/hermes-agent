-- ---------------------------------------------------------------------------------
-- Author: yuminqian
-- Name: UIArenaQiXuePageCell
-- Date: 2025-7-3 14:48:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@class UIArenaQiXuePageCell
local UIArenaQiXuePageCell = class("UIArenaQiXuePageCell")
local PLAYER_NAME_MAX_LEN = 6
local QIXUE_MAX_NUM = 6
local JIANG_HU_TYPE = 11
local MountRequestTypeDict = {
    [0] = 1,
    [JIANG_HU_TYPE] = 1
}

function UIArenaQiXuePageCell:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not tInfo then
        return
    end

    self.dwID = tInfo.dwID
    local hPlayer = GetPlayer(self.dwID)
    local szName = UIHelper.GBKToUTF8(tInfo.szName)
    UIHelper.SetString(self.LabelPlayerName, UIHelper.LimitUtf8Len(szName, PLAYER_NAME_MAX_LEN))

    local dwKungFu = tInfo.dwMountKungfuID
    if hPlayer then
        dwKungFu = hPlayer.GetActualKungfuMountID() or tInfo.dwMountKungfuID
    end
    local szKungFuName = Table_GetSkillName(dwKungFu, 1)
    local szKungFuImgPath = PlayerKungfuImg[dwKungFu] 
    if szKungFuImgPath then
        UIHelper.SetSpriteFrame(self.ImgXinFa, szKungFuImgPath)
    end
    UIHelper.SetVisible(self.ImgXinFa, true)

    self.tInfo = tInfo
    self:UpdateInfo()
end

function UIArenaQiXuePageCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIArenaQiXuePageCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReport, EventType.OnClick, function()
        RemoteCallToServer("On_XinYu_Jubao", self.dwID, self.tInfo.szName)
        Event.Dispatch(EventType.OnArenaFinishDataReport, self.dwID)
    end)
end

function UIArenaQiXuePageCell:RegEvent()
    Event.Reg(self, EventType.OnArenaFinishDataReport, function(dwID)
        if self.dwID and dwID == self.dwID then
            UIHelper.SetButtonState(self.BtnReport, BTN_STATE.Disable, "已举报过该玩家")
        end
    end)
end

function UIArenaQiXuePageCell:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIArenaQiXuePageCell:UpdateInfo()
    local dwID = self.dwID
    local tInfo = self.tInfo
    local hPlayer = GetPlayer(dwID)
    if hPlayer then
        local dwForceID = hPlayer.dwForceID
        local nCurrentKungFuID = hPlayer.GetActualKungfuMountID()
        if nCurrentKungFuID then
            tInfo.dwMountKungfuID = nCurrentKungFuID
        end
        local nSetID = hPlayer.GetTalentCurrentSet(dwForceID, nCurrentKungFuID) or 0

        tInfo.tTalentInfo = hPlayer.GetTalentInfo(hPlayer.dwForceID, tInfo.dwMountKungfuID, nSetID)
        tInfo.tSkillInfo = hPlayer.GetSlotToSkillList(nSetID)
        -- 1-5 为普通招式槽位 小轻功相关数据放在第六槽位
        tInfo.tSkillInfo[6] = SkillData.GetForceSpecialSprintID(hPlayer.dwSchoolID)

        local tKungfu = nCurrentKungFuID and nCurrentKungFuID > 0 and GetSkill(nCurrentKungFuID, 1)
        if tKungfu and tKungfu.dwMountType then
            tInfo.nKungfuMountType = tKungfu.dwMountType
        end

        Timer.AddFrame(self, 0.01, function()
            self.tEquippedSkillList = {}

            for i = 1, QIXUE_MAX_NUM do
                if self.tbSkillList and self.tbSkillList[i] then
                    self:UpdatePlayerSkillInfo(i, self.tbSkillList[i])
                end
            end

            for k, tQixue in ipairs(tInfo.tTalentInfo) do
                if self.tbQiXueList and self.tbQiXueList[k] then
                    self:UpdatePlayerQiXueInfo(tQixue, self.tbQiXueList[k], hPlayer)
                end
            end    
        end)
    end

    self:OnUpdatePage(true, false)

end

function UIArenaQiXuePageCell:UpdatePlayerQiXueInfo(tQixue, hCell, hPlayer)
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
        local script = UIHelper.AddPrefab(bIsPassiveSkill and PREFAB_ID.WidgetSkillPassiveCell or PREFAB_ID.WidgetSkillCell1, hCell, dwID, dwLevel)
        local toggle = script:GetToggle()
        script:ShowName(true)
        script:BindSelectFunction(function()
            local fnClose = function()
                UIHelper.SetSelected(toggle, false)
            end
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip, toggle, TipsLayoutDir.LEFT_CENTER)
            if hPlayer then
                script:SetPlayer(hPlayer)
            end
            script:Init(tSkillArray[nSelectIndex], false, nil, fnClose, self.tEquippedSkillList)
            script:HideButton()
        end)

        if not bIsPassiveSkill then
            table.insert(self.tEquippedSkillList, dwID) -- 触发技能放已装备队列
        end
    else
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, hCell)
        script:ShowEmptyState()
        script:SetSelectEnable(false)
    end

    UIHelper.SetVisible(self.BtnReport, self.tInfo.bCanReport)
    UIHelper.SetVisible(hCell, true)
end

function UIArenaQiXuePageCell:UpdatePlayerSkillInfo(nIndex, hCell)
    local tInfo = self.tInfo
    local tSkill = tInfo.tSkillInfo[nIndex]
    local nSkillID = nil
    for _, nID in ipairs(tSkill) do
        if nID > 0 then
            local skill = GetSkill(nID, 1)
            if skill and skill.dwMountRequestDetail == tInfo.dwMountKungfuID or (skill.dwMountRequestDetail == 0 and
                    (skill.dwMountRequestType == tInfo.nKungfuMountType or MountRequestTypeDict[skill.dwMountRequestType] == 1)) then
                nSkillID = nID
                table.insert(self.tEquippedSkillList, nSkillID)
            end
        end
    end

    if not nSkillID then
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, hCell)
        script:ShowEmptyState()
    else
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, hCell, nSkillID, 1)
        local toggle = script:GetToggle()
        script:ShowName(true, 5)
        script:BindSelectFunction(function()
            local fnClose = function()
                UIHelper.SetSelected(toggle, false)
            end

            local nFakeMijiIndex = nil
            local hPlayer = GetPlayer(self.dwID)
            if not hPlayer then
                return TipsHelper.ShowImportantYellowTip(g_tStrings.STR_PLAYER_LEAVE)
            else
                local tRecipe = SkillData.GetFinalRecipeList(nSkillID, hPlayer)
                if tRecipe then
                    for j = 1, #tRecipe do
                        if tRecipe[j].active then
                            nFakeMijiIndex = j
                        end
                    end
                end
            end

            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, toggle, TipsLayoutDir.LEFT_CENTER)
            script:InitDisplayOnly(nSkillID, tInfo.dwMountKungfuID, nFakeMijiIndex, hPlayer)
            script:BindExitFunc(fnClose)
            if not nFakeMijiIndex then
                script:HideMiji()
            end
        end)
    end
    UIHelper.SetVisible(hCell, true)
end

function UIArenaQiXuePageCell:OnUpdatePage(bQiXue, bSkill)
    UIHelper.SetVisible(self.ListSkill, bSkill)
    UIHelper.SetVisible(self.ListQiXue, bQiXue) 
    UIHelper.SetVisible(self.BtnReport, bQiXue and self.tInfo.bCanReport)
end

return UIArenaQiXuePageCell