-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAthleticsSell
-- Date: 2023-12-18 16:52:13
-- Desc: ?
-- ---------------------------------------------------------------------------------
local TAGID_TO_NAME = {
    [93] = "UIAtlas2_Collection_CollectionLabel_CollectionLabelMust.png",
    [94] = "UIAtlas2_Collection_CollectionLabel_CollectionLabelBoom.png",
    [95] = "UIAtlas2_Collection_CollectionLabel_CollectionLabelEasy.png",
    [96] = "UIAtlas2_Collection_CollectionLabel_CollectionLabelTime.png",
    [117] = "UIAtlas2_Collection_CollectionLabel_CollectionLabelUp.png",
}

local CARD_ID_TO_RED_POINT_IDS = {
    [22] = {3501,3502,3503}
}

local UIWidgetAthleticsSell = class("UIWidgetAthleticsSell")

function UIWidgetAthleticsSell:OnEnter(tbCardInfo, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbCardInfo = tbCardInfo
    self.nIndex = nIndex

    local bShowSelect = self.bChatSelectedMark or false
    UIHelper.SetVisible(self.ImgSelect, bShowSelect)
    self.bChatSelectedMark = false

    if self.nIndex then
        self:UpdateQuestInfo()
    else
        self.tbReward = CollectionData.GetItemRewardList(self.tbCardInfo)
        self:UpdateInfo()
        self:UpdateReward()
    end
end

function UIWidgetAthleticsSell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAthleticsSell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSecretArea, EventType.OnClick, function()
        CollectionData.OnClickCard(self.tbCardInfo)
    end)

    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function()
        local bVis = UIHelper.GetVisible(self.WidgetShowMore)
        if bVis then
            UIHelper.SetVisible(self.WidgetShowMore, false)
        else
            self:ShowMoreReward()
        end
        Event.Dispatch(EventType.OnShowCollectionMoreReward, self.tbReward, not bVis)
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        local szHelpID = self.tbCardInfo and self.tbCardInfo.szMobileHelpID
        local t = string.split(szHelpID, "|")
        local nType = tonumber(t[1]) --1:Help, 2:Tutorial
        local nID = tonumber(t[2])
        if not nType or not nID then
            return
        end

        if nType == 1 then
            UIMgr.Open(VIEW_ID.PanelHelpPop, nID)
        elseif nType == 2 then
            TeachBoxData.OpenTutorialPanel(nID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        if not self.tbCardInfo then return end

        local szName = UIHelper.GBKToUTF8(self.tbCardInfo.szName)

        local szLinkInfo = nil
        if self.nIndex then
            szLinkInfo = string.format("GameGuideDaily/%d", self.tbCardInfo.dwID)
            szName = "每日江湖·" .. szName
        else
            szLinkInfo = string.format("GameGuide/%d", self.tbCardInfo.dwID)
            szName = "大侠之路·" .. szName
        end

        if szLinkInfo then
            ChatHelper.SendEventLinkToChat(szName, szLinkInfo)
        end
    end)

    UIHelper.BindUIEvent(self.BtnReFresh, EventType.OnClick, function()
        self:PlayReFreshSFX()
        Event.Dispatch("ON_COLLECTION_CARD_FRESH")
        RemoteCallToServer("On_Daily_FreshCourse", self.nIndex)
    end)

    UIHelper.SetTouchEnabled(self.WidgetShowMore, true)

end

function UIWidgetAthleticsSell:RegEvent()
    Event.Reg(self, EventType.OnWindowsSetFocus, function()
        self:DoLayout()
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:DoLayout()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetShowMore, false)
    end)

    Event.Reg(self, EventType.OnShowCollectionMoreReward, function(tbReward, bShow)
        if not self.tbReward or self.tbReward ~= tbReward then
            UIHelper.SetVisible(self.WidgetShowMore, false)
        end
    end)

    Event.Reg(self, "UPDATE_DUNGEON_ROLE_PROGRESS", function()
        self:UpdateDungeonProgress()
    end)

    Event.Reg(self, EventType.OnChatGameGuideSelected, function(dwID)
        if self.tbCardInfo and self.tbCardInfo.dwID == dwID then
            UIHelper.SetVisible(self.ImgSelect, true)
            self.bChatSelectedMark = true
        end
    end)
end

function UIWidgetAthleticsSell:UnRegEvent()
    RedpointMgr.UnRegisterRedpoint(self.ImgRedPoint)
    --Event.UnReg(self, EventType.XXX)
end







-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAthleticsSell:UpdateInfo()

    local tbCardInfo = self.tbCardInfo
    local bFinished, nCurCount, nTolCount = CollectionData.GetFinishState(tbCardInfo)
    local bLock, szLockDesc, szLockTip = CollectionData.IsLocked(tbCardInfo)

    --刷新时间

    --背景
    -- local szImagePath = tbCardInfo.szMobileImagePath
    -- if not string.is_nil(szImagePath) then
    --     UIHelper.SetSpriteFrame(self.ImgLvBg, szImagePath)
    -- end

    --地图
    local szImagePath = tbCardInfo.szImagePath
    if not string.is_nil(szImagePath) then
        local tbPath = string.split(szImagePath, "/")
        szImagePath = string.format("Resource/Collection/%s", tbPath[#tbPath])
        szImagePath = string.gsub(szImagePath, ".tga", ".png")
        UIHelper.SetTexture(self.ImgMap, szImagePath)
    end

    --大战之类的标签
    local szTags = tbCardInfo.szMobileTags
    if not string.is_nil(szTags) then
        -- UIHelper.SetSpriteFrame(self.ImgLvBg, tbCardInfo.szQuality)
        UIHelper.SetSpriteFrame(self.ImgTagTips, szTags)
    end
    UIHelper.SetVisible(self.ImgTagTips, not string.is_nil(szTags))

    --难易度
    local szDifficulty = tbCardInfo.szMobileDifficulty

    --等级锁
    local nPlayerLevel = g_pClientPlayer.nLevel
    UIHelper.SetVisible(self.WidgetLvLock, bLock)
    UIHelper.SetString(self.Label120, szLockDesc)
    --是否完成
    if not tbCardInfo.bDungeonProgress then
        UIHelper.SetVisible(self.ImgComplete, bFinished)
    end

    --时间描述
    UIHelper.SetString(self.LabelTime, UIHelper.GBKToUTF8(tbCardInfo.szTimeDesc))

    --名字
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tbCardInfo.szName))

    --人数
    UIHelper.SetString(self.LabelNum01, tbCardInfo.szPeopleNum)
    UIHelper.LayoutDoLayout(self.LayoutLabelNum)

    -- --排队描述
    -- if not string.is_nil(tbCardInfo.szQueueDesc) then
    --     UIHelper.SetString(self.LabelQueue, UIHelper.GBKToUTF8(tbCardInfo.szQueueDesc))
    --     UIHelper.SetVisible(self.LabelQueue, true)
    -- else
    --     UIHelper.SetVisible(self.LabelQueue, false)
    -- end

    --教程按钮
    UIHelper.SetVisible(self.BtnHelp, not string.is_nil(tbCardInfo.szMobileHelpID))
    UIHelper.SetSwallowTouches(self.BtnHelp, true)

    UIHelper.SetVisible(self.BtnSendToChat, true)
    UIHelper.SetSwallowTouches(self.BtnSendToChat, true)

    --试炼之地下载
    if tbCardInfo.szMobileFunction == "GoToSLZD" and not (nPlayerLevel < tbCardInfo.nLockLevel) then
        --资源下载Widget
        local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
        local tPackIDList = PakDownloadMgr.GetPackIDListInPackTree(PACKTREE_ID.Crossing)
        scriptDownload:OnInitWithPackIDList(tPackIDList)
        UIHelper.SetVisible(self.WidgetDownload, true)
    elseif tbCardInfo.szMobileFunction == "GoToSJYZC" and not (nPlayerLevel < tbCardInfo.nLockLevel) then
        local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
        local nPackID = PakDownloadMgr.GetMapResPackID(BattleFieldData.NEW_PLAYER_BF_MAP_ID) --拭剑园战场
        scriptDownload:OnInitWithPackID(nPackID)
        UIHelper.SetVisible(self.WidgetDownload, true)
    else
        UIHelper.SetVisible(self.WidgetDownload, false)
    end

    -- --预约按钮
    -- local szList          = tbCardInfo.szAppointmentID
    -- local tList           = SplitString(szList, ";")
    -- for _, v in pairs(tList) do
    --     local dwAppointmentID = tonumber(v)
    --     local nState = AppointmentData.GetMapAppointmentStateByID(dwAppointmentID)
    --     if nState ~= MAP_APPOINTMENT_SATE.CANNOT_BOOK then
    --         self.scriptAppointment = self.scriptAppointment or UIHelper.AddPrefab(PREFAB_ID.WidgetPreBookBtn, self.WidgetPreBookBtn)
    --         self.scriptAppointment:OnInitWithAppointmentID(dwAppointmentID)
    --         break
    --     end
    -- end

    local nBtnState = bLock and BTN_STATE.Disable or BTN_STATE.Normal
    local szTip = szLockTip or szLockDesc
    UIHelper.SetButtonState(self.BtnSecretArea, nBtnState, function()
        TipsHelper.ShowNormalTip(szTip)
    end, false)

    UIHelper.SetVisible(self.ImgTagNon, tbCardInfo.nTagFrame ~= 0)
    if tbCardInfo.nTagFrame ~= 0 then
        UIHelper.SetSpriteFrame(self.ImgTagNon, TAGID_TO_NAME[tbCardInfo.nTagFrame])
    end


    --进度
    UIHelper.SetVisible(self.WidgetCountNum, nTolCount ~= 0 and not bFinished)
    UIHelper.SetString(self.LabelCount, tostring(nCurCount).. "/".. tostring(nTolCount))

    UIHelper.SetString(self.LabelCountTitle, UIHelper.GBKToUTF8(tbCardInfo.szMobileDifficulty))

    RedpointMgr.UnRegisterRedpoint(self.ImgRedPoint)
    local tbRedPointID = CARD_ID_TO_RED_POINT_IDS[tbCardInfo.dwID]
    if tbRedPointID and #tbRedPointID > 0 then
        RedpointMgr.RegisterRedpoint(self.ImgRedPoint, nil, tbRedPointID)
    end

    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UIWidgetAthleticsSell:UpdateDungeonProgress()
    local tbCardInfo = self.tbCardInfo
    local nMapID = tbCardInfo.dwMapID
    if tbCardInfo.nClass1 == CLASS_MODE.FB and nMapID and nMapID ~= 0 and tbCardInfo.bDungeonProgress then
        local bFinished = CollectionData.CheckFBProgress(nMapID)
        UIHelper.SetVisible(self.ImgComplete, bFinished)
    end
end

function UIWidgetAthleticsSell:UpdateQuestInfo()


    UIHelper.SetVisible(self.LayoutLabelNum, false)
    UIHelper.SetVisible(self.ImgLvTag, false)
    UIHelper.SetVisible(self.LabelTime, false)

    UIHelper.SetVisible(self.ImgComplete, self.tbCardInfo[2])
    UIHelper.SetVisible(self.BtnReFresh, not self.tbCardInfo[2])
    UIHelper.SetVisible(self.LabelTaskTitle, true)
    UIHelper.SetSwallowTouches(self.BtnReFresh, true)

    UIHelper.SetVisible(self.BtnSendToChat, true)
    UIHelper.SetSwallowTouches(self.BtnSendToChat, true)

    UIHelper.SetTouchEnabled(self.BtnSecretArea, not self.tbCardInfo[2])

    self.tbCardInfo = CollectionDailyData.GetQuestInfoByID(self.tbCardInfo[1])
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(self.tbCardInfo.szTypeName))
    UIHelper.SetString(self.LabelDayTask, UIHelper.GBKToUTF8(self.tbCardInfo.szDesc))

    --背景图
    local szImagePath = self.tbCardInfo.szImagePath
    if not string.is_nil(szImagePath) then
        local tbPath = string.split(szImagePath, "/")
        szImagePath = string.format("Resource/Collection/%s", tbPath[#tbPath])
        szImagePath = string.gsub(szImagePath, ".tga", ".png")
        UIHelper.SetTexture(self.ImgMap, szImagePath)
    end
    UIHelper.SetVisible(self.LabelDayTask, true)
    UIHelper.SetVisible(self.LabelReward, true)
    UIHelper.SetVisible(self.LabelDay, true)
    UIHelper.SetVisible(self.LabelQueue, false)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end


function UIWidgetAthleticsSell:UpdateReward()
    UIHelper.RemoveAllChildren(self.LayoutMoreItem44)
    if not self.tbReward then return end
    --奖励
    local bLock = false
    if not self.nIndex then
        bLock = CollectionData.IsLocked(self.tbCardInfo)
    end

    local nCount = #self.tbReward
    if nCount > 0 and not bLock then
        for nIndex = 1, 4 do
            local tbReward = self.tbReward[nIndex]
            if tbReward then
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.LayoutMoreItem44)
                self:InitItem(script, tbReward)
                self:OnSelectChange(script, tbReward[1], tbReward[2], tbReward[3])
            end
        end
        UIHelper.LayoutDoLayout(self.LayoutMoreItem44)
    end

    UIHelper.SetVisible(self.WidgetRewardIcon, nCount > 0 and not bLock)
    UIHelper.SetVisible(self.BtnMore, nCount > 0 and not bLock)
    UIHelper.SetSwallowTouches(self.BtnMore, true)
    UIHelper.SetTouchDownHideTips(self.BtnMore, false)

    UIHelper.SetSwallowTouches(self.WidgetShowMore, true)
    UIHelper.SetTouchDownHideTips(self.WidgetShowMore, false)
end

function UIWidgetAthleticsSell:DoLayout()
    Timer.DelTimer(self, self.nTimerID)
    self.nLayoutCnt = 0
    self.nTimerID = Timer.AddFrameCycle(self, 1, function()
        UIHelper.LayoutDoLayout(self.LayoutLabelNum)
        self.nLayoutCnt = self.nLayoutCnt + 1
        if self.nLayoutCnt >= 10 then
            Timer.DelTimer(self, self.nTimerID)
        end
    end)
end

function UIWidgetAthleticsSell:ShowMoreReward()
    UIHelper.SetVisible(self.WidgetShowMore, true)
    local nCount = UIHelper.GetChildrenCount(self.LayoutRewardItem44)
    if nCount == 0 then
        for nIndex, tbRewardInfo in ipairs(self.tbReward) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.LayoutRewardItem44)
            self:InitItem(script, tbRewardInfo)
            self:OnSelectChange(script, tbRewardInfo[1], tbRewardInfo[2], tbRewardInfo[3])
        end
        UIHelper.LayoutDoLayout(self.LayoutRewardItem44)
    end
end

function UIWidgetAthleticsSell:InitItem(script, tbRewardInfo)
    local szType      = tbRewardInfo[1]
    local dwTabType   = tonumber(tbRewardInfo[1])
    local dwID        = tonumber(tbRewardInfo[2])
    local nCount      = tonumber(tbRewardInfo[3])
    if szType == "COIN" then
        nCount = nCount or 0
        local tbLine = Table_GetCalenderActivityAwardIconByID(dwID) or {}
        local szName = CurrencyNameToType[tbLine.szName]
        script:OnInitCurrency(szName, nCount * 10000)
        if nCount ~= 0 then
            script:SetLabelCount(nCount)
        else
            script:SetLabelCount()
        end
    else
        script:OnInitWithTabID(dwTabType, dwID, nCount)
    end
    script:SetToggleSwallowTouches(true)
    script:SetTouchDownHideTips(false)
end

function UIWidgetAthleticsSell:OnSelectChange(script, tbRewardInfo1, tbRewardInfo2, tbRewardInfo3)
    local szType      = tbRewardInfo1
    local dwTabType   = tonumber(tbRewardInfo1) or 0
    local dwID        = tonumber(tbRewardInfo2)
    local nCount      = tonumber(tbRewardInfo3)
    script:SetSelectChangeCallback(function(nItemID, bSelected, nTabType, nTabID)
        Event.Dispatch(EventType.OnSelectCollectionAwardChanged, script, bSelected, szType, dwTabType, dwID, nCount)
    end)
end

function UIWidgetAthleticsSell:PlayReFreshSFX()
    UIHelper.SetVisible(self.SFXRefresh, false)
    UIHelper.SetVisible(self.SFXRefresh, true)
end

return UIWidgetAthleticsSell