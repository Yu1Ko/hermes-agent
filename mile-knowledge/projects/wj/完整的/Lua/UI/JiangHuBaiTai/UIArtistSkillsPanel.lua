-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIArtistSkillsPanel
-- Date: 2023-08-30 10:56:10
-- Desc: WidgetJiangHuBaiTaiButton
-- ---------------------------------------------------------------------------------

local UIArtistSkillsPanel = class("UIArtistSkillsPanel")
local ARTIST_SELECT_SKILL_TYPE = {
    SKILL = 1,
    PENDANT = 2,
    EMOTION = 3
}

local tSkillID2Index = {40,41,42,43,44,45,46,47,48,49}

function UIArtistSkillsPanel:OnEnter(nActionID)
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
		--JiangHuData.Init()
		self:InitUI()
		if nActionID then
			self:UpdateEmotionSmall(nActionID)
		else
			self:UpdateBtnSlot()
		end
		SprintData.SetViewState(true, true)
		Event.Dispatch("ON_OPEN_ARTIST_SKILLPANEL")
	end
	Timer.AddFrame(self, 1, function ()
		Event.Dispatch(EventType.OnShortcutInteractionChange)
	end)
	
end

function UIArtistSkillsPanel:OnExit()
	self.bInit = false
	self:UnRegEvent()
	SprintData.SetViewState(true, true)
end

function UIArtistSkillsPanel:BindUIEvent()

end

function UIArtistSkillsPanel:RegEvent()
	Event.Reg(self, "ON_USE_ARTIST_SKILL", function (nType, nIndex, arg1, arg2, arg3)
		local tbSlot = self.tbSlotData[nIndex]
		if nType == ARTIST_SELECT_SKILL_TYPE.SKILL then
			self:UseArtistSkill(arg1, arg2)
		elseif nType == ARTIST_SELECT_SKILL_TYPE.PENDANT then
			self:UsePendantAction(tbSlot.btn, arg1, arg2, tbSlot.imgCD, tbSlot.labelCD)
		elseif nType == ARTIST_SELECT_SKILL_TYPE.EMOTION then
			EmotionData.ProcessEmotionActionTemp(arg1, true)
		end
    end)

	Event.Reg(self, "SCENE_END_LOAD", function ()
		if JiangHuData.nActionID then
			EmotionData.StopCurrentEmotionAction(JiangHuData.nActionID)
		end
    end)
end

function UIArtistSkillsPanel:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIArtistSkillsPanel:InitUI()
	EmotionData.QuickLoad()
	local tbSlotData = {}
    local nIndex = 1
    while(self["FunctionSlot" .. nIndex]) do
        local nodeSlot = self["FunctionSlot" .. nIndex]
        local btn = nodeSlot:getChildByName("WidgetFunction/BtnFunction") assert(btn, "Can't find BtnFunction:" .. nIndex)
        local imgIcon = btn:getChildByName("MaskIcon/ImgFunctionIcon") or btn:getChildByName("ImgFunctionIcon") or btn:getChildByName("WidgetFunctionIcon/ImgFunctionIcon") assert(imgIcon, "Can't find ImgFunctionIcon:" .. nIndex)
        local label = btn:getChildByName("LabelFunction") assert(btn, "Can't find LabelFunction:" .. nIndex)
        local imgCD = btn:getChildByName("ImgCd")
        local labelCD = nodeSlot:getChildByName("WidgetFunction/CdLabel")
        local WidgetAniLight = nodeSlot:getChildByName("WidgetFunction/WidgetAniLight") assert(btn, "Can't find WidgetAniLight:" .. nIndex)
        local maskIcon = btn:getChildByName("MaskIcon") assert(btn, "Can't find MaskIcon:" .. nIndex)
        local imgSkillIcon = btn:getChildByName("MaskIcon/ImgFunctionSkillIcon") or btn:getChildByName("MaskIcon/ImgFunctionIcon")


        UIHelper.SetVisible(imgCD, false)
        UIHelper.SetVisible(labelCD, false)

        local tbSlot = {
            nodeSlot = nodeSlot,
            btn = btn,
            imgIcon = imgIcon,
            label = label,
            imgCD = imgCD,
            labelCD = labelCD,
            WidgetAniLight = WidgetAniLight,
            maskIcon = maskIcon,
            imgSkillIcon = imgSkillIcon,
        }
        tbSlotData[nIndex] = tbSlot
        nIndex = nIndex + 1
    end
    self.tbSlotData = tbSlotData
end

function UIArtistSkillsPanel:UpdateBtnSlot()
	self.tbSkillList = {}
	local tSelSkill = Storage.ArtistSkills.tbSkillList
	for nSlotIndex = 1, #self.tbSlotData do
		local tbSlot = self.tbSlotData[nSlotIndex]
		local tbBtnData = tSelSkill[nSlotIndex]
		local nIndex = tSkillID2Index[nSlotIndex]
		local szFuncName
		if tbBtnData then
			if tbBtnData.nLevel and tbBtnData.nSkill then --技能
				local szImagePath = TabHelper.GetSkillIconPathByIDAndLevel(tbBtnData.nSkill, tbBtnData.nLevel)
				UIHelper.SetTexture(tbSlot.imgIcon, szImagePath)
				UIHelper.SetVisible(tbSlot.nodeSlot, true)
				table.insert(self.tbSkillList, tbSlot)
				self:BindSlotBtnEvent(tbSlot, nSlotIndex, ARTIST_SELECT_SKILL_TYPE.SKILL, tbBtnData.nSkill, tbBtnData.nLevel)
				szFuncName = Table_GetSkillName(tbBtnData.nSkill, tbBtnData.nLevel)

			elseif tbBtnData.nTabType and tbBtnData.nTabIndex then --外观或挂件
				local item = ItemData.GetItemInfo(tbBtnData.nTabType, tbBtnData.nTabIndex)
				UIHelper.SetItemIconByItemInfo(tbSlot.imgIcon, item)
				self:BindSlotBtnEvent(tbSlot, nSlotIndex, ARTIST_SELECT_SKILL_TYPE.PENDANT, tbBtnData.nTabType, tbBtnData.nTabIndex)

				local tItemInfo =tbBtnData.nTabIndex > 0 and GetItemInfo(tbBtnData.nTabType, tbBtnData.nTabIndex) or nil
				self.nPendantCDTimer = Timer.AddCycle(self, 1, function()
					self:UpdatePendantSkillCoolDown(tItemInfo.dwSkillID, tbSlot.btn, tbSlot.imgCD, tbSlot.labelCD)
				end)
				szFuncName = item.szName

			elseif tbBtnData.nEmotionID then --表情
				local actionData = EmotionData.GetEmotionAction(tbBtnData.nEmotionID)
				UIHelper.SetItemIconByIconID(tbSlot.imgIcon, actionData.nIconID)

				UIHelper.SetVisible(tbSlot.nodeSlot, true)
				self:BindSlotBtnEvent(tbSlot, nSlotIndex, ARTIST_SELECT_SKILL_TYPE.EMOTION, actionData.dwID)

				szFuncName = actionData.szName
			end
			UIHelper.SetVisible(tbSlot.nodeSlot, false)
			if szFuncName then
				szFuncName = UIHelper.GBKToUTF8(szFuncName)
				szFuncName = UIHelper.TruncateStringReturnOnlyResult(szFuncName, 3, "...")
				SHORTCUT_INTERACTION[SHORTCUT_KEY_BOARD_STATE.Artist][nIndex].szFuncName = szFuncName
			end
			
			Timer.Add(self, 0.1, function ()
				UIHelper.UpdateMask(self.tbMaskSkillIcon[nSlotIndex])
				UIHelper.SetVisible(tbSlot.nodeSlot, true)
			end)
		else
			UIHelper.SetVisible(tbSlot.nodeSlot, false)
		end
	end
end

function UIArtistSkillsPanel:BindSlotBtnEvent(tbSlot, nSlotIndex, nEventType, ...)
	UIHelper.SetButtonClickSound(tbSlot.btn, "")
	local tArg = {...}
	if nEventType == ARTIST_SELECT_SKILL_TYPE.SKILL then
		UIHelper.BindUIEvent(tbSlot.btn, EventType.OnClick, function()
			self:UseArtistSkill(tArg[1], tArg[2])
		end)

	elseif nEventType == ARTIST_SELECT_SKILL_TYPE.PENDANT then
		UIHelper.BindUIEvent(tbSlot.btn, EventType.OnClick, function()
			self:UsePendantAction(tbSlot.btn, tArg[1], tArg[2], tbSlot.imgCD, tbSlot.labelCD)
		end)
	elseif nEventType == ARTIST_SELECT_SKILL_TYPE.EMOTION then
		UIHelper.BindUIEvent(tbSlot.btn, EventType.OnClick, function()
			EmotionData.ProcessEmotionActionTemp(tArg[1], true)
		end)
	end
end

function UIArtistSkillsPanel:UpdateArtistSkillCoolDown(nSkillID, tbSkillList)
    local _, nLeft, nTotal = SkillData.GetSkillCDProcess(g_pClientPlayer, nSkillID)
    nLeft = nLeft or 0
    nTotal = nTotal or 1
    nLeft = math.ceil(nLeft / GLOBAL.GAME_FPS)
    nTotal = math.ceil(nTotal / GLOBAL.GAME_FPS)
    if nLeft and nLeft ~= 0 then
        self.nArtistSkillCDTimer = self.nArtistSkillCDTimer or Timer.AddCycle(self, 1, function()
            self:UpdateArtistSkillCoolDown(nSkillID, tbSkillList)
        end)
		for k, v in pairs(tbSkillList) do
			UIHelper.SetString(v.labelCD,nLeft)
			UIHelper.SetVisible(v.imgCD, true)
		end

    else
        if self.nArtistSkillCDTimer then
			Timer.DelTimer(self, self.nSkillCDTimer)
			Timer.DelTimer(self, self.nArtistSkillCDTimer)
            self.nArtistSkillCDTimer = nil
            self.nSkillCDTimer = nil
        end
    end
	for k, v in pairs(tbSkillList) do
		UIHelper.SetVisible(v.labelCD, nLeft ~= 0)
		UIHelper.SetVisible(v.imgCD, nLeft ~= 0)
		UIHelper.SetEnable(v.btn, nLeft == 0)
	end
end

function UIArtistSkillsPanel:UpdatePendantSkillCoolDown(nSkillID, btn, imgCD, labelCD)
    local _, nLeft, nTotal = SkillData.GetSkillCDProcess(g_pClientPlayer, nSkillID)
    nLeft = nLeft or 0
    nTotal = nTotal or 1
    nLeft = math.ceil(nLeft / GLOBAL.GAME_FPS)
    nTotal = math.ceil(nTotal / GLOBAL.GAME_FPS)
    if nLeft and nLeft ~= 0 then
        self.nPendantSkillCDTimer = self.nPendantSkillCDTimer or Timer.AddCycle(self, 1, function()
            self:UpdatePendantSkillCoolDown(nSkillID)
        end)
        UIHelper.SetString(labelCD,nLeft)
        UIHelper.SetProgressBarPercent(imgCD,  nLeft * 100 / nTotal)
    else
        if self.nPendantSkillCDTimer then
			Timer.DelTimer(self, self.nPendantSkillCDTimer)
			Timer.DelTimer(self, self.nPendantCDTimer)
            self.nPendantSkillCDTimer = nil
            self.nPendantCDTimer = nil
        end
    end
    UIHelper.SetVisible(labelCD, nLeft ~= 0)
    UIHelper.SetVisible(imgCD, nLeft ~= 0)
	UIHelper.SetEnable(btn, nLeft == 0)
end

function UIArtistSkillsPanel:UpdateEmotionSmall(nActionID)
	local tbSlot = self.tbSlotData[1]
	local actionData = EmotionData.GetEmotionAction(nActionID)
	UIHelper.SetTexture(tbSlot.imgIcon, "Resource/icon/emotion/Emotion1/biaoqingdongzuo_fengli.png")
	-- UIHelper.SetItemIconByIconID(tbSlot.imgIcon, actionData.nIconID)
	UIHelper.SetVisible(tbSlot.nodeSlot, true)
	UIHelper.BindUIEvent(tbSlot.btn, EventType.OnClick, function()
		EmotionData.StopCurrentEmotionAction(nActionID)
	end)
	UIHelper.SetVisible(tbSlot.nodeSlot, false)
	Timer.Add(self, 0.1, function ()
		UIHelper.UpdateMask(self.tbMaskSkillIcon[1])
		UIHelper.SetVisible(tbSlot.nodeSlot, true)
	end)

	local WidgetKey = tbSlot.nodeSlot:getChildByName("WidgetFunction/WidgetKeyBoardKey")
	assert(WidgetKey)
	local script = UIHelper.GetBindScript(WidgetKey)
	Timer.AddFrame(self, 5, function()
		script:SetLabelKey("")
	end)

	for nSlotIndex = 2, #self.tbSlotData do
		local t = self.tbSlotData[nSlotIndex]
		UIHelper.SetVisible(t.nodeSlot, false)
	end
end

function UIArtistSkillsPanel:UseArtistSkill(nSkill, nLevel)
	if self.nSkillCDTimer then
		for k, v in pairs(self.tbSkillList) do
			UIHelper.SetEnable(v.btn, false)
		end
		return
	end
	local hBox = {}
	hBox.nSkillLevel = nLevel
	OnUseSkill(nSkill, (nSkill * (nSkill % 10 + 1)), hBox)

	self.nSkillCDTimer = Timer.AddCycle(self, 1, function()
		self:UpdateArtistSkillCoolDown(nSkill, self.tbSkillList)
	end)
end

function UIArtistSkillsPanel:UsePendantAction(btn, nTabType, nTabIndex, imgCD, labelCD)
	self:UpdateBtnSlot()
	if self.nPendantCDTimer then
		UIHelper.SetEnable(btn, false)
	end
	local tItemInfo = nTabIndex > 0 and GetItemInfo(nTabType, nTabIndex) or nil
	OnUseSkill(tItemInfo.dwSkillID, 1)

	self.nPendantCDTimer = Timer.AddCycle(self, 1, function()
		self:UpdatePendantSkillCoolDown(tItemInfo.dwSkillID, btn, imgCD, labelCD)
	end)
end

return UIArtistSkillsPanel