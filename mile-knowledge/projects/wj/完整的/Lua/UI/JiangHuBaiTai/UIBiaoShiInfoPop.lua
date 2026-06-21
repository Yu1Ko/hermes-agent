-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIBiaoShiInfoPop
-- Date: 2023-09-08 14:47:10
-- Desc: PanelHuBiaoPop
-- ---------------------------------------------------------------------------------
local MAX_COUNT 	= 3
local UIBiaoShiInfoPop = class("UIBiaoShiInfoPop")

function UIBiaoShiInfoPop:OnEnter(dwID, szName, nCount, nCurValue, nMaxValue)
	self:UpdateInfo(dwID, szName, nCount, nCurValue, nMaxValue)
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
end

function UIBiaoShiInfoPop:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIBiaoShiInfoPop:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		--UIMgr.Close(VIEW_ID.PanelHuBiaoPop)
		Event.Dispatch("ON_HIDE_WIDGETHUBIAOPOP")
		JiangHuData.UpdateBiaoShiInfoBubble()
	end)
	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
		self:TwoConfirm()
	end)

	local tbParentNode = UIHelper.GetParent(self._rootNode)
	local tbScript = UIHelper.GetBindScript(tbParentNode)
	UIHelper.BindFreeDrag(tbScript, self.BtnDrag)
end

function UIBiaoShiInfoPop:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIBiaoShiInfoPop:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBiaoShiInfoPop:UpdateInfo(dwID, szName, nCount, nCurValue, nMaxValue)

	self.dwID = dwID
	self.szName = szName
	self.nCount  = nCount
	self.nCurValue = nCurValue
	self.nMaxValue = nMaxValue
	self:UpdateGurardInfo()
	self:UpdateGurardSpeedOfProgress()
end

function UIBiaoShiInfoPop:UpdateGurardInfo()
	if self.szName then
		UIHelper.SetString(self.LabelArtistName, self.szName)
	else
		UIHelper.SetString(self.LabelArtistName, g_tStrings.STR_JH_GUARD_FAR_TIP)
	end
	UIHelper.SetString(self.LabelAmountNum, string.format("%d/%d次", self.nCount, MAX_COUNT))
end

function UIBiaoShiInfoPop:UpdateGurardSpeedOfProgress()
	local nPer = math.min(self.nCurValue / self.nMaxValue, 1)
	if self.nCurValue < self.nMaxValue then
		UIHelper.SetVisible(self.ProgressBarVersionsCount, true)
		UIHelper.SetVisible(self.LabelProgressNum, true)
		UIHelper.SetVisible(self.LabelFinish, false)
		UIHelper.SetProgressBarPercent(self.ProgressBarVersionsCount, nPer*100)
		UIHelper.SetString(self.LabelProgressNum, string.format("%d/%d", self.nCurValue, self.nMaxValue))
	else
		UIHelper.SetVisible(self.ProgressBarVersionsCount, false)
		UIHelper.SetVisible(self.LabelProgressNum, false)
		UIHelper.SetVisible(self.LabelFinish, true)
	end
end

function UIBiaoShiInfoPop:TwoConfirm()
	local szMessage = nil
	if self.szName then
		szMessage = string.format("%s将失去你的保护，确定要解除么？", self.szName)
	else
		szMessage = string.format("该镖师将失去你的保护，确定要解除么？")
	end
	local confirmDialog = UIHelper.ShowConfirm(szMessage, function ()
		RemoteCallToServer("On_Identity_CancelRelationship", self.dwID, 1)
	end)
end

return UIBiaoShiInfoPop