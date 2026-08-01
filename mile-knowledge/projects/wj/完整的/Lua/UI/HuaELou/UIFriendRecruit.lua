-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFriendRecruit
-- Date: 2023-05-23 11:28:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFriendRecruit = class("UIFriendRecruit")

local nRecruitPoint = 0

local UrlFriendRecallIndex = "http://jx3.xoyo.com/zt/2015/02/06/friend/index.html?param=" --好友招募
local UrlFriendRecallList = "http://jx3.xoyo.com/zt/2015/02/06/friend/list.html?param=" --好友邀请信息

function UIFriendRecruit:OnEnter(dwOperatActID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    -- self.szUrl = Login.GetAutoLoginSpecialUrl(tUrl.FriendRecallIndex) --好友招募
    self.nCurRewardIndex = 1
    RemoteCallToServer("On_Recharge_GetFriendsPoints")
    self:IfRewardExist()
    self:UpdateInfo()
    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end
end

function UIFriendRecruit:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFriendRecruit:BindUIEvent()
    --受邀人状态
    UIHelper.BindUIEvent(self.BtnStatus,EventType.OnClick,function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "COIN") then
            return
        end
        local szUrl = self:GetAutoLoginUrl(UrlFriendRecallList)
        UIHelper.OpenWeb(szUrl)
    end)

    --发送邀请
    UIHelper.BindUIEvent(self.BtnInvite,EventType.OnClick,function ()
        UIMgr.Open(VIEW_ID.PanelInviteMailPop)
    end)

    --复制链接
    UIHelper.BindUIEvent(self.BtnCopyLink,EventType.OnClick,function ()
        local szUrl = self:GetAutoLoginSpecialUrl(UrlFriendRecallIndex)
        SetClipboard(szUrl)

        TipsHelper.ShowNormalTip(g_tStrings.STR_COPY_SUCESS)
    end)

    --兑换
    UIHelper.BindUIEvent(self.BtnGetReward,EventType.OnClick,function ()
        self:GetFriendInvReward()
    end)

    UIHelper.BindUIEvent(self.WidgetInvitePoint,EventType.OnClick,function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips,self.WidgetInvitePoint, g_tStrings.STR_FRIEND_RECRUIT)
    end)
end

function UIFriendRecruit:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "On_Recharge_GetFriendsPoints_CallBack", function (nLeftPoint)
        nRecruitPoint = nLeftPoint
        UIHelper.SetString(self.LabelMoney,nRecruitPoint)
        UIHelper.LayoutDoLayout(self.WidgetMoney1)
    end)

    Event.Reg(self, "On_Recharge_GetFriInvReward_CallBack", function (nRewardIndex, nCost)
        if not nRewardIndex and not nCost then
            return
        end

        self:UpdateRecruitPoint()
    end)
end

function UIFriendRecruit:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFriendRecruit:IfRewardExist()
    --引用自这个脚本，判断有没有领取奖励的方法是判断玩家有没有此物品
    --scripts/Include/UIscript/UIscript_FriendsInvite.lua
    self.tbRewardExist = {
        [EQUIPMENT_SUB.PET] = function (dwTabType, dwIndex) return g_pClientPlayer.IsFellowPetAcquired(dwTabType, dwIndex) end,
        [EQUIPMENT_SUB.HORSE] = function () return false end,
        [EQUIPMENT_SUB.HORSE_EQUIP] = function (_, dwIndex) return g_pClientPlayer.IsHorseEquipExist(dwIndex) end,
        [EQUIPMENT_SUB.BACK_EXTEND] = function (_, dwIndex) return g_pClientPlayer.IsPendentExist(dwIndex) end,
        [EQUIPMENT_SUB.WAIST_EXTEND] = function (_, dwIndex) return g_pClientPlayer.IsPendentExist(dwIndex) end,
    }
end

function UIFriendRecruit:UpdateInfo()
    self:GetRecruitRewardDataFromOperatActFRecall()
    self:InitLeftListRewardInfo()
    self:UpdateRecruitPoint()
end

function UIFriendRecruit:GetRecruitRewardDataFromOperatActFRecall()
    local tNewList = {}
	local tOldList = {}
	self.tLastList 	= {}
	local tList = Table_GetOperatActFRecall()

    for k, v in pairs(tList) do
		if v.bNewProduct == 1 then
			table.insert(tNewList, v)
		else
			table.insert(tOldList, v)
		end
	end

    table.sort(tNewList, function(a, b) return a.dwIntergral > b.dwIntergral end)
	table.sort(tOldList, function(a, b) return a.dwIntergral > b.dwIntergral end)

    for k, v in pairs(tNewList) do
		table.insert(self.tLastList, v)
	end

	for k, v in pairs(tOldList) do
		table.insert(self.tLastList, v)
	end
end

function UIFriendRecruit:InitLeftListRewardInfo()
    local tAllRecruitRewardInfo = self.tLastList
    self.tRewardCellSript = {}

    UIHelper.RemoveAllChildren(self.ScrollViewReward)
    local tbItemScript = {}
    for nRewardIndex, tRewardInfo in ipairs(tAllRecruitRewardInfo) do
        local RewardCellSript = UIHelper.AddPrefab(PREFAB_ID.WidgetFriendRecruitRewardCell,self.ScrollViewReward) assert(RewardCellSript)
        UIHelper.SetString(RewardCellSript.LabelMoney, tRewardInfo.dwIntergral)
        if tRewardInfo.szFRecallReward ~= "" then
			local tReward = SplitString(tRewardInfo.szFRecallReward, ";")
            local dwTabType, dwIndex, nCount = tReward[1], tReward[2], 1
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, RewardCellSript.WidgetItem) assert(itemScript)
            itemScript:OnInitWithTabID(tonumber(dwTabType), tonumber(dwIndex), nCount)
            itemScript:SetClickCallback(function (nTabType, nTabID)
                if nTabType and nTabID then
                    TipsHelper.ShowItemTips(self.BtnStatus, nTabType, nTabID)
                    if UIHelper.GetSelected(itemScript.ToggleSelect) then
                        UIHelper.SetSelected(itemScript.ToggleSelect,false)
                    end
                end
            end)
            table.insert(tbItemScript,itemScript)
		end

        UIHelper.ToggleGroupAddToggle(self.toggleGroup,RewardCellSript.TogRewardCell)
        UIHelper.BindUIEvent(RewardCellSript.TogRewardCell,EventType.OnClick,function ()
            UIHelper.SetTexture(self.ImgRewardPreview,FriendRecruitImg[tRewardInfo.dwID])
            self.nCurRewardIndex = nRewardIndex
        end)
        table.insert(self.tRewardCellSript,RewardCellSript)
    end
    UIHelper.SetTexture(self.ImgRewardPreview,FriendRecruitImg[11])
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReward)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewReward, self.WidgetArrow)
end

function UIFriendRecruit:GetFriendInvReward()
    local szRewardName = UIHelper.GBKToUTF8(self.tLastList[self.nCurRewardIndex].szName)
    local nImgRewardCost = self.tLastList[self.nCurRewardIndex].dwIntergral
    local nRewardIndex = self.tLastList[self.nCurRewardIndex].dwID
    UIHelper.ShowConfirm(FormatString(g_tStrings.BUY_REWARD_SURE, nImgRewardCost, szRewardName),function ()
        RemoteCallToServer("On_Recharge_GetFriInvReward", nRewardIndex)
    end)
end

function UIFriendRecruit:UpdateRecruitPoint()
    UIHelper.SetString(self.LabelMoney,nRecruitPoint)

    local tAllRecruitRewardInfo = self.tLastList
    for nIndex, tRewardInfo in ipairs(tAllRecruitRewardInfo) do
        local tReward = SplitString(tRewardInfo.szFRecallReward, ";")
        local dwTabType, dwIndex = tonumber(tReward[1]), tonumber(tReward[2])
        local nState = self:GetPointRewardState(dwTabType, dwIndex, tRewardInfo.dwIntergral)

        local RewardCellSript = self.tRewardCellSript[nIndex]
        UIHelper.SetVisible(RewardCellSript.LabelNotAchieved,nState == OPERACT_REWARD_STATE.NON_GET)
        UIHelper.SetVisible(RewardCellSript.LabelAchieved,nState == OPERACT_REWARD_STATE.CAN_GET)
        UIHelper.SetVisible(RewardCellSript.LabelGotten,nState == OPERACT_REWARD_STATE.ALREADY_GOT)
    end
end

function UIFriendRecruit:GetPointRewardState(dwTabType,dwIndex,dwIntergral)
    local bGotten = false
    if g_pClientPlayer.GetItemAmountInAllPackages(dwTabType, dwIndex) >= 1 then
        bGotten = true
    else
        local ItemInfo = GetItemInfo(dwTabType,dwIndex)
        bGotten = self.tbRewardExist[ItemInfo.nSub](dwTabType,dwIndex)
    end

    local nState = OPERACT_REWARD_STATE.NON_GET
    if bGotten then
        nState = OPERACT_REWARD_STATE.ALREADY_GOT
    elseif nRecruitPoint >= dwIntergral then
        nState = OPERACT_REWARD_STATE.CAN_GET
    end

    return nState
end

function UIFriendRecruit:GetAutoLoginSpecialUrl(url)
    local account = Login_GetAccount()
    -- local ip = (select(7, GetUserServer()))
    local token
    local data
    local key = "kingt9Joy:8Xit"
    token = MD5(account .. key)
    data = account .. "&" .. token

    data = Base64_Encode( data )
    data = UrlEncode(data)

    url = url .. data
    return url
end

function UIFriendRecruit:GetAutoLoginUrl(url)
    local account = Login_GetAccount()
    -- local ip = (select(7, GetUserServer()))
    -- local code    = select(11, LoginServerList.GetSelectedServer())
    local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tbSelectServer = LoginServerList.GetSelectServer()
    local code = tbSelectServer.szSerial
    local time    = GetCurrentTime()

    local key = "kingt9Joy:8Xit"
    local token = table.concat({account, code, time, key}, "")
    token = MD5(token)
    local data = table.concat({account, code, time, token}, "&")
    data = Base64_Encode( data )
    data = UrlEncode(data)

    url = url .. data
    return url
end

return UIFriendRecruit