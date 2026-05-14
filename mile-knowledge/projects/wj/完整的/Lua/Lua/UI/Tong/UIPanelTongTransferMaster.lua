-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIPanelTongTransferMaster
-- Date: 2022-12-19 16:33:37
-- Desc: 帮主转交确认界面
-- ---------------------------------------------------------------------------------

local UIPanelTongTransferMaster = class("UIPanelTongTransferMaster")

function UIPanelTongTransferMaster:OnEnter(tData)
	self.m = {}
	self.m.tData = tData

	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	UIHelper.SetRichText(self.LabelFactionTransfer, string.format(
		[=[<color=#FFFFFF>你确定要将帮主转交给</c><color=#ff857d>[%s]</color><color=#ffffff>吗？</color><color=#ffffff>请输入</color><color=#FFF449>“%s”</color><color=>确认。</color>]=],
		UIHelper.GBKToUTF8(tData.szName),
		g_tStrings.STR_GUILD_CHANGE_MASTER_INPUT
	))
end

function UIPanelTongTransferMaster:OnExit()
	self.bInit = false
	self:UnRegEvent()
	self.m = nil
end

function UIPanelTongTransferMaster:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()		
		self:Close()		
	end)
	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()		
		self:Close()		
	end)
	UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_DONATE) then
            return
        end

        local sz = UIHelper.GetString(self.EditBox)
		if sz == g_tStrings.STR_GUILD_CHANGE_MASTER_INPUT then
			GetTongClient().ChangeMaster(self.m.tData.dwID)
			self:Close()
		else
			TipsHelper.ShowNormalTip(g_tStrings.STR_GUILD_CHANGE_MASTER_ERROR, false)
			self:Close()
		end
	end)		
end

function UIPanelTongTransferMaster:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIPanelTongTransferMaster:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTongTransferMaster:UpdateInfo()
	
end


function UIPanelTongTransferMaster:Close()
	UIMgr.Close(self)
end

return UIPanelTongTransferMaster