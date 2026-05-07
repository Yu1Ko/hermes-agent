-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetQuickUse
-- Date: 2024-05-07 15:04:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetQuickUse = class("UIWidgetQuickUse")

function UIWidgetQuickUse:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
end

function UIWidgetQuickUse:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWidgetQuickUse:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnQuickUse, EventType.OnClick, function()
        local nX = UIHelper.GetWorldPositionX(self.BtnQuickUse)
        local nY = UIHelper.GetWorldPositionY(self.BtnQuickUse)
        --local _, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetQuickUsedTip, nX, nY)
        Event.Dispatch(EventType.OnUpdateQuickUseTipPosByNewPos, nX, nY)
    end)

	UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()  --进入黑框,maincity加载新的
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.FULL, CUSTOM_TYPE.QUICKUSE, self.nMode)
    end)
end

function UIWidgetQuickUse:RegEvent()
	Event.Reg(self, EventType.OnQuickUseSuccess, function()
    --    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetQuickUsedTip)
    end)
end

function UIWidgetQuickUse:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetQuickUse:UpdateInfo()

end

function UIWidgetQuickUse:UpdatePrepareState(nMode, bStart)
    self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
	self.nMode = nMode
end

function UIWidgetQuickUse:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState
end

function UIWidgetQuickUse:UpdateCustomState()
    self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
end

return UIWidgetQuickUse