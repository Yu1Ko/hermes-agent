-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlotDialogueView
-- Date: 2022-11-15 20:58:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local DATA_TYPE_TO_FUNC =
{
    [PLOT_DIALOGUE_ITEM_TYPE.NAME]    = "UpdateName" ,
    [PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON]  = "AddToggleList" ,
    [PLOT_DIALOGUE_ITEM_TYPE.TEXT]    = "UpdateDialogueText" ,
}

local tbMustUpdateFuncList = {
    "UpdateName",
    "UpdateDialogueText",
    "UpdateButtonList",
}

local UIPlotDialogueView = class("UIPlotDialogueView")

function UIPlotDialogueView:OnEnter(dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:InitData(dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)
    self:InitUI()
    self:UpdateNPCInfo(true)


    PlotMgr.GetNextItemDataList()--获得默认对话

    PlotMgr.CallOnDialogueOpenFunc()--主要是触发任务function

    InputHelper.LockMove(true)
end

function UIPlotDialogueView:SetHasInitData(bHasInitData)
    self.bHasInitData = bHasInitData
end

function UIPlotDialogueView:GetHasInitData()
    return self.bHasInitData or false
end

function UIPlotDialogueView:InitData(dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)
    self.dwIndex = dwIndex
    self.szText = szText  -- GWTextEncoder_Encode
    self.dwTargetType = dwTargetType
    self.dwTargetID = dwTargetID
    self.dwCameraID = dwCameraID
    self.dwOperation = nil

    self.tbDialogueList = {}
    self.tbDialogueSound = {}
    self:SetHasInitData(true)
    -- self.bUseszText = false
    -- self.bUseUnfinishedDialogue = false
    -- self.tbFinishFailID = {}
    self:SetHasQuestToAccept(false)
    if Platform.IsWindows() or Platform.IsMac() then
        Timer.DelTimer(self, self.nTimerID)
        Timer.AddFrameCycle(self, 3, function()
            self:_tryClose()
        end)
    end
    self:UpdateCamera()
end

function UIPlotDialogueView:InitUI()
    UIHelper.SetSwallowTouches(self.BtnBlock, true)
    UIHelper.SetSwallowTouches(self.ScrollViewScript, false)
    UIHelper.SetVisible(self.BtnSkip, false)
end

function UIPlotDialogueView:OnExit()
    InputHelper.LockMove(false)

    self.bInit = false
    self:UnRegEvent()
    UIHelper.SetVisible(self.WidgetAnchorRight, false)
    CameraMgr.EnableDof(false)
    self:UpdateNPCInfo(false)
    rlcmd("set LODGrade 0")
    PlotMgr.NpcCamera_Close(self.dwTargetType)
    if self.tbCameraParams then
        CameraMgr.Status_Set(self.tbCameraParams)
    end

    if self.tEnvCtrl then
        RLEnv.RemoveVisibleCtrl(self.tEnvCtrl)
        self.tEnvCtrl = nil
    end
end

function UIPlotDialogueView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        PlotMgr.ClosePanel(PLOT_TYPE.NEW)
    end)

    UIHelper.BindUIEvent(self.BtnSkip, EventType.OnClick, function(btn)
        self:UpdateAccept()
    end)

    UIHelper.BindUIEvent(self.BtnBox, EventType.OnClick, function(btn)
        self:OnClickNext()
    end)

    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function(btn)
        self:OnClickNext()
    end)

    UIHelper.BindUIEvent(self.BtnAwardPreview, EventType.OnClick, function(btn)
        self:HideAwardPreview()
    end)
end

function UIPlotDialogueView:RegEvent()

    Event.Reg(self, EventType.OnQuestAwardPreview, function(nQuestID)
        -- local tbQuestConfig = QuestData.GetQuestConfig(nQuestID)
        self:ShowAwardPreview(nQuestID)
    end)


    Event.Reg(self, EventType.OnStartNewQuestDialogue, function(nQuestID, tbQuestRpg, dwOperation)
        self:SetHasQuestToAccept(false)
        self:SetCurQuestID(nQuestID, dwOperation)
        if tbQuestRpg then
            self:SetCurQuestRPG(tbQuestRpg)
        else
            -- if dwOperation == 1 then
            --     QuestData.AcceptQuest(self.dwTargetType, self.dwTargetID, self.nQuestID)
            -- else
            --     self:FormatInfo()
            -- end
            self:UpdateAccept()
        end
    end)

    Event.Reg(self, EventType.OnItemDataListReady, function(tbItemDataList, nType)
        if nType == PLOT_TYPE.NEW then
            self:UpdateInfo(tbItemDataList)
            UIHelper.SetVisible(self.BtnNext, PlotMgr.GetNextClickCallBackCount() > 0)
        end
    end)

    Event.Reg(self, EventType.CloseDialoguePanel, function()
        PlotMgr.DelayClose(PLOT_TYPE.NEW)
    end)

    Event.Reg(self, "UI_START_AUTOFLY", function ()
        PlotMgr.ClosePanel(PLOT_TYPE.NEW)
    end)

    Event.Reg(self, EventType.OnSceneInteractByHotkey, function()
        if self.bCall then return end
        self.bCall = true
        Timer.Add(self, 0.1, function ()
            if (not self.tbButtonList) or #self.tbButtonList == 0 then
                self:OnClickNext()
            else
                self.tbButtonList[1].tbData.callback()
                self.tbButtonList = {}
            end
            self.bCall = false
        end)
    end)

end

function UIPlotDialogueView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIPlotDialogueView:OnClickNext()

    if self.dwOperation ~= nil then--交接任务对话
        if self.bClickClose then
            PlotMgr.ClosePanel(PLOT_TYPE.NEW)
        else
            if self:HaveNextDialogue() then
                self:ShowNext()
            else
                self:UpdateAccept()
            end
        end
    else
        if PlotMgr.GetNextClickCallBackCount() > 0 then-- 逻辑翻页（对应Dx：PlotDialoguePanel 240行）
            PlotMgr.CallNextClickCallBack()
        elseif #self.tbButtonList == 0 then
            PlotMgr.ClosePanel(PLOT_TYPE.NEW)
        end
    end
end


function UIPlotDialogueView:HaveNextDialogue()
    return #self.tbDialogueList >= 1
end


function UIPlotDialogueView:ShowNext()


    if self:GetHasQuestToAccept()  then return end


    self.szCurDialogueText = table.remove(self.tbDialogueList, 1)
    self.nCurSound = table.remove(self.tbDialogueSound, 1)

    self:PlaySound()

    PlotMgr.GetItemDataList(PLOT_TYPE.NEW, self.dwIndex, self.szCurDialogueText, self.dwTargetType, self.dwTargetID, false)
end


function UIPlotDialogueView:UpdateAccept()
    self:FormatInfo()
    UIHelper.SetVisible(self.BtnSkip, false)
end

function UIPlotDialogueView:FormatInfo()
    self.aInfo = {}
    local bUpdateItemList = true -- 是否刷新剧情内容
    if self.dwOperation == 1 then
        local _, aInfo = GWTextEncoder_Encode(self.szLastRPG or "")
        self.aInfo = aInfo or {}
        if self.nLastestSound and self.nLastestSound ~= 0 then
            self.nCurSound = self.nLastestSound
            self:PlaySound()
        end
        self.tbAcceptInfo = self:CreateQuestAcceptData()
    else
        local questInfo = GetQuestInfo(self.nQuestID)
        local tQuestStringInfo = QuestData.GetQuestConfig(self.nQuestID)
        local dwTID, target = nil, nil
        if self.dwTargetType == TARGET.NPC then
            dwTID, target = questInfo.dwEndNpcTemplateID, GetNpc(self.dwTargetID)
        elseif self.dwTargetType == TARGET.DOODAD then
            dwTID, target = questInfo.dwEndDoodadTemplateID, GetDoodad(self.dwTargetID)
        end
        local player = g_pClientPlayer
        if not target or target.dwTemplateID ~= dwTID then
            local _, aInfo = GWTextEncoder_Encode(tQuestStringInfo.szDunningDialogue.."\n\n")
            for k, v in pairs(aInfo) do
                table.insert(self.aInfo, v)
            end
            self.bClickClose = true
        elseif player.CanFinishQuest(self.nQuestID) == QUEST_RESULT.SUCCESS then
            local _, aInfo = GWTextEncoder_Encode(tQuestStringInfo.szFinishedDialogue.."\n\n")
            for k, v in pairs(aInfo) do
                table.insert(self.aInfo, v)
            end
            local szContent = g_tStrings.STR_QUEST_FINSISH_QUEST
            self.tbFinishInfo = self:CreateQuestFinishData(szContent)
            if QuestData.HaveChooseItem(self.nQuestID) then
                szContent = g_tStrings.STR_QUEST_FINSISH_CHOOSE_REWARD
                self.tbFinishInfo = self:CreateQuestFinishData(szContent)
            elseif not (questInfo.bRepeat and not questInfo.bAccept) then
                -- 如果直接完成任务，没有奖励物品溢出提示，则不刷新物品列表
                -- 因为之前去向服务器完成任务时，客户端会显示最后一句，造成闪一下
                -- 因此这里判断，如果没奖励客户端不刷新，这样就不会闪一下了
				local bHasRedward = QuestData.TryFinishQuest(self.nQuestID, self.dwTargetType, self.dwTargetID, 0, 4)
                bUpdateItemList = bHasRedward
                if not bUpdateItemList then
                    self.tbFinishInfo = nil -- 这里要置空，否则会显示“交任务”按钮
                end
			end
        else
            local _, aInfo = GWTextEncoder_Encode(tQuestStringInfo.szUnfinishedDialogue.."\n\n")
            for k, v in pairs(aInfo) do
                table.insert(self.aInfo, v)
            end
            -- if self.nLastQuestID and self.nLastQuestID == self.nQuestID then
            --     PlotMgr.ClosePanel(PLOT_TYPE.NEW)
            -- end
            -- self.nLastQuestID = self.nQuestID
        end

    end

    -- if #self.aInfo ~= 0 then
    if bUpdateItemList then
        PlotMgr.GetItemDataListByInfoList(PLOT_TYPE.NEW, self.dwIndex, self.aInfo, self.dwTargetType, self.dwTargetID, false)
    end
    -- end
end


function UIPlotDialogueView:UpdateInfo(tbItemDataList)

    self.tbButtonList = {}
    local tbFuncList = {}

    for nIndex, tbData in ipairs(tbItemDataList) do
        local szFuncName = DATA_TYPE_TO_FUNC[tbData.nItemType]
        if IsFunction(self[szFuncName]) then
            self[szFuncName](self, tbData)
            table.insert(tbFuncList, szFuncName)
        end
    end

    if self.tbAcceptInfo then
        self:AddToggleList(clone(self.tbAcceptInfo))
        self.tbAcceptInfo = nil
    end

    if self.tbFinishInfo then
        self:AddToggleList(clone(self.tbFinishInfo))
        self.tbFinishInfo = nil
    end

    for nIndex, szFuncName in ipairs(tbMustUpdateFuncList) do
        if not table.contain_value(tbFuncList, szFuncName) then
            self[szFuncName](self)
        end
    end
    -- self:UpdateImgArrow()
end


--------------------------------------------更新解析的结果-----------------------------------------------------
function UIPlotDialogueView:UpdateName(tbData)
    local szName = ""
    local szIconName = ""
    if tbData then
        szName = tbData.szContent
        szIconName = tbData.szIconName
    else
        szName =  UIHelper.GBKToUTF8(TargetMgr.GetTargetName(self.dwTargetType, self.dwTargetID)) or g_tStrings.STR_DIALOG_PANEL
        szIconName = QuestDialogueNameBGColor["NPC_NAME"]
    end
    UIHelper.SetString(self.LabelPlayerName, szName)
    UIHelper.SetSpriteFrame(self.ImgPlayerNameBg, szIconName)

    local szType = szIconName == QuestDialogueNameBGColor["NPC_NAME"] and "NPC_NAME" or "PLAYER_NAME"
    local szLeafIcon1 = QuestDialogueLeafColor[szType][1]
    local szLeafIcon2 = QuestDialogueLeafColor[szType][2]
    UIHelper.SetSpriteFrame(self.ImgLeaf1, szLeafIcon1)
    UIHelper.SetSpriteFrame(self.ImgLeaf2, szLeafIcon2)
end


function UIPlotDialogueView:UpdateDialogueText(tbData)
    if tbData then
        tbData.szContent = string.gsub(tbData.szContent, "[%s\n]+$", "")
        tbData.szContent = string.gsub(tbData.szContent, "侠士当前网络状况不佳，请切换网络环境再试。", "")
        UIHelper.SetRichText(self.RichTextScript, tbData.szContent)
    else
        UIHelper.SetRichText(self.RichTextScript, "")
    end
    -- local nHeight = UIHelper.GetHeight(self.RichTextScript)
    -- UIHelper.SetVisible(self.scrollBar, nHeight >= 144)
    UIHelper.ScrollViewDoLayout(self.ScrollViewScript)
    UIHelper.ScrollToTop(self.ScrollViewScript, 0)
end

function UIPlotDialogueView:UpdateImgArrow()
    UIHelper.SetVisible(self.ImgArrow, #self.tbDialogueList ~= 0)
end

function UIPlotDialogueView:AddToggleList(tbData)


    table.insert(self.tbButtonList, {tbData = tbData, nIndex = #self.tbButtonList + 1})
    if tbData.bClockDialogue then
        self:SetHasQuestToAccept(true)
    end
end

function UIPlotDialogueView:UpdateButtonList()

    if not self.tbButtonList then return end
    local nButtonNum = #self.tbButtonList

    local function GetItemPriority(tbInfo)
        local tbData = tbInfo.tbData
        local nPriority = 0
        if tbData.szDialogueIconBg and tbData.szDialogueIconBg == PLOT_ITEM_BG_IMG[1] then--黄色背景在前面
            nPriority = 1
        end
        return nPriority
    end

    table.sort(self.tbButtonList, function(l, r)
        local nPriorityA = GetItemPriority(l)
        local nPriorityB = GetItemPriority(r)
        if nPriorityA ~= nPriorityB then
            return nPriorityA > nPriorityB
        else
            return l.nIndex < r.nIndex
        end
    end)

    UIHelper.SetVisible(self.WidgetAnchorRight,  nButtonNum >= 1)
    if nButtonNum == 0 then return end

    UIHelper.RemoveAllChildren(self.ScrollViewDialogueContent)
    UIHelper.RemoveAllChildren(self.LayoutDialogueContent)
    local parent = nButtonNum >= 4 and self.ScrollViewDialogueContent or self.LayoutDialogueContent
    for nIndex, tbInfo in ipairs(self.tbButtonList) do
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetDialogueCell, parent, tbInfo.tbData)
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



function UIPlotDialogueView:CreateQuestAcceptData()
    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.QUEST
    local szAcceptDes = self.tbCurQuestRPG and UIHelper.GBKToUTF8(self.tbCurQuestRPG.szAcceptDes)
    if not szAcceptDes or szAcceptDes == "" then szAcceptDes = g_tStrings.STR_QUEST_ACCEPT_QUEST end
    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.bClockDialogue = true
    tbData.tbInfo = {name == "Q"}
    tbData.szContent = szAcceptDes
    tbData.szDialogueIcon = PlotMgr.GetDialogueQuestIcon(self.nQuestID, self.dwTargetType, self.dwTargetID)
    tbData.bCanAccept = QuestData.CanAcceptQuest(self.nQuestID, self.dwTargetType, self.dwTargetID)
    tbData.bCanFinish = QuestData.CanFinishQuest(self.nQuestID, self.dwTargetType, self.dwTargetID)
    tbData.szDialogueIconBg = PLOT_ITEM_BG_IMG[1]
    tbData.callback = function()
        QuestData.AcceptQuest(self.dwTargetType, self.dwTargetID, self.nQuestID)
    end
    tbData.funcAwardPreview = function()--任务奖励预览
        self:ShowAwardPreview(self.nQuestID)
    end
    return tbData
end

function UIPlotDialogueView:CreateQuestFinishData(szContent)
    local tbData = {}
    -- tbData.nDataType = PLOT_DATA_TYPE.QUEST

    tbData.nItemType = PLOT_DIALOGUE_ITEM_TYPE.NORMAL_BUTTON
    tbData.bClockDialogue = false
    -- tbData.tbInfo = tbInfo
    tbData.szContent = szContent or g_tStrings.STR_QUEST_FINSISH_QUEST
    -- tbData.szIconName = PlotMgr.GetDialogueQuestIcon(self.nQuestID, self.dwTargetType, self.dwTargetID)
    tbData.szDialogueIcon = PlotMgr.GetDialogueQuestIcon(self.nQuestID, self.dwTargetType, self.dwTargetID)
    tbData.szDialogueIconBg = PLOT_ITEM_BG_IMG[1]
    tbData.callback = function()
        if QuestData.HaveChooseItem(self.nQuestID) then
            if not UIMgr.IsViewOpened(VIEW_ID.PanelTaskRewardPop) then
                UIMgr.Open(VIEW_ID.PanelTaskRewardPop, self.nQuestID, self.dwTargetType, self.dwTargetID)
            end
        else
            QuestData.TryFinishQuest(self.nQuestID, self.dwTargetType, self.dwTargetID, 0, 4)
        end
    end
    tbData.funcAwardPreview = function()--任务奖励预览
        self:ShowAwardPreview(self.nQuestID)
    end
    return tbData
end


----------------------------------------------更新其他UI------------------------------------

function UIPlotDialogueView:ShowAwardPreview(nQuestID)
    UIHelper.SetVisible(self.BtnAwardPreview, true)
    local tbAwardList = QuestData.GetCurQuestAwardList(nQuestID)
    if not self.AwardPreviewScript  then
        self.AwardPreviewScript = UIHelper.AddPrefab(PREFAB_ID.WidgetRewardPreview, self.WidgetAnchorMiddle, tbAwardList, PREFAB_ID.WidgetAward)
    else
        self.AwardPreviewScript:OnEnter(tbAwardList, PREFAB_ID.WidgetAward)
    end
end

function UIPlotDialogueView:HideAwardPreview()
    if self.AwardPreviewScript  then
        UIHelper.RemoveAllChildren(self.WidgetAnchorMiddle)
        self.AwardPreviewScript = nil
    end
    UIHelper.SetVisible(self.BtnAwardPreview, false)
end

----------------------------------------------设置页面变量值-----------
function UIPlotDialogueView:SetHasQuestToAccept(bHasQuestToAccept)
    self.bHasQuestToAccept = bHasQuestToAccept
end


function  UIPlotDialogueView:GetHasQuestToAccept()
    return self.bHasQuestToAccept
end

--设置当前对话的任务ID
--dwOperation:1、交任务 2、完成任务
function UIPlotDialogueView:SetCurQuestID(nQuestID, dwOperation)
    self.nQuestID = nQuestID
    self.dwOperation = dwOperation
    PlotMgr.NpcCamera_Close(self.dwTargetType)
    if nQuestID ~= -1 then
        self:UpdateCamera()
    end
end

function UIPlotDialogueView:SetCurQuestRPG(tbQuestRpg)
    self.tbCurQuestRPG = tbQuestRpg
    UIHelper.SetVisible(self.BtnSkip, true)--拿到任务对话，打开跳过按钮
    self:UpdateDialogueList()
    self:SetHasQuestToAccept(false)

    if not self:HaveNextDialogue() and self.dwOperation == 1 then--只有一句且为接任务(抄端游的)
        self:UpdateAccept()
        return
    end
    self:ShowNext()
end

function UIPlotDialogueView:UpdateDialogueList()
    self.tbDialogueList = {}
    self.tbDialogueSound = {}
    local dwIndex = 1
    self.szLastRPG = ""
    self.nLastestSound = 0--最后一句
    if self.tbCurQuestRPG then
        while true do
            local szText = self.tbCurQuestRPG["szText" .. dwIndex]
            local nSound = self.tbCurQuestRPG["nSound" .. dwIndex]
            if not szText or szText == "" then
                break
            end
            table.insert(self.tbDialogueList, szText)
            table.insert(self.tbDialogueSound, nSound)
            dwIndex = dwIndex + 1
            self.szLastRPG = szText
            self.nLastestSound = nSound
        end
    end

    if self.dwOperation == 1 then--接任务，去掉最后一句
        table.remove(self.tbDialogueList, dwIndex - 1)
        table.remove(self.tbDialogueSound, dwIndex - 1)
    end
end

function UIPlotDialogueView:StopRPGSound()
    if not self.bStopNPCDialog then
		rlcmd("stop npc dialog 1") --立即停止播NPC待机声音
		self.bStopNPCDialog = true
	end
	if self.nLastSound then
	    Character_StopSound(self.dwTargetID)
        self.nLastSound = nil
    end
end

function UIPlotDialogueView:PlaySound()
    self:StopRPGSound()
    Character_PlaySound(self.dwTargetID, UI_GetClientPlayerID(), self.nCurSound, false)
    self.nLastSound = self.nCurSound
end

function UIPlotDialogueView:UpdateCamera()
    local tQuestRpg, bAccepted = nil, nil
    if self.nQuestID then
        tQuestRpg, bAccepted =Table_GetQuestRpg(self.nQuestID, self.dwTargetType, self.dwTargetID, self.dwOperation)
    end
    local dwCameraID = self.dwCameraID
    if tQuestRpg and tQuestRpg.dwCameraID ~= 0 then
        dwCameraID = tQuestRpg.dwCameraID
    end
    if dwCameraID ~= 0 then
        CameraMgr.EnableDof(true)
        rlcmd("set LODGrade 4")

        if not self.bFistUpdateCamera then
            local oriscale, oriyaw, oripitch = Camera_GetRTParams()
            local nEnterTime = 0 -- 单位 毫秒
            self.tbCameraParams = {
                mode    = "local camera",
                scale   = oriscale,
                yaw     = oriyaw,
                pitch   = oripitch,
                tick    = nEnterTime,
            }
            self.bFistUpdateCamera = true
        end
    end
    PlotMgr.NpcCamera_Open(self.dwTargetType, self.dwTargetID, dwCameraID)
end

function UIPlotDialogueView:UpdateNPCInfo(bOpen)
    if self.bOpen and self.bOpen == bOpen then --修复当正隐藏完Info的时候再次隐藏，导致self.bLife等变量值变为false，关闭界面时头顶图标等消失的问题
        return
    end

    if not self.tEnvCtrl then
        self.tEnvCtrl = RLEnv.PushVisibleCtrl()
    end

    self.bOpen = bOpen
    if bOpen then
        self.tEnvCtrl:ShowPlayer(PLAYER_SHOW_MODE.kNone)
        self.tEnvCtrl:ShowAllHeadFlags(false)   --强制不显示血条,名字
        Global_UpdateHeadTopPosition()
    else
        self.tEnvCtrl:ShowPlayer(PLAYER_SHOW_MODE.kAll)
        self.tEnvCtrl:RestoreHeadFlags()        -- 恢复血条、名字显示
        Global_UpdateHeadTopPosition()
    end
end

function UIPlotDialogueView:_tryClose()
    local pPlayer = g_pClientPlayer
    if not pPlayer or pPlayer.nMoveState == MOVE_STATE.ON_DEATH then
        PlotMgr.ClosePanel(PLOT_TYPE.NEW)
        return
    end

    if self.dwTargetType then
        if self.dwTargetType == TARGET.NPC then
            local npc = GetNpc(self.dwTargetID)
            if not npc or not npc.CanDialog(pPlayer) then
                PlotMgr.ClosePanel(PLOT_TYPE.NEW)
            end
        elseif self.dwTargetType == TARGET.DOODAD then
            local doodad = GetDoodad(self.dwTargetID)
            if not doodad or not doodad.CanDialog(pPlayer) then
                PlotMgr.ClosePanel(PLOT_TYPE.NEW)
            end
        end
    end
end

return UIPlotDialogueView
