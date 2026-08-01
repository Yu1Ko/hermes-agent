-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIArtistReward
-- Date: 2023-08-21 19:43:19
-- Desc: PanelRewardPop
-- ---------------------------------------------------------------------------------

local UIArtistReward = class("UIArtistReward")
local tImageGift = {
    "UIAtlas2_JiangHuBaiTai_JHBTNormal_FlowerBig.png",
}
local LIMIT_NUMBER 		= 999
local INIT_PRICE 		= 1
local MAX_LIMIT_TIME    = 3000

local tRankingToImg = {
    [1] = "UIAtlas2_FengYunLu_Rank_icon_ranking01.png",
    [2] = "UIAtlas2_FengYunLu_Rank_icon_ranking02.png",
    [3] = "UIAtlas2_FengYunLu_Rank_icon_ranking03.png",
}
function UIArtistReward:OnEnter(dwArtistID, szPlayerName, nCurValue, nMaxValue, nDoodadID)
	self:UpdateInfo(dwArtistID, szPlayerName, nCurValue, nMaxValue, nDoodadID)
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
end

function UIArtistReward:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIArtistReward:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelRewardPop)
	end)

	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelRewardPop)
	end)

	UIHelper.BindUIEvent(self.BtnGive, EventType.OnClick, function()
		if self.nNumber == 0 then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_JH_REWARD_NUMBER_PROMPT)
			return
		end

		if self.dwID and self.szRewardName and self.nPrice then
			local szMessage = string.format("确定花费%d金购买%s",self.nTotalPrice, UIHelper.GBKToUTF8(self.szRewardName))
			local confirmDialog = UIHelper.ShowConfirm(szMessage, function ()
				if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE, "artist reward") then
					return
				else
					RemoteCallToServer("On_Identity_BuyFlower", self.dwID, self.nNumber)
					UIHelper.RemoveAllChildren(self.ScrollViewRewardList)
					self:GetRankList()
					self:UpdateMoney(self.nNumber)
				end
			end, nil)
		else
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_JH_SELECT_REWARD_PROMPT)
		end
	end)

    UIHelper.RegisterEditBoxChanged(self.EditPaginate, function()
        local szText = UIHelper.GetString(self.EditPaginate)
        if not szText or szText == "" then
			self.nNumber = 0
			self:UpdateMoney(self.nNumber)
			return
		end

		self.nNumber = tonumber(szText)
		if self.nNumber < 0 then
			self.nNumber = 0
		end

		if self.nNumber > LIMIT_NUMBER then
			self.nNumber = LIMIT_NUMBER
		end
		self:UpdateMoney(self.nNumber)
		UIHelper.SetString(self.EditPaginate, self.nNumber)
    end)
end

function UIArtistReward:RegEvent()
	Event.Reg(self, "UPDATE_ARTIST_EXP", function(nCurValue, nMaxValue)
		self.nCurValue = nCurValue
		self.nMaxValue = nMaxValue
		self:UpdateArtistExp()
    end)

	Event.Reg(self, "UPDATE_ARTIST_RANK", function(tRank)
		self.tRankList = tRank
		self:UpdateArtistRank()
    end)
end

function UIArtistReward:UnRegEvent()
	Event.UnReg(self, "UPDATE_ARTIST_EXP")
	Event.UnReg(self, "UPDATE_ARTIST_RANK")
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIArtistReward:UpdateInfo(dwArtistID, szPlayerName, nCurValue, nMaxValue, nDoodadID)
	self.dwArtistID = dwArtistID
	self.szPlayerName = szPlayerName
	self.nCurValue = nCurValue
	self.nMaxValue = nMaxValue
	self.nDoodadID = nDoodadID
	self.nLimitTime  = 0
	if not GetDoodad(self.nDoodadID) then
		return
	end
	self:UpdateRewardInfo()
	self:UpdateArtistName()
	self:UpdateArtistExp()
	self:InitEdit()
	self:UpdateMoney(INIT_PRICE)
	self:GetRankList()
end

function UIArtistReward:UpdateRewardInfo()
	local tReward = Table_GetArtistReward()
	for k, v in pairs(tReward) do
		UIHelper.SetString(self.LabelMoney, v.nPrice)
		if v.dwID == 1 then
			UIHelper.SetSpriteFrame(self.ImgGift, tImageGift[1])
		end
		self.dwID  = v.dwID
		self.szRewardName = v.szRewardName
		self.nPrice = v.nPrice
	end
end

function UIArtistReward:UpdateArtistName()
	UIHelper.SetString(self.LabelArtistName, UIHelper.GBKToUTF8(self.szPlayerName))
end

function UIArtistReward:UpdateArtistExp()
	local nPre = 0
	if self.nCurValue and self.nMaxValue and self.nMaxValue ~= 0 then
		if self.nCurValue > self.nMaxValue then
			self.nCurValue = self.nMaxValue
		end

		nPre = self.nCurValue / self.nMaxValue
		UIHelper.SetProgressBarPercent(self.ProgressBarVersionsCount, nPre*100)
		UIHelper.SetString(self.LabelProgressNum, string.format("%d/%d", self.nCurValue, self.nMaxValue))
	end
end

function UIArtistReward:InitEdit()
	UIHelper.SetString(self.EditPaginate, INIT_PRICE)
end

function UIArtistReward:UpdateMoney(nNum)
	local colorRed = cc.c3b(255, 133, 125)
    local colorWhite = cc.c3b(255, 255, 255)
	local player = GetClientPlayer()
	local tMoney = player.GetMoney()
	self.nNumber = nNum
	local nGold = nNum * self.nPrice
	UIHelper.SetString(self.LabelAmountNum, nGold)
	if nGold > tMoney.nGold then
		UIHelper.SetTextColor(self.LabelAmountNum, colorRed)
	else
		UIHelper.SetTextColor(self.LabelAmountNum, colorWhite)
	end
	self.nTotalPrice = nGold
	UIHelper.LayoutDoLayout(self.LayoutAmount)
end

function UIArtistReward:UpdateArtistRank()
	local player = GetClientPlayer()
	if not player then
		return
	end

	if not self.tRankList or IsTableEmpty(self.tRankList) then
		UIHelper.SetVisible(self.WidgetEmpty, true)
		UIHelper.SetVisible(self.ScrollViewRewardList, false)
		return
	end
	UIHelper.SetVisible(self.WidgetEmpty, false)
	UIHelper.SetVisible(self.ScrollViewRewardList, true)
	UIHelper.RemoveAllChildren(self.ScrollViewRewardList)
	for k, v in pairs(self.tRankList) do
		local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRewardListCell, self.ScrollViewRewardList, v.szName, v.nNum)
		if k <= 3 then
			tbScript:UpdateRankIcon(tRankingToImg[k])
		else
			tbScript:UpdateRankIcon()
		end
	end
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRewardList)
end

function UIArtistReward:GetRankList()
	RemoteCallToServer("On_Identity_GetFlowerRankList", self.dwArtistID)
end

return UIArtistReward