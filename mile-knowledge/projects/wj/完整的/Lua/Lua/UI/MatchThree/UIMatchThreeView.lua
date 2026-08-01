-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMatchThreeView
-- Date: 2025-12-22 18:02:13
-- Desc: ?
-- ---------------------------------------------------------------------------------
--UIMgr.Open(VIEW_ID.PanelMatch_3)
local UIMatchThreeView = class("UIMatchThreeView")

local tbCellImgList = {
    gold = "UIAtlas2_Activity_Match_3_Match_3_Icon_Yuanbao",
    purple = "UIAtlas2_Activity_Match_3_Match_3_Icon_Huaban",
    blue = "UIAtlas2_Activity_Match_3_Match_3_Icon_Tangyuan",
    red = "UIAtlas2_Activity_Match_3_Match_3_Icon_Denglong"
}

local BOARD_SIZE   = 6

local tbNames = {
    {szColor = "gold", szHero = "康宴别", szSkillName = "大狮子吼" },
    {szColor = "blue", szHero = "月嘉禾", szSkillName = "月朔观气" },
    {szColor = "red", szHero = "白鹊",   szSkillName = "长击·穿云" },
    {szColor = "purple", szHero = "姜棠",   szSkillName = "决芳剑" },
}

local nRewardScore = 30000

local tbNumImgList = {
    [1] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_1",
    [2] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_2",
    [3] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_3",
    [4] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_4",
    [5] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_5",
    [6] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_6",
    [7] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_7",
    [8] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_8",
    [9] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_9",
    [10] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Cheng_0",
}

local tbGreenNumImgList = {
    [1] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Lv_1",
    [2] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Lv_2",
    [3] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Lv_3",
    [4] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Lv_4",
    [5] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Lv_5",
    [6] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Lv_6",
    [7] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Lv_7",
    [8] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Lv_8",
    [9] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Lv_9",
    [10] = "UIAtlas2_Activity_Match_3_Number_Shuzi_Lv_0",
}

function UIMatchThreeView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    MatchThreeData.Apply()
    self.nScore = MatchThreeData.GetScore()
    self.tbRewardScript = nil
    self:UpdateLeftSkill()
    
    if MatchThreeData.IsShowGameStartHint() and IsActivityOn(224) then
        Timer.AddFrame(self, 2, function ()
            local tbScript = UIMgr.Open(VIEW_ID.PanelMatch_3Pop, true)
            tbScript:UpdateStartInfo()
            MatchThreeData.HideGameStartHint()
        end)
    else
        self:Init()
        self:UpdateViewInfo()
    end

    SoundMgr.PlayBgMusic("BGM_State_XiaKeXiaoXiaoLe")
    local bMute = MatchThreeData.GetBgmState()
    UIHelper.SetSelected(self.TogVoice, not bMute)
    RemoteCallToServer("On_Activity_PanelState", true)
end

function UIMatchThreeView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    MatchThreeData.OnClose()
    Timer.DelAllTimer(self)
    SoundMgr.PlayBackBgMusic()
    RemoteCallToServer("On_Activity_PanelState", false)
end

function UIMatchThreeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        local nCurScore = MatchThreeData.GetScore()
        local nMaxScore = MatchThreeData.GetHistoryScore()
        local szContent = string.format("是否提交分数并退出游戏？\n本局分数：%d <img src='UIAtlas2_HomeIdentify_HomeFish_Img_Tab_New' width='46' height='38'/>\n历史最高：%d", nCurScore, nMaxScore)
        if nCurScore <= nMaxScore then
            szContent = string.format("是否提交分数并退出游戏？\n本局分数：%d\n历史最高：%d", nCurScore, nMaxScore)
        end
        UIHelper.ShowConfirm(szContent, function()
            MatchThreeData.SubmitScore()
            UIMgr.Close(self)
        end, nil, true)
    end)

    UIHelper.BindUIEvent(self.BtnOver, EventType.OnClick, function()
        local tbScript = UIMgr.Open(VIEW_ID.PanelMatch_3Pop)
        tbScript:UpdateFinishInfo()
    end)


    UIHelper.BindUIEvent(self.BtnAgain, EventType.OnClick, function()
        local tbScript = UIMgr.Open(VIEW_ID.PanelMatch_3Pop)
        tbScript:UpdateAgainInfo()
    end)

    UIHelper.BindUIEvent(self.TogVoice, EventType.OnSelectChanged, function(_, bSelected)
        local tVal = GetGameSoundSetting(SOUND.MAIN)
        if not bSelected then
            SoundMgr.StopBgMusic()
            MatchThreeData.SetBgmState(true)
        elseif bSelected then
            if tVal.TogSelect then
                TipsHelper.ShowNormalTip("为了更好的游戏体验，请前往设置-声音设置中打开主音量。")
                Timer.AddFrame(self, 1, function ()
                    UIHelper.SetSelected(self.TogVoice, false, false)
                end)
            else
                SoundMgr.PlayLastBgMusic()
                MatchThreeData.SetBgmState(false)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnInfo, EventType.OnClick, function()    --问号指引
        TeachBoxData.OpenTutorialPanel(172,173)
    end)
end

local function CreateEmptyBoard()
    local tbBoard = {}
    for i = 1, BOARD_SIZE do
        tbBoard[i] = {}
        for j = 1, BOARD_SIZE do
            tbBoard[i][j] = nil
        end
    end

    return tbBoard
end

function UIMatchThreeView:RegEvent()
    Event.Reg(self, "MatchThree_BoardChanged", function(tbBoard, tbBeforeDropBoard, tbAfterDropBoard, bInit)   --更新棋盘
        if tbBeforeDropBoard and tbAfterDropBoard then
            self:PlayDropAnim(tbBeforeDropBoard, tbAfterDropBoard, tbBoard, function()
                self:UpdateInfo(tbBoard)
                if self.bEndGame then
                    MatchThreeData.SubmitScore()
                    local tbScript = UIMgr.Open(VIEW_ID.PanelMatch_3Pop)
                    tbScript:UpdateEndInfo()
                end
            end)
        else
            if bInit then
                self:PlayInitDropAnim(tbBoard, function()
                    self:UpdateInfo(tbBoard)
                end)
            else
                self:UpdateInfo(tbBoard)
            end

        end
    end)

    Event.Reg(self, "MatchThree_BoardCellSwap", function (tbCell1, tbCell2, tbBoard)
        self:PlaySwapAnim(tbCell1, tbCell2, tbBoard)
    end)

    Event.Reg(self, "MatchThree_ScoreChanged", function(nScore)   --更新分数
        local nOldScore = self.nScore or 0
        self.nScore = nScore

        local nFlag = MatchThreeData.GetGameRewardFlag() or 0
        local bHave = nFlag == 6
       --游玩过程中第一次达标,且未领取奖励,自动提交分数为历史最高分数
        if nOldScore < nRewardScore and nScore >= nRewardScore and not bHave then
            MatchThreeData.SubmitScore()
            Timer.Add(self, 1, function ()
                self:UpdateReward()
                self:UpdateHistoryScore()
            end)
        end

        self:UpdateSkillAutoShout(nScore)
    end)

    Event.Reg(self, "MatchThree_EnergyChanged", function(szType, nEnergy, nMaxEnergy)   --更新能量
        self:UpdateLeftSkill()
    end)

    Event.Reg(self, "MatchThree_AllEnergyChanged", function(tbEnergy, nMaxEnergy)   --更新所有能量
        self:UpdateLeftSkill()
    end)

    Event.Reg(self, "MatchThree_SkillUsed", function(szHero, tbStartCell) --技能使用提示
        self:ShowHeroAni(szHero)
        self:ShowHeroSkillEff(szHero, tbStartCell)
    end)

    Event.Reg(self, "MatchThree_SameColor", function ()
        if not UIHelper.GetVisible(self.Eff_TongSe) then
            UIHelper.SetVisible(self.Eff_TongSe, true)
        else
            self.Eff_TongSe:Play(0)
        end
    end)


    Event.Reg(self, "MatchThree_ReStartGame", function() --重开
        -- MatchThreeData.SubmitScore()
        self:Init()
        self:UpdateViewInfo()
    end)

    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        szUrl = string.gsub(szUrl, "\\", "/")
        local szLinkEvent, szLinkArg = szUrl:match("(%w+)/(.*)")
        if szLinkEvent == "ItemLinkInfo" then
            local szType, szID = szLinkArg:match("(%d+)/(%d+)")
            local dwType       = tonumber(szType)
            local dwID         = tonumber(szID)

            TipsHelper.ShowItemTips(node, dwType, dwID)
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.tbRewardScript then
            self.tbRewardScript:RawSetSelected(false)
        end
    end)

    Event.Reg(self, "MatchThree_ShowEliminateScore", function(row, col, nAddScore)
        self:ShowEliminateScore(row, col, nAddScore)
    end)

    Event.Reg(self, "MatchThree_UpdateSwapCount", function (nStep)
        self:UpdateGameState()
    end)

    Event.Reg(self, "MatchThree_SwapSuccess", function (nStep)
        self:UpdateStepInfo(nStep)
    end)

    Event.Reg(self, "MatchThree_SettlementEnd", function (nDropCount)
        nDropCount = tonumber(nDropCount) or 0

        if nDropCount >= 10 then
            if not UIHelper.GetVisible(self.Eff_NiZhenBang) then
                UIHelper.SetVisible(self.Eff_NiZhenBang, true)
            else
                self.Eff_NiZhenBang:Play(0)
            end
        elseif nDropCount >= 5 then
            if not UIHelper.GetVisible(self.Eff_LiHaiLa) then
                UIHelper.SetVisible(self.Eff_LiHaiLa, true)
            else
                self.Eff_LiHaiLa:Play(0)
            end
        elseif nDropCount >= 3 then
            if not UIHelper.GetVisible(self.Eff_WaO) then
                UIHelper.SetVisible(self.Eff_WaO, true)
            else
                self.Eff_WaO:Play(0)
            end
        end
    end)
end

function UIMatchThreeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function buildDropMoves(tbBefore, tbAfter, tbBoard)
    local tbMoves = {} -- { {col=, fromRow=, toRow=, szColor=} ... }
    local tbFills = {}

    for col = 1, BOARD_SIZE do
        local tbSources = {}
        for row = BOARD_SIZE, 1, -1 do
            local v = tbBefore[row] and tbBefore[row][col]
            if v ~= nil then
                table.insert(tbSources, { row = row, szColor = v })
            end
        end

        local nFillTotalInCol = 0
        for toRow = BOARD_SIZE, 1, -1 do
            local szCellColorAfter = tbAfter[toRow] and tbAfter[toRow][col]
            if szCellColorAfter == nil then
                local szFillColor = tbBoard[toRow] and tbBoard[toRow][col]
                if szFillColor ~= nil then
                    nFillTotalInCol = nFillTotalInCol + 1
                end
            end
        end

        local nIndex = 1
        for toRow = BOARD_SIZE, 1, -1 do
            local szCellColor = tbAfter[toRow] and tbAfter[toRow][col]
            if szCellColor ~= nil then
                local tbSrc = tbSources[nIndex]
                nIndex = nIndex + 1
                if tbSrc then
                    if tbSrc.row ~= toRow then
                        table.insert(tbMoves, {
                            col = col,
                            fromRow = tbSrc.row,
                            toRow = toRow,
                            szColor = tbSrc.szColor
                        })
                    end
                end
            else
                local szFillColor = tbBoard[toRow] and tbBoard[toRow][col] -- 完整补充后颜色
                if szFillColor ~= nil then
                    table.insert(tbFills, {
                        col = col,
                        toRow = toRow,
                        szColor = szFillColor,
                        nCount = nFillTotalInCol
                    })
                end
            end
        end
    end

    return tbMoves, tbFills
end

-- 统一弹跳效果（fills 也要用）
local function createBounce()
    local bounceUp = cc.MoveBy:create(0.04, cc.p(0, 15))
    local bounceDn = cc.MoveBy:create(0.05, cc.p(0, -15))
    return cc.Sequence:create(
        cc.EaseIn:create(bounceDn, 2.0),
        cc.EaseOut:create(bounceUp, 2.0)
    )
end

function UIMatchThreeView:GetCellScript(nRow, nCol)
    return self.tbCellScriptList[nRow] and self.tbCellScriptList[nRow][nCol]
end

function UIMatchThreeView:PlayDropAnim(tbBeforeDropBoard, tbAfterDropBoard, tbBoard, onDone)
    local moves, tbFills = buildDropMoves(tbBeforeDropBoard, tbAfterDropBoard, tbBoard)
    
    if #moves == 0 and #tbFills == 0 then
        if onDone then onDone() end
        return
    end

    -- self:UpdateInfo(tbBeforeDropBoard)

    for _, m in ipairs(moves) do
        local fromCell = self:GetCellScript(m.fromRow, m.col)
        if fromCell then
            fromCell:SetIconVisible(false)
        end
    end

    local pending = #moves + #tbFills
    local function oneDone()
        pending = pending - 1
        if pending <= 0 then
            if onDone then onDone() end
        end
    end

    UIHelper.RemoveAllChildren(self.WidgetFly)

    for _, m in ipairs(moves) do
        local fromCell = self:GetCellScript(m.fromRow, m.col)
        local toCell   = self:GetCellScript(m.toRow, m.col)
        if fromCell and toCell then
            local szImg = tbCellImgList[m.szColor]

            local fly = UIHelper.AddPrefab(PREFAB_ID.WidgetMatch_3Cell, self.WidgetFly)
            fly:SetInteractive(false)
            fly:UpdateInfo(szImg, m.szColor)

            local nFromX, nFromY = fromCell._rootNode:getPosition()
            fly._rootNode:setPosition(nFromX, nFromY)

            local nToX, nToY = toCell._rootNode:getPosition()
            local duration = 0.1
            local moveDown = cc.MoveTo:create(duration, cc.p(nToX, nToY))
            local easeDown = cc.EaseIn:create(moveDown, 3.0)
            
            
            local act = cc.Sequence:create(
                easeDown,
                createBounce(),
                cc.CallFunc:create(function()
                    if fly and fly._rootNode then
                        UIHelper.RemoveFromParent(fly._rootNode)
                    end
                    oneDone()
                end)
            )
            fly._rootNode:runAction(act)
        else
            oneDone()
        end
    end
    
    for _, f in ipairs(tbFills) do
        local toCell = self:GetCellScript(f.toRow, f.col)
        if toCell then
            local szImg = tbCellImgList[f.szColor]

            local fly = UIHelper.AddPrefab(PREFAB_ID.WidgetMatch_3Cell, self.WidgetFly)
            fly:SetInteractive(false)
            fly:UpdateInfo(szImg, f.szColor)
            UIHelper.SetVisible(fly.ImgBg, false)

            local nToX, nToY = toCell._rootNode:getPosition()

            local nCount = f.nCount
            local nHeight = UIHelper.GetHeight(toCell._rootNode)
            local nSpacing = UIHelper.LayoutGetSpacingY(self.LayoutMatch)
            local nFromX, nFromY = nToX, nToY + (nHeight + nSpacing) * nCount
            fly._rootNode:setPosition(nFromX, nFromY)

            local duration = 0.1
            local moveDown = cc.MoveTo:create(duration, cc.p(nToX, nToY))
            local easeDown = cc.EaseIn:create(moveDown, 3.0)

            local act = cc.Sequence:create(
                easeDown,
                createBounce(),
                cc.CallFunc:create(function()
                    if fly and fly._rootNode then
                        UIHelper.RemoveAllChildren(fly._rootNode)
                    end
                    oneDone()
                end)
            )
            fly._rootNode:runAction(act)
        else
            oneDone()
        end
    end

end


local function GetExchangeableCellList(nRow, nCol)
    local tbCellList = {}
    if nRow > 1 then
        table.insert(tbCellList, { row = nRow - 1, col = nCol })
    end
    if nRow < BOARD_SIZE then
        table.insert(tbCellList, { row = nRow + 1, col = nCol })
    end
    if nCol > 1 then
        table.insert(tbCellList, { row = nRow, col = nCol - 1 })
    end
    if nCol < BOARD_SIZE then
        table.insert(tbCellList, { row = nRow, col = nCol + 1 })
    end

    return tbCellList
end

function UIMatchThreeView:GetCurThroughCell(nX, nY, tbCellList)
    for k, tbCell in pairs(tbCellList) do
        local nRow = tbCell.row
        local nCol = tbCell.col
        local tbCellScript = self:GetCellScript(nRow, nCol)
        if tbCellScript then
            local nCellX, nCellY = UIHelper.GetWorldPosition(tbCellScript._rootNode)
            local nWidth, nHeight = UIHelper.GetContentSize(tbCellScript._rootNode)
            if nX >= nCellX - nWidth / 2 and nX <= nCellX + nWidth / 2 and
               nY >= nCellY - nHeight / 2 and nY <= nCellY + nHeight / 2 then
                return tbCell
            end
        end
    end

    return nil
end

function UIMatchThreeView:UpdateInfo(tbBoard)
    self.tbCellScriptList = self.tbCellScriptList or {}

    --更新棋盘显示
    for nRow = 1, BOARD_SIZE do
        local tbRow = tbBoard[nRow]
        for nCol = 1, BOARD_SIZE, 1 do
            local szColor = tbRow[nCol]
            local szImg = tbCellImgList[szColor]
            local tbCellScript = self.tbCellScriptList[nRow] and self.tbCellScriptList[nRow][nCol]
            if not tbCellScript then
                tbCellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetMatch_3Cell, self.LayoutMatch)
                UIHelper.BindUIEvent(tbCellScript.TogMatch, EventType.OnTouchBegan, function(btn, nX, nY)
                    local bIsAnimating = MatchThreeData.ClickCell(nRow, nCol)
                    if self.tbCurSelectedCell then
                        UIHelper.SetVisible(self.tbCurSelectedCell.ImgChoose, false)
                    end
                    UIHelper.SetSelected(tbCellScript.TogMatch, true)
                    UIHelper.SetVisible(tbCellScript.ImgChoose, not bIsAnimating)
                    self.tbCurSelectedCell = tbCellScript
                end)

                UIHelper.BindUIEvent(tbCellScript.TogMatch, EventType.OnTouchMoved, function(btn, nX, nY)
                    local tbCellList = GetExchangeableCellList(nRow, nCol)
                    local tbThroughCell = self:GetCurThroughCell(nX, nY, tbCellList)
                    if tbThroughCell then
                        local nRow = tbThroughCell.row
                        local nCol = tbThroughCell.col
                        MatchThreeData.ClickCell(nRow, nCol)
                    end
                end)

                UIHelper.SetToggleGroupIndex(tbCellScript.TogMatch, ToggleGroupIndex.MatchThreeGame)

                self.tbCellScriptList[nRow] = self.tbCellScriptList[nRow] or {}
                self.tbCellScriptList[nRow][nCol] = tbCellScript
            end

            tbCellScript:UpdateInfo(szImg, szColor)
        end
    end
end

function UIMatchThreeView:DoUpdateScoreNow(nScore)
    if not nScore then
        nScore = 0
    end

    if nScore ~= 0 then
        UIHelper.PlayAni(self, self.AniScore, "AniScore", function ()
        end)
    end

    Timer.Add(self, 0.417, function ()
        UIHelper.RemoveAllChildren(self.LayouttNumber)
        local szScoreStr = tostring(nScore)
        for i = 1, #szScoreStr do
            local szNumChar = string.sub(szScoreStr, i, i)
            local nNum = tonumber(szNumChar)
            local szImg = nNum == 0 and tbNumImgList[10] or tbNumImgList[nNum]
            if szImg then
                local imgScript = UIHelper.AddPrefab(PREFAB_ID.WidgetScoreNum, self.LayouttNumber)
                UIHelper.SetSpriteFrame(imgScript.ImgScore, szImg, false)
            end
        end
    end)
end

function UIMatchThreeView:UpdateScore(nScore)
    if not nScore then
        nScore = 0
    end

    self._pendingScore = nScore

    if self._scoreUpdateCooling then
        return
    end

    self._scoreUpdateCooling = true
    local scoreToApply = self._pendingScore
    self._pendingScore = nil
    self:DoUpdateScoreNow(scoreToApply)

    Timer.Add(self, 1.0, function()
        self._scoreUpdateCooling = false

        if self._pendingScore ~= nil then
            local nextScore = self._pendingScore
            self._pendingScore = nil
            self:UpdateScore(nextScore)
        end
    end)
end

function UIMatchThreeView:UpdateHistoryScore()
    Timer.Add(self, 1, function ()
        local nHistoryScore = MatchThreeData.GetHistoryScore() or 0
        local szText = "历史最高记录：%d"
        UIHelper.SetString(self.LabelHistory, string.format(szText, nHistoryScore))
        UIHelper.LayoutDoLayout(self.LayputHistory)
    end)
end

function UIMatchThreeView:Init()
    MatchThreeData.InitGame()
    MatchThreeData.StartGame()
end

function UIMatchThreeView:UpdateViewInfo()
    local nScore = MatchThreeData.GetScore()
    local nStep = MatchThreeData.GetSwapStepNum()
    self:UpdateScore(nScore)
    self:UpdateReward()
    self:UpdateHistoryScore()
    self:UpdateStepInfo(nStep)
    self:UpdateGameState()
end

function UIMatchThreeView:SubmitScore()
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    local nScore = MatchThreeData.GetScore()
    local nMaxScore = MatchThreeData.GetHistoryScore()
    if nScore > nMaxScore then
        RemoteCallToServer("On_Activity_UpdateGameScore", nScore)
    end
end

function UIMatchThreeView:UpdateLeftSkill()
    self.tbSkillScriptList = self.tbSkillScriptList or {}
    local tbEnergy = MatchThreeData.GetEnergy()

    for nIndex, tbNameInfo in ipairs(tbNames) do
        local szColor = tbNameInfo.szColor
        local tbSkillScript = self.tbSkillScriptList[szColor]
        if not tbSkillScript then
            tbSkillScript = UIHelper.AddPrefab(PREFAB_ID.WidgetMatch_3SkillCell, self.LayoutSkill)
            tbSkillScript:UpdateInfo(szColor, tbNameInfo.szHero, tbNameInfo.szSkillName)
            self.tbSkillScriptList[szColor] = tbSkillScript
        end
        tbSkillScript:UpdateEnergy(tbEnergy[szColor] or 0)
    end

    UIHelper.LayoutDoLayout(self.LayoutSkill)
end

function UIMatchThreeView:UpdateReward()
    local szText = "<color=#FFE9D3>达到30000分可获得</c><color=#FFE9D3>称号<href=ItemLinkInfo\\5\\85240><color=#FFB0F3>【大神】</color></href></color>"
    UIHelper.SetRichText(self.LabelTip, szText)
    UIHelper.SetVisible(self.LabelTip, true)

    -- if not IsActivityOn(224) then
    --     return
    -- end

    local nHisToryScore = MatchThreeData.GetHistoryScore() or 0
    local nFlag = MatchThreeData.GetGameRewardFlag() or 0
    local bHave = nFlag == 6
    local bCanGet = nFlag == 5 or nHisToryScore >= nRewardScore

    local scriptView = self.tbRewardScript
    if not scriptView then
        scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.WidgetItem)
        scriptView:OnInitWithTabID(5, 85240)
        scriptView:SetClickCallback(function(nTabType, nTabID)
            nHisToryScore = MatchThreeData.GetHistoryScore() or 0
            nFlag = MatchThreeData.GetGameRewardFlag() or 0
            bHave = nFlag == 6
            bCanGet = nFlag == 5 or nHisToryScore >= nRewardScore
            if bHave then
                TipsHelper.ShowItemTips(scriptView._rootNode, 5, 85240)
            else
                if bCanGet then
                    RemoteCallToServer("On_Activity_GetGameReward")
                    Timer.Add(self, 1, function ()
                        self:UpdateReward()
                    end)
                else
                    TipsHelper.ShowItemTips(scriptView._rootNode, 5, 85240)
                end
            end
        end)

        self.tbRewardScript = scriptView
    end

    self:UpdateRewardInfo(bCanGet, bHave)
end

function UIMatchThreeView:UpdateRewardInfo(bCanGet, bHaveGet)
    UIHelper.SetVisible(self.ImgAvailableNew, bCanGet)
    UIHelper.SetVisible(self.WidgetGet, bHaveGet)
end

function UIMatchThreeView:ShowHeroSkillEff(szHero, tbStartCell)
    local nRow = tbStartCell.row
    local nCol = tbStartCell.col
    local tbCellScript = self:GetCellScript(nRow, nCol)
    if not tbCellScript then
        return
    end

    local nX, nY = tbCellScript._rootNode:getPosition()
    local nWidth, nHeight = UIHelper.GetContentSize(tbCellScript._rootNode)
    local nSpacing = UIHelper.LayoutGetSpacingY(self.LayoutMatch)
    local node = nil
    local Eff = nil

    if szHero == "康宴别" then
        nY = nY + nHeight / 2
        nX = nX - nWidth / 2
        node = self.WidgetKangYanBie
        Eff = self.Eff_KangYanBie
    elseif szHero == "姜棠" then
        nY = nY + nHeight + nSpacing + nHeight / 2
        nX = nX - nWidth - nSpacing - nWidth / 2
        node = self.WidgetJiangTang
        Eff = self.Eff_JiangTang
    elseif szHero == "月嘉禾" then
        nY = nY + nHeight / 2
        nX = nX - nWidth / 2
        node = self.WidgetYueJiaHe
        Eff = self.Eff_YueJiaHe
    elseif szHero == "白鹊" then
        local bIsHorizontal = tbStartCell.isHorizontal
        nY = nY + nHeight / 2
        nX = nX - nWidth / 2
        node = bIsHorizontal and self.WidgetBaiQue_Heng or self.WidgetBaiQue_Lie
        Eff = bIsHorizontal and self.Eff_BaiQue2 or self.Eff_BaiQue
    end

    node:setPosition(nX, nY)
    if not UIHelper.GetVisible(Eff) then
        UIHelper.SetVisible(Eff, true)
    else
        Eff:Play(0)
    end
end

function UIMatchThreeView:PlaySwapAnim(tbCell1, tbCell2, tbBoard)
    if not tbCell1 or not tbCell2 or not tbBoard then
        return
    end

    local c1 = self:GetCellScript(tbCell1.row, tbCell1.col)
    local c2 = self:GetCellScript(tbCell2.row, tbCell2.col)
    if not c1 or not c2 then
        self:UpdateInfo(tbBoard)
        return
    end

    c1:SetIconVisible(false)
    c2:SetIconVisible(false)

    UIHelper.RemoveAllChildren(self.WidgetFly)

    local function createFlyCell(szColor, nRow, nCol, x, y)
        local szImg = tbCellImgList[szColor]

        local fly = UIHelper.AddPrefab(PREFAB_ID.WidgetMatch_3Cell, self.WidgetFly)
        fly:SetInteractive(false)
        fly:UpdateInfo(szImg, szColor)
        UIHelper.SetVisible(fly.ImgBg, false) -- 飞行时不显示底色（与你的下落动画一致）
        fly._rootNode:setPosition(x, y)
        return fly
    end

    local x1, y1 = c1._rootNode:getPosition()
    local x2, y2 = c2._rootNode:getPosition()

    local fly1 = createFlyCell(tbCell1.color, tbCell1.row, tbCell1.col, x1, y1)
    local fly2 = createFlyCell(tbCell2.color, tbCell2.row, tbCell2.col, x2, y2)

    local pending = 2
    local function oneDone()
        pending = pending - 1
        if pending <= 0 then
            if fly1 and fly1._rootNode then
                UIHelper.RemoveFromParent(fly1._rootNode)
            end
            if fly2 and fly2._rootNode then
                UIHelper.RemoveFromParent(fly2._rootNode)
            end
            self:UpdateInfo(tbBoard)
        end
    end

    local duration = 0.12
    local act1 = cc.Sequence:create(
        cc.MoveTo:create(duration, cc.p(x2, y2)),
        cc.CallFunc:create(oneDone)
    )
    local act2 = cc.Sequence:create(
        cc.MoveTo:create(duration, cc.p(x1, y1)),
        cc.CallFunc:create(oneDone)
    )

    fly1._rootNode:stopAllActions()
    fly2._rootNode:stopAllActions()
    fly1._rootNode:runAction(act1)
    fly2._rootNode:runAction(act2)

end

function UIMatchThreeView:ShowEliminateScore(nRow, nCol, nAddScore)
    local nScore = MatchThreeData.GetScore()
    if not nRow or not nCol then
        self:UpdateScore(nScore)
        return
    end

    local cell = self:GetCellScript(nRow, nCol)
    if not cell or not cell._rootNode then
        self:UpdateScore(nScore)
        return
    end

    local szScoreStr = tostring(nAddScore)
    UIHelper.RemoveAllChildren(cell.LayouttNumber)
    local tbImgList = nAddScore >=200 and tbNumImgList or tbGreenNumImgList
    for i = 1, #szScoreStr do
        local szNumChar = string.sub(szScoreStr, i, i)
        local nNum = tonumber(szNumChar)
        local szImg = nNum == 0 and tbImgList[10] or tbImgList[nNum]
        if szImg then
            local imgScript = UIHelper.AddPrefab(PREFAB_ID.WidgetScoreNum, cell.LayouttNumber)
            UIHelper.SetSpriteFrame(imgScript.ImgScore, szImg, false)
        end
    end
    UIHelper.PlayAni(cell, cell.LayouttNumber, "AniMatch_3CellScore2", function ()
        self:UpdateScore(nScore)
    end)
end

local tbName2Node = {
    ["康宴别"] = {"WidgetKYB", "AniSkill_BaiQue"},
    ["姜棠"]   = {"WidgetJT", "AniSkill_JiangTang"},
    ["月嘉禾"] = {"WidgetYJH", "AniSkill_YueJiaHe"},
    ["白鹊"]   = {"WidgetBQ", "AniSkill_KangYanBie"},
}
function UIMatchThreeView:ShowHeroAni(szHero)
    if not szHero then
        return
    end

    local tbAniInfo = tbName2Node[szHero]
    local node, szAni = tbAniInfo[1] and self[tbAniInfo[1]], tbAniInfo[2]
    if not node then
        return
    end

    self._heroAniToken = (self._heroAniToken or 0) + 1
    local myToken = self._heroAniToken
    self._heroAniPlaying = true

    UIHelper.SetVisible(self.LayoutSkill, false)
    UIHelper.SetVisible(node, true)

    UIHelper.PlayAni(self, node, szAni, function ()
        if self._heroAniToken ~= myToken then
            return
        end
        UIHelper.SetVisible(node, false)
        UIHelper.SetVisible(self.LayoutSkill, true)
        self._heroAniPlaying = false

        local pendingColor = self._pendingAutoShoutColor
        self._pendingAutoShoutColor = nil
        if pendingColor and self.tbSkillScriptList and self.tbSkillScriptList[pendingColor] then
            self.tbSkillScriptList[pendingColor]:ShowAutoShout()
        end
    end)
end

local tbColors = {
    "gold","purple", "blue", "red"
}
function UIMatchThreeView:UpdateSkillAutoShout(nScore)
    --分数每次新增5000分，自动喊话一次
    local nOldAutoShoutScore = self.nAutoShoutScore or 0
    if nScore - nOldAutoShoutScore >= 5000 then
        self.nAutoShoutScore = nScore - (nScore % 5000)
        local szColor = tbColors[math.random(1, #tbColors)]

        if self._heroAniPlaying then
            self._pendingAutoShoutColor = szColor
            return
        end

        local tbSkillScript = self.tbSkillScriptList[szColor]
        if tbSkillScript then
            tbSkillScript:ShowAutoShout()
        end
    end
end

function UIMatchThreeView:PlayInitDropAnim(tbBoard, onDone)
    if not tbBoard then
        if onDone then onDone() end
        return
    end

    self:UpdateInfo(tbBoard)
    for r = 1, BOARD_SIZE do
        for c = 1, BOARD_SIZE do
            local cell = self:GetCellScript(r, c)
            if cell then
                cell:SetIconVisible(false)
            end
        end
    end
    Timer.Add(self, 0.5, function ()
        UIHelper.RemoveAllChildren(self.WidgetFly)
    
        local pending = BOARD_SIZE * BOARD_SIZE
        local function oneDone()
            pending = pending - 1
            if pending <= 0 then
                if onDone then onDone() end
            end
        end
    
        local duration = 0.3
        for toRow = 1, BOARD_SIZE do
            for col = 1, BOARD_SIZE do
                local szColor = tbBoard[toRow] and tbBoard[toRow][col]
                local toCell = self:GetCellScript(toRow, col)
                if szColor and toCell then
                    local szImg = tbCellImgList[szColor]
    
                    local fly = UIHelper.AddPrefab(PREFAB_ID.WidgetMatch_3Cell, self.WidgetFly)
                    fly:SetInteractive(false)
                    fly:UpdateInfo(szImg, szColor)
                    UIHelper.SetVisible(fly.ImgBg, false)
    
                    local nToX, nToY = toCell._rootNode:getPosition()
                    local nHeight = UIHelper.GetHeight(toCell._rootNode)
                    local nSpacing = UIHelper.LayoutGetSpacingY(self.LayoutMatch)
    
                    local nFromX, nFromY = nToX, nToY + (nHeight + nSpacing) * BOARD_SIZE
                    fly._rootNode:setPosition(nFromX, nFromY)
    
                    local moveDown = cc.MoveTo:create(duration, cc.p(nToX, nToY))
                    local easeDown = cc.EaseIn:create(moveDown, 3.0)
    
                    fly._rootNode:runAction(cc.Sequence:create(
                        easeDown,
                        createBounce(),
                        cc.CallFunc:create(function()
                            if fly and fly._rootNode then
                                UIHelper.RemoveFromParent(fly._rootNode)
                            end
                            oneDone()
                        end)
                    ))
                else
                    oneDone()
                end
            end
        end
    end)

end

function UIMatchThreeView:UpdateStepInfo(nStep)
    if nStep and nStep >= 0 then
        UIHelper.SetString(self.LabelStepNum, string.format("%d", nStep))
        UIHelper.PlayAni(self, self.ImgLantern2, "AniStep")
    end
end

function UIMatchThreeView:UpdateGameState()
    local nStep = MatchThreeData.GetSwapStepNum()
    self.bEndGame = nStep and nStep <= 0
end

return UIMatchThreeView