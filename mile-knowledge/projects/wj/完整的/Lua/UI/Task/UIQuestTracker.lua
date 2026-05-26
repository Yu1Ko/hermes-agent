-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIQuestTracker
-- Date: 2022-11-15 15:14:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuestTracker = class("UIQuestTracker")

function UIQuestTracker:OnEnter(nQuestID, bPublicQuest)
    if not self.bInit then
        self:Init()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nQuestID = nQuestID
    self.bPublicQuest = bPublicQuest or false--世界公共任务
    self.bNav = false
    -- self.nMapID, self.tbPoints = QuestData.GetQuestMapIDAndPoints(self.nQuestID)
    self:UpdateInfo()
end

function UIQuestTracker:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self:RemoveAllTarget()
    if self.cellRichText then self.cellRichText:Dispose() end
    if self.cellSliderPool then self.cellSliderPool:Dispose() end
    self.cellRichText = nil
    self.cellSliderPool = nil
end

function UIQuestTracker:Init()
    self.cellRichText = self.cellRichText or PrefabPool.New(PREFAB_ID.WidgetRichTextOtherDescribe)
    self.cellSliderPool = self.cellSliderPool or PrefabPool.New(PREFAB_ID.WidgetSliderOtherDescribe)
end

function UIQuestTracker:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgetTaskNew, EventType.OnClick, function(btn)
        -- self:StopShowCanTrack()
        QuestData.SetTracingQuestID(self.nQuestID)
    end)

    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function(btn)

        if QuestData.IsIdentityQuest(self.nQuestID) then
            if QuestData.CheckIdentityQuestShowConfirm(self.nQuestID) then
                return
            end
        end

        if self.bPublicQuest and self.nQuestID then
            if not QuestData.IsTracingQuestID(self.nQuestID) then
                QuestData.SetTracingQuestID(self.nQuestID)
            end
            return--世界公共任务
        end

        if self.nQuestID then
            local func = QuestData.GetSpecialQuestHandler(self.nQuestID)
            if func then
                local bDone = func()
                if bDone then
                    return
                end
            end
        end

        if MapMgr.IsCurrentMap(self.nMapID) then
            local szRemark = "Quest_" .. self.nQuestID
            AutoNav.NavTo(self.nMapID, self.tbPoints[1], self.tbPoints[2], self.tbPoints[3], AutoNav.DefaultNavCutTailCellCount, szRemark)
            self:PlayZhuizongSFX()
            return
        end

        local _, nMapType = GetMapParams(self.nMapID)
        if not nMapType then
            TipsHelper.ShowNormalTip("请按任务描述进行操作")
            return
        end

        if nMapType == 1 then --秘境
            UIMgr.Open(VIEW_ID.PanelDungeonEntrance, {bNeedChooseFirst=false, dwTargetMapID = self.nMapID})
        else
            UIMgr.Open(VIEW_ID.PanelMiddleMap, self.nMapID, 0, nil, nil, {szMessage = "请前往最近的神行点进行任务"})
        end
    end)
    UIHelper.SetTouchEnabled(self._rootNode, true)
    UIHelper.SetSwallowTouches(self._rootNode, false)
end

function UIQuestTracker:RegEvent()
	-- Event.Reg(self, "QUEST_FAILED", function(nQuestIndex)
    --     self:UpdateInfo()
    -- end)
	-- Event.Reg(self, "QUEST_CANCELED", function(dwQuestID)
    --     self:UpdateInfo()
    -- end)
	-- Event.Reg(self, "QUEST_FINISHED", function(dwQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
    --     self:UpdateInfo()
    -- end)
	-- Event.Reg(self, "SET_QUEST_STATE", function(dwQuestID, byQuestState)
    --     self:UpdateInfo()
    -- end)
	-- Event.Reg(self, "QUEST_SHARED", function(dwSrcPlayerID, dwQuestID)
    --     self:UpdateInfo()
    -- end)
	-- Event.Reg(self, "QUEST_DATA_UPDATE", function(nQuestIndex, eEventType)
    --     self:UpdateInfo()
    -- end)
    -- Event.Reg(self, "QUEST_TIME_UPDATE", function(nQuestIndex)
    --     self:UpdateInfo()
    -- end)

    -- Event.Reg(self, EventType.OnQuestTracingTargetChanged, function() self:UpdateInfo() end)


    Event.Reg(self, EventType.OnAutoNavResult, function(bSuccess)
        local bNav = AutoNav.IsNavQuest(self.nQuestID)
        if self.bNav ~= bNav then
            self.bNav = bNav
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "SYS_MSG", function (szEventType, nRespondCode, nMoney)
        if szEventType == "UI_OME_USE_ITEM_RESPOND" then

            -- 避免频繁点击时界面会闪一下，所以有些错误码就不做刷新处理
			if nRespondCode == USE_ITEM_RESULT_CODE.NOT_READY then
                return
            end

            self:UpdateInfo()
		end
	end)

    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "CHANGE_CHARACTER_IDENTITY_VISIABLE_ID", function()
        if arg0 == UI_GetClientPlayerID() then
            self:UpdateInfo()
		end
    end)

    Event.Reg(self, "QUEST_TIME_UPDATE", function(nQuestIndex)
        local nQuestID = g_pClientPlayer and g_pClientPlayer.GetQuestID(nQuestIndex)
        if self.nQuestID and nQuestID == self.nQuestID then
            self:UpdateCountDown()
        end
    end)


end

function UIQuestTracker:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuestTracker:UpdateInfo()

    self:UpdateInfo_Invalid()

    if IsNumber(self.nQuestID) and self.nQuestID > 0 then
        self.nMapID, self.tbPoints = QuestData.GetQuestMapIDAndPoints(self.nQuestID, true)
        self:UpdateInfo_Content()
        self:UpdateInfo_UseItem()
        self:UpdateDoubleExpMark()
        -- self:UpdateInfo_TrackNew()

    end
    if self.nDoLayoutTimer then
        Timer.DelTimer(self, self.nDoLayoutTimer)
    end

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    self.nDoLayoutTimer = Timer.AddFrame(self, 1, function()
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end)
end

function UIQuestTracker:UpdateInfo_Content()

    local szName = QuestData.GetQuestName(self.nQuestID)
    if QuestData.IsFailed(self.nQuestID) then
        szName = "【失败】"..szName
    end


    UIHelper.SetVisible(self.MaskEff, not self.bNav)
    UIHelper.SetVisible(self.ImgTaskMark, not self.bNav)
    UIHelper.SetVisible(self.ImgTaskAuto, self.bNav)

    UIHelper.SetVisible(self.LabelTaskTitle, true)
    UIHelper.SetString(self.LabelTaskTitle, szName, 9)

    local nQuestType = QuestData.GetQuestNewType(self.nQuestID)
    local nColor
    if nQuestType == QuestType.Branch or nQuestType == QuestType.Other then
        local tbQuestInfo = QuestData.GetQuestInfo(self.nQuestID)
        local nLevel = tbQuestInfo and tbQuestInfo.nLevel or 1
        if nLevel < 5 then
            nColor = QuestTypeColor[nQuestType][1]
        elseif nLevel >= 5 and nLevel <= 10 then
            nColor = QuestTypeColor[nQuestType][2]
        else
            nColor = QuestTypeColor[nQuestType][3]
        end
    else
        nColor = QuestTypeColor[nQuestType]
    end
    UIHelper.SetColor(self.LabelTaskTitle, nColor)

    self:UpdateInfo_Target()

    local bCurrentMap = QuestData.IsInCurrentMap(self.nQuestID)
    local tbTraceQuest = QuestData.GetTracingQuestIDList()
    local _, nMapType = GetMapParams(self.nMapID)
    local szMubiaoPath = self.nQuestID == tbTraceQuest[1] and "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_mubiao" or "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_mubiao2"
    local imgTask = bCurrentMap and szMubiaoPath or (nMapType and "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_shenxing1" or "UIAtlas2_Public_PublicIcon_PublicIcon1_img_NoGuideTask")

    if self.bPublicQuest then
        imgTask = "UIAtlas2_Public_PublicIcon_PublicIcon1_ImgWorldTask5.png"
    end

    if QuestData.IsIdentityQuest(self.nQuestID) then
        imgTask = "UIAtlas2_Public_PublicIcon_PublicIcon1_btn_shenxing4.png"
    end

    UIHelper.SetSpriteFrame(self.ImgTaskMark, imgTask)
    UIHelper.SetVisible(self.Eff_UITaskTracking, not bCurrentMap)
    UIHelper.SetVisible(self.ImgTaskBg, not self.bPublicQuest)

    UIHelper.WidgetFoceDoAlign(self)
end

function UIQuestTracker:RemoveAllTarget()
    if self.tbTargetNode then
        for nIndex, tbNode in ipairs(self.tbTargetNode) do
            tbNode.cellPool:Recycle(tbNode.node)
        end
    end
    self.tbTargetNode = {}
    self.scriptCountDown = nil
end

function UIQuestTracker:UpdateInfo_Target()
    self:RemoveAllTarget()

    self:UpdateCountDown()

    local tbTargetList = QuestData.GetQuestTargetString(self.nQuestID)
    for nIndex, tbTargetInfo in ipairs(tbTargetList) do
        if IsString(tbTargetInfo) then
            local node, scriptView = self.cellRichText:Allocate(self.LayoutTask, tbTargetInfo, nil, 24)
            UIHelper.SetAnchorPoint(node, 0.5, 1)
            table.insert(self.tbTargetNode, {node = node, cellPool = self.cellRichText})
        else
            local szTitle = tbTargetInfo.szName
            local szValue = tbTargetInfo.nHave.."/"..tbTargetInfo.nNeed
            local nPercent = (tbTargetInfo.nHave / tbTargetInfo.nNeed) * 100
            local node, scriptView = self.cellSliderPool:Allocate(self.LayoutTask, szTitle, szValue, nPercent, 11, false)
            UIHelper.SetAnchorPoint(node, 0.5, 1)
            table.insert(self.tbTargetNode, {node = node, cellPool = self.cellSliderPool})
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutTask)
end

function UIQuestTracker:UpdateCountDown()
    local szTime = QuestData.GetQuestTime(self.nQuestID)
    if szTime ~= "" then
        if not self.scriptCountDown then
            local node, scriptView = self.cellRichText:Allocate(self.LayoutTask, szTime, nil, 24)
            UIHelper.SetAnchorPoint(node, 0.5, 1)
            table.insert(self.tbTargetNode, {node = node, cellPool = self.cellRichText})
            self.scriptCountDown = scriptView
        else
            self.scriptCountDown:UpdateInfo(szTime)
        end
    end
end

function UIQuestTracker:UpdateInfo_UseItem()
    self.dwItemType = nil
    self.dwItemIndex = nil

    if QuestData.IsFailed(self.nQuestID) then
        return
    end

    local tbQuestInfo = QuestData.GetQuestInfo(self.nQuestID)
    if tbQuestInfo then
        local tbConf = QuestData.GetQuestConfig(self.nQuestID)
        local dwItemType = tbQuestInfo["dwOfferItemType1"]
        local dwItemIndex = tbQuestInfo["dwOfferItemIndex1"]
        if dwItemType > 0 and dwItemIndex > 0 and tbConf and tbConf.bUseItem then
            self.dwItemType = dwItemType
            self.dwItemIndex = dwItemIndex

            local nAmount = ItemData.GetItemAmountInPackage(dwItemType, dwItemIndex)

            --1、当richText的内容小于108的时候，加载到WidgetTaskItemUse1
            --2、当richText的内容大于108的时候，加载到WidgetTaskItemUse2，且ScrollViewTask的高度需要变为180
            -- local nRichTextHeight = UIHelper.GetHeight(self.RichTextTask)--没有用self.RichTextTask承载目标内容了
            -- local parent = nRichTextHeight < 108 and self.WidgetTaskItemUse1 or self.WidgetTaskItemUse2


            -- UIHelper.RemoveAllChildren(parent)
            self.itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskItemUse, self.WidgetTaskItemUse1, dwItemType, dwItemIndex, nAmount)

            UIHelper.SetVisible(self.WidgetTaskItem1, true)
            UIHelper.SetVisible(self.WidgetTaskItemUse1, true)
            -- UIHelper.SetVisible(self.WidgetTaskItemUse2, nRichTextHeight >= 108)
        end
    end

end

function UIQuestTracker:UpdateDoubleExpMark()
    UIHelper.SetVisible(self.ImgIcon, QuestData.IsDoubleExpQuest(self.nQuestID))
end

-- function UIQuestTracker:UpdateInfo_TrackNew()
--     UIHelper.SetVisible(self.WidgetTaskNew, self.bNewTaskCanTrack)
-- end

function UIQuestTracker:UpdateInfo_Invalid()

    -- UIHelper.SetString(self.LabelTaskTitle, "--")
    UIHelper.SetVisible(self.LabelTaskTitle, false)
    UIHelper.SetVisible(self.ImgTaskMark, false)
	UIHelper.SetRichText(self.RichTextTask, string.format("<div>%s</div>", ""))


    UIHelper.SetVisible(self.WidgetTaskItem1, false)
    UIHelper.SetVisible(self.WidgetTaskItemUse1, false)
    UIHelper.SetVisible(self.WidgetTaskItemUse2, false)
    UIHelper.RemoveAllChildren(self.WidgetTaskItemUse1)
    UIHelper.RemoveAllChildren(self.WidgetTaskItemUse2)

    UIHelper.SetVisible(self.WidgetTaskNew, false)
end

-- function UIQuestTracker:StartShowCanTrack(nQuestID)
--     self.bNewTaskCanTrack = true
--     self.nQuestID = nQuestID
--     self.szTarget = QuestData.GetQuestTargetString(self.nQuestID, true)

--     self:UpdateInfo()

--     -- 8s 后还原所追踪的任务
--     Timer.DelTimer(self, self.nTimerID)
--     self.nTimerID = Timer.Add(self, 8, function()
--         self:StopShowCanTrack()
--         self:UpdateInfo()
--     end)
-- end

-- function UIQuestTracker:StopShowCanTrack()
--     Timer.DelTimer(self, self.nTimerID)
--     self.bNewTaskCanTrack = false
-- end

function UIQuestTracker:PlayZhuizongSFX()
    UIHelper.SetVisible(self.Eff_RenWuZhuiZong, true)

    if self.nPlaySFXTimer then
        Timer.DelTimer(self, self.nPlaySFXTimer)
        self.nPlaySFXTimer = nil
    end
    self.nPlaySFXTimer = Timer.Add(self, 1, function()
        UIHelper.SetVisible(self.Eff_RenWuZhuiZong, false)
        self.nPlaySFXTimer = nil
    end)
end


return UIQuestTracker