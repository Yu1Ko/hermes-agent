-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationFriendRecruit
-- Date: 2026-03-25 21:35:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationFriendRecruit = class("UIOperationFriendRecruit")

function UIOperationFriendRecruit:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    RemoteCallToServer("On_Recharge_GetFriendsPoints")
    OperationFriendRecruitData.ResetRuntimeState(true)
    OperationFriendRecruitData.RefreshReceivedReward()

    self:UpdateInfo()
end

function UIOperationFriendRecruit:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationFriendRecruit:BindUIEvent()

end

function UIOperationFriendRecruit:RegEvent()
end

function UIOperationFriendRecruit:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationFriendRecruit:UpdateInfo()
    local scriptBottom = self.tComponentContext and self.tComponentContext.scriptBottom
    if scriptBottom then
        scriptBottom:SetTitle("兑换奖励")
        local tList = OperationFriendRecruitData.GetAllRecruitRewardData()
        local parent = scriptBottom:GetPrefabParent(#tList)
        UIHelper.SetVisible(parent, true)
        UIHelper.RemoveAllChildren(parent)
        self.tScriptList = {}
        for i = #tList, 1, -1 do
            local tInfo = tList[i]
            local script = UIHelper.AddPrefab(scriptBottom.nPrefabID, parent, tInfo, i)
            table.insert(self.tScriptList, script)
        end
        UIHelper.ScrollViewDoLayout(parent)
        UIHelper.ScrollToLeft(parent)
    end
    Event.Dispatch(EventType.OnOperationRecruitSelectReward, 1)
end

return UIOperationFriendRecruit