local UIMonsterBookSkillEntranceButton = class("UIMonsterBookSkillEntranceButton")

function UIMonsterBookSkillEntranceButton:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bDbmState = false
    self:UpdateInfo()
end

function UIMonsterBookSkillEntranceButton:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMonsterBookSkillEntranceButton:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnExit, EventType.OnClick, function ()
        self:LeaveDungeonScene()
    end)

    UIHelper.BindUIEvent(self.BtnSkill, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelBaizhanMain, 2)
    end)

    UIHelper.BindUIEvent(self.BtnMove, EventType.OnClick, function ()
        RemoteCallToServer("On_MonsterBook_OpenTower")
    end)
end

function UIMonsterBookSkillEntranceButton:RegEvent()
    Event.Reg(self, "QUEST_FINISHED", function(nQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
        if nQuestID == MonsterBookData.dwLevelChoosePreQuestID1 or nQuestID == MonsterBookData.dwLevelChoosePreQuestID2 then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "ON_ENTER_BAIZHAN_DBM", function (bStart, nGroupID)
        self.bDbmState = bStart
        UIHelper.SetVisible(self.BtnSkill, not self.bDbmState)
        self:UpdateInfo()
	end)

    Event.Reg(self, "ON_UPDATEBOSSDBM_STATE", function(bShow)
        self.bDbmState = bShow
		UIHelper.SetVisible(self.BtnSkill, not bShow)
        self:UpdateInfo()
    end)
end

function UIMonsterBookSkillEntranceButton:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMonsterBookSkillEntranceButton:UpdateInfo()
    UIHelper.SetVisible(self.BtnMove, MonsterBookData.IsFinishLevelChoosePreQuest() and not self.bDbmState)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.BtnMove))
end

function UIMonsterBookSkillEntranceButton:LeaveDungeonScene()
	if RoomData.IsInGlobalRoomDungeon() then
		RoomData.ConfirmLeaveRoomScene()
	else
		local confirmDialog = UIHelper.ShowConfirm(g_tStrings.STR_ROOM_LEAVE_DUNGEON_MAP_CONFIRM, function()
			RemoteCallToServer("On_Dungeon_Leave")
		end, nil)
		confirmDialog:SetButtonContent("Confirm", g_tStrings.STR_HOTKEY_SURE)
	end
end

return UIMonsterBookSkillEntranceButton