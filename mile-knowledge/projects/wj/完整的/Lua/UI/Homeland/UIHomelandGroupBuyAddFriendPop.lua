-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandGroupBuyAddFriendPop
-- Date: 2024-02-18 15:46:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandGroupBuyAddFriendPop = class("UIHomelandGroupBuyAddFriendPop")
local m_bRefresh = true
-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.GetFriendGroup()
    DataModel.tFriendGroup = FellowshipData.GetFellowshipGroupInfo()
    for _, tGroup in pairs(DataModel.tFriendGroup) do
        tGroup.tFriendList = FellowshipData.GetFellowshipInfoListByGroup(tGroup.id)
        local i = 1
        while i <= #tGroup.tFriendList do
            local szGlobalID = tGroup.tFriendList[i].id
            local aRoleEntery = FellowshipData.GetRoleEntryInfo(szGlobalID)
            local bOnLine = FellowshipData.IsOnline(szGlobalID)
            local bIsRemote = FellowshipData.IsRemoteFriend(szGlobalID)
            if not bOnLine or bIsRemote then
                table.remove(tGroup.tFriendList, i)
            else
                tGroup.tFriendList[i].name = aRoleEntery.szName
                tGroup.tFriendList[i].aRoleEntery = aRoleEntery
                i = i + 1
            end
        end
    end
end

function DataModel.UnInit()
    DataModel.tFriendGroup = nil
    DataModel.tChoosedFriend = nil
    m_bRefresh = true
    m_tAnchor = nil
end



function DataModel.Init()
    DataModel.tFriendGroup = nil
    DataModel.tChoosedFriend = {}
    DataModel.GetFriendGroup()
    m_bRefresh = true
end

function DataModel.TurnSelectStatus(tPlayer)
    if tPlayer then
        if DataModel.tChoosedFriend[tPlayer.name] then
            DataModel.tChoosedFriend[tPlayer.name] = nil
        else
            DataModel.tChoosedFriend[tPlayer.name] = true
        end
    end
end

function DataModel.ClearFriendChoosedFlag()
    DataModel.tChoosedFriend = {}
end

function UIHomelandGroupBuyAddFriendPop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        DataModel.Init()
        self.bInit = true
    end
    self.szSearchKey = nil
    self:UpdateInfo()
end

function UIHomelandGroupBuyAddFriendPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandGroupBuyAddFriendPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnInvite, EventType.OnClick, function(btn)
        for name, _ in pairs(DataModel.tChoosedFriend) do
            GetHomelandMgr().BuyLandGrouponAddPlayerRequest(name)
        end
        DataModel.ClearFriendChoosedFlag()
    end)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function(btn)
        DataModel.Init()
        self:UpdateFriendsList()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function ()
        local szSearchKey = UIHelper.GetString(self.EditKindSearch)
        self.szSearchKey = szSearchKey
        self:UpdateFriendsList()
    end)
end

function UIHomelandGroupBuyAddFriendPop:RegEvent()
    Event.Reg(self, "PLAYER_FELLOWSHIP_UPDATE", function ()
        DataModel.Init()
        self:UpdateFriendsList()
    end)

    Event.Reg(self, EventType.OnHomelandGroupBuyInviteFriend, function (tPlayer)
        DataModel.TurnSelectStatus(tPlayer)
    end)
end

function UIHomelandGroupBuyAddFriendPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandGroupBuyAddFriendPop:UpdateInfo()
    self:UpdateFriendsList()
end

function UIHomelandGroupBuyAddFriendPop:UpdateFriendsList()
    local tbPlayerList = {}
    UIHelper.RemoveAllChildren(self.ScrollViewMessageContent)
    for i, tGroup in pairs(DataModel.tFriendGroup) do
        for j, tPlayer in pairs(tGroup.tFriendList) do
            local szName = UIHelper.GBKToUTF8(tPlayer.name)
            if self.szSearchKey then
                if string.find(szName, self.szSearchKey) then
                    table.insert(tbPlayerList, tPlayer)
                end
            else
                table.insert(tbPlayerList, tPlayer)
            end
        end
    end
    for _, tPlayer in ipairs(tbPlayerList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFriendTog, self.ScrollViewMessageContent)
        script:OnEnter(tPlayer)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewMessageContent)
    UIHelper.ScrollToTop(self.ScrollViewMessageContent)
end

return UIHomelandGroupBuyAddFriendPop