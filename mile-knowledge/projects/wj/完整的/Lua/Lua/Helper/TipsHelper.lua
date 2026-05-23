TipsHelper = TipsHelper or {
    Def = {
        MaxLifeTime = 10, -- 最大显示时长
        Queue1 = 1,       -- 队1, NormalTips
        Queue2 = 2,       -- 队2, ImportantTips/PlaceTips
        Queue3 = 3,       -- 队3, 可操作性区域提示排队
    },
}
local self = TipsHelper

local _tNormalBlackList = {--配置后，聊天频道系统消息，tips不显示，包含以下文字的
    "你获得称号",
    "名剑大会倒计时:5",
    "名剑大会倒计时:4",
    "名剑大会倒计时:3",
    "名剑大会倒计时:2",
    "名剑大会倒计时:1",
    "名剑大会倒计时:0",
    "名剑大会开始!!!",
	"龙门绝境开启倒计时:5",
    "龙门绝境开启倒计时:4",
    "龙门绝境开启倒计时:3",
    "龙门绝境开启倒计时:2",
    "龙门绝境开启倒计时:1",
    "龙门绝境开启倒计时:0",
    "龙门绝境开始!!!",
    "战斗将在5秒后开始。",
    "战斗将在4秒后开始。",
    "战斗将在3秒后开始。",
    "战斗将在2秒后开始。",
    "战斗将在1秒后开始。",
    "战斗开始。",
    "您已成功激活武技殊影图！",
}
local _fnCheckBlackList = function(szText)
    for i = 1, #_tNormalBlackList do
        if string.find(szText, _tNormalBlackList[i]) then
            return true
        end
    end
    return false
end

local _tSmallEventList = {
    EventType.ShowLikeTip,
    EventType.ShowTradeTip,
    EventType.ShowInteractTip,
    EventType.ShowRoomTip,
    EventType.ShowTeamTip,
}

local _tIgnoreUnpackTip = {
    [EventType.ShowImportantTip] = true,
    [EventType.ShowPlaceTip] = true,
}

local _tHoldOnTip = {
    [EventType.ShowImportantTip] = true,
}

local _fnCheckIsFromBubbleIcon = function(nQueueIndex, tEvent)
    if nQueueIndex ~= self.Def.Queue3 then
        return
    end

    if tEvent and (tEvent[1] == EventType.ShowLikeTip
        or tEvent[1] == EventType.ShowTradeTip
        or tEvent[1] == EventType.ShowInteractTip
        or tEvent[1] == EventType.ShowRoomTip
        or tEvent[1] == EventType.ShowAssistNewbieInviteTip
        or tEvent[1] == EventType.ShowTeamTip) then
        return tEvent[2].bFromBubbleIcon
    end

    return false
end

function TipsHelper.InitEventQueue()
    if self.tEventQueueArr then return end
    self.tEventQueueArr = {
        {}, -- Queue1
        {}, -- Queue2
        {}, -- Queue3
    }
    self.tCurEventArr = {}
    self.tCurSmallArr = {}
end

function TipsHelper.UnInitEventQueue()
    self.tEventQueueArr = nil
    self.tCurEventArr = nil
    self.tCurSmallArr = nil
end

function TipsHelper:Init(bTop)
    self.InitEventQueue()

    local nViewID = bTop and VIEW_ID.PanelHintTop or VIEW_ID.PanelHint
    if not UIMgr.IsViewOpened(nViewID) then
        UIMgr.Open(nViewID, bTop)
    end

    if not self.bRegEvents then
        self.bRegEvents = true
        Event.Reg(self, EventType.OnSceneTouchTarget, function()
            self.DeleteAllHoverTips(false)
        end)

        Event.Reg(self, EventType.OnSceneTouchNothing, function()
            self.DeleteAllHoverTips(false)
        end)

        Event.Reg(self, EventType.HideAllHoverTips, function()
            self.DeleteAllHoverTips(false)
        end)

        Event.Reg(self, EventType.OnViewClose, function(nViewID)
            if nViewID == VIEW_ID.PanelLoading then
                if self.tbLoadingQueueMap then
                    for nQueueIndex, v in pairs(self.tbLoadingQueueMap) do
                        self.NextTip(nQueueIndex)
                    end
                end
                self.tbLoadingQueueMap = nil
            end
        end)

        Event.Reg(self, EventType.CloseLevelUpPanel, function(bCloseLevelUpPanel)
            self.bCloseLevelUpPanel = bCloseLevelUpPanel
        end)

        Event.Reg(self, "SYS_MSG", function(szEvent)
            if szEvent == "UI_OME_DEATH_NOTIFY" then
                self:Init(true)
                Event.Dispatch(EventType.UpdateDeathNotify, arg1, arg2)
            end
        end)
    end
end

function TipsHelper:UnInit()
    UIMgr.Close(VIEW_ID.PanelHint)
    UIMgr.Close(VIEW_ID.PanelHintTop)

    self.UnInitEventQueue()
end

function TipsHelper.ShowNormalTip(Text, bRichText, funcTipEnd)
    if not TipsHelper.TextTipsCheck(Text) then
        return
    end

    if _fnCheckBlackList(Text) then
        return
    end

    self:Init(true)
    -- TipsHelper.PushEvent(self.Def.Queue1, { EventType.ShowNormalTip, Text, bRichText })
    Event.Dispatch(EventType.ShowNormalTip, Text, bRichText, funcTipEnd)
end

function TipsHelper.ShowImportantBlueTip(Text, bRichText, nTime)
    if not TipsHelper.TextTipsCheck(Text) then
        return
    end

    self:Init(true)
    -- TipsHelper.PushEvent(self.Def.Queue2, { EventType.ShowImportantTip, "Blue", Text, bRichText, nTime })
    TipsHelper.PushImportantTips(self.Def.Queue2, { EventType.ShowImportantTip, "Blue", Text, bRichText, nTime })
end

function TipsHelper.ShowImportantRedTip(Text, bRichText, nTime)
    if not TipsHelper.TextTipsCheck(Text) then
        return
    end

    self:Init(true)
    -- TipsHelper.PushEvent(self.Def.Queue2, { EventType.ShowImportantTip, "Red", Text, bRichText, nTime })
    TipsHelper.PushImportantTips(self.Def.Queue2, { EventType.ShowImportantTip, "Red", Text, bRichText, nTime })
end

function TipsHelper.ShowImportantYellowTip(Text, bRichText, nTime)
    if not TipsHelper.TextTipsCheck(Text) then
        return
    end

    self:Init(true)
    -- TipsHelper.PushEvent(self.Def.Queue2, { EventType.ShowImportantTip, "Yellow", Text, bRichText, nTime })
    TipsHelper.PushImportantTips(self.Def.Queue2, { EventType.ShowImportantTip, "Yellow", Text, bRichText, nTime })
end

function TipsHelper.TextTipsCheck(szText)
    if string.is_nil(szText) then
        return false
    end

    -- 在Loading时不弹提示
    if SceneMgr.IsLoading() then
        return false
    end

    do  -- 去重检查，防止服务器在很短的时间里给了同样的重复Tips过来
        if self.tbRecentPopTipsMap == nil then self.tbRecentPopTipsMap = {} end   -- map 用来快速取值
        if self.tbRecentPopTipsList == nil then self.tbRecentPopTipsList = {} end  -- list 用来计算长度

        local bHasInMap = self.tbRecentPopTipsMap[szText] ~= nil

        local nNow = Timer.RealMStimeSinceStartup()
        local nDelta = nNow - (self.tbRecentPopTipsMap[szText] or 0)

        -- 小于200ms，并且有相同tips的就不弹
        if nDelta < 200 then
            return false
        end

        -- 缓存起来
        self.tbRecentPopTipsMap[szText] = nNow

        if not bHasInMap then
            -- 超过10个就移除最早进来的，并且在map里也删掉
            local nLen = #self.tbRecentPopTipsList
            if nLen > 10 then
                local szRemovedText = table.remove(self.tbRecentPopTipsList, 1)
                self.tbRecentPopTipsMap[szRemovedText] = nil
            end

            table.insert(self.tbRecentPopTipsList, szText)
        end
    end

    return true
end

function TipsHelper.PushImportantTips(nQueueIndex, tbImportantEvent)
    local tEvent = self.tCurEventArr[nQueueIndex]
    self.PushEvent(nQueueIndex, tbImportantEvent)
    if tEvent then
        local nEndTime = tEvent.nStartTime + 1
        local nCurTime = Timer.RealtimeSinceStartup()
        if TipsHelper.IsSameImportantTip(tEvent, tbImportantEvent) and TipsHelper.GetEventArrCount(nQueueIndex) == 1 then
            tEvent.bPlayHideAnim = false
            if nEndTime <= nCurTime  then
                TipsHelper.SkipCurrentImportantTips()
                return
            end
            tEvent.nEndTime = nEndTime
        end
    end
end

function TipsHelper.SkipCurrentImportantTips()
    local nQueueIndex = self.Def.Queue2
    local tEvent = self.tCurEventArr[nQueueIndex]
    if tEvent and tEvent[1] == EventType.ShowImportantTip then
        tEvent.nEndTime = Timer.RealtimeSinceStartup()
    end
end

function TipsHelper.ShowPlaceYellowTip(Text)
    self:Init(false)
    TipsHelper.PushEvent(self.Def.Queue2, { EventType.ShowPlaceTip, "3", Text })
end

function TipsHelper.ShowPlaceRedTip(Text)
    self:Init(false)
    TipsHelper.PushEvent(self.Def.Queue2, { EventType.ShowPlaceTip, "2", Text })
end

function TipsHelper.ShowPlaceBlueTip(Text)
    self:Init(false)
    TipsHelper.PushEvent(self.Def.Queue2, { EventType.ShowPlaceTip, "1", Text })
end

function TipsHelper.ShowQuestComplete(nQuestID)
    self:Init(false)
    Event.Dispatch(EventType.ShowQuestComplete, nQuestID)
end

--[[ 播放读条
    tParam = {
        szType = "Normal",              -- 类型: Normal/Skill
        szFormat = "神行(%d/%d)",       -- 格式化显示文本
        nDuration = 1,                  -- 持续时长, 单位为秒
        nStartVal = 0,                  -- 起始值
        nEndVal = 100,                  -- 结束值
        fnStop = function(bCompleted),  -- 停止回调, bCompleted为是否完成读条
    }
--]]
function TipsHelper.PlayProgressBar(tParam)
    assert(tParam)
    assert(type(tParam.szFormat) == "string")
    assert(type(tParam.nDuration) == "number")
    --assert(tParam.szType == "Normal" or tParam.szType == "Skill")

    self:Init(false)
    Event.Dispatch(EventType.PlayProgressBarTip, tParam)
end

function TipsHelper.StopProgressBar()
    Event.Dispatch(EventType.StopProgressBarTip)
end

function TipsHelper.IsProgressBarShow()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelHint)
    return scriptView and scriptView.tDataOfProgressBar ~= nil or false
end

function TipsHelper.GetProgressBarSkillInfo()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelHint)
    return scriptView and scriptView.tDataOfProgressBar
end

-- 升级
function TipsHelper.ShowLevelUpTip(nLevel)
    if self.bCloseLevelUpPanel then return end
    self:Init(false)
    SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.LevelUp)
    TipsHelper.PushEvent(self.Def.Queue2, { EventType.ShowLevelUpTip, nLevel })
    -- Event.Dispatch(EventType.ShowLevelUpTip, nLevel)
end

-- 达成新成就
function TipsHelper.ShowNewAchievement(dwAchievementID)
    local fnShowTips = function()
        if self.bCloseLevelUpPanel then return end

        -- 101级以下不弹提示
        if g_pClientPlayer and g_pClientPlayer.nLevel < 101 then
            return false
        end

        self:Init(false)
        -- TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowNewAchievement, dwAchievementID })
        Event.Dispatch(EventType.ShowNewAchievement, dwAchievementID)
    end

    if not SceneMgr.IsLoading() then
        fnShowTips()
    else
        Event.Reg(self, EventType.UILoadingFinish, function()
            Event.UnReg(self, EventType.UILoadingFinish)

            fnShowTips()
        end)
    end
end

--获得新称号
function TipsHelper.ShowNewDesignation(nID, bPrefix)
    if self.bCloseLevelUpPanel then return end

    self:Init(false)
    Event.Dispatch(EventType.ShowNewDesignation, nID, bPrefix)
end

-- 功能开启
function TipsHelper.ShowNewFeatureTip(nSystemID)
    if self.bCloseLevelUpPanel then return end
    self:Init(false)
    local tMenu = UISystemMenuTab[nSystemID]
    if tMenu.nNewFeatureAniType ~= 0 then
        TipsHelper.PushEvent(self.Def.Queue2, { EventType.ShowNewFeatureTip, nSystemID })
    end

end

-- 攻击、治疗、防御 变化
function TipsHelper.ShowEquipScore(tbData)
    if SceneMgr.IsLoading() then
        return
    end

    if not APIHelper.GetCanShowEquipScore() then
        return
    end

    Timer.DelTimer(self, self.nEquipScoreTimerID)
    self.nEquipScoreTimerID = Timer.AddFrame(self, 2, function()
        APIHelper.SetCanShowEquipScore(false)
    end)

    self:Init(true)
    Event.Dispatch(EventType.ShowEquipScore, tbData)
    --TipsHelper.PushEvent(self.Def.Queue2, {EventType.ShowEquipScore, tbData})
end

--倒计时相关
--PlayCountDown会随时间自动倒数，倒数到0（或直接传0作参数）会显示“开始”文字
function TipsHelper.PlayCountDown(nCountDown, bShowStart)
    if bShowStart == nil then
        bShowStart = true
    end

    self:Init(true)
    Event.Dispatch(EventType.PlayCountDown, nCountDown, bShowStart)
end

--停止倒数
function TipsHelper.StopCountDown()
    self:Init(true)
    Event.Dispatch(EventType.StopCountDown)
end

--UpdateCountDown不会自动倒数，只会更新数字显示和动画，通常由RemoteFunction调用
function TipsHelper.UpdateCountDown(nLeftTime, szPanelName, dwDuration)
    self:Init(true)
    Event.Dispatch(EventType.UpdateCountDown, nLeftTime, szPanelName, dwDuration)
end

function TipsHelper.OutputMessage(szStyle, szMsg, bRichText, nTime)
    if string.is_nil(szStyle) then return end
    if string.is_nil(szMsg) then return end

    -- 暂时根据最后一节的key来判断样式
    szStyle = string.match(szStyle, "_(%a+)$")

    -- 去掉换行符
    szMsg = string.gsub(szMsg, "\n", "")

    if "YELLOW" == szStyle then
        self.ShowImportantYellowTip(szMsg, bRichText, nTime)
    elseif "RED" == szStyle then
        self.ShowImportantRedTip(szMsg, bRichText, nTime)
    elseif "BLUE" == szStyle or "GREEN" == szStyle then
        self.ShowImportantBlueTip(szMsg, bRichText, nTime)
    elseif "SYS" == szStyle then
        self.ShowNormalTip(szMsg, bRichText)
        ChatData.Append(szMsg, 0, PLAYER_TALK_CHANNEL.LOCAL_SYS, false, "")
    else
        self.ShowNormalTip(szMsg, bRichText)
    end
end

-- 快速穿装备
function TipsHelper.ShowQuickEquipTip(tbEquipItem)
    self:Init(false)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowQuickEquipTip, tbEquipItem})
end

-- 获得新表情动作
function TipsHelper.ShowNewEmotionTip(dwActionID)
    self:Init(false)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowNewEmotionTip, dwActionID})
end

-- RemotePanel
function TipsHelper.OnOpenRemotePanel(szName, tData)
    self:Init(false)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.OnOpenRemotePanel, szName, tData})
end

-- SpecailGift
function TipsHelper.OpenSpecailGift(dwID)
    self:Init(false)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.OpenSpecailGift, dwID})
end

-- 公告
-- @param tMsg = {szMsg = "消息文本", szType = "显示类型, 可以不填"} TipsHelper.ShowAnnounceTip({szMsg = "消息文本", szType = "显示类型, 可以不填"})
function TipsHelper.ShowAnnounceTip(tMsg)
    if Global.IsThereKeyOfShielding(tMsg.szMsg) then
        return
    end

    if not APIHelper.IsShowSystemAnnouncement() then
        return
    end

    self:Init(true)
    Event.Dispatch(EventType.ShowAnnounceTip, tMsg)
end

--在点击位置旁边显示悬浮Tips
function TipsHelper.ShowClickHoverTips(nPrefabID, nX, nY, ...)
    self:Init()
    TipsHelper.DeleteHoverTips(nPrefabID)

    local view = UIMgr.GetView(VIEW_ID.PanelHoverTips)
    local scriptView = view and view.scriptView
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelHoverTips)
    end

    local tips, tipsScriptView = scriptView:CreateHoverTips(nPrefabID, ...)
    tips:Show(nX, nY)
    return tips, tipsScriptView
end

--在node旁边显示悬浮Tips，并设置默认方向 nDir: TipsLayoutDir.XXX
function TipsHelper.ShowClickHoverTipsInDir(nPrefabID, nDir,nX, nY,...)
    nDir = nDir or TipsLayoutDir.AUTO

    local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(nPrefabID, nX, nY,...)
    tips:SetDisplayLayoutDir(nDir)
    tips:Update()
    return tips, tipsScriptView
end

--- 在node旁边显示悬浮Tips
--- @return HoverTips, table
function TipsHelper.ShowNodeHoverTips(nPrefabID, node, ...)
    self:Init()
    TipsHelper.DeleteHoverTips(nPrefabID)

    local view = UIMgr.GetView(VIEW_ID.PanelHoverTips)
    local scriptView = view and view.scriptView
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelHoverTips)
    end

    local tips, tipsScriptView = scriptView:CreateHoverTips(nPrefabID, ...)
    tips:ShowNodeTips(node)
    return tips, tipsScriptView
end

--在node旁边显示悬浮Tips，并设置默认方向 nDir: TipsLayoutDir.XXX
---@param nPrefabID number
---@param nDir number TipsLayoutDir.XXX
--- @return HoverTips, table
function TipsHelper.ShowNodeHoverTipsInDir(nPrefabID, node, nDir, ...)
    nDir = nDir or TipsLayoutDir.AUTO

    local tips, tipsScriptView = TipsHelper.ShowNodeHoverTips(nPrefabID, node, ...)
    tips:SetDisplayLayoutDir(nDir)
    tips:Update()
    return tips, tipsScriptView
end

--关闭Tips
function TipsHelper.DeleteHoverTips(nPrefabID)
    local view = UIMgr.GetView(VIEW_ID.PanelHoverTips)
    local scriptView = view and view.scriptView
    if scriptView then
        scriptView:DeleteHoverTips(nPrefabID)
    end
end

-- 是否存在悬浮Tips
function TipsHelper.IsHoverTipsExist(nPrefabID)
    local view = UIMgr.GetView(VIEW_ID.PanelHoverTips)
    local scriptView = view and view.scriptView
    if not scriptView then return false end

    return scriptView:IsHoverTipsExist(nPrefabID)
end

-- 关闭悬浮Tips时不删除仅隐藏，用于避免Tips重复打开加载；
function TipsHelper.KeepHoverTipsAlive(nPrefabID, bKeepAlive)
    if bKeepAlive == nil then
        bKeepAlive = true
    end

    local view = UIMgr.GetView(VIEW_ID.PanelHoverTips)
    local scriptView = view and view.scriptView
    if scriptView then
        scriptView:KeepHoverTipsAlive(nPrefabID, bKeepAlive)
    end
end

-- 关闭所有的悬浮tips
function TipsHelper.DeleteAllHoverTips(bForceDelete)
    local view = UIMgr.GetView(VIEW_ID.PanelHoverTips)
    local scriptView = view and view.scriptView
    if scriptView then
        scriptView:DeleteAllHoverTips(bForceDelete)
    end
end

--- 道具tips
--- @return HoverTips, UIItemTip
function TipsHelper.ShowItemTips(node, nBox, nIndex, bItem, nDir)
    local tips, scriptItemTip = nil, nil
    if nDir then
        tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, node, nDir)
    else
        tips, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, node)
    end

    local tbButton = {}
    local item = bItem and ItemData.GetItemByPos(nBox, nIndex)
    local dwTabType = bItem and item.dwTabType or nBox
    local dwIndex = bItem and item.dwIndex or nIndex
    if dwTabType and dwIndex and OutFitPreviewData.CanPreview(dwTabType, dwIndex) then
        local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(dwTabType, dwIndex)
        if not table.is_empty(tbPreviewBtn) then
            table.insert(tbButton, tbPreviewBtn[1])
        end
    end

    -- 宝箱奖励界面
    TreasureBoxData.GetPreviewBtn(tbButton, dwTabType, dwIndex)

    scriptItemTip:SetFunctionButtons(tbButton)
    if bItem then
        scriptItemTip:OnInit(nBox, nIndex)
    else
        scriptItemTip:OnInitWithTabID(nBox, nIndex)
    end
    return tips, scriptItemTip
end

-- 道具tips
function TipsHelper.ShowItemTipsWithItemID(node, nItemID, nDir)
    local tips, scriptItemTip = nil, nil
    if nDir then
        tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, node, nDir)
    else
        tips, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, node)
    end
    local tbButton = {}
    local item = GetItem(nItemID)
    if item and OutFitPreviewData.CanPreview(item.dwTabType, item.dwIndex) then
        local tbPreviewBtn = OutFitPreviewData.SetPreviewBtn(item.dwTabType, item.dwIndex)
        if not table.is_empty(tbPreviewBtn) then
            table.insert(tbButton, tbPreviewBtn[1])
        end
    end

    -- 宝箱奖励界面
    TreasureBoxData.GetPreviewBtn(tbButton, item.dwTabType, item.dwIndex)

    scriptItemTip:SetFunctionButtons(tbButton)
    scriptItemTip:OnInitWithItemID(nItemID)

    return tips, scriptItemTip
end

function TipsHelper.ShowTextTipsWithRuleID(node, nDir, nRuleID)
    local tbConfig = TabHelper.GetUIRuleTab(nRuleID)
    if not tbConfig then
        return
    end

    local i = 1
	local szDesc = ""
    while tbConfig["nPrefabID"..i] and tbConfig["szDesc"..i] and tbConfig["nPrefabID"..i] > 0 and tbConfig["szDesc"..i] ~= "" do
		if szDesc ~= "" then
			szDesc = szDesc .. "\n"
		end
        szDesc = szDesc .. tbConfig["szDesc"..i]
        i = i + 1
    end

    local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, node, nDir, szDesc)

    return tips, scriptItemTip
end

function TipsHelper.ShowCurrencyTips(node, szName, nCount)
    local tips, scriptItemTip = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, node)
    scriptItemTip:OnInitCurrency(szName, nCount)
    scriptItemTip:SetBtnState({})
    return tips, scriptItemTip
end

function TipsHelper.ShowRewardList(tRewardList, nCanCloseTime)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelNormalConfirmation)
    if not scriptView and not self.bIsOpening then --self.bIsOpening：仅用于检测PanelNormalConfirmation是否正在打开中，防止PanelNormalConfirmation在已经加入打开队列的情况下检测到界面还没打开，再次加入打开队列
        scriptView = UIMgr.Open(VIEW_ID.PanelNormalConfirmation)
    end
    if scriptView then
        scriptView:OnShowRewardListTip(tRewardList, nCanCloseTime)
    else
        --前一个界面还在打开过程中，此时并没有打开Confirm界面(比如浪客行第一关终点处领取食材)
        TipsHelper.PushRewardListEvent({ "ShowRewardListTip", tRewardList, nCanCloseTime })
    end
end

function TipsHelper.ShowServiceConfirmTips(szTips, funcConfirm, funcCancel)
    -- 客服咨询前往弹窗
    funcConfirm = funcConfirm or function()
        ServiceCenterData.OpenServiceWeb()
    end

    local scriptView = UIHelper.ShowConfirm(szTips, funcConfirm, funcCancel, true)
    if scriptView then
        -- scriptView:OnShowServiceTip()   -- 超链接相关
        scriptView:SetConfirmButtonContent("联系客服") -- 方便统一
    end
    return scriptView
end

function TipsHelper.ShowNpcHeadBalloon(characterID, szContent , nChannel)
    if SelfieData.IsInStudioMap() then
        return
    end
    self:Init(false)
    Event.Dispatch(EventType.OnShowNpcHeadBalloon, characterID, szContent , nChannel)
end

function TipsHelper.ShowNpcSpeechSoundsBalloon(dwID)
    self:Init(false)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.OnShowNpcSpeechSoundsBalloon, dwID })
end

function TipsHelper.IsEqualEvent(a, b)
    -- 临时屏蔽
    if a[1] == EventType.ShowNormalTip and string.find(a[2], "你学会了")
        and b[1] == EventType.ShowNormalTip and string.find(b[2], "你学会了") then
        return true
    end

    local n = #a
    if n ~= #b then
        return false
    end

    if a[1] == EventType.ShowBiaoShiTip and b[1] == EventType.ShowBiaoShiTip then
        --return TipsHelper.IsEqualEvent(a[1], b[1])
        return IsTableEqual(a[2], b[2])
    else
        for i = 1, n do
            if a[i] ~= b[i] then
                return false
            end
        end
    end
    return true
end

function TipsHelper.PushEvent(nQueueIndex, tEvent)
    assert(nQueueIndex)
    assert(tEvent)
    local tEventArr = self.tEventQueueArr[nQueueIndex]
    local tCurEvent = self.tCurEventArr[nQueueIndex]

    if tEvent[1] == EventType.ShowInteractTip and tEvent[2].szType == "EmotionActionInviteTip" then
        local _, key = table.find_if(tEventArr, function (v)
            return v[1] == EventType.ShowInteractTip and v[2].szType == "EmotionActionInviteTip"
        end)
        local bInCurEvent = tCurEvent and tCurEvent[1] == EventType.ShowInteractTip and tCurEvent[2].szType == "EmotionActionInviteTip"
        if key or bInCurEvent then
            -- 收到多个交互邀请时会将后来的邀请直接过滤掉
            -- LOG.INFO("成功抛出%s", key and tEventArr[key].szType or tCurEvent[2].szType)
            return
        end
    end

    -- 临时黑名单
    if tEvent[1] == EventType.ShowNormalTip then
        if _fnCheckBlackList(tEvent[2]) or Global.IsThereKeyOfShielding(tEvent[2]) then
            return
        end
    elseif tEvent[1] == EventType.ShowImportantTip then
        if Global.IsThereKeyOfShielding(tEvent[3]) then
            return
        end
    end

    -- 跳过当前
    if tCurEvent and self.IsEqualEvent(tCurEvent, tEvent) then
        return
    end
    -- 跳过队列
    for _, v in ipairs(tEventArr) do
        if self.IsEqualEvent(v, tEvent) then
            return
        end
    end

    TipsHelper.InsertEvent(nQueueIndex, tEvent)
    self.NextTip(nQueueIndex)
end

local event2order = {
    [self.Def.Queue2] ={
        [EventType.ShowLevelUpTip] = 1,
        [EventType.ShowNewFeatureTip] = 2,
        [EventType.ShowImportantTip] = 3,
    },
    [self.Def.Queue3] = {
        [EventType.ShowMobaSurrenderTip] = 0,
        [EventType.ShowTeamReadyConfirmTip] = 0,
        [EventType.ShowTeamTip] = 1,
        [EventType.ShowRoomTip] = 2,
        [EventType.ShowInteractTip] = 3,
        [EventType.ShowTradeTip] = 4,
        [EventType.ShowLikeTip] = 5,
        [EventType.ShowNewAchievement] = 6,
        [EventType.ShowNewDesignation] = 6,
        [EventType.ShowQuickEquipTip] = 6,
        [EventType.OnShowNpcSpeechSoundsBalloon] = 6,
        [EventType.ShowNewEmotionTip] = 6,
        [EventType.ShowBiaoShiTip] = 7,
        [EventType.ShowHuBiaoTip] = 7,
        [EventType.ShowMessageBubble] = 8,
        [EventType.OnOpenRemotePanel] = 8,
        [EventType.OpenSpecailGift] = 8,
        [EventType.ShowAssistNewbieInviteTip] = 8,
        [EventType.ShowOptickRecordTip] = 8,
    },
}

function TipsHelper.InsertEvent(nQueueIndex, tEvent)
    local tEventArr = self.tEventQueueArr[nQueueIndex]
    local tbCurOrder = event2order[nQueueIndex]
    if tbCurOrder ~= nil then
        local szEventName = tEvent[1]
        if tbCurOrder[szEventName] == nil then
            table.insert(tEventArr, tEvent)
        else
            local pos = 1
            local bFound = false
            for i, v in ipairs(tEventArr) do
                if tbCurOrder[v[1]] == nil or tbCurOrder[v[1]] > tbCurOrder[szEventName] then
                    pos = i
                    bFound = true
                    break
                end
            end
            if bFound == true then
                table.insert(tEventArr, pos, tEvent)
            else
                table.insert(tEventArr, tEvent)
            end
        end
    else
        table.insert(tEventArr, tEvent)
    end
end

function TipsHelper.CheckCanSmall(nQueueIndex, szEventName)
    if nQueueIndex ~= self.Def.Queue3 then
        return false
    end
    for _, szName in ipairs(_tSmallEventList) do
        if szName == szEventName then
            return true
        end
    end
    return false
end

function TipsHelper.NextTip(nQueueIndex)
    assert(nQueueIndex)
    local bCanNext, szBeforeEvent = TipsHelper.JudgeCanNext(nQueueIndex)
    if bCanNext == false then
        return
    end

    local tLastEvent = self.tCurEventArr[nQueueIndex]
    if tLastEvent and tLastEvent.bPutBackToQueue then
        table.insert(self.tEventQueueArr[nQueueIndex], tLastEvent)
    end
    
    local szCurEventName = self.tCurEventArr[nQueueIndex] and self.tCurEventArr[nQueueIndex][1] or ""
    local tNextEvent = table.remove(self.tEventQueueArr[nQueueIndex], 1)

    self.tCurEventArr[nQueueIndex] = tNextEvent

    if tNextEvent then
        if nQueueIndex == self.Def.Queue3 then
            if szBeforeEvent then
                table.insert(tNextEvent, szBeforeEvent)
            end
            local bCurTimeNotFixed = (
            tNextEvent[1] == EventType.ShowTeamTip or
            tNextEvent[1] == EventType.ShowAssistNewbieInviteTip or
            tNextEvent[1] == EventType.ShowMobaSurrenderTip or
            tNextEvent[1] == EventType.ShowTeamReadyConfirmTip or
            tNextEvent[1] == EventType.ShowRoomTip or
            tNextEvent[1] == EventType.ShowTradeTip or
            tNextEvent[1] == EventType.OnShowNpcSpeechSoundsBalloon or
            tNextEvent[1] == EventType.ShowOptickRecordTip or
            tNextEvent[1] == EventType.ShowBiaoShiTip)
            if not bCurTimeNotFixed then
                tNextEvent.nEndTime = Timer.RealtimeSinceStartup() + self.Def.MaxLifeTime
            end

            if szCurEventName == EventType.ShowMessageBubble then
                Event.Dispatch(EventType.ShowMessageBubble)
            end
            if tNextEvent[2] and IsTable(tNextEvent[2]) and tNextEvent[2].bFromBubbleIcon then
                tNextEvent[2].bFromBubbleIcon = nil
            end
        else
            tNextEvent.nEndTime = Timer.RealtimeSinceStartup() + self.Def.MaxLifeTime
        end
        tNextEvent.nStartTime = Timer.RealtimeSinceStartup()
        tNextEvent.bHoldOn = _tHoldOnTip[tNextEvent[1]] or false
        if _tIgnoreUnpackTip[tNextEvent[1]] then
            Event.Dispatch(tNextEvent[1], tNextEvent)
        else
            Event.Dispatch(unpack(tNextEvent))
        end
    end
end

function TipsHelper.JudgeCanNext(nQueueIndex)
    if SceneMgr.IsLoading() then
        if self.tbLoadingQueueMap == nil then
            self.tbLoadingQueueMap = {}
        end
        self.tbLoadingQueueMap[nQueueIndex] = true
        return false
    end

    local tCurEvent = self.tCurEventArr[nQueueIndex]
    local bTimeNotPast = tCurEvent and (tCurEvent.nEndTime == nil or tCurEvent.nEndTime > Timer.RealtimeSinceStartup() )

    if nQueueIndex ~= self.Def.Queue3 then
        if not bTimeNotPast then
            return true
        else
            return false
        end
    else
        local bCurIsTeam = tCurEvent ~= nil and tCurEvent[1] == EventType.ShowTeamTip
        local bNextIsTeam = #self.tEventQueueArr[nQueueIndex] > 0 and self.tEventQueueArr[nQueueIndex][1][1] == EventType.ShowTeamTip

        local bCurIsAssist = tCurEvent ~= nil and tCurEvent[1] == EventType.ShowAssistNewbieInviteTip
        local bNextIsAssist = #self.tEventQueueArr[nQueueIndex] > 0 and self.tEventQueueArr[nQueueIndex][1][1] == EventType.ShowAssistNewbieInviteTip

        local bCurIsRoom = tCurEvent ~= nil and tCurEvent[1] == EventType.ShowRoomTip
        local bNextIsRoom = #self.tEventQueueArr[nQueueIndex] > 0 and self.tEventQueueArr[nQueueIndex][1][1] == EventType.ShowRoomTip

        local bCurIsBiaoShi = tCurEvent ~= nil and tCurEvent[1] == EventType.ShowBiaoShiTip
        local bNextIsBiaoShi = #self.tEventQueueArr[nQueueIndex] > 0 and self.tEventQueueArr[nQueueIndex][1][1] == EventType.ShowBiaoShiTip

        local bCurIsMessageBubble = tCurEvent ~= nil and tCurEvent[1] == EventType.ShowMessageBubble
        local bNextIsMessageBubble = #self.tEventQueueArr[nQueueIndex] > 0 and self.tEventQueueArr[nQueueIndex][1][1] == EventType.ShowMessageBubble

        local bFromBubbleIcon = _fnCheckIsFromBubbleIcon(nQueueIndex, self.tEventQueueArr[nQueueIndex][1])

        local nCurType = 10
        local nNextType = 10
        if tCurEvent then
            nCurType = event2order[self.Def.Queue3][tCurEvent[1] ]
        end
        if #self.tEventQueueArr[nQueueIndex] > 0 then
            nNextType = event2order[self.Def.Queue3][self.tEventQueueArr[nQueueIndex][1][1] ]
        end

        local bNextNotInSmall = self.tCurSmallArr[nNextType] == nil

        if (not bNextNotInSmall or bCurIsTeam) and bNextIsTeam then
            return true
        elseif (not bNextNotInSmall or bCurIsAssist) and bNextIsAssist then
            return true
        elseif (not bNextNotInSmall or bCurIsRoom) and bNextIsRoom then
            return true
        elseif (not bNextNotInSmall or bCurIsBiaoShi) and bNextIsBiaoShi then
            return true
        elseif bCurIsMessageBubble and bNextIsMessageBubble then
            return true
        elseif ((not bTimeNotPast) or (nCurType > nNextType)) and bNextNotInSmall then
            if tCurEvent then
                if TipsHelper.CheckCanSmall(nQueueIndex, tCurEvent[1]) then
                    TipsHelper.SetSmallEvent(tCurEvent)
                    return true, tCurEvent[1]
                else
                    TipsHelper.DispatchCloseEvent(tCurEvent[1])
                end
            end
            return true
        elseif bFromBubbleIcon then
            return true
        else
            return false
        end
    end
end

function TipsHelper.ClearSmallEvent(szEventName)
    local name2order = event2order[self.Def.Queue3][szEventName]
    if name2order then
        self.tCurSmallArr[name2order] = nil
    end
end

function TipsHelper.SetSmallEvent(tEvent)
    local name2order = event2order[self.Def.Queue3][tEvent[1]]
    if name2order then
        self.tCurSmallArr[name2order] = tEvent
    end
end

function TipsHelper.GetSmallEvent(szEventName)
    local name2order = event2order[self.Def.Queue3][szEventName]
    if name2order then
        return self.tCurSmallArr[name2order]
    end
end

function TipsHelper.JudgeSmallEventExist(szEventName)
    local name2order = event2order[self.Def.Queue3][szEventName]
    if name2order then
        return self.tCurSmallArr[name2order] ~= nil
    else
        return false
    end
end

function TipsHelper.GetEventOrder(szEventName)
    local name2order = event2order[self.Def.Queue3][szEventName]
    return name2order
end

function TipsHelper.SetCurEvent(nQueueIndex, tEvent)
    assert(nQueueIndex)
    if self.tCurEventArr then
        self.tCurEventArr[nQueueIndex] = tEvent
    end
end

function TipsHelper.GetCurEvent(nQueueIndex)
    assert(nQueueIndex)
    return self.tCurEventArr and self.tCurEventArr[nQueueIndex]
end

function TipsHelper.DispatchCloseEvent(szEventName)
    local tb = {
        [EventType.ShowNewAchievement] = EventType.CloseNewAchievement,
        [EventType.ShowNewDesignation] = EventType.CloseNewDesignation,
        [EventType.ShowQuickEquipTip] = EventType.OnHideNpcSpeechSoundsBalloon,
        [EventType.OnShowNpcSpeechSoundsBalloon] = EventType.OnCloseQuickEquipTip,
        [EventType.ShowMessageBubble] = EventType.CloseTimelyMessageBubble,
    }
    if tb[szEventName] then
        Event.Dispatch(tb[szEventName])
    end
end

function TipsHelper.ClearCurEvent(nQueueIndex)
    assert(nQueueIndex)
    self.tCurEventArr[nQueueIndex] = nil
end

function TipsHelper.GetEventArrCount(nQueueIndex)
    assert(nQueueIndex)
    local tEventArr = self.tEventQueueArr[nQueueIndex]
    return tEventArr and #tEventArr or 0
end

function TipsHelper.GetNextEventTip(nQueueIndex)
    assert(nQueueIndex)
    local tEventArr = self.tEventQueueArr[nQueueIndex]
    if tEventArr and #tEventArr > 0 then
        return tEventArr[1]
    end
    return nil
end

function TipsHelper.IsSameImportantTip(tbEvent1, tbEvent2)
    return tbEvent1[1] == tbEvent2[1] and tbEvent1[2] == tbEvent2[2] and tbEvent1[1] == EventType.ShowImportantTip
end

function TipsHelper.PushRewardListEvent(tbEvent) --在二次确认界面,单独一个逻辑，PushEvent会立即执行一次NextTip，不合适，此队列里的事件应该由ConfirmView的OnEnter触发
    if not self.tbRewardListEvent then
        self.tbRewardListEvent = {}
    end
    table.insert(self.tbRewardListEvent, tbEvent)
    self.bIsOpening = true
end

function TipsHelper.IsRewardListEventEmpty()
    return self.tbRewardListEvent == nil or #self.tbRewardListEvent == 0
end

function TipsHelper.CallRewardListEvent()
    if self.IsRewardListEventEmpty() then return end
    for index, tbEvent in ipairs(self.tbRewardListEvent) do
        Event.Dispatch(unpack(tbEvent))
    end
    self.tbRewardListEvent = {}
    self.bIsOpening = false
end

function TipsHelper.ShowLikeTip(tInfo, nType)
    if not tInfo or not IsTable(tInfo) or #tInfo < 1 then
        return
    end

    self:Init(true)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowLikeTip, tInfo, nType })
end

function TipsHelper.ShowTeamTip()
    self:Init(true)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowTeamTip, {}})
end

function TipsHelper.ShowAssistNewbieInviteTip()
    self:Init(true)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowAssistNewbieInviteTip, {}})
end

function TipsHelper.ShowMobaSurrenderTip()
    self:Init(true)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowMobaSurrenderTip, {}})
end

function TipsHelper.ShowTeamReadyConfirmTip(tbInfo)
    self:Init(true)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowTeamReadyConfirmTip, tbInfo})
end

function TipsHelper.ShowRoomTip()
    self:Init(true)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowRoomTip, {}})
end

function TipsHelper.ShowInteractTip(tbInfo)
    self:Init(true)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowInteractTip, tbInfo })
end

function TipsHelper.ShowTradeTip(tbInfo)
    self:Init(true)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowTradeTip, tbInfo})
end

function TipsHelper.ShowMessageBubble(tbInfo)
    self:Init(true)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowMessageBubble, tbInfo })
end

function TipsHelper.ShowBiaoShiTip(tGuradList)
    self:Init(false)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowBiaoShiTip, tGuradList })
end

function TipsHelper.ShowHuBiaoTip(dwID, szName, nCount, nCurValue, nMaxValue)
    self:Init(false)
    TipsHelper.PushEvent(self.Def.Queue3, { EventType.ShowHuBiaoTip, dwID, szName, nCount, nCurValue, nMaxValue })
end

function TipsHelper.ShowHintSFX(dwID)
    self:Init(false)
    Event.Dispatch(EventType.ShowHintSFX, dwID)
end

function TipsHelper.ShowCampHint(nBossID)
    self:Init(false)
    Event.Dispatch(EventType.ShowCampHint, nBossID)
end


function TipsHelper.ShowRefreshAltar(szAltar, tbNumber, tbTime, bStart)
    self:Init(false)
    Event.Dispatch(EventType.RefreshAltar, szAltar, tbNumber, tbTime, bStart)
end

function TipsHelper.ShowRefreshBoss()
    self:Init(false)
    Event.Dispatch(EventType.RefreshBoss)
end

function TipsHelper.OnStartEvent()
    self:Init(false)
    Event.Dispatch(EventType.OnStartEvent)
end




--只允许某些tip显示
function TipsHelper.OnlyShowTipList(tbEvent)
    for nIndex, szEvent in pairs(SHOW_TIP_EVENT_LIST) do
        if not table.contain_value(tbEvent, szEvent) then
            self.ShieldTip(szEvent, false)
        elseif self.IsTipShield(szEvent) and table.contain_value(tbEvent, szEvent) then
            self.UnShieldTip(szEvent)
        end
    end
end

--显示所有tip
function TipsHelper.ShowAllTip()
    for nIndex, szEvent in pairs(SHOW_TIP_EVENT_LIST) do
        if self.IsTipShield(szEvent) then
            self.UnShieldTip(szEvent)
        end
    end
end


--屏蔽某个tip
--bClose：是否关闭当前屏幕上正在展示的tip,否则只是隐藏
function TipsHelper.ShieldTip(szEvent, bClose)
    if self.IsTipShield(szEvent) then return end
    if bClose == nil then bClose = false end
    local tbData = {
        szEvent = szEvent,
        bClose = bClose,
    }
    if not self.tbShieldTip then self.tbShieldTip = {} end
    self.tbShieldTip[szEvent] = tbData
    --发送事件，通知ui
    Event.Dispatch(EventType.OnShieldTip, szEvent, tbData)
end

--取消屏蔽某个tip
function TipsHelper.UnShieldTip(szEvent)
    if not self.tbShieldTip then return end
    local tbData = self.tbShieldTip[szEvent]
    if not tbData then return end
    local bClose = tbData.bClose
    self.tbShieldTip[szEvent] = nil
    --发送事件，通知ui
    Event.Dispatch(EventType.OnUnShieldTip, szEvent, bClose)
end

function TipsHelper.IsTipShield(szEvent)
    if not self.tbShieldTip then return false end
    return self.tbShieldTip[szEvent] ~= nil
end

function TipsHelper.UpdateAllShieldTip()
    for nIndex, tbData in pairs(self.tbShieldTip) do
        Event.Dispatch(EventType.OnShieldTip, tbData.szEvent, tbData)
    end
end

function TipsHelper.ShowWinterFestivalSkillHint(dwID)
    self:Init(false)
    Event.Dispatch(EventType.ShowWinterFestivalTip, dwID)
end

function TipsHelper.ShowRewardHint(nRewardType, szText, tbItem, tbOtherReward, funcConfirm, funcCancel, szCancel, szConfirm, bShowBtnSure, bShowBtnCancel, tCustomTip)
    self:Init(false)
    Event.Dispatch(EventType.ShowRewardHint, nRewardType, szText, tbItem, tbOtherReward, funcConfirm, funcCancel, szCancel, szConfirm, bShowBtnSure, bShowBtnCancel, tCustomTip)
end

return TipsHelper
