-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatMonitor
-- Date: 2024-11-21 10:19:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatMonitor = class("UIChatMonitor")

function UIChatMonitor:OnEnter()
	self.tbWordScript = {}
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:UpdateInfo()
end

function UIChatMonitor:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIChatMonitor:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

	UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function(btn)	--添加关键字
		UIMgr.Open(VIEW_ID.PanelChatMonitorWordPop)
    end)
end

function UIChatMonitor:RegEvent()
	Event.Reg(self, EventType.OnAddChatMonitor, function (tbData)
		if not tbData then
			return
		end
		self:AddChatInfo(tbData)
		self:UpdateScrollViewPosition()
		self:ShowWidgetEmpty(false)
	end)

	Event.Reg(self, EventType.OnWordMonitorChanged, function()
        self:UdpateChatKeyWordList()
    end)

	Event.Reg(self, EventType.OnWindowsSizeChanged, function()
		Timer.AddFrame(self, 1, function ()
			UIHelper.LayoutDoLayout(self.LayoutInfo)
		end)
    end)
end

function UIChatMonitor:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatMonitor:UpdateInfo()
	BubbleMsgData.RemoveMsg("ChatMonitorTips")
	self.nScrollHeight = UIHelper.GetHeight(self.ScrollViewChatList)
	self:UdpateChatKeyWordList()	--关键词
	self:UpdateChatList()	--监控记录
end

function UIChatMonitor:UdpateChatKeyWordList()
	local nTotal = ChatMonitor.GetMaxStorageLen()
    local tbList = ChatMonitor.GetStorageList()
    local nCount = #tbList

	UIHelper.SetString(self.LabelSettingsWordageTitle, string.format("监控关键词（%d/%d）", nCount, nTotal))

	UIHelper.SetVisible(self.WidgetAdd, nCount < nTotal)

	for k, script in pairs(self.tbWordScript) do
		UIHelper.RemoveFromParent(script._rootNode)
	end

	self.tbWordScript = {}
	for i = 1, nCount, 1 do
		local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChatMonitorKeyWord, self.LayoutKeyWord, tbList[i])
		self.tbWordScript[i] = script
	end

	local nSpacingY = UIHelper.LayoutGetSpacingY(self.LayoutKeyWord)
	local nCellHeight = UIHelper.GetHeight(self.WidgetAdd)
	if nCount > 2 then
		UIHelper.SetHeight(self.ScrollViewChatList, self.nScrollHeight - nSpacingY - nCellHeight)
	else
		UIHelper.SetHeight(self.ScrollViewChatList, self.nScrollHeight)
	end

	UIHelper.LayoutDoLayout(self.LayoutKeyWord)
	UIHelper.LayoutDoLayout(self.LayoutInfo)

end

function UIChatMonitor:UpdateChatList()
	local tbChatList = ChatMonitor.GetMonitorChatList()
	local bHaveChat = false
	for i, tbChat in ipairs(tbChatList) do
		bHaveChat = true
		self:AddChatInfo(tbChat)
	end

	if bHaveChat then
		self:UpdateScrollViewPosition()
	end

	self:ShowWidgetEmpty(not bHaveChat)
end

function UIChatMonitor:AddChatInfo(tbChat)
	self:InitChatPrefab(30, PREFAB_ID.WidgetChatMonitorListCell, self.ScrollViewChatList)
	self:TryAddChat(tbChat)
end

function UIChatMonitor:InitChatPrefab(nMaxNum, nPrefabID, parent)
    if self:IsInitChatPrefab() then
        return
    end


    self.tbChats = {}
    self.tbChats.nMaxNum = nMaxNum
    self.tbChats.cellPrefabPool = PrefabPool.New(nPrefabID, nMaxNum)
    self.tbChats.parent = parent
    self.tbChats.cache = {}
    self.tbChats.tbChatView = {}
end

function UIChatMonitor:IsInitChatPrefab()
	return self.tbChats ~= nil
end

function UIChatMonitor:TryAddChat(tbChat)
	local tbChatView = self.tbChats.tbChatView
    local nMaxNum = self.tbChats.nMaxNum
    local cellPrefabPool = self.tbChats.cellPrefabPool
    local parent = self.tbChats.parent
    local cache = self.tbChats.cache

	if #tbChatView == nMaxNum then	--已到最大数量，移除第一个再加
		self:RemoveChat(tbChatView[1]._rootNode, parent)
    end

	self:AddChat(tbChat)
end

function UIChatMonitor:RemoveChat(node, parent)
	local tbChatView = self.tbChats.tbChatView
    local cellPrefabPool = self.tbChats.cellPrefabPool

	table.remove(tbChatView, 1)
	cellPrefabPool:Recycle(node)

	UIHelper.ScrollViewDoLayoutAndToTop(parent)
end

function UIChatMonitor:AddChat(tbChat)
	local cellPrefabPool = self.tbChats.cellPrefabPool
    local parent = self.tbChats.parent
    local tbChatView = self.tbChats.tbChatView

    local node, scriptView = cellPrefabPool:Allocate(parent)
	scriptView:SetWidth(UIHelper.GetWidth(parent))
	scriptView:OnEnter(1, tbChat)
	UIHelper.SetRichTextCanClick(scriptView.RichText, true)
    table.insert(tbChatView, scriptView)
end

function UIChatMonitor:UpdateScrollViewPosition()
	local tbChatView = self.tbChats.tbChatView
	local nCount = table.get_len(tbChatView) or 0
	local nCellHeight = UIHelper.GetHeight(tbChatView[1]._rootNode) or 0
	local bSpacingY = UIHelper.LayoutGetSpacingY(self.LayoutChatList)
	local nScrollViewHeight = UIHelper.GetHeight(self.ScrollViewChatList)
	UIHelper.ScrollViewDoLayout(self.ScrollViewChatList)
	Timer.AddFrame(self, 2, function ()
		if nCount * (nCellHeight + bSpacingY) > nScrollViewHeight then
			UIHelper.ScrollToBottom(self.ScrollViewChatList)
		else
			UIHelper.ScrollToTop(self.ScrollViewChatList)
		end	
	end)

end

function UIChatMonitor:ShowWidgetEmpty(bShow)
	UIHelper.SetVisible(self.WidgetEmpty, bShow)
	UIHelper.SetVisible(self.ScrollViewChatList, not bShow)
	UIHelper.LayoutDoLayout(self.LayoutInfo)
end

return UIChatMonitor