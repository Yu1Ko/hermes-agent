-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldJoinRoom
-- Date: 2025-01-07 15:08:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldJoinRoom = class("UITreasureBattleFieldJoinRoom")

function UITreasureBattleFieldJoinRoom:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITreasureBattleFieldJoinRoom:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldJoinRoom:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnJoinRoom, EventType.OnClick, function()
        local szCode = UIHelper.GetString(self.EditBoxID)
        local nCode = tonumber(szCode)
        if not nCode or nCode < 0 then
            return
        end
        RemoteCallToServer("On_JueJing_JoinRoom", nCode, nil, 0)
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBoxID, function ()
            self:UpdateInfo()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBoxID, function ()
            self:UpdateInfo()
        end)
    end

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function (editBox, nCurNum)
        if editBox ~= self.EditBoxID then return end
        self:UpdateInfo()
    end)
end

function UITreasureBattleFieldJoinRoom:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBattleFieldJoinRoom:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldJoinRoom:UpdateInfo()
    local szCode = UIHelper.GetString(self.EditBoxID)
    local nCode = tonumber(szCode)
    UIHelper.SetButtonState(self.BtnJoinRoom, nCode and nCode > 0 and BTN_STATE.Normal or BTN_STATE.Disable)
end


return UITreasureBattleFieldJoinRoom