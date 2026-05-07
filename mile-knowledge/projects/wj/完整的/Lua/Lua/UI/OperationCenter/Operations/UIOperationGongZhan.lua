-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationGongZhan
-- Date: 2026-03-30 09:39:42
-- Desc: 共战江湖活动总控
-- ---------------------------------------------------------------------------------

local UIOperationGongZhan = class("UIOperationGongZhan")

-----------------------------DataModel------------------------------
local m_tActInfo = nil

local function DataModel_Init()
    m_tActInfo = Table_GetGongZhanActInfo()
end

local function DataModel_UnInit()
    m_tActInfo = nil
end

-----------------------------View------------------------------

-- 获取有效的分类列表（排除1，因为1是概览奖励）
local function GetCategories()
    if not m_tActInfo then
        return {}
    end
    local tCategories = {}
    for nCat in pairs(m_tActInfo) do
        if nCat ~= 1 then
            table.insert(tCategories, nCat)
        end
    end
    table.sort(tCategories)
    return tCategories
end

local function GetGategoryData(nCategory)
    return m_tActInfo and m_tActInfo[nCategory]
end

local function GetActData(nCategory, nType)
    if not m_tActInfo or not m_tActInfo[nCategory] then
        return nil
    end
    return m_tActInfo[nCategory][nType]
end

-----------------------------Controller------------------------------

function UIOperationGongZhan:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    -- 初始化数据
    DataModel_Init()

    local tScriptTop = tComponentContext and tComponentContext.tScriptLayoutTop
    self.scriptGongZhanReward = tScriptTop and tScriptTop[3] -- WidgetGongZhanReward's script
    self.scriptContentTitleTog = tScriptTop and tScriptTop[4] -- WidgetContentTitleTog80's script

    -- 初始化标签页
    self:InitTabs()

    -- 默认选中第一个分类
    local tCategories = GetCategories()
    if #tCategories > 0 then
        self.m_nActiveCategory = tCategories[1]
    end

    self:UpdateInfo()
end

function UIOperationGongZhan:OnExit()
    self.bInit = false
    DataModel_UnInit()
    self:UnRegEvent()
end

function UIOperationGongZhan:BindUIEvent()

end

function UIOperationGongZhan:RegEvent()
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelGongZhanSide then
            UIHelper.SetVisible(UIHelper.GetParent(self.scriptGongZhanReward._rootNode), false)
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelGongZhanSide then
            UIHelper.SetVisible(UIHelper.GetParent(self.scriptGongZhanReward._rootNode), true)
        end
    end)
end

function UIOperationGongZhan:UnRegEvent()
    -- Event.UnReg(self, EventType.XXX, func)
end

------------------------------------------------------------
-- 初始化标签页
------------------------------------------------------------
function UIOperationGongZhan:InitTabs()
    if self.scriptContentTitleTog then
        self.scriptContentTitleTog:SetToggleSelectCallback(function(nIndex)
            self:OnTabChanged(nIndex)
        end)
    end
end

------------------------------------------------------------
-- Tab切换处理
------------------------------------------------------------
function UIOperationGongZhan:OnTabChanged(nIndex)
    local tCategories = GetCategories()
    if nIndex and tCategories[nIndex] then
        self.m_nActiveCategory = tCategories[nIndex]
        self:RefreshList()
    end
end

------------------------------------------------------------
-- 刷新任务列表
------------------------------------------------------------
function UIOperationGongZhan:RefreshList()
    if not self.scriptContentTitleTog or not self.scriptContentTitleTog.tScriptTaskList then
        return
    end

    local tTaskList = self.scriptContentTitleTog.tScriptTaskList
    local nCategory = self.m_nActiveCategory

    if not nCategory or not m_tActInfo or not m_tActInfo[nCategory] then
        return
    end

    -- 获取该分类下的所有类型，按nType排序
    local tKeys = {}
    for nType in pairs(m_tActInfo[nCategory]) do
        table.insert(tKeys, nType)
    end
    table.sort(tKeys)

    -- 更新每个任务单元
    local nTaskIndex = 1
    for _, nType in ipairs(tKeys) do
        local tLine = m_tActInfo[nCategory][nType]
        if tLine and tTaskList[nTaskIndex] then
            local scriptTask = tTaskList[nTaskIndex]
            local szTitle = UIHelper.GBKToUTF8(ParseTextHelper.ParseNormalText(tLine.szType, false))
            szTitle = szTitle .. "<img src='UIAtlas2_Public_PublicIcon_PublicIcon1_up' width='34' height='34' />"
            -- 使用UpdateTaskItem一次性更新
            scriptTask:UpdateTaskItem({
                szTitle = szTitle,
                szHintText = "",
                nTaskState = scriptTask.TASK_STATE.NON_GET,
                szMarkTag = "",
                bShowArrow = true,
            })

            -- 设置点击回调：打开侧面板
            scriptTask:SetfnCallBack(function()
                UIMgr.Open(VIEW_ID.PanelGongZhanSide, nCategory, nType, tLine)
            end)

            -- 显示任务单元
            UIHelper.SetVisible(scriptTask._rootNode, true)
            nTaskIndex = nTaskIndex + 1
        end
    end

    -- 隐藏多余的TaskList单元
    for i = nTaskIndex, #tTaskList do
        if tTaskList[i] then
            UIHelper.SetVisible(tTaskList[i]._rootNode, false)
        end
    end
end

------------------------------------------------------------
-- 刷新奖励显示
------------------------------------------------------------
function UIOperationGongZhan:RefreshReward()
    if not self.scriptGongZhanReward then
        return
    end

    -- 更新奖励信息
    self.scriptGongZhanReward:UpdateInfo(GetActData(1, 0))
end

------------------------------------------------------------
-- 主更新入口
------------------------------------------------------------
function UIOperationGongZhan:UpdateInfo()

    -- 刷新奖励模块
    self:RefreshReward()

    -- 刷新任务列表
    self:RefreshList()

    -- 刷新布局
    if self.scriptContentTitleTog and self.scriptContentTitleTog.LayoutContentTopWide then
        UIHelper.LayoutDoLayout(self.scriptContentTitleTog.LayoutContentTopWide)
    end
end

return UIOperationGongZhan