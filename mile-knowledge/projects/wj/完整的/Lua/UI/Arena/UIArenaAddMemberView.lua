-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaAddMemberView
-- Date: 2023-01-03 20:05:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaAddMemberView = class("UIArenaAddMemberView")

function UIArenaAddMemberView:OnEnter(nArenaType)
    self.nArenaType = nArenaType

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIArenaAddMemberView:OnExit()
    self.bInit = false
end

function UIArenaAddMemberView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        local szName = UIHelper.GetText(self.EditBox)
        if not szName or szName == "" then
            TipsHelper.ShowNormalTip("请先输入玩家名")
            return
        end

        local nPlayerID = PlayerData.GetPlayerID()
        local nCorpsID = ArenaData.GetCorpsID(self.nArenaType, nPlayerID)
        if nCorpsID and nCorpsID > 0 then
            ArenaData.InvitationJoinCorps(szName, nCorpsID)
            TipsHelper.ShowNormalTip("已成功发出邀请")
            UIMgr.Close(self)
        else
            TipsHelper.ShowNormalTip("你当前暂无战队")
            return
        end
    end)
end

function UIArenaAddMemberView:RegEvent()
    Event.Reg(self, "CORPS_OPERATION", function(nType, nRetCode, dwCorpsID, dwCorpsType, dwOperatorID, dwBeOperatorID, szOperatorName, szBeOperatorName, szCorpsName)
		if nRetCode == CORPS_OPERATION_RESULT_CODE.SUCCESS then
			if nType == CORPS_OPERATION_TYPE.CORPS_ADD_MEMBER then
                UIMgr.Close(self)
			end
		end
    end)
end

function UIArenaAddMemberView:UpdateInfo()

end


return UIArenaAddMemberView