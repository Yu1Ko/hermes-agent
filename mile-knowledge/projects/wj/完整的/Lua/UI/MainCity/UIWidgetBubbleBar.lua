-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetBubbleBar
-- Date: 2022-12-07 21:58:12
-- Desc: 气泡信息栏
-- ---------------------------------------------------------------------------------

local UIWidgetBubbleBar = class("UIWidgetBubbleBar")

function UIWidgetBubbleBar:OnEnter(scriptParent)
	self.scriptParent = scriptParent

	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true

		self.m = {}
		self.m.tMsgArr = {}
		self.tbScriptMainCityIcon = {}
	end
	self:Init()
	self:UpdateBubbleBtnVisible()
end

function UIWidgetBubbleBar:OnExit()
	for szScript, script in pairs(self.tbScriptMainCityIcon) do
		if script._donotdestroy then
			script:SetDestroy(true)
		end
		UIHelper.RemoveFromParent(script._rootNode)
		self.tbScriptMainCityIcon[szScript] = nil
	end
	self:UnRegEvent()
	self:ClearCall()
	self.bInit = false
	self.m = nil
end

function UIWidgetBubbleBar:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnBubbleInfomation, EventType.OnClick, function()
		BubbleMsgData.OpenMsgPanel()
	end)
end

function UIWidgetBubbleBar:RegEvent()
	Event.Reg(self, EventType.BubbleMsg, function (tMsg)
		self:PushMsg(tMsg)
		self:UpdateBubbleInfoBtn()
		self:UpdateBtn()
	end)

	Event.Reg(self, EventType.BubbleMsgRemove, function (szType, bShowTimelyHintBar)
		self:UpdateBubbleInfoBtn()
		self:UpdateBtn()

		if not self.m or not self.m.tMsg
				or table.is_empty(self.m.tMsg) then
			self.m.tMsg = nil
			self:ShowBarTitle(false)
		end

		if bShowTimelyHintBar and self.tbCurTimelyHintMsg and self.tbCurTimelyHintMsg.szType == szType then
			return
		end

		local tMsg = self:GetMsgByType(szType, true)
		if not tMsg and self.m.tMsg and self.m.tMsg.szType == szType then
			tMsg = self.m.tMsg
		end

		if tMsg then
			tMsg.bRemove = true
		end

		self:NextMsg()
		self:UpdateBtn()
	end)

	Event.Reg(self, "PLAYER_LEVEL_UPDATE", function (dwPlayerID)
        if g_pClientPlayer and g_pClientPlayer.dwID == dwPlayerID then
			self:UpdateBubbleBtnVisible()
        end
    end)

	Event.Reg(self, EventType.UILoadingFinish, function ()
		if not self.m or not self.m.tMsg or table.is_empty(self.m.tMsg)
				or (self.tbCurTimelyHintMsg and self.tbCurTimelyHintMsg.szType == self.m.tMsg.szType) then
			self.m.tMsg = nil
			self:ShowBarTitle(false)
		end

		self:Init()
    end)

	Event.Reg(self, EventType.ShowMessageBubble, function ()
		local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
		if not tEvent then
			return
		end
		if tEvent[1] ~= EventType.ShowMessageBubble then
			return
		end
		self.tbCurTimelyHintMsg = tEvent[2]
		self.bOnShowTimelyHintBar = true
		self:UpdateBubbleInfoBtn()
    end)

	Event.Reg(self, EventType.CloseTimelyMessageBubble, function ()
		self.tbCurTimelyHintMsg = nil
		self.bOnShowTimelyHintBar = false
		self:UpdateBubbleInfoBtn()
    end)
end

function UIWidgetBubbleBar:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetBubbleBar:Init()
	--NOTE:WidgetPvpRightTop也用了这个脚本，但没有WidgetBubbleList且BtnBubbleInfomation需手动加载，所以做了一些兼容判空处理

	if self.WidgetBubbleList then
		self.scriptBubbleList = self.scriptBubbleList or UIHelper.AddPrefab(PREFAB_ID.WidgetBubbleList, self.WidgetBubbleList)
		self.scriptBubbleList:SetVisible(false)
	end

	if not self.BtnBubbleInfomation then
		local tbMgr = {
			szMainCityIcon = "UIAtlas2_MainCity_MainCity1_icon_Xinxi",
			szAction = BubbleMsgData.OpenMsgPanel,
			nRedPointID = 1701,
		}

		local scriptNewIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetBubbleInfomationBtn, self.LayoutBtnBubbleList)
		scriptNewIcon:OnEnter(tbMgr)

		self.BtnBubbleInfomation = scriptNewIcon._rootNode
	end

	local arr = BubbleMsgData.GetMsgArr()
	for i, tMsg in ipairs(arr) do
		self:PushMsg(tMsg)
	end

	self:NextMsg()
	self:UpdateBtn()
end

function UIWidgetBubbleBar:UpdateBtn()
	-- self:UpdateBubbleInfoBtn()
	self:UpdateMainCityBtn()
end

function UIWidgetBubbleBar:UpdateBubbleInfoBtn()
	local tCurMsg = self.m.tMsg
	local nNonIconCount = BubbleMsgData.GetMsgCount(true)
	local nTotalCount = BubbleMsgData.GetMsgCount(false)
	local nIconCount = nTotalCount - nNonIconCount
	-- 超过3个的MainCityIcon消息也应通过消息盒子按钮访问
	local nCount = nNonIconCount + math.max(0, nIconCount - 3)
	local bOnShowAdventureBar = tCurMsg and tCurMsg.bShowAdventureBar
	if self.bOnShowTimelyHintBar then
		-- 队列中有消息正在显示及时消息需要把这部分计数减1，用事件数量来判断是否显示消息盒子按钮
		nCount = nCount - 1
	end
	if self.scriptBubbleList then
		local bShowBtn = nCount > 0
		if self.bShowBarTitle and not bOnShowAdventureBar then
			bShowBtn = nCount > 1
		end
		UIHelper.SetVisible(self.BtnBubbleInfomation, bShowBtn)
		return
	end

	UIHelper.SetVisible(self.BtnBubbleInfomation, nCount > 0)
end

function UIWidgetBubbleBar:ShowBarTitle(bShow)
	if not self.scriptBubbleList then
		return
	end

	if bShow then
		self.bShowBarTitle = true
		self.scriptBubbleList:OnShowBarTitle()
	else
		self.bShowBarTitle = false
		self.scriptBubbleList:OnHideBarTitle()
	end
end

function UIWidgetBubbleBar:UpdateInfo(tMsg)
	self:ClearTitleCall()
	Timer.DelTimer(self, self.nCounDownTimerID)

	if not self.scriptBubbleList then
		return
	end

	local bShowBarTitle = tMsg ~= nil and (not tMsg.bHideMessageLabel and not tMsg.bShowMainCityIcon)
	local bShowAdventureBar = tMsg and tMsg.bShowAdventureBar or false -- 奇遇特判标记,金色底
	if bShowAdventureBar then
		bShowBarTitle = true
	end
	self:ShowBarTitle(bShowBarTitle)
	self:UpdateBubbleInfoBtn()
	if not tMsg then return end

	local szBarTitle, nDelay = not self:CheckBarTitle_is_nil(tMsg.szBarTitle) and tMsg.szBarTitle or tMsg.szTitle, nil
	local fnClickBarTitle = tMsg and tMsg.szAction
	self.scriptBubbleList:UpdateBubbleListImg(tMsg.szImgBubbleList)
	self.scriptBubbleList:SetBarFunction(fnClickBarTitle)
	-- 倒计时类型的
	if tMsg.bIsCountDown then
		local nCountDown = tMsg.nCountDownEndTime - Timer.RealtimeSinceStartup()
		if nCountDown > 0 then
			self.scriptBubbleList:SetString(string.format(szBarTitle, nCountDown))
			self.nCounDownTimerID = Timer.AddCountDown(self, nCountDown, function(nRemain)
				self.scriptBubbleList:SetString(string.format(szBarTitle, nRemain))
			end)
			return
		end
	end

	if type(szBarTitle) == "function" then
		szBarTitle, nDelay = szBarTitle()
		if nDelay then
			self.m.nTitleCallId = Timer.Add(self, nDelay, function ()
				self:UpdateInfo(tMsg)
			end)
		end
	end
	self.scriptBubbleList:SetString(szBarTitle)
end

function UIWidgetBubbleBar:GetMsgByType(szType, bIngoreRemove)
	local arr = self.m and self.m.tMsgArr
	assert(arr)
	for _, v in pairs(arr) do
		if bIngoreRemove and v.szType == szType  then
			return v
		elseif not v.bRemove and v.szType == szType then
			return v
		end
	end
end

function UIWidgetBubbleBar:RefreshMsgData(tOld, tNew)
	for k, v in pairs(tNew) do
		tOld[k] = v
	end
end

function UIWidgetBubbleBar:CheckBarTitle_is_nil(szBarTitle)
	if type(szBarTitle) == "string" then
		return string.is_nil(szBarTitle)
	elseif type(szBarTitle) == "function" then
		return szBarTitle == nil
	else
		return true
	end
end

function UIWidgetBubbleBar:PushMsg(tMsg)
	assert(tMsg)
	-- 排重
	local tCurMsg = self.m.tMsg
    if tCurMsg then
		-- 若与当前显示的消息匹配
		if tCurMsg.szType == tMsg.szType and not tMsg.bShowTimelyHintBar then
			self.m.tMsg = nil
			table.insert(self.m.tMsgArr, 1, tMsg)
			tMsg = nil

		-- 若当前显示常驻消息
		elseif tCurMsg.nBarTime == 0 then
			-- 回到队列尾
			self.m.tMsg = nil
			table.insert(self.m.tMsgArr, tCurMsg)

		-- 若当前显示奇遇
		elseif tCurMsg.szType == "AdventureTips" and tMsg and tMsg.nPriority >= tCurMsg.nPriority then
			self.m.tMsg = nil
		end
	end

	if tMsg and (not tMsg.bShowMainCityIcon or tMsg.bShowAdventureBar) and not tMsg.bHideMessageLabel then
		local tOldMsg = self:GetMsgByType(tMsg.szType)
		if tOldMsg then
			self:RefreshMsgData(tOldMsg, tMsg)

		---@type UIWidgetHintBubbleMsgOnly
		-- 若当前消息在TimelyHintBar里面
		elseif tMsg.bShowTimelyHintBar then
			self.m.tMsg = nil
			table.insert(self.m.tMsgArr, 1, tMsg)

		else
			table.insert(self.m.tMsgArr, 1, tMsg)
		end
    end

	-- sort
	-- Global.SortStably(self.m.tMsgArr, function (a, b)	-- 以新旧顺序
	-- 	local nA = a.nPriority or 0
	-- 	local nB = b.nPriority or 0
	-- 	nA = nA + (a.nBarTime > 0 and 100000 or 0)
	-- 	nB = nB + (b.nBarTime > 0 and 100000 or 0)
	-- 	return nA >= nB
	-- end)
	self:NextMsg()
end

function UIWidgetBubbleBar:NextMsg()
	self:ClearRemovedMsg()
    local tMsg = self.m.tMsg
    if tMsg then return end

	self:ClearCall()
    tMsg = table.remove(self.m.tMsgArr, 1)
    self.m.tMsg = tMsg
    if tMsg then
		local nDelay = tMsg.nBarTime
		if tMsg.bShowMainCityIcon and not tMsg.bShowAdventureBar then--如果有MainCityIcon则直接下一个
			self.m.tMsg = nil
			self:NextMsg()
			return
		elseif nDelay and nDelay > 0 then
			self.m.nCallId = Timer.Add(self, nDelay, function ()
				self.m.tMsg = nil
				self:NextMsg()
			end)
		end

		local bResult = self:TrySwitch2TimelyHintBar()
		if bResult then
			return
		end
    end
	-- if self.scriptBubbleList then
	-- 	self.scriptBubbleList:SetVisible(g_pClientPlayer and g_pClientPlayer.nLevel >= 102)
	-- end
	self:UpdateInfo(tMsg)
end

function UIWidgetBubbleBar:ClearCall()
	self:ClearTitleCall()
	if self.m and self.m.nCallId then
		Timer.DelTimer(self, self.m.nCallId)
		self.m.nCallId = nil
	end
end

function UIWidgetBubbleBar:TrySwitch2TimelyHintBar()
	local tMsg = self.m.tMsg
	local tEvent = TipsHelper.GetCurEvent(TipsHelper.Def.Queue3)
	if (tEvent and tEvent[1] ~= EventType.ShowMessageBubble) then
		return false
	end

	local tbCurTimelyHintMsg = self.tbCurTimelyHintMsg
	if tbCurTimelyHintMsg and tbCurTimelyHintMsg.szType == tMsg.szType then
		tMsg.bShowTimelyHintBar = false
	elseif not tMsg or tMsg.bShowTimelyHintBar or not tMsg.fnConfirmAction or not tMsg.fnCancelAction then
		return false
	end

	self.m.tMsg = nil
	tMsg.bShowTimelyHintBar = true
	TipsHelper.ShowMessageBubble(tMsg)
	return true
end

local function GetNewIconList()
	local tNewList = {}
	local count = 0
	for i, v in ipairs(BubbleMsgData.GetMsgArr()) do
        if v.bShowMainCityIcon == true then
            table.insert(tNewList, v)
            count = count + 1
            if count == 3 then
                break
            end
        end
    end
	return tNewList
end

function UIWidgetBubbleBar:UpdateMainCityBtn()
	-- 先重置所有Icon消息的bOnIconAct，避免残留标记导致消息面板中无法显示
	for _, v in ipairs(BubbleMsgData.GetMsgArr()) do
		if v.bShowMainCityIcon then
			v.bOnIconAct = false
		end
	end

	local tbCurIconList = {}
	for i = 1, #self.tbScriptMainCityIcon, 1 do
		local script = self.tbScriptMainCityIcon[i]
		if script then
			table.insert(tbCurIconList, script)
			script.bPreRemoveIcon = true
		end
	end
	self.tbScriptMainCityIcon = {}

	local tBtnMsgList = GetNewIconList()
	for index, tbMgr in ipairs(tBtnMsgList) do
		if tbMgr.szType == "AdventureTips" and index ~= 1 then
			-- 策划需求：特判奇遇按钮固定放在第一位
			tbMgr.bIsMoveToFront = true
			table.remove(tBtnMsgList, index)
			table.insert(tBtnMsgList, 1, tbMgr)
			break
		end
	end
	-- local tbNewList = {}
	for _, tbMgr in ipairs(tBtnMsgList) do
		local _, key = table.find_if(tbCurIconList, function (v)
			if v and v.tbMgr then
				return v.tbMgr.szType == tbMgr.szType
			end
		end)
		if key and tbCurIconList[key] then
			-- 检测已有Icon
			tbCurIconList[key].bPreRemoveIcon = false
			tbCurIconList[key]:OnEnter(tbMgr)
			tbMgr.bOnIconAct = true
			UIHelper.SetParent(tbCurIconList[key]._rootNode, self.LayoutBtnBubbleList)
			table.insert(self.tbScriptMainCityIcon, tbCurIconList[key])
		else
			local scriptNewIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetBubbleInfomationBtn, self.LayoutBtnBubbleList)
			scriptNewIcon:OnEnter(tbMgr)
			scriptNewIcon:SetDestroy(false)
			tbMgr.bOnIconAct = true
			table.insert(self.tbScriptMainCityIcon, scriptNewIcon)
		end
	end

	--删除旧图标
	for _, script in ipairs(tbCurIconList) do
		if script.bPreRemoveIcon then
			script:SetDestroy(true)
			UIHelper.RemoveFromParent(script._rootNode)
		end
	end

	--优先级重排后处理显示超数量的情况
	self:ReplaceBubblyIconArr()

	if #self.tbScriptMainCityIcon > 3 then
		for index = #self.tbScriptMainCityIcon, 4, -1 do
			local script = self.tbScriptMainCityIcon[index]
			if script then
				script.tbMgr.bOnIconAct = false
				script:SetDestroy(true)
				UIHelper.RemoveFromParent(script._rootNode)
			end
			table.remove(self.tbScriptMainCityIcon, index)
		end
	end

	UIHelper.LayoutDoLayout(self.LayoutBtnBubbleList)
end

function UIWidgetBubbleBar:ReplaceBubblyIconArr()
	local tbArr = self.tbScriptMainCityIcon
	self.tbScriptMainCityIcon = {}

	for _, scriptIcon in pairs(tbArr) do
		table.insert(self.tbScriptMainCityIcon, scriptIcon)
	end

	Global.SortStably(self.tbScriptMainCityIcon, function (a, b)
		local nA = a and a.tbMgr.nPriority or 0
		local nB = b and b.tbMgr.nPriority or 0
		return nA >= nB
	end)
end

function UIWidgetBubbleBar:ClearTitleCall()
	if self.m and self.m.nTitleCallId then
		Timer.DelTimer(self, self.m.nTitleCallId)
		self.m.nTitleCallId = nil
	end
end

function UIWidgetBubbleBar:ClearRemovedMsg()
	local nCount = BubbleMsgData.GetMsgCount(false)
	if nCount <= 0 then
		self.m.tMsg = nil
	end

	local arr = self.m and self.m.tMsgArr
	assert(arr)
	for i = #arr, 1, -1 do
		local tMsg = arr[i]
		if tMsg.bRemove then
			table.remove(arr, i)
		end
	end

	local tMsg = self.m.tMsg
	if tMsg and tMsg.bRemove then
		self.m.tMsg = nil
	end
end

function UIWidgetBubbleBar:DoAction()
	local tMsg = self.m.tMsg
	assert(tMsg)
	local szAction = tMsg.szAction

	if IsFunction(szAction) then
		szAction()
	elseif IsString(szAction) then
		if not string.is_nil(szAction) then
			BubbleMsgData.OpenMsgPanel()
		end
	end
end

function UIWidgetBubbleBar:UpdateBubbleBtnVisible()
	self:UpdateBubbleInfoBtn()
	UIHelper.SetVisible(self._rootNode, true)
	UIHelper.LayoutDoLayout(self.LayoutBtnBubbleList)
end

return UIWidgetBubbleBar