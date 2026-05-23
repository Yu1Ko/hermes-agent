-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetAnnouncement
-- Date: 2022-11-24 22:56:43
-- Desc: 公告栏
-- ---------------------------------------------------------------------------------

local UIWidgetAnnouncement = class("UIWidgetAnnouncement")

local Def = {
	ScrollSpeed = 2,
}

function UIWidgetAnnouncement:OnEnter()
	self.m = {}
	self.m.tMsgArr = {}
	self.bIsRunning = false

	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	-- 默认是隐藏的，强制隐藏，不走计数
	UIHelper.HideAnnouncement(true)
	self:Init()
end

function UIWidgetAnnouncement:OnExit()
	self.bInit = false
	self:_Stop()
	self:UnRegEvent()
	self.m = nil
end

function UIWidgetAnnouncement:BindUIEvent()

end

function UIWidgetAnnouncement:RegEvent()
	Event.Reg(self, EventType.AnnouncementShow, function(bForce, nVisibleCount)
		self:SetVisible(true, bForce, nVisibleCount)
	end)

	Event.Reg(self, EventType.AnnouncementHide, function(bForce, nVisibleCount)
		self:SetVisible(false, bForce, nVisibleCount)
	end)

	Event.Reg(self, EventType.OnGameSettingDisplaySystemAnnouncement, function(bOpen)
		if not bOpen then
			self:ClearMsg()
			self:_Stop()

			if self.m then
				if self.bIsRunning then
					self.bIsRunning = false
					UIHelper.PlayAni(self.m.tRootScript, self.AniAnnouncement, "AniAnnouncementHide", function ()
						UIHelper.HideAnnouncement()
						RM_SetRunMode(self.m.rm, "Idle")
					end)
				end
			end
		end
	end)
end

function UIWidgetAnnouncement:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end


function UIWidgetAnnouncement:OnUpdate()
	RM_UpdateRunMode(self.m.rm)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAnnouncement:PushMsg(tMsg)
	if not self.bInit then return end

	table.insert(self.m.tMsgArr, tMsg)
	self:_Start()
end

function UIWidgetAnnouncement:ClearMsg()
	self.m.tMsgArr = {}
end

function UIWidgetAnnouncement:Init()
	-- 获取有动画管理器的节点
	local aniMgr
	local node = self._rootNode
	repeat
		local tScript = UIHelper.GetBindScript(node)
		if tScript and tScript._aniMgr then
			self.m.tRootScript = tScript
			break
		end
		node = UIHelper.GetParent(node)

	until node == nil
	assert(self.m.tRootScript)

	-- text控件根据文本调整大小
	node = self.RichTextAnnouncement assert(node)
	node:ignoreContentAdaptWithSize(true)

	self:InitRM()
end

function UIWidgetAnnouncement:_Start()
	if not self.m.nUpdateId then
		self.m.nUpdateId = Timer.AddFrameCycle(self, 1, function ()
			self:OnUpdate()
		end)
	end
end
function UIWidgetAnnouncement:_Stop()
	if self.m.nUpdateId then
		Timer.DelTimer(self, self.m.nUpdateId)
		self.m.nUpdateId = nil
	end
end

function UIWidgetAnnouncement:InitRM()
	local rm = {}
	rm.Idle = function()
		if #self.m.tMsgArr > 0 then
			RM_SetRunMode(self.m.rm, "Start")
		else
			self:_Stop()
		end
	end
	rm.Start = function()
		if RM_IsFirstCycle(rm) then
			self.bIsRunning = true

			UIHelper.ShowAnnouncement()
			UIHelper.SetVisible(self.RichTextAnnouncement, false)
			UIHelper.PlayAni(self.m.tRootScript, self.AniAnnouncement, "AniAnnouncementShow", function ()
				RM_SetRunMode(rm, "Scroll")
			end)
		end
	end
	rm.Stop = function()
		if RM_IsFirstCycle(rm) then
			self.bIsRunning = false

			UIHelper.PlayAni(self.m.tRootScript, self.AniAnnouncement, "AniAnnouncementHide", function ()
				UIHelper.HideAnnouncement()
				RM_SetRunMode(rm, "Idle")
			end)
		end
	end
	rm.Scroll = function()
		if RM_IsFirstCycle(rm) then
			local tMsg = table.remove(self.m.tMsgArr, 1)
			if not tMsg then
				RM_SetRunMode(rm, "Stop")
				return
			end
			self.m.tMsg = tMsg

			local node = self.RichTextAnnouncement assert(node)
			UIHelper.SetVisible(node, true)
			UIHelper.SetRichText(node, tMsg.szMsg)

			local mask = UIHelper.GetParent(node)
			local w, h = UIHelper.GetContentSize(mask)
			self.m.nMaskWidth = w
			UIHelper.SetPositionX(node, w / 2)
		end

		local node = self.RichTextAnnouncement assert(node)
		local w, _ = UIHelper.GetContentSize(node)
		local x = UIHelper.GetPositionX(node)

		-- 滚动结束
		if x + w < - self.m.nMaskWidth / 2 then
			RM_SetRunMode(rm, "Scroll", true)
			return
		end

		x = x - Def.ScrollSpeed
		UIHelper.SetPositionX(node, x)
	end


	self.m.rm = rm
	RM_InitRunMode(rm, "UIWidgetAnnouncement")
	RM_SetRunMode(rm, "Idle")
end

function UIWidgetAnnouncement:SetVisible(bVisible, bFroce, nVisibleCount)
	local nMsgLen = (self.m and self.m.tMsgArr) and #self.m.tMsgArr or 0
	if self.m.nUpdateId == nil and nMsgLen == 0 then
		UIHelper.SetVisible(self._rootNode, false)
		return
	end

	if bFroce then
		UIHelper.SetVisible(self._rootNode, bVisible and self.bIsRunning)
		return
	end

	nVisibleCount = nVisibleCount or 0
	UIHelper.SetVisible(self._rootNode, nVisibleCount > 0 and self.bIsRunning)
end

return UIWidgetAnnouncement