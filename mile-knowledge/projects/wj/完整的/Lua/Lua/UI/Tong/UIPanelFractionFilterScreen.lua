-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelFractionFilterScreen
-- Date: 2023-01-09 11:33:34
-- Desc: PanelFactionManagementFilterScreen
-- ---------------------------------------------------------------------------------

local UIPanelFractionFilterScreen = class("UIPanelFractionFilterScreen")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPanelFractionFilterScreen:_LuaBindList()
    self.WidgetAnchorFilterPermissions = self.WidgetAnchorFilterPermissions --- 移动头衔模式的组件
    self.WidgetAnchorFilterMember      = self.WidgetAnchorFilterMember --- 成员筛选模式的组件

    self.ScrollViewMemberFilterList    = self.ScrollViewMemberFilterList --- 筛选条目的scroll view
    self.BtnReset                      = self.BtnReset --- 重置为【全部】选项
    self.BtnComplete                   = self.BtnComplete --- 完成选择

    self.TogSchool                     = self.TogSchool --- 门派的toggle
    self.TogGroup                      = self.TogGroup --- 头衔的toggle
end

function UIPanelFractionFilterScreen:OnEnter(nFilterScreenType, tbSelectIDList, nGroupIndex, fnMemberFilterCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nFilterScreenType      = nFilterScreenType
    self.tbSelectIDList         = tbSelectIDList
    self.nGroupIndex            = nGroupIndex
    self.fnMemberFilterCallback = fnMemberFilterCallback

    --- 成员筛选类型
    self.nMemberFilterType      = TongData.tMemberFilterType.School

    --- 门派筛选
    self.nSchoolFilter          = TongData.nMemberFilterSchoolAll
    --- 头衔筛选
    self.nGroupFilter           = TongData.nMemberFilterGroupAll

    self:UpdateInfo()
end

function UIPanelFractionFilterScreen:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelFractionFilterScreen:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMove, EventType.OnClick, function()
        self:MoveTo()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        for idx, tWidgetPermission in ipairs(UIHelper.GetChildren(self.ScrollViewMemberFilterList)) do
            local script = UIHelper.GetBindScript(tWidgetPermission)
            UIHelper.SetSelected(script.TogFilterScreenItem, idx == 1)
        end

        self:SetMemberFilter()
    end)

    UIHelper.BindUIEvent(self.BtnComplete, EventType.OnClick, function()
        self:SetMemberFilter()
    end)

    UIHelper.BindUIEvent(self.TogSchool, EventType.OnClick, function()
        self.nMemberFilterType = TongData.tMemberFilterType.School
        self:UpdateInfoMemberFilterList()
    end)

    UIHelper.BindUIEvent(self.TogGroup, EventType.OnClick, function()
        self.nMemberFilterType = TongData.tMemberFilterType.Group
        self:UpdateInfoMemberFilterList()
    end)

    UIHelper.SetToggleGroupIndex(self.TogSchool, ToggleGroupIndex.TongMemberFilter)
    UIHelper.SetToggleGroupIndex(self.TogGroup, ToggleGroupIndex.TongMemberFilter)
end

function UIPanelFractionFilterScreen:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        UIMgr.Close(self)
    end)
end

function UIPanelFractionFilterScreen:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelFractionFilterScreen:UpdateInfo()
    UIHelper.SetVisible(self.WidgetAnchorFilterPermissions, self.nFilterScreenType == TongData.tFilterScreenType.Permissions)
    UIHelper.SetVisible(self.WidgetAnchorFilterMember, self.nFilterScreenType == TongData.tFilterScreenType.Member)

    if self.nFilterScreenType == TongData.tFilterScreenType.Permissions then
        self:UpdateInfoPermissions()
    else
        self:UpdateInfoMember()
    end
end

function UIPanelFractionFilterScreen:UpdateInfoPermissions()
    self.tbScriptView = {}
    UIHelper.RemoveAllChildren(self.LayoutFilterPermissions)
    local tbGroupList = TongData.GetCanAddMemberGroupList(self.nGroupIndex)
    for index, tbInfo in ipairs(tbGroupList) do
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetFilterScreenItemPermissions, self.LayoutFilterPermissions, {
            szName = UIHelper.GBKToUTF8(tbInfo.szName),
            nGroupIndex = tbInfo.nGroupIndex,
        })
        table.insert(self.tbScriptView, scriptView)
    end
    UIHelper.LayoutDoLayout(self.LayoutFilterPermissions)
    UIHelper.ScrollViewDoLayout(self.ScrollViewFilterPermissions)
    UIHelper.ScrollToTop(self.ScrollViewFilterPermissions, 0)
end

-- 帮会单个组人数太多的情况下（比如200多人），一次性批量移动到其他组的情况下，很大概率会因为请求过于频繁被服务器踢下线，这里做下分批处理
local function DoByBatch(tbSelectIDList, nTargetGroupIndex, nStartIndex)
    if nStartIndex > #tbSelectIDList then
        return
    end

    local nBatchSize = 50
    local nEndIndex = math.min(nStartIndex + nBatchSize - 1, #tbSelectIDList)
    
    --- 做个标记，避免每一批次都触发消息
    Global.bLastBatchChangeTongMemberGroup = nEndIndex == #tbSelectIDList

    --- 如果需要分批处理，则在第一次的时候弹个开始发送的提示
    if nStartIndex == 1 and #tbSelectIDList > nBatchSize then
        TipsHelper.ShowNormalTip("开始修改成员组")
    end

    for index = nStartIndex, nEndIndex do
        local dwTargetMemberID = tbSelectIDList[index]
        TongData.ChangeMemberGroup(dwTargetMemberID, nTargetGroupIndex)
    end

    Timer.Add(Global, 1, function()
        DoByBatch(tbSelectIDList, nTargetGroupIndex, nEndIndex + 1)
    end)
end

function UIPanelFractionFilterScreen:MoveTo()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE) then
        return
    end

    local nTargetGroupIndex = -1
    for index, scriptView in ipairs(self.tbScriptView) do
        if scriptView:GetSelected() then
            nTargetGroupIndex = scriptView:GetGroupIndex()
            break
        end
    end
    if nTargetGroupIndex ~= -1 then
        DoByBatch(clone(self.tbSelectIDList), nTargetGroupIndex, 1)
    end
end

function UIPanelFractionFilterScreen:UpdateInfoMember()
    self:UpdateInfoMemberFilterList()
end

function UIPanelFractionFilterScreen:UpdateInfoMemberFilterList()
    UIHelper.RemoveAllChildren(self.ScrollViewMemberFilterList)

    local tFilterList = self:GetFilterList()
    for idx, tFilter in ipairs(tFilterList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFilterScreenItemPermissions, self.ScrollViewMemberFilterList, tFilter)
        UIHelper.SetSelected(script.TogFilterScreenItem, idx == 1)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMemberFilterList)
end

function UIPanelFractionFilterScreen:GetFilterList()
    local tFilterList = {}

    local guild       = GetTongClient()
    if self.nMemberFilterType == TongData.tMemberFilterType.School then
        -- 门派
        local tList = Table_GetAllForceUI()
        for nForceType, v in pairs(tList) do
            table.insert(tFilterList, { szName = v.szName, nGroupIndex = nForceType })
        end
        table.sort(tFilterList, function(a, b) return a.nGroupIndex < b.nGroupIndex end)
        table.insert(tFilterList, 1, { szName = g_tStrings.STR_GUILD_ALL, nGroupIndex = TongData.nMemberFilterSchoolAll })
    else
        -- 头衔
        for i = 0, TongData.TOTAL_GROUP_CNT - 1, 1 do
            local groupInfo = guild.GetGroupInfo(i)
            if groupInfo.bEnable then
                table.insert(tFilterList, { szName = UIHelper.GBKToUTF8(groupInfo.szName), nGroupIndex = i })
            end
        end
        table.insert(tFilterList, 1, { szName = g_tStrings.STR_GUILD_ALL, nGroupIndex = TongData.nMemberFilterGroupAll })
    end

    return tFilterList
end

function UIPanelFractionFilterScreen:SetMemberFilter()
    local nTargetGroupIndex = nil

    for idx, tWidgetPermission in ipairs(UIHelper.GetChildren(self.ScrollViewMemberFilterList)) do
        local script = UIHelper.GetBindScript(tWidgetPermission)

        if script:GetSelected() then
            nTargetGroupIndex = script:GetGroupIndex()
            break
        end
    end

    if nTargetGroupIndex == nil then
        return
    end

    if self.nMemberFilterType == TongData.tMemberFilterType.School then
        self.nSchoolFilter = nTargetGroupIndex
    else
        self.nGroupFilter = nTargetGroupIndex
    end

    self.fnMemberFilterCallback(self.nSchoolFilter, self.nGroupFilter)
end

return UIPanelFractionFilterScreen