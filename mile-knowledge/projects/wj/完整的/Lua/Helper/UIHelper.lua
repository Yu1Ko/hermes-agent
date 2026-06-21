UIHelper = UIHelper or { className = "UIHelper" }

UIHelper.GBKToUTF8 = GBKToUTF8
UIHelper.UTF8ToGBK = UTF8ToGBK

local cc_size_zero = cc.size(0, 0)
local cc_p_zero = cc.p(0, 0)
local cc_anchor_center = cc.p(0.5, 0.5)
local cc_anchor_valign_center = cc.p(0, 0.5)
local cc_anchor_valign_top = cc.p(0, 1)
local cc_spriteFrameCache = cc.SpriteFrameCache:getInstance()
local cc_textureCache = cc.Director:getInstance():getTextureCache()
local cc_font_color_white = cc.c4b(255, 255, 255, 255)
local mfloor, mmin, mmax, mceil = math.floor, math.min, math.max, math.ceil
local kDpi = cc.Device:getDPI()

local tEscapeTable = {
    ['"'] = '\\"',
    ['\\'] = '\\\\',
    ['\n'] = '\\n',
    ['\t'] = '\\t'
}

function safe_check(obj)
    if not obj then
        --LOG.ERROR("object is nil.")
        return false
    end

    if not IsUserData(obj) then
        LOG.ERROR("object is not userdata.")
        return false
    end

    if obj.safe_check then
        if not obj:safe_check() then
            LOG.ERROR("object is invalid.")
            return false
        end
    end

    return true
end

function UIHelper.AddPrefab(nPrefabID, parent, ...)
    return UIMgr.AddPrefab(nPrefabID, parent, ...)
end

function UIHelper.SetVisible(node, bVisible)
    if not safe_check(node) then
        return
    end


    bVisible = bVisible and true or false
    if UIHelper.GetVisible(node) ~= bVisible then
        if node.setVisible then
            node:setVisible(bVisible)
        end
    end
end

function UIHelper.GetVisible(node)
    if not safe_check(node) then
        return
    end

    if not node.isVisible then
        return
    end

    return node:isVisible()
end

function UIHelper.GetHierarchyVisible(node, bCheckOpacity)
    if not node then
        return false
    end

    local root = UIMgr.GetCurrentScene()
    while node do
        if node == root then
            --逐层往上直到找到根节点，表示该节点未被removeFromParent或回收到池子里
            return true
        end
        if not UIHelper.GetVisible(node) or (bCheckOpacity and UIHelper.GetOpacity(node) <= 0) then
            return false
        end
        node = node.getParent and node:getParent()
    end
    return false
end

function UIHelper.GetHierarchyScale(node)
    if not safe_check(node) then
        return
    end

    local nScaleX = UIHelper.GetScaleX(node)
    local nScaleY = UIHelper.GetScaleY(node)
    local parent = node.getParent and node:getParent()
    if parent then
        local nParentScaleX, nParentScaleY = UIHelper.GetHierarchyScale(parent)
        if nParentScaleX and nParentScaleY then
            nScaleX = nScaleX * nParentScaleX
            nScaleY = nScaleY * nParentScaleY
        end
    end
    return nScaleX, nScaleY
end

function UIHelper.SetTabVisible(tbNode, bVisible)
    for _, v in pairs(tbNode or {}) do
        UIHelper.SetVisible(v, bVisible)
    end
end

function UIHelper.SetOpacity(node, nOpacity)
    if not safe_check(node) then
        return
    end
    node:setOpacity(nOpacity) -- [0-255]
end

function UIHelper.GetOpacity(node)
    if not safe_check(node) then
        return
    end
    return node:getOpacity()
end

function UIHelper.SetEnable(node, bEnable)
    if not safe_check(node) then
        return
    end
    return node:setEnabled(bEnable)
end

function UIHelper.SetString(label, szContent, nMaxLen)
    if not safe_check(label) then
        return
    end
    szContent = szContent or ""

    if IsNumber(nMaxLen) and nMaxLen > 0 and not string.is_nil(szContent) then
        -- if utf8.len(szContent) > nMaxLen then
        -- 	szContent = utf8.sub(szContent, 1, nMaxLen) .. "..."
        -- end
        szContent = UIHelper.LimitUtf8Len(szContent, nMaxLen)
    end

    if label.setString then
        -- Lable
        if label.getTenThousand and label:getTenThousand() then
            local nDecimal = label.getTenThousandDecimal and label:getTenThousandDecimal() or 0
            szContent = UIHelper.NumberToTenThousand(szContent, nDecimal)
        end
        label:setString(szContent)
    elseif label.setText then
        -- EditBox
        label:setText(szContent)
    end
end

function UIHelper.SetFontSize(label, nSize)
    if not safe_check(label) then
        return
    end
    if label.setFontSize then
        label:setFontSize(nSize)
    elseif label.getTTFConfig then
        local ttfConfig = label:getTTFConfig()
        ttfConfig.fontSize = nSize
        label:setTTFConfig(ttfConfig)
    end
end

function UIHelper.GetFontSize(label)
    if not safe_check(label) then
        return
    end
    local nSize = 0
    if label.getFontSize then
        nSize = label:getFontSize()
    elseif label.getTTFConfig then
        local ttfConfig = label:getTTFConfig()
        nSize = ttfConfig.fontSize
    end
    return nSize
end

-- 自动根据宽度裁剪并且补...
-- 预制上的label需设置为CLAMP，关闭自动换行，做左右拉伸适配
function UIHelper.SetStringAutoClamp(label, szContent)
    if not safe_check(label) then
        return
    end
    szContent = szContent or ""

    label:setString(szContent)
    label:updateContent()

    local fMaxWidth = label:getLineMaxWidth()
    local fWidth = UIHelper.GetWidth(label)
    if fMaxWidth > fWidth then
        local nClampStartIndex = label:getClampCharStartIndex()
        if nClampStartIndex > 0 then
            szContent = UIHelper.LimitUtf8Len(szContent, nClampStartIndex)
            label:setString(szContent)
        end
    end

end
-- 文本标签自动裁剪文字长度，多余的文字补齐"...."
function UIHelper.SetStringEllipsis(label, szContent, nMaxCharCount)
    if not safe_check(label) then
        return
    end
    local nCharCount, szUtfName = GetStringCharCountAndTopChars(szContent, nMaxCharCount)
    UIHelper.SetString(label, nCharCount > nMaxCharCount and szUtfName .. "..." or szUtfName)
end

function UIHelper.SetHorizontalAlignment(label, nAlign)
    if not safe_check(label) then
        return
    end
    label:setAlignment(nAlign)
end

function UIHelper.SetLabelDimensions(label, nWidth, nHeight)
    if not safe_check(label) then
        return
    end
    label:setDimensions(nWidth, nHeight)
end

function UIHelper.SetOverflow(label, nLabelOverflow)
    if not safe_check(label) then
        return
    end
    label:setOverflow(nLabelOverflow)
end

--- 设置node的显示和隐藏并缓存，有改动才设置，性能较高
--- 注：需要保证缓存状态一致，避免多个脚本操作同一个go，否则可能状态错乱
function UIHelper.SetActiveAndCache(script, node, bActive)
    bActive = bActive or false
    if not safe_check(node) then
        return
    end
    if not script then
        return
    end

    local cacheTable = rawget(script, '_tbActiveCache')
    if not cacheTable then
        cacheTable = {}
        rawset(script, '_tbActiveCache', cacheTable)
    end
    local oldValue = cacheTable[node]
    if bActive ~= oldValue then
        cacheTable[node] = bActive
        node:setVisible(bActive)
        return true
    end
    return false
end

---@param node  table ccNode
---@param color table use cc.c3b
function UIHelper.SetColor(node, color)
    if not safe_check(node) then
        return
    end
    node:setColor(color)
end

function UIHelper.SetCascadeColorEnabled(node, bEnable)
    if not safe_check(node) then
        return
    end
    node:setCascadeColorEnabled(bEnable)
end

function UIHelper.GetString(label)
    if not safe_check(label) then
        return
    end

    if label.getString then
        -- Lable
        return label:getString()
    elseif label.getText then
        -- EditBox
        return label:getText()
    end

    return nil
end

function UIHelper.SetTextColor(label, color)
    if not safe_check(label) then
        return
    end
    label:setTextColor(color) -- cc.c4b( _r,_g,_b,_a )
end

function UIHelper.SetSelected(checkBox, bSelected, bCallback)
    -- toggle 也可以这个接口
    if not safe_check(checkBox) then
        return
    end
    if bCallback == nil then
        bCallback = true
    end

    if bCallback then
        if checkBox.setSelected then
            checkBox:setSelected(bSelected)
        end
    else
        if checkBox.onlySetSelected then
            checkBox:onlySetSelected(bSelected)
        end
    end
end

function UIHelper.GetSelected(checkBox)
    -- toggle 也可以这个接口
    if not safe_check(checkBox) then
        return
    end
    return checkBox:isSelected()
end

-- 设置是否可以 SetSelected
function UIHelper.SetCanSelect(checkBox, bCanSelect, szTips, bWithGray)
    if not safe_check(checkBox) then
        return
    end

    if not checkBox.SetCanSelect then
        return
    end

    if not IsBoolean(bCanSelect) then
        return
    end

    checkBox:SetCanSelect(bCanSelect)

    local nState = bCanSelect and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(checkBox, nState, szTips, bWithGray)
end

function UIHelper.GetCanSelect(checkBox)
    if not safe_check(checkBox) then
        return false
    end

    if not checkBox.GetCanSelect then
        return false
    end
    return checkBox:GetCanSelect()

end

function UIHelper.GetPositionX(node, parent)
    if not safe_check(node) then
        return
    end

    local nX = node:getPositionX()

    parent = parent or UIHelper.GetParent(node)
    if parent then
        local px, py = UIHelper.GetAnchorPoint(parent)
        local pw, ph = UIHelper.GetContentSize(parent)
        nX = nX - px * pw
    end

    return nX
end

function UIHelper.PreloadSpriteFrame(szFrameName)
    local bHasSprite = cc_spriteFrameCache:getSpriteFrame(szFrameName)
    if not bHasSprite then
        local nIndex = UISpriteNameToFileTab.tbSpriteNameToFileMap[szFrameName] or 0
        local szFile = UISpriteNameToFileTab.tbFileList[nIndex]
        if szFile then
            cc_spriteFrameCache:addSpriteFramesWithJson(szFile)
        end
    end
end

function UIHelper.SetSpriteFrameWithFrameSize(sp, szFrameName, bAsync)
    if not safe_check(sp) then
        return
    end
    if string.is_nil(szFrameName) then
        return
    end

    local nLen = string.len(szFrameName)
    local szExt = string.sub(szFrameName, nLen - 3, nLen)
    if szExt ~= ".png" then
        szFrameName = szFrameName .. ".png"
    end

    local ci = sp:getCapInsets()
    local w, h = nil, nil

    if bAsync == nil then
        bAsync = true
    end

    UIHelper.PreloadSpriteFrame(szFrameName)
    local frame = cc_spriteFrameCache:getSpriteFrame(szFrameName)
    if frame then
        sp:setSpriteFrame(frame, ci, bAsync)
        local tbSize = frame:getOriginalSize()
        UIHelper.SetContentSize(sp, tbSize.width, tbSize.height)
    end
end

function UIHelper.SetSpriteFrame(sp, szFrameName, bKeepSize, bAsync)
    if not safe_check(sp) then
        return
    end
    if string.is_nil(szFrameName) then
        return
    end
    if bKeepSize == nil then
        bKeepSize = true
    end

    local nLen = string.len(szFrameName)
    local szExt = string.sub(szFrameName, nLen - 3, nLen)
    if szExt ~= ".png" then
        szFrameName = szFrameName .. ".png"
    end

    local ci = sp.getCapInsets and sp:getCapInsets() or nil
    local w, h = nil, nil
    if bKeepSize then
        w, h = UIHelper.GetContentSize(sp)
    end

    if bAsync == nil then
        bAsync = true
    end

    UIHelper.PreloadSpriteFrame(szFrameName)
    local frame = cc_spriteFrameCache:getSpriteFrame(szFrameName)
    if frame then
        if not ci then
            local framSize = frame:getOriginalSize()
            ci = cc.rect(0, 0, framSize.width, framSize.height)
        end
        if sp.setSpriteFrame then
            sp:setSpriteFrame(frame, ci, bAsync)
        elseif sp.getSprite then
            local progressTimerSprite = sp:getSprite()
            if progressTimerSprite then
                progressTimerSprite:setSpriteFrame(frame, ci, bAsync)
            end
        else
            LOG.ERROR("UIHelper.SetSpriteFrame: sp does not have setSpriteFrame or getSprite method.")
            return
        end
        if bKeepSize then
            UIHelper.SetContentSize(sp, w, h)
        end
    end
end

function UIHelper.GetSpriteFrame(szFrameName)
    return cc_spriteFrameCache:getSpriteFrame(szFrameName)
end

function UIHelper.SetTextureAntiAliasEnabled(tex, bEnabled)
    if not safe_check(tex) then
        return
    end

    if bEnabled then
        tex:setAntiAliasTexParameters()
    else
        tex:setAliasTexParameters()
    end
end

function UIHelper.ReloadTexture(szTextureFilePath)
    if not szTextureFilePath then
        return false
    end
    return cc.Director:getInstance():getTextureCache():reloadTexture(szTextureFilePath)
end

function UIHelper.GetTexture(node)
    if not safe_check(node) then
        return
    end

    return node:getTexture()
end

function UIHelper.SetTexture(node, textureFilePath, bAsync, funcLoadedCallback)
    if not safe_check(node) then
        return
    end
    if not textureFilePath then
        return
    end
    if bAsync == nil then
        bAsync = true
    end
    local w, h = UIHelper.GetContentSize(node)

    textureFilePath = string.gsub(textureFilePath, "\\", "/")

    if funcLoadedCallback then
        node:setTexture(textureFilePath, bAsync, funcLoadedCallback)
    else
        node:setTexture(textureFilePath, bAsync)
    end
    UIHelper.SetContentSize(node, w, h)
end

function UIHelper.SetTextureWithBlur(node, texture, bBlur, nBlurRadius, nBlurSampleNum, nWidth, nHeight)
    if not safe_check(node) then
        return
    end
    if not safe_check(texture) then
        return
    end

    local w, h = UIHelper.GetContentSize(node)
    if IsNumber(nWidth) and IsNumber(nHeight) then
        w = nWidth
        h = nHeight
    end

    if bBlur == nil then
        bBlur = false
    end
    if nBlurRadius == nil then
        nBlurRadius = 24
    end
    if nBlurSampleNum == nil then
        nBlurSampleNum = 10
    end
    node:setTextureWithBlur(texture, bBlur, nBlurRadius, nBlurSampleNum)
    UIHelper.SetContentSize(node, w, h)
end

function UIHelper.SetTextureWithBlurEx(node, texture, bBlur, nBlurRadius, nBlurSampleNum, nWidth, nHeight)
    if not safe_check(node) then
        LOG.ERROR("UIHelper.SetTextureWithBlurEx, node is null.")
        return
    end

    if not safe_check(texture) then
        LOG.ERROR("UIHelper.SetTextureWithBlurEx, texture is null.")
        return
    end

    local w, h = UIHelper.GetContentSize(node)
    if IsNumber(nWidth) and IsNumber(nHeight) then
        w = nWidth
        h = nHeight
    end

    if bBlur == nil then
        bBlur = false
    end
    if nBlurRadius == nil then
        nBlurRadius = 24
    end
    if nBlurSampleNum == nil then
        nBlurSampleNum = 10
    end

    local nWX, nWY = UIHelper.GetWorldPosition(node)
    UIHelper.SetWorldPosition(node, -nWX, -nWY)
    node:setTextureWithBlur(texture, bBlur, nBlurRadius, nBlurSampleNum)
    nWX, nWY = UIHelper.GetWorldPosition(node)
    UIHelper.SetWorldPosition(node, -nWX, -nWY)

    UIHelper.SetContentSize(node, w, h)
end

function UIHelper.ClearTexture(node)
    if not safe_check(node) then
        return
    end
    local w, h = UIHelper.GetContentSize(node)
    node:setTexture("")
    UIHelper.SetContentSize(node, w, h)
end

function UIHelper.GetTextureResourceName(node)
    if not safe_check(node) then
        return
    end

    local szName
    if node.getResourceName then
        szName = node:getResourceName()
    end

    if string.is_nil(szName) then
        local tex
        if node.getTexture then
            tex = node:getTexture()
        end

        if safe_check(tex) then
            szName = tex:getPath()
        end
    end

    return szName
end

function UIHelper.GetPositionY(node, parent)
    if not safe_check(node) then
        return
    end

    local nY = node:getPositionY()

    parent = parent or UIHelper.GetParent(node)
    if parent then
        local px, py = UIHelper.GetAnchorPoint(parent)
        local pw, ph = UIHelper.GetContentSize(parent)
        nY = nY - py * ph
    end

    return nY
end

function UIHelper.SetPositionX(node, nX, parent)
    if not safe_check(node) then
        return
    end

    parent = parent or UIHelper.GetParent(node)
    if parent then
        local px, py = UIHelper.GetAnchorPoint(parent)
        local pw, ph = UIHelper.GetContentSize(parent)
        nX = nX + px * pw
    end

    node:setPositionX(nX)
end

function UIHelper.SetPositionY(node, nY, parent)
    if not safe_check(node) then
        return
    end

    parent = parent or UIHelper.GetParent(node)
    if parent then
        local px, py = UIHelper.GetAnchorPoint(parent)
        local pw, ph = UIHelper.GetContentSize(parent)
        nY = nY + py * ph
    end

    node:setPositionY(nY)
end

function UIHelper.GetPosition(node, parent)
    if not safe_check(node) then
        return
    end
    local nX, nY = node:getPosition()

    parent = parent or UIHelper.GetParent(node)
    if parent then
        local px, py = UIHelper.GetAnchorPoint(parent)
        local pw, ph = UIHelper.GetContentSize(parent)
        nX = nX - px * pw
        nY = nY - py * ph
    end

    return nX, nY
end

function UIHelper.SetPosition(node, nX, nY, parent)
    if not safe_check(node) then
        return
    end

    parent = parent or UIHelper.GetParent(node)
    if parent then
        local px, py = UIHelper.GetAnchorPoint(parent)
        local pw, ph = UIHelper.GetContentSize(parent)
        nX = nX + px * pw
        nY = nY + py * ph
    end

    node:setPosition(nX, nY)
end

function UIHelper.SetSpriteColor(sprite, color, isHex)
    if not safe_check(sprite) then
        return
    end
    if not color then
        return
    end
    if isHex then
        color = UIHelper.ChangeHexColorStrToColor(color)
    end
    sprite.color = color
end

function UIHelper.ChangeHexColorStrToColor(hexColorStr)
    if not string.starts(hexColorStr, "#") then
        hexColorStr = string.format("#%s", hexColorStr)
    end

    local r, g, b = string.match(hexColorStr, "#(%x%x)(%x%x)(%x%x)") -- 将十六进制颜色字符串转换为RGB值
    if r and g and b then
        r = tonumber(r, 16)  -- 将RGB值转换为颜色值
        g = tonumber(g, 16)
        b = tonumber(b, 16)

        local color = cc.c3b(r, g, b)
        return color
    else
        return nil
    end
end

function UIHelper.GetWorldPosition(node)
    if not safe_check(node) then
        return
    end
    local nX, nY = node:getPosition()
    return UIHelper.ConvertToWorldSpace(node:getParent(), nX, nY)
end

function UIHelper.GetWorldPositionX(node)
    if not safe_check(node) then
        return
    end
    local nX, nY = UIHelper.GetWorldPosition(node)
    return nX
end

function UIHelper.GetWorldPositionY(node)
    if not safe_check(node) then
        return
    end
    local nX, nY = UIHelper.GetWorldPosition(node)
    return nY
end

function UIHelper.SetWorldPosition(node, nWorldPositionX, nWorldPositionY)
    if not safe_check(node) then
        return
    end
    if not node:getParent() then
        return
    end
    local nX, nY = UIHelper.ConvertToNodeSpace(node:getParent(), nWorldPositionX, nWorldPositionY)
    UIHelper.SetPosition(node, nX, nY)
end

function UIHelper.GetWidth(node)
    if not safe_check(node) then
        return
    end
    local nWidth, nHeight = UIHelper.GetContentSize(node)
    return nWidth
end

function UIHelper.GetHeight(node)
    if not safe_check(node) then
        return
    end
    local nWidth, nHeight = UIHelper.GetContentSize(node)
    return nHeight
end

function UIHelper.SetWidth(node, nWidth)
    if not safe_check(node) then
        return
    end
    local nHeight = UIHelper.GetHeight(node)
    UIHelper.SetContentSize(node, nWidth, nHeight)
end

function UIHelper.SetHeight(node, nHeight)
    if not safe_check(node) then
        return
    end
    local nWidth = UIHelper.GetWidth(node)
    UIHelper.SetContentSize(node, nWidth, nHeight)
end

function UIHelper.GetContentSize(node)
    if not safe_check(node) then
        return
    end
    local size = node:getContentSize()
    return size.width, size.height
end

function UIHelper.GetScaledContentSize(node)
    if not safe_check(node) then
        return
    end
    local size = node:getContentSize()
    local nScaleX, nScaleY = UIHelper.GetHierarchyScale(node)
    return size.width * nScaleX, size.height * nScaleY
end

function UIHelper.SetContentSize(node, nWidth, nHeight)
    if not safe_check(node) then
        return
    end
    node:setContentSize({ width = nWidth, height = nHeight })
end

function UIHelper.SetScaleX(node, nScale)
    if not safe_check(node) then
        return
    end
    node:setScaleX(nScale)
end

function UIHelper.SetScaleY(node, nScale)
    if not safe_check(node) then
        return
    end
    node:setScaleY(nScale)
end

function UIHelper.SetScale(node, nScaleX, nScaleY)
    if not safe_check(node) then
        return
    end
    node:setScale(nScaleX, nScaleY)
end

function UIHelper.GetScaleX(node)
    if not safe_check(node) then
        return
    end
    return node:getScaleX()
end

function UIHelper.GetScaleY(node)
    if not safe_check(node) then
        return
    end
    return node:getScaleY()
end

function UIHelper.GetScale(node)
    if not safe_check(node) then
        return
    end
    local nScale = node:getScale()
    return nScale
end

function UIHelper.SetAnchorPoint(node, nX, nY)
    if not safe_check(node) then
        return
    end
    node:setAnchorPoint({ x = nX, y = nY })
end

function UIHelper.GetAnchorPoint(node)
    if not safe_check(node) then
        return
    end
    local point = node:getAnchorPoint()
    return point.x, point.y
end

function UIHelper.ConvertToWorldSpace(node, nPositionX, nPositionY)
    if not safe_check(node) then
        return
    end
    local worldPos = node:convertToWorldSpace({ x = nPositionX, y = nPositionY })
    -- TODO 这里要和 ConvertToNodeSpace一样 做个 锚点和尺寸的转换计算
    return worldPos.x, worldPos.y
end

function UIHelper.ConvertToNodeSpace(parent, nWorldPositionX, nWorldPositionY)
    if not safe_check(parent) then
        return
    end
    local pos = parent:convertToNodeSpace({ x = nWorldPositionX, y = nWorldPositionY })

    local px, py = UIHelper.GetAnchorPoint(parent)
    local pw, ph = UIHelper.GetContentSize(parent)
    pos.x = pos.x - px * pw
    pos.y = pos.y - py * ph

    return pos.x, pos.y
end

function UIHelper.SetRotation(node, nRotation)
    if not safe_check(node) then
        return
    end
    node:setRotation(nRotation)
end

function UIHelper.GetRotation(node)
    if not safe_check(node) then
        return
    end
    return node:getRotation()
end

function UIHelper.Set2DRotation(sfx, nAngle, nYaw)
    if not safe_check(sfx) then
        return
    end
    return sfx:Set2DRotation(nAngle or 0, nYaw or 0)
end

function UIHelper.GetNodeEdgeXY(node, bScale)
    if not safe_check(node) then
        return
    end

    local nPosX, nPosY = UIHelper.GetWorldPosition(node)
    if not nPosX or not nPosY then
        return
    end

    local nSizeX, nSizeY
    if bScale then
        nSizeX, nSizeY = UIHelper.GetScaledContentSize(node)
    else
        nSizeX, nSizeY = UIHelper.GetContentSize(node)
    end
    local nAnchX, nAnchY = UIHelper.GetAnchorPoint(node)

    local nXMin = nPosX - nSizeX * nAnchX
    local nXMax = nPosX + nSizeX * (1 - nAnchX)
    local nYMin = nPosY - nSizeY * nAnchY
    local nYMax = nPosY + nSizeY * (1 - nAnchY)
    return nXMin, nXMax, nYMin, nYMax
end

function UIHelper.RemoveFromParent(node, bClean)
    if not safe_check(node) then
        return
    end
    node:removeFromParent(not not bClean)
end

function UIHelper.RemoveToCacheLayer(node, bClean)
    local cacheLayer = UIMgr.GetLayer(UILayer.Cache)
    if not safe_check(node) then
        return
    end
    DelayDestoryCocosNode(node)
    UIHelper.RemoveFromParent(node, bClean)
    UIHelper.RemoveComponent(node, "LuaBind", true)
    UIHelper.SetParent(node, cacheLayer)
end

function UIHelper.ClearCacheLayer()
    local cacheLayer = UIMgr.GetLayer(UILayer.Cache)
    UIHelper.RemoveAllChildren(cacheLayer)
end

function UIHelper.SetParent(node, parent)
    if not safe_check(node) then
        return
    end
    if not safe_check(parent) then
        return
    end
    node:retain() --引用计数+1，防止Remove后释放
    node:removeFromParent(false)
    parent:addChild(node)
    node:release() --引用计数-1
end

function UIHelper.GetParent(node)
    if not safe_check(node) then
        return
    end
    return node:getParent()
end

function UIHelper.SetGlobalZOrder(node, nZOrder, bAllChild)
    if not safe_check(node) then
        return
    end
    node:setGlobalZOrder(nZOrder)

    if bAllChild then
        local tbChildrens = node:getChildren()
        if tbChildrens then
            for i = 1, #tbChildrens do
                local childNode = tbChildrens[i]
                if nZOrder ~= 0 then
                    nZOrder = nZOrder + i
                end
                UIHelper.SetGlobalZOrder(childNode, nZOrder, true)
            end
        end
    end
end

function UIHelper.GetGlobalZOrder(node)
    if not safe_check(node) then
        return
    end
    return node:getGlobalZOrder()
end

function UIHelper.SetLocalZOrder(node, nZ)
    if not safe_check(node) then
        return
    end
    return node:setLocalZOrder(nZ)
end

function UIHelper.GetLocalZOrder(node)
    if not safe_check(node) then
        return
    end
    return node:getLocalZOrder()
end

function UIHelper.SetName(node, szName)
    if not safe_check(node) then
        return
    end
    node:setName(szName)
end

function UIHelper.GetName(node)
    if not safe_check(node) then
        return
    end
    return node:getName()
end

function UIHelper.SetTag(node, nTag)
    if not safe_check(node) then
        return
    end
    node:setTag(nTag)
end

function UIHelper.GetTag(node)
    if not safe_check(node) then
        return
    end
    return node:getTag()
end

function UIHelper.GetChildByTag(node, nTag)
    if not safe_check(node) then
        return
    end
    return node:getChildByTag(nTag)
end

function UIHelper.GetChildByName(node, szName)
    if not safe_check(node) then
        return
    end
    return node:getChildByName(szName)
end

function UIHelper.GetChildByPath(node, szPath)
    if not safe_check(node) then
        return
    end

    local childNode = node:getChildByName(szPath) --tableview下的protected node用这种方法无法获取
    if childNode then
        return childNode
    end

    local szName, szSubPath = string.match(szPath, "(.-)/(.*)")
    local children = UIHelper.GetChildren(node)
    for _, child in ipairs(children) do
        if UIHelper.GetVisible(child) then
            local szChildName = child:getName()
            if szName and szChildName == szName then
                return UIHelper.GetChildByPath(child, szSubPath)
            elseif szChildName == szPath then
                return child
            end
        end
    end

end

function UIHelper.SetMaxPercent(slider, nPercent)
    if not safe_check(slider) then
        return
    end
    slider:setMaxPercent(nPercent)
end

function UIHelper.UpdateVisualSlider(slider)
    if not safe_check(slider) then
        return
    end
    slider:updateVisualSlider()
end

function UIHelper.SetProgressBarPercent(node, nPercent)
    if not safe_check(node) then
        return
    end
    if not nPercent then
        return
    end

    if nPercent == 0 then
        nPercent = 0.01
    end

    if node.setPercentage then
        node:setPercentage(nPercent)
    else
        node:setPercent(nPercent)
    end
end

function UIHelper.GetProgressBarPercent(node)
    if not safe_check(node) then
        return
    end
    if node.getPercentage then
        return node:getPercentage()
    else
        return node:getPercent()
    end
end

function UIHelper.SetProgressBarStarPercentPt(node, nX, nY)
    if not safe_check(node) then
        return
    end
    if node.setStarPercentPt then
        node:setStarPercentPt({ x = nX, y = nY })
    end

end

function UIHelper.BindUIEvent(btn, nEventType, func)
    local _doBindUIEvent = function(btn, nEventType, func)
        if not safe_check(btn) then
            return
        end

        if nEventType == EventType.OnClick then
            btn:addClickEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnTouchBegan then
            btn:addTouchBeganEventListener(func) -- func(btn, x, y)
        elseif nEventType == EventType.OnTouchMoved then
            btn:addTouchMovedEventListener(func) -- func(btn, x, y)
        elseif nEventType == EventType.OnTouchEnded then
            btn:addTouchEndedEventListener(func) -- func(btn, x, y)
        elseif nEventType == EventType.OnTouchCanceled then
            btn:addTouchCanceledEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnSelectChanged then
            btn:addEventListener(function(btn, eventType)
                func(btn, eventType == 0)
            end) -- func(btn, bSelected)
        elseif nEventType == EventType.OnLongPress then
            -- 长按的时间默认为1秒，如有特殊需求，可以设置btn:setLongPressDelay(3)
            btn:addLongPressEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnPersistentPress then
            btn:addPersistentPressEventListener(func) -- func(btn, nCount)
        elseif nEventType == EventType.OnDragOver then
            btn:addDragOverEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnDragOut then
            btn:addDragOutEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnChangeSliderPercent then
            btn:addEventListener(func) -- func(btn, ccui.SliderEventType nSliderEvent)
        elseif nEventType == EventType.OnScrollingScrollView then
            btn:addEventListener(func) -- func(btn, ccui.ScrollviewEventType nSliderEvent)
        elseif nEventType == EventType.OnVideoStateChanged then
            btn:addEventListener(func) -- func(btn, ccui.VideoPlayerEvent nVideoPlayerEvent)
        elseif nEventType == EventType.OnTurningPageView then
            btn:addEventListener(func) -- func(btn)
        elseif nEventType == EventType.OnToggleGroupSelectedChanged then
            btn:addEventListener(func)
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

function UIHelper.UnBindUIEvent(btn, nEventType)
    local _doUnBindUIEvent = function(btn, nEventType)
        if not safe_check(btn) then
            return
        end

        if nEventType == EventType.OnClick then
            btn:addClickEventListener()
        elseif nEventType == EventType.OnTouchBegan then
            btn:addTouchBeganEventListener()
        elseif nEventType == EventType.OnTouchMoved then
            btn:addTouchMovedEventListener()
        elseif nEventType == EventType.OnTouchEnded then
            btn:addTouchEndedEventListener()
        elseif nEventType == EventType.OnTouchCanceled then
            btn:addTouchCanceledEventListener()
        elseif nEventType == EventType.OnLongPress then
            btn:addLongPressEventListener()
        elseif nEventType == EventType.OnPersistentPress then
            btn:addPersistentPressEventListener()
        elseif nEventType == EventType.OnDragOver then
            btn:addDragOverEventListener()
        elseif nEventType == EventType.OnDragOut then
            btn:addDragOutEventListener()
        end
    end

    if IsTable(btn) then
        for k, v in ipairs(btn) do
            _doUnBindUIEvent(v, nEventType)
        end
    else
        _doUnBindUIEvent(btn, nEventType)
    end
end

function UIHelper.SetTouchEnabled(btn, bEnable)
    if not safe_check(btn) then
        return
    end

    if btn.setTouchEnabled then
        btn:setTouchEnabled(bEnable)
    end
end

function UIHelper.GetTouchEnabled(btn)
    if not safe_check(btn) then
        return
    end

    local bTouchEnabled = false
    if btn.isTouchEnabled then
        bTouchEnabled = btn:isTouchEnabled()
    end

    return bTouchEnabled
end

function UIHelper.SetButtonClickSound(btn, szFileName)
    if not safe_check(btn) then
        return
    end
    szFileName = szFileName or ""
    btn:setClickSoundFileName(szFileName)
end

function UIHelper.GetButtonState(btn)
    if btn.nBtnState then
        return btn.nBtnState
    else
        return BTN_STATE.Normal
    end
end

function UIHelper.SetButtonState(btn, nState, param, bWithGray, bWithColor)
    if not safe_check(btn) then
        return
    end
    if not nState then
        return
    end

    if btn.nBtnState and btn.nBtnState == nState then
        return
    end

    btn.nBtnState = nState

    if bWithGray == nil then
        bWithGray = true
    end
    if bWithColor == nil then
        bWithColor = true
    end

    if bWithGray then
        UIHelper.SetNodeGray(btn, nState == BTN_STATE.Disable, true)
    end

    if bWithColor then
        if nState == BTN_STATE.Disable then
            UIHelper.SetColor(btn, cc.c3b(155, 155, 155))
        else
            UIHelper.SetColor(btn, cc.c3b(255, 255, 255))
        end
    end

    if nState == BTN_STATE.Normal then
        btn:addDisableClickEventListener()
        -- btn:setEnabled(true)
        return
    end

    if nState == BTN_STATE.Disable then
        if param then
            if IsString(param) and not string.is_nil(param) then
                btn:addDisableClickEventListener(function()
                    TipsHelper.ShowNormalTip(param)
                end)
            elseif IsFunction(param) then
                btn:addDisableClickEventListener(param)
            end
        else
            btn:addDisableClickEventListener(function()
            end)
        end
        -- btn:setEnabled(false)
        return
    end
end

function UIHelper.SetSwallowTouches(btn, bSwallow)
    if not safe_check(btn) then
        return
    end
    btn:setSwallowTouches(bSwallow)
end

function UIHelper.SetClickInterval(btn, nInterval)
    if not safe_check(btn) then
        return
    end
    btn:setClickInterval(nInterval)
end

function UIHelper.SimulateClick(btn)
    if not safe_check(btn) then
        return
    end

    btn:SimulateClick()
end

---@param nThreshold number 单位为像素点 默认值为30
function UIHelper.SetLongPressDistThreshold(btn, nThreshold)
    if not safe_check(btn) then
        return
    end
    if btn.setLongPressDistThreshold then
        btn:setLongPressDistThreshold(nThreshold)
    end
end

---@param nDelay number 单位为秒
function UIHelper.SetLongPressDelay(btn, nDelay)
    if not safe_check(btn) then
        return
    end
    btn:setLongPressDelay(nDelay)
end

-- nPercent [0, 100]
function UIHelper.ScrollToPercent(scrollView, nPercent, nTimeInSec, bAttenuated)
    if not safe_check(scrollView) then
        return
    end

    if not nPercent or nPercent < 0 then
        nPercent = 0
    end
    if not nTimeInSec or nTimeInSec < 0 then
        nTimeInSec = 0
    end
    if bAttenuated == nil then
        bAttenuated = false
    end

    local nDirection = scrollView:getDirection()
    if nDirection == ccui.ScrollViewDir.horizontal then
        scrollView:scrollToPercentHorizontal(nPercent, nTimeInSec, bAttenuated)
    elseif nDirection == ccui.ScrollViewDir.vertical then
        scrollView:scrollToPercentVertical(nPercent, nTimeInSec, bAttenuated)
    elseif nDirection == ccui.ScrollViewDir.both then
        scrollView:scrollToPercentHorizontal(nPercent, nTimeInSec, bAttenuated)
        scrollView:scrollToPercentVertical(nPercent, nTimeInSec, bAttenuated)
    end
end

---- 垂直滚动到ScrollView内的指定Node
function UIHelper.ScrollLocateToPreviewItem(scrollView, node, nLocateType, nTimeInSec)
    if not safe_check(scrollView) then
        return
    end

    if not safe_check(node) then
        return
    end
    nTimeInSec = nTimeInSec or 0

    local layout = scrollView:getInnerContainer()
    local nPosX, nPosY = UIHelper.GetWorldPosition(node)
    local nSizeX, nSizeY = UIHelper.GetContentSize(node)
    local nAnchX, nAnchY = UIHelper.GetAnchorPoint(node)
    local nXMin = nPosX - nSizeX * nAnchX
    local nXMax = nPosX + nSizeX * (1 - nAnchX)
    local nYMin = nPosY - nSizeY * nAnchY
    local nYMax = nPosY + nSizeY * (1 - nAnchY)
    local _, nLayoutHeight = UIHelper.GetContentSize(layout)
    local _, nScreenHeight = UIHelper.GetContentSize(scrollView)
    local nLen = nLayoutHeight - nScreenHeight

    local nCenterX = (nXMin + nXMax) / 2
    local nCenterY = (nYMin + nYMax) / 2
    local nSpaceX, nSpaceY
    local nPos
    if nLocateType == Locate.TO_TOP then
        nSpaceX, nSpaceY = UIHelper.ConvertToNodeSpace(layout, nXMax, nYMax)
        nPos = nLayoutHeight - nSpaceY
    elseif nLocateType == Locate.TO_CENTER then
        nSpaceX, nSpaceY = UIHelper.ConvertToNodeSpace(layout, nCenterX, nCenterY)
        nPos = (nLayoutHeight - nSpaceY) - nScreenHeight / 2
    elseif nLocateType == Locate.TO_BOTTOM then
        nSpaceX, nSpaceY = UIHelper.ConvertToNodeSpace(layout, nXMin, nYMin)
        nPos = (nLayoutHeight - nSpaceY) - nScreenHeight
    end

    if nLen <= 0 then
        nLen = 1
    end
    local nPercent = nPos * 100 / nLen
    if nPercent <= 0 then
        nPercent = 0
    end
    if nPercent >= 100 then
        nPercent = 100
    end
    UIHelper.ScrollToPercent(scrollView, nPercent, nTimeInSec)
end

function UIHelper.IsPreviewItemInView(scrollView, node)
    if not safe_check(scrollView) then
        return
    end

    if not safe_check(node) then
        return
    end

    local nHeight = UIHelper.GetHeight(scrollView)
    local nAnchScrollX, nAnchScrollY = UIHelper.GetAnchorPoint(scrollView)
    local nScrollX, nScrollY = UIHelper.GetWorldPosition(scrollView)
    local nBottomScrollX, nBottomScrollY = nScrollX, nScrollY - nAnchScrollY * nHeight
    local nTopX, nTopY = nScrollX, nScrollY + (1 - nAnchScrollY) * nHeight

    local nNodeY = UIHelper.GetWorldPositionY(node)
    local nWidth, nHeight = UIHelper.GetContentSize(node)
    local nAnchX, nAnchY = UIHelper.GetAnchorPoint(node)

    local nNodeTopY = nNodeY + nHeight * (1 - nAnchY)
    local nNodeBottomY = nNodeY - nHeight * nAnchY

    return nNodeTopY <= nTopY and nNodeBottomY >= nBottomScrollY
end

-- 滚动到ScrollView内的第nIndex个Node的位置(从0开始)
function UIHelper.ScrollToIndex(scrollView, nIndex, nTimeInSec, bAttenuated)
    if not safe_check(scrollView) then
        return
    end

    if not nIndex or nIndex < 0 then
        nIndex = 0
    end
    if not nTimeInSec or nTimeInSec < 0 then
        nTimeInSec = 0
    end
    if bAttenuated == nil then
        bAttenuated = false
    end

    local nDirection = scrollView:getDirection()
    if nDirection == ccui.ScrollViewDir.horizontal then
        scrollView:scrollToIndexHorizontal(nIndex, nTimeInSec, bAttenuated)
    elseif nDirection == ccui.ScrollViewDir.vertical then
        scrollView:scrollToIndexVertical(nIndex, nTimeInSec, bAttenuated)
    elseif nDirection == ccui.ScrollViewDir.both then
        scrollView:scrollToIndexBothDirection(nIndex, nTimeInSec, bAttenuated)
    end
end

function UIHelper.ScrollToTop(scrollView, nTimeInSec, bAttenuated)
    if not safe_check(scrollView) then
        return
    end

    if not nTimeInSec or nTimeInSec < 0 then
        nTimeInSec = 0
    end
    if bAttenuated == nil then
        bAttenuated = false
    end

    scrollView:scrollToTop(nTimeInSec, bAttenuated)
end

function UIHelper.ScrollToBottom(scrollView, nTimeInSec, bAttenuated)
    if not safe_check(scrollView) then
        return
    end

    if not nTimeInSec or nTimeInSec < 0 then
        nTimeInSec = 0
    end
    if bAttenuated == nil then
        bAttenuated = false
    end

    scrollView:scrollToBottom(nTimeInSec, bAttenuated)
end

function UIHelper.ScrollToLeft(scrollView, nTimeInSec, bAttenuated)
    if not safe_check(scrollView) then
        return
    end

    if not nTimeInSec or nTimeInSec < 0 then
        nTimeInSec = 0
    end
    if bAttenuated == nil then
        bAttenuated = false
    end

    scrollView:scrollToLeft(nTimeInSec, bAttenuated)
end

function UIHelper.ScrollToRight(scrollView, nTimeInSec, bAttenuated)
    if not safe_check(scrollView) then
        return
    end

    if not nTimeInSec or nTimeInSec < 0 then
        nTimeInSec = 0
    end
    if bAttenuated == nil then
        bAttenuated = false
    end

    scrollView:scrollToRight(nTimeInSec, bAttenuated)
end

function UIHelper.ScrollToPage(pageView, nIndex, nTimeInSec)
    if not safe_check(pageView) then
        return
    end
    if not nIndex then
        return
    end

    if not nTimeInSec or nTimeInSec < 0 then
        nTimeInSec = 0
    end

    pageView:scrollToPage(nIndex, nTimeInSec)
end

function UIHelper.GetScrollPercent(scrollView)
    local nPercent = 0
    if safe_check(scrollView) then
        local nDirection = scrollView:getDirection()
        if nDirection == ccui.ScrollViewDir.horizontal then
            nPercent = scrollView:getScrolledPercentHorizontal()
        elseif nDirection == ccui.ScrollViewDir.vertical then
            nPercent = scrollView:getScrolledPercentVertical()
        end
    end
    return nPercent
end

function UIHelper.SetImmediatelyDoLayoutWhenSizeChange(scrollView, bValue)
    if not safe_check(scrollView) then
        return
    end

    scrollView:setImmediatelyDoLayoutWhenSizeChange(bValue)
end

function UIHelper.GetScrollViewSlide(scrollView, nThresholdX, nThresholdY)
    if not safe_check(scrollView) then
        return
    end
    local layout = scrollView:getInnerContainer()
    if not safe_check(layout) then
        return
    end

    nThresholdX = nThresholdX or 0
    nThresholdY = nThresholdY or 0
    local nLayoutWidth, nLayoutHeight = UIHelper.GetContentSize(layout)
    local nScreenWidth, nScreenHeight = UIHelper.GetContentSize(scrollView)

    local nDirection = scrollView:getDirection()
    local nLen, bCanSlide
    if nDirection == ccui.ScrollViewDir.horizontal then
        nLen = nScreenWidth - nLayoutWidth
        bCanSlide = nLen < nThresholdX
        return bCanSlide
    elseif nDirection == ccui.ScrollViewDir.vertical then
        nLen = nScreenHeight - nLayoutHeight
        bCanSlide = nLen < nThresholdY
        return bCanSlide
    elseif nDirection == ccui.ScrollViewDir.both then
        local nLen1 = nScreenWidth - nLayoutWidth
        nLen = nScreenHeight - nLayoutHeight
        bCanSlide = nLen1 < nThresholdX or nLen < nThresholdY
        return bCanSlide
    end
end

function UIHelper.GetHorizontalScrollPercent(scrollView)
    local nPercent = 0
    if safe_check(scrollView) then
        nPercent = scrollView:getScrolledPercentHorizontal()
    end
    return nPercent
end

function UIHelper.GetScrolledPosition(scrollView)
    if not safe_check(scrollView) then
        return
    end
    local position = scrollView:getInnerContainerPosition()
    return position.x, position.y
end

function UIHelper.SetScrolledPosition(scrollView, nX, nY)
    if not safe_check(scrollView) then
        return
    end
    return scrollView:setInnerContainerPosition({ x = nX, y = nY })
end

function UIHelper.GetInnerContainerSize(scrollView)
    if not safe_check(scrollView) then
        return
    end
    local size = scrollView:getInnerContainerSize()
    return size.width, size.height
end

function UIHelper.SetInnerContainerSize(scrollView, nWidth, nHeight)
    if not safe_check(scrollView) then
        return
    end
    return scrollView:setInnerContainerSize(cc.size(nWidth, nHeight))
end

function UIHelper.SetScrollViewBackgroundImage(scrollView, pngName)
    if not safe_check(scrollView) then
        return
    end
    scrollView:getInnerContainer():setBackGroundImage(pngName)
    scrollView:getInnerContainer():setBackGroundImageScale9Enabled(true)
end

function UIHelper.SetScrollViewLayoutPaddingTop(scrollView, nTop)
    if not safe_check(scrollView) then
        return
    end
    local layout = scrollView:getInnerContainer()
    if layout and layout.setPaddingTop then
        layout:setPaddingTop(nTop)
    end
end

function UIHelper.SetScrollViewLayoutPaddingBottom(scrollView, nBottom)
    if not safe_check(scrollView) then
        return
    end
    local layout = scrollView:getInnerContainer()
    if layout and layout.setPaddingBottom then
        layout:setPaddingBottom(nBottom)
    end
end

function UIHelper.SetScrollViewLayoutPaddingLeft(scrollView, nLeft)
    if not safe_check(scrollView) then
        return
    end
    local layout = scrollView:getInnerContainer()
    if layout and layout.setPaddingLeft then
        layout:setPaddingLeft(nLeft)
    end
end

function UIHelper.SetScrollViewLayoutPaddingRight(scrollView, nRight)
    if not safe_check(scrollView) then
        return
    end
    local layout = scrollView:getInnerContainer()
    if layout and layout.setPaddingRight then
        layout:setPaddingRight(nRight)
    end
end

function UIHelper.SetScrollEnabled(scrollView, bEnabled)
    if not safe_check(scrollView) then
        return
    end

    return scrollView:setScrollEnabled(bEnabled)
end

function UIHelper.SetScrollRightMouseEnable(scrollView, bEnabled)
    if not safe_check(scrollView) then
        return
    end

    return scrollView:setRightMouseEnable(bEnabled)
end

function UIHelper.SetLayoutBackGroundImage(layout, szImage, texType)
    if not safe_check(layout) then
        return
    end
    if texType then
        layout:setBackGroundImage(szImage, texType)
    else
        layout:setBackGroundImage(szImage)
    end
end

function UIHelper.SetBackGroundImageOpacity(layout, nOpacity)
    if not safe_check(layout) then
        return
    end

    layout:setBackGroundImageOpacity(nOpacity)
end

function UIHelper.GetPageIndex(pageView)
    if not safe_check(pageView) then
        return
    end
    return pageView:getCurrentPageIndex()
end

function UIHelper.SetPageIndex(pageView, nIndex)
    if not safe_check(pageView) then
        return
    end
    if not nIndex then
        return
    end
    return pageView:setCurrentPageIndex(nIndex)
end

function UIHelper.PageViewAddPage(pageView, nPrefabID, ...)
    if not safe_check(pageView) or not nPrefabID then
        return
    end

    local nodeScript = UIHelper.AddPrefab(nPrefabID, pageView, ...)
    if not nodeScript then
        return
    end

    local node = nodeScript._rootNode
    if not safe_check(node) then
        return
    end

    node:retain()
    node:removeFromParent()
    node:release()

    local widget = ccui.Widget:create()
    widget:setCascadeOpacityEnabled(true)
    widget:setName(node:getName())
    widget:setAnchorPoint(UIHelper.GetAnchorPoint(node))
    widget:setContentSize(UIHelper.GetContentSize(node))
    widget:setPosition(node:getPosition())
    node:setAnchorPoint(0, 0)
    node:setPosition(0, 0)
    widget:addChild(node)
    pageView:addPage(widget)

    return nodeScript
end

--nIndex从零开始计数
function UIHelper.RemovePageAtIndex(pageView, nIndex)
    if not pageView or not nIndex then
        return
    end
    pageView:removePageAtIndex(nIndex)
end

function UIHelper.GetItem(pageView, nIndex)
    if not pageView or not nIndex then
        return
    end
    return pageView:getItem(nIndex)
end

function UIHelper.InsertPage(pageView, nPrefabID, nIndex, ...)
    if not safe_check(pageView) or not nPrefabID or not nIndex then
        return
    end

    local nodeScript = UIHelper.AddPrefab(nPrefabID, pageView, ...)
    if not nodeScript then
        return
    end

    local node = nodeScript._rootNode
    if not safe_check(node) then
        return
    end

    node:retain()
    node:removeFromParent()
    node:release()

    local widget = ccui.Widget:create()
    widget:setName(node:getName())
    widget:setAnchorPoint(UIHelper.GetAnchorPoint(node))
    widget:setContentSize(UIHelper.GetContentSize(node))
    widget:setPosition(node:getPosition())
    node:setAnchorPoint(0, 0)
    node:setPosition(0, 0)
    widget:addChild(node)
    pageView:insertPage(widget, nIndex)

    return nodeScript
end

function UIHelper.GetListViewItems(listView)
    if not safe_check(listView) then
        return
    end

    return listView:getItems()
end

function UIHelper.SetScrollBounceEnabled(scrollView, bEnable)
    if not safe_check(scrollView) then
        return
    end
    scrollView:setBounceEnabled(bEnable)
end

function UIHelper.SetScrollViewMouseWheelEnabled(scrollView, bEnabled)
    if not safe_check(scrollView) then
        return
    end
    if not scrollView.setMouseWheelEnabled then
        return
    end
    scrollView:setMouseWheelEnabled(bEnabled)
end

function UIHelper.SetInertiaVelocityRatio(scrollView, fRatio)
    if not safe_check(scrollView) or not fRatio then
        return
    end
    scrollView:setInertiaVelocityRatio(fRatio)
end

function UIHelper.SetInertiaScrollEnabled(scrollView, bEnable)
    if not safe_check(scrollView) then
        return
    end
    scrollView:setInertiaScrollEnabled(bEnable)
end

function UIHelper.AddDidScrollCallback(scrollView, callback)
    if not safe_check(scrollView) then
        return
    end
    scrollView:setDelegate()
    scrollView:registerScriptHandler(function(scrollView)
        if IsFunction(callback) then
            callback(scrollView)
        end
    end, 0)
end

function UIHelper.SetCombinedBatchEnabled(node, bEnable)
    if not safe_check(node) then
        return
    end

    node:setCombinedBatchEnabled(bEnable)
end

function UIHelper.SetScrollViewCombinedBatchEnabled(scrollView, bEnable)
    if not safe_check(scrollView) then
        return
    end

    local innerContainer = scrollView:getInnerContainer()
    if innerContainer then
        innerContainer:setCombinedBatchEnabled(bEnable)
    end
end

function UIHelper.ScrollViewDoLayout(scrollView)
    if not safe_check(scrollView) then
        return
    end

    local innerContainer = scrollView:getInnerContainer()
    if innerContainer then
        innerContainer:forceDoLayout()
    end

    scrollView:updateBoundary()
end

function UIHelper.ScrollViewDoLayoutAndToTop(scrollView)
    UIHelper.ScrollViewDoLayout(scrollView)
    UIHelper.ScrollToTop(scrollView, 0)
end

function UIHelper.ScrollViewDoLayoutAndToLeft(scrollView)
    UIHelper.ScrollViewDoLayout(scrollView)
    UIHelper.ScrollToLeft(scrollView, 0)
end

function UIHelper.ScrollViewSetupArrow(scrollView, arrowParent)
    if not safe_check(scrollView) or not safe_check(arrowParent) then
        return
    end

    local widgetArrow = arrowParent._widgetArrow
    if not widgetArrow or not IsUserData(widgetArrow) then
        arrowParent._widgetArrow = UIHelper.AddPrefab(PREFAB_ID.WidgetArrow, arrowParent)
        widgetArrow = arrowParent._widgetArrow
    end

    local SHOW_SCROLL_GUILD_CRITICAL_VALUE = -30
    local bCanSlide = UIHelper.GetScrollViewSlide(scrollView, nil, SHOW_SCROLL_GUILD_CRITICAL_VALUE)

    if bCanSlide then
        UIHelper.SetVisible(widgetArrow, true)
        UIHelper.BindUIEvent(scrollView, EventType.OnScrollingScrollView, function(_, eventType)
            if eventType == ccui.ScrollviewEventType.scrollToBottom then
                UIHelper.SetVisible(widgetArrow, false)
            end
            UIHelper.UnBindUIEvent(scrollView, EventType.OnScrollingScrollView)
        end)
    else
        UIHelper.SetVisible(widgetArrow, false)
    end
end

--[[

@ scriptScrollViewTree: 结构树脚本；
@ nContainerPrefabID: Container预制ID，注意该预制要挂UIScrollViewTreeContainer脚本并绑定LayoutContent和ToggleSelect；
@ nItemPrefabID：默认Item项预制ID；
@ fnInitContainer：Container如何初始化
fnInitContainer = function(scriptContainer, tArgs) ... end
作用：可在Container预制挂上UIScrollViewTreeContainer脚本后，再多拖一些自己的组件进去并自定义这些组件要如何显示内容

@ tData = {
	[1] = {
		tArgs = { XXX = XXX }, --Container初始化（调用fnInitContainer）时传入的参数
		tItemList = {
			[1] = {
				nPrefabID = XXX --可空，若不填则用nItemPrefabID
				tArgs = { XXX = XXX, XXX = XXX}  --Item AddPrefab时传入的参数
			},
			[2] = ...
		},
		fnSelectedCallback = function(bSelected) ... end, --选中Container的回调，可空
	},
	[2] = ...
}

@bDelayLoad：是否延迟加载，用于Item特别多的情况，当点开Container时才加载Item

--]]
--用法示例见：UIPvPCampRewardView:Test()
function UIHelper.SetupScrollViewTree(scriptScrollViewTree, nContainerPrefabID, nItemPrefabID, fnInitContainer, tData, bDelayLoad)
    if not scriptScrollViewTree or not scriptScrollViewTree.AddContainer then
        return
    end

    scriptScrollViewTree:OnInit(nContainerPrefabID, fnInitContainer, nItemPrefabID)
    for i, v in ipairs(tData) do
        scriptScrollViewTree:AddContainer(v.tArgs, v.tItemList, v.fnSelectedCallback, v.fnOnCickCallBack, bDelayLoad)
    end
    scriptScrollViewTree:UpdateInfo()
end

function UIHelper.SetScrollBarPositionFromCorner(scrollView, nPositionX, nPositionY)
    if not safe_check(scrollView) then
        return
    end
    scrollView:setScrollBarPositionFromCorner({ x = nPositionX, y = nPositionY })
end

function UIHelper.SetScrollBarWidth(scrollView, nWidth)
    if not safe_check(scrollView) then
        return
    end
    scrollView:setScrollBarWidth(nWidth)
end

function UIHelper.LayoutDoLayout(layout)
    if not safe_check(layout) then
        return
    end
    if layout.forceDoLayout then
        layout:forceDoLayout()
    end
end

-- 延迟nFrame帧后再执行LayoutDoLayout(layout)
-- 也就是不要在同一帧内执行多次LayoutDoLayout(layout)，提供性能
function UIHelper.DelayFrameLayoutDoLayout(script, layout, nFrame)
    if not script or not safe_check(layout) then
        return
    end

    if not script.__delayFrameTab then
        script.__delayFrameTab = {}
    end

    local szKey = tostring(layout)

    if not script.__delayFrameTab[szKey] then
        script.__delayFrameTab[szKey] = {nLastTick = 0, nTimerID = nil}
    end

    -- 如果是同一帧的 LayoutDoLayout(layout)，则不执行
    if Global.nUITickCount - script.__delayFrameTab[szKey].nLastTick < 1 then
        return
    end

    if not nFrame then
        nFrame = 1
    end

    script.__delayFrameTab[szKey].nLastTick = Global.nUITickCount or 0
    Timer.DelTimer(script, script.__delayFrameTab[szKey].nTimerID)
    script.__delayFrameTab[szKey].nTimerID = Timer.AddFrame(script, nFrame, function()
        -- 因为脚本在释放的时候会Timer.DelAllTimer()，所以这里不用layout担心野指针
        UIHelper.LayoutDoLayout(layout)
        script.__delayFrameTab[szKey] = nil
    end)
end

function UIHelper.SetPaddingLayoutTop(layout, nTop)
    if not safe_check(layout) then
        return
    end
    if layout.setPaddingTop then
        layout:setPaddingTop(nTop)
    end
end

function UIHelper.SetPaddingLayoutBottom(layout, nBottom)
    if not safe_check(layout) then
        return
    end
    if layout.setPaddingBottom then
        layout:setPaddingBottom(nBottom)
    end
end

function UIHelper.SetPaddingLayoutLeft(layout, nLeft)
    if not safe_check(layout) then
        return
    end
    if layout.setPaddingLeft then
        layout:setPaddingLeft(nLeft)
    end
end

function UIHelper.SetPaddingLayoutRight(layout, nRight)
    if not safe_check(layout) then
        return
    end
    if layout.setPaddingRight then
        layout:setPaddingRight(nRight)
    end
end

function UIHelper.LayoutSetSpacingX(layout, nSpacingX)
    if not safe_check(layout) then
        return
    end
    if layout.setSpacingX then
        layout:setSpacingX(nSpacingX)
    end
end

function UIHelper.LayoutSetSpacingY(layout, nSpacingY)
    if not safe_check(layout) then
        return
    end
    if layout.setSpacingY then
        layout:setSpacingY(nSpacingY)
    end
end

function UIHelper.LayoutGetSpacingX(layout)
    if not safe_check(layout) then
        return
    end
    if layout.getSpacingX then
        return layout:getSpacingX()
    end
    return 0
end

function UIHelper.LayoutGetSpacingY(layout)
    if not safe_check(layout) then
        return
    end
    if layout.getSpacingY then
        return layout:getSpacingY()
    end
    return 0
end

function UIHelper.WidgetFoceDoAlign(script)
    if not script then
        return
    end
    if not script._widgetMgr then
        return
    end
    if script._widgetMgr.forceDoAlign then
        script._widgetMgr:forceDoAlign()
    end
end

function UIHelper.WidgetFoceDoAlignAssignNode(script, node)
    if not safe_check(node) then
        return
    end

    if not script then
        return
    end
    if not script._widgetMgr then
        return
    end
    if script._widgetMgr.forceDoAlignAssignNode then
        script._widgetMgr:forceDoAlignAssignNode(node)
    end
end

function UIHelper.SetPosAndSizeByRefNode(node, refNode, tPaddingArr)
    if not safe_check(node) then
        return
    end
    local parent = node:getParent()
    assert(parent)

    local tRefSize = refNode:getContentSize()
    local tLB = cc.p(0, 0)
    local tRT = cc.p(tRefSize.width, tRefSize.height)
    tLB = parent:convertToNodeSpace(refNode:convertToWorldSpace(tLB))
    tRT = parent:convertToNodeSpace(refNode:convertToWorldSpace(tRT))

    if tPaddingArr then
        local n = #tPaddingArr
        local l, t, r, b
        if 1 == n then
            b = tPaddingArr[1]
            l, t, r = b, b, b
        elseif 2 == n then
            l = tPaddingArr[1]
            r = l
            t = tPaddingArr[2]
            b = t
        elseif 4 == n then
            l = tPaddingArr[1]
            r = tPaddingArr[2]
            t = tPaddingArr[3]
            b = tPaddingArr[4]
        end
        assert(b)
        tLB.x = tLB.x + l
        tLB.y = tLB.y + b
        tRT.x = tRT.x - r
        tRT.y = tRT.y - t
    end

    local width = tRT.x - tLB.x
    local height = tRT.y - tLB.y
    node:setContentSize(cc.size(width, height))
    local tAnchor = node:getAnchorPoint()
    node:setPosition(tLB.x + width * tAnchor.x, tLB.y + height * tAnchor.y)
end

local _boxOutsideForTouchLikeTips
local _fnTouchOutsideForTouchLikeTips
function UIHelper.ClearTouchLikeTips()
    if _boxOutsideForTouchLikeTips then
        local box = _boxOutsideForTouchLikeTips
        _boxOutsideForTouchLikeTips = nil
        UIHelper.RemoveFromParent(box)
    end
    if _fnTouchOutsideForTouchLikeTips then
        local fn = _fnTouchOutsideForTouchLikeTips
        _fnTouchOutsideForTouchLikeTips = nil
        fn()
    end
end
-- 注: 由于界面开关可以通过非touch的方式触发(如热键), 故需要在调用本函数相关的View的OnExit中调用上面的清理函数
function UIHelper.SetTouchLikeTips(tipsNode, rootNode, fnTouchOutside)
    if not safe_check(tipsNode) then
        return
    end
    if not safe_check(rootNode) then
        return
    end

    UIHelper.ClearTouchLikeTips()
    _fnTouchOutsideForTouchLikeTips = fnTouchOutside

    local boxOutside = ccui.Layout:create()
    boxOutside:setName("_boxOutsideForTouchLikeTips")
    boxOutside:setTouchEnabled(true)
    boxOutside:setSwallowTouches(false)
    rootNode:addChild(boxOutside)
    UIHelper.SetPosAndSizeByRefNode(boxOutside, rootNode)
    _boxOutsideForTouchLikeTips = boxOutside

    UIHelper.BindUIEvent(boxOutside, EventType.OnTouchBegan, function(node, x, y)
        local tPos = tipsNode:convertToNodeSpace(cc.p(x, y))
        local tSize = tipsNode:getContentSize()
        local bInside = cc.rectContainsPoint(cc.rect(0, 0, tSize.width, tSize.height), tPos)
        if not bInside then
            UIHelper.ClearTouchLikeTips()
        end
    end)

end

function UIHelper.SetTouchDownHideTips(node, bHideTips)
    if not safe_check(node) then
        return
    end

    if node.setTouchDownHideTips then
        node:setTouchDownHideTips(bHideTips)
    end
end

function UIHelper.SetMultiTouch(node, bMultiTouch)
    if not safe_check(node) then
        return
    end

    if node.setMultiTouch then
        node:setMultiTouch(bMultiTouch)
    end
end

function UIHelper.GetTouchDownHideTips(node)
    if not safe_check(node) then
        return
    end

    node:getTouchDownHideTips()
end

--[[
	递归刷新Layout 和 Widget
	bLaout 是否刷新Layout
	bWidget 是否刷新Widget
]]
function UIHelper.CascadeDoLayoutDoWidget(node, bLayout, bWidget)
    if not safe_check(node) then
        return
    end
    if not IsBoolean(bLayout) then
        bLayout = false
    end
    if not IsBoolean(bWidget) then
        bWidget = false
    end

    local tbNodeTree = UIHelper.GetNodeTree(node)
    local tbReversedNodeTree = Lib.ReverseTable(tbNodeTree)
    for _, tbSubTree in ipairs(tbReversedNodeTree) do
        for nIndex, oneNode in ipairs(tbSubTree) do
            if bWidget then
                local script = UIHelper.GetBindScript(oneNode)
                UIHelper.WidgetFoceDoAlign(script)
            end

            if bLayout then
                UIHelper.LayoutDoLayout(oneNode)
            end
        end
    end
end

function UIHelper.GetNodeTree(node)
    if not safe_check(node) then
        return
    end

    local tbNodeTree = {}

    function makeNodeTree(node, tbNodeTree, nIndex)
        if not safe_check(node) then
            return
        end
        if not tbNodeTree[nIndex] then
            tbNodeTree[nIndex] = {}
        end

        table.insert(tbNodeTree[nIndex], node)

        local tbChildren = UIHelper.GetChildren(node)
        for k, v in ipairs(tbChildren or {}) do
            makeNodeTree(v, tbNodeTree, nIndex + 1)
        end
    end

    makeNodeTree(node, tbNodeTree, 1)

    return tbNodeTree
end


-- --------------------------------------------------------------------------
-- TableView相关
-- --------------------------------------------------------------------------
function UIHelper.TableView_init(tableView, nDataLen, nCellPrefabID)
    if not safe_check(tableView) then
        return
    end
    tableView:setDataSource()
    tableView:setCellPrefabID(nCellPrefabID)
    tableView:setDataLen(nDataLen)
end

function UIHelper.TableView_setDataLen(tableView, nLen)
    if not safe_check(tableView) then
        return
    end
    tableView:setDataSource()
    tableView:setDataLen(nLen)
end

function UIHelper.TableView_getDataLen(tableView)
    if not safe_check(tableView) then
        return
    end
    tableView:getDataLen()
end

function UIHelper.TableView_setCellPrefabID(tableView, nPrefabID)
    if not safe_check(tableView) then
        return
    end
    tableView:setDataSource()
    tableView:setCellPrefabID(nPrefabID)
end

function UIHelper.TableView_setDataSource(tableView)
    if not safe_check(tableView) then
        return
    end
    tableView:setDataSource()
end

function UIHelper.TableView_setDelegate(tableView)
    if not safe_check(tableView) then
        return
    end
    tableView:setDelegate()
end

function UIHelper.TableView_reloadData(tableView)
    if not safe_check(tableView) then
        return
    end
    tableView:setTouchEnabled(false)
    tableView:setDataSource()
    tableView:reloadData()
    tableView:setTouchEnabled(true)
end

function UIHelper.TableView_scrollTo(tableView, nOffset, nDuration)
    if not safe_check(tableView) then
        return
    end
    if not nOffset then
        return
    end
    if not nDuration then
        nDuration = 0
    end

    tableView:setContentOffsetInDuration({ x = 0, y = nOffset }, nDuration)
end

function UIHelper.TableView_scrollToCell(tableView, nCellCount, nIndex, nDuration)
    if not safe_check(tableView) then
        return
    end
    local tableViewMask = UIHelper.GetParent(tableView)
    -- 整个table view的最外层组件，可能跨越一个屏幕，基于这个计算每个cell的高度
    local uiWholeTable = UIHelper.GetChildren(tableView)[1]
    --整个table view的最外层组件高度
    local nWholeHeight = UIHelper.GetHeight(uiWholeTable)
    -- 单个cell的高度
    local nCellHeight = nWholeHeight / nCellCount
    -- 实际显示在屏幕中的table的部分的高度
    local nPageHeight = UIHelper.GetHeight(tableViewMask)

    -- 单个屏幕中显示的cell数目
    local nCellCountPerPage = math.floor(nPageHeight / nCellHeight)
    local nOffsetCellCount = nCellCount - nCellCountPerPage - nIndex + 1

    -- table view默认会在最下方，offset是y轴移动距离，负值时表示整个table view在屏幕中往下拖动，效果就是上面的cell会慢慢显示在屏幕中
    -- 往下拖动 nCellCount - nCellCountPerPage 后，第一个cell会显示在屏幕最上方
    -- 如果想要第 nIndex 个cell显示在屏幕最上方，需要减少拖动 nIndex - 1 个cell的距离

    local nMin = nPageHeight - nWholeHeight
    local nMax = 0
    -- 当cell很少时允许向上滚动
    if nCellCountPerPage > nCellCount then
        nMax = (nCellCountPerPage - nCellCount) * nCellHeight
    end
    local nOffset = math.min(nMax, math.max(-nOffsetCellCount * nCellHeight, nMin))--防止滚动过度导致界面显示异常
    UIHelper.TableView_scrollTo(tableView, nOffset, nDuration)
end

function UIHelper.TableView_scrollToCellFitTop(tableView, nCellCount, nIndex, nDuration)
    if not safe_check(tableView) then
        return
    end
    local tableViewMask = UIHelper.GetParent(tableView)
    -- 整个table view的最外层组件，可能跨越一个屏幕，基于这个计算每个cell的高度
    local uiWholeTable = UIHelper.GetChildren(tableView)[1]
    --整个table view的最外层组件高度
    local nWholeHeight = UIHelper.GetHeight(uiWholeTable)
    -- 单个cell的高度
    local nCellHeight = nWholeHeight / nCellCount
    -- 实际显示在屏幕中的table的部分的高度
    local nPageHeight = UIHelper.GetHeight(tableViewMask)

    -- 单个屏幕中显示的cell数目(这里追求精确数量，不保留整数)
    local nCellCountPerPage = nPageHeight / nCellHeight --math.floor(nPageHeight / nCellHeight)
    local nOffsetCellCount = nCellCount - nCellCountPerPage - nIndex + 1

    -- table view默认会在最下方，offset是y轴移动距离，负值时表示整个table view在屏幕中往下拖动，效果就是上面的cell会慢慢显示在屏幕中
    -- 往下拖动 nCellCount - nCellCountPerPage 后，第一个cell会显示在屏幕最上方
    -- 如果想要第 nIndex 个cell显示在屏幕最上方，需要减少拖动 nIndex - 1 个cell的距离

    local nMin = nPageHeight - nWholeHeight
    local nMax = 0
    -- 当cell很少时允许向上滚动
    if nCellCountPerPage > nCellCount then
        nMax = (nCellCountPerPage - nCellCount) * nCellHeight
    end
    local nOffset = math.min(nMax, math.max(-nOffsetCellCount * nCellHeight, nMin))--防止滚动过度导致界面显示异常
    UIHelper.TableView_scrollTo(tableView, nOffset, nDuration)
end

function UIHelper.TableView_scrollToTop(tableView, nDuration)
    if not safe_check(tableView) then
        return
    end
    local tableViewMask = UIHelper.GetParent(tableView)
    -- 整个table view的最外层组件，可能跨越一个屏幕，基于这个计算每个cell的高度
    local uiWholeTable = UIHelper.GetChildren(tableView)[1]
    --整个table view的最外层组件高度
    local nWholeHeight = UIHelper.GetHeight(uiWholeTable)
    -- 实际显示在屏幕中的table的部分的高度
    local nPageHeight = UIHelper.GetHeight(tableViewMask)

    -- table view默认会在最下方，offset是y轴移动距离，负值时表示整个table view在屏幕中往下拖动，效果就是上面的cell会慢慢显示在屏幕中
    -- 往下拖动 nCellCount - nCellCountPerPage 后，第一个cell会显示在屏幕最上方
    -- 如果想要第 nIndex 个cell显示在屏幕最上方，需要减少拖动 nIndex - 1 个cell的距离

    local nMin = nPageHeight - nWholeHeight
    UIHelper.TableView_scrollTo(tableView, nMin, nDuration)
end

function UIHelper.TableView_CanSlide(tableView, nCellCount)
    if not safe_check(tableView) then
        return
    end
    local tableViewMask = UIHelper.GetParent(tableView)
    -- 整个table view的最外层组件，可能跨越一个屏幕，基于这个计算每个cell的高度
    local uiWholeTable = UIHelper.GetChildren(tableView)[1]
    --整个table view的最外层组件高度
    local nWholeHeight = UIHelper.GetHeight(uiWholeTable)
    -- 单个cell的高度
    local nCellHeight = nWholeHeight / nCellCount
    -- 实际显示在屏幕中的table的部分的高度
    local nPageHeight = UIHelper.GetHeight(tableViewMask)

    -- 单个屏幕中显示的cell数目
    local nCellCountPerPage = math.floor(nPageHeight / nCellHeight)

    return nCellCountPerPage < nCellCount
end

function UIHelper.TableView_NeedSlide(tableView, nCellCount, nCellIndex)
    if not safe_check(tableView) then
        return
    end
    local tableViewMask = UIHelper.GetParent(tableView)
    -- 整个table view的最外层组件，可能跨越一个屏幕，基于这个计算每个cell的高度
    local uiWholeTable = UIHelper.GetChildren(tableView)[1]
    --整个table view的最外层组件高度
    local nWholeHeight = UIHelper.GetHeight(uiWholeTable)
    -- 单个cell的高度
    local nCellHeight = nWholeHeight / nCellCount
    -- 实际显示在屏幕中的table的部分的高度
    local nPageHeight = UIHelper.GetHeight(tableViewMask)

    -- 单个屏幕中显示的cell数目
    local nCellCountPerPage = math.floor(nPageHeight / nCellHeight)

    return nCellCountPerPage < nCellIndex
end

function UIHelper.TableView_addCellTouchCallback(tableView, callback)
    if not safe_check(tableView) then
        return
    end
    if not callback then
        return
    end

    tableView:setDelegate()
    tableView:registerScriptHandler(function(tableView, cell)
        if IsFunction(callback) then
            local node = cell:getChildByTag(TableView.Tag)
            local script = UIHelper.GetBindScript(node)
            local idx = cell:getIdx()
            callback(tableView, idx + 1, script, node, cell)
        end
    end, TableView.CellTouch)
end

function UIHelper.TableView_addCellSizeForIndexCallback(tableView, callback)
    if not safe_check(tableView) then
        return
    end
    if not callback then
        return
    end

    tableView:setDataSource()
    tableView:registerScriptHandler(function(tableView, idx)
        if IsFunction(callback) then
            return callback(tableView, idx + 1)
        end
    end, TableView.CellSizeForIndex)
end

function UIHelper.TableView_addCellAtIndexCallback(tableView, callback)
    if not safe_check(tableView) then
        return
    end
    if not callback then
        return
    end

    tableView:setDataSource()
    tableView:registerScriptHandler(function(tableView, idx)
        if IsFunction(callback) then
            local nPrefabID = tableView:getCellPrefabID()
            local cell = tableView:dequeueCell()
            if not cell then
                cell = cc.TableViewCell:new()

                if nPrefabID > 0 then
                    local script = UIHelper.AddPrefab(nPrefabID, cell)
                    local node = script and script._rootNode or script
                    if node then
                        script._keepmt = true
                        node:setTag(TableView.Tag)
                        UIHelper.SetWidth(cell, UIHelper.GetWidth(tableView))
                        UIHelper.SetAnchorPoint(node, 0, 0)
                        UIHelper.SetPosition(node, 0, 0)

                        if script then
                            UIHelper.WidgetFoceDoAlign(script)
                        end
                    end
                end
            end

            local node, script
            if nPrefabID > 0 then
                node = cell:getChildByTag(TableView.Tag)
                script = UIHelper.GetBindScript(node)
            end

            callback(tableView, idx + 1, script, node, cell)

            if node then
                UIHelper.SetNodeSwallowTouches(node, false, true)
            end

            return cell
        end
    end, TableView.CellAtIndex)
end

function UIHelper.TableView_addNumberOfCellsCallback(tableView, callback)
    if not safe_check(tableView) then
        return
    end
    if not callback then
        return
    end

    tableView:setDataSource()
    tableView:registerScriptHandler(function(tableView)
        if IsFunction(callback) then
            return callback(tableView)
        end
    end, TableView.NumberOfCells)
end

--@ outline:<outline=#color&size>content</u>
--@ shadow:<shadow=#color&offsetWidth&offsetHeight>content</shadow>
--@ underline:<u>content</u>
--@ url:<href=xxxx>content</href>
--@ 转义符 <:&lt; >:&gt; &:&amp; ':&apos; ":&quot;
function UIHelper.SetRichText(richText, szXMLContent)
    if not safe_check(richText) then
        return
    end

    if string.is_nil(szXMLContent) then
        local szEmpty = "<div></div>"
        if UIHelper.GetRichText(richText) == szEmpty then
            return
        end
        richText:setXMLData(szEmpty)
        richText:formatText()
        return
    end

    for szText in string.gmatch(szXMLContent, "<img src='(.-)'") do
        UIHelper.PreloadSpriteFrame(szText .. ".png")
    end

    szXMLContent = szXMLContent or ""
    szXMLContent = string.format("<div>%s</div>", szXMLContent)

    -- 如果一样，就不用再次设置了
    if UIHelper.GetRichText(richText) == szXMLContent then
        return
    end

    richText:setXMLData(szXMLContent)
    richText:formatText()
end

function UIHelper.GetRichText(richText)
    if not safe_check(richText) then
        return
    end

    if richText.getXMLData then
        return richText:getXMLData()
    end
end

function UIHelper.SetRichTextCanClick(richText, bCanClick)
    if not safe_check(richText) then
        return
    end

    if richText.setUrlCanClick then
        richText:setUrlCanClick(bCanClick)
    end
end

-- 忽略内容自适应大小，这样宽度就不会自动换行
function UIHelper.RichTextIgnoreContentAdaptWithSize(richText, bIgnore)
    if not safe_check(richText) then
        return
    end

    if richText.ignoreContentAdaptWithSize then
        richText:ignoreContentAdaptWithSize(bIgnore)
    end
end

---@param szText string 原文本
---@param nFontColorID number|string 字体颜色ID(FontColorID.XXX) 或 字体颜色字符串(如"#ffffff")
function UIHelper.AttachTextColor(szText, nFontColorID)
    local tColorCfg = UIDialogueColorTab[nFontColorID]
    local szColor = tColorCfg and tColorCfg.Color
    if not szColor and IsString(nFontColorID) then
        szColor = nFontColorID
    end
    if not szColor then
        LOG.ERROR("AttachTextColor Error, Invalid FontColorID: %s", tostring(nFontColorID))
        return szText
    end

    if string.sub(szColor, 1, 1) ~= "#" then
        szColor = "#" .. szColor
    end
    return "<color=" .. szColor .. ">" .. szText .. "</color>"
end


--添加目标类型文字的颜色
function UIHelper.AttachTargetTextColor(szTitle, nHave, nNeed, szFinishColor, szUnFinishColor, szTitleColor)

    if IsNumber(szFinishColor) then
        local tbColor = UIDialogueColorTab[szFinishColor]
        szFinishColor = tbColor and tbColor.Color or FontColorID.Text_Level1_Backup
    end

    if IsNumber(szUnFinishColor) then
        local tbColor = UIDialogueColorTab[szUnFinishColor]
        szUnFinishColor = tbColor and tbColor.Color or FontColorID.Text_Level1_Backup
    end

    if IsNumber(szTitleColor) then
        local tbColor = UIDialogueColorTab[szTitleColor]
        szTitleColor = tbColor and tbColor.Color or FontColorID.Text_Level1_Backup
    end

    local szTarget = szTitle
    if szTitleColor then
        szTarget = "<color=" .. szTitleColor .. ">" .. szTitle .. "</color>"
    end

    local bFinish = nHave == nNeed
    local szColor = bFinish and szFinishColor or szUnFinishColor
    szTarget = szTarget .. "：" .. "<color=" .. szColor .. ">" .. tostring(nHave) .. "/" .. tostring(nNeed) .. "</color>"
    return szTarget
end

--添加时间类型文字颜色，单位为秒
function UIHelper.AttachTimeTextColor(szTitle, nSecond, nThresholdTime, nShowTimeType, szNormalColor, szThresholdColor, szTitleColor)

    if IsNumber(szNormalColor) then
        local tbColor = UIDialogueColorTab[szNormalColor]
        szNormalColor = tbColor and tbColor.Color or FontColorID.Text_Level1_Backup
    end

    if IsNumber(szThresholdColor) then
        local tbColor = UIDialogueColorTab[szThresholdColor]
        szThresholdColor = tbColor and tbColor.Color or FontColorID.Text_Level1_Backup
    end

    if IsNumber(szTitleColor) then
        local tbColor = UIDialogueColorTab[szTitleColor]
        szTitleColor = tbColor and tbColor.Color or FontColorID.Text_Level1_Backup
    end

    local szTarget = szTitle
    if szTitleColor then
        szTarget = "<color=" .. szTitleColor .. ">" .. szTitle .. "</color>"
    end

    if not nSecond then
        return szTarget
    end

    --..小时
    if nShowTimeType == TIME_TEXT_STATE.HOUR then
        local nHour = math.ceil(nSecond / 3600)
        local szHour = nHour >= 1 and tostring(nHour) or "<1"
        szTime = szHour .. g_tStrings.STR_HOUR

        --..分钟
    elseif nShowTimeType == TIME_TEXT_STATE.MINUTE then
        local nMinute = math.ceil(nSecond / 60)
        local szMinute = nMinute >= 1 and tostring(nMinute) or "<1"
        szTime = szMinute .. g_tStrings.STR_MINUTE

        --..秒
    elseif nShowTimeType == TIME_TEXT_STATE.SECOND then
        szTime = tostring(nSecond) .. g_tStrings.STR_SECOND

        --..小时..分钟
    elseif nShowTimeType == TIME_TEXT_STATE.HOUR_MINUTE then
        local nHour = math.floor(nSecond / 3600)
        nSecond = nSecond - nHour * 3600
        local nMinute = math.floor(nSecond / 60)

        local szHour = nHour >= 1 and tostring(nHour) .. g_tStrings.STR_HOUR or ""
        local szMinute = (nMinute >= 1 and tostring(nMinute) or "<1") .. g_tStrings.STR_MINUTE

        szTime = szHour .. szMinute

        --..小时..分钟..秒
    elseif nShowTimeType == TIME_TEXT_STATE.HOUR_MINUTE_SECOND then
        local nHour = math.floor(nSecond / 3600)
        nSecond = nSecond - nHour * 3600
        local nMinute = math.floor(nSecond / 60)
        nSecond = nSecond - nMinute * 60

        local szHour = nHour >= 1 and tostring(nHour) .. g_tStrings.STR_HOUR or ""
        local szMinute = nMinute >= 1 and tostring(nMinute) .. g_tStrings.STR_MINUTE or ""
        local szSecond = tostring(nSecond) .. g_tStrings.STR_SECOND

        szTime = szHour .. szMinute .. szSecond

        --分钟..秒
    elseif nShowTimeType == TIME_TEXT_STATE.MINUTE_SECOND then
        local nMinute = math.floor(nSecond / 60)
        nSecond = nSecond - nMinute * 60

        local szMinute = nMinute >= 1 and tostring(nMinute) .. g_tStrings.STR_MINUTE or ""
        local szSecond = tostring(nSecond) .. g_tStrings.STR_SECOND

        szTime = szMinute .. szSecond
    end

    local szColor = nSecond >= nThresholdTime and szNormalColor or szThresholdColor
    szTarget = szTarget .. " " .. "<color=" .. szColor .. ">" .. szTime .. "</color>"
    return szTarget
end

function UIHelper.IsRichText(szText)
    local bResult = false

    if not string.is_nil(szText) then
        if string.find(szText, "<") and string.find(szText, ">") then
            if string.find(szText, "/>") or string.find(szText, "</") then
                bResult = true
            end
        end
    end

    return bResult
end

--将需要在RichText中显示的文本转义为RichText支持的格式
--@ 转义符 <:&lt; >:&gt; &:&amp; ':&apos; ":&quot;
function UIHelper.RichTextEscape(szText)
    szText = string.gsub(szText, "&", "&amp;")
    szText = string.gsub(szText, "<", "&lt;")
    szText = string.gsub(szText, ">", "&gt;")
    szText = string.gsub(szText, "'", "&apos;")
    szText = string.gsub(szText, "\"", "&quot;")
    return szText
end

function UIHelper.RichTextToNormal(szText)
    szText = string.gsub(szText, "&amp;", "&")
    szText = string.gsub(szText, "&lt;", "<")
    szText = string.gsub(szText, "&gt;", ">")
    szText = string.gsub(szText, "&apos;", "'")
    szText = string.gsub(szText, "&quot;", "\"")
    return szText
end

-- @param container 容器节点
-- @param tTextArr = {
--		{szText = "1234中文", nFontSize = 42, nVAlign = 1, color = cc.c4b(255, 255, 255, 255)},
--		{szFrame = "img_ziyuan_04", nWidth = 50, nHeight = 50, nVAlign = 1, nOffsetY = 5}, -- nVAlign: 0为下对齐 1为中对齐 2为上对齐
-- }
-- @param nSizeMode 修正container大小的模式, 0为不修正 1为修正宽度 2为修正高度 3为修正宽高
function UIHelper.SetPoorText(container, tbTextArr, nSizeMode, c4bColor)
    if not safe_check(container) then
        return
    end
    assert(tbTextArr)

    nSizeMode = nSizeMode or 0
    c4bColor = c4bColor or cc_font_color_white
    local nWidth, nHeight = 0, 0
    local nFontSize = 26
    local nVAlign = 1

	local _, tbFontConfig = FontMgr.GetCurFont(FontID.Default)
    local szFont = tbFontConfig.szPath

    -- create
    container:removeAllChildren()
    for i = 1, #tbTextArr do
        local t = tbTextArr[i]
        if t.szText then
            local label = cc.Label:create()
            assert(label)
            label:initWithTTF(t.szText,
                    t.szFont or szFont,
                    t.nFontSize or nFontSize)
            label:setTextColor(t.color or c4bColor)
            label:setLineHeight(t.nFontSize or nFontSize)
            container:addChild(label)
            label:setAnchorPoint(cc_p_zero)
            label:setPosition(nWidth + (t.nOffsetX or 0), t.nOffsetY or 0)

            local size = label:getContentSize()
            nWidth = nWidth + size.width
            if size.height > nHeight then
                nHeight = size.height
            end

        elseif t.szFrame then
            local image = cc.Sprite:create()
            assert(image)
            local szFrameName = t.szFrame .. ".png"
            UIHelper.PreloadSpriteFrame(szFrameName)
            image:initWithSpriteFrameName(szFrameName)
            image:setContentSize(cc.size(t.nWidth, t.nHeight or t.nWidth))
            container:addChild(image)
            image:setAnchorPoint(cc_p_zero)
            image:setPosition(nWidth + (t.nOffsetX or 0), t.nOffsetY or 0)

            local size = image:getContentSize()
            nWidth = nWidth + size.width
            if t.bHeight and nHeight < size.height then
                nHeight = size.height
            end
        end
    end

    -- size mode
    if nSizeMode == 3 then
        UIHelper.SetContentSize(container, nWidth, nHeight)
    elseif nSizeMode == 2 then
        UIHelper.SetHeight(container, nHeight)
    elseif nSizeMode == 1 then
        UIHelper.SetWidth(container, nWidth)
    end

    -- position
    if nSizeMode < 2 then
        local size = container:getContentSize()
        local children = container:getChildren()
        for i = 1, #tbTextArr do
            local t = tbTextArr[i]
            local child = children[i]
            if t.nVAlign == 1 then
                child:setAnchorPoint(cc_anchor_valign_center)
                child:setPositionY(size.height / 2 + (t.nOffsetY or 0))
            elseif t.nVAlign == 2 then
                child:setAnchorPoint(cc_anchor_valign_top)
                child:setPositionY(size.height + (t.nOffsetY or 0))
            end
        end
    end

end

---@return UIConfirmView
function UIHelper.ShowConfirm(szContent, funcConfirm, funcCancel, bRichText, bDisableEnter)
    if string.is_nil(szContent) then
        LOG.ERROR("UIHelper.ShowConfirm, Error szContent is nil")
    end

    -- 如果在Loading中，那就先存队列，等Loading结束在一起弹
    if SceneMgr.IsLoading() then
        if not UIHelper.tbConfirmList then UIHelper.tbConfirmList = {} end
        table.insert(UIHelper.tbConfirmList, {szContent = szContent, funcConfirm = funcConfirm, funcCancel = funcCancel, bRichText = bRichText, bDisableEnter = bDisableEnter})

        Event.Reg(UIHelper, EventType.UILoadingFinish, function()
            Timer.DelTimer(UIHelper, UIHelper.nConfirmQueueTimerID)
            UIHelper.nConfirmQueueTimerID = Timer.Add(UIHelper, 0.2, function()
                for _, v in ipairs(UIHelper.tbConfirmList or {}) do
                    UIHelper.ShowConfirm(v.szContent, v.funcConfirm, v.funcCancel, v.bRichText, v.bDisableEnter)
                end
                UIHelper.tbConfirmList = nil
            end)

            Event.UnReg(UIHelper, EventType.UILoadingFinish)
        end)

        return
    end

    return UIMgr.Open(VIEW_ID.PanelNormalConfirmation, szContent, funcConfirm, funcCancel, bRichText, nil, nil, bDisableEnter)
end

function UIHelper.ShowConfirmWithItemList(szContent, tbItemList, funcConfirm, funcCancel, funcChooseItem)
    if string.is_nil(szContent) then
        LOG.ERROR("UIHelper.ShowConfirmWithItemList, Error szContent is nil")
    end
    return UIMgr.Open(VIEW_ID.PanelStripConfirmation, szContent, tbItemList, funcConfirm, funcCancel, funcChooseItem)
end

function UIHelper.ShowSystemConfirm(szContent, funcConfirm, funcCancel, bRichText)
    if string.is_nil(szContent) then
        LOG.ERROR("UIHelper.ShowSystemConfirm, Error szContent is nil")
    end
    return UIMgr.Open(VIEW_ID.PanelSystemConfirm, szContent, funcConfirm, funcCancel, bRichText)
end

function UIHelper.ShowSwitchMapConfirm(szContent, funcConfirm, funcCancel)
    if string.is_nil(szContent) then
        LOG.ERROR("UIHelper.ShowSwitchMapConfirm, Error szContent is nil")
    end
    return UIMgr.Open(VIEW_ID.PanelMapTeleportConfirmation, szContent, funcConfirm, funcCancel)
end

function UIHelper.GetChildren(node)
    if not safe_check(node) then
        return
    end
    return node:getChildren()
end

function UIHelper.GetChildrenCount(node)
    if not safe_check(node) then
        return
    end
    return node:getChildrenCount()
end

function UIHelper.RemoveAllChildren(node)
    if not safe_check(node) then
        return
    end
    return node:removeAllChildren()
end

function UIHelper.GetProtectedChildByTag(protectedNode, nTag)
    if not safe_check(protectedNode) then
        return
    end
    if protectedNode.getProtectedChildByTag then
        return protectedNode:getProtectedChildByTag(nTag)
    end
end

function UIHelper.GetProtectedChildren(protectedNode)
    if not safe_check(protectedNode) then
        return
    end
    if protectedNode.getProtectedChildren then
        return protectedNode:getProtectedChildren()
    end
end

function UIHelper.IsProtectedNode(node)
    local bResult = false
    if safe_check(node) then
        if protectedNode.getProtectedChildByTag and
                protectedNode.getProtectedChildren then
            bResult = true
        end
    end
    return bResult
end

function UIHelper.HideAllChildren(node)
    if not safe_check(node) then
        return
    end

    local childrens = UIHelper.GetChildren(node)
    for _, children in ipairs(childrens) do
        UIHelper.SetVisible(children, false)
    end
end

function UIHelper.ShowAllChildren(node)
    if not safe_check(node) then
        return
    end

    local childrens = UIHelper.GetChildren(node)
    for _, children in ipairs(childrens) do
        UIHelper.SetVisible(children, true)
    end
end

function UIHelper.GetVisableChildrenCount(node)
    if not safe_check(node) then
        return
    end

    local nCount = 0
    local childrens = UIHelper.GetChildren(node)
    for _, children in ipairs(childrens or {}) do
        local bVisible = UIHelper.GetVisible(children)
        if bVisible then
            nCount = nCount + 1
        end
    end

    return nCount
end

function UIHelper.SetToggleGroupSelected(toggleGroup, nIndex)
    if not safe_check(toggleGroup) then
        return
    end

    if IsNumber(nIndex) then
        local nToggleCount = toggleGroup:getNumberOfRadioButtons()
        if nIndex >= 0 and nIndex < nToggleCount then
            --Index从0开始
            toggleGroup:setSelectedButton(nIndex)
        end
    end
end

function UIHelper.SetToggleGroupSelectedToggle(toggleGroup, toggle)
    if not safe_check(toggleGroup) then
        return
    end
    toggleGroup:setSelectedButton(toggle)
end

function UIHelper.GetToggleGroupSelectedIndex(toggleGroup)
    if not safe_check(toggleGroup) then
        return
    end
    return toggleGroup:getSelectedButtonIndex() --Index从0开始
end

function UIHelper.ToggleGroupAddToggle(toggleGroup, toggle)
    if not safe_check(toggleGroup) then
        return
    end
    if not safe_check(toggle) then
        return
    end

    if not toggleGroup.addRadioButton then
        LOG.ERROR("UIHelper.ToggleGroupAddToggle, error toggleGroup.name = " .. toggleGroup:getName())
        return
    end

    toggleGroup:addRadioButton(toggle)
    toggle:setToggleGroup(true)
end

function UIHelper.ToggleGroupGetToggleByIndex(toggleGroup, nIndex)
    if not safe_check(toggleGroup) then
        return
    end

    if IsNumber(nIndex) then
        local nToggleCount = toggleGroup:getNumberOfRadioButtons()
        if nIndex >= 0 and nIndex < nToggleCount then
            --Index从0开始
            return toggleGroup:getRadioButtonByIndex(nIndex)
        end
    end
end

function UIHelper.ToggleGroupRemoveToggle(toggleGroup, toggle)
    if not safe_check(toggleGroup) then
        return
    end
    if not safe_check(toggle) then
        return
    end

    toggle:setToggleGroup(false)
    toggleGroup:removeRadioButton(toggle)
end

function UIHelper.ToggleGroupRemoveAllToggle(toggleGroup)
    if not safe_check(toggleGroup) then
        return
    end

    if not toggleGroup.getNumberOfRadioButtons then
        LOG.ERROR("UIHelper.ToggleGroupRemoveAllToggle, error toggleGroup.name = " .. toggleGroup:getName())
        return
    end

    local nToggleCount = toggleGroup:getNumberOfRadioButtons()
    for i = 1, nToggleCount do
        local toggle = toggleGroup:getRadioButtonByIndex(0)
        if safe_check(toggle) then
            toggle:setToggleGroup(false)
            toggleGroup:removeRadioButton(toggle)
        end
    end
end

function UIHelper.SetToggleGroupAllowedNoSelection(toggleGroup, bAllowNoSelection)
    if not safe_check(toggleGroup) then
        return
    end

    toggleGroup:setAllowedNoSelection(bAllowNoSelection)
end

function UIHelper.SetToggleGroupIndex(toggle, nToggleGroupIndex)
    if (nToggleGroupIndex ~= -1) and not table.contain_value(ToggleGroupIndex, nToggleGroupIndex) then
        LOG.ERROR("param2 nToggleGroupIndex(%d) must define in ToggleGroupIndex", nToggleGroupIndex)
        return
    end

    toggle:setGroupIndex(nToggleGroupIndex)
end

function UIHelper.RegisterEditBoxBegan(editbox, callback)
    if not safe_check(editbox) then
        return
    end
    if not callback then
        return
    end

    editbox:registerScriptEditBoxHandler(function(szType, _editbox)
        if szType == "began" then
            callback(_editbox)
        end
    end)
end

--- 编辑框输入结束，在windows或max下使用该事件
function UIHelper.RegisterEditBoxEnded(editbox, callback)
    if not safe_check(editbox) then
        return
    end
    if not callback then
        return
    end

    editbox:registerScriptEditBoxHandler(function(szType, _editbox)
        -- szType == "began"  szType == "changed"  这两个暂时都用不上
        if szType == "ended" then
            callback(_editbox)
        end
    end)
end

--- 编辑框输入结束，在移动设备（非windows和mac）使用该事件
--- note: 如果是数字键盘，需要额外注册 EventType.OnGameNumKeyboardChanged 事件，否则无法监听到数字键盘输入结束的事件
function UIHelper.RegisterEditBoxReturn(editbox, callback)
    if not safe_check(editbox) then
        return
    end
    if not callback then
        return
    end

    editbox:registerScriptEditBoxHandler(function(szType, _editbox)
        -- szType == "began"  szType == "changed"  这两个暂时都用不上
        if szType == "return" then
            callback(_editbox)
        end
    end)
end

function UIHelper.RegisterEditBoxChanged(editbox, callback)
    if not safe_check(editbox) then
        return
    end
    if not callback then
        return
    end

    editbox:registerScriptEditBoxHandler(function(szType, _editbox)
        if szType == "changed" then
            callback(_editbox)
        end
    end)
end

function UIHelper.RegisterEditBox(editbox, callback)
    if not safe_check(editbox) then
        return
    end
    if not callback then
        return
    end

    editbox:registerScriptEditBoxHandler(callback)
end

--@example:
-- UIHelper.PlayVideo(self.videoPlayer,"http://xxxxx....",false,function (eventType)
-- 		eventType: UIDef.lua 中的VideoPlayerEventType
-- end)
function UIHelper.PlayVideo(videoPlayer, szUrl, bIsLocal, onCompletedCallback, bKeepFps , newVolume, bNeedFirstFrame)
    if not safe_check(videoPlayer) then
        return
    end

    -- 所有的本地视频都是Bink形式,网络视频是FFMpeg形式
    if bIsLocal then
        videoPlayer:setPlayerModel(VIDEOPLAYER_MODEL.BINK)
        if GetFpsLimit then
            local fpsLimit = GetFpsLimit()
            if Platform.IsWindows() or Platform.IsMac() or bKeepFps then
                fpsLimit = fpsLimit > 30 and 30 or fpsLimit
            else
                fpsLimit = fpsLimit > 25 and 25 or fpsLimit
            end
            LOG.INFO("UIHelper.PlayVideo fpsLimit:%d", fpsLimit)
            videoPlayer:setNetworkPreloadCount(fpsLimit)
        end

    else
        videoPlayer:setPlayerModel(VIDEOPLAYER_MODEL.FFMPEG)
        videoPlayer:setNetworkPreloadCount(Const.nVideoNetPreloadFrameCount)
    end
    local volume = 1
    local bEnableSound = IsEnableAllSound()
    -- 有可能在加载界面后
    local loadingView = UIMgr.GetViewScript(VIEW_ID.PanelLoading)
    if loadingView then
        bEnableSound = loadingView.bTempIsEnableAllSound
    end

    if bEnableSound then
        local nMainSound = GameSettingData.GetSoundSliderValue(SOUND.MAIN)
        if nMainSound then
            volume = nMainSound
        end
        volume = volume * 0.7
    else
        volume = 0
    end
    if newVolume then
        volume = bEnableSound and newVolume or 0
    end

    UIHelper.SetVideoPlayerVolume(videoPlayer, volume)
    if szUrl and szUrl ~= "" then
        if bIsLocal then
            videoPlayer:setFileName(szUrl)
        else
            videoPlayer:setURL(szUrl)
        end
    end

    if videoPlayer.setNeedFirstFrame then
        videoPlayer:setNeedFirstFrame(bNeedFirstFrame or false)
    end


    if onCompletedCallback then
        videoPlayer:addEventListener(function(_, eventType, szMsg)
            onCompletedCallback(eventType, szMsg)
        end)
    end

    videoPlayer:play()
    UIHelper.SetVisible(videoPlayer, true)
end

function UIHelper.ClosePlayVideo(videoPlayer)
    if not safe_check(videoPlayer) then
        return
    end
    videoPlayer:stop()
    UIHelper.SetVisible(videoPlayer, false)
end

function UIHelper.StopVideo(videoPlayer)
    if not safe_check(videoPlayer) then
        return
    end
    videoPlayer:stop()
end

function UIHelper.SetVideoLooping(videoPlayer, bLooping)
    if not safe_check(videoPlayer) then
        return
    end
    videoPlayer:setLooping(bLooping)
end

function UIHelper.GetVideoLooping(videoPlayer)
    if not safe_check(videoPlayer) then
        return
    end
    return videoPlayer:isLooping()
end

function UIHelper.VideoPlayerClearFileQueue(videoPlayer)
    if not safe_check(videoPlayer) then
        return
    end
    return videoPlayer:clearFileQueue()
end

function UIHelper.VideoPlayerAddFileQueue(videoPlayer, fileName)
    if not safe_check(videoPlayer) then
        return
    end
    return videoPlayer:addFileQueue(fileName)
end

function UIHelper.SetVideoPlayerLoopSeek(videoPlayer, seekPro)
    if not safe_check(videoPlayer) then
        return
    end
    return videoPlayer:seekTo(seekPro)
end

function UIHelper.SetVideoPlayerModel(videoPlayer, model)
    if not safe_check(videoPlayer) then
        return
    end
    return videoPlayer:setPlayerModel(model)
end

function UIHelper.SetVideoPlayerVolume(videoPlayer, volume)
    if not safe_check(videoPlayer) then
        return
    end
    if not videoPlayer.setVolume then
        return
    end
    return videoPlayer:setVolume(volume)
end

function UIHelper.ParseVideoPlayerFile(fileName, model)
    if model == VIDEOPLAYER_MODEL.FFMPEG then
        fileName = string.gsub(fileName, "bk2", "mp4")
    else
        fileName = string.gsub(fileName, "mp4", "bk2")
    end
    return fileName
end

function UIHelper.PlayAni(script, clipNode, szClipName, callback, nModeType, bToEndFrame, fSpeed)
    if not script then
        return
    end
    if not script._aniMgr then
        return
    end
    if not clipNode then
        return
    end
    if not szClipName then
        return
    end
    if not nModeType then
        nModeType = -1
    end
    if not bToEndFrame then
        bToEndFrame = false
    end
    if not fSpeed then
        fSpeed = 1.0
    end

    script._aniMgr:playAnimationClip(clipNode, szClipName, callback, nModeType, bToEndFrame, fSpeed) -- nModeType = cc.AniMode
end

function UIHelper.PauseAni(script, clipNode, szClipName)
    if not script then
        return
    end
    if not script._aniMgr then
        return
    end
    if not clipNode then
        return
    end
    if not szClipName then
        return
    end

    script._aniMgr:pauseAnimationClip(clipNode, szClipName)
end

function UIHelper.ResumeAni(script, clipNode, szClipName)
    if not script then
        return
    end
    if not script._aniMgr then
        return
    end
    if not clipNode then
        return
    end
    if not szClipName then
        return
    end

    script._aniMgr:resumeAnimationClip(clipNode, szClipName)
end

function UIHelper.StopAni(script, clipNode, szClipName)
    if not script then
        return
    end
    if not script._aniMgr then
        return
    end
    if not clipNode then
        return
    end
    if not szClipName then
        return
    end

    script._aniMgr:stopAnimationClip(clipNode, szClipName)
end

function UIHelper.StopAllAni(script)
    if not script then
        return
    end
    if not script._aniMgr then
        return
    end

    script._aniMgr:stopAllAnimationClips()
end

function UIHelper.PlayListAni(tbScriptList, szNodeName, szClipName, nStepFrame)
    local nCurFrame = 0
    for _, script in ipairs(tbScriptList) do
        -- UIHelper.SetVisible(script._rootNode, false)--隐藏了后如果Dolayout会很危险，导致排版错乱
        if nCurFrame > 0 then
            Timer.AddFrame(script, nCurFrame, function()
                -- UIHelper.SetVisible(script._rootNode, true)
                UIHelper.PlayAni(script, script[szNodeName], szClipName)
            end)
        else
            -- UIHelper.SetVisible(script._rootNode, true)
            UIHelper.PlayAni(script, script[szNodeName], szClipName)
        end
        nCurFrame = nCurFrame + nStepFrame
    end
end

local _tFindChildByNameCache = setmetatable({ nil, nil, nil, nil, nil, nil, nil, nil }, { __mode = "v" })
-- 广度优先查找指定名称的子节点
function UIHelper.FindChildByName(root, szName)
    if not safe_check(root) then
        return
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
-- 收集指定名称的节点填充到tRet中
function UIHelper.FindNodeByNameArr(root, tRet, tNameArr)
    if not safe_check(root) then
        return
    end
    assert(tRet)
    assert(tNameArr)
    local nCount = #tNameArr
    for i = 1, nCount do
        tRet[tNameArr[i]] = false
    end

    local nBeg, nEnd = 1, 1
    _tFindChildByNameCache[nEnd] = root
    while nBeg <= nEnd do
        local node = _tFindChildByNameCache[nBeg]
        local children = node:getChildren()
        for _, child in ipairs(children) do
            local szName = child:getName()
            if tRet[szName] == false then
                tRet[szName] = child
                nCount = nCount - 1
                if nCount == 0 then
                    return 0
                end
            end
            nEnd = nEnd + 1
            _tFindChildByNameCache[nEnd] = child
        end
        nBeg = nBeg + 1
    end

    return nCount
end

-- 向根方向查找父辈节点
function UIHelper.FindParentNode(node, szParentName)
    node = node and node:getParent()
    while node ~= nil do
        if node:getName() == szParentName then
            return node
        end
        node = node:getParent()
    end
end

function UIHelper.GetNodePath(node)
    if node == nil or not safe_check(node) then
        return ""
    end
    local szPath = UIHelper.GetNodePath(node:getParent())
    return szPath .. "/" .. node:getName()
end

local _tUtf8Mask = { 0, 0xc0, 0xe0, 0xf0 }
function UIHelper.GetUtf8Len(szUtf8)
    if string.is_nil(szUtf8) then
        return 0
    end

    local nLeft = string.len(szUtf8)
    local nLen = 0
    while nLeft > 0 do
        local code = string.byte(szUtf8, -nLeft)
        for i = 4, 1, -1 do
            if code >= _tUtf8Mask[i] then
                nLeft = nLeft - i
                break
            end
        end
        nLen = nLen + 1
    end
    return nLen
end
function UIHelper.GetUtf8Width(szUtf8, nFontSize, szFont)
    local nLeft = string.len(szUtf8)
    local nWidth = 0
    local nScale = nFontSize / 26
    local nCharWidth = nFontSize
    while nLeft > 0 do
        local code = string.byte(szUtf8, -nLeft)
        for i = 4, 1, -1 do
            if code >= _tUtf8Mask[i] then
                nLeft = nLeft - i
                if i > 1 then
                    nCharWidth = nFontSize
                else
                    nCharWidth = AsciiDef_CharWidth_26(code)
                    nCharWidth = mceil(nCharWidth and (nCharWidth * nScale) or (nFontSize / 2))
                end
                nWidth = nWidth + nCharWidth
                break
            end
        end
    end
    return nWidth
end

function UIHelper.LimitUtf8Len(szUtf8, nLimit)
    local nLeft = string.len(szUtf8)
    local nCharIndex = 0
    local nLast = nLeft
    while nLeft > 0 do
        if nCharIndex >= nLimit then
            return string.sub(szUtf8, 1, -nLast - 1) .. "..."
        end
        nLast = nLeft
        local code = string.byte(szUtf8, -nLeft)
        for i = 4, 1, -1 do
            if code >= _tUtf8Mask[i] then
                nLeft = nLeft - i
                break
            end
        end
        nCharIndex = nCharIndex + 1
    end
    return szUtf8
end
function UIHelper.GetUtf8SubString(szUtf8, nStart, nCount)
    local nByteCount = string.len(szUtf8)
    local nIndex = 1
    local nLen = 0
    local nBeg, nEnd
    while nIndex <= nByteCount and nCount > 0 do
        local nMarkIndex = nIndex
        local code = string.byte(szUtf8, nIndex)
        for i = 4, 1, -1 do
            if code >= _tUtf8Mask[i] then
                nIndex = nIndex + i
                break
            end
        end

        nLen = nLen + 1
        if nLen == nStart then
            nBeg = nMarkIndex
        end

        if nBeg then
            nCount = nCount - 1
            if nCount == 0 then
                nEnd = nIndex - 1
            end
        end
    end

    local sz = ""
    if nBeg then
        sz = string.sub(szUtf8, nBeg, nEnd or -1)
    end

    return sz
end

--获取字符串开头连续的数字
function UIHelper.GetUtf8HeadNum(szUtf8)
    local nByteCount = string.len(szUtf8)
    local nIndex = 1
    local nLastIndex = 0
    local szRes = ""
    while nIndex <= nByteCount do
        local code = string.byte(szUtf8, nIndex)
        for i = 4, 1, -1 do
            if code >= _tUtf8Mask[i] then
                nIndex = nIndex + i
                break
            end
        end
        nLastIndex = nLastIndex + 1
        local str = string.sub(szUtf8, 1, nIndex - 1)
        local nNum = tonumber(str)
        if nNum then
            szRes = str
        else
            break
        end
    end

    return szRes, nLastIndex
end


--获取字符串不超过最大宽度得字串
function UIHelper.GetLimitedUtf8Text(szUtf8, nFontSize, nMaxWidth)
    local nByteCount = string.len(szUtf8)
    local nWidth = 0
    local nIndex = 1
    local szRes = ""
    while nIndex <= nByteCount do
        local code = string.byte(szUtf8, nIndex)
        local nLastIndex = nIndex
        for i = 4, 1, -1 do
            if code >= _tUtf8Mask[i] then
                nIndex = nIndex + i
                break
            end
        end
        local str = string.sub(szUtf8, nLastIndex, nIndex - 1)
        nWidth = nWidth + UIHelper.GetUtf8Width(str, nFontSize)
        if nWidth > nMaxWidth then
            nIndex = nLastIndex
            break
        end
        szRes = szRes .. str
    end
    szUtf8 = string.sub(szUtf8, nIndex, string.len(szUtf8))

    return szRes, szUtf8
end


-- GetUtf8RichTextWidth beg --------------------------------
local _tData_GetUtf8RichTextWidth
_tData_GetUtf8RichTextWidth = {
    nTotalWidth = 0,
    tSizeStack = nil,

    AddText = function(szText, szFont)
        local tData = _tData_GetUtf8RichTextWidth
        local tSizeStack = tData.tSizeStack
        local nSize = tSizeStack[#tSizeStack] or 0
        tData.nTotalWidth = tData.nTotalWidth + UIHelper.GetUtf8Width(szText, nSize, szFont)
    end,

    HandleTailTag = function(szTag)
        if szTag == "size" then
            table.remove(_tData_GetUtf8RichTextWidth.tSizeStack)
        end
    end,

    HandleHeadTag = function(szTag, sz, nEnd)
        local tData = _tData_GetUtf8RichTextWidth
        local szVal
        if szTag == "size" then
            _, nEnd, szVal = string.find(sz, "=(%d+)>", nEnd)
            if nEnd == nil then
                return nil
            end
            table.insert(tData.tSizeStack, tonumber(szVal))
        elseif szTag == "img" then
            local nBeg = nEnd
            _, nEnd = string.find(sz, "/>", nEnd)
            if nEnd == nil then
                return nil
            end
            local szSub = string.sub(sz, nBeg, nEnd)
            _, _, szVal = string.find(szSub, "width=.-(%d+)")
            if szVal then
                tData.nTotalWidth = tData.nTotalWidth + tonumber(szVal)
            end
        else
            _, nEnd = string.find(sz, ">", nEnd)
            if nEnd == nil then
                return nil
            end
        end
        return nEnd + 1
    end

}

-- @ szFont defalut is nil, szFont == "HYJinKaiJ"
function UIHelper.GetUtf8RichTextWidth(szUtf8, nFontSize, szFont, bIngoreFlag)
    if string.is_nil(szUtf8) then return 0 end

    if bIngoreFlag then
        szUtf8 = string.gsub(szUtf8, "<", " ")
        szUtf8 = string.gsub(szUtf8, ">", " ")
    end

    local tData = _tData_GetUtf8RichTextWidth
    local nLen = string.len(szUtf8)
    local nBeg, nEnd = 1, 1
    local szTag
    local szText
    tData.tSizeStack = { nFontSize or 26 }
    tData.nTotalWidth = 0
    repeat
        nBeg = nEnd
        -- 找标签
        _, nEnd = string.find(szUtf8, "<", nEnd)
        -- 找不到标签了
        if nEnd == nil then
            -- 处理剩余的文本
            if nBeg < nLen then
                szText = string.sub(szUtf8, nBeg, nLen)
                tData.AddText(szText, szFont)
            end
            break
        end
        -- 找到标签
        if nBeg < nEnd then
            -- 处理前面的文本
            szText = string.sub(szUtf8, nBeg, nEnd - 1)
            tData.AddText(szText, szFont)
        end

        -- 是尾标签
        nEnd = nEnd + 1
        if string.sub(szUtf8, nEnd, nEnd) == "/" then
            _, nEnd, szTag = string.find(szUtf8, "(%a+)>", nEnd + 1)
            if nEnd == nil then
                break
            end
            tData.HandleTailTag(szTag)
            nEnd = nEnd + 1
            -- 是首标签
        else
            _, nEnd, szTag = string.find(szUtf8, "(%a+)", nEnd)
            if nEnd == nil then
                break
            end
            nEnd = tData.HandleHeadTag(szTag, szUtf8, nEnd + 1)
        end
    until nEnd == nil

    return tData.nTotalWidth
end
-- GetUtf8RichTextWidth end --------------------------------

-- 当字符串转码失败时, 去掉其中影响转码的字符(现象: 包含繁体字时, 真机在转码失败时会返回""字符串)
function UIHelper.FixGBKToUTF8(szGBK)
    local szUTF = UIHelper.GBKToUTF8(szGBK)
    if szUTF == "" then
        local arr = {}
        local nLen = string.len(szGBK)
        local i = 1
        while i <= nLen do
            local nByte = string.byte(szGBK, i)
            if nByte < 128 then
                table.insert(arr, UIHelper.GBKToUTF8(string.sub(szGBK, i, i)))
                i = i + 1
            else
                table.insert(arr, UIHelper.GBKToUTF8(string.sub(szGBK, i, i + 1)))
                i = i + 2
            end
        end
        szUTF = table.concat(arr, "")
    end
    return szUTF
end


function UIHelper.IsAllChinese(str)
    return IsSimpleChineseString(str)
end

function UIHelper.IsDigit(str)
    local nLen = string.len(str)
    for nIndex = 1, nLen do
        local byte = string.byte(str, nIndex)
        local bDigitOrAlpha = (byte >= 48 and byte <= 57)   -- 数字 0-9
        if not bDigitOrAlpha then
            return false
        end
    end
    return true
end

function UIHelper.IsDigitOrAlpha(str)
    local nLen = string.len(str)
    for nIndex = 1, nLen do
        local byte = string.byte(str, nIndex)
        local bDigitOrAlpha = (byte >= 48 and byte <= 57) or   -- 数字 0-9
           (byte >= 65 and byte <= 90) or   -- 大写字母 A-Z
           (byte >= 97 and byte <= 122)     -- 小写字母 a-z
        if not bDigitOrAlpha then
            return false
        end
    end
    return true
end

function UIHelper.GetSkillCDText(fTime, bDecimalPoint)
    if fTime > 60 then
        return string.format("%.0fm", math.ceil(fTime / 60))
    end

    if fTime < 1 then
        if bDecimalPoint then
            return string.format("%0.1f", fTime)
        else
            return "0"
        end
    else
        return string.format("%.0f", fTime)
    end
end

function UIHelper.GetSelfStateString(nCurValue, nMaxValue, bDanger, bIgore)
    local szState1 = 100 * nCurValue / nMaxValue
    szState1 = tonumber(string.format("%.1f", szState1)) .. "%"
    local szState2 = ""

    local szSelf = GameSettingData.GetNewValue(UISettingKey.SelfHealthBarDisplay).szDec

    if bDanger and (nCurValue == nMaxValue or nCurValue > 9999) then
        szState2 = "????/????"
    else
        if szSelf == "数字精简显示" then
            if nCurValue >= 100000000 then
                nCurValue = string.format("%.2f", nCurValue / 100000000) .. g_tStrings.DIGTABLE.tCharDiH[3]
            elseif nCurValue > 100000 then
                nCurValue = string.format("%.2f", nCurValue / 10000) .. g_tStrings.DIGTABLE.tCharDiH[2]
            end

            if nMaxValue >= 100000000 then
                nMaxValue = string.format("%.2f", nMaxValue / 100000000) .. g_tStrings.DIGTABLE.tCharDiH[3]
            elseif nMaxValue > 100000 then
                nMaxValue = string.format("%.2f", nMaxValue / 10000) .. g_tStrings.DIGTABLE.tCharDiH[2]
            end
        end

        szState2 = nCurValue .. "/" .. nMaxValue
    end

    if szSelf == "显示数值和百分比" and not bIgore then
        local szState = szState2 .. "(" .. szState1 .. ")"
        return szState
    end

    if szSelf == "百分比显示" then
        return szState1
    end
    return szState2
end

function UIHelper.GetStateString(nCurValue, nMaxValue, bDanger, bIgnore)
    local szState1 = 100 * nCurValue / nMaxValue
    szState1 = tonumber(string.format("%.1f", szState1)) .. "%"
    local szState2 = ""

    local szTarget = GameSettingData.GetNewValue(UISettingKey.TargetHealthBarDisplay).szDec
    if bDanger and (nCurValue == nMaxValue or nCurValue > 9999) then
        szState2 = "????/????"
    else
        if szTarget == "数字精简显示" then
            if nCurValue >= 100000000 then
                nCurValue = string.format("%.2f", nCurValue / 100000000) .. g_tStrings.DIGTABLE.tCharDiH[3]
            elseif nCurValue > 100000 then
                nCurValue = string.format("%.2f", nCurValue / 10000) .. g_tStrings.DIGTABLE.tCharDiH[2]
            end

            if nMaxValue >= 100000000 then
                nMaxValue = string.format("%.2f", nMaxValue / 100000000) .. g_tStrings.DIGTABLE.tCharDiH[3]
            elseif nMaxValue > 100000 then
                nMaxValue = string.format("%.2f", nMaxValue / 10000) .. g_tStrings.DIGTABLE.tCharDiH[2]
            end
        end

        szState2 = nCurValue .. "/" .. nMaxValue
    end

    if szTarget == "显示数值和百分比" and not bIgnore then
        local szState = szState2 .. "(" .. szState1 .. ")"
        return szState
    end

    if szTarget == "百分比显示" then
        return szState1
    end
    return szState2
end

function UIHelper.GetTimeText(nTime, bFrame, bCeil)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end

    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60

    if bCeil then
        nS = math.ceil(nS)
    else
        nS = math.floor(nS)
    end

    return string.format("%02d:%02d:%02d", nH, nM, nS)
end

function UIHelper.GetTimeTextWithDay(nTime, bFrame, bCeil)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end

    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60

    if bCeil then
        nS = math.ceil(nS)
    else
        nS = math.floor(nS)
    end

    if nD > 0 then
        return string.format("%d天%02d时%02d分钟%02d秒", nD, nH, nM, nS)
    elseif nH > 0 then
        return string.format("%02d时%02d分钟%02d秒", nH, nM, nS)
    else
        return string.format("%02d分钟%02d秒", nM, nS)
    end
end

function UIHelper.GetTimeTextWithDayNoFill(nTime, bFrame, bCeil)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end

    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60

    if bCeil then
        nS = math.ceil(nS)
    else
        nS = math.floor(nS)
    end

    if nD > 0 then
        return string.format("%d天%d时%d分%d秒", nD, nH, nM, nS)
    elseif nH > 0 then
        return string.format("%d时%d分%d秒", nH, nM, nS)
    elseif nM > 0 then
        return string.format("%d分%d秒", nM, nS)
    else
        return string.format("%d秒", nS)
    end
end

function UIHelper.GetTimeSecondText(nTime, bFrame)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end

    local fFloatTime = FixFloat(nTime, 2)
    return fFloatTime .. "秒"
end

function UIHelper.GetValueStringWithMostEffective(value)
    local ceilVal = math.ceil(value)
    if ceilVal ~= value then
        return string.format("%.1f", value)
    else
        return string.format("%d", value)
    end
end

function UIHelper.GetTimeHourText(nTime, bFrame)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end

    return string.format("%d%s", nTime, g_tStrings.STR_CHS_TIME_TEXT)
end

function UIHelper.GetDeltaTimeText(nTime, bFrame)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end
    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60
    nS = math.floor(nS)
    local szText = ""
    if nD > 0 then
        szText = tostring(nD) .. g_tStrings.STR_BUFF_H_TIME_D
    end
    if nH > 0 then
        szText = szText .. tostring(nH) .. g_tStrings.STR_BUFF_H_TIME_H
    end
    if nM > 0 then
        szText = szText .. tostring(nM) .. g_tStrings.STR_BUFF_H_TIME_M
    end
    if nS > 0 then
        szText = szText .. tostring(nS) .. g_tStrings.STR_BUFF_H_TIME_S
    end
    return szText
end

function UIHelper.GetDeltaTimeShortText(nTime, bFrame)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end
    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60
    nS = math.floor(nS)
    local szText = ""
    if nD > 0 then
        szText = tostring(nD) .. g_tStrings.STR_BUFF_H_TIME_D_SHORT
    end
    if nH > 0 then
        szText = szText .. tostring(nH) .. g_tStrings.STR_BUFF_H_TIME_H_SHORT
    end
    if nM > 0 then
        szText = szText .. tostring(nM) .. g_tStrings.STR_BUFF_H_TIME_M_SHORT
    end
    if nS > 0 then
        szText = szText .. tostring(nS) .. g_tStrings.STR_BUFF_H_TIME_S_SHORT
    end
    return szText
end

-- 获取最高单位时间文本，如19小时20分钟31秒显示为19小时
function UIHelper.GetHeightestTimeText(nTime, bFrame)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end
    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60
    nS = math.floor(nS)
    local szText = ""
    if nD > 0 then
        szText = tostring(nD) .. g_tStrings.STR_BUFF_H_TIME_D
        return szText
    end
    if nH > 0 then
        szText = szText .. tostring(nH) .. g_tStrings.STR_BUFF_H_TIME_H
        return szText
    end
    if nM > 0 then
        szText = szText .. tostring(nM) .. g_tStrings.STR_BUFF_H_TIME_M
        return szText
    end
    if nS > 0 then
        szText = szText .. tostring(nS) .. g_tStrings.STR_BUFF_H_TIME_S
        return szText
    end
    szText = "0" .. g_tStrings.STR_BUFF_H_TIME_S
    return szText
end

-- 获取最高两个单位时间文本，如19小时20分钟31秒显示为19小时20分
function UIHelper.GetHeightestTwoTimeText(nTime, bFrame, nFixCount)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end
    local nCount = nFixCount or 2
    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60
    nS = math.floor(nS)
    local szText = ""
    if nD > 0 then
        szText = tostring(nD) .. g_tStrings.STR_BUFF_H_TIME_D
        nCount = nCount - 1
    end
    if nH > 0 then
        szText = szText .. tostring(nH) .. g_tStrings.STR_BUFF_H_TIME_H
        nCount = nCount - 1
    end
    if nCount == 0 then return szText end

    if nM > 0 then
        szText = szText .. tostring(nM) .. g_tStrings.STR_BUFF_H_TIME_M
        nCount = nCount - 1
    end
    if nCount == 0 then return szText end

    if nS > 0 then
        szText = szText .. tostring(nS) .. g_tStrings.STR_BUFF_H_TIME_S
        nCount = nCount - 1
    end

    return szText
end

-- 获取最高单位时间+1单位的文本，如19小时20分钟31秒显示为少于20小时
function UIHelper.GetHeightestCeilTimeText(nTime, bFrame)
    if bFrame then
        nTime = nTime / GLOBAL.GAME_FPS
    end
    local nD = math.floor(nTime / 3600 / 24)
    local nH = math.floor(nTime / 3600 % 24)
    local nM = math.floor((nTime % 3600) / 60)
    local nS = (nTime % 3600) % 60
    nS = math.floor(nS)
    local szText = ""
    if nD > 0 then
        szText = tostring(nD + 1) .. g_tStrings.STR_BUFF_H_TIME_D
        return szText
    end
    if nH > 0 then
        szText = szText .. tostring(nH + 1) .. g_tStrings.STR_BUFF_H_TIME_H
        return szText
    end
    if nM > 0 then
        szText = szText .. tostring(nM + 1) .. g_tStrings.STR_BUFF_H_TIME_M
        return szText
    end
    if nS > 0 then
        szText = szText .. tostring(nS + 1) .. g_tStrings.STR_BUFF_H_TIME_S
        return szText
    end
    szText = "0" .. g_tStrings.STR_BUFF_H_TIME_S
    return szText
end

function UIHelper.GetComponent(node, name)
    if not safe_check(node) then
        return
    end
    if string.is_nil(name) then
        return
    end
    return node:getComponent(name)
end

function UIHelper.GetBindScript(node)
    if not node then
        return
    end

    if node.getComponent then
        local compLuaBind = node:getComponent("LuaBind")
        local script = compLuaBind and compLuaBind:getScriptObject()
        return script
    end

    return nil
end

-- 游戏内置浏览器打开
function UIHelper.OpenWeb(szUrl, bForceUseEmbeddedWebPagesInWindows, bPortrait)
    if string.is_nil(szUrl) then
        return
    end

    LOG.INFO("UIHelper.OpenWeb, szUrl = %s, bForceUseEmbeddedWebPagesInWindows = %s, bPortrait = %s", tostring(szUrl), tostring(bForceUseEmbeddedWebPagesInWindows), tostring(bPortrait))

    if (Platform.IsWindows() or Platform.IsMac()) and not bForceUseEmbeddedWebPagesInWindows and not Channel.IsCloud() then
        UIHelper.OpenWebWithDefaultBrowser(szUrl)
    else
        if Channel.Is_WLColud() then
            XGSDK_WLCloud_OpenWebWithDefaultBrowser(false, szUrl)
            return
        end

        if bPortrait then
            UIHelper.SetScreenPortrait(true)
            Event.Reg(UIHelper, EventType.OnViewClose, function(nViewID)
                if nViewID == VIEW_ID.PanelEmbeddedWebPagesPortrait then
                    Event.UnReg(UIHelper, EventType.OnViewClose)
                    UIHelper.SetScreenPortrait(false)
                end
            end)
            return UIMgr.Open(VIEW_ID.PanelEmbeddedWebPagesPortrait, szUrl)
        else
            return UIMgr.Open(VIEW_ID.PanelEmbeddedWebPages, szUrl)
        end
    end
end

-- 使用操作系统默认浏览器打开
function UIHelper.OpenWebWithDefaultBrowser(szUrl)
    if string.is_nil(szUrl) then
        return
    end

    LOG.INFO("UIHelper.OpenWebWithDefaultBrowser, szUrl = %s", tostring(szUrl))

    if Channel.Is_WLColud() then
        --- 蔚领云版本尝试使用默认浏览器时，不直接打开，而是转发到云游戏app上去实际打开
        XGSDK_WLCloud_OpenWebWithDefaultBrowser(true, szUrl)
        return
    elseif Channel.IsCloud() then
        UIHelper.OpenWeb(szUrl)
        return
    end

    OpenWebWithDefaultBrowser(szUrl)
end

--[[
-- 节点置灰
  @node 节点对象
  @bGray 是否置灰
  @bCascade 是否级联到各个子节点
]]
function UIHelper.SetNodeGray(node, bGray, bCascade)
    if not safe_check(node) then
        return
    end
    if bGray == nil then
        return
    end
    if not bCascade then
        bCascade = false
    end
    CascadeSetGray(node, bGray, bCascade)
end

--[[
-- 节点设置SwallowTouches
  @node 节点对象
  @bSwallow 是否吞噬
  @bCascade 是否级联到各个子节点
]]
function UIHelper.SetNodeSwallowTouches(node, bSwallow, bCascade)
    if not safe_check(node) then
        return
    end
    if bSwallow == nil then
        return
    end
    if not bCascade then
        bCascade = false
    end
    CascadeSetSwallowTouches(node, bSwallow, bCascade)
end

--[[
	播放序列帧动画
	@sprite Sprite节点
	@nSpriteFrameAnimtionID    UISpriteFrameAnimationTab表里的ID字段
]]
function UIHelper.PlaySpriteFrameAnimtion(sprite, nSpriteFrameAnimtionID, bKeepSize)
    if not safe_check(sprite) then
        return
    end
    if not nSpriteFrameAnimtionID then
        return
    end

    local tbAnimConf = UISpriteFrameAnimationTab[nSpriteFrameAnimtionID]
    if not tbAnimConf then
        return
    end

    if bKeepSize == nil then
        bKeepSize = false
    end

    local szPlist = tbAnimConf.szPlist
    local szNameFormat = tbAnimConf.szNameFormat
    local nStart = tbAnimConf.nStart
    local nEnd = tbAnimConf.nEnd
    local tbIndexList = tbAnimConf.tbIndexList
    local nDelayPerUnit = tbAnimConf.nDelayPerUnit
    local nLoops = tbAnimConf.nLoops

    cc_spriteFrameCache:addSpriteFramesWithJson(szPlist)

    local tbSpriteFrames = {}
    if not table.is_empty(tbIndexList) then
        for k, v in ipairs(tbIndexList) do
            local szName = string.format(szNameFormat, v)
            table.insert(tbSpriteFrames, cc_spriteFrameCache:getSpriteFrame(szName))
        end
    else
        for i = nStart, nEnd do
            local szName = string.format(szNameFormat, i)
            local spriteFrame = cc_spriteFrameCache:getSpriteFrame(szName)
            table.insert(tbSpriteFrames, spriteFrame)
        end
    end

    local animation = cc.Animation:createWithSpriteFrames(tbSpriteFrames, nDelayPerUnit, nLoops, bKeepSize)
    local animate = cc.Animate:create(animation)
    sprite:runAction(animate)
end

function UIHelper.StopAllActions(node)
    if not safe_check(node) then
        return
    end

    if node.stopAllActions then
        node:stopAllActions()
    end
end

function UIHelper.GetText(editbox)
    if not safe_check(editbox) then
        return
    end
    return editbox:getText()
end

function UIHelper.SetText(editbox, szContent)
    if not safe_check(editbox) then
        return
    end
    return editbox:setText(szContent)
end

function UIHelper.GetPlaceHolder(editbox)
    if not safe_check(editbox) then
        return
    end
    return editbox:getPlaceHolder()
end

function UIHelper.SetPlaceHolder(editbox, szContent)
    if not safe_check(editbox) then
        return
    end
    return editbox:setPlaceHolder(szContent)
end

function UIHelper.SetEditboxTextHorizontalAlign(editbox, nTextHAlignment)
    --TextHAlignment.CENTER
    if not safe_check(editbox) then
        return
    end
    editbox:setTextHorizontalAlignment(nTextHAlignment)
end

--cc.EditBoxInputMode_Any = 0,
--cc.EditBoxInputMode_EmailAddress = 1,
--cc.EditBoxInputMode_Numeric = 2,
--cc.EditBoxInputMode_PhoneNumber = 3,
--cc.EditBoxInputMode_URL = 4,
--cc.EditBoxInputMode_Decime = 5,
--cc.EditBoxInputMode_SingleLine = 6,
function UIHelper.SetEditBoxInputMode(editbox, nInputMode)
    if not safe_check(editbox) or not IsNumber(nInputMode) then
        return
    end
    editbox:setInputMode(nInputMode)
end

-- 设置输入框游戏内小键盘的输入范围
function UIHelper.SetEditBoxGameKeyboardRange(editbox, nMin, nMax)
    if not safe_check(editbox) then
        return
    end

    if IsNumber(nMin) then
        editbox:setGameNumKeyboardMin(nMin)
    end

    if IsNumber(nMax) then
        editbox:setGameNumKeyboardMax(nMax)
    end
end

function UIHelper.SetClearStencilAll(mask, bClear)
    if not safe_check(mask) then
        return
    end

    mask:setClearStencilAll(bClear)
end

function UIHelper.UpdateMask(mask)
    if not safe_check(mask) then
        return
    end

    mask:updateMask()
end

--==== money text ====================================================================================
function UIHelper.MoneyToGoldSilverAndCopper(nMoney)
    local nGold = mfloor(nMoney / 10000)
    nMoney = nMoney - nGold * 10000
    local nSilver = mfloor(nMoney / 100)
    local nCopper = nMoney - nSilver * 100

    return nGold, nSilver, nCopper
end

function UIHelper.MoneyToBullionGoldSilverAndCopper(nMoney)

    local nGold = 0
    local nSilver = 0
    local nCopper = 0
    local nBullion = 0

    nBullion = nMoney / 100000000
    nBullion = math.floor(nBullion)
    nGold = (nMoney % 100000000) / 10000
    nGold = math.floor(nGold)
    nSilver = (nMoney % 10000) / 100
    nSilver = math.floor(nSilver)
    nCopper = nMoney % 100
    nCopper = math.floor(nCopper)

    return nBullion, nGold, nSilver, nCopper
end

function UIHelper.BullionGoldSilverAndCopperToMoney(nBullion, nGold, nSilver, nCopper)
    nBullion = nBullion or 0
    nGold = nGold or 0
    nSilver = nSilver or 0
    nCopper = nCopper or 0
    return nBullion * 100000000 + nGold * 10000 + nSilver * 100 + nCopper
end

function UIHelper.GoldSilverAndCopperToMoney(nGold, nSilver, nCopper)
    if type(nGold) == "table" then
        nGold, nSilver, nCopper = unpack(nGold)
    end

    return nGold * 10000 + nSilver * 100 + nCopper
end

function UIHelper.GetMoneyTipText(nMoney, bGold)
    local nGold, nSilver, nCopper
    local tMoney = nMoney
    if bGold then
        tMoney = { nGold = nMoney }
    elseif type(nMoney) == "number" then
        tMoney = PackMoney(UIHelper.MoneyToGoldSilverAndCopper(nMoney))
    end

    local szMoney = UIHelper.GetMoneyText(tMoney)
    return szMoney
end

function UIHelper.GetGoldText(nGold, nFontSize)
    nFontSize = nFontSize or 26
    local nImageSize = nFontSize * 1.5
    local szText = string.format(" %d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='%d' height='%d' />", nGold, nImageSize, nImageSize)
    return szText
end

function UIHelper.GetTongGoldText(nTongGold, nFontSize)
    nFontSize = nFontSize or 26
    local nImageSize = nFontSize * 1.5
    local szText = string.format(" %d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao' width='%d' height='%d' />", nTongGold, nImageSize, nImageSize)
    return szText
end

function UIHelper.GetCurrencyText(nCurrency, szIconFile, nFontSize)
    nFontSize = nFontSize or 26
    local nImageSize = nFontSize * 1.5
    local szText = string.format(" %d<img src='%s' width='%d' height='%d' />", nCurrency, szIconFile, nImageSize, nImageSize)
    return szText
end

function UIHelper.GetItemText(nItemCount, szIconFile, nFontSize)
    nFontSize = nFontSize or 26
    local nImageSize = nFontSize * 1.5
    local szText = string.format(" %d<img src='%s' width='%d' height='%d' />", nItemCount, szIconFile, nImageSize, nImageSize)
    return szText
end


-- @param szIndent 间隔填充
-- @param bAll 是否完全显示
function UIHelper.GetMoneyText(nMoney, nFontSize, szIndent, bAll)
    local szText = ""
    local nGoldBrick = 0
    local nGold, nSilver, nCopper
    nFontSize = nFontSize or 26

    if type(nMoney) == "table" then
        nGold, nSilver, nCopper = UnpackMoney(nMoney)
    else
        nGold, nSilver, nCopper = UIHelper.MoneyToGoldSilverAndCopper(nMoney)
    end

    if nGold >= 10000 then
        nGoldBrick = mfloor(nGold / 10000)
        nGold = nGold - nGoldBrick * 10000
    end
    szIndent = szIndent or ""

    local t = {}
    local nImgSize = nFontSize * 1.5
    -- brick
    if nGoldBrick > 0 or bAll then
        table.insert(t, string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Zhuan' width='%d' height='%d' />", nGoldBrick, nImgSize, nImgSize))
        bAll = true
    end
    -- glod
    if nGold > 0 or bAll then
        table.insert(t, string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='%d' height='%d' />", nGold, nImgSize, nImgSize))
        bAll = true
    end
    -- sliver
    if nSilver > 0 or bAll then
        table.insert(t, string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Yin' width='%d' height='%d' />", nSilver, nImgSize, nImgSize))
        bAll = true
    end
    -- copper
    if nCopper > 0 or bAll then
        table.insert(t, string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong' width='%d' height='%d' />", nCopper, nImgSize, nImgSize))
    end

    return string.format("<size=%d>%s</size>", nFontSize, table.concat(t, szIndent))
end

-- @param szIndent 间隔填充
-- @param bAll 是否完全显示
function UIHelper.GetGoldAndBrickText(nMoney, nFontSize, szIndent, bAll)
    local szText = ""
    local nGoldBrick = 0
    local nGold, nSilver, nCopper
    nFontSize = nFontSize or 26

    nGold = nMoney

    if nGold >= 10000 then
        nGoldBrick = mfloor(nGold / 10000)
        nGold = nGold - nGoldBrick * 10000
    end
    szIndent = szIndent or ""

    local t = {}
    local nImgSize = nFontSize * 1.5
    -- brick
    if nGoldBrick > 0 then
        table.insert(t, string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Zhuan' width='%d' height='%d' />", nGoldBrick, nImgSize, nImgSize))
        bAll = true
    end
    -- glod
    if nGold > 0 or bAll then
        table.insert(t, string.format("%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='%d' height='%d' />", nGold, nImgSize, nImgSize))
        bAll = true
    end

    return string.format("<size=%d>%s</size>", nFontSize, table.concat(t, szIndent))
end

function UIHelper.GetFundText(nFund, nFontSize, szIcon)
    local nImgSize = nFontSize * 1.5
    szIcon = szIcon or "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_BangHui"
    return string.format("<size=%d>%d<img src='%s' width='%d' height='%d' /></size>", nFontSize, nFund, szIcon, nImgSize, nImgSize)
end

function UIHelper.GetMoneyIcon(nMoney)
    local nGold, nSilver, nCopper
    if type(nMoney) == "table" then
        nGold, nSilver, nCopper = UnpackMoney(nMoney)
    else
        nGold, nSilver, nCopper = UIHelper.MoneyToGoldSilverAndCopper(nMoney)
    end

    local nIconID = 1
    if nGold > 0 then
        if nGold >= 10000 then
            return "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Zhuan_Big.png";
        end
        return "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Jin_Big.png";
        -- if nGold <= 10 then
        --     --nIconID = 2 --95 					--金的图标
        -- else
        --    -- nIconID = 1 --94					--金的图标
        -- end
    elseif nSilver > 0 then
        -- if nSilver <= 10 then
        --     nIconID = 4 --97 					--银的图标
        -- else
        --     nIconID = 3 --96 					--银的图标
        -- end
        return "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Yin_Big.png";
    else
        -- if nCopper <= 10 then
        --     nIconID = 6 --99					--铜的图标
        -- else
        --     nIconID = 5 --98					--铜的图标
        -- end
        return "UIAtlas2_Public_PublicMoney_PublicMoney_Big_img_Tong_Big.png";
    end

    return string.format("Resource/icon/item/Coin/coin0%d.png", nIconID)
end

function UIHelper.SetMoneyIcon(node, nMoney)
    if not safe_check(node) then
        return
    end
    local szFile = UIHelper.GetMoneyIcon(nMoney or 0)
    assert(szFile)
    UIHelper.SetSpriteFrame(node, szFile)
end

function UIHelper.GetMoneyPureText(nMoney)
    local szText = ""
    local bCheckZero = true
    local nGold, nSilver, nCopper
    if type(nMoney) == "table" then
        nGold, nSilver, nCopper = UnpackMoney(nMoney)
    else
        nGold, nSilver, nCopper = UIHelper.MoneyToGoldSilverAndCopper(nMoney)
    end
    if nGold ~= 0 then
        szText = szText .. FormatString(g_tStrings.MPNEY_GOLD, nGold)
        bCheckZero = false
    end

    if not bCheckZero or nSilver ~= 0 then
        szText = szText .. FormatString(g_tStrings.MPNEY_SILVER, nSilver)
    end

    szText = szText .. FormatString(g_tStrings.MPNEY_COPPER, nCopper)
    return szText
end

function UIHelper.SetMoneyText(container, nMoney, nFontSize, bAll, szPrevious, c4bColor)
    if not safe_check(container) then
        return
    end
    nMoney = nMoney or 0
    nFontSize = nFontSize or 22

    local nGoldBrick = 0
    local nGold, nSilver, nCopper
    if type(nMoney) == "table" then
        nGold, nSilver, nCopper = UnpackMoney(nMoney)
    else
        nGold, nSilver, nCopper = UIHelper.MoneyToGoldSilverAndCopper(nMoney)
    end

    if nGold >= 10000 then
        nGoldBrick = mfloor(nGold / 10000)
        nGold = nGold - nGoldBrick * 10000
    end

    local t = {}

    -- previous text
    if szPrevious then
        table.insert(t, { szText = szPrevious, nFontSize = nFontSize, nVAlign = 1 })
    end

    -- brick
    if nGoldBrick > 0 or bAll then
        table.insert(t, { szText = tostring(nGoldBrick), nFontSize = nFontSize, nVAlign = 1 })
        table.insert(t, { szFrame = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Zhuan", nWidth = nFontSize * 1.5, nVAlign = 1 })
        table.insert(t, { szText = " ", nFontSize = nFontSize, nVAlign = 1 })
        bAll = true
    end
    -- glod
    if nGold > 0 or bAll then
        table.insert(t, { szText = tostring(nGold), nFontSize = nFontSize, nVAlign = 1 })
        table.insert(t, { szFrame = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin", nWidth = nFontSize * 1.5, nVAlign = 1 })
        table.insert(t, { szText = " ", nFontSize = nFontSize, nVAlign = 1 })
        bAll = true
    end
    -- sliver
    if nSilver > 0 or bAll then
        table.insert(t, { szText = tostring(nSilver), nFontSize = nFontSize, nVAlign = 1 })
        table.insert(t, { szFrame = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Yin", nWidth = nFontSize * 1.5, nVAlign = 1 })
        table.insert(t, { szText = " ", nFontSize = nFontSize, nVAlign = 1 })
        bAll = true
    end
    -- copper
    if nCopper > 0 or bAll then
        table.insert(t, { szText = tostring(nCopper), nFontSize = nFontSize, nVAlign = 1 })
        table.insert(t, { szFrame = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong", nWidth = nFontSize * 1.5, nVAlign = 1 })
    end

    UIHelper.SetPoorText(container, t, 1, c4bColor)
end

function UIHelper.OpenWebview(webview, url)
    webview:loadURL(url)
end

function UIHelper.WebviewCanGoBack(webview)
    return webview:canGoBack()
end

function UIHelper.WebviewCanGoForward(webview)
    return webview:canGoForward()
end

function UIHelper.WebviewGoBack(webview)
    return webview:goBack()
end

function UIHelper.WebviewGoForward(webview)
    return webview:goForward()
end

--==== end ====================================================================================

function UIHelper.AddItemIconPrefab_Small(container)
    if not safe_check(container) then
        return
    end
    local szPrefabName = "WidgetItem_44"

    -- local tItemScript
    -- local itemNode = container:getChildByName(szPrefabName)
    -- if itemNode then
    -- 	tItemScript = UIHelper.GetBindScript(itemNode)
    -- 	assert(tItemScript)
    -- else
    -- 	tItemScript = UIHelper.AddPrefab(PREFAB_ID[szPrefabName], container)
    -- 	assert(tItemScript)
    -- 	tItemScript:SetSelectEnable(false)
    -- end

    UIHelper.RemoveAllChildren(container)
    local tItemScript = UIHelper.AddPrefab(PREFAB_ID[szPrefabName], container)
    assert(tItemScript)
    tItemScript:SetSelectEnable(false)

    return tItemScript
end

local function GetImageFile(tData, nRoleType)
    if nRoleType == ROLE_TYPE.STANDARD_MALE then
        return tData.szM2Image, tData.nM2ImgFrame, tData.szM2Sfx

    elseif nRoleType == ROLE_TYPE.STANDARD_FEMALE then
        return tData.szF2Image, tData.nF2ImgFrame, tData.szF2Sfx

    elseif nRoleType == ROLE_TYPE.STRONG_MALE then
        return tData.szM3Image, tData.nM3ImgFrame, tData.szM3Sfx

    elseif nRoleType == ROLE_TYPE.SEXY_FEMALE then
        return tData.szF3Image, tData.nF3ImgFrame, tData.szF3Sfx

    elseif nRoleType == ROLE_TYPE.LITTLE_BOY then
        return tData.szM1Image, tData.nM1ImgFrame, tData.szM1Sfx

    elseif nRoleType == ROLE_TYPE.LITTLE_GIRL then
        return tData.szF1Image, tData.nF1ImgFrame, tData.szF1Sfx
    end
end

function UIHelper.RoleChange_UpdateAvatar(playerImgNode, dwMiniAvatarID, SFXPlayerIconNode, playerAniNode, nRoleType, dwForceID, bFlip, bZombieMod, tTargetPlayer, bOnlyAvatar)
    local dwID = dwMiniAvatarID or g_pClientPlayer.dwMiniAvatarID
    if bZombieMod and BattleFieldData.IsInZombieBattleFieldMap() then
        local player = g_pClientPlayer
        if tTargetPlayer then
            player = tTargetPlayer
        end
        local tLine = Table_GetPlayerZombieLevel(player)
        if tLine then
            dwID = tLine.dwAvatarID
        end
    end
    if bOnlyAvatar == nil then--优先使用bOnlyAvatar参数，同步端游
        bOnlyAvatar = true
    end

    UIHelper.ClearAvatarState(playerImgNode, playerAniNode, SFXPlayerIconNode)

    local szImage, nImgFrame, szSfx = Table_GetRoleavatar(dwID, (nRoleType and nRoleType ~= 0) and nRoleType or g_pClientPlayer.nRoleType, bOnlyAvatar)
    if dwMiniAvatarID == 0 and nRoleType == 0 and dwForceID == 0 then
        nImgFrame = -1
    end
    if nImgFrame == -1 and (szImage ~= "" or dwID == 0) then
        if not playerImgNode then
            return
        end
        UIHelper.SetVisible(playerImgNode, true)
        if dwID ~= 0 then
            szImage = ParseTextHelper.ConvertAvatarPathText(szImage)
        else
            szImage = DefaultAvatar[dwForceID or g_pClientPlayer.dwForceID]
        end
        UIHelper.SetTexture(playerImgNode, szImage)

        local nScale = UIHelper.GetScaleX(playerImgNode)
        if (nScale > 0 and bFlip and dwID ~= 0) then
            UIHelper.SetScaleX(playerImgNode, -nScale)
        elseif nScale < 0 and (not bFlip or dwID == 0) then
            UIHelper.SetScaleX(playerImgNode, -nScale)
        end
    elseif szSfx == "" then
        if string.is_nil(szImage) then
            return
        end

        if not playerAniNode then
            return
        end
        UIHelper.SetVisible(playerAniNode, true)

        local szPlist = ParseTextHelper.ConvertAvatarPathText(szImage)
        cc_spriteFrameCache:addSpriteFramesWithJson(szPlist)
        local tbFrames = cc_spriteFrameCache:getFramesByPlist(szPlist)

        local tbSpriteFrames = {}
        for k, v in ipairs(tbFrames or {}) do
            table.insert(tbSpriteFrames, cc_spriteFrameCache:getSpriteFrame(v))
            cc_spriteFrameCache:removeSpriteFrameByName(v)
        end
        local animation = cc.Animation:createWithSpriteFrames(tbSpriteFrames, 0.1, -1)
        local animate = cc.Animate:create(animation)
        playerAniNode:runAction(animate)

        local nScale = UIHelper.GetScaleX(playerAniNode)
        if (nScale > 0 and bFlip) then
            UIHelper.SetScaleX(playerAniNode, -nScale)
        elseif nScale < 0 and (not bFlip or dwID == 0) then
            UIHelper.SetScaleX(playerImgNode, -nScale)
        end
    else
        UIHelper.SetVisible(SFXPlayerIconNode, true)
        UIHelper.SetSFXPath(SFXPlayerIconNode, szSfx, true)
    end
end

function UIHelper.RoleChange_UpdateRankAvatar(playerImgNode, dwMiniAvatarID, SFXPlayerIconNode, playerAniNode, nRoleType, dwForceID, bWanted, bFlip, bOnlyAvatar)
    local dwID = dwMiniAvatarID

    if bOnlyAvatar == nil then--优先使用bOnlyAvatar参数，同步端游
        bOnlyAvatar = true
    end
    UIHelper.ClearAvatarState(playerImgNode, playerAniNode, SFXPlayerIconNode)
    local szImage, nImgFrame, szSfx = Table_GetRoleavatar(dwID, nRoleType or g_pClientPlayer.nRoleType, bOnlyAvatar)

    if bWanted then
        local tWantedInfo = Table_GetWantedRoleavatar(dwForceID)
        if tWantedInfo then
            szImage, nImgFrame = GetImageFile(tWantedInfo, nRoleType)
        end
    end

    if nImgFrame == -1 then
        UIHelper.SetVisible(playerImgNode, true)
        if dwID ~= 0 or bWanted then
            szImage = ParseTextHelper.ConvertAvatarPathText(szImage)
        else
            szImage = DefaultAvatar[dwForceID or g_pClientPlayer.dwForceID]
        end

        szImage = UIHelper.FixDXUIImagePath(szImage)
        UIHelper.SetTexture(playerImgNode, szImage)

        local nScale = UIHelper.GetScaleX(playerImgNode)
        if (nScale > 0 and bFlip and dwID ~= 0) then
            UIHelper.SetScaleX(playerImgNode, -nScale)
        elseif nScale < 0 and (not bFlip or dwID == 0) then
            UIHelper.SetScaleX(playerImgNode, -nScale)
        end
    elseif szSfx == "" then
        UIHelper.SetVisible(playerAniNode, true)

        local szPlist = ParseTextHelper.ConvertAvatarPathText(szImage)
        cc_spriteFrameCache:addSpriteFramesWithJson(szPlist)
        local tbFrames = cc_spriteFrameCache:getFramesByPlist(szPlist)

        local tbSpriteFrames = {}
        for k, v in ipairs(tbFrames or {}) do
            table.insert(tbSpriteFrames, cc_spriteFrameCache:getSpriteFrame(v))
            cc_spriteFrameCache:removeSpriteFrameByName(v)
        end
        local animation = cc.Animation:createWithSpriteFrames(tbSpriteFrames, 0.1, -1)
        local animate = cc.Animate:create(animation)
        playerAniNode:runAction(animate)

        local nScale = UIHelper.GetScaleX(playerAniNode)
        if (nScale > 0 and bFlip) then
            UIHelper.SetScaleX(playerAniNode, -nScale)
        elseif nScale < 0 and (not bFlip or dwID == 0) then
            UIHelper.SetScaleX(playerImgNode, -nScale)
        end
    else
        UIHelper.SetVisible(SFXPlayerIconNode, true)
        UIHelper.SetSFXPath(SFXPlayerIconNode, szSfx, true)
    end
end

function UIHelper.UpdateAvatarFarme(tbImgFrameNormalBg, dwID, FrameBgAll, FrameBgLeft, FrameBgRight, bHaveMana)
    UIHelper.ClearAvatarFarmeState(tbImgFrameNormalBg, FrameBgAll, FrameBgLeft, FrameBgRight)

    local tImage = g_tTable.RoleAvatar:Search(dwID)
    -- VK没有UICommon/Player.UITex这个图集，如果表里使用了就会不显示默认框
    if tImage and tImage.szWholeSfx ~= "" and tImage.szWholeSfx ~= "/ui/Image/UItimate/UICommon/Player.UITex" then
        if bHaveMana and tImage.szWholeSfxMana and tImage.szWholeSfxMana ~= "" then
            UIHelper.SetSFXPath(FrameBgAll, tImage.szWholeSfxMana, true)
        else
            UIHelper.SetSFXPath(FrameBgAll, tImage.szWholeSfx, true)
        end
        UIHelper.SetVisible(FrameBgAll, true)
    elseif tImage and tImage.szLeftHUDImage ~= "" and tImage.szLeftHUDImage ~= "/ui/Image/UItimate/UICommon/Player.UITex" then
        if bHaveMana and tImage.szMidHUDImageMana and tImage.szMidHUDImageMana ~= "" then
            UIHelper.SetNormalBgSpriteFrame(tImage.szMidHUDImageMana, tbImgFrameNormalBg)
        elseif tImage.szMidHUDImage then
            UIHelper.SetNormalBgSpriteFrame(tImage.szMidHUDImage, tbImgFrameNormalBg)
        end

        if tImage and tImage.szLeftSfx and tImage.szLeftSfx ~= "" then
            if bHaveMana and tImage.szLeftSfxMana then
                local sz = UIHelper.GBKToUTF8(tImage.szLeftSfxMana)
                UIHelper.SetSFXPath(FrameBgLeft, tImage.szLeftSfxMana, true)
            else
                UIHelper.SetSFXPath(FrameBgLeft, tImage.szLeftSfx, true)
            end
            UIHelper.SetVisible(FrameBgLeft, true)
            UIHelper.SetVisible(tbImgFrameNormalBg[1], false)
        else
            if bHaveMana and tImage.szLeftHUDImageMana and tImage.szLeftHUDImageMana then
                UIHelper.SetNormalBgSpriteFrame(tImage.szLeftHUDImageMana, tbImgFrameNormalBg)
            elseif tImage.szLeftHUDImage then
                UIHelper.SetNormalBgSpriteFrame(tImage.szLeftHUDImage, tbImgFrameNormalBg)
            end
        end

        if tImage and tImage.szRightSfx and tImage.szRightSfx ~= "" then
            if bHaveMana and tImage.szRightSfxMana then
                UIHelper.SetSFXPath(FrameBgRight, tImage.szRightSfxMana, true)
            else
                UIHelper.SetSFXPath(FrameBgRight, tImage.szRightSfx, true)
            end
            UIHelper.SetVisible(FrameBgRight, true)
            UIHelper.SetVisible(tbImgFrameNormalBg[3], false)
        else
            if bHaveMana and tImage.szRightHUDImageMana and tImage.szRightHUDImageMana ~= "" then
                UIHelper.SetNormalBgSpriteFrame(tImage.szRightHUDImageMana, tbImgFrameNormalBg)
            elseif tImage.szRightHUDImage then
                UIHelper.SetNormalBgSpriteFrame(tImage.szRightHUDImage, tbImgFrameNormalBg)
            end
        end
    else
        for k, v in ipairs(tbImgFrameNormalBg) do
            UIHelper.SetSpriteFrame(tbImgFrameNormalBg[k], DefaultAvatarFrame[k])
            UIHelper.SetVisible(tbImgFrameNormalBg[k], true)
        end
    end
end

function UIHelper.UpdateDesignationDecorationFarme(tInfo, ImgDecoration, Eff_Decoration, LabelName, szLabelContent)
    local bShowSfx = false
    local bShowImg = false
    if tInfo.szImgPath ~= "" then
        bShowImg = true
        UIHelper.SetTexture(ImgDecoration,UIHelper.FixDXUIImagePath(tInfo.szImgPath))
    elseif tInfo.szSfxPath ~= "" then
        bShowSfx = true
        UIHelper.SetSFXPath(Eff_Decoration, tInfo.szSfxPath, true)
    end
    UIHelper.SetVisible(ImgDecoration, bShowImg)
    UIHelper.SetVisible(Eff_Decoration, bShowSfx)
    if Eff_Decoration then
        Eff_Decoration:setVisible(bShowSfx)
    end
    local tFontRGB = SplitString(tInfo.szFontRGB, "|")
    local szFontRGB = string.format("#%02x%02x%02x", tFontRGB[1], tFontRGB[2], tFontRGB[3])

    local tBorderRGB = SplitString(tInfo.szBorderRGB, "|")
    local szBorderRGB = string.format("#%02x%02x%02x", tBorderRGB[1], tBorderRGB[2], tBorderRGB[3])
    local szXMLContent = string.format("<color=%s><outline=%s&%d>%s</u></c>",szFontRGB, szBorderRGB, tInfo.nBorderSize,szLabelContent or "称号示例文字")
    if LabelName then
        UIHelper.SetRichText(LabelName, szXMLContent)
    end

end

function UIHelper.SetNormalBgSpriteFrame(szImage, tbImgFrameNormalBg)
    if not szImage or szImage == "" then
        return
    end

    local szPlist = ParseTextHelper.ConvertAvatarPathText(szImage)
    cc_spriteFrameCache:addSpriteFramesWithJson(szPlist)

    local tbFrames = cc_spriteFrameCache:getFramesByPlist(szPlist)
    for k, v in ipairs(tbFrames or {}) do
        UIHelper.SetSpriteFrame(tbImgFrameNormalBg[k], v)
        UIHelper.SetVisible(tbImgFrameNormalBg[k], true)
        cc_spriteFrameCache:removeSpriteFrameByName(v)
    end
end

function UIHelper.ClearAvatarState(playerNode, playerAniNode, SFXPlayerIconNode)
    if playerAniNode then
        playerAniNode:stopAllActions()
    end
    if SFXPlayerIconNode and SFXPlayerIconNode.DelModel then
        SFXPlayerIconNode:DelModel()
    end
    UIHelper.SetVisible(playerNode, false)
    UIHelper.SetVisible(playerAniNode, false)
    UIHelper.SetVisible(SFXPlayerIconNode, false)
end

function UIHelper.ClearAvatarFarmeState(tbImgFrameNormalBg, FrameBgAll, FrameBgLeft, FrameBgRight)
    for k, v in ipairs(tbImgFrameNormalBg) do
        UIHelper.SetVisible(tbImgFrameNormalBg[k], false)
    end
    for _, bg in ipairs({ FrameBgAll, FrameBgLeft, FrameBgRight }) do
        if bg.DelModel then
            bg:DelModel()
        end
        UIHelper.SetVisible(bg, false)
    end
end

function UIHelper.SetSFXPath(sfx, szPath, bLoop, nAlpha, fAngle, fYaw)
    if not sfx or not szPath or szPath == "" then
        return
    end

    local bStateFrame = 1
    local bShowOnce = bLoop and 0 or 1
    nAlpha = nAlpha or 255
    fAngle = fAngle or 0
    fYaw = fYaw or 0

    sfx:LoadSfx(szPath, nAlpha, fAngle, fYaw, bShowOnce, 1)
end

function UIHelper.PlaySFX(sfx, nLoop)
    if not sfx then
        return
    end
    nLoop = nLoop or 0
    sfx:Play(nLoop)
end

function UIHelper.InitItemIcon(tItemScript, item, nCount, bShowTip)
    assert(tItemScript)
    assert(item)
    tItemScript:OnInitWithTabID(item.dwTabType, item.dwIndex, nCount)
    if bShowTip then
        tItemScript:SetClickCallback(function(dwItemTabType, dwItemTabIndex)
            TipsHelper.DeleteAllHoverTips()
            local uiTips, uiItemTipScript = TipsHelper.ShowItemTips(tItemScript._rootNode, item.dwTabType, item.dwIndex)
            if item.dwID then
                uiItemTipScript:OnInitWithItemID(item.dwID)
            end
            uiItemTipScript:SetBtnState({})
        end)
    end
end

function UIHelper.InitItemIcon_Exp(tItemScript)
    assert(tItemScript)
    tItemScript:SetIconBySpriteFrameName("UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YueLi.png")
    tItemScript:SetLabelCount(0)
end

function UIHelper.InitItemIcon_Money(tItemScript, nMoney)
    assert(tItemScript)
    local szFile = UIHelper.GetMoneyIcon(nMoney or 0)
    tItemScript:SetIconBySpriteFrameName(szFile)
    tItemScript:SetLabelCountVisible(false)
end

-- fnCallback(szName): Cancel => szName = nil
function UIHelper.ShowModifyNamePanel(szTitle, szDefault, fnCallback, nMaxLength)
    -- UIPanelModifyNamePop
    UIMgr.Open(VIEW_ID.PanelModifyNamePop, szTitle, szDefault, fnCallback, nMaxLength)
end

-- fnCallback(szText): Cancel => szText = nil
function UIHelper.ShowEditPanel(szTitle, szDefault, fnCallback, nMaxLength, szEmptyTips)
    -- UIPanelFactionEditPop
    UIMgr.Open(VIEW_ID.PanelFactionAnnounceEditPop, szTitle, szDefault, fnCallback, nMaxLength, szEmptyTips)
end

function UIHelper.RemoveUnusedTexture()
    cc_spriteFrameCache:removeUnusedSpriteFrames()
    cc_textureCache:removeUnusedTextures()
end

function UIHelper.SetMaxLength(editbox, nMaxLength)
    if not safe_check(editbox) then
        return
    end
    if not nMaxLength then
        return
    end
    editbox:setMaxLength(nMaxLength)
end

function UIHelper.GetPureText(szInfo, bIgnorFirstSpace)
    local _, aInfo = GWTextEncoder_Encode(szInfo)
    if not aInfo then
        return ""
    end

    local szText = ""
    for k, v in pairs(aInfo) do
        if v.name == "text" then
            --普通文本
            szText = szText .. UIHelper.EncodeComponentsString(v.context)
        elseif v.name == "N" then
            --自己的名字
            szText = szText .. UIHelper.EncodeComponentsString(GetClientPlayer().szName)
        elseif v.name == "C" then
            --自己的体型对应的称呼
            szText = szText .. g_tStrings.tRoleTypeToName[GetClientPlayer().nRoleType]
        elseif v.name == "F" then
            --字体
            szText = szText .. UIHelper.EncodeComponentsString(v.attribute.text)
        elseif v.name == "T" then
            --图片
        elseif v.name == "A" then
            --动画
        elseif v.name == "H" then
            --控制行高，如果高度大于当前行高，调整为这个高度，否则，不变
        elseif v.name == "G" then
            --4个英文空格
            if not bIgnorFirstSpace then
                if v.attribute.english then
                    szText = szText .. "    "
                else
                    szText = szText .. g_tStrings.STR_TWO_CHINESE_SPACE
                end
                bIgnorFirstSpace = true
            end
        elseif v.name == "J" then
            --金钱
            local nMoney = tonumber(v.attribute.money)
            local tMoney = PackMoney(MoneyToGoldSilverAndCopper(nMoney))
            szText = szText .. UIHelper.GetMoneyPureText(tMoney)
        elseif v.name == "AT" then
            --动作
        elseif v.name == "SD" then
            --声音
        elseif v.name == "WT" then
            --延迟
        else
            --错误的解析，还原文本
            if v.context then
                szText = szText .. UIHelper.EncodeComponentsString("<" .. v.context .. ">")
            end
        end
    end
    return szText
end

function UIHelper.EncodeComponentsString(string)
    return '"' .. string.gsub(string, "[\"\\\n\t]", tEscapeTable) .. '"'
end

function UIHelper.GetBuffTip(dwID, nLevel)
    local szTip = "<Text>text=" .. UIHelper.GBKToUTF8(UIHelper.EncodeComponentsString(Table_GetBuffName(dwID, nLevel))) .. " font=65 </text>"

    local aInfo = {}
    local bufferInfo = GetBuffInfo(dwID, nLevel, aInfo)

    local szDetachType = ""
    if g_tStrings.tBuffDetachType[bufferInfo.nDetachType] then
        szDetachType = g_tStrings.tBuffDetachType[bufferInfo.nDetachType]
    end
    szTip = szTip .. "<Text>text=" .. UIHelper.EncodeComponentsString(szDetachType .. "\n") .. " font=106 </text>"

    local szDesc = GetBuffDesc(dwID, nLevel, "desc")
    if szDesc and Table_IsBuffDescAddPeriod(dwID, nLevel) then
        szDesc = UIHelper.GBKToUTF8(szDesc) .. g_tStrings.STR_FULL_STOP
    end
    szTip = szTip .. "<Text>text=" .. UIHelper.EncodeComponentsString(szDesc) .. " font=106 </text>"

    if bShowTime then
        local szTime = ""
        if nTime > 0 then
            local szLeftH = ""
            local szLeftM = ""
            local szLeftS = ""

            local h = math.floor(nTime / 3600)
            if h > 0 then
                szLeftH = h .. g_tStrings.STR_BUFF_H_TIME_H .. " "
            end

            local m = math.floor((nTime - h * 3600) / 60)
            if h > 0 or m > 0 then
                szLeftM = m .. g_tStrings.STR_BUFF_H_TIME_M_SHORT .. " "
            end

            local s = math.floor((nTime - h * 3600 - m * 60))
            if h > 0 or m > 0 or s > 0 then
                szLeftS = s .. g_tStrings.STR_BUFF_H_TIME_S
                szTime = FormatString(g_tStrings.STR_BUFF_H_LEFT_TIME_MSG, szLeftH, szLeftM, szLeftS)
            else
                szTime = g_tStrings.STR_BUFF_H_TIME_ZERO
            end
        else
            szTime = g_tStrings.STR_BUFF_H_TIME_ZERO
        end
        szTip = szTip .. "<Text>text=" .. UIHelper.EncodeComponentsString("\n" .. szTime) .. " font=102 </text>"
    end
    return szTip
end

---返回字符串对应的MD5
---@param szText string 要处理的字符串
function UIHelper.MD5(szText)
    return MD5(szText)
end

function UIHelper.RemoteCallToServer(szFunction, ...)
    return RemoteCallToServer(szFunction, ...)
end

function UIHelper.NumberToChinese(num, bTradional)
    local cnNumbers_TC = { "零", "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖" }
    local cnUnits_TC = { "", "拾", "佰", "仟", "萬", "億" }
    local cnNumbers = { "零", "一", "二", "三", "四", "五", "六", "七", "八", "九" }
    local cnUnits = { "", "十", "百", "千", "万", "亿" }
    if bTradional then
        cnNumbers = cnNumbers_TC
        cnUnits = cnUnits_TC
    end

    local cnStr = ""
    local index = 1
    local len = string.len(num)
    local unitLen = table.get_len(cnUnits)
    local unitIndex = 1
    repeat
        local remainder = num % 10
        if remainder ~= 0 then
            cnStr = cnNumbers[remainder + 1] .. cnUnits[unitIndex] .. cnStr
        else
            if unitIndex == unitLen then
                cnStr = cnUnits[unitIndex] .. cnStr
            elseif cnStr:sub(1, 3) ~= "零" and index ~= 1 then
                cnStr = "零" .. cnStr
            end
        end
        index = index + 1
        num = math.floor(num / 10)
        unitIndex = unitIndex + 1
    until num == 0
    -- 去除最后一个为零的显示
    cnStr = cnStr:gsub("零+$", "")
    if cnStr == "一十" then
        cnStr = "十"
    end
    return cnStr
end

-- 获取称号信息
function UIHelper.GetDesignationInfoByTitleID(dwTitleID, dwForceID)
    local tLine = g_tTable.Designation_Title:Search(dwTitleID)
    if not tLine then
        return
    end

    local nID = tLine.dwDesignationID
    local bPrefix = tLine.nType == 1

    local tbDesignation = nil
    if bPrefix then
        tbDesignation = Table_GetDesignationPrefixByID(nID, dwForceID)
    else
        tbDesignation = g_tTable.Designation_Postfix:Search(nID)
    end

    if not tbDesignation then
        return
    end

    tbDesignation.tbColor = ItemQualityColorC4b[tbDesignation.nQuality + 1]
    tbDesignation.bPrefix = bPrefix

    return tbDesignation
end

-- 显示全屏特效
function UIHelper.ShowFullScreenSFX(szSfxName)
    -- local szPath = Table_GetPath(szSfxName)
    -- if not szPath then
    --     -- LOG.ERROR("UIHelper.ShowFullScreenSFX szPath not exist, szSfxName = ", szSfxName)
    --     -- return
    -- end

    -- local tbSfxInfo = {
    --     Name = szName,
    --     File = szPath,
    --     Translation = {x=0, y=100}, -- screen center offset
    --     Scaling = 1.0
    -- }

    if UIMgr.GetView(VIEW_ID.PanelFullScreenSfx) then
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelFullScreenSfx)
        scriptView:OnEnter(szSfxName)
    else
        UIMgr.Open(VIEW_ID.PanelFullScreenSfx, szSfxName)
    end
end

-- 隐藏全屏特效
function UIHelper.HideFullScreenSFX()
    UIMgr.Close(VIEW_ID.PanelFullScreenSfx)
end

-- 需要屏蔽主界面动画的界面白名单 当有这些界面存在时，不播放主界面显示和隐藏动画
local PlayMainCityAnimIgnoreViewID = {
    VIEW_ID.PanelConstructionMain,
}

-- 播放主界面显示动画 [nType 1 所有，2 左边，3 右边，4 底部，5 中间]
function UIHelper.PlayMainCityAnimShow(nType, callback)
    local bHadIgnoreView = false
    for _, nViewID in ipairs(PlayMainCityAnimIgnoreViewID) do
        if UIMgr.GetViewScript(nViewID) then
            bHadIgnoreView = true
        end
    end
    if bHadIgnoreView then
        if IsFunction(callback) then
            callback()
        end
        return
    end

    local scriptMC = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    if not scriptMC then
        if IsFunction(callback) then
            callback()
        end
        return
    end

    UIHelper.DispatchMainCityAnimByType(true, nType, callback)
end

-- 播放主界面隐藏动画 [nType 1 所有，2 左边，3 右边，4 底部，5 中间, 6 其他部分（左上角，做下角自定义）]
function UIHelper.PlayMainCityAnimHide(nType, callback)
    local bHadIgnoreView = false
    for _, nViewID in ipairs(PlayMainCityAnimIgnoreViewID) do
        if UIMgr.GetViewScript(nViewID) then
            bHadIgnoreView = true
        end
    end
    if bHadIgnoreView then
        if IsFunction(callback) then
            callback()
        end
        return
    end

    local scriptMC = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    if not scriptMC then
        if IsFunction(callback) then
            callback()
        end
        return
    end

    UIHelper.DispatchMainCityAnimByType(false, nType, callback)
end

function UIHelper.DispatchMainCityAnimByType(bShow, nType, callback)
    local szEvent = nil

    if nType == MainCityAnimType.All then
        szEvent = bShow and EventType.PlayAnimMainCityShow or EventType.PlayAnimMainCityHide
    elseif nType == MainCityAnimType.Left then
        szEvent = bShow and EventType.PlayAnimMainCityLeftShow or EventType.PlayAnimMainCityLeftHide
    elseif nType == MainCityAnimType.Right then
        szEvent = bShow and EventType.PlayAnimMainCityRightShow or EventType.PlayAnimMainCityRightHide
    elseif nType == MainCityAnimType.Bottom then
        szEvent = bShow and EventType.PlayAnimMainCityBottomShow or EventType.PlayAnimMainCityBottomHide
    elseif nType == MainCityAnimType.Middle then
        szEvent = bShow and EventType.PlayAnimMainCityMiddleShow or EventType.PlayAnimMainCityMiddleHide
    elseif nType == MainCityAnimType.Other then
        szEvent = bShow and EventType.PlayAnimMainCityOtherShow or EventType.PlayAnimMainCityOtherHide
    end

    if not string.is_nil(szEvent) then
        Event.Dispatch(szEvent, callback)
    end
end

-- 播放动画显示界面里的 Bottom Bar
function UIHelper.ShowPageBottomBar(callback, bIsRightSidePage)
    Event.Dispatch(EventType.OnShowPageBottomBar, callback, bIsRightSidePage)
end

-- 播放动画隐藏界面里的 Bottom Bar
function UIHelper.HidePageBottomBar(callback, bIsRightSidePage)
    Event.Dispatch(EventType.OnHidePageBottomBar, callback, bIsRightSidePage)
end

function UIHelper.CaptureNode(node, callback, nScale)
    if not safe_check(node) then
        return
    end

    -- 这里做个排队机制，因为底层不支持很短时间内多次截屏，然后目前这个接口只有UIMgr里用到
    if UIHelper.bIsCaptureNodeing then
        if not UIHelper.tbCaptureNodeList then UIHelper.tbCaptureNodeList = {} end
        table.insert(UIHelper.tbCaptureNodeList, {node = node, callback = callback, nScale = nScale})
        return
    end

    UIHelper.bIsCaptureNodeing = true
    cc.utils:captureNode(node, function(pRetTexture)
        if safe_check(pRetTexture) then
            pRetTexture:retain()
        end

        Event.Dispatch(EventType.OnCaptureNodeFinished, pRetTexture)

        Timer.DelTimer(UIHelper, UIHelper.nCaptureNodeTimerID)
        UIHelper.nCaptureNodeTimerID = Timer.AddFrame(UIHelper, 2, function()
            if safe_check(pRetTexture) then
                pRetTexture:release()
            end
        end)

        if IsFunction(callback) then
            callback(pRetTexture)
        end

        UIHelper.bIsCaptureNodeing = false

        -- pendding next
        if UIHelper.tbCaptureNodeList and #UIHelper.tbCaptureNodeList > 0 then
            local one = table.remove(UIHelper.tbCaptureNodeList, 1)
            if one then
                UIHelper.CaptureNode(one.node, one.callback, one.nScale)
            end
        end

    end, nScale or Const.UIBgBlur.nScale)
end

function UIHelper.CaptureScreen(callback, nScale, bSaveImage)
    --local captureScreen = cc.utils.captureScreen --cc.utils.captureScreen2Texture or cc.utils.captureScreen
    cc.utils:captureScreen(function(nCaptureRet, szScreenPath, pRetTexture, pImage)
        if safe_check(pRetTexture) then
            pRetTexture:retain()
        end
        if bSaveImage then
            if safe_check(pImage) then
                pImage:retain()
            end
        end

        if nCaptureRet == CaptureScreenResult.Finish then
            Event.Dispatch(EventType.OnCaptureScreenFinished, pRetTexture)
        elseif nCaptureRet == CaptureScreenResult.Failed then
            Event.Dispatch(EventType.OnCaptureScreenFailed)
        end
        if IsFunction(callback) then
            callback(pRetTexture, pImage)
        end

        Timer.DelTimer(UIHelper, UIHelper.nCaptureScreenTimerID)
        UIHelper.nCaptureScreenTimerID = Timer.AddFrame(UIHelper, 2, function()
            if safe_check(pRetTexture) then
                pRetTexture:release()
            end
        end)


    end, "", nScale or Const.UIBgBlur.nScale)
end

function UIHelper.CaptureScreenMainPlayer(callback, nScale, bSaveImage)
    cc.utils:captureScreenMainPlayer(function(nCaptureRet, szScreenPath, pRetTexture, pImage)
        if safe_check(pRetTexture) then
            pRetTexture:retain()
        end
        if bSaveImage then
            if safe_check(pImage) then
                pImage:retain()
            end
        end

        if nCaptureRet == CaptureScreenResult.Finish then
            Event.Dispatch(EventType.OnCaptureScreenFinished, pRetTexture)
        elseif nCaptureRet == CaptureScreenResult.Failed then
            Event.Dispatch(EventType.OnCaptureScreenFailed)
        end
        if IsFunction(callback) then
            callback(pRetTexture, pImage)
        end

        Timer.DelTimer(UIHelper, UIHelper.nCaptureScreenTimerID)
        UIHelper.nCaptureScreenTimerID = Timer.AddFrame(UIHelper, 2, function()
            if safe_check(pRetTexture) then
                pRetTexture:release()
            end
        end)


    end, "", nScale or Const.UIBgBlur.nScale)
end

function UIHelper.GetImageFromPngData(callback, pData, nDataLen, bSaveImage)
    cc.utils:getImageFromPngData(function(nCaptureRet, szScreenPath, pRetTexture, pImage)
        if safe_check(pRetTexture) then
            pRetTexture:retain()
        end

        if bSaveImage then
            if safe_check(pImage) then
                pImage:retain()
            end
        end

        if nCaptureRet == CaptureScreenResult.Finish then
            Event.Dispatch(EventType.OnCaptureScreenFinished, pRetTexture)
        elseif nCaptureRet == CaptureScreenResult.Failed then
            Event.Dispatch(EventType.OnCaptureScreenFailed)
        end
        if IsFunction(callback) then
            callback(pRetTexture, pImage)
        end

        Timer.DelTimer(UIHelper, UIHelper.nCaptureScreenTimerID)
        UIHelper.nCaptureScreenTimerID = Timer.AddFrame(UIHelper, 2, function()
            if safe_check(pRetTexture) then
                pRetTexture:release()
            end
        end)
    end, pData, nDataLen)
end

function UIHelper.GetPngDataFromImage(callback, pSrcImage)
    cc.utils:getPngDataFromImage(function(pData, nDataLen)
        if IsFunction(callback) then
            callback(pData, nDataLen)
        end
    end, pSrcImage)
end

-- 需要注意压缩失败时pData会直接返回pSrcImage，记得退出时要先判safe_check再释放
function UIHelper.CompressImage(callback, pSrcImage, nTargetWidth, nTargetHeight)
    cc.utils:compressImage(function(pData)
        if IsFunction(callback) then
            callback(pData)
        end
    end, pSrcImage, nTargetWidth, nTargetHeight)
end

function UIHelper.CropImage(callback, pSrcImage, nLeft, nRight, nTop, nBottom, bSaveImage)
    cc.utils:cropImage(function(nCaptureRet, szScreenPath, pRetTexture, pImage)
        if safe_check(pRetTexture) then
            pRetTexture:retain()
        end

        if bSaveImage then
            if safe_check(pImage) then
                pImage:retain()
            end
        end

        if nCaptureRet == CaptureScreenResult.Finish then
            Event.Dispatch(EventType.OnCaptureScreenFinished, pRetTexture)
        elseif nCaptureRet == CaptureScreenResult.Failed then
            Event.Dispatch(EventType.OnCaptureScreenFailed)
        end
        if IsFunction(callback) then
            callback(pRetTexture, pImage)
        end

        Timer.DelTimer(UIHelper, UIHelper.nCaptureScreenTimerID)
        UIHelper.nCaptureScreenTimerID = Timer.AddFrame(UIHelper, 2, function()
            if safe_check(pRetTexture) then
                pRetTexture:release()
            end
        end)
    end, "", pSrcImage, nLeft, nRight, nTop, nBottom)
end

function UIHelper.SaveImageToLocalFile(fileName, pImage, callback, nTargetWidth, nTargetHeight)
    if not safe_check(pImage) then
        if callback then
            callback(CaptureScreenResult.Failed)
        end
        return
    end
    cc.utils:saveImageToLocalFile(fileName, pImage, function(nCaptureRet)
        if callback then
            callback(nCaptureRet)
        end
    end, nTargetWidth, nTargetHeight)
end

function UIHelper.SaveImageToLocalFile_RGB(fileName, pImage, callback)
    Timer.AddFrame(UIHelper , 3 , function ()
        local ccFileUtils = cc.FileUtils:getInstance()
        if safe_check(pImage) then
            local outputFile = ""
            if ccFileUtils:isAbsolutePath(fileName) then
                outputFile = fileName
            else
                outputFile = ccFileUtils:getWritablePath()..fileName
            end

            local bSuccess = pImage:saveToFile(outputFile, true)
            Timer.AddFrame(UIHelper , 3 , function ()
                if callback then
                    callback(bSuccess and CaptureScreenResult.SaveFinish or CaptureScreenResult.Failed )
                end
            end)
        end
    end)
end

function UIHelper.SaveImageToPhoto(fileName, callback)
    cc.utils:saveImageToPhoto(fileName, function(nCaptureRet)
        if nCaptureRet == 100 then
            LOG.ERROR("[KMUI] Save texture to photo fail 100 , we need premisson")
        elseif nCaptureRet == 101 then
            LOG.ERROR("[KMUI] Save texture to photo fail 101")
        elseif nCaptureRet == 102 then
            LOG.ERROR("[KMUI] Save texture to photo fail 102")
        else
            if callback then
                callback(nCaptureRet)
            end
        end
    end)
end


function UIHelper.SaveVideoToPhoto(fileName, callback)
    cc.utils:saveVideoToPhoto(fileName, function(nCaptureRet)
        if callback then
            callback(nCaptureRet)
        end
    end)
end

function UIHelper.CaptureScreenToFile(szFilePath, nScale, callback)
    szFilePath = szFilePath or "screen.png"
    nScale = nScale or 1

    cc.utils:sreenSaveToLocalFile(function(nCaptureRet, szScreenPath, pRetTexture)
        if nCaptureRet == CaptureScreenResult.SaveFinish then
            Event.Dispatch(EventType.OnCaptureScreenSaveFinished, pRetTexture)
        elseif nCaptureRet == CaptureScreenResult.Failed then
            Event.Dispatch(EventType.OnCaptureScreenFailed)
        end

        if IsFunction(callback) then
            callback(szFilePath, pRetTexture)
        end

    end, szFilePath, nScale)
end

function UIHelper.FixDXUIImagePath(szPath)
    szPath = string.gsub(szPath, "ui/Image", "Resource")
    szPath = string.gsub(szPath, ".tga", ".png")

    return szPath
end

---comment 获取屏幕的像素点密度
---@return integer
function UIHelper.GetDpi()
    return kDpi
end

-- 获取设备的真实分辨率
function UIHelper.DeviceScreenSize()
    return GetDeviceScreenSize() --size.width, size.height
end

--[[
    引擎画布的大小
    PC上和设备分辨率是1:1
    手机上是640P，但保持和设备屏幕分辨率相同比例，既高度为640，宽度按比例缩减
]]
function UIHelper.GetScreenSize()
    if not UIHelper.tbScreenSize then
        UIHelper.tbScreenSize = GetScreenSize()
        Event.Reg(UIHelper, EventType.OnWindowsSizeChanged, function(nWidth, nHeight)
            UIHelper.tbScreenSize.width = nWidth
            UIHelper.tbScreenSize.height = nHeight
            UIHelper.tbScreenToResolutionScale = nil
            UIHelper.tbScreenToDesignScale = nil
        end)
    end

    return UIHelper.tbScreenSize --size.width, size.height
end

-- 获取 GetScreenSize 和 GetCurResolutionSize 宽高各自的比例
function UIHelper.GetScreenToResolutionScale()
    if not UIHelper.tbScreenToResolutionScale then
        UIHelper.tbScreenToResolutionScale = {}
        local sizeResolution = UIHelper.GetCurResolutionSize()
        local sizeScreen = UIHelper.GetScreenSize()
        local nScaleX = (sizeScreen.width / sizeResolution.width)
        local nScaleY = (sizeScreen.height / sizeResolution.height)

        UIHelper.tbScreenToResolutionScale.x = nScaleX
        UIHelper.tbScreenToResolutionScale.y = nScaleY
    end

    return UIHelper.tbScreenToResolutionScale.x, UIHelper.tbScreenToResolutionScale.y
end

-- 获取 GetScreenSize 和 GetDesignResolutionSize 宽高各自的比例
function UIHelper.GetScreenToDesignScale()
    if not UIHelper.tbScreenToDesignScale then
        UIHelper.tbScreenToDesignScale = {}
        local sizeDesign = UIHelper.GetDesignResolutionSize()
        local sizeScreen = UIHelper.GetScreenSize()
        local nScaleX = (sizeScreen.width / sizeDesign.width)
        local nScaleY = (sizeScreen.height / sizeDesign.height)

        UIHelper.tbScreenToDesignScale.x = nScaleX
        UIHelper.tbScreenToDesignScale.y = nScaleY
    end

    return UIHelper.tbScreenToDesignScale.x, UIHelper.tbScreenToDesignScale.y
end

-- 获取 GetScreenSize 和 DeviceScreenSize 宽高各自的比例
function UIHelper.GetScreenToDeviceScale()
    if not UIHelper.tbScreenToDeviceScale then
        UIHelper.tbScreenToDeviceScale = {}
        local sizeDeviceScreen = UIHelper.DeviceScreenSize()
        local sizeScreen = UIHelper.GetScreenSize()
        local nScaleX = (sizeScreen.width / sizeDeviceScreen.width)
        local nScaleY = (sizeScreen.height / sizeDeviceScreen.height)

        UIHelper.tbScreenToDeviceScale.x = nScaleX
        UIHelper.tbScreenToDeviceScale.y = nScaleY
    end

    return UIHelper.tbScreenToDeviceScale.x, UIHelper.tbScreenToDeviceScale.y
end

-- 设计分辨率 固定位：1600 X 900
function UIHelper.GetDesignResolutionSize()
    return GetDesignResolutionSize() --size.width, size.height
end

--[[
    根据设计分辨率和ScreenSize计算出来的大小
    目前游戏是按照ResolutionPolicy::FIXED_HEIGHT_OR_WIDTH来做适配
    就是宽和搞哪个比例大就按哪个来，计算规则如下：
    local nScaleX = ScreenSize().width / DesignResolutionSize().height
    local nScaleY = ScreenSize().height / DesignResolutionSize().height
    if nScaleX > nScaleY then
        nScaleX = nScaleY;
        DesignResolutionSize().width = ceilf(ScreenSize().width / nScaleX);
    else
        nScaleY = nScaleX;
        DesignResolutionSize().height = ceilf(ScreenSize().height / _scaleY);
    end
]]
function UIHelper.GetCurResolutionSize()
    return GetCurResolutionSize() --size.width, size.height
end

-- 返回和GetCurResolutionSize一样
function UIHelper.GetWinSize()
    return cc.Director:getInstance():getWinSize() --size.width, size.height
end

--[[
    获得窗口大小，计算过缩放因子后的大小
    return Size(_winSizeInPoints.width * _contentScaleFactor, _winSizeInPoints.height * _contentScaleFactor);

    但由于目前，我们游戏的_contentScaleFactor始终为1
    因此，这个吃粉，其实和GetCurResolutionSize返回的大小是一样的
]]
function UIHelper.GetWinSizeInPixels()
    return cc.Director:getInstance():getWinSizeInPixels() --size.width, size.height
end

--[[
    获得安全区矩形
    宽高和GetCurResolutionSize一样
]]
function UIHelper.GetSafeAreaRect()
    return cc.Director:getInstance():getSafeAreaRect() --retc.x, retc.y, retc.width, retc.height
end

function UIHelper.ShowTouchMask(nAutoHideDelay)
    Event.Dispatch(EventType.OnTouchMaskShow, nAutoHideDelay)
end

function UIHelper.HideTouchMask()
    Event.Dispatch(EventType.OnTouchMaskHide)
end

function UIHelper.BlackMaskEnter(nViewID, callback)
    if not UIMgr.GetView(VIEW_ID.PanelTouchMask) then
        Lib.SafeCall(callback)
        return
    end

    Event.Dispatch(EventType.OnBlackMaskEnter, nViewID, callback)
end

function UIHelper.BlackMaskExit(nViewID, callback)
    if not UIMgr.GetView(VIEW_ID.PanelTouchMask) then
        Lib.SafeCall(callback)
        return
    end

    Event.Dispatch(EventType.OnBlackMaskExit, nViewID, callback)
end

function UIHelper.ShowTouchMaskWithTips(szTips, nAutoHideDelay)
    Event.Dispatch(EventType.OnTouchMaskWithTipsShow, szTips, nAutoHideDelay)
end

function UIHelper.HideTouchMaskWithTips()
    Event.Dispatch(EventType.OnTouchMaskWithTipsHide)
end

function UIHelper.ShowInteract()
    Event.Dispatch(EventType.OnInteractChangeVisible, true)
end

function UIHelper.HideInteract()
    Event.Dispatch(EventType.OnInteractChangeVisible, false)
end

function UIHelper.EnterHideAllUIMode()
    if UIHelper.bIsEnterHideAllUIMode then
        return
    end

    -- 如果场景不可见了，就不处理，不然全黑了
    if not UIMgr.IsLayerVisible(UILayer.Scene) then
        return
    end

    UIMgr.HideAllLayer()

    local bMoved = false
    local nBeganX, nBeganY = nil, nil

    Event.Reg(UIHelper, EventType.OnSceneTouchBegan, function(nX, nY)
        if SceneMgr.GetTouchingCount() <= 1 then
            bMoved = false
            nBeganX, nBeganY = nX, nY
        else
            bMoved = true -- 只要多指触摸了，就不能退出
        end
    end)

    Event.Reg(UIHelper, EventType.OnSceneTouchMoved, function(nX, nY)
        if kmath.len2(nBeganX, nBeganY, nX, nY) > 3 then
            bMoved = true
        end
    end)

    Event.Reg(UIHelper, EventType.OnSceneTouchEnded, function()
        if not bMoved then
            UIHelper.ExitHideAllUIMode()
        end
    end)

    UIHelper.bIsEnterHideAllUIMode = true
end

function UIHelper.ExitHideAllUIMode()
    if not UIHelper.bIsEnterHideAllUIMode then
        return
    end

    UIMgr.ShowAllLayer()

    Event.UnReg(UIHelper, EventType.OnSceneTouchBegan)
    Event.UnReg(UIHelper, EventType.OnSceneTouchMoved)
    Event.UnReg(UIHelper, EventType.OnSceneTouchEnded)

    UIHelper.bIsEnterHideAllUIMode = false
end

function UIHelper.TruncateString(szText, nMaxShowLength, szTruncation, nTruncationKeepLength)
    local bTruncated = false
    local szResult = szText

    if UIHelper.GetUtf8Len(szText) > nMaxShowLength then
        bTruncated = true
        if not szTruncation then
            szTruncation = "…"
        end
        if not nTruncationKeepLength then
            nTruncationKeepLength = nMaxShowLength
        end

        szResult = UIHelper.GetUtf8SubString(szText, 1, nTruncationKeepLength) .. szTruncation
    end

    return bTruncated, szResult
end

function UIHelper.TruncateStringReturnOnlyResult(szText, nMaxShowLength, szTruncation, nTruncationKeepLength)
    local _, szResult = UIHelper.TruncateString(szText, nMaxShowLength, szTruncation, nTruncationKeepLength)

    return szResult
end

-- 节点数量统计
function UIHelper.GetNodeCount(node)
    if not safe_check(node) then
        return 0, 0
    end

    local nCount = 0
    local nProtCount = 0

    local nOneNodeCount = UIHelper.GetChildrenCount(node)
    nCount = nCount + nOneNodeCount

    local tbProtChildren = UIHelper.GetProtectedChildren(node) or {}
    nProtCount = nProtCount + #tbProtChildren

    local tbChildren = UIHelper.GetChildren(node)
    for k, v in ipairs(tbChildren or {}) do
        local _nCount, _nProtCount = UIHelper.GetNodeCount(v)
        nCount = nCount + _nCount
        nProtCount = nProtCount + _nProtCount
    end

    for k, v in ipairs(tbProtChildren or {}) do
        local _nCount, _nProtCount = UIHelper.GetNodeCount(v)
        --nCount = nCount + _nCount
        nProtCount = nProtCount + _nProtCount
    end

    return nCount, nProtCount
end

-- 将data\目录转换成data_mb\目录
function UIHelper.ConvertToMBPath(szPath)
    if not szPath then
        return
    end

    -- 先替换 data 目录
    local nStart, nEnd = string.find(szPath, "data\\")
    if nStart == 1 and nEnd == 5 then
        szPath = string.gsub(szPath, "data", "data_mb", 1)

        -- 再替换后缀名
        -- local nLen = string.len(szPath)
        -- local szExt = string.sub(szPath, nLen - 3, nLen)
        -- if szExt == ".png" or szExt == ".dds" then
        --     szPath = string.sub(szPath, 1, nLen - 4) .. ".ktx"
        -- end
    end

    return szPath
end

-- UIBtnCtrlTab 检查
function UIHelper.CheckBtnCtrl(nID)
    local bResult = true
    local tbInfo = UIBtnCtrlTab[nID]
    if tbInfo then
        for k, v in ipairs(tbInfo.tbCheckFunc) do
            if not string.is_nil(v) and not string.execute(v) then
                bResult = false
                break
            end
        end
    end
    return bResult
end

-- UIBtnCtrlTab 执行
function UIHelper.DoBtnCtrl(nID)
    local tbInfo = UIBtnCtrlTab[nID]
    if tbInfo then
        for k, v in ipairs(tbInfo.tbActionFunc) do
            local szCheck = tbInfo.tbCheckFunc[k]
            if string.is_nil(szCheck) or string.execute(szCheck) then
                string.execute(v)
            end
        end
    end
end

-- 数字以 **万、**亿显示
---@param szContent string 显示内容
---@param nDecimal number 小数点的位数
function UIHelper.NumberToTenThousand(szContent, nDecimal)
    local numVal = tonumber(szContent)
    local strVal = tostring(szContent)
    local szResult = strVal
    if numVal then
        if not IsNumber(nDecimal) or nDecimal < 0 then
            nDecimal = 0
        end
        nDecimal = math.floor(nDecimal)

        local nFloor = math.floor(numVal)
        local len = string.len(nFloor)
        if len > 8 then
            local szTemp = string.sub(strVal, 1, len - 8 + nDecimal)
            if nDecimal > 0 then
                local nTempLen = string.len(szTemp)
                szTemp = string.sub(szTemp, 1, nTempLen - nDecimal) .. "." .. string.sub(szTemp, nTempLen - nDecimal + 1, nTempLen)
            end
            szResult = szTemp .. "亿"
        elseif len > 4 then
            local szTemp = string.sub(strVal, 1, len - 4 + nDecimal)
            if nDecimal > 0 then
                local nTempLen = string.len(szTemp)
                szTemp = string.sub(szTemp, 1, nTempLen - nDecimal) .. "." .. string.sub(szTemp, nTempLen - nDecimal + 1, nTempLen)
            end
            szResult = szTemp .. "万"
        else
            return string.format("%.0f", numVal)
        end
    end

    return szResult
end

function UIHelper.SetProgressBarTexture(node, textureFilePath, nType)
    if not safe_check(node) then
        return
    end
    if not textureFilePath then
        return
    end

    UIHelper.PreloadSpriteFrame(textureFilePath)

    local w, h = UIHelper.GetContentSize(node)
    node:loadTexture(textureFilePath, nType)
    UIHelper.SetContentSize(node, w, h)
end

--- 在打开新界面前，先临时隐藏当前界面中的MiniScene，否则新的界面里的MiniScene可能无法正常显示，而且有概率宕机
--- 案例：侠客 UIPartnerFetter 打开选择侠客界面 UIPartnerTeamView时，不提前隐藏MiniScene，此时再点击右下角的查看详情，会发现无法正常显示侠客模型
function UIHelper.TempHideMiniSceneUntilNewViewClose(self, MiniScene, tOldModelView, nNewOpenViewID, fnCallback)
    UIHelper.SetVisible(MiniScene, false)
    if tOldModelView then
        tOldModelView:ShowModel(false)
    end

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == nNewOpenViewID then
            Event.UnReg(self, EventType.OnViewClose)

            if tOldModelView then
                tOldModelView:ShowModel(true)
            end
            if fnCallback and IsFunction(fnCallback) then
                fnCallback()
            end

            UIHelper.SetVisible(MiniScene, true)
        end
    end)
end

--- 当某些界面打开时，暂时隐藏 self 所对应的界面，等其关闭后再恢复显示
function UIHelper.TempHideCurrentViewOnSomeViewOpen(self, tTargetViewIdList)
    Event.Reg(self, EventType.OnViewOpen, function(nOpenViewID)
        if table.contain_value(tTargetViewIdList, nOpenViewID) then
            UIMgr.HideView(self._nViewID)

            Event.Reg(self, EventType.OnViewClose, function(nCloseViewID)
                if nCloseViewID == nOpenViewID then
                    UIMgr.ShowView(self._nViewID)
                end
            end)
        end
    end)
end

function UIHelper.TouchIsRightMouse(touch)
    if not safe_check(touch) then
        return
    end

    local bResult = false
    if touch.getMouseButton then
        bResult = touch:getMouseButton() == cc.MouseButton.BUTTON_RIGHT
    end

    return bResult
end

function UIHelper.FadeNode(tbNodes, nOpacity, nTime, funcCallback)
    if not IsTable(tbNodes) then
        tbNodes = { tbNodes }
    end

    for index, node in ipairs(tbNodes) do
        if safe_check(node) then
            local fadeto = cc.FadeTo:create(nTime, nOpacity)
            local callback = cc.CallFunc:create(function()
                if funcCallback and index == #tbNodes then
                    funcCallback()
                end
            end)
            local sequence = cc.Sequence:create(fadeto, callback)
            node:runAction(sequence)
        end
    end
end

function UIHelper.GetIconPathByIconID(nItemIconID, bWithoutSuffix)
    local szIconPath = ""

    if IsNumber(nItemIconID) and nItemIconID > 0 then
        local tbIconCfg = Table_GetItemIconInfo(nItemIconID)
        if tbIconCfg then
            if tbIconCfg then
                szIconPath = string.format("Resource/icon/%s", tostring(tbIconCfg.FileName))
                if bWithoutSuffix then
                    szIconPath = string.gsub(szIconPath, ".png", "")
                end
            end
        end
    end

    return szIconPath
end

function UIHelper.GetIconPathByItemInfo(itemInfo, bWithoutSuffix, bBigSize)
    local szIconPath = ""

    if itemInfo then
        local nItemIconID = Table_GetItemIconID(itemInfo.nUiId, bBigSize)
        szIconPath = UIHelper.GetIconPathByIconID(nItemIconID, bWithoutSuffix)
    end

    return szIconPath
end

function UIHelper.SetItemIconByIconID(imgIcon, nItemIconID, bAsync, funLoadedCallback)
    local bResult = false

    if safe_check(imgIcon) then
        local szPath = UIHelper.GetIconPathByIconID(nItemIconID)
        if not string.is_nil(szPath) then
            UIHelper.SetTexture(imgIcon, szPath, bAsync, funLoadedCallback)
            bResult = true
        end
    end

    return bResult
end

function UIHelper.SetItemIconByItemInfo(imgIcon, itemInfo, bBigSize, bAsync, funLoadedCallback)
    local bResult = false

    if safe_check(imgIcon) and itemInfo then
        local szPath = UIHelper.GetIconPathByItemInfo(itemInfo, false, bBigSize)
        if not string.is_nil(szPath) then
            UIHelper.SetTexture(imgIcon, szPath, bAsync, funLoadedCallback)
            bResult = true
        end
    end

    return bResult
end

function UIHelper.SetItemIconByItemUuid(imgIcon, nItemUiId, bBigSize, bAsync)
    local bResult = false

    if safe_check(imgIcon) then
        local nItemIconID = Table_GetItemIconID(nItemUiId, bBigSize)
        local szPath = UIHelper.GetIconPathByIconID(nItemIconID)
        if not string.is_nil(szPath) then
            UIHelper.SetTexture(imgIcon, szPath, bAsync)
            bResult = true
        end
    end

    return bResult
end

function UIHelper.GetScreenPortrait()
    return GetScreenPortrait()
end

function UIHelper.SetScreenPortrait(bIsPortrait)
    SetScreenPortrait(bIsPortrait)
    Event.Dispatch(EventType.OnSetScreenPortrait, bIsPortrait)
end

function UIHelper.ShowMiniKeyboard(editbox, nMin, nMax)
    if not safe_check(editbox) then
        return
    end

    if not TipsHelper.IsHoverTipsExist(PREFAB_ID.WidgetMiniKeyboard) then
        local tSize = UIHelper.GetDesignResolutionSize()
        local nX, nY = UIHelper.GetWorldPosition(editbox)
        local nDir = TipsLayoutDir.BOTTOM_CENTER
        if nY < tSize.height / 2 then
            nDir = TipsLayoutDir.TOP_CENTER
        end

        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetMiniKeyboard, editbox, nDir, editbox, nMin, nMax)
        -- local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelHoverTips)
        -- local scriptBG = scriptView._scriptBG
        -- scriptBG:SetTouchDownHideTips(PREFAB_ID.WidgetMiniKeyboard)--防止在背包的itemtip输入数字时，点击空白会连tip一起关闭掉
    end
end

function UIHelper.TempHidePlayerMiniSceneUntilNewViewClose(tbScript, MiniScene, tOldModelView, nNewOpenViewID, fnCallback)
    UIHelper.SetVisible(MiniScene, false)
    if tOldModelView then
        tOldModelView:HideMDL(tOldModelView)
    end

    Event.Reg(tbScript, EventType.OnViewClose, function(nViewID)
        if nViewID == nNewOpenViewID then
            Event.UnReg(tbScript, EventType.OnViewClose)

            if tOldModelView then
                tOldModelView:ShowMDL(tOldModelView)
            end
            if fnCallback and IsFunction(fnCallback) then
                fnCallback()
            end

            UIHelper.SetVisible(MiniScene, true)
        end
    end)
end

function UIHelper.SetPressedActionEnabled(btn, bEnable)
    if not safe_check(btn) then
        return
    end
    btn:setPressedActionEnabled(bEnable)
end

function UIHelper.ScrollViewAddScrollEndCallback(scrollView, callback)
    if not safe_check(scrollView) then
        return
    end

    if not IsFunction(callback) then
        return
    end

    scrollView:addEventListener(function(_scrollView, nEventType)
        if nEventType == 12 then
            callback()
        end
    end)
end

function UIHelper.RemoveComponent(node, szName, bCascade)
    if not safe_check(node) then
        return
    end
    if szName == nil then
        return
    end
    if not bCascade then
        bCascade = false
    end

    if CascadeRemoveComponent then
        CascadeRemoveComponent(node, szName, bCascade)
    else
        node:removeComponent(szName)
    end
end

--- 将端游的富文本改写为bd版支持的富文本，尤其是将其中的link字段改写为bd版的href字段，方便实现点击跳转等功能
---
--- 输入格式
--- <text>text="在" font=162</text><text>text="韩荞生" font=67 link="NPCGuide/132"</text>
--- 输出格式
--- 在<href="NPCGuide/132">韩荞生</href>
function UIHelper.ConvertRichTextFormat(szText)
    szText                     = string.gsub(szText, "\\\n", "\n")  -- 策划要求兼容配置表中字符串"\\n"填成"\\\n"的情况

    -- 定义匹配模式
    local szTextPattern        = "<text>(.-)</text>"
    local szLinkPattern        = "link=\"(.-)\""
    local szTextContentPattern = "text=\"(.-)\""

    -- 提取富文本 text 标签内的所有内容
    local tTextParts           = {}
    for part in string.gmatch(szText, szTextPattern) do
        table.insert(tTextParts, part)
    end

    -- 转换为bd版本的富文本格式
    local tBDRichTextList = {}
    for _, szPart in ipairs(tTextParts) do
        local szLink      = string.match(szPart, szLinkPattern)
        local szTextValue = string.match(szPart, szTextContentPattern)

        if szLink then
            -- 如果包含链接，则转写为bd版支持的链接格式
            szLink               = Base64_Encode(szLink)
            local szTextWithLink = string.format("<href=%s><color=#F9B222>%s</color></href>", szLink, szTextValue)
            table.insert(tBDRichTextList, szTextWithLink)
        else
            -- 如果不包含link=，则直接提取文本内容
            table.insert(tBDRichTextList, szTextValue)
        end
    end

    -- 拼接最终的结果
    local szRichText = table.concat(tBDRichTextList)

    return szRichText
end

function UIHelper.EnableRightTouch(btn , bEnable)
    if not safe_check(btn) then
        return
    end
    if btn.enableRightTouch then
        btn:enableRightTouch(bEnable)
    end

end

-- 显示公告 计数+1, bForce强行不走计数
function UIHelper.ShowAnnouncement(bForce)
    if UIHelper.nAnnounceVisibleCount == nil then UIHelper.nAnnounceVisibleCount = 0 end
    if not bForce then
        UIHelper.nAnnounceVisibleCount = UIHelper.nAnnounceVisibleCount + 1
    end

    Event.Dispatch(EventType.AnnouncementShow, bForce, UIHelper.nAnnounceVisibleCount)
end

-- 隐藏公告 计数-1, bForce强行不走计数
function UIHelper.HideAnnouncement(bForce)
    if UIHelper.nAnnounceVisibleCount == nil then UIHelper.nAnnounceVisibleCount = 0 end
    if not bForce then
        UIHelper.nAnnounceVisibleCount = UIHelper.nAnnounceVisibleCount - 1
    end

    Event.Dispatch(EventType.AnnouncementHide, bForce, UIHelper.nAnnounceVisibleCount)
end

-- 清除公告计数
function UIHelper.ClearAnnouncement()
    UIHelper.nAnnounceVisibleCount = nil
end

function UIHelper.ExitPowerSaveMode()
    Event.Dispatch(EventType.DoExitPowerSaveMode)
end

function UIHelper.UpdateNodeInsideScreen(node, nNewX, nNewY)
    if not nNewX or not nNewY then
        nNewX, nNewY = UIHelper.GetWorldPosition(node)
    end

    local w, h = UIHelper.GetScaledContentSize(node)
    local nAnchorX, nAnchorY = UIHelper.GetAnchorPoint(node)
    local tScreenSize = UIHelper.GetCurResolutionSize()
    local nAreaWidth, nAreaHeight = tScreenSize.width, tScreenSize.height
    local nNewX1 = (nNewX + w * (1 - nAnchorX) > nAreaWidth and nAreaWidth - w * (1 - nAnchorX))
            or (nNewX < w * nAnchorX and w * nAnchorX) or nNewX

    local nNewY2 = (nNewY + h * (1 - nAnchorY) > nAreaHeight and nAreaHeight - h * (1 - nAnchorY))
            or (nNewY < h * nAnchorY and h * nAnchorY) or nNewY

    UIHelper.SetWorldPosition(node, nNewX1, nNewY2)
end


function UIHelper.SetLabel(node, szString)
    if node and node.setXMLData then
        if string.is_nil(szString) then
            szString = "<div></div>"
        end
        UIHelper.SetRichText(node, szString)
    else
        UIHelper.SetString(node, szString)
    end
end

function UIHelper.GetLabel(node)
    if node and node.getXMLData then
        return UIHelper.GetRichText(node)
    else
        return UIHelper.GetString(node)
    end
end

function UIHelper.BindFreeDrag(script, btnNode, nDragThreshold, callBack)
    local btn = btnNode
    local self = script
    local tbCustomNode = {"WidgetDbm", "BtnHurtStatistics", "TogTargetFocus", "WidgetActiongBar", "BtnWhoSeeMe", "BtnTeamNotice", "BtnRoomNotice" }
    nDragThreshold = nDragThreshold or 450

    UIHelper.BindUIEvent(btn, EventType.OnTouchBegan, function(btn, nX, nY)
        self.nWx, self.nWy = UIHelper.GetWorldPosition(self._rootNode)
        self.nTouchBeganX, self.nTouchBeganY = nX, nY
        self.bDragging = false
        return true
    end)

    UIHelper.BindUIEvent(btn, EventType.OnTouchMoved, function(btn, nX, nY)
        if not self.bDragging then
            local dx = nX - self.nTouchBeganX
            local dy = nY - self.nTouchBeganY
            local dx2 = dx * dx
            local dy2 = dy * dy
            if dx2 + dy2 > nDragThreshold then
                self.bDragging = true
                self.bMoved = true
            end
        end

        if self.bDragging then
            local ndx = nX - self.nTouchBeganX
            local ndy = nY - self.nTouchBeganY
            local nNewX = self.nWx + ndx
            local nNewY = self.nWy + ndy

            UIHelper.UpdateNodeInsideScreen(self._rootNode, nNewX, nNewY)
        end
    end)

    UIHelper.BindUIEvent(btn, EventType.OnTouchEnded, function(btn, nX, nY)
        if callBack then
            callBack()
        end

        local szNodeName = btn:getName()
        if not MainCityCustomData.bSubsidiaryCustomState and table.contain_value(tbCustomNode, szNodeName) then
            MainCityCustomData.SaveDraggableNodePosition()
		end

        if self.bDragging then
            self.bDragging = false
        end

    end)

    UIHelper.BindUIEvent(btn, EventType.OnTouchCanceled, function(btn, nX, nY)
        if self.bDragging then
            self.bDragging = false
        end
        local szNodeName = btn:getName()
        if not MainCityCustomData.bSubsidiaryCustomState and table.contain_value(tbCustomNode, szNodeName) then
            MainCityCustomData.SaveDraggableNodePosition()
		end
    end)
end


function UIHelper.GetCoolTimeText(nLeft)
    local function GetTimeText(nTime)
        if nTime < 10 then
            return '0' .. nTime
        else
            return nTime
        end
    end

	nLeft = nLeft or 0
	local szText
	local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nLeft, false)
	if nH > 0 then
		szText = GetTimeText(nH) ..':'
	else
		szText = "00:"
	end
	if nM  > 0 then
		szText = szText .. GetTimeText(nM) ..':'
	else
		szText = szText .. "00:"
	end
	if nS >= 0 then
		szText = szText .. GetTimeText(nS)
	else
		szText = szText .. "00:"
	end
	return szText
end

function UIHelper.GetLabelTimeColor(nLeftTime)

    local nFontColorID = TimeLib.GetTimeColor(nLeftTime)
    local tColorCfg = UIDialogueColorTab[nFontColorID]
    local szColor = tColorCfg and tColorCfg.Color
    if not szColor and IsString(nFontColorID) then
        szColor = nFontColorID
    end
    if not szColor then
        return nil
    end
    return UIHelper.ChangeHexColorStrToColor(szColor)
end

function UIHelper.GetSchoolIcon(dwSchoolID)
    local nForceID = SchoolTypeToForceID[dwSchoolID]
    return PlayerForceID2SchoolImg2[nForceID] or SchoolID2SchoolImg2[dwSchoolID]
end