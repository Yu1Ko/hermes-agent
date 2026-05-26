-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatBulletView
-- Date: 2026-03-23 20:37:39
-- Desc: 弹幕界面 穿透不影响其他界面点击
-- ---------------------------------------------------------------------------------


local LINE_SPACE   = 10  -- 每行间距
local CYCLE_TIME   = 0.2 -- 轮询时间
local SCROLL_SPEED = Platform.IsAndroid() and 5 or 2   -- 滚动方式的 速度

local FIX_DISPLAY_TIME  = 8    -- 固定显示方式的单挑文字显示时长
local SCROLL_CALC_SPACE = 100  -- 计算的额外空白


local SHOW_MODE_TYPE =
{
    BULLETSCREEN_SHOWMODE_TYPE.TOP,
    BULLETSCREEN_SHOWMODE_TYPE.BOTTOM,
    BULLETSCREEN_SHOWMODE_TYPE.ROLL,
}


local UIChatBulletView = class("UIChatBulletView")

function UIChatBulletView:OnEnter()

    self:InitPool()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:ResetAll()
    self:UpdateInfo()
    self:UpdateOpacity()
end

function UIChatBulletView:OnExit()
    self:UnInitPool()

    self.bInit = false
    self:UnRegEvent()
end

function UIChatBulletView:InitPool()
    self.poolTop    = self.poolTop or PrefabPool.New(PREFAB_ID.WidgetDanmuRichTextFix, 8)
    self.poolBottom = self.poolBottom or PrefabPool.New(PREFAB_ID.WidgetDanmuRichTextFix, 8)
    self.poolScroll = self.poolScroll or PrefabPool.New(PREFAB_ID.WidgetDanmuRichTextScroll, 50)

    self.tbMapPool = {}
    self.tbMapPool[BULLETSCREEN_SHOWMODE_TYPE.TOP]    = self.poolTop
    self.tbMapPool[BULLETSCREEN_SHOWMODE_TYPE.BOTTOM] = self.poolBottom
    self.tbMapPool[BULLETSCREEN_SHOWMODE_TYPE.ROLL]   = self.poolScroll

    self.tbMapWidget = {}
    self.tbMapWidget[BULLETSCREEN_SHOWMODE_TYPE.TOP]    = self.WidgetTop
    self.tbMapWidget[BULLETSCREEN_SHOWMODE_TYPE.BOTTOM] = self.WidgetBottom
    self.tbMapWidget[BULLETSCREEN_SHOWMODE_TYPE.ROLL]   = self.WidgetScroll
end

function UIChatBulletView:UnInitPool()
    if self.poolTop then self.poolTop:Dispose() end
    self.poolTop = nil

    if self.poolBottom then self.poolBottom:Dispose() end
    self.poolBottom = nil

    if self.poolScroll then self.poolScroll:Dispose() end
    self.poolScroll = nil
end

function UIChatBulletView:BindUIEvent()

end

function UIChatBulletView:RegEvent()
    Event.Reg(self, EventType.OnChatBulletSettingUpdate, function(bNeedRebuild)
        self:UpdateOpacity()
    end)

    Event.Reg(self, EventType.OnReceiveChat, function(tbData, bToTop)
        -- TODO 要不要这里也刷一下？
    end)
end

function UIChatBulletView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIChatBulletView:ResetAll()
    self.tbMapTotalLine = {}
    self.tbMapLineOccupy = {}
    for k, nShowMode in ipairs(SHOW_MODE_TYPE) do
        self.tbMapTotalLine[nShowMode] = 0
        self.tbMapLineOccupy[nShowMode] = {}

        self:ResetOne(nShowMode)
    end
end

function UIChatBulletView:ResetOne(nShowMode)
    local pool = self.tbMapPool[nShowMode]
    if pool then
        pool:RecycleAll()
    end

    local widget = self.tbMapWidget[nShowMode]
    if widget then
        UIHelper.RemoveAllChildren(widget)
    end

    local nW, nH = UIHelper.GetContentSize(widget)
    local nFontSize = 30 -- 按每行30来算，这样预留点空间

    -- 算出总行数，和每行的位置
    local tbLineOccupy = {}
    local nTotalLine = math.ceil(nH / (nFontSize + LINE_SPACE))
    for i = 1, nTotalLine do
        local nPosY = -(nFontSize / 2 + (i - 1) * (LINE_SPACE + nFontSize))
        tbLineOccupy[i] = {nY = nPosY, bOccupy = false, nRightEdge = -math.huge, nIndex = i}
    end

    self.tbMapTotalLine[nShowMode]  = nTotalLine
    self.tbMapLineOccupy[nShowMode] = tbLineOccupy
end

function UIChatBulletView:IsFixShowMode(nShowMode)
    return nShowMode == BULLETSCREEN_SHOWMODE_TYPE.TOP or nShowMode == BULLETSCREEN_SHOWMODE_TYPE.BOTTOM
end

function UIChatBulletView:IsScrollShowMode(nShowMode)
    return nShowMode == BULLETSCREEN_SHOWMODE_TYPE.ROLL
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatBulletView:UpdateInfo()
    Timer.DelTimer(self, self.nTimerID)
    self.nTimerID = Timer.AddCycle(self, CYCLE_TIME, function()
        local tbData = ChatData.PickOneBulletData()
        if not tbData then
            return
        end

        local nShowMode = tbData.nShowMode
        if self:IsScrollShowMode(nShowMode) then
            local nLineIndex = self:FindIdleLine(nShowMode)
            if nLineIndex then
                self:UpdateInfo_Scroll_One(nShowMode, tbData, nLineIndex)
            end
        elseif self:IsFixShowMode(nShowMode) then
            if self:HasIdleLine(nShowMode) then
                self:UpdateInfo_Fix_One(nShowMode, tbData)
            end
        end
    end)
end

-- 固定的，顶部或底部显示
function UIChatBulletView:UpdateInfo_Fix_One(nShowMode, tbData)
    if not tbData then
        return
    end

    local pool = self.tbMapPool[nShowMode]
    if not pool then
        return
    end

    local widget = self.tbMapWidget[nShowMode]
    if not widget then
        return
    end

    if not self:HasIdleLine(nShowMode) then
        return
    end

    local tLine = self:TakeLine(nShowMode)
    if not tLine then
        return
    end

    local node, script = pool:Allocate(widget)
    local szContent = self:GetFormatContent(tbData)
    local nRichTextW = self:SetString(script.RichText, szContent)
    UIHelper.SetRichTextCanClick(script.RichText, false)

    script.tLine = tLine
    UIHelper.SetPosition(node, 0, tLine.nY)

    Timer.Add(script, FIX_DISPLAY_TIME, function()
        self:ReturnLine(nShowMode, tLine.nIndex)

        local pool = self.tbMapPool[nShowMode]
        if pool then
            pool:Recycle(node)
        end

        -- 继续找下一个
        --self:UpdateInfo_Fix_One(nShowMode)
    end)
end

-- 从右到左滚动显示
function UIChatBulletView:UpdateInfo_Scroll_One(nShowMode, tbData, nLineIndex)
    if not tbData then
        return
    end

    local pool = self.tbMapPool[nShowMode]
    if not pool then
        return
    end

    local widget = self.tbMapWidget[nShowMode]
    if not widget then
        return
    end

    local tLine = self.tbMapLineOccupy[nShowMode][nLineIndex]
    if not tLine then
        return
    end

    local node, script = pool:Allocate(widget)
    local szContent = self:GetFormatContent(tbData)
    local nRichTextW = self:SetString(script.RichText, szContent)
    UIHelper.SetRichTextCanClick(script.RichText, false)

    local nWidgetW = UIHelper.GetWidth(widget)
    local nHalfW = nWidgetW / 2

    -- 根据当前行右侧边缘计算起始位置（排除自己）
    local nRightEdge = self:ComputeRightEdge(nShowMode, nLineIndex, node)
    local nStartX = math.max(nHalfW, nRightEdge + SCROLL_CALC_SPACE)

    script.tLine = tLine
    script.nRichTextW = nRichTextW
    UIHelper.SetPosition(node, nStartX, tLine.nY)

    Timer.DelTimer(script, script.nTimerID)
    script.nTimerID = Timer.AddFrameCycle(script, 1, function()
        local nX = UIHelper.GetPositionX(node)
        local nNewX = nX - SCROLL_SPEED
        UIHelper.SetPosition(node, nNewX, tLine.nY)

        -- 完全滚出屏幕后回收
        if nNewX + nRichTextW + 10 < -nHalfW then
            Timer.DelTimer(script, script.nTimerID)
            pool:Recycle(node)
        end
    end)
end


-- 是否有空行（固定模式用）
function UIChatBulletView:HasIdleLine(nShowMode)
    for k, v in ipairs(self.tbMapLineOccupy[nShowMode]) do
        if v.bOccupy == false then
            return true
        end
    end

    return false
end

-- 获取行（固定模式用）
function UIChatBulletView:TakeLine(nShowMode)
    for k, v in ipairs(self.tbMapLineOccupy[nShowMode]) do
        if v.bOccupy == false then
            v.bOccupy = true
            return v
        end
    end

    return nil
end

-- 返回行（固定模式用）
function UIChatBulletView:ReturnLine(nShowMode, nIndex)
    if nIndex and self.tbMapLineOccupy[nShowMode] and self.tbMapLineOccupy[nShowMode][nIndex] then
        self.tbMapLineOccupy[nShowMode][nIndex].bOccupy = false
    end
end

-- 找到有足够空间的行（滚动模式用）
function UIChatBulletView:FindIdleLine(nShowMode)
    local widget = self.tbMapWidget[nShowMode]
    if not widget then return nil end

    local nHalfW = UIHelper.GetWidth(widget) / 2

    for k, line in ipairs(self.tbMapLineOccupy[nShowMode]) do
        local nRightEdge = self:ComputeRightEdge(nShowMode, k)
        if nRightEdge + SCROLL_CALC_SPACE <= nHalfW then
            return k
        end
    end

    return nil
end

-- 计算某一行上所有活跃弹幕的最右侧边缘
function UIChatBulletView:ComputeRightEdge(nShowMode, nIndex, excludeNode)
    local nRightEdge = -math.huge
    local pool = self.tbMapPool[nShowMode]
    if not pool then return nRightEdge end

    for node, script in pairs(pool.m_tbNodeScriptMap) do
        if node ~= excludeNode and UIHelper.GetParent(node) and script.tLine and script.tLine.nIndex == nIndex then
            local nX = UIHelper.GetPositionX(node)
            local nW = script.nRichTextW or 0
            local edge = nX + nW
            if edge > nRightEdge then
                nRightEdge = edge
            end
        end
    end

    return nRightEdge
end

-- 设置富文本
function UIChatBulletView:SetString(richText, szBulletContent)
    if not richText then
        return
    end

    local nFontID = Storage.Chat_Bullet.nFontSize
    local nFontSize = Bullet_FontID_To_Size[nFontID]

    UIHelper.SetHeight(richText, nFontSize)
    UIHelper.SetRichText(richText, szBulletContent)

    local nRichTextWidth = UIHelper.GetUtf8RichTextWidth(szBulletContent, nFontSize)
    return nRichTextWidth
end

-- 格式化字符串
function UIChatBulletView:GetFormatContent(tbData)
    if not tbData or string.is_nil(tbData.szContent) then
        return ""
    end

    local nColorID = tbData.nColourID or Storage.Chat_Bullet.nColorID
    local tColor = Table_GetDanmakuColor(nColorID)
    local szColor = string.format("#%02X%02X%02X", tColor.r, tColor.g, tColor.b)

    local nFontID = tbData.nFontType or Storage.Chat_Bullet.nFontSize
    local nFontSize = Bullet_FontID_To_Size[nFontID]

    --local nShowMode = tbData.nShowMode

    local szBulletContent = string.format("<font size='%d'><color=%s>[%s]：%s</color></font>", nFontSize, szColor, tostring(tbData.szName), tbData.szContent)

    return szBulletContent
end

-- 透明度
function UIChatBulletView:UpdateOpacity()
    local nOpacity = Storage.Chat_Bullet.nOpacity

    local nCocosOpacity = (nOpacity / 100) * 255
    UIHelper.SetOpacity(self.WidgetTop, nCocosOpacity)
    UIHelper.SetOpacity(self.WidgetBottom, nCocosOpacity)
    UIHelper.SetOpacity(self.WidgetScroll, nCocosOpacity)
end

return UIChatBulletView