-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIPanelBubbleMsg
-- Date: 2022-12-07 21:58:12
-- Desc: 气泡信息栏
-- ---------------------------------------------------------------------------------

local UIPanelBubbleMsg = class("UIPanelBubbleMsg")

function UIPanelBubbleMsg:OnEnter()
	self.m = {}
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:Init()
	self:UpdateList()

	BubbleMsgData.SetHasRedPoint(false)
end

function UIPanelBubbleMsg:OnExit()
	self.bInit = false
	self:UnRegEvent()
	--self:ClearCall()
	self.m = nil
end

function UIPanelBubbleMsg:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnBg, EventType.OnClick, function()
		self:Close()
	end)

end

function UIPanelBubbleMsg:RegEvent()
	Event.Reg(self, EventType.BubbleMsg, function (tMsg)
		self:UpdateList()
	end)
	Event.Reg(self, EventType.BubbleMsgRemove, function ()
		self:UpdateList()
	end)
	Event.Reg(self, EventType.OnSceneTouchNothing, function()
        if not UIHelper.GetVisible(self._rootNode) then
            return
        end

        --UIMgr.Close(VIEW_ID.PanelBagUp2)
        UIMgr.Close(self)
    end)
end

function UIPanelBubbleMsg:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPanelBubbleMsg:Init()

end

function UIPanelBubbleMsg:UpdateList()
	local list = self.ScrollViewMessageContent
	assert(list)
	UIHelper.RemoveAllChildren(list)

	local arr = BubbleMsgData.GetMsgArr()
	if #arr == 0 then
		return
	end

	for i, tMsg in ipairs(arr) do
		if not tMsg.bOnIconAct then
			local tScript = UIHelper.AddPrefab(PREFAB_ID.WidgetInformationContent, list, tMsg)
			assert(tScript) -- UIWidgetBubbleCell
		end
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0, false)
end

function UIPanelBubbleMsg:Close()
	UIMgr.Close(self)
end


return UIPanelBubbleMsg