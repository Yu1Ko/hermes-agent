TraceInfoData = TraceInfoData or {}
local self = TraceInfoData

local m_nAllocatedWidgetID = 0

--左侧信息追踪显示 相关功能

--[[
    如何新增左侧信息类型：
    1. 在UIDef.lua新增TraceInfoType.XXX新类型；
    2. 创建XXXInfoHandler.lua文件，格式请参考TemplateInfoHandler.lua，并将其添加到下方的InitAllInfoHandler中；
    3. 在XXXInfoHandler中通过接收事件等方式，获取要显示的数据，并记录该数据（由于这里同一份数据要在多个地方显示，所以把数据和显示拆开）；
    4. 在XXXInfoHandler.OnUpdateView函数中编写【如何显示记录数据】的逻辑（同理XXXInfoHandler.OnClear清理数据）；
    5. 当需要显示时，触发事件Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.XXX, true, tData)，使内容在左边信息栏显示；
    6. 调用UpdateInfo(TraceInfoType.XXX)可更新数据显示（上面OnTogTraceInfo的时候会自动调用一次）；
--]]

function TraceInfoData.Init()
    self.tInfoHandler = self.tInfoHandler or {} --信息Handler表
    self.tTraceInfoWidget = self.tTraceInfoWidget or {} --追踪信息显示Widget

    self.RegEvent()
    self.InitAllInfoHandler()
end

function TraceInfoData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

    self.ClearAllTraceInfo()
end

function TraceInfoData.InitAllInfoHandler()
    local szPath = "Lua/Logic/TraceInfo/TraceInfoHandler/%sInfoHandler.lua" --命名规则 XXXInfoHandler.lua
    self.RegInfoHandler(TraceInfoType.PublicQuest,          string.format(szPath, TraceInfoType.PublicQuest))
    self.RegInfoHandler(TraceInfoType.ActivityTip,          string.format(szPath, TraceInfoType.ActivityTip))
    self.RegInfoHandler(TraceInfoType.CrossingProgress,     string.format(szPath, TraceInfoType.CrossingProgress))
    self.RegInfoHandler(TraceInfoType.DungeonProgress,      string.format(szPath, TraceInfoType.DungeonProgress))
    self.RegInfoHandler(TraceInfoType.TreasureBattleField,  string.format(szPath, TraceInfoType.TreasureBattleField))
    self.RegInfoHandler(TraceInfoType.LangKeXing,           string.format(szPath, TraceInfoType.LangKeXing))
    self.RegInfoHandler(TraceInfoType.CampData,             string.format(szPath, TraceInfoType.CampData))
    self.RegInfoHandler(TraceInfoType.BombFightBar,         string.format(szPath, TraceInfoType.BombFightBar))
    self.RegInfoHandler(TraceInfoType.ZombieFightBar,       string.format(szPath, TraceInfoType.ZombieFightBar))
    self.RegInfoHandler(TraceInfoType.BahuangDataInfo,      string.format(szPath, TraceInfoType.BahuangDataInfo))
    self.RegInfoHandler(TraceInfoType.LangKeXingProgress,   string.format(szPath, TraceInfoType.LangKeXingProgress))
    self.RegInfoHandler(TraceInfoType.HomeWeeklyMission,    string.format(szPath, TraceInfoType.HomeWeeklyMission))
    self.RegInfoHandler(TraceInfoType.Compass,              string.format(szPath, TraceInfoType.Compass))
    self.RegInfoHandler(TraceInfoType.GolfSpirit,           string.format(szPath, TraceInfoType.GolfSpirit))
    self.RegInfoHandler(TraceInfoType.HotSpring,            string.format(szPath, TraceInfoType.HotSpring))
    self.RegInfoHandler(TraceInfoType.ArenaTowerElement,    string.format(szPath, TraceInfoType.ArenaTowerElement))
end

function TraceInfoData.RegEvent()

end

-------------------------------- Public --------------------------------

--注册一个Widget(ScrollView)，会在它上面显示信息（PQ、动态信息Tip之类的），并且实时更新；
--因为在左侧信息栏和信息追踪界面都要显示，所以做成这种绑定的形式，并且把相关代码整合一下
--注册完记得在script或scrollViewParent销毁的时候UnRegWidget
function TraceInfoData.RegWidget(szInfoType, script, scrollViewParent, tData, bDelayLayout)
    if not szInfoType then
        return
    end

    if not self.tTraceInfoWidget[szInfoType] then
        self.tTraceInfoWidget[szInfoType] = {}
    end

    --若已注册其他信息类型，则解绑
    if script._szTraceInfoType and script._szTraceInfoType ~= szInfoType then
        self.UnRegWidget(script)
    end

    local nWidgetID = script._nTraceInfoWidgetID
    if not nWidgetID then
        m_nAllocatedWidgetID = m_nAllocatedWidgetID + 1
        nWidgetID = m_nAllocatedWidgetID
        script._nTraceInfoWidgetID = m_nAllocatedWidgetID
        script._szTraceInfoType = szInfoType

        --存放TimerID的Table
        if script._tTraceInfoTimer then
            Timer.DelAllTimer(script._tTraceInfoTimer)
        end
        script._tTraceInfoTimer = {}

        if script._tTraceInfoEvent then
            Event.UnRegAll(script._tTraceInfoEvent)
        end
        script._tTraceInfoEvent = {}
    end

    local tWidgetData = {
        script = script,
        scrollViewParent = scrollViewParent,
        tData = tData,
    }

    self.tTraceInfoWidget[szInfoType][nWidgetID] = tWidgetData
    self.UpdateWidgetInfo(szInfoType, tWidgetData)

    --延迟1帧，用于刚打开的界面或预制
    if bDelayLayout then
        Timer.AddFrame(script._tTraceInfoTimer, 1, function()
            UIHelper.CascadeDoLayoutDoWidget(scrollViewParent)
            UIHelper.ScrollViewDoLayoutAndToTop(scrollViewParent)
        end)
    else
        UIHelper.ScrollViewDoLayoutAndToTop(scrollViewParent)
    end

    Event.Reg(script._tTraceInfoEvent, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(script._tTraceInfoTimer, 5, function()
            if UIHelper.GetHierarchyVisible(scrollViewParent) then
                UIHelper.CascadeDoLayoutDoWidget(scrollViewParent)
                UIHelper.ScrollViewDoLayoutAndToTop(scrollViewParent)
            end
        end)
    end)
end

--解绑Widget
function TraceInfoData.UnRegWidget(script)
    local szInfoType = script._szTraceInfoType
    if not self.tTraceInfoWidget[szInfoType] then
        return
    end

    local nWidgetID = script._nTraceInfoWidgetID
    if nWidgetID then
        local tWidgetData = self.tTraceInfoWidget[szInfoType][nWidgetID]
        self.ClearWidgetInfo(szInfoType, tWidgetData)
        Timer.DelAllTimer(script._tTraceInfoTimer)
        Event.UnRegAll(script._tTraceInfoEvent)

        script._nTraceInfoWidgetID = nil
        script._szTraceInfoType = nil
        script._tTraceInfoTimer = nil
        script._tTraceInfoEvent = nil
        self.tTraceInfoWidget[szInfoType][nWidgetID] = nil
    end
end

--更新信息显示
function TraceInfoData.UpdateInfo(szInfoType)
    for nWidgetID, tWidgetData in pairs(self.tTraceInfoWidget[szInfoType] or {}) do
        self.UpdateWidgetInfo(szInfoType, tWidgetData)
    end
end

--遍历显示同一个信息类型的所有Widget，用于根据条件更新
--fnAction(script, scrollViewParent, tData)
function TraceInfoData.ForEach(szInfoType, fnAction)
    for nWidgetID, tWidgetData in pairs(self.tTraceInfoWidget[szInfoType] or {}) do
        local script = tWidgetData.script
        local scrollViewParent = tWidgetData.scrollViewParent
        local tData = tWidgetData.tData
        if fnAction then
            fnAction(script, scrollViewParent, tData)
        end
    end
end

--获取信息Handler
function TraceInfoData.GetInfoHandler(szInfoType)
    return self.tInfoHandler[szInfoType]
end

-------------------------------- Private --------------------------------

function TraceInfoData.RegInfoHandler(szInfoType, szPath)
    local tHandler = require(szPath)
    if tHandler then
        self.tInfoHandler[szInfoType] = tHandler
        if tHandler.Init then
            tHandler.Init()
        end
    end
end

function TraceInfoData.ClearAllTraceInfo()
    for _, tHandler in pairs(self.tInfoHandler or {}) do
        if tHandler.UnInit then
            tHandler.UnInit()
        end
    end
    self.tInfoHandler = {}
end

function TraceInfoData.UpdateWidgetInfo(szInfoType, tWidgetData)
    if not tWidgetData then
        return
    end

    local script = tWidgetData.script                       --要显示内容的Widget上的脚本，用于存放部分数据
    local scrollViewParent = tWidgetData.scrollViewParent   --要显示内容的Widget上具体的ScrollView父节点
    local tData = tWidgetData.tData                         --触发OnTogTraceInfo事件时传入的参数tData

    local tHandler = self.tInfoHandler[szInfoType]
    if tHandler and tHandler.OnUpdateView then
        tHandler.OnUpdateView(script, scrollViewParent, tData)
    end

    -- note: 部分界面的排版刷新由其自行负责，如李渡鬼域仅在显示的条目集合有变动时才刷新，避免需要不停往下滑看剩余内容
    if szInfoType ~= TraceInfoType.ZombieFightBar and szInfoType ~= TraceInfoType.PublicQuest and szInfoType ~= TraceInfoType.HotSpring then
        UIHelper.CascadeDoLayoutDoWidget(scrollViewParent)
        UIHelper.ScrollViewDoLayoutAndToTop(scrollViewParent)
    end
end

function TraceInfoData.ClearWidgetInfo(szInfoType, tWidgetData)
    if not tWidgetData then
        return
    end

    local script = tWidgetData.script
    local scrollViewParent = tWidgetData.scrollViewParent

    UIHelper.RemoveAllChildren(scrollViewParent)

    local tHandler = self.tInfoHandler[szInfoType]
    if tHandler and tHandler.OnClear then
        tHandler.OnClear(script)
    end
end
