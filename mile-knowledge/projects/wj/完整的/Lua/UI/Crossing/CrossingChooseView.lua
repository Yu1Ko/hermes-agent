-- ---------------------------------------------------------------------------------
-- Author: Liu yu min
-- Name: CrossingChooseView
-- Date: 2023-03-15 15:08:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local CrossingChooseView = class("CrossingChooseView")

local ViewPath =
{
    [1] = "Lua/UI/Crossing/CrossingChoose_TestPlaceView.lua",
    [2] = "Lua/UI/Crossing/CrossingChoose_FourFightView.lua"
}


function CrossingChooseView:OnEnter(nState)
    if not nState then 
        nState = 1
    end
    CrossingData.nState = nState
    require(ViewPath[CrossingData.nState])
    if CrossingData.nState == 1 then
        self.mainView = CrossingChoose_TestPlaceView.CreateInstance(CrossingChoose_TestPlaceView)
    else
        self.mainView = CrossingChoose_FourFightView.CreateInstance(CrossingChoose_FourFightView)
    end
    
    self.mainView:OnEnter(self)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function CrossingChooseView:OnExit()
    self.bInit = false

    self:UnRegEvent()
    if self.mainView then
        self.mainView:OnExit()
    end
end

function CrossingChooseView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelTestPlaceEntrance)
    end)
end

function CrossingChooseView:RegEvent()

end

function CrossingChooseView:UnRegEvent()

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
-- 获取数据


return CrossingChooseView
