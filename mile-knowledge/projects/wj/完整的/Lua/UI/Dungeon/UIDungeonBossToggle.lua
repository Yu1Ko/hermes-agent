local UIDungeonBossToggle = class("UIDungeonBossToggle")

function UIDungeonBossToggle:OnEnter(tBoss, bSelected)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(tBoss, bSelected)
end

function UIDungeonBossToggle:OnExit()
    self.bInit = false
end

function UIDungeonBossToggle:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTabList, EventType.OnSelectChanged, function(_, bSelected)
		if bSelected then
            Event.Dispatch(EventType.OnDungeonBossItemSelectChanged, self.tBoss)
        end
	end)
end

function UIDungeonBossToggle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonBossToggle:UpdateInfo(tBoss, bSelected)
    self.tBoss = tBoss
    local szName = UIHelper.GBKToUTF8(tBoss.szName)
    UIHelper.SetString(self.LabelNormalAll, szName)
    UIHelper.SetString(self.LabelUpAll, szName)
    UIHelper.SetSelected(self.TogTabList, bSelected)
end

return UIDungeonBossToggle