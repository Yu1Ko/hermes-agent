UIClickDebugger = {}
local self = UIClickDebugger

local bEnabled = false
local touchListener = nil

-- 检测类型
local CheckType = {
    None = 0,                       -- 无
    Node = 1,                       -- 节点
    Interactable = 2,               -- 可交互的
    InteractableAndSpriteLabel = 3, -- 可交互的+图片/文字
    AllWidget = 4                   -- 所有组件
}

UIClickDebugger.bPrintTopOnly = true -- 只打印最顶层UI
UIClickDebugger.nCheckType = CheckType.InteractableAndSpriteLabel -- 检测类型

local function _forEachValidNode(node, func)
    -- 筛选widget
    if not node then return end
    if node:getName() == "PanelHoverTips" then return end
    if node:getName() == "PanelNodeExplorer" then return end
    if not UIHelper.GetVisible(node) then return end
    if node.isEnabled and not node:isEnabled() then return end

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

-- hitTest for widget
local function _hitTest(node, tbPoint)
    local tbSize = node:getContentSize()
    local nWorldPosX, nWorldPosY = UIHelper.GetWorldPosition(node)
    local nAnchPosX, nAnchPosY = UIHelper.GetAnchorPoint(node) -- 需要考虑anchor得到真实的rect
    local nNodePosX = nWorldPosX - nAnchPosX * tbSize.width
    local nNodePosY = nWorldPosY - nAnchPosY * tbSize.height
    local tbRect = cc.rect(nNodePosX, nNodePosY, tbSize.width, tbSize.height)
    return cc.rectContainsPoint(tbRect, tbPoint)
end

-- 排除UILayer
local function _isValidNode(node)
    local parent = UIHelper.GetParent(node)
    return parent and UIHelper.GetParent(parent)
end

local function _getNodeHierarchy(node)
    if not _isValidNode(node) then return "" end

    local szParentHierarchy = _getNodeHierarchy(UIHelper.GetParent(node))
    return szParentHierarchy .. "/" .. node:getName()
end

local function _getExtraInfo(node)
    if not node then return nil end

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

    return _getExtraInfo(UIHelper.GetParent(node))
end

local function _insertNodeInfo(node, tbReselt)
    local szInfo = _getNodeHierarchy(node)
    local szExtraInfo = _getExtraInfo(node)
    if szInfo and szInfo ~= "" then
        if szExtraInfo then
            szInfo = szInfo .. "\n(" .. szExtraInfo .. ")"
        end
        table.insert(tbReselt, szInfo)
    end
end

local _onTouchBeganCallback = function(touch, event)
    local tbPoint = touch:getLocation()

    -- 获取根节点
    local sceneNode = cc.Director:getInstance():getRunningScene()
    local camera = sceneNode:getDefaultCamera()
    local topNode
    local tbPrintContent = {}

    -- 遍历所有节点
    _forEachValidNode(sceneNode, function(node)
        -- print("ForEach Node:", node:getName())

        local bIsHit = false
        if self.nCheckType >= CheckType.Interactable then
            -- hitTest for button etc.
            if node.hitTest and node:hitTest(tbPoint, camera) then
                if node:isClippingParentContainsPoint(tbPoint) then
                    bIsHit = true
                    if not self.bPrintTopOnly then
                        _insertNodeInfo(node, tbPrintContent)
                    else
                        topNode = node
                    end
                end
            end

            if not bIsHit and self.nCheckType == CheckType.AllWidget or
                IsUserType(node, "cc.Sprite") or IsUserType(node, "cc.Label") then
                -- hit test for widget
                if _isValidNode(node) and _hitTest(node, tbPoint) then
                    -- if node:isClippingParentContainsPoint(tbPoint) then
                        bIsHit = true
                        if not self.bPrintTopOnly then
                            _insertNodeInfo(node, tbPrintContent)
                        else
                            topNode = node
                        end
                    -- end
                end
            end
        elseif self.nCheckType == CheckType.Node then
            if _isValidNode(node) and _hitTest(node, tbPoint) then
                bIsHit = true
                if not self.bPrintTopOnly then
                    _insertNodeInfo(node, tbPrintContent)
                else
                    topNode = node
                end
            end
        end
    end)

    if topNode and self.bPrintTopOnly then
        _insertNodeInfo(topNode, tbPrintContent)
    end

    local view = UIMgr.GetView(VIEW_ID.PanelNodeExplorer)
    local scriptView = view and view.scriptView
    if not scriptView then
        scriptView = UIMgr.Open(VIEW_ID.PanelNodeExplorer)
    end
    scriptView:LocateNode(topNode)

    local nCount = #tbPrintContent
    if nCount > 0 then
        local szContent = string.format("Click Point: (%d, %d)\n", tbPoint.x, tbPoint.y)
        for i = 1, #tbPrintContent do
            szContent = szContent .. tbPrintContent[i]
            if i ~= #tbPrintContent then szContent = szContent .. "\n" end
        end

        print("----------------Start----------------")
        print(string.format("Click Point: (%d, %d)", tbPoint.x, tbPoint.y))
        for i = 1, #tbPrintContent do
            print(tbPrintContent[i])
            if i ~= #tbPrintContent then print("\n") end
        end
        print("----------------End----------------")
    end
end

-------------------------------- Public --------------------------------

function UIClickDebugger.IsEnabled() 
    return bEnabled and touchListener 
end

function UIClickDebugger.Enable(nCheckType)
    if self.IsEnabled() then return end
    bEnabled = true

    if nCheckType then
        self.SetCheckType(nCheckType)
    end

    -- 注册全局点击事件
    local bIsInit = touchListener ~= nil
    if not bIsInit then
        touchListener = cc.EventListenerTouchOneByOne:create()
    end
    touchListener:registerScriptHandler(_onTouchBeganCallback, cc.Handler.EVENT_TOUCH_BEGAN)

    if not bIsInit then
        local dispatchEvent = cc.Director:getInstance():getEventDispatcher()
        dispatchEvent:addEventListenerWithFixedPriority(touchListener, -999)
    end
end

function UIClickDebugger.Disable()
    bEnabled = false
    if touchListener then
        touchListener:registerScriptHandler(function() end, cc.Handler.EVENT_TOUCH_BEGAN)
    end
end

function UIClickDebugger.SetCheckType(nCheckType)
    self.nCheckType = nCheckType
    LOG.INFO("[UIClickDebugger] SetCheckType Done!")
end

return UIClickDebugger

