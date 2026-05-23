MahjongAnimHelper = MahjongAnimHelper or {}
local tbInitOffset = {
    [tUIPosIndex.Down] = {nX = 0, nY = 100},
    [tUIPosIndex.Up] = {nX = 0, nY = 100},
    [tUIPosIndex.Left] = {nX = 0, nY = 20},
    [tUIPosIndex.Right] = {nX = 0, nY = 20},
}

local tbDisCardOffset = {
    [tUIPosIndex.Down] = {nX = 0, nY = -100},
    [tUIPosIndex.Up] = {nX = 0, nY = 100},
    [tUIPosIndex.Left] = {nX = -50, nY = 0},
    [tUIPosIndex.Right] = {nX = 50, nY = 0},
}

local tbDisAddNumberOffset = {
    [tUIPosIndex.Down] = {nX = 0, nY = 300},
    [tUIPosIndex.Up] = {nX = 0, nY = -300},
    [tUIPosIndex.Left] = {nX = 300, nY = 0},
    [tUIPosIndex.Right] = {nX = -300, nY = 0},
}

function MahjongAnimHelper.PlayInitCardAnim(tbNode, Layout, nUIDirection, funcEndCallback)
    if not tbNode or #tbNode == 0 then
        if safe_check(Layout) then UIHelper.CascadeDoLayoutDoWidget(Layout, true, true) end
        if funcEndCallback then funcEndCallback() end
        return
    end

    for nIndex = #tbNode, 1, -1 do
        local node = tbNode[nIndex]
        if safe_check(node) then
            UIHelper.SetOpacity(node, 0)
        else
            table.remove(tbNode, nIndex)
        end
    end

    local nStartIndex = 1
    local function PlayAnim()
        local tbPlayAnimNode = {}
        for nIndex = nStartIndex, nStartIndex + 3 do
            local node = tbNode[nIndex]
            if safe_check(node) then
                table.insert(tbPlayAnimNode, tbNode[nIndex])
            end
        end
        MahjongAnimHelper.PlayCardInAnim(tbPlayAnimNode, Layout, nUIDirection, nil, function()
            nStartIndex = nStartIndex + 4
            if nStartIndex > #tbNode then
                if funcEndCallback then
                    funcEndCallback()
                end
            else
                PlayAnim()
            end
        end)
    end
    PlayAnim()
end


function MahjongAnimHelper.PlayCardInAnim(tbNode, Layout, nUIDirection, funcCallback, funcEndCallBack)

    if not tbNode or #tbNode == 0 then
        if safe_check(Layout) then UIHelper.CascadeDoLayoutDoWidget(Layout, true, true) end
        if funcEndCallBack then funcEndCallBack() end
        return
    end

    for nIndex = #tbNode, 1, -1 do
        local node = tbNode[nIndex]
        if not safe_check(node) then
            table.remove(tbNode, nIndex)
        end
    end

    if #tbNode == 0 then
        if funcEndCallBack then funcEndCallBack() end
        return
    end


    for index, node in ipairs(tbNode) do
        UIHelper.SetVisible(node, true)
    end

    if safe_check(Layout) then
        UIHelper.CascadeDoLayoutDoWidget(Layout, true, true)
    end

    for nIndex, node in ipairs(tbNode) do
        if safe_check(node) then
            local fadeTo = cc.FadeTo:create(0, 255)
            node:runAction(fadeTo)
            local nX, nY = node:getPosition()
            local nStartX = nX + tbInitOffset[nUIDirection].nX
            local nStartY = nY + tbInitOffset[nUIDirection].nY

            local function callback()
                if funcCallback then
                    funcCallback()
                end
                if nIndex == #tbNode and funcEndCallBack  then
                    funcEndCallBack()
                end
            end
            MahjongAnimHelper.MoveNode(node, {x = nStartX, y = nStartY}, {x = nX, y = nY}, 0.3, callback)
        end
    end
end



---牌移出手牌队列
function MahjongAnimHelper.PlayCardOutAnim(tbNode, nUIDirection, funcCallback, funcEndCallBack)

    if not tbNode or #tbNode == 0 then
        if funcEndCallBack then funcEndCallBack() end
        return
    end

    for nIndex = #tbNode, 1, -1 do
        local node = tbNode[nIndex]
        if not safe_check(node) then
            table.remove(tbNode, nIndex)
        end
    end

    if #tbNode == 0 then
        if funcEndCallBack then funcEndCallBack() end
        return
    end


    for nIndex, node in ipairs(tbNode) do

        local function callback()
            UIHelper.SetVisible(node, false)
            if funcCallback then
                funcCallback()
            end
            if nIndex == #tbNode and funcEndCallBack  then
                funcEndCallBack()
            end
        end

        if nUIDirection == tUIPosIndex.Down then

            local fadeTo = cc.FadeTo:create(0.2, 0)
            node:runAction(fadeTo)

            local nX, nY = 0, 0
            if safe_check(node) then
                nX, nY = node:getPosition()
            end
            MahjongAnimHelper.MoveNode(node, {x = nX, y = nY}, {x = nX, y = nY + 100}, 0.2, callback)
        else
            local fadeto = cc.FadeTo:create(0.2, 0)
            local callfunc = cc.CallFunc:create(function()
                 callback()
            end)
            local sequence = cc.Sequence:create(fadeto, callfunc)
            node:runAction(sequence)
        end
    end
end


function MahjongAnimHelper.PlayDisCardAnim(node, nUIDirection, funcCallback)
    if safe_check(node) then

        UIHelper.SetOpacity(node, 0)
        local fadeto = cc.FadeTo:create(0.2, 255)
        node:runAction(fadeto)

        local nX, nY = node:getPosition()
        local nStartX = nX + tbDisCardOffset[nUIDirection].nX
        local nStartY = nY + tbDisCardOffset[nUIDirection].nY
        MahjongAnimHelper.MoveNode(node, {x = nStartX, y = nStartY}, {x = nX, y = nY}, 0.2, funcCallback)
    end
end


function MahjongAnimHelper.PlayAddNumerEffects(node, nUIDirection, nTime, funcCallback)
    if safe_check(node) then
        MahjongAnimHelper.ScaleNode(node, 1, 2, nTime, funcCallback)
    end
end


function MahjongAnimHelper.PlayDiceEffects(tbNode, nTime, funcCallback)
    for nIndex, node in ipairs(tbNode) do
        if safe_check(node) then
            local nRotation = UIHelper.GetRotation(node)
            local rotateby = cc.RotateBy:create(0.3, 360)
            local repeate = cc.Repeat:create(rotateby, math.ceil(nTime / 0.3))
            local callback = cc.CallFunc:create(function()
                if nIndex == #tbNode and funcCallback then funcCallback() end
            end)
            local sequence = cc.Sequence:create(repeate, callback)
            node:stopAction(sequence)
            node:runAction(sequence)
        end
    end
end


function MahjongAnimHelper.MoveNode(node, tbStartPos, tbEndPos, nTime, funcCallback)
    if safe_check(node) then
        local movetoStart = cc.MoveTo:create(0, tbStartPos)
        local movetoEnd = cc.MoveTo:create(nTime, tbEndPos)
        local callback = cc.CallFunc:create(function()
            if funcCallback then
                funcCallback()
            end
        end)
        local sequence = cc.Sequence:create(movetoStart, movetoEnd, callback)
        node:runAction(sequence)
    end
end

function MahjongAnimHelper.FadeNode(node, nOpacity, nTime, funcCallback)
    UIHelper.FadeNode(node, nOpacity, nTime, funcCallback)
end

function MahjongAnimHelper.ScaleNode(node, nStartScale, nEndScale, nTime, funcCallback)
    if safe_check(node) then
        local scaletoStart = cc.ScaleTo:create(0, nStartScale)
        local scaletoEnd = cc.ScaleTo:create(nTime, nEndScale)
        local callback = cc.CallFunc:create(function()
            if funcCallback then
                funcCallback()
            end
        end)
        local sequence = cc.Sequence:create(scaletoStart, scaletoEnd, callback)
        node:runAction(sequence)
    end
end

