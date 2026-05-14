-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillConfigurationCell
-- Date: 2022-11-23 10:01:29
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class UIWidgetConfigurationAccupointTip
local UIWidgetConfigurationAccupointTip = class("UIWidgetConfigurationAccupointTip")

function UIWidgetConfigurationAccupointTip:OnEnter(nCurrentKungFuID, nCurrentSetID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.nCurrentKungFuID = nCurrentKungFuID
        self.nCurrentSetID = nCurrentSetID
        self.tQiXueList = SkillData.GetQixueList(true, self.nCurrentKungFuID, self.nCurrentSetID)
    end
    self:UpdateInfo()
end

function UIWidgetConfigurationAccupointTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if self.fnExit then
        self.fnExit()
    end
end

function UIWidgetConfigurationAccupointTip:BindUIEvent()

end

function UIWidgetConfigurationAccupointTip:RegEvent()
    Event.Reg(self, "ON_UPDATE_TALENT", function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetConfigurationAcupointTip)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetAcupointTip)
    end)
end

function UIWidgetConfigurationAccupointTip:UnRegEvent()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetConfigurationAccupointTip:UpdateInfo()
    UIHelper.RemoveAllChildren(self.WidgetSkillCell1)
    UIHelper.RemoveAllChildren(self.WidgetSkillCell2)

    local nPrefabID = PREFAB_ID.WidgetSkillCell1
    local tList = self.tQiXueList
    local tQixue = tList[4]
    local bIconVisible = false

    if tQixue then
        local dwPointID = tQixue.dwPointID
        local nRequireLevel = tQixue.nRequireLevel
        local nSelectIndex = tQixue.nSelectIndex
        local tSkillArray = tQixue.SkillArray

        bIconVisible = nSelectIndex > 0

        local script1 = UIHelper.AddPrefab(nPrefabID, self.WidgetSkillCell1, tSkillArray[1].dwSkillID)
        local script2 = UIHelper.AddPrefab(nPrefabID, self.WidgetSkillCell2, tSkillArray[2].dwSkillID)
        self.tScripts = { script1, script2 }

        for index, script in ipairs(self.tScripts) do
            local hPlayer = g_pClientPlayer
            if hPlayer and hPlayer.nLevel < SKILL_RESTRICTION_LEVEL then
                UIHelper.SetNodeGray(script.TogSkill, true, true)
                script:BindSelectFunction(function()
                    TipsHelper.ShowNormalTip("侠士达到106级后方可切换奇穴")
                    Timer.AddFrame(self, 1, function()
                        script:SetSelected(false)
                    end)
                end)
            else
                script:BindSelectFunction(function()
                    self:ShowTip(index, script)
                end)
            end
            
            UIHelper.SetTouchDownHideTips(script:GetToggle(),false)
        end

        if nSelectIndex > 0 then
            self.tScripts[nSelectIndex]:SetUsed(true)
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetConfigurationAccupointTip:ShowTip(nSubIndex, iconScript)
    local nQiXueIndex = 4
    local tList = self.tQiXueList
    local nSelectIndex = tList[nQiXueIndex].nSelectIndex
    local dwPointID = tList[nQiXueIndex].dwPointID

    local fnChangeQiXue = function()
        return SkillData.ChangeQiXue(dwPointID, nSubIndex, self.nCurrentKungFuID, self.nCurrentSetID)
    end

    local fnClose = function()
        if iconScript then
            iconScript:SetSelected(false)
        end
    end

    local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAcupointTip, iconScript._rootNode, TipsLayoutDir.BOTTOM_LEFT)
    local pw, ph = UIHelper.GetContentSize(script._rootNode)
    tip:SetSize(pw + 50, ph + 200)
    tip:Update()

    script:Init(tList[nQiXueIndex].SkillArray[nSubIndex], nSelectIndex == nSubIndex, fnChangeQiXue, fnClose)

    if self.nCurrentKungFuID ~= g_pClientPlayer.GetActualKungfuMount().dwSkillID then
        script:DisableButton()
    end
    
    local scriptBG = UIMgr.AddPrefab(PREFAB_ID.WidgetTouchBackGround, script._rootNode, true, script)
    scriptBG:SetTouchDownHideTips(PREFAB_ID.WidgetAcupointTip)
end

function UIWidgetConfigurationAccupointTip:BindExitFunc(fnFunc)
    if IsFunction(fnFunc) then
        self.fnExit = fnFunc
    end
end


return UIWidgetConfigurationAccupointTip