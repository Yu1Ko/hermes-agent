-- ---------------------------------------------------------------------------------
-- Author: liu yu min
-- Name: UIJiangHuPanel
-- Date: 2023-08-04 17:13:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIJiangHuPanel = class("UIJiangHuPanel")
local tbIdentityIcon = {
    [1] = "UIAtlas2_JiangHuBaiTai_JHBTNormal_YiRen.png",
	[2] = "UIAtlas2_JiangHuBaiTai_JHBTNormal_BiaoShi.png",
	[3] = "UIAtlas2_JiangHuBaiTai_JHBTNormal_FangShi.png",
	[4] = "UIAtlas2_JiangHuBaiTai_JHBTNormal_YuShou.png",
	[5] = "UIAtlas2_JiangHuBaiTai_JHBTNormal_LvLin.png",
}
local tbRankList = {
	[1] = 1,
	[2] = 2,
	[3] = 5,
	[4] = 4,
	[5] = 3
}
function UIJiangHuPanel:OnEnter(nIndex)
	self.nIndex = nIndex
	self.nInfoIndex = 1
	self.nSetIndex = 1
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIJiangHuPanel:OnExit()
	self.bInit = false
	self:UnRegEvent()
	--CustomData.Register(CustomDataType.Role, "ArtistSkillsData", JiangHuData.tSelSkill)
end

function UIJiangHuPanel:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelJiangHuBaiTai)
		--if not UIMgr.IsViewOpened(VIEW_ID.PanelJiangHuBaiTaiMain) then
		--	UIMgr.Open(VIEW_ID.PanelJiangHuBaiTaiMain)
		--end
	end)

	for k,v in ipairs(self.tbTogIdentityList) do
        UIHelper.BindUIEvent(v, EventType.OnClick, function ()
			UIHelper.SetSelected(self.tbTogIdentityList[self.nIndex], false)
            self.nIndex = k
			self.nInfoIndex = 1
			UIHelper.SetSelected(self.tbTogIdentityList[self.nIndex], true)
			UIHelper.SetVisible(self.WidgetSkillinfoTips, false)
            self:UpdateRightInfo(false)
			self:UpdateRightTogInfo()
			self:UpdatePersonImg()
			self:UpdateLevelSlider()
        end)
    end

	for k, v in pairs(self.tbTitleTogList) do
		UIHelper.BindUIEvent(v, EventType.OnClick, function ()
            self.nInfoIndex = k
			self:UpdateRightTogInfo()
			if self.nInfoIndex == 2 then
				UIHelper.SetSelected(self.tbSkillSetTogList[self.nSetIndex], true)
				--UIHelper.SetVisible(self.WidgetAnchorLeftPop, false)
				UIHelper.SetVisible(self.WidgetSkillinfoTips, false)
				UIHelper.RemoveAllChildren(self.ScrollViewIdentityList)
				self:UpdateSkillConfig()
			end

        end)
	end

	for k, v in pairs(self.tbSkillSetTogList) do
		UIHelper.BindUIEvent(v, EventType.OnClick, function ()
			UIHelper.SetSelected(self.tbSkillSetTogList[self.nSetIndex], false)
            self.nSetIndex = k
			UIHelper.SetSelected(self.tbSkillSetTogList[self.nSetIndex], true)
			UIHelper.RemoveAllChildren(self.ScrollViewIdentityList)
			self:UpdateSkillConfig()
			self:UpdateEmptyState()
        end)
	end

	UIHelper.BindUIEvent(self.BtnTrace01, EventType.OnClick, function() --追踪
		--UIMgr.Close(VIEW_ID.PanelJiangHuBaiTai)
		--if UIMgr.IsViewOpened(VIEW_ID.PanelJiangHuBaiTaiMain) then
		--	UIMgr.Close(VIEW_ID.PanelJiangHuBaiTaiMain)
		--end
		MapMgr.SetTracePoint(JiangHuData.NpcTraceData[self.nIndex][1], JiangHuData.NpcTraceData[self.nIndex][2], JiangHuData.NpcTraceData[self.nIndex][3])
		UIMgr.Open(VIEW_ID.PanelMiddleMap, JiangHuData.NpcTraceData[self.nIndex][2], 0)
	end)

	UIHelper.BindUIEvent(self.BtnOpen, EventType.OnClick, function()
		local player = GetClientPlayer()
		if JiangHuData.nCurActID and JiangHuData.nCurActID ~= 0 then
			player.GetPlayerIdentityManager().SwitchIdentity(JiangHuData.tSItem[self.nIndex].nIdentityIDS)
		else
			player.GetPlayerIdentityManager().OpenIdentity(JiangHuData.tSItem[self.nIndex].nIdentityIDS) --开启身份
		end
		UIHelper.SetVisible(self.BtnClose01, true)
		UIHelper.SetVisible(self.BtnOpen, false)
		UIHelper.SetVisible(self.LayoutCountdown, false)
		--Event.Dispatch("ON_SHOW_CHOOSEICON", self.nIndex, true)
		JiangHuData.UpdateIdentitySystemCD()
		UIMgr.Close(VIEW_ID.PanelJiangHuBaiTai)
		--UIMgr.Close(VIEW_ID.PanelJiangHuBaiTaiMain)
		UIMgr.Close(VIEW_ID.PanelSystemMenu)
	end)

	UIHelper.BindUIEvent(self.BtnClose01, EventType.OnClick, function()
		local player = GetClientPlayer()
		local szMessage = FormatString(g_tStrings.STR_JH_CLOSE_SURE_TIP, UIHelper.GBKToUTF8(JiangHuData.tSItem[self.nIndex].tOneInfo.szName))
		local confirmDialog = UIHelper.ShowConfirm(szMessage, function ()
			player.GetPlayerIdentityManager().CloseIdentity()
			JiangHuData.UpdateIdentitySystemCD()
			Event.Dispatch("ON_SHOW_CHOOSEICON", self.nIndex, false)
			if JiangHuData.nCurActID == 5 then
				JiangHuData.tbIdentitySkills = {}
			end
			IdentitySkillData.OnSwitchDynamicSkillStateBySkills()

		end, nil)
	end)

	UIHelper.BindUIEvent(self.BtnRanking, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelFengYunLu, FengYunLuCategory.JiangHu, tbRankList[self.nIndex]) --打开排行榜
	end)
end

function UIJiangHuPanel:RegEvent()
	Event.Reg(self, "On_OpenAnchorLeftPop", function(dwSkillID,nSkillLevel)
		UIHelper.SetVisible(self.WidgetSkillinfoTips, true)
		self:UpdateSkillDetailInfo(dwSkillID, nSkillLevel)
    end)

	Event.Reg(self, "SHOW_CLOSE_IDENTITYBTN", function()
		local nCountDown = JiangHuData.nLeftTime
		if nCountDown and nCountDown > 0 then
			UIHelper.SetVisible(self.BtnClose01, false)
			UIHelper.SetVisible(self.BtnOpen, true)
			UIHelper.SetEnable(self.BtnOpen, false)
			UIHelper.SetButtonState(self.BtnOpen, BTN_STATE.Disable)
			UIHelper.SetVisible(self.LayoutCountdown, true)
			UIHelper.SetString(self.LabelCountdownLabel, self:GetFormatTime(nCountDown))
			self.nTimer = Timer.AddCountDown(self, nCountDown, function(nRemain)
				UIHelper.SetString(self.LabelCountdownLabel, self:GetFormatTime(nRemain))
			end, function()
				UIHelper.SetEnable(self.BtnOpen, true)
				UIHelper.SetButtonState(self.BtnOpen, BTN_STATE.Normal)
				UIHelper.SetVisible(self.LayoutCountdown, false)
				self.nTimer = nil
			end)
		else
			UIHelper.SetVisible(self.BtnClose01, false)
			UIHelper.SetVisible(self.BtnOpen, true)
			UIHelper.SetEnable(self.BtnOpen, true)
			UIHelper.SetButtonState(self.BtnOpen, BTN_STATE.Normal)
			UIHelper.SetVisible(self.LayoutCountdown, false)
		end
    end)

	--Event.Reg(self, "UPDATE_IDENTITY_ARTIST_SKILL", function(tArtistSkill)
	--	JiangHuData.tArtistSkill = tArtistSkill
    --end)
	Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        if string.is_nil(szUrl) then
            return
        end

        szUrl = Base64_Decode(szUrl)

        local szLinkEvent, szLinkArg = szUrl:match("(%w+)/(.*)")

        if szLinkEvent == "NPCGuide" then
            -- NPCGuide/120
            local nLinkID = tonumber(szLinkArg)

            local tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
            if #tAllLinkInfo > 0 then
                -- todo: 暂时先只显示第一个
                local tLink  = tAllLinkInfo[1]

                local tPoint = { tLink.fX, tLink.fY, tLink.fZ }
                MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tLink.szNpcName), tLink.dwMapID, tPoint)
                UIMgr.Open(VIEW_ID.PanelMiddleMap, tLink.dwMapID, 0)
            end
		end
    end)

	Event.Reg(self, "ON_SHOWPETDETAILINFO", function(nTabType, nTabID)
		self:UpdatePetDetailInfo(nTabType, nTabID)
    end)

	Event.Reg(self, EventType.HideAllHoverTips, function ()
		UIHelper.SetVisible(self.WidgetSkillinfoTips, false)
		Event.Dispatch("On_CancelSkillSelected")
        if self.scriptItemTip then
            UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
            self.scriptItemTip = nil
        end
    end)


end

function UIJiangHuPanel:UnRegEvent()
	Event.UnReg(self, "On_OpenAnchorLeftPop")
	Event.UnReg(self, "SHOW_CLOSE_IDENTITYBTN")
	Event.UnReg(self, EventType.OnRichTextOpenUrl)
	Event.UnReg(self, "ON_SHOWPETDETAILINFO")
	Event.UnReg(self, EventType.HideAllHoverTips)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIJiangHuPanel:UpdateInfo()
	self:UpdateSelectSkill()
	for k, v in pairs(self.tbTogIdentityList) do
		UIHelper.ToggleGroupAddToggle(self.ToggleGroupIdentity, v)
	end

	for k, v in pairs(self.tbTitleTogList) do
		UIHelper.ToggleGroupAddToggle(self.ToggleGroup, v)
	end

	for k, v in pairs(self.tbSkillSetTogList) do
		UIHelper.ToggleGroupAddToggle(self.ToggleSkillSetGroup, v)
	end

	UIHelper.SetSelected(self.tbTogIdentityList[1],false)
	UIHelper.SetSelected(self.tbTogIdentityList[self.nIndex],true)
	--if self.nInfoIndex == 2 then
		UIHelper.SetSelected(self.tbSkillSetTogList[1],true)
	--end
	self:UpdateRightInfo(true)
	self:UpdatePersonImg()
	self:UpdateLevelSlider()
end

function UIJiangHuPanel:UpdateRightInfo(bFirst)
	local player = GetClientPlayer()
	if JiangHuData.tSItem[self.nIndex].bActivate then --已拥有
			--仅艺人显示技能栏配置
		if self.nIndex == 1 then
			UIHelper.SetVisible(self.WidgetTitleTog, true)
		else
			UIHelper.SetVisible(self.WidgetTitleTog, false)
		end
		UIHelper.SetVisible(self.RichTextInfo01, false)
		UIHelper.SetVisible(self.WidgetButton, true)
		UIHelper.SetVisible(self.BtnTrace01, false)
		UIHelper.SetVisible(self.WidgetLock, false)
	else
		UIHelper.SetVisible(self.WidgetTitleTog, false)
		UIHelper.SetVisible(self.RichTextInfo01, true)
		UIHelper.SetVisible(self.WidgetButton, false)
		UIHelper.SetVisible(self.WidgetLock, true)
		if player.nCamp == 0 and (self.nIndex == 2 or self.nIndex == 5) then
			UIHelper.SetVisible(self.BtnTrace01, false)
		else
			UIHelper.SetVisible(self.BtnTrace01, true)
		end
	end



	--技能描述
	UIHelper.SetString(self.LabelAcailable, UIHelper.GBKToUTF8(JiangHuData.tSItem[self.nIndex].tOneInfo.szUnlockDes))
	UIHelper.SetString(self.LabelNextAcailable, UIHelper.GBKToUTF8(JiangHuData.tSItem[self.nIndex].tOneInfo.szUnlockDesNext))

	self:UpdateTitle()
	self:UpdateLevel()
	self:UpdateRichTextInfo()
	self:UpdateSkills(bFirst)
	self:UpdateBtn()
	self:UpdateTime()
end

function UIJiangHuPanel:UpdateTitle()
	local szTitle = JiangHuData.UpdateLevelTitle(self.nIndex)
	if szTitle then
		UIHelper.SetString(self.LabelTitle01, UIHelper.GBKToUTF8(szTitle))
	else
		UIHelper.SetString(self.LabelTitle01, g_tStrings.STR_JH_ZERO_TITLE)
	end
end

function UIJiangHuPanel:UpdateLevel()
	local tbExperience = JiangHuData.tSItem[self.nIndex].tExperience
	if JiangHuData.tSItem[self.nIndex].nLevel == 5 then
		UIHelper.SetVisible(self.LabelExperience, false)
		UIHelper.SetVisible(self.LabelLevel, true)
		UIHelper.SetString(self.LabelLevel, string.format("%s级", tostring(JiangHuData.tSItem[self.nIndex].nLevel)))
	elseif not JiangHuData.tSItem[self.nIndex].bActivate then
		UIHelper.SetVisible(self.LabelExperience, false)
		UIHelper.SetVisible(self.LabelLevel, false)
		--UIHelper.SetString(self.LabelLevel, "0")
	else
		UIHelper.SetVisible(self.LabelExperience, true)
		UIHelper.SetVisible(self.LabelLevel, true)
		UIHelper.SetString(self.LabelExperience, string.format("%s/%s", tbExperience.nCurValue, tbExperience.nSlotValue))
		UIHelper.SetString(self.LabelLevel, string.format("%s级", tostring(JiangHuData.tSItem[self.nIndex].nLevel)))
	end
end

function UIJiangHuPanel:UpdateRichTextInfo()
	local player = GetClientPlayer()
	local szMsg = ""
	if player.nCamp == 0 and JiangHuData.tSItem[self.nIndex].tOneInfo.szNeutralTip ~= "" then
		szMsg = ParseTextHelper.ParseNormalText(JiangHuData.tSItem[self.nIndex].tOneInfo.szNeutralTip)
	else
		szMsg = ParseTextHelper.ConvertRichTextFormat(JiangHuData.tSItem[self.nIndex].tOneInfo.szLinkToPos)
	end
	UIHelper.SetRichText(self.RichTextInfo01, UIHelper.GBKToUTF8(szMsg))
end

function UIJiangHuPanel:UpdateRightTogInfo()
	UIHelper.SetSelected(self.tbTitleTogList[self.nInfoIndex], true)
	if self.nInfoIndex == 1 then
		UIHelper.SetVisible(self.WidgetInformation, true)
		UIHelper.SetVisible(self.WidgetList, false)
	else
		UIHelper.SetVisible(self.WidgetInformation, false)
		UIHelper.SetVisible(self.WidgetList, true)
	end
end

function UIJiangHuPanel:UpdateSkills(bFirst)
	UIHelper.RemoveAllChildren(self.LayoutIdentitySkill01)
	UIHelper.RemoveAllChildren(self.LayoutIdentitySkill02)
	JiangHuData.tSkills, JiangHuData.nType = JiangHuData.GetSkills(self.nIndex)
	JiangHuData.tNextSkills, JiangHuData.nTypeNext = JiangHuData.GetNextSkills(self.nIndex)
	if JiangHuData.tSkills and not IsTableEmpty(JiangHuData.tSkills) then --已习得技能
		local tbSkillList = {}
		local tbPetList = {}
		UIHelper.SetVisible(self.LabelAcailable, true)
		UIHelper.SetVisible(self.LayoutIdentitySkill01, true)
		for k, v in pairs(JiangHuData.tSkills) do
			local szValue = JiangHuData.tSkills[k]

			if szValue ~= "" then
				local tInfo = string.split(szValue, "_")
				if JiangHuData.nType == 1 then--宠物
					table.insert(tbPetList, {tonumber(tInfo[1]), tonumber(tInfo[2])})
				elseif JiangHuData.nType == 0 then--技能
					table.insert(tbSkillList, {tonumber(tInfo[2]), tonumber(tInfo[1])})
				end
			end
		end
		if JiangHuData.nType == 1 then--宠物
			for i = 1, math.ceil(#tbPetList / 5) do
				UIHelper.AddPrefab(PREFAB_ID.WidgetIdentitySkillCell, self.LayoutIdentitySkill01, tbPetList, i - 1, true, bFirst)
			end
		elseif JiangHuData.nType == 0 then--技能
			for i = 1, math.ceil(#tbSkillList / 5) do
				UIHelper.AddPrefab(PREFAB_ID.WidgetIdentitySkillCell, self.LayoutIdentitySkill01, tbSkillList, i - 1, false, bFirst)
			end
		end
		UIHelper.LayoutDoLayout(self.LayoutIdentitySkill01)
	else
		UIHelper.SetVisible(self.LabelAcailable, false)
		UIHelper.SetVisible(self.LayoutIdentitySkill01, false)
	end
	if JiangHuData.tNextSkills and not IsTableEmpty(JiangHuData.tNextSkills) then --下一级可习得技能
		local tbNextSkillList = {}
		local tbNextPetList = {}
		UIHelper.SetVisible(self.LabelNextAcailable, true)
		UIHelper.SetVisible(self.LayoutIdentitySkill02, true)
		for k, v in pairs(JiangHuData.tNextSkills) do
			if v ~= "" then
				local tInfo = string.split(v, "_")
				if JiangHuData.nTypeNext == 1 then
					table.insert(tbNextPetList, {tonumber(tInfo[1]), tonumber(tInfo[2])})
				elseif JiangHuData.nTypeNext == 0 then
					table.insert(tbNextSkillList, {tonumber(tInfo[2]), tonumber(tInfo[1])})
				end

			end
		end
		if JiangHuData.nTypeNext == 1 then--宠物
			for i = 1, math.ceil(#tbNextPetList / 5) do
				UIHelper.AddPrefab(PREFAB_ID.WidgetIdentitySkillCell, self.LayoutIdentitySkill02, tbNextPetList, i - 1, true, bFirst)
			end
		elseif JiangHuData.nTypeNext == 0 then--技能
			for i = 1, math.ceil(#tbNextSkillList / 5) do
				UIHelper.AddPrefab(PREFAB_ID.WidgetIdentitySkillCell, self.LayoutIdentitySkill02, tbNextSkillList, i - 1, false, bFirst)
			end
		end
		UIHelper.LayoutDoLayout(self.LayoutIdentitySkill02)
	else
		UIHelper.SetVisible(self.LabelNextAcailable, false)
		UIHelper.SetVisible(self.LayoutIdentitySkill02, false)
	end
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewIdentitySkill)
	UIHelper.LayoutDoLayout(self.LayoutIdentitySkill)
end

function UIJiangHuPanel:UpdateSkillConfig()
	if JiangHuData.tArtistSkill then
		self.tTypeSkill = JiangHuData.tArtistSkill[self.nSetIndex]
		if not self.tTypeSkill then
			return
		end
	end

	for k, v in pairs(self.tTypeSkill) do
		if self.nSetIndex == 1 then --动作配置
			if v.nLevel and v.nSkill then
				--local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewIdentityList) assert(scriptBtn)
				local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetYirenSkill, self.ScrollViewIdentityList)
				local szName       = Table_GetSkillName(v.nSkill, v.nLevel)
				szName = self:FormatSkillName(szName)
				UIHelper.SetString(tbScript.LabelYirenSkillName, szName)
				local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, tbScript.WidgetItem) assert(scriptBtn)
				--scriptBtn:OnInitSkill(v.nSkill, v.nLevel)
				scriptBtn.nSkillID = v.nSkill
				scriptBtn.nSkillLevel = v.nLevel
				scriptBtn:BindUIEvent()
				scriptBtn.bIsSkill = true
				local szImagePath = TabHelper.GetSkillIconPathByIDAndLevel(v.nSkill, v.nLevel)
				scriptBtn:SetIconByTexture(szImagePath)
				scriptBtn:HideLabelCount()
				scriptBtn:SetClickNotSelected(true)
				UIHelper.SetVisible(scriptBtn.ImgPolishCountBG, false)
				UIHelper.SetVisible(scriptBtn.ImgBlack, false)
				UIHelper.SetVisible(scriptBtn.ImgItemMask, false)

				self:SetItemClickCallback(scriptBtn, v)
				self:SetBottomItemSelected(scriptBtn, v)
				UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewIdentityList)
			end
		elseif self.nSetIndex == 2 then --外观配置
			if v.nTabType and v.nTabIndex then
				--local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewIdentityList) assert(scriptBtn)
				local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetYirenSkill, self.ScrollViewIdentityList)
				local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, tbScript.WidgetItem) assert(scriptBtn)

				scriptBtn:SetClickNotSelected(true)
				scriptBtn.nTabType = v.nTabType
				scriptBtn.nTabID = v.nTabIndex
				scriptBtn:BindUIEvent()
				local item = ItemData.GetItemInfo(v.nTabType, v.nTabIndex)
				local szName = self:FormatSkillName(item.szName)
				UIHelper.SetString(tbScript.LabelYirenSkillName, szName)


				UIHelper.SetItemIconByItemInfo(scriptBtn.ImgIcon, item)
				scriptBtn:HideLabelCount()
				UIHelper.SetVisible(scriptBtn.ImgPolishCountBG, false)
				UIHelper.SetVisible(scriptBtn.ImgBlack, false)
				UIHelper.SetVisible(scriptBtn.ImgItemMask, false)

				self:SetItemClickCallback(scriptBtn, v)
				self:SetBottomItemSelected(scriptBtn, v)
				UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewIdentityList)
			end
		elseif self.nSetIndex == 3 then	--挂件配置
			if v.nTabType and v.nTabIndex then
				--local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewIdentityList) assert(scriptBtn)
				local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetYirenSkill, self.ScrollViewIdentityList)
				local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, tbScript.WidgetItem) assert(scriptBtn)
				scriptBtn.nTabType = v.nTabType
				scriptBtn.nTabID = v.nTabIndex
				scriptBtn:BindUIEvent()
				local item = ItemData.GetItemInfo(v.nTabType, v.nTabIndex)
				local szName = self:FormatSkillName(item.szName)
				UIHelper.SetString(tbScript.LabelYirenSkillName, szName)

				UIHelper.SetItemIconByItemInfo(scriptBtn.ImgIcon, item)
				scriptBtn:HideLabelCount()
				UIHelper.SetVisible(scriptBtn.ImgPolishCountBG, false)
				UIHelper.SetVisible(scriptBtn.ImgBlack, false)
				UIHelper.SetVisible(scriptBtn.ImgItemMask, false)

				self:SetItemClickCallback(scriptBtn, v)
				self:SetBottomItemSelected(scriptBtn, v)
				UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewIdentityList)
			end
		elseif self.nSetIndex == 4 then	--表情配置
			if v.nEmotionID then
				local actionData = EmotionData.GetEmotionAction(v.nEmotionID)
				--local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewIdentityList) assert(itemScript)
				local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetYirenSkill, self.ScrollViewIdentityList)
				local szName = actionData.szName
				szName = self:FormatSkillName(szName)
				UIHelper.SetString(tbScript.LabelYirenSkillName, szName)
				if actionData.bInteract then
					UIHelper.SetVisible(tbScript.ImgDoubleMark, true)
					UIHelper.SetSpriteFrame(tbScript.ImgDoubleMark, "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon1")
				elseif actionData.bAniEdit then
					UIHelper.SetVisible(tbScript.ImgDoubleMark, true)
					UIHelper.SetSpriteFrame(tbScript.ImgDoubleMark, "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon2")
				elseif actionData.nAniType ~= 0 and EMOTION_ACTION_ANI_TYPE[actionData.nAniType] then
					UIHelper.SetVisible(tbScript.ImgDoubleMark, true)
					local path = "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon" .. EMOTION_ACTION_ANI_TYPE[actionData.nAniType]
					UIHelper.SetSpriteFrame(tbScript.ImgDoubleMark, path)
				else
					UIHelper.SetVisible(tbScript.ImgDoubleMark, false)
				end

				local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, tbScript.WidgetItem) assert(itemScript)
				UIHelper.SetSwallowTouches(itemScript.ToggleSelect, false)
				itemScript.nIconID = actionData.nIconID
				itemScript:BindUIEvent()
				UIHelper.SetItemIconByIconID(itemScript.ImgIcon, actionData.nIconID)
				UIHelper.SetVisible(itemScript.LabelCount, false)
				UIHelper.SetVisible(itemScript.LabelPolishCount, false)
				UIHelper.SetVisible(itemScript.ImgPolishCountBG, false)
				UIHelper.SetVisible(itemScript.ImgBlack, false)
				UIHelper.SetVisible(itemScript.ImgItemMask, false)

				self:SetItemClickCallback(itemScript, v)
				self:SetBottomItemSelected(itemScript, v)
				UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewIdentityList)
			end
		end
	end

end

function UIJiangHuPanel:UpdateEmotionActionChoosenType(nowBtn)
    if self.preEmotionActionBtn then
        UIHelper.SetVisible(self.preEmotionActionBtn.ImgSelect , false)
    end
    UIHelper.SetVisible(nowBtn.ImgSelect, true)
    self.preEmotionActionBtn = nowBtn
end

function UIJiangHuPanel:GetSelSkillCount(tSelSkill)
	local nCount = 0

	for k, v in pairs(tSelSkill) do
		if JiangHuData.tSelSkill[k] then
			nCount = nCount + 1
		end
	end

	return nCount
end

function UIJiangHuPanel:InsertSelectSkill(tbItem)
	local nNoneBoxIndex = nil
	for i = 1, JiangHuData.MAX_ARTIST_SKILL_COUNT do
		local tSel = JiangHuData.tSelSkill[i]
		if not tSel then
			nNoneBoxIndex = i
			break
		end
	end

	if not nNoneBoxIndex then
		return
	end

	if tbItem.nLevel and tbItem.nSkill then
		JiangHuData.tSelSkill[nNoneBoxIndex] = { nLevel = tbItem.nLevel, nSkill = tbItem.nSkill }
	elseif tbItem.nTabType and tbItem.nTabIndex then
		JiangHuData.tSelSkill[nNoneBoxIndex] = { nTabType = tbItem.nTabType, nTabIndex = tbItem.nTabIndex }
	elseif tbItem.nEmotionID then
		JiangHuData.tSelSkill[nNoneBoxIndex] = { nEmotionID = tbItem.nEmotionID }
	end
end

function UIJiangHuPanel:UpdateSelectSkill() --已选技能
	Storage.ArtistSkills.tbSkillList = {}

	for i = 1, JiangHuData.MAX_ARTIST_SKILL_COUNT, 1 do
		local tSelSkill = JiangHuData.tSelSkill[i] or {}
		UIHelper.RemoveAllChildren(self.tbSelSkillList[i])
		if tSelSkill.nLevel and tSelSkill.nSkill then
			local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tbSelSkillList[i]) assert(scriptBtn)
			scriptBtn.nSkillID = tSelSkill.nSkill
			scriptBtn.nSkillLevel = tSelSkill.nLevel
			local szImagePath = TabHelper.GetSkillIconPathByIDAndLevel(tSelSkill.nSkill, tSelSkill.nLevel)
			UIHelper.SetTexture(scriptBtn.ImgIcon, szImagePath)
			scriptBtn:HideLabelCount()
			scriptBtn:SetClickNotSelected(true)
			UIHelper.SetVisible(scriptBtn.ImgPolishCountBG, false)
			UIHelper.SetVisible(scriptBtn.ImgBlack, false)
			UIHelper.SetVisible(scriptBtn.ImgItemMask, false)
			self:UpdateItemBtnRecall(scriptBtn, i)
			table.insert(Storage.ArtistSkills.tbSkillList, i, tSelSkill)
			Storage.ArtistSkills.Dirty()
			UIHelper.SetVisible(self.tbImgAddList[i], false)
		elseif tSelSkill.nTabType and tSelSkill.nTabIndex then
			local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tbSelSkillList[i]) assert(scriptBtn)
			--scriptBtn:OnInitWithTabID(tSelSkill.nTabType, tSelSkill.nTabIndex)
			scriptBtn.nTabType = tSelSkill.nTabType
			scriptBtn.nTabID = tSelSkill.nTabIndex
			local item = ItemData.GetItemInfo(tSelSkill.nTabType, tSelSkill.nTabIndex)
			UIHelper.SetItemIconByItemInfo(scriptBtn.ImgIcon, item)
			scriptBtn:HideLabelCount()
			scriptBtn:SetClickNotSelected(true)
			UIHelper.SetVisible(scriptBtn.ImgPolishCountBG, false)
			UIHelper.SetVisible(scriptBtn.ImgBlack, false)
			UIHelper.SetVisible(scriptBtn.ImgItemMask, false)
			self:UpdateItemBtnRecall(scriptBtn, i)
			table.insert(Storage.ArtistSkills.tbSkillList, i, tSelSkill)
			Storage.ArtistSkills.Dirty()
			UIHelper.SetVisible(self.tbImgAddList[i], false)
		elseif tSelSkill.nEmotionID then
			local actionData = EmotionData.GetEmotionAction(tSelSkill.nEmotionID)
			local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.tbSelSkillList[i]) assert(itemScript)
			itemScript.nIconID = actionData.nIconID
			UIHelper.SetItemIconByIconID(itemScript.ImgIcon, actionData.nIconID)
			UIHelper.SetVisible(itemScript.LabelCount, false)
			UIHelper.SetVisible(itemScript.LabelPolishCount, false)
			itemScript:SetClickNotSelected(true)
			UIHelper.SetVisible(itemScript.ImgPolishCountBG, false)
			UIHelper.SetVisible(itemScript.ImgBlack, false)
			UIHelper.SetVisible(itemScript.ImgItemMask, false)
			self:UpdateItemBtnRecall(itemScript,i)
			table.insert(Storage.ArtistSkills.tbSkillList, i, tSelSkill)
			Storage.ArtistSkills.Dirty()
			UIHelper.SetVisible(self.tbImgAddList[i], false)
		else
			UIHelper.SetVisible(self.tbImgAddList[i], true)
		end
	end

end

function UIJiangHuPanel:IsSkillSelected(tbSelSkill)--技能是否已选
	local nCount = self:GetSelSkillCount(JiangHuData.tSelSkill)
	for i = 1, nCount, 1 do
		if self.nSetIndex == 1 and JiangHuData.tSelSkill[i].nLevel == tbSelSkill.nLevel and JiangHuData.tSelSkill[i].nSkill == tbSelSkill.nSkill then
			return true
		elseif self.nSetIndex == 2 or self.nSetIndex ==3 then
			if JiangHuData.tSelSkill[i].nTabType == tbSelSkill.nTabType and JiangHuData.tSelSkill[i].nTabIndex == tbSelSkill.nTabIndex then
				return true
			end
		elseif self.nSetIndex == 4 and JiangHuData.tSelSkill[i].nEmotionID == tbSelSkill.nEmotionID then
			return true
		end
	end
	return false
end

function UIJiangHuPanel:UpdateItemBtnRecall(tbScript,nIndex) --减号角标
	UIHelper.SetSwallowTouches(tbScript.BtnRecall, true)
	UIHelper.SetVisible(tbScript.BtnRecall, true)
	UIHelper.BindUIEvent(tbScript.BtnRecall, EventType.OnClick, function () --移除已选
		local nCount = self:GetSelSkillCount(JiangHuData.tSelSkill)
		table.remove(JiangHuData.tSelSkill, nIndex)
		UIHelper.RemoveAllChildren(self.tbSelSkillList[nIndex])
		UIHelper.RemoveAllChildren(self.tbSelSkillList[nCount])
		self:UpdateSelectSkill()
		self:SetItemSelected(tbScript)
	end)
end

function UIJiangHuPanel:SetItemClickCallback(tbScript, tbTypeSkill)--list的item点击回调
	tbScript:SetClickCallback(function()
		self:UpdateEmotionActionChoosenType(tbScript)
		local nCount = self:GetSelSkillCount(JiangHuData.tSelSkill)
		if not self:IsSkillSelected(tbTypeSkill) then
			if nCount < JiangHuData.MAX_ARTIST_SKILL_COUNT then
				tbScript:SetTogMultiSelected(true)
				tbScript:SetSelectEnable(false)
				self:InsertSelectSkill(tbTypeSkill)
				self:UpdateSelectSkill()
			else
				OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_ARTIST_SKILL_ENCOUGH)
			end
		end
	end)
end

function UIJiangHuPanel:SetBottomItemSelected(tbScript, tbTypeSkill)--勾角标显隐
	local nCount = self:GetSelSkillCount(JiangHuData.tSelSkill)
	if self:IsSkillSelected(tbTypeSkill) then
		tbScript:SetTogMultiSelected(true)
		tbScript:SetSelectEnable(false)
	else
		tbScript:SetTogMultiSelected(false)
		tbScript:SetSelectEnable(true)
	end
end

function UIJiangHuPanel:SetItemSelected(tbScript) --点击减号勾角标消失
	local nodes = UIHelper.GetChildren(self.ScrollViewIdentityList)
	for k, v in pairs(nodes) do
		local Script = UIHelper.GetBindScript(v)
		local Child = UIHelper.GetChildren(Script.WidgetItem)[1]
		local ScriptChild =  UIHelper.GetBindScript(Child)
		if self.nSetIndex == 4 and tbScript.nIconID == ScriptChild.nIconID then
			ScriptChild:SetTogMultiSelected(false)
			ScriptChild:SetSelectEnable(true)
		end
		if self.nSetIndex == 1 and tbScript.nSkillID == ScriptChild.nSkillID  and tbScript.nSkillLevel and ScriptChild.nSkillLevel then
			ScriptChild:SetTogMultiSelected(false)
			ScriptChild:SetSelectEnable(true)
		end
		if (self.nSetIndex == 3 or self.nSetIndex == 2) and tbScript.nTabType == ScriptChild.nTabType and tbScript.nTabID == ScriptChild.nTabID then
			ScriptChild:SetTogMultiSelected(false)
			ScriptChild:SetSelectEnable(true)
		end
	end
end

function UIJiangHuPanel:UpdateBtn()
	local player = GetClientPlayer()
	local bHaveCD = JiangHuData.UpdateIdentitySystemCD()
	JiangHuData.nCurActID = player.GetPlayerIdentityManager().dwCurrentIdentityType
	--LOG.INFO("JiangHuData.nCurActID :%s",tostring(JiangHuData.nCurActID))
	if JiangHuData.tSItem[self.nIndex].bActivate then --已拥有
		if JiangHuData.nCurActID and JiangHuData.nCurActID ~= 0 and JiangHuData.tSItem[self.nIndex].nIdentityIDS == JiangHuData.nCurActID then --当前身份已开启
			UIHelper.SetVisible(self.BtnOpen, false)
			UIHelper.SetVisible(self.BtnClose01, true)
			UIHelper.SetVisible(self.LayoutCountdown, false)
		elseif JiangHuData.nCurActID and JiangHuData.nCurActID ~= 0 then --当前身份未开启，但有其他身份开启
			if bHaveCD then --cd
				UIHelper.SetEnable(self.BtnOpen, false)
				UIHelper.SetButtonState(self.BtnOpen,BTN_STATE.Disable)
				UIHelper.SetVisible(self.LayoutCountdown, true)
			else --cd结束
				UIHelper.SetEnable(self.BtnOpen, true)
				UIHelper.SetButtonState(self.BtnOpen,BTN_STATE.Normal)
				UIHelper.SetVisible(self.LayoutCountdown, false)
			end
			UIHelper.SetVisible(self.BtnOpen, true)
			UIHelper.SetVisible(self.BtnClose01, false)
		else --无任何身份开启
			if bHaveCD then
				UIHelper.SetEnable(self.BtnOpen, false)
				UIHelper.SetButtonState(self.BtnOpen,BTN_STATE.Disable)
				UIHelper.SetVisible(self.LayoutCountdown, true)
			else
				UIHelper.SetVisible(self.LayoutCountdown, false)
			end
			UIHelper.SetVisible(self.BtnOpen, true)
			UIHelper.SetVisible(self.BtnClose01, false)
		end
	else --未拥有
		UIHelper.SetVisible(self.BtnOpen, false)
		UIHelper.SetVisible(self.BtnClose01, false)
		UIHelper.SetVisible(self.LayoutCountdown, false)
	end

end

function UIJiangHuPanel:UpdateTime()
	if UIHelper.GetVisible(self.LayoutCountdown) then
		local nCountDown = JiangHuData.nLeftTime
		UIHelper.SetString(self.LabelCountdownLabel,self:GetFormatTime(nCountDown))
		self.nTimer = Timer.AddCountDown(self, nCountDown, function(nRemain)
			UIHelper.SetString(self.LabelCountdownLabel,self:GetFormatTime(nRemain))
        end, function()
			UIHelper.SetEnable(self.BtnOpen, true)
			UIHelper.SetButtonState(self.BtnOpen,BTN_STATE.Normal)
			UIHelper.SetVisible(self.LayoutCountdown, false)
            self.nTimer = nil
        end)
	end
end

function UIJiangHuPanel:GetFormatTime(nTime)
    local nM = math.floor(nTime / 60)
    local nS = math.floor(nTime % 60)
    local szTimeText = ""

    if nM ~= 0 then
        szTimeText= szTimeText..nM..":"
    end

    if nS < 10 and nM ~= 0 then
        szTimeText = szTimeText.."0"
    end

    szTimeText= szTimeText..nS

    return szTimeText
end

function UIJiangHuPanel:GetIdentityDynSkill(tInfo)
	local szSkill = tInfo.szSkill
    if not szSkill or szSkill == "" then
        return
    end

	return string.split(szSkill, ";")
end

function UIJiangHuPanel:ShowArtistSkillConfig()
	self.nInfoIndex = 2
	self:UpdateRightTogInfo()
	UIHelper.SetSelected(self.tbSkillSetTogList[self.nSetIndex] , true)
	UIHelper.SetVisible(self.WidgetSkillinfoTips, false)
	UIHelper.RemoveAllChildren(self.ScrollViewIdentityList)
	self:UpdateSkillConfig()
end

function UIJiangHuPanel:UpdatePersonImg()
	UIHelper.SetSpriteFrame(self.ImgIcon01, tbIdentityIcon[self.nIndex])
end

function UIJiangHuPanel:UpdateSkillDetailInfo(dwSkillID, nSkillLevel)
	local dwID, nLevel = dwSkillID, nSkillLevel

    local szName       = Table_GetSkillName(dwID, nLevel)
    szName             = UIHelper.GBKToUTF8(szName)

    -- todo
    local szType       = "技能类型"

    local tRecipeKey   = g_pClientPlayer.GetSkillRecipeKey(dwID, nLevel)
    local pSkillInfo   = GetSkillInfo(tRecipeKey)

    local nCooldown    = 0
    for i = 1, 3 do
        local szKey = "CoolDown" .. i

        if pSkillInfo[szKey] > nCooldown then
            nCooldown = pSkillInfo[szKey]
        end
    end

    local nCD           = nCooldown / GLOBAL.GAME_FPS

    local szDescription = GetSubSkillDesc(dwID, nLevel)
    szDescription       = UIHelper.GBKToUTF8(szDescription)

	--橙色技能描述
	local tDescSkillInfo = Table_GetSkill(dwID, nLevel)
	if tDescSkillInfo then
		UIHelper.SetString(self.LabelDescribe01, UIHelper.GBKToUTF8(tDescSkillInfo.szHelpDesc))
	end

    UIHelper.RemoveAllChildren(self.WIdgetSkillCell)
    UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell, self.WIdgetSkillCell, dwSkillID, nSkillLevel)

    UIHelper.SetString(self.LabelSkillName, szName)
    UIHelper.SetString(self.LabelSkillType, szType)
    UIHelper.SetString(self.LabelSkillLevel, string.format("等级 %d", nLevel))
    UIHelper.SetString(self.LabelSkillTime, string.format("冷却  %d秒", nCD))
    UIHelper.SetString(self.LabelDescribe, szDescription)

    UIHelper.SetVisible(self.LabelSkillType, false)
	UIHelper.LayoutDoLayout(self.LayoutSkillTitle)
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillDetailsList)
    UIHelper.LayoutDoLayout(self.LayoutSkillDetailsList)
	UIHelper.SetTouchDownHideTips(self.ScrollViewSkillDetailsList, false)
end

function UIJiangHuPanel:UpdatePetDetailInfo(nTabType, nTabID)
	if not self.scriptItemTip then
		self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip)
	end
	UIHelper.SetVisible(self.scriptItemTip._rootNode , true)
	self.scriptItemTip:OnInitWithTabID(nTabType, nTabID)
	self.scriptItemTip:SetBtnState({})
end

function UIJiangHuPanel:UpdateEmptyState()
	local children = UIHelper.GetChildren(self.ScrollViewIdentityList)
	UIHelper.SetVisible(self.WidgetEmpty, table.is_empty(children))
end

function UIJiangHuPanel:UpdateLevelSlider()
	local tbExperience = JiangHuData.tSItem[self.nIndex].tExperience
	local nPercent = 0
	if tbExperience.nCurValue ~= 0 and tbExperience.nSlotValue ~= 0 then
		nPercent = tbExperience.nCurValue/tbExperience.nSlotValue
	else
		if JiangHuData.tSItem[self.nIndex].nLevel == 5 then
			nPercent = 1
		end
	end
	--UIHelper.SetProgressBarStarPercentPt(self.ImgSlider, 0 , 0)
	--UIHelper.SetProgressBarPercent(self.ImgSlider, nPercent*75)
	UIHelper.SetProgressBarPercent(self.ImgSlider, nPercent * 100)
end

function UIJiangHuPanel:FormatSkillName(szName)
	local szResult  = UIHelper.GBKToUTF8(szName)
	local nLength = UIHelper.GetUtf8Len(szResult)
	if nLength > 4 then
		szResult = UIHelper.GetUtf8SubString(szResult, 1, 3)
		szResult = szResult.. "…"
	end
	return szResult
end

return UIJiangHuPanel