-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaCreateTeamView
-- Date: 2022-12-30 15:22:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaCreateTeamView = class("UIArenaCreateTeamView")

function UIArenaCreateTeamView:OnEnter(nArenaType)
    self.nArenaType = nArenaType

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaCreateTeamView:OnExit()
    self.bInit = false
end

function UIArenaCreateTeamView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.ARENA, "") then
            return
        end
        
        local szName = UIHelper.GetText(self.EditBox)
        if not szName or szName == "" then
            TipsHelper.ShowNormalTip("请先输入队名")
            return
        end

        ArenaData.CreateCorps(self.nArenaType, szName)
    end)
end

function UIArenaCreateTeamView:RegEvent()
    Event.Reg(self, "CORPS_OPERATION", function(nType, nRetCode, dwCorpsID, dwCorpsType, dwOperatorID, dwBeOperatorID, szOperatorName, szBeOperatorName, szCorpsName)
		if nRetCode == CORPS_OPERATION_RESULT_CODE.SUCCESS then
			if nType == CORPS_OPERATION_TYPE.CORPS_CREATE then
                UIMgr.Close(self)
			end
		end
    end)
end

function UIArenaCreateTeamView:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, string.format("请输入%s队名", g_tStrings.tCorpsType[self.nArenaType]))
    UIHelper.SetString(self.LabelCreationTeamCost, tostring(ArenaData.CREATE_GOLD))

end


return UIArenaCreateTeamView