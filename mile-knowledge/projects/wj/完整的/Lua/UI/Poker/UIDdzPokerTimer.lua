-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerTimer
-- Date: 2023-08-16 16:04:08
-- Desc: 斗地主界面时间
-- ---------------------------------------------------------------------------------

local UIDdzPokerTimer = class("UIDdzPokerTimer")
local COUNTDOWN_TIME = 5
function UIDdzPokerTimer:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIDdzPokerTimer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerTimer:BindUIEvent()
    
end

function UIDdzPokerTimer:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerTimer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIDdzPokerTimer:SetDirection(szDirection)
    self.szDirection = szDirection
end

function UIDdzPokerTimer:UpdateTimer()
    UIHelper.SetString(self.TextTimeNum , DdzPokerData.DataModel.nDiffTime)
end


function UIDdzPokerTimer:SetVisible(bVisible)
    self.bVisible = bVisible
    UIHelper.SetVisible(self._rootNode , bVisible)
end

return UIDdzPokerTimer