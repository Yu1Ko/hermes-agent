-- ---------------------------------------------------------------------------------
-- Name: UIPanelRemovePlayerPop
-- Desc: 地图踢人弹出框
-- Prefab:PanelRemovePlayerPop
-- ---------------------------------------------------------------------------------

local UIPanelRemovePlayerPop = class("UIPanelRemovePlayerPop")

function UIPanelRemovePlayerPop:_LuaBindList()
    self.BtnClose          = self.BtnClose

    self.EditBox           = self.EditBox -- 玩家名字编辑

    self.BtnRemovePlayer   = self.BtnRemovePlayer -- 确认踢人
end

function UIPanelRemovePlayerPop:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
end

function UIPanelRemovePlayerPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelRemovePlayerPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnRemovePlayer, EventType.OnClick, function()
        local szPlayerName = UIHelper.GetText(self.EditBox)
        if szPlayerName ~= nil and szPlayerName ~= "" then 
			RemoteCallToServer("On_Camp_GFKickOut", UIHelper.UTF8ToGBK(szPlayerName), nil)
		end
		UIMgr.Close(self)
    end)
end

function UIPanelRemovePlayerPop:RegEvent()
    
end

function UIPanelRemovePlayerPop:UnRegEvent()

end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

return UIPanelRemovePlayerPop