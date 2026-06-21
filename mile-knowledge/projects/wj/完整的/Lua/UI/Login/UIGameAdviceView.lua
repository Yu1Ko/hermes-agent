-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIGameAdviceView
-- Date: 2023-01-10 19:31:16
-- Desc: 健康游戏忠告界面 UIGameAdviceView
-- ---------------------------------------------------------------------------------

local UIGameAdviceView = class("UIGameAdviceView")

local ADVICE_STAY_TIME = 3 --健康游戏忠告停留时间

function UIGameAdviceView:OnEnter(fnCompleteCallback)
    self.fnCompleteCallback = fnCompleteCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIGameAdviceView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGameAdviceView:BindUIEvent()

end

function UIGameAdviceView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGameAdviceView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGameAdviceView:UpdateInfo()
    Timer.Add(self, ADVICE_STAY_TIME, function()
        if self.fnCompleteCallback then
            UIMgr.Close(self)
            self.fnCompleteCallback()
        end
    end)
end


return UIGameAdviceView