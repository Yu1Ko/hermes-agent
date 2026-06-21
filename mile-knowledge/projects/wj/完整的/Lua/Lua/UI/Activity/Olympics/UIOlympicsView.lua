-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIOlympicsView
-- Date: 2024-08-07 14:50:22
-- Desc: 乐游纪-尘世曼舞 音游玩法
-- ---------------------------------------------------------------------------------

local UIOlympicsView = class("UIOlympicsView")

local m_tReward =
{
    {fPercentage = 0.05, szRewardLevel = "Miss"},
    {fPercentage = 0.43, szRewardLevel = "Good"},
    {fPercentage = 0.63, szRewardLevel = "Nice"},
    {fPercentage = 0.83, szRewardLevel = "Perfect"},
    {fPercentage = 0.88, szRewardLevel = "Nice"},
    {fPercentage = 0.95, szRewardLevel = "Good"},
    {fPercentage = 1, szRewardLevel = "Miss"},
}

local DataModel = {}

local DELTA_FRAME = 23 -- 一个完整音符的特效，从开始到完美打击需要走多少帧
local SFX_PLAY_DELAY = 100 --缩圈特效需要延迟一些播放，单位是毫秒
local SFX_TOTAL_FRAME = 33 --完整音符特效需要多少帧来播放
local LONG_NODE_COMBO_DEALTA_FRAME = 5 --长按每隔多少帧算一次分
local COMBO_SHOW_TIME = 1500 --连击特效的显示持续多久时间
local DELAY_EXIT_TIME = 5000
local TIME_PER_FRAME = 0.033

local m_tRewardScore =
{
    Miss = {nScore = 0, nAccuracy = 0},
    Good = {nScore = 1000, nAccuracy = 10},
    Nice = {nScore = 1800, nAccuracy = 45},
    Perfect = {nScore = 2250, nAccuracy = 100},
}

local ROLETYPE_ANIMATION =
{
    [ROLE_TYPE.STANDARD_FEMALE] = "dwAdultFemaleAnimationID",
    [ROLE_TYPE.STANDARD_MALE] = "dwAdultMaleAnimationID",
    [ROLE_TYPE.LITTLE_GIRL] = "dwLittleGirlAnimationID",
    [ROLE_TYPE.LITTLE_BOY] = "dwLittleBoyAnimationID",
    [ROLE_TYPE.STRONG_MALE] = "dwStrongMaleAnimationID",
    [ROLE_TYPE.SEXY_FEMALE] = "dwSexyFemaleAnimationID",
}

local m_tEvaluate = {
    1, 0.96, 0.91, 0.81, 0.61, 0.41, 0
}

local m_tFancySkatingInfo = g_tFancySkatingInfo

function DataModel.Init(dwID, dwOtherRoleID)
    DataModel.tNodeData = {}
    DataModel.tNodeQueue = {}
    DataModel.nMaxCombo = 0
    DataModel.dwID = dwID
    DataModel.nNodeIndex = 1
    DataModel.nTotalNode = 0
    DataModel.nAccuracy = 0
    DataModel.nScore = 0
    DataModel.nCombo = 0
    DataModel.tRecord = {
        Miss = 0,
        Nice = 0,
        Good = 0,
        Perfect = 0,
    }
    DataModel.dwOtherRoleID = dwOtherRoleID
    DataModel.LoadNodeData(dwID)
end

function DataModel.UnInit()
    DataModel.ClearQueue()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

function DataModel.LoadNodeData(dwID)
    DataModel.tMusicInfo = Table_GetFancySkatingMusicInfo(dwID)
    DataModel.tMusicInfo.tPressAudio = string.split(DataModel.tMusicInfo.szPressAudio, ";")
    if not DataModel.tMusicInfo.nTotalScore or DataModel.tMusicInfo.nTotalScore == 0 then
        DataModel.tMusicInfo.nTotalScore = 1
    end
    local hPlayer = GetClientPlayer()
    if hPlayer then
        local dwMovieID = DataModel.tMusicInfo[ROLETYPE_ANIMATION[hPlayer.nRoleType]]
        DataModel.dwMovieID = dwMovieID
    end
    DataModel.tFancySkatingInfo = Table_GetFancySkatingInfo(DataModel.tMusicInfo.szTableName, m_tFancySkatingInfo.Path .. DataModel.tMusicInfo.szTableName .. ".txt", m_tFancySkatingInfo.Title)
    DataModel.nCurrentInfoIndex = 1
    DataModel.nNodeInfoTotalIndex = #DataModel.tFancySkatingInfo
end

function DataModel.GetAvailableNode(szNodeType, szPressButton)
    for _, tNode in pairs(DataModel.tNodeData) do
        if tNode.szNodeType == szNodeType and tNode.szPressButton == szPressButton and tNode.bAvaliable then
            return tNode
        end
    end
end

function DataModel.AddNode(szNodeType, szPressButton, hNode)
    local tNode = {
        hNode = hNode,
        szNodeType = szNodeType,
        szPressButton = szPressButton,
        bAvaliable = true,

        nX = 0,
        nY = 0,

        nLongPressCombo = 0,
        nPerfectStartFrame = 0,
        nPerfectEndFrame = 0,
        bShowTip = false,
        bPress = false,
        szRewardLevel = nil,
    }

    table.insert(DataModel.tNodeData, tNode)
    return tNode
end

function DataModel.PushQueue(tNode)
    tNode.nNodeIndex = DataModel.nNodeIndex
    DataModel.tNodeQueue[tNode.nNodeIndex] = tNode
    if tNode.szNodeType == "LongNode" then
        local nLongPressCombo = math.floor((tNode.nPerfectEndFrame - tNode.nPerfectStartFrame - 6) / LONG_NODE_COMBO_DEALTA_FRAME)
        DataModel.nTotalNode = DataModel.nTotalNode + nLongPressCombo
        tNode.nLongPressCombo = nLongPressCombo + 1
    end
    DataModel.nTotalNode = DataModel.nTotalNode + 1
    DataModel.nNodeIndex = DataModel.nNodeIndex + 1
    tNode.bShowTip = false
    tNode.bPress = false
end

function DataModel.PopQueue(nNodeIndex)
    local tNode = DataModel.tNodeQueue[nNodeIndex]
    if not tNode then
        return
    end

    DataModel.tNodeQueue[nNodeIndex] = nil
    if tNode.szNodeType == "LongNode" then
        DataModel.tRecord["Miss"] = DataModel.tRecord["Miss"] + tNode.nLongPressCombo
        tNode.nLongPressCombo = 0
        tNode.bPressLongNoteNow = false
        tNode.fNextComboFrame = nil
    end
    return tNode
end

function DataModel.ClearQueue()
    while table.get_len(DataModel.tNodeQueue) > 0 do
        local nNodeIndex = DataModel.GetQueueFrontIndex()
        local tNode = DataModel.PopQueue(nNodeIndex)
        if tNode then
            tNode.hNode:SetImgBgVisible(false)
            tNode.hNode:HideStartSfx()
            tNode.hNode:HideCenterPerfectSfx()
            tNode.hNode:HideGetScoreSfx()
            tNode.hNode:HidePlaySfx()
            Timer.DelAllTimer(tNode)
            tNode.bAvaliable = true
        end
    end
end

function DataModel.GetQueueFrontIndex(szPressButton)
    local nNodeIndex
    for _, tNode in pairs(DataModel.tNodeQueue) do
        if (not szPressButton or tNode.szPressButton == szPressButton) and (not nNodeIndex or tNode.nNodeIndex < nNodeIndex) then
            nNodeIndex = tNode.nNodeIndex
        end
    end
    return nNodeIndex
end

function DataModel.GetQueueNode(nNodeIndex)
    if not nNodeIndex then
        return
    end

    return DataModel.tNodeQueue[nNodeIndex]
end

function DataModel.UpdateGrade(tNode)
    if tNode.szRewardLevel == "Miss" then
        DataModel.nCombo = 0
        if tNode.szNodeType == "LongNode" then
            return
        end
    else
        DataModel.nCombo = DataModel.nCombo + 1
        if tNode.szNodeType == "LongNode" then
            tNode.nLongPressCombo = tNode.nLongPressCombo - 1
        end
    end
    DataModel.nMaxCombo = math.max(DataModel.nMaxCombo, DataModel.nCombo)
    DataModel.tRecord[tNode.szRewardLevel] = DataModel.tRecord[tNode.szRewardLevel] + 1
    local nFactor = 1
    if DataModel.nCombo > 50 then
        nFactor = 2
    elseif DataModel.nCombo > 30 then
        nFactor = 1.8
    elseif DataModel.nCombo > 10 then
        nFactor = 1.5
    end
    DataModel.nScore = DataModel.nScore + m_tRewardScore[tNode.szRewardLevel].nScore * nFactor
    DataModel.nAccuracy = DataModel.nAccuracy + m_tRewardScore[tNode.szRewardLevel].nAccuracy
end

function UIOlympicsView:OnEnter(dwID, dwOtherRoleID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init(dwID, dwOtherRoleID)
    self:InitUI()

    Event.Dispatch(EventType.OnEnterFancySkating)

    if MapHelper.GetMapID() == 583 then
        LOG.INFO("UIOlympicsView:OnEnter set env preset 1")
        rlcmd("set env preset 1") --开启环境预设
    end
end

function UIOlympicsView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    DataModel.UnInit()
    MovieMgr.SetPlayMovie(true)

    Event.Dispatch(EventType.OnExitFancySkating)

    if MapHelper.GetMapID() == 583 then
        LOG.INFO("UIOlympicsView:OnExit set env preset 0")
        rlcmd("set env preset 0") --关闭环境预设
    end
end

function UIOlympicsView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)

end

function UIOlympicsView:RegEvent()
    Event.Reg(self, "MOVIES_FRAME_NOTIFY", function(dwID, nFrame)
        if not GetClientPlayer() then
            return
        end
        if DataModel.bEnd then
            return
        end
        DataModel.nCurrentFrame = nFrame
        self:CheckNodeQueue("F")
        self:CheckNodeQueue("J")
        self:UpdateNodePerfectTip()
        self:PrepareShowNextNode(DataModel.nCurrentFrame)
        self:UpdateLongNodeProgress()
        if not DataModel.bEnd and DataModel.nCurrentFrame >= DataModel.tMusicInfo.nMusicEndFrame then
            local fAccuracy = DataModel.nAccuracy / (DataModel.nTotalNode)
            if DataModel.nTotalNode == 0 then
                fAccuracy = 0
            end

            for i, v in ipairs(m_tEvaluate) do
                if DataModel.nScore / DataModel.tMusicInfo.nTotalScore >= v then
                    DataModel.nEvaluate = i
                    break
                end
            end
            local tData = {
                nMusicID =  DataModel.dwID,
                nScore = DataModel.nScore,
                fAccuracy =  fAccuracy / 100,
                nGood = DataModel.tRecord.Good,
                nNice = DataModel.tRecord.Nice,
                nPerfect = DataModel.tRecord.Perfect,
                nCombo = DataModel.nMaxCombo,
                nMiss = DataModel.tRecord.Miss,
                nEvaluate = DataModel.nEvaluate
            }
            if DataModel.dwOtherRoleID then
                tData.bSkatingPair = true
            end
            DataModel.bEnd = true
            DataModel.ClearQueue()
            RemoteCallToServer("On_FancySkating_Score", tData)
        end
        self:UpdateTimeLeft()
    end)
    Event.Reg(self, "STOP_MOVIES", function(dwID, bFinishedNormally)
        if dwID then
            self:Close()
        end
    end)
    Event.Reg(self, "PLAY_MOVIES", function(dwID)
        if DataModel.dwOtherRoleID then
            --延迟1帧，保证顺序
            Timer.AddFrame(self, 1, function()
                MovieMgr.SetPlayMovie(true)
                RemoteCallToServer("On_FancySkating_Ready")
            end)
        end
    end)

    Event.Reg(self, EventType.FancySkating_StartSkaingPair, function()
        Event.Dispatch(EventType.OnStartPlayMovie, DataModel.dwMovieID)
    end)
    Event.Reg(self, EventType.FancySkating_CloseSkatingPair, function()
        self:Close()
    end)
    Event.Reg(self, EventType.FancySkating_PairsCancel, function(szName)
        TipsHelper.ShowImportantYellowTip(FormatString(g_tStrings.STR_SKATING_PAIRS_EXIT, UIHelper.GBKToUTF8(szName)))
        DataModel.dwOtherRoleID = nil
        Timer.Add(self, DELAY_EXIT_TIME / 1000, function()
            self:Close()
        end)
    end)
    Event.Reg(self, EventType.On_FancySkating_Record, function(tPersonalRecord, tRankList, tItem, tOtherData)
        -- print_table("tPersonalRecord", tPersonalRecord)
        -- print_table("tRankList", tRankList)
        -- print_table("tItem", tItem)
        -- print_table("tOtherData", tOtherData)
        self:OpenSettlement(tPersonalRecord, tRankList, tItem, tOtherData)
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        if szKeyName == "F" or szKeyName == "J" then
            local nNodeIndex = DataModel.GetQueueFrontIndex(szKeyName)
            self:OnButtonDown(nNodeIndex)
            UIHelper.SetVisible(self["Img" .. szKeyName .. "2"], true) --self.ImgF2和self.ImgJ2
        end
    end)
    Event.Reg(self, EventType.OnKeyboardUp, function(nKeyCode, szKeyName)
        if szKeyName == "F" or szKeyName == "J" then
            local nNodeIndex = DataModel.GetQueueFrontIndex(szKeyName)
            self:OnButtonUp(nNodeIndex)
            UIHelper.SetVisible(self["Img" .. szKeyName .. "2"], false) --self.ImgF2和self.ImgJ2
        end
    end)
    Event.Reg(self, EventType.FancySkating_OnButtonDown, function(szPressButton, nNodeIndex)
        self:OnButtonDown(nNodeIndex)
    end)
    Event.Reg(self, EventType.FancySkating_OnButtonUp, function(szPressButton, nNodeIndex)
        self:OnButtonUp(nNodeIndex)
    end)
    Event.Reg(self, "OnGamepadKeyDown", function(nKey)
        if nKey == GamepadKeyCode.KEY_L_SHOULDER then
            local nNodeIndex = DataModel.GetQueueFrontIndex("F")
            self:OnButtonDown(nNodeIndex)
        elseif nKey == GamepadKeyCode.KEY_R_SHOULDER then
            local nNodeIndex = DataModel.GetQueueFrontIndex("J")
            self:OnButtonDown(nNodeIndex)
        end
    end)
    Event.Reg(self, "OnGamepadKeyUp", function(nKey)
        if nKey == GamepadKeyCode.KEY_L_SHOULDER then
            local nNodeIndex = DataModel.GetQueueFrontIndex("F")
            self:OnButtonUp(nNodeIndex)
        elseif nKey == GamepadKeyCode.KEY_R_SHOULDER then
            local nNodeIndex = DataModel.GetQueueFrontIndex("J")
            self:OnButtonUp(nNodeIndex)
        end
    end)
    Event.Reg(self, EventType.OnGamepadTypeChanged, function()
        self:UpdateButtonTip()
    end)
    Event.Reg(self, "OnMobileKeyboardConnected", function()
        self:UpdateButtonTip()
    end)
    Event.Reg(self, "OnMobileKeyboardDisConnected", function()
        self:UpdateButtonTip()
    end)
end

function UIOlympicsView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIOlympicsView:InitUI()
    self.scriptSettlement = self.scriptSettlement or UIHelper.GetBindScript(self.WidgetAnchorRight)
    self.scriptSettlement:OnInit(self, DataModel)

    LOG.INFO("UIOlympicsView.PlayProtocolMovie: %s", tostring(DataModel.dwMovieID))


    if DataModel.dwOtherRoleID then
        MovieMgr.SetPlayMovie(false)
    end
    MovieMgr.PlayProtocolMovie(DataModel.dwMovieID, true, DataModel.dwOtherRoleID)

    UIHelper.RemoveAllChildren(self.WidgetMusic)

    UIHelper.SetString(self.LabelMusic, UIHelper.GBKToUTF8(DataModel.tMusicInfo.szMusicName))
    UIHelper.SetString(self.LabelScoreNum, "0")
    UIHelper.SetString(self.LabelAccuracyNum, "0.00%")
    UIHelper.SetVisible(self.WidgetCombo, false)
    UIHelper.SetVisible(self.Eff_Continuous, false)
    UIHelper.SetVisible(self.SFXNewHistory, false)

    self:UpdateButtonTip()
    self:PreCreateNode()
end

function UIOlympicsView:UpdateButtonTip()
    if GamepadData.IsGamepadMode() then
        local nGamepadType = GamepadData.GetGamepadType()

        local szIconL = GamepadData.GetGamepadRichTextIcon("L_SHOULDER", 50)
        local szIconR = GamepadData.GetGamepadRichTextIcon("R_SHOULDER", 50)
        UIHelper.SetRichText(self.LabelName1, string.format("单击%s", szIconL))
        UIHelper.SetRichText(self.LabelName2, string.format("长按%s", szIconL))
        UIHelper.SetRichText(self.LabelName3, string.format("单击%s", szIconR))
        UIHelper.SetRichText(self.LabelName4, string.format("长按%s", szIconR))

        UIHelper.SetVisible(self.WidgetPCTip, false)
        UIHelper.SetVisible(self.WidgetLeftBottom_JoyStick, true)
        UIHelper.SetVisible(self.WidgetLeftBottom_PC, false)
        UIHelper.SetVisible(self.WidgetLeftBottom, false)

        return
    end

    local bKeyboard = (Platform.IsWindows() or Platform.IsMac()) and not Channel.Is_WLColud() or KeyBoard.MobileHasKeyboard()
    UIHelper.SetVisible(self.WidgetPCTip, bKeyboard)
    UIHelper.SetVisible(self.WidgetLeftBottom_JoyStick, false)
    UIHelper.SetVisible(self.WidgetLeftBottom_PC, bKeyboard)
    UIHelper.SetVisible(self.WidgetLeftBottom, not bKeyboard)
end

function UIOlympicsView:UpdateTimeLeft()
    local nLeftFrame = math.max(DataModel.tMusicInfo.nMusicEndFrame - DataModel.nCurrentFrame, 0)
    local nMin = math.floor(nLeftFrame * TIME_PER_FRAME / 60)
    local nSec =  math.floor(nLeftFrame * TIME_PER_FRAME % 60)
    local szMinPre = ""
    local szSecPre = ""
    if nMin < 10 then
        szMinPre = "0"
    end
    if nSec < 10 then
        szSecPre = "0"
    end
    UIHelper.SetString(self.LabelTime, szMinPre .. nMin .. ":" .. szSecPre .. nSec)
end

function UIOlympicsView:UpdateGrade(tNode)
    local nLastCombo = DataModel.nCombo
    DataModel.UpdateGrade(tNode)

    Timer.DelTimer(self, self.nComboTimerID)
    UIHelper.SetVisible(self.WidgetCombo, DataModel.nCombo >= 3)
    UIHelper.SetVisible(self.Eff_Continuous, DataModel.nCombo >= 3)
    UIHelper.SetString(self.LabelCombo, "x" .. DataModel.nCombo)

    if DataModel.nCombo >= 3 then
        UIHelper.PlayAni(self, self.AniAll, "AniTopDouble")
    end

    self.nComboTimerID = Timer.Add(self, COMBO_SHOW_TIME / 1000, function()
        UIHelper.SetVisible(self.WidgetCombo, false)
        UIHelper.SetVisible(self.Eff_Continuous, false)
    end)

    UIHelper.SetString(self.LabelScoreNum, DataModel.nScore)
    UIHelper.SetString(self.LabelAccuracyNum, string.format("%.2f%%", (DataModel.nAccuracy / (DataModel.nTotalNode))))
end

function UIOlympicsView:CheckNodeQueue(szPressButton)
    local nNodeIndex = DataModel.GetQueueFrontIndex(szPressButton)
    local tNode = DataModel.GetQueueNode(nNodeIndex)
    if tNode and not tNode.bPressLongNoteNow and DataModel.nCurrentFrame - tNode.nPerfectStartFrame > SFX_TOTAL_FRAME - DELTA_FRAME then
        if not tNode.bPress then
            tNode.szRewardLevel = "Miss"
            local nRandomIndex = math.random(1, 6)
            SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.SKATING_PRESS_MISS .. nRandomIndex .. ".wav")
            tNode.hNode:SetImgBgVisible(false)
            tNode.hNode:HidePlaySfx()
            tNode.hNode:ShowAppraiseSfx(tNode.szRewardLevel)
            self:UpdateGrade(tNode)
        end
        self:PopQueue(nNodeIndex)
    end
end

function UIOlympicsView:PopQueue(nNodeIndex)
    local tNode = DataModel.PopQueue(nNodeIndex)
    if tNode then
        tNode.hNode:SetImgBgVisible(false)
        tNode.hNode:HideStartSfx()
        tNode.hNode:HideCenterPerfectSfx()
        tNode.hNode:HideGetScoreSfx()
        tNode.hNode:HidePlaySfx()
        Timer.DelTimer(tNode, tNode.nStartTimerID)
        Timer.Add(tNode, 1100 / 1000, function()
            if tNode.hNode and tNode.hNode.bInit then
                tNode.hNode:SetVisible(false)
            end
            tNode.bAvaliable = true
        end)
    end
end

function UIOlympicsView:PreCreateNode()
    if #DataModel.tNodeData > 0 then
        return
    end

    local nNodeSize = 6
    local nLongNodeSize = 3
    for i = 1, nNodeSize do
        self:NewNode("Node", "F")
        self:NewNode("Node", "J")
    end
    for i = 1, nLongNodeSize do
        self:NewNode("LongNode", "F")
        self:NewNode("LongNode", "J")
    end
    for _, tNode in pairs(DataModel.tNodeData) do
        tNode.hNode:SetVisible(false)
    end
end

function UIOlympicsView:NewNode(szNodeType, szPressButton)
    local hNode = UIHelper.AddPrefab(PREFAB_ID.WidgetOlympicsCell, self.WidgetMusic)
    local tNode = DataModel.AddNode(szNodeType, szPressButton, hNode)
    return tNode
end

function UIOlympicsView:ShowNode(szNodeType, szPressButton, nX, nY, nPerfectStartFrame, nPerfectEndFrame, nCurrentFrame)
    local tNode = DataModel.GetAvailableNode(szNodeType, szPressButton)
    if not tNode then
        tNode = self:NewNode(szNodeType, szPressButton)
    end

    tNode.bAvaliable = false
    tNode.nX = nX
    tNode.nY = nY
    tNode.nPerfectStartFrame = math.floor(nPerfectStartFrame + 0.5)
    tNode.nPerfectEndFrame = math.floor(nPerfectEndFrame + 0.5)

    DataModel.PushQueue(tNode)

    Timer.DelAllTimer(tNode)
    tNode.hNode:OnInit(szNodeType, szPressButton, tNode.nNodeIndex, nX, nY)

    if szNodeType == "LongNode" then
        tNode.hNode:SetProgressVisible(true)
        tNode.hNode:SetProgress(1)
        tNode.hNode:HideStartSfx()
        tNode.hNode:HideCenterPerfectSfx()
        tNode.hNode:HideGetScoreSfx()
        tNode.hNode:HidePlaySfx()
    end

    tNode.hNode:SetVisible(true)
    tNode.hNode:SetClickVisible(false)
    tNode.hNode:SetImgBgVisible(true)

    local nGap = DELTA_FRAME / 6
    local nIndex = 6 - math.floor((nPerfectStartFrame - nCurrentFrame) / nGap)
    Timer.DelTimer(tNode, tNode.nStartTimerID)
    tNode.nStartTimerID = Timer.Add(tNode, SFX_PLAY_DELAY / 1000, function()
        if tNode.hNode and tNode.hNode.bInit then
            tNode.hNode:ShowStartSfx(nIndex)
        end
    end)
end

function UIOlympicsView:PrepareShowNextNode(nCurrentFrame)
    if DataModel.nCurrentInfoIndex > DataModel.nNodeInfoTotalIndex then
        return
    end
    local tInfo = DataModel.tFancySkatingInfo[DataModel.nCurrentInfoIndex]
    if tInfo.nStartFrame - nCurrentFrame > DELTA_FRAME then
        return
    end
    if nCurrentFrame <= tInfo.nStartFrame then
        local tScreenSize = UIHelper.GetCurResolutionSize()
        local nW, nH = tScreenSize.width, tScreenSize.height
        self:ShowNode(tInfo.szNodeType, tInfo.szPressButtom, tInfo.fPercentX * nW, (1 - tInfo.fPercentY) * nH, tInfo.nStartFrame, tInfo.nEndFrame, nCurrentFrame)
    end
    DataModel.nCurrentInfoIndex = DataModel.nCurrentInfoIndex + 1
end

function UIOlympicsView:PressButtonResult(nNodeIndex)
    local bSoundPlayed = false
    local nRandomIndex = math.random(1, 6)
    local tNode = DataModel.GetQueueNode(nNodeIndex)
    if not tNode then
        return
    end

    local nStartFrame = tNode.nPerfectStartFrame - DELTA_FRAME
    local nFrame = DataModel.nCurrentFrame - nStartFrame
    if nFrame < 0 or nFrame >= SFX_TOTAL_FRAME then
        return
    end
    tNode.bPress = true
    for i, v in ipairs(m_tReward) do
        if nFrame < SFX_TOTAL_FRAME * v.fPercentage then
            tNode.hNode:ShowAppraiseSfx(v.szRewardLevel)
            tNode.szRewardLevel = v.szRewardLevel
            if tNode.szRewardLevel == "Miss" then
                SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.SKATING_PRESS_MISS .. nRandomIndex .. ".wav")
                bSoundPlayed = true
                tNode.hNode:HideStartSfx()
                Timer.DelTimer(tNode, tNode.nStartTimerID)
            end
            tNode.hNode:SetClickVisible(true)
            if tNode.szNodeType == "LongNode" then
                if not tNode.bPressLongNoteNow and not bSoundPlayed then
                    SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.SKATING_PRESS_LONG .. nRandomIndex .. ".wav")
                end
                tNode.bPressLongNoteNow = true
                tNode.fNextComboFrame = tNode.nPerfectStartFrame + 11
                tNode.nStartPressFrame = DataModel.nCurrentFrame
                tNode.hNode:ShowPlaySfx(v.szRewardLevel == "Perfect")
                if v.szRewardLevel == "Miss" then
                    self:PopQueue(nNodeIndex)
                end
            else
                if not bSoundPlayed then
                    local nIndex = math.random(1, #DataModel.tMusicInfo.tPressAudio)
                    SoundMgr.PlaySound(SOUND.UI_SOUND, g_sound.SKATING_PRESS .. DataModel.tMusicInfo.tPressAudio[nIndex] .. ".wav")
                end
                tNode.hNode:SetImgBgVisible(false)
                tNode.hNode:HidePlaySfx()
                self:PopQueue(nNodeIndex)
            end
            break
        end
    end
    self:UpdateGrade(tNode)
end

function UIOlympicsView:UpdateLongNodeProgress()
    for nNodeIndex, tNode in pairs(DataModel.tNodeQueue) do
        if tNode.bPressLongNoteNow and tNode.nStartPressFrame then
            local fPercentage = 1 - (DataModel.nCurrentFrame - tNode.nStartPressFrame) / (tNode.nPerfectEndFrame - tNode.nStartPressFrame)
            tNode.hNode:SetProgress(fPercentage)
            if fPercentage < 0 then
                tNode.hNode:SetProgressVisible(false)
                tNode.hNode:SetImgBgVisible(false)
                tNode.hNode:HidePlaySfx()
                self:PopQueue(nNodeIndex)
            elseif tNode.fNextComboFrame and DataModel.nCurrentFrame >= tNode.fNextComboFrame then
                self:UpdateGrade(tNode)
                tNode.hNode:ShowGetScoreSfx(tNode.szRewardLevel)
                tNode.fNextComboFrame = tNode.fNextComboFrame + LONG_NODE_COMBO_DEALTA_FRAME
            end
        end
    end
end

function UIOlympicsView:UpdateNodePerfectTip()
    for nNodexIndex, tNode in pairs(DataModel.tNodeQueue) do
        if not tNode.bShowTip and DataModel.nCurrentFrame >= (tNode.nPerfectStartFrame - 5) then
            tNode.bShowTip = true
            tNode.hNode:ShowCenterPerfectSfx(false)
            Timer.Add(tNode, 1100 * 0.2 / 1000, function()
                if tNode.hNode and tNode.hNode.bInit then
                    tNode.hNode:HideCenterPerfectSfx(false)
                end
            end)
        end
    end
end

function UIOlympicsView:OnButtonDown(nNodeIndex)
    local tNode = DataModel.GetQueueNode(nNodeIndex)
    if tNode and not tNode.bPress and not tNode.bPressLongNoteNow then
        tNode.bPress = true
        self:PressButtonResult(nNodeIndex)
    end
end

function UIOlympicsView:OnButtonUp(nNodeIndex)
    local tNode = DataModel.GetQueueNode(nNodeIndex)
    if tNode and tNode.bPress then
        tNode.bPress = false
        if tNode.szNodeType == "LongNode" then
            tNode.szRewardLevel = "Miss"
            tNode.hNode:ShowAppraiseSfx(tNode.szRewardLevel)
            tNode.hNode:SetImgBgVisible(false)
            tNode.hNode:HidePlaySfx()
            if DataModel.nCurrentFrame < tNode.nPerfectEndFrame - (tNode.nPerfectEndFrame - tNode.nPerfectStartFrame) % LONG_NODE_COMBO_DEALTA_FRAME then
                self:UpdateGrade(tNode)
            end
            tNode.hNode:SetProgress(0)
            self:PopQueue(nNodeIndex)
        end
    end
end

function UIOlympicsView:OpenSettlement(tPersonalRecord, tRankList, tItem, tOtherData)
    local function _openSettlement()
        UIHelper.SetVisible(self.WidgetAnchorRight, true)
        if tOtherData then
            self.scriptSettlement:UpdateSettlementPair(tPersonalRecord, tItem, tOtherData)
        else
            self.scriptSettlement:UpdateSettlement(tPersonalRecord, tRankList, tItem)
        end
    end

    Timer.DelTimer(self, self.nSettlementTimerID)

    local nDelayTime = 0
    if DataModel.nScore >= DataModel.tMusicInfo.nTotalScore then
        UIHelper.SetVisible(self.SFXNewHistory, true)
        UIHelper.PlaySFX(self.SFXNewHistory)
        self.nSettlementTimerID = Timer.Add(self, 4000 / 1000, function()
            UIHelper.SetVisible(self.SFXNewHistory, false)
            _openSettlement()
        end)
    else
        _openSettlement()
    end
end

function UIOlympicsView:Close()
    if DataModel.dwOtherRoleID and not DataModel.bEnd then
        RemoteCallToServer("On_FancySkating_PairsCancel")
    end
    MovieMgr.StopVideo()
    MovieMgr.StopStory()
    UIMgr.Close(self)
end


return UIOlympicsView