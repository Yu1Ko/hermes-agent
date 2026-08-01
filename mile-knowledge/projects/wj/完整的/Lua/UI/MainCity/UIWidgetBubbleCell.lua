-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetBubbleCell
-- Date: 2022-12-07 21:58:12
-- Desc: 气泡信息栏
-- ---------------------------------------------------------------------------------

local UIWidgetBubbleCell = class("UIWidgetBubbleCell")

function UIWidgetBubbleCell:OnEnter(tMsg)
	self.m = {}
	self.m.tMsg = tMsg
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:Init()
end

function UIWidgetBubbleCell:OnExit()
	self.bInit = false
	self:UnRegEvent()
	self:ClearCall()
	self.m = nil
end

function UIWidgetBubbleCell:BindUIEvent()
	UIHelper.SetSwallowTouches(self.BtnDel, true)
	UIHelper.BindUIEvent(self.BtnDel, EventType.OnClick, function()
		self:DelMsg()
	end)
	UIHelper.BindUIEvent(self.BtnContent, EventType.OnClick, function()
		self:DoAction()
		--if self.m.tMsg.szType == "NewMailTips" then 邮件已新增功能直接打开邮件界面，暂时屏蔽信使指引
		--	self:SkipToMap()
		--end
		-- if self.m.tMsg.szType == "EquipDurabilityWarning" then
		-- 	self:RepairItem()
		-- end
	end)
end

function UIWidgetBubbleCell:RegEvent()
end

function UIWidgetBubbleCell:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetBubbleCell:Init()
	self:UpdateCell()
end

function UIWidgetBubbleCell:UpdateCell()
	local tMsg = self.m.tMsg
	Timer.DelTimer(self, self.nCounDownTimerID)
	self:ClearContentCall()

	-- title
	local szTitle, nTitleDelay = tMsg.szTitle, nil
	if type(szTitle) == "function" then
		szTitle, nTitleDelay = szTitle()
	end
	UIHelper.SetString(self.LabelAdventure, szTitle)

	-- bCanRemove
	local bCanRemove = tMsg.bCanRemove
	if type(bCanRemove) == "function" then
		bCanRemove = bCanRemove()
	end
	UIHelper.SetVisible(self.BtnDel, bCanRemove)

	-- icon
	UIHelper.SetSpriteFrame(self.ImgNormalIcon, tMsg.szIcon)

	--
	UIHelper.SetVisible(self.LabelAdventureContent, false)
	UIHelper.SetVisible(self.LabelAdventureContentNormal, false)

	if tMsg.bIsCountDown then
		local nCountDown = tMsg.nCountDownEndTime - Timer.RealtimeSinceStartup()
		if nCountDown > 0 then
			local szContent, nContentDelay = tMsg.szContent, nil
			UIHelper.SetVisible(self.LabelAdventureContentNormal, true)
			UIHelper.SetString(self.LabelAdventureContentNormal, string.format(szContent, nCountDown))
			self.nCounDownTimerID = Timer.AddCountDown(self, nCountDown, function(nRemain)
				UIHelper.SetString(self.LabelAdventureContentNormal, string.format(szContent, nRemain))
			end)

			return
		end
	end

	-- content
	local szContent, nContentDelay = tMsg.szContent, nil
	if type(szContent) == "function" then
		szContent, nContentDelay = szContent()
	end
	UIHelper.SetRichText(self.LabelAdventureContent, szContent)
	UIHelper.SetVisible(self.LabelAdventureContent, true)

	-- callback
	if nTitleDelay ~= nil or nContentDelay ~= nil then
		local nDelay = math.min(nTitleDelay or 0xFFFFFFFF, nContentDelay or 0xFFFFFFFF)
		self.m.nContentCallId = Timer.Add(self, nDelay, function ()
			self:UpdateCell()
		end)
	end

end


function UIWidgetBubbleCell:ClearCall()
	self:ClearContentCall()
end

function UIWidgetBubbleCell:ClearContentCall()
	if self.m.nContentCallId then
		Timer.DelTimer(self, self.m.nContentCallId)
		self.m.nContentCallId = nil
	end
end

function UIWidgetBubbleCell:DelMsg()
	local tMsg = self.m.tMsg
	assert(tMsg)
	BubbleMsgData.RemoveMsg(tMsg.szType)
end

function UIWidgetBubbleCell:DoAction()
	local tMsg = self.m.tMsg
	assert(tMsg)
	local szAction = tMsg.szAction

	if IsFunction(szAction) then
		szAction()
	elseif IsString(szAction) then
		if not string.is_nil(szAction) then
			local bResult = string.execute(szAction)
		end
	end
end

function UIWidgetBubbleCell:SkipToMap()
	local szMessage = "是否前往追踪信使？"
	if self:JudjeMessenger() then
		local confirmDialog = UIHelper.ShowConfirm(szMessage, function ()
			if not UIMgr.GetView(VIEW_ID.PanelMiddleMap) then
				UIMgr.Close(VIEW_ID.PanelBubbleInformation)
				local scriptView = UIMgr.Open(VIEW_ID.PanelMiddleMap,MapHelper.GetMapID(),0)
				scriptView:ShowRightMenu()
			end
		end, nil)
	else --固定打开扬州地图
		szMessage = "当前场景无信使，是否前往追踪扬州场景的信使？"
		local confirmDialog = UIHelper.ShowConfirm(szMessage, function ()
			if not UIMgr.GetView(VIEW_ID.PanelMiddleMap) then
				UIMgr.Close(VIEW_ID.PanelBubbleInformation)
				local scriptView = UIMgr.Open(VIEW_ID.PanelMiddleMap,6,0)
				scriptView:ShowRightMenu()
			end
		end, nil)
	end

end

function UIWidgetBubbleCell:JudjeMessenger()	--判断当前地图是否有信使
    local tbNavigationInfo = {}
    local nMapID = MapHelper.GetMapID()
    local aNpc = MapHelper.tbMiddleMapNpc[nMapID]
    if aNpc == nil then
        MapHelper.InitMiddleMapInfo(nMapID)
        aNpc = MapHelper.tbMiddleMapNpc[nMapID]
    end
    local nIndex = 0
    local tbData = {}
    for k, v in pairs(aNpc) do
        local tbCatalogue = MapHelper.GetMiddleMapNpcCatalogueIconTab(v.id)
        if v.middlemap == nIndex and tbCatalogue.nNpcCatalogue ~= 0 then
            tbData[tbCatalogue.nNpcCatalogue] = tbData[tbCatalogue.nNpcCatalogue] or {}
            table.insert(tbData[tbCatalogue.nNpcCatalogue], v)
        end
    end

    for nType, tbNav in pairs(tbData) do
        if nType == 2 then
            tbNavigationInfo[2] = tbNavigationInfo[2] or {}
            for nNav, tbCell in ipairs(tbNav) do
                local tItemList = {}
                for i, v in ipairs(tbCell.group) do
                    table.insert(tItemList, {
                        tArgs = {
                            2, nNav, i, v, nMapID
                        }
                    })
                end
                table.insert(tbNavigationInfo[2], {
                    tArgs = tbCell,
                    tItemList = tItemList,
                    fnSelectedCallback = function(bSelected) end,
                })
            end
        end
    end

	if tbNavigationInfo[2] then
		return true
	end
end

function UIWidgetBubbleCell:RepairItem()
	if not self.m.tMsg.nPosIndex then
		TipsHelper.ShowNormalTip(self.m.tMsg.szTitle, false)
		return
	end
	local player = PlayerData.GetClientPlayer()

	local nPrice = GetRepairAllItemsPrice()
	local tPrice = PackMoney(UIHelper.MoneyToGoldSilverAndCopper(nPrice))
	local szMoney = UIHelper.GetMoneyText(tPrice)
	local szMessage

	local bEnough = MoneyOptCmp(player.GetMoney(), tPrice) > 0
	if bEnough then
		szMessage = "确定" .. szMoney ..  "修理所有装备吗？"
		UIHelper.ShowConfirm(szMessage, function ()
			RepairAllItemsWithoutTips()
		end, nil, true)
	else
		szMessage = "本次修理需要" .. szMoney ..  "，余额不足。"
		local scriptConfirm = UIHelper.ShowConfirm(szMessage, _, _, true)
		scriptConfirm:HideButton("Confirm")
	end
end

return UIWidgetBubbleCell