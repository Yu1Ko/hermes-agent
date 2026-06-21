-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILuckyMeetingDialogue
-- Date: 2024-05-08 19:58:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UILuckyMeetingDialogue = class("UILuckyMeetingDialogue")

function UILuckyMeetingDialogue:OnEnter(dwIndex, dwTargetType, dwTargetID, tbInfoList, tbQuestStringInfo, szQuestState)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UnDelayClose()
    self:Init(dwIndex, dwTargetType, dwTargetID, tbInfoList, tbQuestStringInfo, szQuestState)
end

function UILuckyMeetingDialogue:OnExit()
    PlotMgr.NpcCamera_Close(self.dwTargetType)
    self:SheildEnable(false)
    if self.bSetCamera then
        CameraMgr.Status_Backward("all")
    end
    self.bInit = false
    self:UnRegEvent()
end

function UILuckyMeetingDialogue:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBox, EventType.OnClick, function(btn)
        self:ShowQiYuNextDialogue()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UILuckyMeetingDialogue:RegEvent()
    Event.Reg(self, EventType.OnSceneInteractByHotkey, function()
        if self.bCall then return end
        self.bCall = true
        Timer.Add(self, 0.1, function ()
            if  (not self.tbButtonList) or #self.tbButtonList == 0 then
                self:ShowQiYuNextDialogue()
            else
                self.tbButtonList[1].callback()
                self.tbButtonList = {}
            end
            self.bCall = false
        end)
    end)

    Event.Reg(self,"QUEST_FINISHED",function(dwQuestID)
        LOG.INFO("-------UIPlotDialogueView   QUEST_FINISHED-------",tostring(dwQuestID))

        local bHasNext = PlotMgr.GetSubsequenceQiYuQuestDialogue(self.dwTargetType, self.dwTargetID, dwQuestID)

        if not bHasNext then
            bHasNext = PlotMgr.GetNextQiYuQuestDialogue(self.dwTargetType, self.dwTargetID, self.tbQuestIDList)
        end

        if not bHasNext then
            UIMgr.Close(self)
        end

    end)

    Event.Reg(self,"SET_QUEST_STATE",function(dwQuestID, nQuestState)
        if nQuestState ~= 1 then return end

        local bHasNext = PlotMgr.GetSubsequenceQiYuQuestDialogue(self.dwTargetType, self.dwTargetID, dwQuestID)

        if not bHasNext then
            bHasNext = PlotMgr.GetNextQiYuQuestDialogue(self.dwTargetType, self.dwTargetID, self.tbQuestIDList)
        end

        if not bHasNext then
            UIMgr.Close(self)
        end

    end)

    Event.Reg(self, EventType.OnStartQiYuDialogue, function(tbInfoList, tbQuestStringInfo, szQuestState)--开始奇遇对话
        self:InitDialogueInfo(tbInfoList, tbQuestStringInfo, szQuestState)
    end)
end

function UILuckyMeetingDialogue:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UILuckyMeetingDialogue:Init(dwIndex, dwTargetType, dwTargetID, tbInfoList, tbQuestStringInfo, szQuestState)
    self.dwIndex, self.dwTargetType, self.dwTargetID = dwIndex, dwTargetType, dwTargetID
    UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(TargetMgr.GetTargetName(dwTargetType, dwTargetID)))
    self:InitDialogueInfo(tbInfoList, tbQuestStringInfo, szQuestState)
    if dwTargetType == TARGET.NPC then
        PlotMgr.NpcCamera_Open(dwTargetType, dwTargetID, 2)
        self:SheildEnable(true,  false)
    elseif dwTargetType == TARGET.PLAYER then
        PlotMgr.NpcCamera_Close(dwTargetType)
        self.bSetCamera = true
        CameraMgr.Status_Push({
            mode    = "local camera",
            scale   = 0.10,
            yaw     = 2 * math.pi - (g_pClientPlayer.nFaceDirection / 255 * math.pi * 2 + math.pi / 4),
            pitch   = - math.pi / 8,
            tick    = 300,
        })
        self:SheildEnable(true,  true)
    end
end

function UILuckyMeetingDialogue:GetNpcQuestID(dwTargetId)
    local tList = {}
	local npc = GetNpc(dwTargetId)
	if npc then
		local tQuest = npc.GetNpcQuest()
		for _, dwQuestId in pairs(tQuest) do
			local tQuestStringInfo = Table_GetQuestStringInfo(dwQuestId)
			if tQuestStringInfo.IsAdventure == 1 then
				table.insert(tList, dwQuestId)
			end
		end
	end

	return tList
end

function UILuckyMeetingDialogue:InitDialogueInfo(tbInfoList, tbQuestStringInfo, szQuestState)
    self.tbButtonList = nil
    self.tbQiYuInfoList = tbInfoList
    self.tbQuestStringInfo = tbQuestStringInfo
    self.szQuestState = szQuestState
    self.bQuestQiYu = tbInfoList == nil
    if self.bQuestQiYu then
        self.tbQuestIDList = self:GetNpcQuestID(self.dwTargetID)
    end

    self.bInQiYuDialogue = true

    if self.bQuestQiYu then--LuckyMeetingDialogue 270行
        local szDes = ""
        if szQuestState == "finished" then
            szDes = tbQuestStringInfo.szFinishedDialogue
        elseif szQuestState == "accpet" then
            szDes = tbQuestStringInfo.szDescription
        elseif szQuestState == "finishing" then
            szDes = tbQuestStringInfo.szUnfinishedDialogue
        elseif szQuestState == "option" then
            szDes = tbQuestStringInfo.szDunningDialogue
        end

        local _, aInfo = GWTextEncoder_Encode(szDes .."\n")
        self.tbQiYuInfoList = aInfo
    end

    self.tbQiYuDialogueList = PlotMgr.GetQiYuDialogueList(self.bQuestQiYu, self.tbQiYuInfoList, self.tbQuestStringInfo, self.szQuestState, self.dwTargetType, self.dwTargetID, self.dwIndex)
    self:ShowQiYuNextDialogue()
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILuckyMeetingDialogue:UpdateInfo()
    
end

function UILuckyMeetingDialogue:ShowQiYuNextDialogue()
    if self.tbButtonList and #self.tbButtonList > 0 then return end--有按钮不让下一句
    local nLen = #self.tbQiYuDialogueList.tbTextList  
    if nLen >= 1 then
        local tbData = {}
        tbData.szContent = table.remove(self.tbQiYuDialogueList.tbTextList, 1)
        self:UpdateDialogueText(tbData)
    end

    self.tbButtonList = {}
    if nLen == 1 then
        self:AddQiYuToggleList()
    elseif nLen == 0 then
        UIMgr.Close(self)--没有奇遇对话了，关闭面板(DX没有这个逻辑)
        return 
    end
    self:UpdateButtonList()
end

function UILuckyMeetingDialogue:AddQiYuToggleList()
    for nIndex, tbData in ipairs(self.tbQiYuDialogueList.tbButtList) do
        table.insert(self.tbButtonList, tbData)
    end
end

function UILuckyMeetingDialogue:UpdateDialogueText(tbData)
    if tbData then
        tbData.szContent = string.gsub(tbData.szContent, "[%s\n]+$", "")
        UIHelper.SetRichText(self.RichTextScript, tbData.szContent)
    else
        UIHelper.SetRichText(self.RichTextScript, "")
    end
    -- local nHeight = UIHelper.GetHeight(self.RichTextScript)
    -- UIHelper.SetVisible(self.scrollBar, nHeight >= 144)
    UIHelper.ScrollViewDoLayout(self.ScrollViewScript)
    UIHelper.ScrollToTop(self.ScrollViewScript, 0)
    UIHelper.SetSwallowTouches(self.ScrollViewScript, false)
end

function UILuckyMeetingDialogue:UpdateButtonList()

    if not self.tbButtonList then return end
    local nButtonNum = #self.tbButtonList


    UIHelper.SetVisible(self.WidgetAnchorRight,  nButtonNum >= 1)
    if nButtonNum == 0 then return end

    UIHelper.RemoveAllChildren(self.ScrollViewDialogueContent)
    UIHelper.RemoveAllChildren(self.LayoutDialogueContent)
    local parent = nButtonNum >= 4 and self.ScrollViewDialogueContent or self.LayoutDialogueContent
    for nIndex, tbData in ipairs(self.tbButtonList) do
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetLuckyMeetingDialogueCell, parent, tbData)
    end

    UIHelper.SetVisible(self.WidgetAnchorRight, nButtonNum >= 1)
    UIHelper.SetVisible(self.ScrollViewDialogueContent, nButtonNum >= 4)
    UIHelper.SetVisible(self.LayoutDialogueContent, nButtonNum < 4)

    if nButtonNum >= 4 then
        UIHelper.ScrollViewDoLayout(self.ScrollViewDialogueContent)
        UIHelper.ScrollToTop(self.ScrollViewDialogueContent, 0)
    else
        UIHelper.LayoutDoLayout(self.LayoutDialogueContent)
    end

    UIHelper.SetSwallowTouches(self.ScrollViewDialogueContent, true)

    UIHelper.SetTouchEnabled(self.LayoutDialogueContent, true)
end

function UILuckyMeetingDialogue:UnDelayClose()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end

function UILuckyMeetingDialogue:DelayClose()
    self:UnDelayClose()
    self.nTimer = Timer.Add(self, 0.6, function()
        UIMgr.Close(self)
    end)
end

function UILuckyMeetingDialogue:SheildEnable(bVisable, bIsPlayer)
	-- local dwType, dwID = Target_GetTargetData()
	-- if dwID and bVisable then
	-- 	rlcmd(string.format("lock npc %d %d", dwID, 0)) -- 锁定NPC、不改Npc面向
	-- 	rlcmd("set npc animation " .. dwID .. " " .. 30)
	-- elseif dwID then
	-- 	rlcmd("unlock npc " .. dwID) -- 解锁NPC
	-- end

	if bVisable then
		if bIsPlayer then
			rlcmd("show self")
			rlcmd("hide npc")
		else
			rlcmd("hide self") --隐藏自己
			rlcmd("show npc")
		end
		-- HideGlobalHeadTop()
		-- Hotkey.ShieldAll(true)
		-- Hotkey_EnableAutoRun(false)
		-- Hotkey_EnableLMouse(false)
		-- Hotkey_EnableRMouse(false)
		-- Hotkey.ModifyShield(false, GetKeyValue("Esc"))
	else
		rlcmd("show self")
		rlcmd("show npc")
		-- ResumeGlobalHeadTop()
		-- Hotkey.ShieldAll(false)
		-- Hotkey_EnableAutoRun(true)
		-- Hotkey_EnableLMouse(true)
		-- Hotkey_EnableRMouse(true)
	end
end

return UILuckyMeetingDialogue