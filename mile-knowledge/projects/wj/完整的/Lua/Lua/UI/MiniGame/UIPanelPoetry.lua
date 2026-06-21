-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIPanelPoetry
-- Date: 2025-09-29 15:41:27
-- Desc: 诗词面板
-- ---------------------------------------------------------------------------------

local szHintPrefix = "连出所有诗词"
local WORD_STATE = {
    NONE    = 0,
    SELECT  = 1,
    CORRECT = 2,
    WRONG   = 3,
    HINT    = 4,
}

local MAX_FAILED_TIMES = 5
local CORRECT_FRAME_STR = {
    "UIAtlas2_LittleGame_Poetry_icon_purple.png", "UIAtlas2_LittleGame_Poetry_icon_pink", "UIAtlas2_LittleGame_Poetry_icon_red",
    "UIAtlas2_LittleGame_Poetry_icon_gblue", "UIAtlas2_LittleGame_Poetry_icon_pink.png", "UIAtlas2_LittleGame_Poetry_icon_pblue.png", "UIAtlas2_LittleGame_Poetry_icon_bule",
    "UIAtlas2_LittleGame_Poetry_icon_gyellow", "UIAtlas2_LittleGame_Poetry_icon_pink.png", "UIAtlas2_LittleGame_Poetry_icon_yellow", "UIAtlas2_LittleGame_Poetry_icon_orange",
}

local function ParseCell(szCell)
    local t = SplitString(szCell, "_")
    local dwID, nIndex = tonumber(t[1]), tonumber(t[2])
    return dwID, nIndex
end
-----------------------------DataModel------------------------------
local DataModel = {}
local gbk = nil

function DataModel.Init(tInfo)
    if not gbk then
        local szPath = "ui/Script/gbk.lua"
        local closure = {}
        LoadScriptFile(szPath, closure)
        gbk = closure.gbk
    end

    DataModel.nType = tInfo.nType
    DataModel.nStartTime = GetCurrentTime()
    if not DataModel.tAllPoetry then
        DataModel.tAllPoetry = Table_GetAllPoetry()
    end
    if MiniGame.bDebugMode then
        local tMatrix, tAnswerPos, tAnswer = DataModel.GenerateMatrix(5, 14, 5)
        DataModel.tPoetryMatrix = tMatrix
        DataModel.tPoetryAnswer = tAnswerPos
        DataModel.tAnswerInfo = tAnswer
    else
        local tConfig = Table_GetPoetryContent(DataModel.nType)
        local szContent = tConfig.szContent
        DataModel.tPoetryMatrix = {}
        local tLine = SplitString(szContent, "|")
        for _, szLine in pairs(tLine) do
            local tWords = SplitString(szLine, ";")
            table.insert(DataModel.tPoetryMatrix, tWords)
        end

        local szAnswer = tConfig.szAnswer
        DataModel.tPoetryAnswer = {}
        DataModel.tAnswerInfo = {}
        local tAnswer = SplitString(szAnswer, "|")
        for _, szLine in pairs(tAnswer) do
            local tWords = SplitString(szLine, ";")
            local t = {}
            local szPoetry = ""
            for _, szPos in pairs(tWords) do
                local x, y = ParseCell(szPos)
                local szCell = DataModel.tPoetryMatrix[x][y]
                local dwID, nIndex = ParseCell(szCell)
                table.insert(t, { x, y })
                szPoetry = szPoetry .. DataModel.GetPoetryWord(dwID, nIndex)
            end
            local dwPoetryID = DataModel.GetIDByPoetry(szPoetry)
            table.insert(DataModel.tPoetryAnswer, t)
            table.insert(DataModel.tAnswerInfo, { dwID = dwPoetryID, szPoetry = szPoetry })
        end
        --UILog(DataModel.tPoetryMatrix, DataModel.tPoetryAnswer, DataModel.tAnswerInfo)
    end
    DataModel.tOperatePos = {}
    DataModel.tOperateKey = {}
    DataModel.tWordState = {}
    DataModel.nCurAnswerIndex = nil
    DataModel.bAutoClick = false
    DataModel.nFailedTimes = 0
    DataModel.tLastWrongPos = {}
end

function DataModel.GetPoetryByID(dwID)
    for _, v in pairs(DataModel.tAllPoetry) do
        if v.dwID == dwID then
            return v
        end
    end
    return nil
end

function DataModel.GetIDByPoetry(szPoetry)
    for _, v in pairs(DataModel.tAllPoetry) do
        if gbk.sub(v.szPoetry, 1, gbk.len(szPoetry)) == szPoetry then
            return v.dwID
        end
    end
    return nil
end

function DataModel.GetPoetryWord(dwID, nIndex)
    local poetry = DataModel.GetPoetryByID(dwID)
    if poetry then
        return gbk.sub(poetry.szPoetry, nIndex, nIndex)
    end
    return nil
end

--指定诗句个数
function DataModel.GenerateMatrix(n, m, nNumAnswers)
    nNumAnswers = nNumAnswers or 1

    if not DataModel.tAllPoetry or #DataModel.tAllPoetry < nNumAnswers then
        UILog("Poetry Library Not Enough")
        return nil, nil, nil
    end

    local tAnswerPoems = {}
    local tAvailablePoems = {}
    for _, tPoem in pairs(DataModel.tAllPoetry) do
        table.insert(tAvailablePoems, tPoem)
    end

    local nTotalLength = 0
    for i = 1, nNumAnswers do
        local nRandIndex = math.random(#tAvailablePoems)
        local tSelectedPoem = table.remove(tAvailablePoems, nRandIndex)
        table.insert(tAnswerPoems, tSelectedPoem)
        nTotalLength = nTotalLength + gbk.len(tSelectedPoem.szPoetry)
    end

    if n * m < nTotalLength then
        UILog("Matrix Does Not Have Enough Space")
        return nil, nil, nil
    end

    local tAllPaths = {}
    local tGlobalVisited = {}
    for i = 1, n do
        tGlobalVisited[i] = {}
    end
    local tDirections = { { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }

    local function GeneratePathRecursive(tPath, tVisited, nTextLength, nX, nY, nIndex)
        if nIndex > nTextLength then
            return true
        end
        if not (nX >= 1 and nX <= n and nY >= 1 and nY <= m and not tVisited[nX][nY] and not tGlobalVisited[nX][nY]) then
            return false
        end
        tVisited[nX][nY] = true
        tPath[nIndex] = { nX, nY }
        for i = #tDirections, 2, -1 do
            local j = math.random(i)
            tDirections[i], tDirections[j] = tDirections[j], tDirections[i]
        end
        for _, tDir in pairs(tDirections) do
            if GeneratePathRecursive(tPath, tVisited, nTextLength, nX + tDir[1], nY + tDir[2], nIndex + 1) then
                return true
            end
        end
        tVisited[nX][nY] = false
        return false
    end

    for _, tPoem in pairs(tAnswerPoems) do
        local tPath = {}
        local Success = false
        local nAttempts = 0
        while not Success and nAttempts < 500 do
            tPath = {}
            local tVisited = {}
            for nI = 1, n do
                tVisited[nI] = {}
            end
            local nStartX, nStartY = math.random(n), math.random(m)
            if GeneratePathRecursive(tPath, tVisited, gbk.len(tPoem.szPoetry), nStartX, nStartY, 1) then
                Success = true
            end
            nAttempts = nAttempts + 1
        end

        if not Success then
            UILog("No Answer")
            return nil, nil, nil
        end

        table.insert(tAllPaths, tPath)
        for _, tPos in ipairs(tPath) do
            tGlobalVisited[tPos[1]][tPos[2]] = true
        end
    end

    local tMatrix = {}
    for i = 1, n do
        tMatrix[i] = {}
    end

    for i, tPoem in pairs(tAnswerPoems) do
        local tPath = tAllPaths[i]
        for j, tPos in ipairs(tPath) do
            tMatrix[tPos[1]][tPos[2]] = string.format("%d_%d", tPoem.dwID, j)
        end
    end

    for i = 1, n do
        for j = 1, m do
            if not tMatrix[i][j] then
                local tRandPoem = DataModel.tAllPoetry[math.random(#DataModel.tAllPoetry)]
                local nRandIndex = math.random(gbk.len(tRandPoem.szPoetry))
                tMatrix[i][j] = string.format("%d_%d", tRandPoem.dwID, nRandIndex)
            end
        end
    end

    -- UILog(tMatrix, tAllPaths, tAnswerPoems)
    local szContent = ""
    for _, tLine in pairs(tMatrix) do
        szContent = szContent .. table.concat(tLine, ";")
        if szContent ~= "" then
            szContent = szContent .. "|"
        end
    end
    UILog("szContent :", szContent)

    local szAnswer = ""
    for _, tPath in pairs(tAllPaths) do
        local szLine = ""
        for _, tPos in ipairs(tPath) do
            szLine = szLine .. table.concat(tPos, "_")
            if szLine ~= "" then
                szLine = szLine .. ";"
            end
        end
        szAnswer = szAnswer .. szLine
        if szAnswer ~= "" then
            szAnswer = szAnswer .. "|"
        end
    end
    UILog("szAnswer :", szAnswer)

    return tMatrix, tAllPaths, tAnswerPoems
end

function DataModel.SolveMatrix(tMatrix)
    if not tMatrix or #tMatrix == 0 then
        return nil
    end

    local nN = #tMatrix
    local nM = #tMatrix[1]
    local tDirections = { { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }
    local tAllSolutions = {}

    local function DFS(tPath, tVisited, tTargetPoem, nIndex, nX, nY)
        if nIndex > gbk.len(tTargetPoem.szPoetry) then
            return true
        end
        if not (nX >= 1 and nX <= nN and nY >= 1 and nY <= nM and not tVisited[nX][nY]) then
            return false
        end

        local dwID, nIndex = ParseCell(tMatrix[nX][nY])
        local CharInMatrix = DataModel.GetPoetryWord(dwID, nIndex)
        local ExpectedChar = gbk.sub(tTargetPoem.szPoetry, nIndex, nIndex)
        if CharInMatrix ~= ExpectedChar then
            return false
        end

        tVisited[nX][nY] = true
        table.insert(tPath, { nX, nY })
        for _, tDir in pairs(tDirections) do
            if DFS(tPath, tVisited, tTargetPoem, nIndex + 1, nX + tDir[1], nY + tDir[2]) then
                return true
            end
        end
        tVisited[nX][nY] = false
        table.remove(tPath)
        return false
    end

    for _, tPoemToFind in pairs(DataModel.tAllPoetry) do
        if gbk.len(tPoemToFind.szPoetry) > 0 then
            for nI = 1, nN do
                for nJ = 1, nM do
                    local tPath = {}
                    local tVisited = {}
                    for nRow = 1, nN do
                        tVisited[nRow] = {}
                    end

                    if DFS(tPath, tVisited, tPoemToFind, 1, nI, nJ) then
                        table.insert(tAllSolutions, { Poem = tPoemToFind, Path = tPath })
                    end
                end
            end
        end
    end

    return tAllSolutions
end

function DataModel.SetWordState(x, y, nState)
    if not DataModel.tWordState[x] then
        DataModel.tWordState[x] = {}
    end
    DataModel.tWordState[x][y] = { nState = nState }
    if nState == WORD_STATE.HINT then
        DataModel.tWordState[x][y].bHint = true
    elseif nState ~= WORD_STATE.WRONG then
        DataModel.tWordState[x][y].bHint = false
    end

    if nState == WORD_STATE.CORRECT then
        local nCorrectFrame = DataModel.GetCorrectFrame()
        DataModel.tWordState[x][y].nCorrectFrame = nCorrectFrame
    end
end

function DataModel.GetWordState(x, y)
    return DataModel.tWordState[x][y].nState
end

function DataModel.GetWordCorrectFrame(x, y)
    return DataModel.tWordState[x][y].nCorrectFrame
end

function DataModel.GetCorrectFrame()
    local nFinishCount, nTotalCount = DataModel.GetFinishCount()
    local nTotalCnt = #CORRECT_FRAME_STR
    local nIndex = nFinishCount + 1

    if nIndex <= 0 then
        nIndex = 1
    elseif nIndex > nTotalCnt then
        nIndex = (nIndex - 1) % nTotalCnt + 1 -- 如果超出表范围，使用取余操作循环
    end
    local nCorrectFrame = CORRECT_FRAME_STR[nIndex]
    return nCorrectFrame
end

function DataModel.IsWordInHint(x, y)
    return DataModel.tWordState[x][y].bHint
end

function DataModel.GetHintAnswer()
    if DataModel.nCurAnswerIndex then
        return DataModel.nCurAnswerIndex
    end

    if not DataModel.tLastWrongPos then
        return 1
    end

    for nIndex, tAnswer in pairs(DataModel.tAnswerInfo) do
        if not tAnswer.bFinish then
            local tInfo = DataModel.tPoetryAnswer[nIndex]
            if tInfo then
                for _, v in pairs(tInfo) do
                    if v[1] == DataModel.tLastWrongPos.x and v[2] == DataModel.tLastWrongPos.y then
                        return nIndex
                    end
                end
            end
        end
    end
end

function DataModel.GetFinishCount()
    local nCount = 0
    for _, tAnswer in pairs(DataModel.tAnswerInfo) do
        if tAnswer.bFinish then
            nCount = nCount + 1
        end
    end
    return nCount, #DataModel.tAnswerInfo
end

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

-----------------------------View------------------------------

local UIPanelPoetry = class("UIPanelPoetry")

function UIPanelPoetry:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init(tInfo)
    self:UpdateInfo()

    Timer.AddFrameCycle(self, 2, function()
        self:UpdateTime()
    end)
end

function UIPanelPoetry:OnExit()
    self.bInit = false
    self:UnRegEvent()
    RemoteCallToServer("On_LianShi_ClearData", { nType = DataModel.nType })
    DataModel.UnInit()
end

function UIPanelPoetry:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        TeachBoxData.OpenTutorialPanel(169)
    end)
end

function UIPanelPoetry:RegEvent()
    Event.Reg(self, "MiniGame_UpdatePoetry", function(tInfo)
        self:Update(tInfo)
    end)
end

function UIPanelPoetry:UnRegEvent()
    --Event.UnReg(self, EventType.XXX )
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local function _forEachValidNode(node, func)
    -- 筛选widget
    if not node then
        return
    end
    if node:getName() == "PanelHoverTips" then
        return
    end
    if node:getName() == "PanelNodeExplorer" then
        return
    end
    if not UIHelper.GetVisible(node) then
        return
    end
    if node.isEnabled and not node:isEnabled() then
        return
    end

    local aChildren = node:getChildren()
    if aChildren then
        for i = 1, #aChildren do
            local childNode = aChildren[i]
            if UIHelper.GetVisible(childNode) and (not childNode.isEnabled or childNode:isEnabled()) then
                func(childNode)
                _forEachValidNode(childNode, func)
            end
        end
    end
end

function UIPanelPoetry:CollectNodeByPoint(x, y)
    local tbPoint = cc.p(x, y) -- 鼠标位置的世界坐标

    local sceneNode = cc.Director:getInstance():getRunningScene()
    local camera = sceneNode:getDefaultCamera()
    local tbNodes = {}

    -- 遍历所有节点
    _forEachValidNode(self.LayoutWidgetPoetry, function(node)
        local bIsHit = false

        -- hitTest for button etc.
        if node.hitTest and node:hitTest(tbPoint, camera) then
            if node:isClippingParentContainsPoint(tbPoint) then
                table.insert(tbNodes, node)
            end
        end
        return bIsHit
    end)

    for _, node in pairs(tbNodes) do
        if self.tAllWordBtns[node] then
            return node
        end
    end

    return nil
end

function UIPanelPoetry:MoveCursor(nX, nY)
    if DataModel.bAutoClick then
        local currentNode = self:CollectNodeByPoint(nX, nY)
        if self.LastBtn ~= currentNode then
            self.LastBtn = currentNode
            if currentNode then
                self:SelectWord(self.tAllWordBtns[currentNode])
            end
        end
    end
end

function UIPanelPoetry:UpdateInfo()
    UIHelper.SetLabel(self.LabelTitle, string.format("第%s关", UIHelper.NumberToChinese(DataModel.nType)))

    self.tAllWordScripts = {}
    self.tAllWordBtns = {}
    if DataModel.tPoetryMatrix then
        local n = #DataModel.tPoetryMatrix
        local m = #DataModel.tPoetryMatrix[1]
        for i = 1, n do
            for j = 1, m do
                local szCell = DataModel.tPoetryMatrix[i][j]
                local dwID, nIndex = ParseCell(szCell)
                local szWord = DataModel.GetPoetryWord(dwID, nIndex)
                local script = UIHelper.AddPrefab(PREFAB_ID.WidgetPoetryIcon, self.LayoutWidgetPoetry)
                UIHelper.SetLabel(script.LabelTitle, UIHelper.GBKToUTF8(szWord))
                script.szKey = szCell
                script.x = i
                script.y = j
                local scriptBtn = script.BtnPoetryIcon
                DataModel.SetWordState(i, j, WORD_STATE.NONE)
                table.insert(self.tAllWordScripts, script)
                self.tAllWordBtns[scriptBtn] = script

                UIHelper.BindUIEvent(script.BtnPoetryIcon, EventType.OnTouchBegan, function()
                    DataModel.bAutoClick = true
                    self.LastBtn = scriptBtn
                    self:SelectWord(script)
                end)
                UIHelper.BindUIEvent(script.BtnPoetryIcon, EventType.OnTouchMoved, function(bnt, nX, nY)
                    self:MoveCursor(nX, nY)
                end)
                UIHelper.BindUIEvent(script.BtnPoetryIcon, EventType.OnTouchEnded, function()
                    DataModel.bAutoClick = false
                    self.LastBtn = nil
                end)
                UIHelper.BindUIEvent(script.BtnPoetryIcon, EventType.OnTouchCanceled, function()
                    DataModel.bAutoClick = false
                    self.LastBtn = nil
                end)
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutWidgetPoetry)
    self:UpdateFinishPoetry()
end

function UIPanelPoetry:UpdateAllWordState()
    for _, script in ipairs(self.tAllWordScripts) do
        self:UpdateWordModState(script)
    end
end

function UIPanelPoetry:UpdateFinishPoetry()
    local nCount, nTotalCount = DataModel.GetFinishCount()
    UIHelper.SetLabel(self.LabelContent, szHintPrefix .. " " .. nCount .. "/" .. nTotalCount)
end

local function CheckWord(hWord)
    local nPos = #DataModel.tOperatePos + 1
    for nIndex, v in pairs(DataModel.tPoetryAnswer) do
        if (not DataModel.nCurAnswerIndex or DataModel.nCurAnswerIndex == nIndex)
                and v[nPos] and v[nPos][1] == hWord.x and v[nPos][2] == hWord.y then
            return true, nIndex, nPos == #v
        end
    end
    return false
end

function UIPanelPoetry:SelectWord(wordScript)
    if not wordScript or not wordScript.x or not wordScript.y then
        return
    end

    local nState = DataModel.GetWordState(wordScript.x, wordScript.y)
    if nState == WORD_STATE.SELECT or nState == WORD_STATE.CORRECT then
        --DataModel.bAutoClick = false
        return
    end

    local bCorrect, nAnswerIndex, bFinished = CheckWord(wordScript)
    if bCorrect then
        DataModel.nCurAnswerIndex = nAnswerIndex
        table.insert(DataModel.tOperatePos, wordScript.x .. "_" .. wordScript.y)
        table.insert(DataModel.tOperateKey, wordScript.szKey)
        DataModel.SetWordState(wordScript.x, wordScript.y, WORD_STATE.SELECT)
        if bFinished then
            if MiniGame.bDebugMode then
                DataModel.SetWordState(wordScript.x, wordScript.y, WORD_STATE.SELECT)
                DataModel.tAnswerInfo[nAnswerIndex].bFinish = true
                self:UpdateFinishPoetry()
                DataModel.tOperatePos = {}
            else
                local szSequence = table.concat(DataModel.tOperatePos, ";")
                RemoteCallToServer("On_LianShi_Check", { nType = DataModel.nType, szSequence = szSequence, nAnswerIndex = nAnswerIndex, x = wordScript.x, y = wordScript.y })
            end
            DataModel.nCurAnswerIndex = nil
        else
            DataModel.SetWordState(wordScript.x, wordScript.y, WORD_STATE.SELECT)
            DataModel.nFailedTimes = 0
            self:HideHint()
        end
    else
        DataModel.tLastWrongPos = { x = wordScript.x, y = wordScript.y }
        DataModel.SetWordState(wordScript.x, wordScript.y, WORD_STATE.WRONG)
        DataModel.nFailedTimes = DataModel.nFailedTimes + 1
        if DataModel.nFailedTimes >= MAX_FAILED_TIMES then
            self:ShowHint()
        end
    end
    self:UpdateWordModState(wordScript)
end

function UIPanelPoetry:UpdateWordModState(hWord)
    local szWrong = "UIAtlas2_LittleGame_Poetry_icon_wrong.png"
    local szCorrect = DataModel.GetWordCorrectFrame(hWord.x, hWord.y)
    local szNormal = "UIAtlas2_LittleGame_Poetry_icon_normal.png"
    local szSelect = "UIAtlas2_LittleGame_Poetry_bg_select.png"
    local szHint = "UIAtlas2_LittleGame_Poetry_bg_red.png"
    local nState = DataModel.GetWordState(hWord.x, hWord.y)

    local szFinalPath
    if nState == WORD_STATE.CORRECT then
        szFinalPath = szCorrect
    elseif nState == WORD_STATE.WRONG then
        szFinalPath = szWrong
    elseif nState == WORD_STATE.HINT then
        szFinalPath = szHint
    elseif nState == WORD_STATE.SELECT then
        szFinalPath = szSelect
    else
        szFinalPath = szNormal
    end
   
    if nState == WORD_STATE.SELECT and not hWord.isPlaying then
        UIHelper.PlayAni(hWord,hWord.SFXSelect, "AniPoetryPrompt", nil,2)
        hWord.isPlaying = true
    elseif nState ~= WORD_STATE.SELECT and hWord.isPlaying then
        UIHelper.StopAni(hWord,hWord.SFXSelect, "AniPoetryPrompt")
        hWord.isPlaying = false
    end

    UIHelper.SetSpriteFrame(hWord.ImgBg, szFinalPath)
    UIHelper.SetActiveAndCache(self, hWord.SFXSelect, nState == WORD_STATE.SELECT)
    UIHelper.SetActiveAndCache(self, hWord.ImgBg, nState ~= WORD_STATE.SELECT)

    if nState == WORD_STATE.WRONG then
        UIHelper.PlayAni(hWord, hWord.AniAll, "AniPoetryWrong")
        Timer.Add(self, 0.16, function()
            if nState == WORD_STATE.WRONG then
                if DataModel.IsWordInHint(hWord.x, hWord.y) then
                    DataModel.SetWordState(hWord.x, hWord.y, WORD_STATE.HINT)
                else
                    DataModel.SetWordState(hWord.x, hWord.y, WORD_STATE.NONE)
                end
                self:UpdateWordModState(hWord)
            end
        end)
    end
end

function UIPanelPoetry:Update(tInfo)
    if tInfo.bSuccess then
        local szSequence = tInfo.szSequence
        local tPosList = SplitString(szSequence, ";")
        for _, v in pairs(tPosList) do
            local tPos = SplitString(v, "_")
            DataModel.SetWordState(tonumber(tPos[1]), tonumber(tPos[2]), WORD_STATE.CORRECT)
        end

        DataModel.tAnswerInfo[tInfo.nAnswerIndex].bFinish = true
        self:UpdateFinishPoetry()
        DataModel.tOperatePos = {}
        DataModel.nFailedTimes = 0
        self:HideHint()
    else
        local szSequence = tInfo.szSequence
        local tPosList = SplitString(szSequence, ";")
        for _, v in pairs(tPosList) do
            local tPos = SplitString(v, "_")
            DataModel.SetWordState(tonumber(tPos[1]), tonumber(tPos[2]), WORD_STATE.WRONG)
        end
        DataModel.tOperatePos = {}
        DataModel.nFailedTimes = DataModel.nFailedTimes + 1
        if DataModel.nFailedTimes >= MAX_FAILED_TIMES then
            self:ShowHint()
        end
    end
    self:UpdateAllWordState()
end

function UIPanelPoetry:ShowHint()
    self:HideHint()

    local nCurAnswerIndex = DataModel.GetHintAnswer()
    local tAnswer = DataModel.tPoetryAnswer[nCurAnswerIndex]
    if not tAnswer then
        print("No Hint Answer Index: " .. nCurAnswerIndex)
        return
    end

    for _, v in pairs(tAnswer) do
        local nState = DataModel.GetWordState(v[1], v[2])
        if nState ~= WORD_STATE.CORRECT and nState ~= WORD_STATE.SELECT then
            if nState == WORD_STATE.WRONG then
                DataModel.tWordState[v[1]][v[2]].bHint = true
            else
                DataModel.SetWordState(v[1], v[2], WORD_STATE.HINT)
            end
        end
    end
    self:UpdateAllWordState()
end

function UIPanelPoetry:HideHint()
    for _, script in ipairs(self.tAllWordScripts) do
        local nState = DataModel.GetWordState(script.x, script.y)
        if nState == WORD_STATE.HINT then
            DataModel.SetWordState(script.x, script.y, WORD_STATE.NONE)
        end
        self:UpdateWordModState(script)
    end
end

function UIPanelPoetry:UpdateTime()
    if not DataModel.nStartTime then
        return
    end

    local nTime = GetCurrentTime() - DataModel.nStartTime
    local szTime = UIHelper.GetCoolTimeText(nTime)
    UIHelper.SetLabel(self.LabelTime, szTime)
end

return UIPanelPoetry