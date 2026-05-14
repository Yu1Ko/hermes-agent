local UIMonsterBookEntrance = class("UIMonsterBookEntrance")
-----------------------------Constant-------------------------------
local LEVEL_PER_GROUP = 10
local LEVEL_STATE = 
{
    UNABLE = 0,
    ENABLE = 1,
    PASSED = 2,
}
local REWARD_SKILL_LEVEL = 1
local BG_IMAGE_PATH = "ui/Image/UICommon/Baizhan.UITex"
local BG_IMAGE_FRAME = {8, 9, 10, 11, 12, 13, 14, 15, 16, 17}
local BG_IMAGE_LOCK_PATH = "ui/Image/UICommon/Baizhan3.UITex"
local BG_IMAGE_LOCK_FRAME = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
local RULE_TEACH_KEY = "Entrance"

local ROLL_IMAGE_FRAME = {
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice01",
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice02",
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice03",
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice04",
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice05",
    "UIAtlas2_Baizhan_LevelChoose_Img_Dice06",
}
local STEP = 
{
    GOTO         = -1,  -- 定向转移
    START        = 0,   -- 初始化
    GUESS        = 1,   -- 随机跃迁-预测
    GUESS_WAIT   = 1.5, -- 随机跃迁-等待队友预测
    ROLL         = 2,   -- 随机跃迁-掷骰子
    ROLL_END     = 2.5, -- 随机跃迁-掷骰子完毕
    JUMP         = 3,   -- 随机跃迁-走格子
    EFFECT       = 4,   -- 随机跃迁-显示结果
}
local GUESS_TIME_LIMIT = 10
local ROLLING_TIME = 1
local JUMP_RATE = 500
local REVERSE_BUFF_ID = 26257
local REVERSE_BUFF_LEVEL = 1

local function CanChangeBoss(nLevel)
    if nLevel == 90 or nLevel == 100 then
        return true
    end
    return false
end

function UIMonsterBookEntrance:OnEnter(tEntranceInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData(tEntranceInfo)
    self:InitView()
    self:UpdateInfo()
    
    self.nTimerID = self.nTimerID or Timer.AddFrameCycle(self, 15, function ()
        self:OnFrameBreathe()
    end)

    Timer.AddFrame(self, 1, function ()
        self:RedirectToCurRow()
    end)
end

function UIMonsterBookEntrance:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if (self.nStep == STEP.EFFECT or self.bTransmit) and not Storage.MonsterBook.bHasFirstChooseLevel then
        Storage.MonsterBook.bHasFirstChooseLevel = true
        Timer.Add(MonsterBookData, 5, function ()
            if not UIMgr.IsViewOpened(VIEW_ID.PanelBaizhanChooseBuff, true) then
                UIMgr.Open(VIEW_ID.PanelTutorialLite, 59)
            else
                UIMgr.SetCloseCallback(VIEW_ID.PanelBaizhanChooseBuff, function ()
                    UIMgr.Open(VIEW_ID.PanelTutorialLite, 59)
                end)
            end
        end)
    end
end

function UIMonsterBookEntrance:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTutorialLite, 39)
    end)

    UIHelper.BindUIEvent(self.BtnSwitchHelp, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelTutorialLite, 171)
    end)

    UIHelper.BindUIEvent(self.BtnAccurateMove, EventType.OnClick, function ()
        local szMsg = g_tStrings.MONSTER_START_CONFIRM1_FREE
        if not MonsterBookData.IsFreeLevel(self.nLevelSelect) then szMsg = g_tStrings.MONSTER_START_CONFIRM1 end

        UIHelper.ShowConfirm(szMsg, function() self:OnMonsterBookChooseLevelStep(STEP.GOTO) end)
    end)

    UIHelper.BindUIEvent(self.BtnRandomMove, EventType.OnClick, function ()        
        self:OnRandomForwardConfirm()
    end)

    UIHelper.BindUIEvent(self.BtnPredict, EventType.OnClick, function ()
        self:OnPredictConfirm()
    end)

    UIHelper.BindUIEvent(self.BtnReturn, EventType.OnClick, function ()
        self:OnMonsterBookChooseLevelStep(STEP.START)
    end)

    UIHelper.BindUIEvent(self.BtnSwitch, EventType.OnClick, function ()
        self:ShowSwitchBoss()
    end)

    UIHelper.BindUIEvent(self.ScrollViewLevelList, EventType.OnScrollingScrollView, function(_, eventType)
        if eventType == ccui.ScrollviewEventType.containerMoved then
            local nViewID = UIMgr.GetLayerTopViewID(UILayer.Page)
            if nViewID == VIEW_ID.PanelLevelChoose then
                TipsHelper.DeleteAllHoverTips()
            end
        end
    end)

    UIHelper.BindUIEvent(self.ScrollViewSkillList, EventType.OnScrollingScrollView, function(_, eventType)
        if eventType == ccui.ScrollviewEventType.containerMoved then
            local nViewID = UIMgr.GetLayerTopViewID(UILayer.Page)
            if nViewID == VIEW_ID.PanelLevelChoose then
                TipsHelper.DeleteAllHoverTips()
            end
        end
    end)
end

function UIMonsterBookEntrance:RegEvent()
    Event.Reg(self, EventType.OnMonsterBookChooseLevelStep, function (nStep, param1, param2, param3)
        self:OnMonsterBookChooseLevelStep(nStep, param1, param2, param3)
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.AddFrame(self, 1, function ()
            self:RedirectToCurRow()
        end)
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetVisible(self.WidgetAnchorBossFor, false)
    end)
end

function UIMonsterBookEntrance:UnRegEvent()
    Event.UnRegAll(self)
end

-------------------------数据----------------------------------
function UIMonsterBookEntrance:InitData(tInfo)
    self.tInfo            = tInfo or {}
    self.bIsLeader        = tInfo.bIsLeader
    self.nCurrentLevel    = tInfo.nCurrentLevel
    self.nStartLevel      = tInfo.nStartLevel
    self.nEndLevel        = tInfo.nEndLevel
    self.nDiceLimit       = tInfo.nDiceLimit
    self.nDiceRemain      = tInfo.nDiceRemain
    self.nTransLimit      = tInfo.nTransLimit
    self.nTransRemain     = tInfo.nTransRemain
    self.nReplaceLimit    = tInfo.nReplaceLimit or 0
    self.nReplaceRemain   = tInfo.nReplaceRemain or 0

    self.nStep            = 0
    self.nGuessRange      = 0
    self.nGuessLevel      = 0
    self.nGuessTimeStart  = nil
    self.nRollResult1     = nil
    self.nRollResult2     = nil
    self.nRollTimeStart   = nil
    self.nJumpBegin       = nil
    self.nJumpEnd         = nil
    self.nJumpStep        = nil
    self.nJumpSpeed       = nil
    self.nJumpTickCount   = nil
    self.nEffectTickCount = nil
    self.tLevelIndex      = nil
    self.nGroupCount      = 0
    
    self:SetLevelIndexList(tInfo)
    self:SelectLevel(tInfo.nCurrentLevel)
end

function UIMonsterBookEntrance:SelectLevel(nLevel)
    if nLevel and nLevel > self.nStartLevel and nLevel <= self.nEndLevel then
        self.nLevelSelect = nLevel
    else
        self.nLevelSelect = self.nStartLevel
    end
    self:UpdateButtonState()
end

function UIMonsterBookEntrance:IsSelectLevel(nLevel)
    return nLevel and self.nLevelSelect == nLevel
end

function UIMonsterBookEntrance:IsLightLevel(nLevel)
    local nCurLevel = self.nCurrentLevel
    local nGuessRange = self.nGuessRange
    if not nCurLevel or not nGuessRange then
        return false
    else
        local bReverse = nGuessRange < 0
        local nLightMin = 0
        local nLightMax = 0
        if bReverse then
            nLightMin = nCurLevel + nGuessRange
            nLightMax = nCurLevel - 1
        else
            nLightMin = nCurLevel + 1
            nLightMax = nCurLevel + nGuessRange
        end
        return nLevel and nLevel >= nLightMin and nLevel <= nLightMax
    end
end

function UIMonsterBookEntrance:IsLegalLevel(nLevel)
    local tLevelInfo = self.tInfo[nLevel] or {}
    return tLevelInfo.nLevelState == LEVEL_STATE.ENABLE or tLevelInfo.nLevelState == LEVEL_STATE.PASSED
end

function UIMonsterBookEntrance:SetLevelIndexList(tInfo)
    local tLevelIndex = {}
    local nStartRow = math.ceil((self.nStartLevel - 1) / 10)
    local nEndRow = math.ceil(self.nEndLevel / 10)
    for i = nStartRow, nEndRow - 1 do
        local nLeft  = i * LEVEL_PER_GROUP + 1
        local nRight = (i + 1) * LEVEL_PER_GROUP
        if (i+1) % 2 == self.nStartLevel % 2 then
            for nPos = nLeft, nRight do
                if tInfo[nPos] then
                    table.insert(tLevelIndex, nPos)
                end
            end
        else
            for nPos = nRight, nLeft, -1 do
                if tInfo[nPos] then
                    table.insert(tLevelIndex, nPos)
                end
            end
        end
    end
    self.nGroupCount = nEndRow - nStartRow
    self.tLevelIndex = tLevelIndex
end

function UIMonsterBookEntrance:GetLevelIndexList()
    return self.tLevelIndex
end

function UIMonsterBookEntrance:TickCountToSecond(nTickCountBegin, nTickCountEnd)
    return math.floor((nTickCountEnd - nTickCountBegin) / 1000)
end

function UIMonsterBookEntrance:JumpNext()
    if self.nCurrentLevel ~= self.nJumpEnd then
        self.nCurrentLevel = self.nCurrentLevel + self.nJumpStep
        self:UpdateDetail(self.nCurrentLevel)
        self:RedirectToCurRow()
    else
        self.nJumpTickCount  = nil
        if self.tDelayEffectParam then
            UIMgr.Open(VIEW_ID.PanelLevelChooseResultPop, self.tDelayEffectParam)
            self.tDelayEffectParam = nil
        end
    end
end

function UIMonsterBookEntrance:GetEffect(nLevel)
    local tLevelInfo = self.tInfo[nLevel] or {}
    local nEffectID = tLevelInfo.nEffectID or 0
    local tEffectInfo = Table_GetMonsterEffectInfo(nEffectID)
    return nEffectID, tEffectInfo
end

function UIMonsterBookEntrance:GetBossName(nLevel)
    local dwNpcID = self:GetBossID(nLevel)
    local tInfo = Table_GetMonsterBossInfo(dwNpcID) or {}
    local szBossName = tInfo.szName or ""
    if szBossName == "" then
        szBossName = g_tStrings.MONSTER_BOOK_NOBOSS
    end
    szBossName = UIHelper.GBKToUTF8(szBossName)
    return szBossName
end

function UIMonsterBookEntrance:GetGroupIndex(nLevel)
    local nGroup = math.ceil(nLevel / LEVEL_PER_GROUP)
    local nIndex = nLevel % LEVEL_PER_GROUP
    return nGroup, nIndex
end

function UIMonsterBookEntrance:GetGroupRange(nGroup)
    local nMin = (nGroup - 1) * LEVEL_PER_GROUP + 1
    local nMax = nGroup * LEVEL_PER_GROUP
    return nMin, nMax
end

function UIMonsterBookEntrance:GetLevelState(nLevel)
    local nState
    local tLevelInfo = self.tInfo[nLevel]
    if tLevelInfo then
        nState = tLevelInfo.nLevelState
    end
    return nState or LEVEL_STATE.UNABLE
end

function UIMonsterBookEntrance:GetBossID(nLevel)
    local dwNpcID
    local tLevelInfo = self.tInfo[nLevel]
    if tLevelInfo then
        dwNpcID = tLevelInfo.dwBossID
    end
    return dwNpcID or 0
end

function UIMonsterBookEntrance:GetSkillList(nLevel)
    local dwNpcID = self:GetBossID(nLevel)
    local tInfo = Table_GetMonsterBossInfo(dwNpcID)
    return tInfo.tSkill or {}
end

function UIMonsterBookEntrance:IsPlayerHaveReverseBuff()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local bReverse = Buff_Have(pPlayer, REVERSE_BUFF_ID, REVERSE_BUFF_LEVEL)
    return bReverse
end

------------------------表现---------------------------
function UIMonsterBookEntrance:InitView()
    self.tScriptRows = {}
    self.tScriptCells = {}
end

function UIMonsterBookEntrance:UpdateInfo()
    local tLevelIndex = self:GetLevelIndexList()
    if not tLevelIndex then
        return
    end
    local scriptLastRow = nil
    for i = 1, #tLevelIndex do
        local nLevel = tLevelIndex[i]
        local nRowIndex = math.floor((nLevel-1)/10)
        local tLevelInfo = self.tInfo[nLevel] or {}
        local nEffectID, tEffectInfo = self:GetEffect(nLevel)
        local tData = {
            nLevel = nLevel,
            nEffectID = nEffectID,
            tLevelInfo = tLevelInfo,
            tEffectInfo = tEffectInfo,
            szBossName = self:GetBossName(nLevel),
            fCallBack = function ()
                self:SelectLevel(nLevel)
                self:UpdateDetail()
            end
        }
        local scriptRow = self.tScriptRows[nRowIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetLevelListRowCell, self.ScrollViewLevelList)
        local scriptCell = self.tScriptCells[nLevel] or scriptRow:CreateScriptCell(nLevel)
        scriptCell:OnEnter(tData)
        self.tScriptRows[nRowIndex] = scriptRow
        self.tScriptCells[nLevel] = scriptCell
        scriptLastRow = scriptRow
    end
    if scriptLastRow then
        UIHelper.SetVisible(scriptLastRow.LabelRightReturn, scriptLastRow.bOrder2Right)
        UIHelper.SetVisible(scriptLastRow.LabelLeftReturn, not scriptLastRow.bOrder2Right)
    end
    local scriptSelectCell = self.tScriptCells[self.nLevelSelect]
    UIHelper.SetSelected(scriptSelectCell.ToggleSelect, true)
    Event.Dispatch(EventType.OnMonsterBookLevelChange, self.nCurrentLevel)
    if table.GetCount(self.tScriptCells) > 0 then UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLevelList) end

    self:UpdateDetail()
    self:UpdateStatusText()
    self:UpdateButtonState()
end

function UIMonsterBookEntrance:UpdateDetail(nLevelSelect)
    nLevelSelect = nLevelSelect or self.nLevelSelect
    -- 精耐显示
    local colorWhite = cc.c3b(0xFF, 0xFF, 0xFF)
    local colorRed = cc.c3b(0xFF, 0x75, 0x75)
    local colorGold = cc.c3b(0xFF, 0xE2, 0x6E)
    local nStageNumber = math.ceil(nLevelSelect / 10)
    local tSpiritEndurancLimit = GDAPI_SpiritEndurance_GettSpiritEndurancLimit()
    local nSpiritEndurancLimit = tSpiritEndurancLimit[nStageNumber] or tSpiritEndurancLimit[#tSpiritEndurancLimit]
    local tSpiritEndurancSuggestion = GDAPI_SpiritEndurance_GetSESuggestion()
    local nSpiritEndurancSuggestion = tSpiritEndurancSuggestion[nStageNumber] or tSpiritEndurancSuggestion[#tSpiritEndurancSuggestion]
    local nMaxSpiritValue, nMaxEnduranceValue = GDAPI_SpiritEndurance_GetMaxValue(g_pClientPlayer)
    local tLevelInfo = self.tInfo[nLevelSelect] or {}
    if (nSpiritEndurancLimit > 0 and nLevelSelect % 10 == 0) or tLevelInfo.bVariant then
        UIHelper.SetString(self.LabelSERecommend, "精耐需求值")
        UIHelper.SetString(self.LabelRecommendJingShen, tostring(nSpiritEndurancLimit))       
        UIHelper.SetString(self.LabelRecommendNaiLi, tostring(nSpiritEndurancLimit))
        
        UIHelper.SetTextColor(self.LabelSERecommend, colorGold)
        if nMaxSpiritValue >= nSpiritEndurancLimit then
            UIHelper.SetTextColor(self.LabelRecommendJingShen, colorWhite)
        else
            UIHelper.SetTextColor(self.LabelRecommendJingShen, colorRed)
        end
        if nMaxEnduranceValue >= nSpiritEndurancLimit then
            UIHelper.SetTextColor(self.LabelRecommendNaiLi, colorWhite)
        else
            UIHelper.SetTextColor(self.LabelRecommendNaiLi, colorRed)
        end
    else
        UIHelper.SetString(self.LabelSERecommend, "精耐推荐值")        
        UIHelper.SetString(self.LabelRecommendJingShen, tostring(nSpiritEndurancSuggestion))
        UIHelper.SetString(self.LabelRecommendNaiLi, tostring(nSpiritEndurancSuggestion))

        UIHelper.SetTextColor(self.LabelSERecommend, colorWhite)
        if nMaxSpiritValue >= nSpiritEndurancSuggestion then
            UIHelper.SetTextColor(self.LabelRecommendJingShen, colorWhite)
        else
            UIHelper.SetTextColor(self.LabelRecommendJingShen, colorRed)
        end
        if nMaxEnduranceValue >= nSpiritEndurancSuggestion then
            UIHelper.SetTextColor(self.LabelRecommendNaiLi, colorWhite)
        else
            UIHelper.SetTextColor(self.LabelRecommendNaiLi, colorRed)
        end
    end
    -- 顶部当前精耐值上限
    UIHelper.SetString(self.LabelCurJingshenLimit, tostring(nMaxSpiritValue))
    UIHelper.SetString(self.LabelCurNailiLimit, tostring(nMaxEnduranceValue))
    -- Boss信息
    local szLevel = tostring(nLevelSelect)
    local szBossName = self:GetBossName(nLevelSelect)
    local dwNpcID = self:GetBossID(nLevelSelect)
    local szAvatarPath, nAvatarFrame = Table_GetFBCDBossAvatar(dwNpcID)
    szAvatarPath = string.gsub(szAvatarPath, "ui/Image/UITga/", "Resource/DungeonBossHead/")
    szAvatarPath = string.gsub(szAvatarPath, ".UITex", "")
    szAvatarPath = string.format("%s/%02d.png", szAvatarPath, nAvatarFrame)
    local nState = self:GetLevelState(nLevelSelect)
    local bDefeated = nState == LEVEL_STATE.PASSED
    local bCanChange = CanChangeBoss(nLevelSelect)
    UIHelper.SetString(self.LabelLevelNum, szLevel)
    UIHelper.SetString(self.LabelBossName, szBossName)
    UIHelper.SetTexture(self.WidgetHead108, szAvatarPath)
    UIHelper.SetVisible(self.ImgDefeated, bDefeated)
    UIHelper.SetVisible(self.ImgVariantCost, not bDefeated and tLevelInfo.bVariant)
    UIHelper.SetVisible(self.ImgSwitchCost, not bDefeated and bCanChange)
    UIHelper.SetVisible(self.BtnSwitch, bCanChange)
    -- 破绽信息
    local tBossInfo = Table_GetMonsterBossInfo(dwNpcID)
    local szWeakPoint = UIHelper.GBKToUTF8(tBossInfo.szWeakPoint)
    local szWPList = string.split(szWeakPoint, ";")
    
    UIHelper.SetVisible(self.LabelWeakPointEmpty, szWeakPoint == nil or szWeakPoint == "")
    for _, labelColor in ipairs(self.tBossWeakPointBlackLabel) do
        UIHelper.SetVisible(UIHelper.GetParent(labelColor), false)
    end
    for nIndex, szSegment in ipairs(szWPList) do
        if szSegment == "" then break end
        local tSegments = string.split(szSegment, "|")
        local szColor = tSegments[1]
        local labelBlack = self.tBossWeakPointBlackLabel[nIndex]
        local labelWhite = self.tBossWeakPointWhiteLabel[nIndex]
        local labelScale = self.tBossWeakPointScaleLabel[nIndex]
        local bIsBlack = szColor == "黑"
        local colorWeakPoint = ShopData.CNameToColor[szColor] or ShopData.CNameToColor["白"]
        UIHelper.SetString(labelBlack, szColor)
        UIHelper.SetString(labelWhite, szColor)
        UIHelper.SetString(labelScale, string.format("(%s)", tSegments[2]))

        UIHelper.SetTextColor(labelBlack, colorWeakPoint)
        UIHelper.SetTextColor(labelWhite, colorWeakPoint)

        UIHelper.SetVisible(labelScale, false)          -- 策划暂定隐藏
        UIHelper.SetVisible(labelBlack, not bIsBlack)   -- 黑色边框
        UIHelper.SetVisible(labelWhite, bIsBlack)       -- 白色边框
        UIHelper.SetVisible(UIHelper.GetParent(labelBlack), true)
    end
    UIHelper.LayoutDoLayout(self.LayoutWeakPoint)
    -- 奖励信息
    local tSkillList = self:GetSkillList(nLevelSelect)
    UIHelper.RemoveAllChildren(self.LayoutSkillList)
    for _, dwSkillID in pairs(tSkillList) do
        local dwOutSkillID = MonsterBookData.tIn2OutSkillMap[dwSkillID] or dwSkillID
        UIHelper.AddPrefab(PREFAB_ID.WidgetBaiZhanSkillItem, self.ScrollViewSkillList, dwOutSkillID, REWARD_SKILL_LEVEL, function ()
            
        end)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillList)
end

function UIMonsterBookEntrance:UpdateButtonState()
    local bStart = self.nStep == STEP.START and self.bIsLeader
    local bLegal = self:IsLegalLevel(self.nLevelSelect)
    UIHelper.SetVisible(self.WidgetBtnAccurateMove, bStart and bLegal)
    UIHelper.SetVisible(self.WidgetBtnRandomMove, bStart and bLegal)
    UIHelper.SetVisible(self.WidgetBtnPredict, self.nStep == STEP.GOTO or self.nStep == STEP.GUESS)
    UIHelper.SetVisible(self.WidgetBtnReturn, self.nStep == STEP.GOTO)
    UIHelper.SetVisible(self.BtnClose, self.nStep ~= STEP.GUESS)
    UIHelper.SetVisible(self.BtnPredict, self.nStep == STEP.GOTO or self.nStep == STEP.GUESS and self:IsLightLevel(self.nLevelSelect))

    if self.nTransRemain > 0 or MonsterBookData.IsFreeLevel(self.nLevelSelect) then
        UIHelper.SetButtonState(self.BtnAccurateMove, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnAccurateMove, BTN_STATE.Disable, "定向转移次数不足")
    end

    if self.nDiceRemain > 0 then
        UIHelper.SetButtonState(self.BtnRandomMove, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnRandomMove, BTN_STATE.Disable, "随机前进次数不足")
    end

    local szPattern = "<color=#AED9E0>剩余次数：</c><color=#d7f6ff>%d/%d</color>"
    local szPattern2 = "<color=#AED9E0>换将点：</c><color=#d7f6ff>%d/%d</color>"
    local szTrans = string.format(szPattern, self.nTransRemain, self.nTransLimit)
    local szDice = string.format(szPattern, self.nDiceRemain, self.nDiceLimit)
    local szReplace = string.format(szPattern2, self.nReplaceRemain, self.nReplaceLimit)
    UIHelper.SetRichText(self.RichTextAccurateMoveNum, szTrans)
    UIHelper.SetRichText(self.RichTextRandomMoveNum, szDice)
    UIHelper.SetRichText(self.RichTextSwitchNum, szReplace)
    UIHelper.SetVisible(self.WidgetSwitch, self.nStep == STEP.START)
    if self.nStep == STEP.GOTO then
        UIHelper.SetString(self.LabelComfirmContent, "确定转移")
    elseif self.nStep == STEP.GUESS then
        UIHelper.SetString(self.LabelComfirmContent, "确定预测")
    end
    UIHelper.LayoutDoLayout(self.LayoutButtons)
end

function UIMonsterBookEntrance:UpdateTime()
    if self.nGuessTimeStart then
        local nTime = GUESS_TIME_LIMIT - self:TickCountToSecond(self.nGuessTimeStart, GetTickCount())
        if nTime >= 0 then
            UIHelper.SetString(self.LabelCountDown, string.format("预测剩余：%d秒", nTime))
            UIHelper.SetVisible(self.LabelCountDown, true)
        else
            self.nGuessTimeStart = nil
            UIHelper.SetVisible(self.LabelCountDown, false)
        end
        if not self.bRedirect then
            self.bRedirect = true
            self:RedirectToCurRow()
        end
    else
        UIHelper.SetVisible(self.LabelCountDown, false)
    end
end

function UIMonsterBookEntrance:Roll()
    local nStep = self.nStep
    local nRet1 = self.nRollResult1
    local nRet2 = self.nRollResult2
    local bRollDice1 = nStep == STEP.ROLL_END and nRet1
    local bRollDice2 = nStep == STEP.ROLL_END and nRet2
    
    UIHelper.SetVisible(self.WidgetEffDice1, nRet1 and nRet1 > 0)
    UIHelper.SetVisible(self.WidgetEffDice2, nRet2 and nRet2 > 0)
    if nStep ~= STEP.ROLL then
        self:StopRollDiceAni()
        if nRet1 then
            local szDiceImgPath = ROLL_IMAGE_FRAME[nRet1]
            UIHelper.SetSpriteFrame(self.ImgDice1, szDiceImgPath)
        end
        if nRet2 then
            local szDiceImgPath = ROLL_IMAGE_FRAME[nRet2]
            UIHelper.SetSpriteFrame(self.ImgDice2, szDiceImgPath)
        end
        UIHelper.SetVisible(self.Eff_SaiZiDianShu1, false)
        UIHelper.SetVisible(self.Eff_SaiZiDianShu2, false)
        self.nRollTimeStart = nil
    else
        self:PlayRollDiceAni()
    end
    if nStep == STEP.ROLL_END then
        -- TODO：等待特效        
        UIHelper.SetVisible(self.Eff_SaiZiDianShu1, true)
        UIHelper.SetVisible(self.Eff_SaiZiDianShu2, true)
    end

end

function UIMonsterBookEntrance:UpdateEffect(tParam)
    tParam.nEffectID, tParam.tEffectInfo = self:GetEffect(tParam.nRealLevel)
    tParam.szBossName = self:GetBossName(tParam.nRealLevel)
    tParam.nEffectTickCount = self.nEffectTickCount
    self.bFinished = true
    if self.nCurrentLevel == self.nJumpEnd then
        UIMgr.Open(VIEW_ID.PanelLevelChooseResultPop, tParam)
    else
        self.tDelayEffectParam = tParam
    end
end

function UIMonsterBookEntrance:UpdateStatusText()
    local szText = ""
    local nStep = self.nStep
    if nStep == STEP.GOTO then
        szText = g_tStrings.MONSTER_STEP_GOTO
    elseif nStep == STEP.GUESS then
        szText = g_tStrings.MONSTER_STEP_GUESS
    elseif nStep == STEP.GUESS_WAIT then
        szText = g_tStrings.MONSTER_STEP_GUESS_WAIT
    elseif nStep == STEP.ROLL then
        szText = g_tStrings.MONSTER_STEP_ROLL
    elseif nStep == STEP.JUMP then
        szText = FormatString(g_tStrings.MONSTER_STEP_JUMP, self.nJumpEnd)
    end
    
    UIHelper.SetString(self.LabelStatus, szText)
end

function UIMonsterBookEntrance:UpdateJumpState()
    for _, scriptCell in pairs(self.tScriptCells) do
        local tState = {}
        tState.nCurrentLevel = self.nCurrentLevel
        scriptCell:OnUpdateState(tState)
    end 
end

function UIMonsterBookEntrance:UpdateAllCellState()
    if self.bFinished then
        return
    end
    for _, scriptCell in pairs(self.tScriptCells) do
        local tState = {}
        tState.nCurrentLevel = self.nCurrentLevel
        tState.bLightLevel = self:IsLightLevel(scriptCell.tData.nLevel)
        scriptCell:OnUpdateState(tState)
    end 
end

function UIMonsterBookEntrance:OnMonsterBookChooseLevelStep(nStep, param1, param2, param3)
    self.nStep = nStep
    if nStep == STEP.START then
    elseif nStep == STEP.GOTO then
    elseif nStep == STEP.GUESS then
        self.nCurrentLevel = param1
        self.nGuessRange = param2
        self.nGuessTimeStart = GetTickCount()
    elseif nStep == STEP.GUESS_WAIT then        
    elseif nStep == STEP.ROLL then
        self.nGuessTimeStart = nil
        self:UpdateTime()

        self.nRollResult1 = param1
        self.nRollResult2 = param2
        if param3 then
            self.nGuessLevel = param3
        end
        self.nRollTimeStart = GetTickCount()
        self:Roll()
    elseif nStep == STEP.ROLL_END then
        self:Roll()
    elseif nStep == STEP.JUMP then
        self.nJumpBegin = param1
        self.nJumpEnd = param2
        self.nJumpSpeed = param3 or JUMP_RATE
        if self.nJumpBegin < self.nJumpEnd then
            self.nJumpStep = 1
        elseif self.nJumpBegin > self.nJumpEnd then
            self.nJumpStep = -1
        end
        self.nJumpTickCount = GetTickCount()
        self.nCurrentLevel = self.nJumpBegin
        self:UpdateDetail(self.nCurrentLevel)
        self:RedirectToCurRow()
    elseif nStep == STEP.EFFECT then
        self.nEffectTickCount = GetTickCount()
        self:UpdateEffect(param1)
    end

    self:UpdateStatusText()
    self:UpdateButtonState()
    self:UpdateAllCellState()
end

function UIMonsterBookEntrance:OnRandomForwardConfirm()
    local bReverse = self:IsPlayerHaveReverseBuff()
    if self.nCurrentLevel == #self.tLevelIndex and not bReverse then
        local szMsg = string.pure_text(g_tStrings.MONSTER_START_CONFIRM3)
        UIHelper.ShowConfirm(szMsg, function() RemoteCallToServer("On_MonsterBook_Reset") end)
    else
        local szMsg = ""
        if bReverse then
            szMsg = g_tStrings.MONSTER_START_CONFIRM2.. "\n" .. string.pure_text(g_tStrings.MONSTER_START_REVERSE)
        else
            szMsg = g_tStrings.MONSTER_START_CONFIRM2
        end
        UIHelper.ShowConfirm(szMsg, function() RemoteCallToServer("On_MonsterBook_GuessBegin") end)
    end
end

function UIMonsterBookEntrance:OnPredictConfirm()
    local nLevel = self.nLevelSelect
    if self.nStep == STEP.GUESS and self:IsLightLevel(nLevel) then
        self.nGuessLevel = nLevel
        RemoteCallToServer("On_MonsterBook_GuessConfirm", self.nGuessLevel)
        self:OnMonsterBookChooseLevelStep(STEP.GUESS_WAIT)
    elseif self.nStep == STEP.GOTO then
        local nLevel = self.nLevelSelect
        RemoteCallToServer("On_MonsterBook_Transmit", nLevel)
        self.bTransmit = true
        UIMgr.Close(self)
    end
end

function UIMonsterBookEntrance:OnFrameBreathe()
    self:UpdateTime()
    if self.nRollTimeStart then
        if self:TickCountToSecond(self.nRollTimeStart, GetTickCount()) >= ROLLING_TIME then
            self:OnMonsterBookChooseLevelStep(STEP.ROLL_END)
        end
    end

    if self.nJumpTickCount then
        local nTickCount = GetTickCount()
        if nTickCount - self.nJumpTickCount >= self.nJumpSpeed then
            self.nJumpTickCount = nTickCount
            self:JumpNext()
            self:UpdateJumpState()
        end
    end
end

function UIMonsterBookEntrance:PlayRollDiceAni()
    if self.bStopRollDiceAni then
        return
    end
    local nRandVal = math.random(1,6)
    local szDiceImgPath = ROLL_IMAGE_FRAME[nRandVal]
    UIHelper.SetSpriteFrame(self.ImgDice1, szDiceImgPath)
    nRandVal = math.random(1,6)
    szDiceImgPath = ROLL_IMAGE_FRAME[nRandVal]
    UIHelper.SetSpriteFrame(self.ImgDice2, szDiceImgPath)
    Timer.AddFrame(self, 5, function ()
        self:PlayRollDiceAni()
    end)
end

function UIMonsterBookEntrance:StopRollDiceAni()
    self.bStopRollDiceAni = true
end

function UIMonsterBookEntrance:RedirectToCurRow()
    if not UIHelper.GetScrollViewSlide(self.ScrollViewLevelList) then
        return
    end
    if not self.nCurrentLevel or not self.tScriptRows or table.GetCount(self.tScriptRows) == 0 then
        return
    end
    local nRowIndex = math.floor((self.nCurrentLevel-1)/10) - 1

    if nRowIndex >= 0 then
        UIHelper.ScrollToIndex(self.ScrollViewLevelList, nRowIndex)
    else
        UIHelper.ScrollToPercent(self.ScrollViewLevelList, 0)
    end    
    Event.Dispatch(EventType.HideAllHoverTips)
end

function UIMonsterBookEntrance:ShowSwitchBoss()
    local nLevel = self.nLevelSelect
    local nStep  = math.floor((nLevel - 1) / 10) + 1
    local tList  = Table_GetMonsterBoss(0, nStep)
    UIHelper.SetVisible(self.WidgetAnchorBossFor, true)
    UIHelper.RemoveAllChildren(self.LayoutLeaveFor)
    for _, v in pairs(tList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetLeaveForBtn, self.LayoutLeaveFor)
        script.nStep = nStep
        self:InitBossBtn(script, v)
        UIHelper.SetTouchDownHideTips(script.BtnLeaveFor, false)
    end
    UIHelper.LayoutDoLayout(self.LayoutLeaveFor)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActivityDetail)
    UIHelper.SetTouchDownHideTips(self.ScrollViewActivityDetail, false)
end

function UIMonsterBookEntrance:InitBossBtn(script, tInfo)
    local szTitle = string.format("是否确认替换当前首领为%s？", UIHelper.GBKToUTF8(tInfo.szName))
    script:BindClickFunction(function ()
        UIHelper.ShowConfirm(szTitle, function ()
            RemoteCallToServer("On_MonsterBook_ReplaceBoss", script.nStep, tInfo.dwNpcID)
            UIMgr.Close(VIEW_ID.PanelLevelChoose)
        end, function () end)
    end)
    script:SetLabelText(UIHelper.GBKToUTF8(tInfo.szName))
end

return UIMonsterBookEntrance