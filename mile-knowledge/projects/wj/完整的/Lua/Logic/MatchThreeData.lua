-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: MatchThreeData
-- Date: 2025-12-22 10:52:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

MatchThreeData = MatchThreeData or {className = "MatchThreeData"}
local self = MatchThreeData

local SimpleRandomCounter = 0
local SimpleRandomState = nil
local BOARD_SIZE   = 6
local COLORS       = { "gold", "purple", "blue", "red" }
local MAX_ENERGY   = 20
local MAX_SCORE    = 9999999

----------------------------------------------------------------------
-- 状态
----------------------------------------------------------------------

local tbBoard        = {}   -- tbBoard[row][col] = "gold"/"purple"/...
local tbSelectedCell = nil  -- { row, col }
local tbEnergy       = { gold = 0, purple = 0, blue = 0, red = 0 }
local bIsAnimating  = false
local nScore        = 0
local nComboCount   = 0
local bGameEnded    = false
local bGameStarted  = false
local nStep = 50
local nSettlementDropCount = 0
local bMute = false

local bSubmitOnLoadingEnd = false

local function notifyBoardChanged(tbBeforeDropBoard, tbAfterDropBoard, bInit)
    Event.Dispatch("MatchThree_BoardChanged", clone(tbBoard), tbBeforeDropBoard, tbAfterDropBoard, bInit)
end

local function notifyBoardCellSwap(tbCell1, tbCell2)
    Event.Dispatch("MatchThree_BoardCellSwap", tbCell1, tbCell2, clone(tbBoard))
end

local function notifyScoreChanged()
    Event.Dispatch("MatchThree_ScoreChanged", nScore)
end

local function notifyEnergyChanged(szColor)
    Event.Dispatch("MatchThree_EnergyChanged", szColor, tbEnergy[szColor], MAX_ENERGY)
end

local function notifyAllEnergyChanged()
    Event.Dispatch("MatchThree_AllEnergyChanged", clone(tbEnergy), MAX_ENERGY)
end

local function notifySettlementEnd()
    Event.Dispatch("MatchThree_SettlementEnd", nSettlementDropCount or 0)
end

local function isValidPos(nRow, nCol)
    return nRow >= 1 and nRow <= BOARD_SIZE and nCol >= 1 and nCol <= BOARD_SIZE
end

local function isAdjacent(nRow1, nCol1, nRow2, nCol2)
    return (math.abs(nRow1 - nRow2) == 1 and nCol1 == nCol2)
        or (math.abs(nCol1 - nCol2) == 1 and nRow1 == nRow2)
end

local function addEnergy(szColor, nAmount)
    tbEnergy[szColor] = math.min((tbEnergy[szColor] or 0) + nAmount, MAX_ENERGY)
    notifyEnergyChanged(szColor)
end

local function getMiddleCell(tbCells)
    if not tbCells or #tbCells == 0 then
        return nil
    end
    local tmp = {}
    for i = 1, #tbCells do
        local c = tbCells[i]
        if c and c.row and c.col then
            tmp[#tmp + 1] = { row = c.row, col = c.col }
        end
    end
    if #tmp == 0 then
        return nil
    end
    table.sort(tmp, function(a, b)
        if a.row ~= b.row then
            return a.row < b.row
        end
        return a.col < b.col
    end)
    return tmp[math.floor((#tmp + 1) / 2)]
end

local function notifyEliminateScore(tbCells, nAddScore)
    if not nAddScore or nAddScore <= 0 then
        return
    end
    local mid = getMiddleCell(tbCells)
    if not mid then
        return
    end
    Event.Dispatch("MatchThree_ShowEliminateScore", mid.row, mid.col, nAddScore)
end

local function SeedOnce()
    local M = 2147483647
    SimpleRandomCounter = (SimpleRandomCounter + 1) % M

    local t1 = os.time() or 0
    local t2 = os.clock() or 0
    local t2i = math.floor(t2 * 1000000) % M

    local addr = tostring({}):match("0x(%x+)")
    local a = addr and (tonumber(addr, 16) % M) or 0

    local seed = (t1 * 48271 + t2i * 16807 + a + SimpleRandomCounter) % M
    if seed <= 0 then seed = 1 end
    SimpleRandomState = seed
end

local function NextI31()
    local M = 2147483647
    if not SimpleRandomState then
        SeedOnce()
    end
    SimpleRandomCounter = (SimpleRandomCounter + 1) % M
    SimpleRandomState = (SimpleRandomState * 16807 + SimpleRandomCounter) % M
    if SimpleRandomState <= 0 then
        SimpleRandomState = 1
    end
    return SimpleRandomState
end

local function UniformInt1N(n)
    local M = 2147483647
    if n <= 1 then return 1 end
    local limit = M - (M % n)
    local x = NextI31()
    while x >= limit do
        x = NextI31()
    end
    return (x % n) + 1
end

local function SimpleRandom(a, b)
    if a == nil and b == nil then
        return NextI31() / 2147483647
    end
    if b == nil then
        return UniformInt1N(tonumber(a) or 0)
    end

    local minv = tonumber(a) or 0
    local maxv = tonumber(b) or 0
    if maxv < minv then minv, maxv = maxv, minv end

    local range = maxv - minv + 1
    if range <= 1 then return minv end
    return minv + UniformInt1N(range) - 1
end

local function getRandomColor()
    local nIndex = SimpleRandom(#COLORS)
    return COLORS[nIndex]
end

local function isPartOfMatch(nRow, nCol)
    local szColor = tbBoard[nRow][nCol]
    if not szColor then return false end

    -- 横向
    local nHorizontalCount = 1
    local nLeft = nCol - 1
    while nLeft >= 1 and tbBoard[nRow][nLeft] == szColor do
        nHorizontalCount = nHorizontalCount + 1
        nLeft = nLeft - 1
    end
    local nRight = nCol + 1
    while nRight <= BOARD_SIZE and tbBoard[nRow][nRight] == szColor do
        nHorizontalCount = nHorizontalCount + 1
        nRight = nRight + 1
    end

    -- 纵向
    local nVerticalCount = 1
    local nUp = nRow - 1
    while nUp >= 1 and tbBoard[nUp][nCol] == szColor do
        nVerticalCount = nVerticalCount + 1
        nUp = nUp - 1
    end
    local nDown = nRow + 1
    while nDown <= BOARD_SIZE and tbBoard[nDown][nCol] == szColor do
        nVerticalCount = nVerticalCount + 1
        nDown = nDown + 1
    end

    return nHorizontalCount >= 3 or nVerticalCount >= 3
end

local function hasMatches()
    for i = 1, BOARD_SIZE do
        for j = 1, BOARD_SIZE do
            if tbBoard[i][j] and isPartOfMatch(i, j) then
                return true
            end
        end
    end
    return false
end

local function swapCells(r1, c1, r2, c2)
    tbBoard[r1][c1], tbBoard[r2][c2] = tbBoard[r2][c2], tbBoard[r1][c1]
end

local function hasAnyPossibleMove()
    for i = 1, BOARD_SIZE do
        for j = 1, BOARD_SIZE do
            if j < BOARD_SIZE then
                swapCells(i, j, i, j + 1)
                local has = hasMatches()
                swapCells(i, j, i, j + 1)
                if has then return true end
            end
            if i < BOARD_SIZE then
                swapCells(i, j, i + 1, j)
                local has = hasMatches()
                swapCells(i, j, i + 1, j)
                if has then return true end
            end
        end
    end
    return false
end

local function ensureSolvable()
    local tries = 0
    local maxTry = 100

    local function pickOther(sz)
        for _, c in ipairs(COLORS) do
            if c ~= sz then return c end
        end
        return sz
    end

    local function tryHorizontal()
        local i = SimpleRandom(2, BOARD_SIZE - 1)
        local j = SimpleRandom(1, BOARD_SIZE - 2)
        local t = getRandomColor()

        local a1 = tbBoard[i][j]
        local a2 = tbBoard[i][j + 2]
        local a3 = tbBoard[i][j + 1]
        local a4 = tbBoard[i - 1][j + 1]

        tbBoard[i][j] = t
        tbBoard[i][j + 2] = t
        if a3 == t then tbBoard[i][j + 1] = pickOther(t) end
        tbBoard[i - 1][j + 1] = t

        local ok = (not hasMatches()) and hasAnyPossibleMove()
        if not ok then
            tbBoard[i][j] = a1
            tbBoard[i][j + 2] = a2
            tbBoard[i][j + 1] = a3
            tbBoard[i - 1][j + 1] = a4
        end
        return ok
    end

    local function tryVertical()
        local i = SimpleRandom(1, BOARD_SIZE - 2)
        local j = SimpleRandom(2, BOARD_SIZE - 1)
        local t = getRandomColor()

        local b1 = tbBoard[i][j]
        local b2 = tbBoard[i + 2][j]
        local b3 = tbBoard[i + 1][j]
        local b4 = tbBoard[i + 1][j - 1]

        tbBoard[i][j] = t
        tbBoard[i + 2][j] = t
        if b3 == t then tbBoard[i + 1][j] = pickOther(t) end
        tbBoard[i + 1][j - 1] = t

        local ok = (not hasMatches()) and hasAnyPossibleMove()
        if not ok then
            tbBoard[i][j] = b1
            tbBoard[i + 2][j] = b2
            tbBoard[i + 1][j] = b3
            tbBoard[i + 1][j - 1] = b4
        end
        return ok
    end

    while tries < maxTry do
        if tryHorizontal() or tryVertical() then
            return
        end
        tries = tries + 1
    end
end

local function composeSolvableBoard()
    for i = 1, BOARD_SIZE do
        tbBoard[i] = {}
        for j = 1, BOARD_SIZE do
            tbBoard[i][j] = nil
        end
    end

    local r = 2
    local c = 2

    local function pickOther(sz)
        for _, cc in ipairs(COLORS) do
            if cc ~= sz then return cc end
        end
        return sz
    end

    local t = COLORS[SimpleRandom(#COLORS)]
    local tp = pickOther(t)

    tbBoard[r][c] = t
    tbBoard[r][c + 2] = t
    tbBoard[r][c + 1] = tp
    tbBoard[r - 1][c + 1] = t

    local function chooseCandidate(i, j)
        local candidates = {}
        for _, cc in ipairs(COLORS) do candidates[#candidates + 1] = cc end

        if j >= 3 then
            local a = tbBoard[i][j - 1]
            local b = tbBoard[i][j - 2]
            if a ~= nil and b ~= nil and a == b then
                local banned = a
                local kept = {}
                for _, cc in ipairs(candidates) do
                    if cc ~= banned then kept[#kept + 1] = cc end
                end
                candidates = kept
            end
        end

        if i >= 3 then
            local a = tbBoard[i - 1][j]
            local b = tbBoard[i - 2][j]
            if a ~= nil and b ~= nil and a == b then
                local banned = a
                local kept = {}
                for _, cc in ipairs(candidates) do
                    if cc ~= banned then kept[#kept + 1] = cc end
                end
                candidates = kept
            end
        end

        if #candidates == 0 then
            for _, cc in ipairs(COLORS) do
                if cc ~= tbBoard[i][j - 1] and cc ~= tbBoard[i - 1][j] then
                    return cc
                end
            end
            return COLORS[1]
        end

        return candidates[SimpleRandom(#candidates)]
    end

    for i = 1, BOARD_SIZE do
        for j = 1, BOARD_SIZE do
            if tbBoard[i][j] == nil then
                tbBoard[i][j] = chooseCandidate(i, j)
            end
        end
    end

    while hasMatches() do
        for i = 1, BOARD_SIZE do
            for j = 1, BOARD_SIZE do
                if tbBoard[i][j] and isPartOfMatch(i, j) then
                    tbBoard[i][j] = chooseCandidate(i, j)
                end
            end
        end
    end
end

local function fixIfUnsolvable()
    if not hasAnyPossibleMove() then
        ensureSolvable()
        if hasMatches() or (not hasAnyPossibleMove()) then
            composeSolvableBoard()
        end
    end
end

function MatchThreeData.InitGame()
    tbBoard = {}
    for i = 1, BOARD_SIZE do
        tbBoard[i] = {}
        for j = 1, BOARD_SIZE do
            tbBoard[i][j] = getRandomColor()
        end
    end

    while hasMatches() do
        for i = 1, BOARD_SIZE do
            for j = 1, BOARD_SIZE do
                if isPartOfMatch(i, j) then
                    tbBoard[i][j] = getRandomColor()
                end
            end
        end
    end

    tbEnergy      = { gold = 0, purple = 0, blue = 0, red = 0 }
    bIsAnimating = false
    nScore       = 0
    nComboCount  = 0
    bGameEnded   = false
    bGameStarted = false
    tbSelectedCell = nil

    nStep = 50

    notifyBoardChanged(nil, nil, true)
    notifyAllEnergyChanged()
    -- notifyScoreChanged()
end

function MatchThreeData.RestartGame()
    bGameEnded   = false
    bGameStarted = false
    bIsAnimating = false
    nScore       = 0
    nComboCount  = 0
    tbEnergy      = { gold = 0, purple = 0, blue = 0, red = 0 }
    nStep = 50
    MatchThreeData.InitGame()
end

function MatchThreeData.StartGame()
    bGameStarted = true
end


local function expandConnectedSameColorFromGroup(tbGroup, tbBaseSet)
    local szColor = tbGroup.szColor
    local queue = {}
    local visited = {}
    local result = {}

    local function keyOf(r, c)
        return r .. "," .. c
    end

    local function push(r, c)
        local k = keyOf(r, c)
        if visited[k] then return end
        visited[k] = true
        queue[#queue + 1] = { row = r, col = c }
    end

    for _, m in ipairs(tbGroup.matches or {}) do
        if m and isValidPos(m.row, m.col) then
            push(m.row, m.col)
        end
    end

    local dirs = {
        { dr = -1, dc = 0 },
        { dr = 1,  dc = 0 },
        { dr = 0,  dc = -1 },
        { dr = 0,  dc = 1 },
    }

    local head = 1
    while head <= #queue do
        local cur = queue[head]
        head = head + 1

        for _, d in ipairs(dirs) do
            local nr, nc = cur.row + d.dr, cur.col + d.dc
            if isValidPos(nr, nc) and tbBoard[nr][nc] == szColor then
                local nk = keyOf(nr, nc)
                if not visited[nk] then
                    visited[nk] = true
                    queue[#queue + 1] = { row = nr, col = nc }

                    if not tbBaseSet[nk] then
                        result[#result + 1] = { row = nr, col = nc, szColor = szColor }
                    end
                end
            end
        end
    end

    return result
end


local function findAllMatches()
    local tbMatchesSet  = {}   -- key: "r,c" => true
    local tbMatchGroups = {}

    local function keyOf(r, c)
        return r .. "," .. c
    end

    for i = BOARD_SIZE, 1, -1 do
        for j = BOARD_SIZE, 1, -1 do
            local szColor = tbBoard[i][j]
            if szColor then
                local horizontal = { { row = i, col = j } }
                local k = j - 1
                while k <= BOARD_SIZE and k >= 1 and tbBoard[i][k] == szColor do
                    table.insert(horizontal, { row = i, col = k })
                    k = k - 1
                end
                if #horizontal >= 3 then
                    table.insert(tbMatchGroups, {
                        matches = horizontal,
                        szColor   = szColor,
                        count   = #horizontal,
                        type    = "horizontal"
                    })
                    for _, m in ipairs(horizontal) do
                        tbMatchesSet[keyOf(m.row, m.col)] = true
                    end
                end

                local vertical = { { row = i, col = j } }
                k = i - 1
                while k <= BOARD_SIZE and k >= 1 and tbBoard[k][j] == szColor do
                    table.insert(vertical, { row = k, col = j })
                    k = k - 1
                end
                if #vertical >= 3 then
                    table.insert(tbMatchGroups, {
                        matches = vertical,
                        szColor   = szColor,
                        count   = #vertical,
                        type    = "vertical"
                    })
                    for _, m in ipairs(vertical) do
                        tbMatchesSet[keyOf(m.row, m.col)] = true
                    end
                end
            end
        end
    end

    local result = {}
    for key, _ in pairs(tbMatchesSet) do
        local r, c = key:match("(%d+),(%d+)")
        r = tonumber(r)
        c = tonumber(c)
        if isValidPos(r, c) then
            table.insert(result, { row = r, col = c, szColor = tbBoard[r][c] })
        end
    end
    result.tbMatchGroups = tbMatchGroups
    result.tbBaseSet = tbMatchesSet
    return result
end

----------------------------------------------------------------------
-- 超级消除范围
----------------------------------------------------------------------

local function getSuperEffectCells(tbEffect)
    local tbCells = {}

    if tbEffect.type == "sameColor" then
        for i = 1, BOARD_SIZE do
            for j = 1, BOARD_SIZE do
                if tbBoard[i][j] == tbEffect.szColor then
                    table.insert(tbCells, { row = i, col = j })
                end
            end
        end
    end

    return tbCells
end

----------------------------------------------------------------------
-- 下落 / 填充
----------------------------------------------------------------------

local function dropCells()
    for col = 1, BOARD_SIZE do
        local emptyRow = BOARD_SIZE
        for row = BOARD_SIZE, 1, -1 do
            if tbBoard[row][col] ~= nil then
                if row ~= emptyRow then
                    tbBoard[emptyRow][col] = tbBoard[row][col]
                    tbBoard[row][col] = nil
                end
                emptyRow = emptyRow - 1
            end
        end
    end

    return clone(tbBoard)
end

local function wouldCreateMatch(row, col, szColor)
    local old = tbBoard[row][col]
    tbBoard[row][col] = szColor
    local b = isPartOfMatch(row, col)
    tbBoard[row][col] = old
    return b
end

local function fillBoard()
    for i = 1, BOARD_SIZE do
        for j = 1, BOARD_SIZE do
            if tbBoard[i][j] == nil then
                local newColor   = getRandomColor()
                local attempts   = 0
                local maxAttempt = 10

                while attempts < maxAttempt and wouldCreateMatch(i, j, newColor) do
                    newColor = getRandomColor()
                    attempts = attempts + 1
                end

                tbBoard[i][j] = newColor
            end
        end
    end

    fixIfUnsolvable()
end

local function eliminateMatchesAsync(matches, doneCallback)
    -- 统计能量
    local tbColorCount = { gold = 0, purple = 0, blue = 0, red = 0 }

    local tbMatchGroups = matches.tbMatchGroups or {}
    local tbBaseSet = matches.tbBaseSet or {}

    local function keyOf(r, c)
        return r .. "," .. c
    end

    local tbSuperEffects = {}
    for _, group in ipairs(tbMatchGroups) do
        if (group.type == "horizontal" or group.type == "vertical") and (group.count or 0) >= 5 then
            table.insert(tbSuperEffects, {
                type   = "sameColor",
                szColor = group.szColor,
                count  = group.count,
                from   = group.type,
            })
        end
    end

    local bHasSameColorSuper = (#tbSuperEffects > 0)

    local tbExtraSet = {}
    local tbExtraCells = {}

    if not bHasSameColorSuper then
        for _, group in ipairs(tbMatchGroups) do
            if group.type == "horizontal" or group.type == "vertical" then
                local expanded = expandConnectedSameColorFromGroup(group, tbBaseSet)
                for _, cell in ipairs(expanded) do
                    local k = keyOf(cell.row, cell.col)
                    if not tbExtraSet[k] then
                        tbExtraSet[k] = true
                        tbExtraCells[#tbExtraCells + 1] = cell
                    end
                end
            end
        end
    end

    for _, m in ipairs(matches) do
        if m.szColor and tbColorCount[m.szColor] ~= nil then
            tbColorCount[m.szColor] = tbColorCount[m.szColor] + 1
        end
    end
    if not bHasSameColorSuper then
        for _, c in ipairs(tbExtraCells) do
            local sz = c.szColor or (isValidPos(c.row, c.col) and tbBoard[c.row][c.col])
            if sz and tbColorCount[sz] ~= nil then
                tbColorCount[sz] = tbColorCount[sz] + 1
            end
        end
    end

    local baseCount  = #matches
    local extraCount = (not bHasSameColorSuper) and (#tbExtraCells) or 0
    local totalClear = baseCount + extraCount
    local baseScore  = baseCount * 10
    local bonusScore = 0

    if not bHasSameColorSuper then
        baseScore = totalClear * 10

        local multiBonus = math.max(0, totalClear - 3) * 20
        if multiBonus > 0 then
            bonusScore = bonusScore + multiBonus
        end
    else
        if baseCount > 3 then
            local multiBonus = (baseCount - 3) * 20
            bonusScore = bonusScore + multiBonus
        end
    end

    if nComboCount > 1 then
        local comboBonus = nComboCount * 30
        bonusScore = bonusScore + comboBonus
    end

    local totalScore = baseScore + bonusScore
    MatchThreeData.SetScore(nScore + totalScore)

    do
        local tbShowCells = {}
        for _, m in ipairs(matches) do tbShowCells[#tbShowCells + 1] = m end
        if not bHasSameColorSuper then
            for _, c in ipairs(tbExtraCells) do tbShowCells[#tbShowCells + 1] = c end
        end
        notifyEliminateScore(tbShowCells, totalScore)
    end

    Timer.Add(self, 0.2, function()
        for _, m in ipairs(matches) do
            if isValidPos(m.row, m.col) then
                tbBoard[m.row][m.col] = nil
            end
        end

        if not bHasSameColorSuper then
            for _, c in ipairs(tbExtraCells) do
                if isValidPos(c.row, c.col) then
                    tbBoard[c.row][c.col] = nil
                end
            end
            notifyBoardChanged()

            for szColor, v in pairs(tbColorCount) do
                if v > 0 then
                    addEnergy(szColor, v)
                end
            end
            if notifyAllEnergyChanged then
                notifyAllEnergyChanged()
            end
            if doneCallback then doneCallback() end
            return
        end

        notifyBoardChanged()

        local index = 1
        local function processNextSuper()
            local tbEffect = tbSuperEffects[index]
            if not tbEffect then
                for szColor, v in pairs(tbColorCount) do
                    if v > 0 then
                        addEnergy(szColor, v)
                    end
                end
                if notifyAllEnergyChanged then
                    notifyAllEnergyChanged()
                end
                if doneCallback then doneCallback() end
                return
            end

            Timer.Add(self, 0.2, function()
                Event.Dispatch("MatchThree_SameColor")
                Timer.Add(self, 0.2, function()
                    local cells = getSuperEffectCells(tbEffect)
                    local tbSuperColorCount = { gold = 0, purple = 0, blue = 0, red = 0 }

                    for _, c in ipairs(cells) do
                        if isValidPos(c.row, c.col) and tbBoard[c.row][c.col] then
                            local szColor = tbBoard[c.row][c.col]
                            if tbSuperColorCount[szColor] ~= nil then
                                tbSuperColorCount[szColor] = tbSuperColorCount[szColor] + 1
                            end
                        end
                    end

                    Timer.Add(self, 0.2, function()
                        for _, c in ipairs(cells) do
                            if isValidPos(c.row, c.col) then
                                tbBoard[c.row][c.col] = nil
                            end
                        end

                        for szColor, v in pairs(tbSuperColorCount) do
                            if v > 0 then
                                tbColorCount[szColor] = tbColorCount[szColor] + v
                            end
                        end

                        local clearedCount = #cells
                        local superBonus   = clearedCount * 50
                        if superBonus > 0 then
                            MatchThreeData.SetScore(nScore + superBonus)
                            notifyEliminateScore(cells, superBonus)
                        end

                        notifyBoardChanged()
                        index = index + 1
                        processNextSuper()
                    end)
                end)
            end)
        end

        processNextSuper()
    end)
end

local function triggerOneSkillIfAny(done)
    for _, szColor in ipairs(COLORS) do
        if (tbEnergy[szColor] or 0) >= MAX_ENERGY then
            Timer.Add(self, 0.1, function()
                MatchThreeData.UseSkill(szColor, function()
                    if done then done() end
                end)
            end)
            return true
        end
    end
    return false
end

local function processMatchesAsync(doneCallback)
    -- nComboCount = 0

    local function step()
        local matches = findAllMatches()
        if #matches == 0 then
            local function afterSkills()
                if doneCallback then doneCallback() end
            end
            local function checkAndTriggerSkillsAsync(cb)
                local idx = 1
                local function nextColor()
                    if idx > #COLORS then
                        if cb then cb() end
                        return
                    end
                    local szColor = COLORS[idx]
                    idx = idx + 1
                    if tbEnergy[szColor] >= MAX_ENERGY then
                        Timer.Add(self, 0.1, function()
                            MatchThreeData.UseSkill(szColor, function()
                                nextColor()
                            end)
                        end)
                    else
                        nextColor()
                    end
                end
                nextColor()
            end
            checkAndTriggerSkillsAsync(afterSkills)
            return
        end

        nComboCount = nComboCount + 1

        eliminateMatchesAsync(matches, function()
            local tbBeforeDropBoard = clone(tbBoard)
            local tbAfterDropBoard = dropCells()
            fillBoard()
            Timer.Add(self, 0.2, function()
                nSettlementDropCount = (nSettlementDropCount or 0) + 1
                notifyBoardChanged(tbBeforeDropBoard, tbAfterDropBoard)
                step()
            end)
        end)
    end

    step()
end

function MatchThreeData.ClickCell(row, col, callback)
    if bIsAnimating or bGameEnded or not bGameStarted then return true end
    if nStep <= 0 then return true end
    if not isValidPos(row, col) then return end

    if not tbSelectedCell then
        tbSelectedCell = { row = row, col = col }
        if callback then
            callback({ selected = tbSelectedCell })
        end
        return
    else
        local prev = tbSelectedCell
        tbSelectedCell = nil

        if isAdjacent(prev.row, prev.col, row, col) then
            bIsAnimating = true
            tbBoard[prev.row][prev.col], tbBoard[row][col] = tbBoard[row][col], tbBoard[prev.row][prev.col]
            -- notifyBoardChanged()
            notifyBoardCellSwap(
                { row = prev.row, col = prev.col, color = tbBoard[row][col] },
                { row = row,      col = col, color = tbBoard[prev.row][prev.col] },
                tbBoard
            )

            -- Timer.Add(self, 0.001, function()
                if hasMatches() then
                    nSettlementDropCount = 0
                    nStep = nStep - 1
                    nComboCount = 0
                    Event.Dispatch("MatchThree_SwapSuccess", nStep)
                    processMatchesAsync(function()
                        bIsAnimating = false
                        if callback then
                            callback({
                                validSwap = true,
                                tbBoard     = clone(tbBoard),
                                nScore     = nScore,
                                tbEnergy    = tbEnergy
                            })
                        end
                        Event.Dispatch("MatchThree_UpdateSwapCount", nStep)
                        notifySettlementEnd()
                    end)
                else
                    Timer.Add(self, 0.2, function ()
                        -- 交换无效，换回
                        tbBoard[prev.row][prev.col], tbBoard[row][col] = tbBoard[row][col], tbBoard[prev.row][prev.col]
                        -- notifyBoardChanged()
                        notifyBoardCellSwap(
                            { row = prev.row, col = prev.col, color = tbBoard[row][col] },
                            { row = row,      col = col, color = tbBoard[prev.row][prev.col] },
                            tbBoard
                        )
                        bIsAnimating = false
                        if callback then
                            callback({
                                validSwap = false,
                                tbBoard     = clone(tbBoard),
                                nScore     = nScore,
                                tbEnergy    = tbEnergy
                            })
                        end
                    end)
                end
            -- end)
        else
            -- 非相邻，仅视作重新选择
            tbSelectedCell = { row = row, col = col }
            if callback then
                callback({ selected = tbSelectedCell })
            end
        end
    end
end

local function getCrossPattern()
    -- local centerRow = math_random(2, BOARD_SIZE - 1)
    -- local centerCol = math_random(2, BOARD_SIZE - 1)
    local centerRow = SimpleRandom(BOARD_SIZE - 2) + 1
    local centerCol = SimpleRandom(BOARD_SIZE - 2) + 1
    local tbStartCell = { row = centerRow, col = centerCol }
    return {
        { row = centerRow,     col = centerCol     },
        { row = centerRow - 1, col = centerCol     },
        { row = centerRow + 1, col = centerCol     },
        { row = centerRow,     col = centerCol - 1 },
        { row = centerRow,     col = centerCol + 1 },
    }, tbStartCell
end

local function getTPattern()
    -- local topRow    = math_random(1, BOARD_SIZE - 2)
    -- local centerCol = math_random(2, BOARD_SIZE - 1)
    local topRow    = SimpleRandom(BOARD_SIZE - 2)
    local centerCol = SimpleRandom(BOARD_SIZE - 2) + 1
    local tbStartCell = { row = topRow, col = centerCol - 1 }
    return {
        { row = topRow,     col = centerCol - 1 },
        { row = topRow,     col = centerCol     },
        { row = topRow,     col = centerCol + 1 },
        { row = topRow + 1, col = centerCol     },
        { row = topRow + 2, col = centerCol     },
    }, tbStartCell
end

local function getIPattern()
    -- local isHorizontal = (math_random() < 0.5)
    local isHorizontal = (SimpleRandom() < 0.5)
    local cells = {}
    local tbStartCell = {}
    if isHorizontal then
        -- local row = math_random(1, BOARD_SIZE)
        local row = SimpleRandom(BOARD_SIZE)
        for col = 1, BOARD_SIZE do
            table.insert(cells, { row = row, col = col })
        end
        tbStartCell = { row = row, col = 1, isHorizontal = isHorizontal }
    else
        -- local col = math_random(1, BOARD_SIZE)
        local col = SimpleRandom(BOARD_SIZE)
        for row = 1, BOARD_SIZE do
            table.insert(cells, { row = row, col = col })
        end
        tbStartCell = { row = 1, col = col, isHorizontal = isHorizontal}
    end
    return cells, tbStartCell
end

local function getSquarePattern()
    -- local row = math_random(1, BOARD_SIZE - 1)
    -- local col = math_random(1, BOARD_SIZE - 1)
    local row = SimpleRandom(BOARD_SIZE - 1)
    local col = SimpleRandom(BOARD_SIZE - 1)
    local tbStartCell = { row = row, col = col }
    return {
        { row = row,     col = col     },
        { row = row,     col = col + 1 },
        { row = row + 1, col = col     },
        { row = row + 1, col = col + 1 },
    }, tbStartCell
end

local function eliminateSkillCellsAsync(cells, doneCallback)
    Timer.Add(self, 0.2, function()
        for _, c in ipairs(cells) do
            if isValidPos(c.row, c.col) then
                tbBoard[c.row][c.col] = nil
            end
        end
        notifyBoardChanged()
        if doneCallback then doneCallback() end
    end)
end

function MatchThreeData.UseSkill(szColor, doneCallback)
    if tbEnergy[szColor] < MAX_ENERGY then
        if doneCallback then doneCallback() end
        return
    end

    local tbNames = {
        gold   = { szHero = "康宴别", szSkillName = "大狮子吼" },
        purple = { szHero = "姜棠",   szSkillName = "决芳剑" },
        blue   = { szHero = "月嘉禾", szSkillName = "月朔观气" },
        red    = { szHero = "白鹊",   szSkillName = "长击·穿云" },
    }

    local cellsToRemove = {}
    local tbStartCell = {}

    if szColor == "gold" then
        cellsToRemove, tbStartCell = getSquarePattern()
    elseif szColor == "purple" then
        cellsToRemove, tbStartCell = getCrossPattern()
    elseif szColor == "blue" then
        cellsToRemove, tbStartCell = getTPattern()
    elseif szColor == "red" then
        cellsToRemove, tbStartCell = getIPattern()
    end

    local tbInfo = tbNames[szColor]
    if tbInfo then
        Event.Dispatch("MatchThree_SkillUsed", tbInfo.szHero, tbStartCell)    --技能提示
    end

    tbEnergy[szColor] = 0
    notifyEnergyChanged(szColor)

    Timer.Add(self, 0.2, function()

        if #cellsToRemove == 0 then
            if doneCallback then doneCallback() end
            return
        end

        local tbTypeCount = { gold = 0, purple = 0, blue = 0, red = 0 }
        for _, c in ipairs(cellsToRemove) do
            if isValidPos(c.row, c.col) then
                local t = tbBoard[c.row] and tbBoard[c.row][c.col]
                if t ~= nil and tbTypeCount[t] ~= nil then
                    tbTypeCount[t] = tbTypeCount[t] + 1
                end
            end
        end

        eliminateSkillCellsAsync(cellsToRemove, function()
            local nSkillScore = 100
            MatchThreeData.SetScore(nScore + nSkillScore)
            notifyEliminateScore(cellsToRemove, nSkillScore)

            for k, v in pairs(tbTypeCount) do
                if v > 0 then
                    addEnergy(k, v)
                end
            end

            local tbBeforeDropBoard = clone(tbBoard)
            local tbAfterDropBoard = dropCells()
            fillBoard()
            
            Timer.Add(self, 0.4, function()
                nSettlementDropCount = (nSettlementDropCount or 0) + 1
                notifyBoardChanged(tbBeforeDropBoard, tbAfterDropBoard)
                processMatchesAsync(function()
                    if doneCallback then doneCallback() end
                end)
            end)
        end)
    end)
end

function MatchThreeData.GetBoard()
    return clone(tbBoard)
end

function MatchThreeData.SetScore(nCurScore)
    if nCurScore > MAX_SCORE then
        nCurScore = MAX_SCORE
    end
    nScore = nCurScore
    notifyScoreChanged()
end

function MatchThreeData.GetScore()
    return nScore
end

function MatchThreeData.GetEnergy()
    return {
        gold   = tbEnergy.gold,
        purple = tbEnergy.purple,
        blue   = tbEnergy.blue,
        red    = tbEnergy.red,
    }
end

function MatchThreeData.IsGameStarted()
    return bGameStarted
end

function MatchThreeData.IsGameEnded()
    return bGameEnded
end

function MatchThreeData.OnClose()
    Timer.DelAllTimer(self)
    MatchThreeData.MarkSubmitOnNextLoadingEnd()
end

local REMOTE_LANTERN_FESTIVAL_GAME = 1213
local REMOTE_LANTERN_FESTIVAL_GAME_SCORE_POS = 0
local REMOTE_LANTERN_FESTIVAL_GAME_FLAG_POS = 4

function MatchThreeData.Init()
    Event.Reg(self, EventType.OnRoleLogin, function()
        Event.Reg(self, "LOADING_END", function()
            MatchThreeData.Apply()
        end, true)
    end)

    Event.Reg(self, "LOADING_END", function()
        if bSubmitOnLoadingEnd then
            bSubmitOnLoadingEnd = false
            MatchThreeData.SubmitScore(true)
        end
    end)

    Event.Reg(self, EventType.OnAccountLogout, function ()
        bSubmitOnLoadingEnd = false
    end)
end

function MatchThreeData.Apply()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    if not pPlayer.HaveRemoteData(REMOTE_LANTERN_FESTIVAL_GAME) then
        pPlayer.ApplyRemoteData(REMOTE_LANTERN_FESTIVAL_GAME)
    end
end

function MatchThreeData.GetHistoryScore()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    if not pPlayer.HaveRemoteData(REMOTE_LANTERN_FESTIVAL_GAME) then
        pPlayer.ApplyRemoteData(REMOTE_LANTERN_FESTIVAL_GAME)
    end

    local nScore = pPlayer.GetRemoteArrayUInt(REMOTE_LANTERN_FESTIVAL_GAME, REMOTE_LANTERN_FESTIVAL_GAME_SCORE_POS, 4)
    return nScore
end

function MatchThreeData.SubmitScore(bLoadingEnd)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nScore = MatchThreeData.GetScore()
    local nStep = MatchThreeData.GetSwapStepNum()
    if bLoadingEnd then
        Timer.Add(self, 1, function ()
            RemoteCallToServer("On_Activity_UpdateGameScore", nScore, nStep)
        end)
    else
        RemoteCallToServer("On_Activity_UpdateGameScore", nScore, nStep)
    end
    RemoteCallToServer("On_Activity_UpdateGameTimes")
end

function MatchThreeData.GetGameRewardFlag()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local nFlag = pPlayer.GetRemoteArrayUInt(REMOTE_LANTERN_FESTIVAL_GAME, REMOTE_LANTERN_FESTIVAL_GAME_FLAG_POS, 1)
    return nFlag
end

function MatchThreeData.IsShowGameStartHint()
    return clone(Storage.MatchThreeGame.bShowStartHint)
end

function MatchThreeData.HideGameStartHint()
    Storage.MatchThreeGame.bShowStartHint = false
    Storage.MatchThreeGame.Dirty()
end

function MatchThreeData.GetSwapStepNum()
    return nStep
end

function MatchThreeData.ClearSelectedCell()
    tbSelectedCell = nil
end

function MatchThreeData.SetBgmState(bMuteBgm)
    bMute = bMuteBgm
end

function MatchThreeData.GetBgmState()
    return bMute
end

function MatchThreeData.MarkSubmitOnNextLoadingEnd()
    bSubmitOnLoadingEnd = true
end