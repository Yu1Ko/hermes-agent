-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIArtistGift
-- Date: 2023-08-25 17:36:06
-- Desc: PanelGiftMainPop
-- ---------------------------------------------------------------------------------

local UIArtistGift = class("UIArtistGift")
local m_tSkill      = { {id = 16175, level = 1}, {id = 16177, level = 1}, {id = 16178, level = 1}, {id = 16179, level = 1}, {id = 16271, level = 1}, }
local m_nNumber = {
	[1314] 	= 5,
	[512] 	= 4,
	[100] 	= 3,
	[10] 	= 2,
	[1] 	= 1,
}

local tRankingToImg = {
    [1] = "UIAtlas2_FengYunLu_Rank_icon_ranking01.png",
    [2] = "UIAtlas2_FengYunLu_Rank_icon_ranking02.png",
    [3] = "UIAtlas2_FengYunLu_Rank_icon_ranking03.png",
}
function UIArtistGift:OnEnter(nFellowNum, nTimeSlot)
	if not JiangHuData.tSendFellowRank then
		JiangHuData.tSendFellowRank = {}
	end
	self.nFellowNum = nFellowNum
	self.nCurID = nil
	JiangHuData.nArtistTimeSlot = nTimeSlot or 0
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIArtistGift:OnExit()
	self.bInit = false
	self:UnRegEvent()
	Timer.DelAllTimer()
end

function UIArtistGift:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		--UIMgr.Close(VIEW_ID.PanelGiftMainPop)
		Event.Dispatch("ON_HIDE_WIDGETGIFTPOP")
		JiangHuData.UpdateBubbleMsgData(self.nFellowNum)
	end)
	
	UIHelper.BindUIEvent(self.BtnClose01, EventType.OnClick, function()
		UIHelper.SetVisible(self.WidgetTips, false)
		self.nCurID = nil
		Event.Dispatch("UPDATE_RANKCELL_SELECTED", self.nCurID)
	end)

	local tbParentNode = UIHelper.GetParent(self._rootNode)
	local tbScript = UIHelper.GetBindScript(tbParentNode)
	UIHelper.BindFreeDrag(tbScript, self.BtnDrag)
end

function UIArtistGift:RegEvent()
	Event.Reg(self, "UPDATE_REWARDS_INCREASE", function(nFellowNum, tRank)
		self.nFellowNum = nFellowNum
		UIHelper.SetString(self.LabelName, self.nFellowNum)
		self:UpdateRankInfo()
		self:UpdateSelectSkillInfo()
    end)

	Event.Reg(self, "SHOW_CONFIGSKILL_TIPS", function(nCurID, nNum)
		UIHelper.SetVisible(self.WidgetTips, true)
		self.nCurID = nCurID 
		self:UpdateSkill(self.nCurID, self:GetShowSkillNum(nNum))
		Event.Dispatch("UPDATE_RANKCELL_SELECTED", self.nCurID)
    end)
end

function UIArtistGift:UnRegEvent()
	Event.UnReg(self, "UPDATE_REWARDS_INCREASE")
	Event.UnReg(self, "SHOW_CONFIGSKILL_TIPS")
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIArtistGift:UpdateInfo()
	UIHelper.SetString(self.LabelName, self.nFellowNum)
	self:UpdateRankInfo()
	self:UpdateTimeDown()

	self:UdpateExperience()
end

local function romoveOwnInfo()
	local tList  = JiangHuData.tSendFellowRank
	local player = GetClientPlayer()
	for k, v in pairs(JiangHuData.tSendFellowRank) do
		if v.dwID == player.dwID then
			table.remove(tList, k)
		end
	end

	return tList
end

function UIArtistGift:GetShowSkillNum(nNum)
	if nNum >= 1314 then
		return m_nNumber[1314]
	elseif nNum >= 512 then
		return m_nNumber[512]
	elseif nNum >= 100 then
		return m_nNumber[100]
	elseif nNum >= 10 then
		return m_nNumber[10]
	else
		return m_nNumber[1]
	end
end

function UIArtistGift:UpdateRankInfo()
	local tRecordRank = romoveOwnInfo()
	UIHelper.SetVisible(self.WidgetEmpty, IsTableEmpty(JiangHuData.tSendFellowRank))
	UIHelper.SetVisible(self.WidgetTitle, not IsTableEmpty(JiangHuData.tSendFellowRank))
	UIHelper.RemoveAllChildren(self.ScrollViewRankingList)
	for k, v in pairs(tRecordRank) do
		local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRankingList, self.ScrollViewRankingList, v.szName, v.nNum, v.dwID)
		if k <= 3 then
			tbScript:UpdateRankIcon(tRankingToImg[k])
		else
			tbScript:UpdateRankIcon()
		end
	end
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRankingList)
end

function UIArtistGift:UpdateSelectSkillInfo()
	local tRecordRank 	= romoveOwnInfo()
	for k, v in pairs(tRecordRank) do
		if self.nCurID and v.dwID == self.nCurID and k <= 6 then --更新选中玩家交互技能
			Event.Dispatch("UPDATE_RANKCELL_SELECTED", self.nCurID)
			self:UpdateSkill(v.dwID, self:GetShowSkillNum(v.nNum))
			return
		end
	end
end

function UIArtistGift:UpdateSkill(dwID, nNumber)
	for k, v in pairs(m_tSkill) do
		UIHelper.RemoveAllChildren(self.tbSkillList[k])
		local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tbSkillList[k]) assert(scriptBtn)
		--scriptBtn:OnInitSkill(v.id, v.level)
		scriptBtn.nSkillID = v.id
		scriptBtn.nSkillLevel = v.level
		scriptBtn:BindUIEvent()
		scriptBtn.bIsSkill = true
		local szImagePath = TabHelper.GetSkillIconPathByIDAndLevel(v.id, v.level)
		scriptBtn:SetIconByTexture(szImagePath)
		scriptBtn:HideLabelCount()
		scriptBtn:SetClickNotSelected(true)
		UIHelper.SetVisible(scriptBtn.ImgPolishCountBG, false)

		scriptBtn:SetClickCallback(function()
			if k <= nNumber then
				local target = GetPlayer(self.nCurID)
				if target then
					SetTarget(TARGET.PLAYER, self.nCurID)
					OnUseSkill(v.id, (v.id * (v.id % 10 + 1)))
				--	UIMgr.Close(VIEW_ID.PanelGiftMainPop)
				  else
					  OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ERROR_SKILL_TARGET_INVISIBLE)
				end
			end

        end)
		--scriptBtn:SetLongPressCallback(function()
		--	local tCursor = GetCursorPoint()
        --    local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetSkillInfoTips, tCursor.x, tCursor.y, v.id, false)
        --    tipsScriptView:SetBtnVisible(false)
        --end)
		

		UIHelper.SetNodeGray(scriptBtn._rootNode, k > nNumber, true)
		scriptBtn:SetEnable(k <= nNumber)
	end
end

function UIArtistGift:UpdateTimeDown()
	JiangHuData.UpdateArtistCD()
	local nCountDown = JiangHuData.nArtistLeftTime
	UIHelper.SetString(self.LabelCountDown,self:GetFormatTime(nCountDown))
	self.nTimer = Timer.AddCountDown(self, nCountDown, function(nRemain)
		UIHelper.SetString(self.LabelCountDown,self:GetFormatTime(nRemain))
	end, function() 
		RemoteCallToServer("On_Identity_ArtistBarClose")
		self.nTimer = nil
	end)
end

function UIArtistGift:GetFormatTime(nTime)
    local nM = math.floor(nTime / 60)
    local nS = math.floor(nTime % 60)
    local szTimeText = ""

    if nM ~= 0 then
        szTimeText= szTimeText..nM..":"
    end

    if nS < 10 and nM ~= 0 then
        szTimeText = szTimeText.."0"
    end

    szTimeText= szTimeText..nS

    return szTimeText
end

function UIArtistGift:UdpateExperience()
	local function UpdateLevelInfo()
		JiangHuData.InitInfo()
		local tbExperience = JiangHuData.tSItem[1].tExperience
		local nLevel = JiangHuData.tSItem[1].nLevel
		local nPercent = 0
		if tbExperience.nCurValue ~= 0 and tbExperience.nSlotValue ~= 0 then
			nPercent = tbExperience.nCurValue/tbExperience.nSlotValue
		else
			if nLevel == 5 then
				nPercent = 1
			end
		end
		UIHelper.SetProgressBarPercent(self.ImgSlider, nPercent * 100)
		UIHelper.SetVisible(self.LabelExperience, nLevel ~= 5)
		UIHelper.SetString(self.LabelLevel, string.format("%s级", tostring(nLevel)))
		if nLevel < 5 then
			UIHelper.SetString(self.LabelExperience, string.format("%s/%s", tbExperience.nCurValue, tbExperience.nSlotValue))
		end
	end
	UpdateLevelInfo()
	Timer.AddCycle(self, 20, function ()
		UpdateLevelInfo()
	end)
end

return UIArtistGift