-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIPanelTongUpgradePop
-- Date: 2022-12-19 16:33:37
-- Desc: 帮主升级界面
-- ---------------------------------------------------------------------------------

local UIPanelTongUpgradePop = class("UIPanelTongUpgradePop")

function UIPanelTongUpgradePop:OnEnter()
	self.m = {}
	
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:InitUI()

end

function UIPanelTongUpgradePop:OnExit()
	self.bInit = false
	self:UnRegEvent()
	self.m = nil
end

function UIPanelTongUpgradePop:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()		
		self:Close()		
	end)
	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()		
		self:Close()		
	end)
	UIHelper.BindUIEvent(self.BtnFactionConstruct, EventType.OnClick, function()		
		local sz = UIHelper.GetString(self.EditBox)
		local nCount = tonumber(sz) or 0

		if nCount <= 0 then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.GOLD_MONEY_EMPTY)
			return
		end		

		local nFund = TongData.GetFund()
		local nMoney = nCount * 10000
		if nMoney > nFund then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_TONG_TREE_UPDATE_REQUIRE_FUND)
			return
		end

		RemoteCallToServer("On_Tong_AddLevelProgressRequest", nMoney)
		self:Close()
	end)		
end

function UIPanelTongUpgradePop:RegEvent()
	Event.Reg(self, "ON_TONG_SYNC_CUSTOMDATA", function ()
		self:InitUI()
	end)
end

function UIPanelTongUpgradePop:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTongUpgradePop:InitUI()
	--
	UIHelper.SetRichText(self.LabelFaction, string.format(
		[=[<color=#FFFFFF>当前帮会等级为</c><color=#f0dc82>%d</color><color=#ffffff>，投入帮会资金可提高帮会建设度。]=],
		TongData.GetLevel()
	))
	
	--
	local tCustomData = TongData.GetCustomData()
	if not tCustomData then
		RemoteCallToServer("OnSyncTongCustomData")
		UIHelper.SetString(self.LabelFactionConstructionNum, "")
	else
		local sz = tCustomData["DW_LEVEL_CURRENT_CTRI"] .. "/" .. tCustomData["DW_LEVEL_MAX_CTRI"]
		UIHelper.SetString(self.LabelFactionConstructionNum, sz)
	end
	UIHelper.SetPositionX(self.ImgMoneyIcon, UIHelper.GetWidth(self.LabelFactionConstructionNum))

	--
	UIHelper.SetEditBoxInputMode(self.EditBox,cc.EDITBOX_INPUT_MODE_NUMERIC)
end


function UIPanelTongUpgradePop:Close()
	UIMgr.Close(self)
end

return UIPanelTongUpgradePop