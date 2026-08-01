-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIChallengeDeclaration
-- Date: 2023-10-10 10:14:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChallengeDeclaration = class("UIChallengeDeclaration")

function UIChallengeDeclaration:OnEnter(tbSloganInfo)
	self.tbSloganInfo = tbSloganInfo
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIChallengeDeclaration:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIChallengeDeclaration:BindUIEvent()
	
end

function UIChallengeDeclaration:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIChallengeDeclaration:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChallengeDeclaration:UpdateInfo()
	for i = 2, table.get_len(self.tbSloganInfo) do
        local sloganScript =  UIHelper.AddPrefab(PREFAB_ID.WidgetArenaPopSloganCell, self.ScollViewTipsDeclaration)
        if sloganScript then
            sloganScript:OnEnter(UIHelper.GBKToUTF8(self.tbSloganInfo[i].szOption),i-1)
        end
    end
	UIHelper.ScrollViewDoLayout(self.ScollViewTipsDeclaration)
    UIHelper.ScrollToTop(self.ScollViewTipsDeclaration)

	UIHelper.SetTouchDownHideTips(self.ScollViewTipsDeclaration, false)
end


return UIChallengeDeclaration