UINodeControl = {}
local self = UINodeControl
UINodeControl.tbUINodeData = {}
UINodeControl.bException = false
UINodeControl.bSwitch = true
UINodeControl.bDebug = false
-- 广度优先查找指定名称的子节点  排除不可见,不可交互节点

--UINodeControl.tbUINodeData[EventType.OnChangeSliderPercent][1]
function UINodeControl.printTab(tbInfo)
    -- body
    for index, value in pairs(tbInfo) do
        -- body
        print(index)
        print(value)
    end
end

function UINodeControl.FindChildByName(szName, root)
    local _tFindChildByNameCache = setmetatable({nil, nil, nil, nil, nil, nil, nil, nil}, {__mode = "v"})
    if not safe_check(root) then
        root = cc.Director:getInstance():getRunningScene()
    end
    local nBeg, nEnd = 1, 1
    _tFindChildByNameCache[nEnd] = root
    while nBeg <= nEnd do
        local node = _tFindChildByNameCache[nBeg]
        local children = node:getChildren()
        for _, child in ipairs(children) do
            if child:getName() == szName then
                return child
            end
            nEnd = nEnd + 1
            _tFindChildByNameCache[nEnd] = child
        end
        nBeg = nBeg + 1
    end
end

function self._FindLableNodeByText(root, szLableText)
    local _tFindLableNodeByText = setmetatable({nil, nil, nil, nil, nil, nil, nil, nil}, {__mode = "v"})
    if not root then
        root = cc.Director:getInstance():getRunningScene()
    end
    --print(root:getName())
    local nBeg, nEnd = 1, 1
    _tFindLableNodeByText[nEnd] = root
    while nBeg <= nEnd do
        local node = _tFindLableNodeByText[nBeg]
        local children = node:getChildren()
        for _, child in ipairs(children) do
            --判断该节点是否是lable Text是否是目标值
            if child.getString and string.find(child:getString(), szLableText) then
                LOG.INFO("Find lable:" .. child:getName() .. "Text:" .. child:getString())
                return child
            end
            nEnd = nEnd + 1
            _tFindLableNodeByText[nEnd] = child
        end
        nBeg = nBeg + 1
    end
end

function UINodeControl.PrintLableText(root)
    UINodeControl.DealWithException()
    local _tFindLableNodeByText = setmetatable({nil, nil, nil, nil, nil, nil, nil, nil}, {__mode = "v"})
    if not root then
        root = cc.Director:getInstance():getRunningScene()
    end
    --print(root:getName())
    local nBeg, nEnd = 1, 1
    _tFindLableNodeByText[nEnd] = root
    while nBeg <= nEnd do
        local node = _tFindLableNodeByText[nBeg]
        local children = node:getChildren()
        for _, child in ipairs(children) do
            --判断该节点是否是lable Text是否是目标值
            if child.getString then
                LOG.INFO(
                    "Find lable:  root:" ..
                        root:getName() .. "    node:" .. child:getName() .. "     Text:" .. child:getString()
                )
            --child:setString('test')
            end
            nEnd = nEnd + 1
            _tFindLableNodeByText[nEnd] = child
        end
        nBeg = nBeg + 1
    end
end

function UINodeControl.GetLableText(root, nCount)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local _tFindLableNodeByText = setmetatable({nil, nil, nil, nil, nil, nil, nil, nil}, {__mode = "v"})
    if not root then
        root = cc.Director:getInstance():getRunningScene()
    end
    local nBeg, nEnd = 1, 1
    _tFindLableNodeByText[nEnd] = root
    while nBeg <= nEnd do
        local node = _tFindLableNodeByText[nBeg]
        local children = node:getChildren()
        for _, child in ipairs(children) do
            --判断该节点是否是lable Text是否是目标值
            if child.getString then
                LOG.INFO(
                    "Find lable:  root:" ..
                        root:getName() .. "    node:" .. child:getName() .. "     Text:" .. child:getString()
                )
                if nCount == 1 then
                    return child:getString()
                else
                    nCount = nCount - 1
                end
            end
            nEnd = nEnd + 1
            _tFindLableNodeByText[nEnd] = child
        end
        nBeg = nBeg + 1
    end
    return false
end

function UINodeControl._isVisable(node)
    --当前节点或者父节点不可见则直接跳过 绑定事件时还未设置bVisible=false 因此需要在处理异常节点中操作
    if node.isVisible and not node:isVisible() then
        if UINodeControl.bDebug then
            OutputMessage("MSG_ANNOUNCE_YELLOW", " node can not visable")
        end
        return false
    end
    if node:getParent().isVisible and not node:getParent():isVisible() then
        if UINodeControl.bDebug then
            OutputMessage("MSG_ANNOUNCE_YELLOW", "node parent:can not visable")
        end
        return false
    end
    if not node:isTouchEnabled() then
        if UINodeControl.bDebug then
            OutputMessage("MSG_ANNOUNCE_YELLOW", "node can not Touch")
        end
        return false
    end
    return true
end

--内置 统一处理触发函数
function self._Trigger(tbUINodeInfo, ...)
    local nEventType = tbUINodeInfo.EventType
    if not UINodeControl._isVisable(tbUINodeInfo.node) then
        if UINodeControl.bDebug then
        --print(tbUINodeInfo.szNodeName..":can not visable")
        end
        return false
    end
    if tbUINodeInfo.EventType == EventType.OnClick then
        tbUINodeInfo.Trigger(tbUINodeInfo.node)
    elseif nEventType == EventType.OnSelectChanged then
        tbUINodeInfo.Trigger(tbUINodeInfo.node, 0)
    elseif nEventType == EventType.OnTouchBegan then
        -- func(btn, x, y)
    elseif nEventType == EventType.OnTouchMoved then
        -- func(btn, x, y)
    elseif nEventType == EventType.OnTouchEnded then
        -- func(btn, x, y)
    elseif nEventType == EventType.OnTouchCanceled then
        -- func(btn)
    elseif nEventType == EventType.OnLongPress then
        -- 长按的时间默认为1秒，如有特殊需求，可以设置btn:setLongPressDelay(3)
        -- func(btn)
    elseif nEventType == EventType.OnPersistentPress then
        -- func(btn, nCount)
    elseif nEventType == EventType.OnDragOver then
        -- func(btn)
    elseif nEventType == EventType.OnDragOut then
        -- func(btn)
    elseif nEventType == EventType.OnChangeSliderPercent then
        -- func(btn, ccui.SliderEventType nSliderEvent)
        --tbUINodeInfo.Trigger(tbUINodeInfo.node,ccui.SliderEventType.slideBallDown)
        local nCnt = ...
        --nCnt: 0或者nil 表示按下滑动条后立马抬起，1表示按下滑动条，2表示抬起滑动条
        if nCnt == nil or nCnt == 0 then
            tbUINodeInfo.Trigger(tbUINodeInfo.node, ccui.SliderEventType.slideBallDown)
            tbUINodeInfo.Trigger(tbUINodeInfo.node, ccui.SliderEventType.slideBallUp)
        elseif nCnt == 1 then
            --print('-----------test1')
            tbUINodeInfo.Trigger(tbUINodeInfo.node, ccui.SliderEventType.slideBallDown)
        elseif nCnt == 2 then
            --print('-----------test2')
            tbUINodeInfo.Trigger(tbUINodeInfo.node, ccui.SliderEventType.slideBallUp)
        end
    elseif nEventType == EventType.OnVideoStateChanged then
        -- func(btn, ccui.VideoPlayerEvent nVideoPlayerEvent)
    elseif nEventType == EventType.OnTurningPageView then
    -- func(btn)
    end
    return true
end

--按钮节点名称和按钮的Text来触发按钮点击事件
function UINodeControl.BtnTriggerByLable(szNodeName, szLableText, nCount)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnClick)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnClick]
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        if szNodeName == tbUINodeInfo.szNodeName and self._FindLableNodeByText(tbUINodeInfo.node, szLableText) then
            if nCount == 1 then
                return self._Trigger(tbUINodeInfo)
            end
            nCount = nCount - 1
        end
    end
    return false
end

--按钮节点名称和按钮节点的父节点名称来触发按钮点击事件
--nCount :第几个按钮
function UINodeControl.BtnTrigger(szNodeName, szParentNodeName, nCount)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnClick)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnClick]
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        if szNodeName == tbUINodeInfo.szNodeName then
            if not szParentNodeName then
                return self._Trigger(tbUINodeInfo)
            end
            local nodeParent = tbUINodeInfo.node:getParent()
            if szParentNodeName == nodeParent:getName() then
                if nCount == 1 then
                    return self._Trigger(tbUINodeInfo)
                end
                nCount = nCount - 1
            end
        end
    end
    return false
end

--按钮节点名称来触发
--nCount :第几个按钮
function UINodeControl.BtnTriggerByCnt(szNodeName, nCount)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnClick)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnClick]
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        if szNodeName == tbUINodeInfo.szNodeName then
            if nCount == 1 then
                return self._Trigger(tbUINodeInfo)
            end
            nCount = nCount - 1
        end
    end
    return false
end

--AniAll/WidgetAniRightTop/WidgetAnchorRightTop/BtnClose
--UINodeControl.BtnTriggerByPath("BtnClose","AniAll/WidgetAniRightTop/WidgetAnchorRightTop/BtnClose")
function UINodeControl.BtnTriggerByPath(szNodeName, szNodePath, nCount)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnClick)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnClick]
    local list_strPath = SearchPanel.StringSplit(szNodePath, "/")
    local nStrPathLen = #list_strPath
    local node = nil
    local nCounter = 0
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        node = tbUINodeInfo.node
        nCounter = 0
        for n, strPath in ipairs(list_strPath) do
            nCounter = n
            if list_strPath[nStrPathLen - n + 1] == node:getName() then
                node = node:getParent()
            else
                break
            end
        end
        if nCounter == nStrPathLen then
            if nCount == 1 then
                xpcall(
                    function()
                        return self._Trigger(tbUINodeInfo)
                    end,
                    function()
                        UINodeControl.bException = true
                    end
                )
                if UINodeControl.bException then
                    UINodeControl.bException = false
                    return false
                end
                return true
            end
            nCount = nCount - 1
        end
    end
    return false
end

--根据数据表中的索引触发事件
function UINodeControl.BtnTriggerByIndex(nIndex)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnClick)
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnClick]
    local tbUINodeInfo = tbBtnUINodeData[nIndex]
    if tbUINodeInfo then
        self._Trigger(tbUINodeInfo)
    end
    return false
end

--toggle因为结点命名不规范的原因,因此以父节点的父节点名称作为toggroup
--(null): =============szTogGroupName:ScrollViewAreanList==============
--(null): =============szTogGroupName:WidgetSettingsMultipleChoice==============
--UINodeControl.TogTriggerByIndex("WidgetSettingsMultipleChoice",1)
--触发单个tog -- 单选框/复选框
--(null): =============szTogGroupName:WidgetServerListCell==============
--/cmd --print(UINodeControl.TogTriggerByIndex("ScrollViewTab2",1))
--[[]]
function UINodeControl.TogTriggerByIndex(szToggleGroupName, nIndex, szToggleGroupParentName, bCheckBox)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnSelectChanged)
    local tbTogNodeData = UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggleGroupName]
    if not tbTogNodeData then
        LOG.INFO("no ToggleGroup:" .. szToggleGroupName)
        return false
    end

    if not szToggleGroupParentName then
        --不填默认用第一个
        for key, value in pairs(tbTogNodeData) do
            szToggleGroupParentName = key
            break
        end
    end

    local tbTogNodeAllData = tbTogNodeData[szToggleGroupParentName]
    if not tbTogNodeAllData then
        LOG.INFO("no ToggleGroup:" .. szToggleGroupName .. "szToggleGroupParentName:" .. szToggleGroupParentName)
        return false
    end

    --先变更UI再变更触发事件
    for n, tbUINodeInfo in ipairs(tbTogNodeAllData) do
        --其它tog设置为未选中 当前tog设置为选中
        if n == nIndex then
            --checkbox需要判断当前是否已经选中
            if bCheckBox then
                UIHelper.SetSelected(tbUINodeInfo.node, not UIHelper.GetSelected(tbUINodeInfo.node))
            else
                UIHelper.SetSelected(tbUINodeInfo.node, true)
            end
        elseif not bCheckBox then
            UIHelper.SetSelected(tbUINodeInfo.node, false)
        end
    end
    --[[]]
    local tbUINodeInfo = tbTogNodeAllData[nIndex]
    if not tbUINodeInfo then
        LOG.INFO(szToggleGroupName .. tostring(nIndex) .. " do not exist")
        return false
    end
    --tog有click事件和selectchange事件
    xpcall(
        function()
            return self._Trigger(tbUINodeInfo)
        end,
        function()
            UINodeControl.bException = true
        end
    )
    if UINodeControl.bException then
        UINodeControl.bException = false
        return false
    end
    return true
end

-- return list_tbNodeData
--szToggleGroupName:toggle父节点的父节点名称
-- 使用办法
--[[
local tbTogNodeData=UINodeControl.GetToggroup(szToggleGroupName)
for nIndex,tbUINodeInfo in ipairs(tbTogNodeData) do
    local szNodeName=tbUINodeInfo.szNodeName
    if szNodeName==

    UINodeControl.TogTriggerByToggle(szToggleGroupName,tbUINodeInfo.node)
    local tbTogNodeData2=UINodeControl.GetToggroup(tbUINodeInfo.szNodeName)
    for nIndex,tbUINodeInfo2 in ipairs(tbTogNodeData2) do
        
    end

end]]
function UINodeControl.GetToggroup(szToggleGroupName, szToggleGroupParentName)
    UINodeControl.DealWithException(EventType.OnSelectChanged)

    local tbTogNodeData = UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggleGroupName]
    if not tbTogNodeData then
        LOG.INFO("no ToggleGroup:" .. szToggleGroupName)
        return false
    end

    if not szToggleGroupParentName then
        --不填默认用第一个
        for key, value in pairs(tbTogNodeData) do
            szToggleGroupParentName = key
            break
        end
    end

    local tbTogNodeAllData = tbTogNodeData[szToggleGroupParentName]
    if not tbTogNodeAllData then
        LOG.INFO("no ToggleGroup:" .. szToggleGroupName .. "szToggleGroupParentName:" .. szToggleGroupParentName)
        return false
    end

    local tbNodeDataTemp = {}
    for nIndex, tbUINodeInfo in ipairs(tbTogNodeAllData) do
        if UINodeControl._isVisable(tbUINodeInfo.node) then
            table.insert(tbNodeDataTemp, tbUINodeInfo)
        end
    end
    --print(szToggleGroupName..":\tlen:"..#tbNodeDataTemp)
    return tbNodeDataTemp
end

--根据toggle触发单个tog 单选框/复选框
function UINodeControl.TogTriggerByToggle(szToggleGroupName, toggle,szToggleGroupParentName, bCheckBox)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnSelectChanged)
    local tbTogNodeData = UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggleGroupName]
    if not tbTogNodeData then
        LOG.INFO("no ToggleGroup:" .. szToggleGroupName)
        return false
    end

    if not szToggleGroupParentName then
        --不填默认用第一个
        for key, value in pairs(tbTogNodeData) do
            szToggleGroupParentName = key
            break
        end
    end

    local tbTogNodeAllData = tbTogNodeData[szToggleGroupParentName]
    if not tbTogNodeAllData then
        LOG.INFO("no ToggleGroup:" .. szToggleGroupName .. "szToggleGroupParentName:" .. szToggleGroupParentName)
        return false
    end

    --先变更UI再变更触发事件
    local nIndex = 0
    for n, tbUINodeInfo in ipairs(tbTogNodeAllData) do
        --其它tog设置为未选中 当前tog设置为选中
        if toggle == tbUINodeInfo.node then
            --tog有click事件和selectchange事件
            nIndex = n
            --checkbox需要判断当前是否已经选中
            if bCheckBox then
                UIHelper.SetSelected(tbUINodeInfo.node, not UIHelper.GetSelected(tbUINodeInfo.node))
            else
                UIHelper.SetSelected(tbUINodeInfo.node, true)
            end
        elseif not bCheckBox then
            UIHelper.SetSelected(tbUINodeInfo.node, false)
        end
    end
    if nIndex == 0 then
        return false
    end
    local tbUINodeInfo = tbTogNodeAllData[nIndex]
    xpcall(
        function()
            return self._Trigger(tbUINodeInfo)
        end,
        function()
            UINodeControl.bException = true
        end
    )
    if UINodeControl.bException then
        UINodeControl.bException = false
        return false
    else
        return true
    end
end

function UINodeControl.TouchBeganTrigger(szNodeName, nCount)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnSelectChanged)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnTouchBegan]
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        if szNodeName == tbUINodeInfo.szNodeName then
            if nCount == 1 then
                return self._Trigger(tbUINodeInfo)
            end
            nCount = nCount - 1
        end
    end
    return false
end

function UINodeControl.TouchEndTrigger(szNodeName, nCount)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnSelectChanged)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnTouchEnded]
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        if szNodeName == tbUINodeInfo.szNodeName then
            if nCount == 1 then
                return self._Trigger(tbUINodeInfo)
            end
            nCount = nCount - 1
        end
    end
    return false
end

function UINodeControl.TouchMovedTrigger(szNodeName, nCount)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnSelectChanged)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnTouchMoved]
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        if szNodeName == tbUINodeInfo.szNodeName then
            if nCount == 1 then
                return self._Trigger(tbUINodeInfo)
            end
            nCount = nCount - 1
        end
    end
    return false
end
TestSkill = {}

function UINodeControl.TestSkill()
    UINodeControl.TouchBeganTrigger(szNodeName, nCount)
    Timer.AddFrameCycle(
        TestSkill,
        10,
        function()
            --
        end
    )
end

function UINodeControl.TouchClickTrigger(szNodeName, nCount)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnSelectChanged)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnClick]
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        if szNodeName == tbUINodeInfo.szNodeName then
            if nCount == 1 then
                return self._Trigger(tbUINodeInfo)
            end
            nCount = nCount - 1
        end
    end
    return false
end

--滑动条触发先设置slider的值再触发slider的事件即可
function UINodeControl.SliderTriggerByCnt(szNodeName, nCount, nPercent)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnChangeSliderPercent)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnChangeSliderPercent]
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        if szNodeName == tbUINodeInfo.szNodeName then
            if nCount == 1 then
                self._Trigger(tbUINodeInfo, 1) --触发滑动条事件按下
                UIHelper.SetProgressBarPercent(tbUINodeInfo.node, nPercent) --设置值
                return self._Trigger(tbUINodeInfo, 2) --触发滑动条事件抬起
            end
            nCount = nCount - 1
        end
    end
    return false
end
--滑动条实现平滑滑动效果 几秒钟由左边滑动到右边
--szNodeName:滑动条的节点名称
--nCount:触发第几个同名滑动条
--nSec:滑动的时间
UINodeControl.tbSlider = {}
function UINodeControl.SliderSlidingInSec(szNodeName, nCount, nSec)
    --清除异常数据
    UINodeControl.DealWithException(EventType.OnChangeSliderPercent)
    if not nCount or nCount <= 0 then
        nCount = 1
    end
    local tbTargetNodeInfo = nil
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnChangeSliderPercent]
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        if szNodeName == tbUINodeInfo.szNodeName then
            if nCount == 1 then
                tbTargetNodeInfo = tbUINodeInfo
            end
            nCount = nCount - 1
        end
    end
    if tbTargetNodeInfo == nil then
        return false
    end
    local nStartPercent = 0
    local nEndPercent = 100
    local nDuration = nSec * GetHotPointReader().GetFrameDataInfo().FPS --默认30帧
    local fCurPercent = nStartPercent
    local fPercentPerFrame = (nEndPercent - nStartPercent) / nDuration --每帧需要设置多少slider的值
    local bFlag = true
    Timer.AddFrameCycle(
        tbTargetNodeInfo,
        1,
        function()
            --print('nCount:'..nCount..'   :--------------------\t'..fCurPercent)
            UIHelper.SetProgressBarPercent(tbTargetNodeInfo.node, fCurPercent)
            if fCurPercent == nStartPercent then
                self._Trigger(tbTargetNodeInfo, 1) --触发滑动条事件按下
            elseif fCurPercent > nEndPercent then
                --print('test-----')
                self._Trigger(tbTargetNodeInfo, 2) --触发滑动条事件抬起
                Timer.DelAllTimer(tbTargetNodeInfo)
            end
            fCurPercent = fCurPercent + fPercentPerFrame
        end
    )
end

function UINodeControl.GetAllCheckBox()
end

function UINodeControl.DealWithException(szEventType)
    if not UINodeControl.bSwitch then
        return
    end
    local function DealWithNode(tbUINodeData)
        local list_ExceptionIndex = {}
        local bException = false
        for nIndex, tbUINodeInfo in ipairs(tbUINodeData) do
            xpcall(
                function()
                    tbUINodeInfo.node:getName()
                end,
                function()
                    bException = true
                end
            )
            if bException then
                bException = false
                table.insert(list_ExceptionIndex, nIndex)
            else
                --当前节点或者父节点不可见则直接跳过 绑定事件时还未设置bVisible=false 因此需要在处理异常节点中操作
                --原始数据保留不可见节点 触发事件是会判断是否可见
                --if not UINodeControl._isVisable(tbUINodeInfo.node) then
                --UINodeControl.bException=true
                --break
                --end
                if tbUINodeInfo.node:getName() == "" or not UINodeControl._IsFindPanel(tbUINodeInfo.node) then
                    table.insert(list_ExceptionIndex, nIndex)
                end
            end
        end
        for nIndex, _ in ipairs(list_ExceptionIndex) do
            --尾部开始移除 避免tab前移
            --print('--remove--:'..tostring(list_ExceptionIndex[#list_ExceptionIndex-nIndex+1])..'\t NodeName:'..tbUINodeData[list_ExceptionIndex[#list_ExceptionIndex-nIndex+1]].szNodeName)
            table.remove(tbUINodeData, list_ExceptionIndex[#list_ExceptionIndex - nIndex + 1])
        end
    end
    local nExceptionIndex = nil
    local szEventTypeTemp = nil
    --一次处理所有节点数据会导致耗时增加
    --[[]]
    if not szEventType then
        --一次处理所有节点数据会导致耗时增加
        --[[]]
        print('test=============')
        for szEventTypeTemp, tbUINodeData in pairs(UINodeControl.tbUINodeData) do
            --toggroup特殊处理  以父节点的父节点名称作为key value为list_tog
            if szEventTypeTemp == EventType.OnSelectChanged then
                for szToggleGroupName, tbUITogNodeData in pairs(tbUINodeData) do
                    nIndex=0
                    for szToggleGroupParentName, tbUITogNodeAllData in pairs(tbUITogNodeData) do
                        nIndex=nIndex+1
                        if #tbUITogNodeAllData==0 then
                            tbUITogNodeData[szToggleGroupParentName] = nil
                            --print("--------------clear2----------"..szToggleGroupParentName)
                        end
                        DealWithNode(tbUITogNodeAllData)
                    end
                    if nIndex==0 then
                        tbUINodeData[szToggleGroupName] = nil
                    end
                end
            else
                DealWithNode(tbUINodeData)
            end
        end
    else
        --根据节点类型分批处理
        local tbUINodeData = UINodeControl.tbUINodeData[szEventType]
        if szEventType == EventType.OnSelectChanged then
            for szToggleGroupName, tbUITogNodeData in pairs(tbUINodeData) do
                nIndex=0
                for szToggleGroupParentName, tbUITogNodeAllData in pairs(tbUITogNodeData) do
                    nIndex=nIndex+1
                    if #tbUITogNodeAllData==0 then
                        tbUITogNodeData[szToggleGroupParentName] = nil
                        --print("--------------clear2----------"..szToggleGroupParentName)
                    end
                    DealWithNode(tbUITogNodeAllData)
                end
                if nIndex==0 then
                    tbUINodeData[szToggleGroupName] = nil
                end
            end
        else
            DealWithNode(tbUINodeData)
        end
    end
end

--清除所有节点
function UINodeControl.ClearAllNode()
    UINodeControl.tbUINodeData = {}
end
--(null): =============szTogGroupName:ScrollViewAreanList==============
--WidgetServerListCell

--打印调试信息
--打印所有绑定了事件的节点
function UINodeControl.PrintAllNode()
    UINodeControl.DealWithException()
    for szEventType, tbUINodeData in pairs(UINodeControl.tbUINodeData) do
        print("---------------------------szEventType:" .. szEventType .. "-----------------------------")
        if szEventType == EventType.OnSelectChanged then
            for szNodeName, tbUITogNodeData in pairs(tbTogNodeData) do
                print(
                    "===============================szTogGroupName:" .. szNodeName .. "==============================="
                )
                for szNodeParentName, tbUITogNodeAllData in pairs(tbUITogNodeData) do
                    print("=============szTogGroupParentName:" .. szNodeParentName .. "==============")
                    for nIndex, tbUINodeInfo in ipairs(tbUITogNodeAllData) do
                        print("___________Idex:" .. tostring(nIndex) .. "____________")
                        if tbUINodeInfo.node then
                            if tbUINodeInfo.node.getName then
                                pcall(
                                    function()
                                        print("++++++++++:" .. tbUINodeInfo.node:getName() .. ":++++++++++")
                                    end
                                )
                            end
                            print(tbUINodeInfo.EventType)
                        end
                    end
                end
            end
        else
            for nIndex, tbUINodeInfo in ipairs(tbUINodeData) do
                print("___________Idex:" .. tostring(nIndex) .. "____________")
                if tbUINodeInfo.node then
                    if tbUINodeInfo.node.getName then
                        pcall(
                            function()
                                print("++++++++++:" .. tbUINodeInfo.node:getName() .. ":++++++++++")
                            end
                        )
                    end
                    print(tbUINodeInfo.EventType)
                end
            end
        end
    end
end

--ReloadScript.Reload("Lua/Interface/SearchPanel/UINodeControl.lua")

function UINodeControl.PrintToggroupNode()
    UINodeControl.DealWithException()
    local tbTogNodeData = UINodeControl.tbUINodeData[EventType.OnSelectChanged]
    for szNodeName, tbUITogNodeData in pairs(tbTogNodeData) do
        print("===============================szTogGroupName:" .. szNodeName .. "===============================")
        for szNodeParentName, tbUITogNodeAllData in pairs(tbUITogNodeData) do
            print("=============szTogGroupParentName:" .. szNodeParentName .. "==============")
            for nIndex, tbUINodeInfo in ipairs(tbUITogNodeAllData) do
                print("___________Idex:" .. tostring(nIndex) .. "____________")
                if tbUINodeInfo.node then
                    if tbUINodeInfo.node.getName then
                        pcall(
                            function()
                                print("++++++++++:" .. tbUINodeInfo.node:getName() .. ":++++++++++")
                            end
                        )
                    end
                    print(tbUINodeInfo.EventType)
                end
            end
        end
    end
end

function UINodeControl.PrintBtnNode()
    UINodeControl.DealWithException()
    local tbBtnUINodeData = UINodeControl.tbUINodeData[EventType.OnClick]
    for nIndex, tbUINodeInfo in ipairs(tbBtnUINodeData) do
        print("___________Idex:" .. tostring(nIndex) .. "____________")
        if tbUINodeInfo.node then
            if tbUINodeInfo.node.getName then
                pcall(
                    function()
                        print("++++++++++:" .. tbUINodeInfo.node:getName() .. ":++++++++++")
                    end
                )
            end
            print(tbUINodeInfo.EventType)
        end
    end
end

--定时清除异常节点
function SearchPanel.DownloadGM()
    Timer.AddCycle(
        UINodeControl,
        1,
        function()
            UINodeControl.DealWithException()
        end
    )
end
--SearchPanel.DownloadGM()

function UINodeControl.RemoveNode(node, nEventType)
    if nEventType == EventType.OnSelectChanged then
        for szToggleGroupName, tbUINodeData in pairs(UINodeControl.tbUINodeData[nEventType]) do
            for nIndex, tbUINodeInfo in ipairs(tbUINodeData) do
                if tbUINodeInfo.node == node then
                    table.remove(tbUINodeData, nIndex)
                end
            end
        end
    else
        for nIndex, tbUINodeInfo in ipairs(UINodeControl.tbUINodeData[nEventType]) do
            if tbUINodeInfo.node == node then
                table.remove(UINodeControl.tbUINodeData[nEventType], nIndex)
            end
        end
    end
end

--UINodeControl.PrintLableText(UINodeControl.tbUINodeData[EventType.OnSelectChanged]["WidgetServerListCell"][1].node)
--(null): =============szTogGroupName:WidgetServerListCell==============
----print(UIHelper.GetVisible(UINodeControl.tbUINodeData[EventType.OnSelectChanged]["WidgetServerListCell"][1].node))
----print(UINodeControl.tbUINodeData[EventType.OnSelectChanged]["TogEmotion"][1].node)

--获取节点的绑定的Lua脚本名称
function self._NodeGetExtraInfo(node)
    if not node then
        return nil
    end

    local compLuaBind = node:getComponent("LuaBind") -- TODO luwenhao1 需判断该LuaBind是否包含当前Node
    local scriptView = compLuaBind and compLuaBind:getScriptObject()
    if scriptView then
        local szName
        local nViewID = scriptView._nViewID
        local nPrefabID = scriptView._nPrefabID
        if nViewID then
            szName = "ViewName: " .. TabHelper.GetUIViewTab(nViewID).szViewName
        elseif nPrefabID then
            szName = "PrefabName: " .. TabHelper.GetUIPrefabTab(nPrefabID).szPrefabName
        else
            return ""
        end
        return "ScriptPath: " .. scriptView._scriptPath .. ", " .. szName
    end
    return self._NodeGetExtraInfo(UIHelper.GetParent(node))
end

function UINodeControl.NodeGetBindPanel(node)
    return true
    --[[
    if node then
        --print('nodeName:'..node:getName())
    else
        return false
    end
    
    if not node.getName then
        return false
    end
    local szNodeName=node:getName()
    if string.find(string.lower(szNodeName),'panel') then
        --print('result:'..szNodeName)
        return true
    end
    UINodeControl.NodeGetBindPanel(node:getParent())]]
end

function test11()
    local tbTest = {}
    local t1 = tbTest
    print(tbTest)
    print(t1)
    if tbTest == t1 then
        print("test")
    end
end

function UINodeControl._IsFindPanel(node)
    if node then
        ----print('nodeName:'..node:getName())
    else
        return false
    end
    local compLuaBind = node:getComponent("LuaBind") -- TODO luwenhao1 需判断该LuaBind是否包含当前Node
    if compLuaBind then
        local scriptView = compLuaBind:getScriptObject()
        if scriptView then
            local szName
            local nViewID = scriptView._nViewID
            if nViewID then
                szName = "ViewName: " .. TabHelper.GetUIViewTab(nViewID).szViewName
                ----print(scriptView._rootNode:getName())
                --print("ScriptPath: " .. scriptView._scriptPath .. ", " .. szName)
                return true
            end
        else
            return false
        end
    end
    return UINodeControl._IsFindPanel(UIHelper.GetParent(node))
end

function UINodeControl.GetNodePanelName(node)
    if node then
        ----print('nodeName:'..node:getName())
    else
        return nil
    end
    local compLuaBind = node:getComponent("LuaBind") -- TODO luwenhao1 需判断该LuaBind是否包含当前Node
    if compLuaBind then
        local scriptView = compLuaBind:getScriptObject()
        if scriptView then
            local szName
            local nViewID = scriptView._nViewID
            if nViewID then
                szName = "ViewName: " .. TabHelper.GetUIViewTab(nViewID).szViewName
                ----print(scriptView._rootNode:getName())
                print("ScriptPath: " .. scriptView._scriptPath .. ", " .. szName)
                return true
            end
        else
            return nil
        end
    end
    return UINodeControl.PrintPanel(UIHelper.GetParent(node))
end

--UINodeControl._NodeGetBindPanel(UINodeControl.tbUINodeData[EventType.OnClick][70].node)
--该表用于记录需要移除的toggroup
UINodeControl.tbTogGroupRemveName = {}
UINodeControl.bTogGroupRemveNameLock = false

function UINodeControl.ProcessTogGroupRemveName()
    if not UINodeControl.bTogGroupRemveNameLock then
        return
    end
    for szToggleGroupName, tbUITogNodeData in pairs(UINodeControl.tbTogGroupRemveName) do
        --print('============szTogGroupName:'..szToggleGroupName..'===============')
        --print(#tbUITogNodeData)
        szTogglexGroupParentNodeName = szToggleGroupName
        for nIndex, tbUINodeInfo in ipairs(tbUITogNodeData) do
            --xpcall(function () print(tbUINodeInfo.node:getGroup():getName()) end,function () print('error    =========') end)
            if tbUINodeInfo.node.getGroup then
                local nodeTemp = nil
                xpcall(
                    function()
                        nodeTemp = tbUINodeInfo.node:getGroup()
                    end,
                    function()
                        print("tog error node:" .. tbUINodeInfo.szNodeName)
                    end
                )
                if nodeTemp then
                    szToggleGroupName = tbUINodeInfo.node:getGroup():getName()

                    --ToggleGroup结构
                    --[szToggleGroupName][szTogglexGroupParentNodeName]={}
                    szTogglexGroupParentNodeName = tbUINodeInfo.node:getGroup():getParent():getName()
                    --print('test-----------')
                    --print(szToggleGroupName)
                    --print(szTogglexGroupParentNodeName)
                else
                    --print("tbUINodeInfo.node:getGroup1 nil")
                end
            else
                --print("tbUINodeInfo.node.getGroup2 nil")
            end
            if not UINodeControl.tbUINodeData[EventType.OnSelectChanged] then
                UINodeControl.tbUINodeData[EventType.OnSelectChanged] = {}
            end
            if not UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggleGroupName] then
                UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggleGroupName] = {}
            end
            if not UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggleGroupName][szTogglexGroupParentNodeName] then
                UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggleGroupName][szTogglexGroupParentNodeName] = {}
            end

            table.insert(UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggleGroupName][szTogglexGroupParentNodeName], tbUINodeInfo)
        end
    end
    UINodeControl.tbTogGroupRemveName = {}
end
--定时处理toggroup
--[[]]
Timer.AddFrameCycle(
    UINodeControl,
    10,
    function()
        UINodeControl.ProcessTogGroupRemveName()
    end
)

function UINodeControl.BindUIEvent(btn, nEventType, func)
    --UINodeControl.DealWithException()
    local _doBindUIEvent = function(btn, nEventType, func)
        if not safe_check(btn) then
            return
        end
        --节点数据表中不存在当前事件子表
        if not UINodeControl.tbUINodeData[nEventType] then
            UINodeControl.tbUINodeData[nEventType] = {}
        end
        local tbUINodeInfo = {}
        tbUINodeInfo.EventType = nEventType
        tbUINodeInfo.szNodeName = btn:getName()
        --tbUINodeInfo.szParentName=btn:getParent():getName()
        tbUINodeInfo.node = btn
        tbUINodeInfo.Trigger = func
        tbUINodeInfo.ArgsCnt = 0
        if nEventType == EventType.OnClick then
            btn:addClickEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnTouchBegan then
            btn:addTouchBeganEventListener(func) -- func(btn, x, y)
            tbUINodeInfo.ArgsCnt = 2
        elseif nEventType == EventType.OnTouchMoved then
            btn:addTouchMovedEventListener(func) -- func(btn, x, y)
            tbUINodeInfo.ArgsCnt = 2
        elseif nEventType == EventType.OnTouchEnded then
            btn:addTouchEndedEventListener(func) -- func(btn, x, y)
            tbUINodeInfo.ArgsCnt = 2
        elseif nEventType == EventType.OnTouchCanceled then
            btn:addTouchCanceledEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnSelectChanged then
            UINodeControl.bTogGroupRemveNameLock = false
            tbUINodeInfo.Trigger = function(btn, eventType)
                func(btn, eventType == 0)
            end
            btn:addEventListener(tbUINodeInfo.Trigger) -- func(btn, bSelected)
            tbUINodeInfo.ArgsCnt = 1
        elseif nEventType == EventType.OnLongPress then
            -- 长按的时间默认为1秒，如有特殊需求，可以设置btn:setLongPressDelay(3)
            btn:addLongPressEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnPersistentPress then
            btn:addPersistentPressEventListener(func) -- func(btn, nCount)
            tbUINodeInfo.ArgsCnt = 1
        elseif nEventType == EventType.OnDragOver then
            btn:addDragOverEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnDragOut then
            btn:addDragOutEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnChangeSliderPercent then
            btn:addEventListener(func) -- func(btn, ccui.SliderEventType nSliderEvent)
            tbUINodeInfo.ArgsCnt = 1
        elseif nEventType == EventType.OnVideoStateChanged then
            btn:addEventListener(func) -- func(btn, ccui.VideoPlayerEvent nVideoPlayerEvent)
            tbUINodeInfo.ArgsCnt = 1
        elseif nEventType == EventType.OnTurningPageView then
            btn:addEventListener(func) -- func(btn)
        end
        --当前节点或者父节点不可见则直接跳过 绑定事件时还未设置bVisible=false 因此需要在处理异常节点中操作

        --部分tog绑定的Onclick事件 暂时特殊处理后续会使用gettogglegroup
        --[[]]
        if string.find(string.lower(tbUINodeInfo.szNodeName), "tog") then
            nEventType = EventType.OnSelectChanged
            --print("TogTest:" .. tbUINodeInfo.szNodeName)
            if not UINodeControl.tbUINodeData[nEventType] then
                UINodeControl.tbUINodeData[nEventType] = {}
            end
        end
        --[[
        if tbUINodeInfo.node.getGroup and tbUINodeInfo.node:getGroup()~=nil and tbUINodeInfo.node:getGroup():getName()~='' then
            nEventType = EventType.OnSelectChanged
            print('TogTest:----------------'..tbUINodeInfo.node.szNodeName)
            if not UINodeControl.tbUINodeData[nEventType] then
                UINodeControl.tbUINodeData[nEventType]={}
            end
        end]]
        --避免节点重复
        --UINodeControl.RemoveNode(tbUINodeInfo.node,nEventType)
        --print('szNodeName:'..tbUINodeInfo.szNodeName)
        if nEventType == EventType.OnSelectChanged then
            --延时帧调用处理toggroup的逻辑
            --[[
            Timer.AddFrame(UINodeControl,10,function ()
                local szToggropName=nil
                for szKey,tbUITogNodeData in pairs(UINodeControl.tbTogGroupRemveName) do
                    szToggropName=szKey
                    print('test2222-----------')
                    print(szKey)
                    for nIndex,tbUINodeInfo in ipairs(tbUITogNodeData) do
                        xpcall(function () print(tbUINodeInfo.node:getGroup():getName()) end,function () print('error    =========') end)
                        if tbUINodeInfo.node.getGroup then
                            print('test---')
                            print(tbUINodeInfo.node.getGroup)
                            print(tbUINodeInfo.szNodeName)
                            print(tbUINodeInfo.Trigger)
                            xpcall(function () nodeTemp=tbUINodeInfo.node:getGroup() end,function () print('tog error node:') end)
                            if nodeTemp then
                                szToggropName=tbUINodeInfo.node:getGroup():getName()
                                --print(szToggropName)
                            else
                                --print("tbUINodeInfo.node:getGroup1 nil")
                            end
                        else
                            --print("tbUINodeInfo.node.getGroup2 nil")
                        end
                        if not UINodeControl.tbUINodeData[EventType.OnSelectChanged] then
                            UINodeControl.tbUINodeData[EventType.OnSelectChanged]={}
                        end
                        if not UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggropName] then
                            UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggropName]={}
                        end
                        table.insert(UINodeControl.tbUINodeData[EventType.OnSelectChanged][szToggropName],tbUINodeInfo)
                    end
                end
                UINodeControl.tbTogGroupRemveName={}
            end)]]
            --[[]]
            local szKey = tbUINodeInfo.node:getParent():getParent():getName()
            --部分节点名称为'' 再往上走一层
            if szKey == "" then
                szKey = tbUINodeInfo.node:getParent():getParent():getParent():getName()
            end
            --print("BindToggroup:" .. szKey)
            if not UINodeControl.tbTogGroupRemveName[szKey] then
                UINodeControl.tbTogGroupRemveName[szKey] = {}
            end
            table.insert(UINodeControl.tbTogGroupRemveName[szKey], tbUINodeInfo)
            UINodeControl.bTogGroupRemveNameLock = true
        else
            table.insert(UINodeControl.tbUINodeData[nEventType], tbUINodeInfo)
        end
    end

    if IsTable(btn) then
        for k, v in ipairs(btn) do
            _doBindUIEvent(v, nEventType, func)
        end
    else
        _doBindUIEvent(btn, nEventType, func)
    end
end
--替换绑定事件的函数
UIHelper.BindUIEvent = UINodeControl.BindUIEvent
