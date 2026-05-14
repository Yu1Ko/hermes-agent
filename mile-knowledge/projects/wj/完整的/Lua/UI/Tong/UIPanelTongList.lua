-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIPanelTongList
-- Date: 2022-12-19 16:33:37
-- Desc: 帮会列表面板
-- Prefab: PanelFactionList
-- ---------------------------------------------------------------------------------

local function IsMsgEditAllowed()
    return UI_IsActivityOn(ACTIVITY_ID.ALLOW_EDIT) -- 此活动在时间上一直开启，通过策划调用指令来改变实际的开启状态
end

---@class UIPanelTongList
local UIPanelTongList = class("UIPanelTongList")

local g2u             = UIHelper.GBKToUTF8
local u2g             = UIHelper.UTF8ToGBK

-- 模拟帮会列表数据
local _FakeTongList   = function(nPage)
    local tTongArr = {}
    for i = 1, 10 do
        local tTong = {
            dwTongID = 1,
            nCamp = 1,
            szTongName = "帮会名字啦啦啦" .. nPage .. "_" .. i,
            szMasterName = "帮主名字" .. nPage .. "_" .. i,
            nMemberCount = 100 + i,
            szDescription = "描述什么的最讨厌了" .. i,
        }
        table.insert(tTongArr, tTong)
    end
    RemoteFunction.On_Tong_GetADTongList(30, #tTongArr, tTongArr)
end

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPanelTongList:_LuaBindList()
    self.ScrollViewNavToggle          = self.ScrollViewNavToggle --- 导航栏的scroll view

    self.TogTopTenTongList            = self.TogTopTenTongList --- 十大推荐帮会的toggle
    self.TogADTongList                = self.TogADTongList --- 帮会列表的toggle

    self.WidgetTopTenTongList         = self.WidgetTopTenTongList --- 十大推荐帮会的标题栏
    self.ScrollViewTopTenTongList     = self.ScrollViewTopTenTongList --- 十大推荐帮会的scroll view

    self.WidgetADTongList             = self.WidgetADTongList --- 帮会列表的标题栏
    self.ScrollViewADTongList         = self.ScrollViewADTongList --- 帮会列表的scroll view

    self.WidgetAniMiddle              = self.WidgetAniMiddle --- 空状态上层的组件
    self.WidgetAnchorFactionListTitle = self.WidgetAnchorFactionListTitle --- 标题栏上层的组件
    
    self.LabelIntroductionRecommend   = self.LabelIntroductionRecommend --- 推荐帮会的【简介】标题栏
end

function UIPanelTongList:OnEnter(bADList)
    self.m          = {}
    self.m.tCellArr = {}

    --- 默认显示十大推荐帮会。true => 帮会列表，false => 推荐帮会
    self.bADList    = false
    if bADList ~= nil then
        self.bADList = bADList
    end
    self.bHasADTongList = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:Init()
    self:UpdateInfo()
end

function UIPanelTongList:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:UnInit()
    self.m = nil
end

function UIPanelTongList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
    UIHelper.BindUIEvent(self.BtnCloseTips, EventType.OnClick, function()
        self:ShowTongBookerList(false)
    end)
    UIHelper.BindUIEvent(self.BtnClose01, EventType.OnClick, function()
        --self.m.bDoNothing = true
        UIHelper.SetString(self.EditBoxFactionSearch, "")
        --self.m.bDoNothing = false
    end)
    UIHelper.BindUIEvent(self.BtnApplicationFaction, EventType.OnClick, function()
        self:ApplyJoinSelectedTong()
    end)
    UIHelper.BindUIEvent(self.TogCreationFaction, EventType.OnClick, function()
        local player = GetClientPlayer()
        if player and player.nLevel < 110 then
            TipsHelper.ShowNormalTip("侠士达到110级后方可创建帮会")
            return
        end
        self:ShowTongBookerList(true)
    end)

    -- self.CellToggleGroup:addEventListener(function (toggle, nIndexBaseZero)
    -- 	self:OnSelectChanged(nIndexBaseZero + 1)
    -- end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxFactionSearch, function()
        local sz = UIHelper.GetString(self.EditBoxFactionSearch)
        if sz and sz ~= "" then
            UIHelper.ShowConfirm(string.format("你确认要申请加入<color=#FFE26E>%s</color>帮会么？", sz), function()
                self:ApplyJoinTongByTongName(u2g(sz))
            end, nil, true)
        end
    end)

    -- 设置toggle互斥
    local tTongListToggle = { self.TogTopTenTongList, self.TogADTongList }
    for idx, tToggle in ipairs(tTongListToggle) do
        UIHelper.SetToggleGroupIndex(tToggle, ToggleGroupIndex.TongList)

        UIHelper.BindUIEvent(tToggle, EventType.OnClick, function()
            self:UpdateInfo()
        end)
    end
    if self.bADList then
        UIHelper.SetSelected(self.TogADTongList, true)
    else
        UIHelper.SetSelected(self.TogTopTenTongList, true)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewNavToggle)
end

function UIPanelTongList:RegEvent()
    Event.Reg(self, "ON_GET_AD_TONGLIST", function(nTotalCount, nCount, tTongArr)
        RM_SetRunMode(self.m.RequestTongListRM, "WaitLayout")
        RM_UpdateRunMode(self.m.RequestTongListRM)

        self.m.nTotalCount = nTotalCount
        self:AddTongList(tTongArr)
    end)
    Event.Reg(self, "On_Tong_ApplyJoinRespond", function(nRetCode)
        if self.bADList then
            if nRetCode == TONG_APPLY_JOININ_RESULT_CODE.SUCCESS then
                self.m.tAppliedJoinTongNameDict[self.m.szApplyJoinName] = true
                self:UpdateCellByTongName(self.m.szApplyJoinName)
            end
        end
    end)

    Event.Reg(self, "ON_GET_TOPTEN_TONGLIST", function(nCount, tTongArr)
        self:UpdateTopTenTongInfo(nCount, tTongArr)
    end)
    
    Event.Reg(self, "LUA_ON_ACTIVITY_STATE_CHANGED_NOTIFY", function(dwActivityID, bOpen)
        UIHelper.SetVisible(self.LabelIntroductionRecommend, IsMsgEditAllowed())

        for _, child in ipairs(UIHelper.GetChildren(self.ScrollViewTopTenTongList)) do
            ---@type UIFactionList
            local script = UIHelper.GetBindScript(child)

            local tTong = script.tTong
            local _, szDescription = TextFilterReplace(tTong.szDescription)
            
            UIHelper.SetString(script.LabelTopTenDescription, bOpen and g2u(szDescription) or "")
        end
    end)
end

function UIPanelTongList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelTongList:UpdateInfo()
    self.bADList = UIHelper.GetSelected(self.TogADTongList)

    -- note: 保持原来帮会列表的写法不变，仅在推荐列表时将其相关组件隐藏，而推荐列表则用其他页面的update info + 事件驱动的写法。这样可以尽量减少改动原有的代码，方便后续维护
    UIHelper.SetVisible(self.WidgetTopTenTongList, not self.bADList)
    UIHelper.SetVisible(self.ScrollViewTopTenTongList, not self.bADList)

    UIHelper.SetVisible(self.LabelIntroductionRecommend, IsMsgEditAllowed())

    UIHelper.SetVisible(self.WidgetADTongList, self.bADList)
    UIHelper.SetVisible(self.ScrollViewADTongList, self.bADList)
    if self.bADList then
        -- 帮会列表由于之前的写法，仅更新一次，这里按照保存的结果来确定是否展示空状态和标题
        UIHelper.SetVisible(self.WidgetAniMiddle, not self.bHasADTongList)
        UIHelper.SetVisible(self.WidgetAnchorFactionListTitle, self.bHasADTongList)
    else
        -- 推荐帮会：默认显示空状态，隐藏右侧标题，这样避免出现刚点击时显示，实际请求数据发现没有被隐藏的奇怪表现
        UIHelper.SetVisible(self.WidgetAniMiddle, true)
        UIHelper.SetVisible(self.WidgetAnchorFactionListTitle, false)
    end

    if self.bADList then
        -- 帮会列表
        -- note: 这部分通过之前的 RequestTongListRM 的写法来更新状态，这里不用任何操作
    else
        -- 十大推荐帮会
        self:RequestTopTenTongList()
    end
end

function UIPanelTongList:Init()
    UIHelper.SetVisible(self.WidgetAniMiddle, false)
    UIHelper.SetVisible(self.WidgetAniRight, false)
    UIHelper.SetVisible(self.BtnApplicationFaction, false)

    self:InitRequestTongListRM()
end

function UIPanelTongList:UnInit()
    self:UnInitRequestTongListRM()
end

function UIPanelTongList:UnInitRequestTongListRM()

    if self.nCallId then
        Timer.DelTimer(self, self.nCallId)
        self.nCallId = nil
    end
end

function UIPanelTongList:InitRequestTongListRM()
    local rm                 = {}
    rm.Idle                  = function()
    end
    -- 开始加载
    rm.Request               = function()
        if RM_IsFirstCycle(rm) then
            self:InitTongList()
            self:RequestTongList()
        end
    end
    -- 等待响应
    rm.WaitRespond           = function()
    end
    -- 等待新数据排版完成
    rm.WaitLayout            = function()
        local list = self.ScrollViewADTongList
        assert(list)
        local tSize = list:getInnerContainerSize()

        if RM_IsFirstCycle(rm) then
            rm.tInnerSize = tSize
        else
            if rm.tInnerSize.height ~= tSize.height then
                RM_SetRunMode(rm, "WaitScroll")
            end
        end
    end
    -- 等待滚动
    rm.WaitScroll            = function()
    end

    --
    self.m.RequestTongListRM = rm
    RM_InitRunMode(rm, "UIPanelTongList.RequestTongList")
    RM_SetRunMode(rm, "Request")

    -- 跑起来
    self.nCallId = Timer.AddFrameCycle(self, 1, function()
        RM_UpdateRunMode(rm)
    end)
end

function UIPanelTongList:CheckRequset()
    if not self.m.nTotalCount or self.m.nTotalCount <= #self.m.tTongArr then
        return
    end

    if not RM_IsInThisRunMode(self.m.RequestTongListRM, "WaitScroll") then
        return
    end

    local list = self.ScrollViewADTongList
    assert(list)
    local size = list:getContentSize()
    local pos  = list:getInnerContainerPosition()
    if math.abs(pos.y) < 1 then
        self:RequestTongList()
    end
end

function UIPanelTongList:RequestTongList()
    RM_SetRunMode(self.m.RequestTongListRM, "WaitRespond")

    self.m.nRequestPage = self.m.nRequestPage + 1
    RemoteCallToServer("On_Tong_GetADTongList", self.m.nRequestPage)
    --_FakeTongList(self.m.nRequestPage)	
end

function UIPanelTongList:InitTongList()
    local list = self.ScrollViewADTongList
    assert(list)
    --UIHelper.ToggleGroupRemoveAllToggle(self.CellToggleGroup)
    UIHelper.RemoveAllChildren(list)
    self.m.tCellArr                 = {}
    self.m.tTongArr                 = {}
    self.m.tAppliedJoinTongNameDict = {}
    self.m.nRequestPage             = 0

    -- 滚动事件回调	
    list:addEventListener(function(list, nEventType)
        if nEventType == 12 then
            -- AUTOSCROLL_ENDED
            self:CheckRequset()
        end
    end)
end

---@class ADTongInfo 系统随机下发的帮会信息
---@field dwTongID number ID
---@field nCamp number 阵营
---@field szTongName string 名字
---@field szMasterName string 帮主名字
---@field nMemberCount number 帮众数目

---@param tTongArr ADTongInfo[] 帮会信息
function UIPanelTongList:AddTongList(tTongArr)
    local list = self.ScrollViewADTongList
    assert(list)

    local nCount = #self.m.tTongArr + #tTongArr

    if self.bADList then
        -- 仅在帮会列表模式下，刷新对应组件（因为之前的写法，打开页面时会触发请求，若不判断，会导致默认打开推荐帮会时，其没有帮会，但帮会列表有数据的情况下，也把帮会列表刷新出来
        UIHelper.SetVisible(self.WidgetAniMiddle, nCount == 0)
        UIHelper.SetVisible(self.WidgetAnchorFactionListTitle, nCount > 0)
    end

    self.bHasADTongList = nCount > 0
    if nCount == 0 then
        return
    end

    local bNeedScrollToTop = #self.m.tCellArr == 0

    for i, tTong in ipairs(tTongArr) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetFactionList, list)._rootNode
        assert(cell)
        table.insert(self.m.tCellArr, cell)
        table.insert(self.m.tTongArr, tTong)
        self:UpdateCell(cell, tTong)
    end
    UIHelper.ScrollViewDoLayout(list)
    if bNeedScrollToTop then
        UIHelper.ScrollToTop(list, 0, false)
    end

    if not self.m.nSelectIndex then
        self:OnSelectChanged(1)
    end
end

local _tCellFieldNameArr = {
    --"TogFaction",
    --"ImgSchoolIcon",
    "LabelFactionNameSelect",
    "LabelFactionMasterSelect",
    "LabelNumberSelect",
    "BtnApplicationFaction",
    "ImgSeal",
    "ImgCamp"
}
---@param tTong ADTongInfo 帮会信息
function UIPanelTongList:UpdateCell(cell, tTong)
    assert(cell)
    local tCell = {}
    UIHelper.FindNodeByNameArr(cell, tCell, _tCellFieldNameArr)

    UIHelper.SetString(tCell.LabelFactionNameSelect, g2u(tTong.szTongName))
    UIHelper.SetString(tCell.LabelFactionMasterSelect, g2u(tTong.szMasterName))
    UIHelper.SetString(tCell.LabelNumberSelect, tostring(tTong.nMemberCount))

    local bApplied = nil ~= self.m.tAppliedJoinTongNameDict[tTong.szTongName]
    UIHelper.SetVisible(tCell.BtnApplicationFaction, not bApplied)
    UIHelper.SetVisible(tCell.ImgSeal, bApplied)

    CampData.SetUICampImg(tCell.ImgCamp, tTong.nCamp, false, true)

    --UIHelper.ToggleGroupAddToggle(self.CellToggleGroup, tCell.TogFaction)
    local szTongName = tTong.szTongName
    UIHelper.BindUIEvent(tCell.BtnApplicationFaction, EventType.OnClick, function()
        self:ApplyJoinTongByTongName(szTongName)
    end)
end

function UIPanelTongList:Close()
    UIMgr.Close(self)
end

function UIPanelTongList:OnSelectChanged(nSelectIndex)
    local tTong = self.m.tTongArr[nSelectIndex]
    assert(tTong, "invalid select index: " .. nSelectIndex)
    self.m.nSelectIndex = nSelectIndex
    --self:UpdateTongInfo(tTong)
end

function UIPanelTongList:UpdateTongInfo(tTong)
    UIHelper.SetVisible(self.WidgetAniRight, tTong ~= nil)
    UIHelper.SetVisible(self.BtnApplicationFaction, tTong ~= nil)
    if not tTong then return end

    -- local tInfo = GetTongSimpleInfo(tTong.dwTongID)
    -- UIHelper.SetString(self.LabelFactionNameTitle, tTong.szTongName)
    -- UIHelper.SetString(self.LabelFactionGrade, "??") -- 等级
    -- UIHelper.SetString(self.LabelFactionArmorNum, "??") -- 兵甲值
    -- UIHelper.SetString(self.LabelFactionLoveNum, "??") -- 爱心值
    -- UIHelper.SetString(self.LabelFactionRankingNum, "??") -- 战功排名
    -- UIHelper.SetString(self.LabelFactionStrongholdWhether, "??") -- 据点
    -- UIHelper.SetString(self.LabelBriefIntroductionConten, tTong.szDescription) -- 简介

end

function UIPanelTongList:ApplyJoinTongByTongName(szName)
    assert(szName)
    -- if (GetClientPlayer().nLevel < CAN_APPLY_JOIN_LEVEL) then
    -- 	OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.TONG_REQUEST_TOO_LOW)
    -- 	OutputMessage("MSG_SYS", g_tStrings.TONG_REQUEST_TOO_LOW .. "\n")
    -- 	return
    -- end
    self.m.szApplyJoinName = szName
    RemoteCallToServer("On_Tong_ApplyJoinRequest", szName)
end

function UIPanelTongList:ApplyJoinSelectedTong()
    local nSelectIndex = self.m.nSelectIndex
    assert(nSelectIndex)
    local tTong = self.m.tTongArr[nSelectIndex]
    assert(tTong, "invalid select index: " .. nSelectIndex)

    self:ApplyJoinTongByTongName(tTong.szTongName)
end

function UIPanelTongList:UpdateCellByTongName(szName)
    assert(szName)
    for i, tTong in ipairs(self.m.tTongArr) do
        if tTong.szTongName == szName then
            local cell = self.m.tCellArr[i]
            assert(cell)
            self:UpdateCell(cell, tTong)
            break
        end
    end
end

local tTempMapFilter = {
    -- [194] = true, -- 太原
    -- [13] = true, -- 金水镇
    -- [332] = true, -- 侠客岛
}
function UIPanelTongList:ShowTongBookerList(bShow)
    UIHelper.SetVisible(self.WidgetScrollViewTips, bShow)
    if not bShow then return end

    local tNpcMap  = Table_GetNpcTypeInfoMap()
    local nCount   = 0
    local list     = self.ScrollViewActivity
    self.m.tNpcArr = {}
    UIHelper.RemoveAllChildren(list)
    for _, tNpc in pairs(tNpcMap) do
        if not tTempMapFilter[tNpc.dwMapID] then
            for _, v in pairs(tNpc.tNpcList) do
                if v.dwNpcID == 5745 then
                    table.insert(self.m.tNpcArr, v)
                    local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetLeaveForTipsBtn, list)
                    assert(cell)
                    nCount = nCount + 1
                    self:UpdateNpcCell(cell, v, nCount)
                end
            end
        end
    end
    UIHelper.ScrollViewDoLayout(list)
    UIHelper.ScrollToTop(list, 0, false)

end

local _tNpcCellFieldNameArr = {
    "BtnLeaveFor",
    "LableLeaveFor",
}
function UIPanelTongList:UpdateNpcCell(cell, tNpc, nIndex)
    assert(cell)

    local szMapName = g2u(Table_GetMapName(tNpc.dwMapID))
    -- note: 目前帮会登记人 5745 的 szTypeName 可能会有以下两种值，这里直接固定写名字了，不再尝试解析，避免报错
    -- 帮会登记人
    -- 帮会登记人·玄字贰壹
    --local _, _, sz  = string.find(g2u(tNpc.szTypeName), "·(.+)$")
    local sz        = "玄字贰壹"
    sz              = sz .. string.format(" (%s)", szMapName)

    cell:OnEnter(sz)
    UIHelper.BindUIEvent(cell.BtnLeaveFor, EventType.OnClick, function()
        self:OnClickNpcCell(nIndex)
    end)
end

function UIPanelTongList:OnClickNpcCell(nIndex)
    assert(nIndex)
    local tNpc = self.m.tNpcArr[nIndex]
    assert(tNpc, "invalid select index: " .. nIndex)

    -- position
    local arr = string.split(tNpc.szPosition, ";")
    assert(#arr > 0)
    arr = string.split(arr[1], ",")
    assert(#arr >= 2)

    --打开中地图travel	
    MapMgr.SetTracePoint(g2u(tNpc.szTypeName), tNpc.dwMapID, tNpc.tPoint)
    UIMgr.Open(VIEW_ID.PanelMiddleMap, tNpc.dwMapID, 0)

end

function UIPanelTongList:UpdateRunMode()
    RM_UpdateRunMode(self)
end

function UIPanelTongList:RequestTopTenTongList()
    RemoteCallToServer("On_Tong_GetTopTenTongList")
end

---@class TopTenTongInfo 十大推荐帮会信息
---@field dwTongID number ID
---@field nCost number 花费帮会资金
---@field szDescription string 帮会描述
---@field nCamp number 阵营
---@field szTongName string 名字
---@field szMasterName string 帮主名字
---@field nMemberCount number 帮众数目

---@param tTongArr TopTenTongInfo[] 推荐帮会信息
function UIPanelTongList:UpdateTopTenTongInfo(nCount, tTongArr)
    if not self.bADList then
        -- 仅在推荐帮会的模式下更新对应组件
        UIHelper.SetVisible(self.WidgetAniMiddle, nCount == 0)
        UIHelper.SetVisible(self.WidgetAnchorFactionListTitle, nCount > 0)
    end

    UIHelper.RemoveAllChildren(self.ScrollViewTopTenTongList)

    for k, tTong in ipairs(tTongArr) do
        -- note: 由于帮会列表使用该组件时，没有通过绑定脚本的方式进行，因此将这个组件设置为不自动调用初始化函数，并在这里手动调用，从而不影响原来的用法
        ---@type UIFactionList
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFactionList, self.ScrollViewTopTenTongList)
        script:OnEnter(not self.bADList, tTong, false)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTopTenTongList)
end

return UIPanelTongList