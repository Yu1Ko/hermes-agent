-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelNew
-- Date: 2025-01-07 10:33:29
-- Desc: 侠客出行首页 新版
-- Prefab: WidgetPartnerTravel
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelNew
local UIPartnerTravelNew       = class("UIPartnerTravelNew")

local REMOTE_HERO_TRAVEL_DATA  = 1174    --侠客出行数据信息，配套修改scripts/Include/UIscript/UIscript_HeroTravel.lua
local REMOTE_HERO_TRAVEL_CLASS = 1175    --侠客出行大类信息，配套修改scripts/Include/UIscript/UIscript_HeroTravel.lua

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelNew:_LuaBindList()
    self.tWidgetTravelInfoList          = self.tWidgetTravelInfoList --- 出行信息的挂载点列表
    self.WidgetTravelInfoLocked         = self.WidgetTravelInfoLocked --- 未解锁信息的挂载点

    self.widgetCardInfoAnchor           = self.widgetCardInfoAnchor --- 右侧出行事件的具体信息组件的挂载点

    self.BtnBack                        = self.BtnBack --- 退出右侧出行信息页面模式

    self.ImgBgMap                       = self.ImgBgMap --- 背景的地图
    self.WidgetTravelInfoListAnchor     = self.WidgetTravelInfoListAnchor --- 槽位列表的上层挂载点

    self.BtnAllReward                   = self.BtnAllReward --- 一键领奖
    self.BtnAllTravel                   = self.BtnAllTravel --- 一键再次委托
    self.BtnAllReset                    = self.BtnAllReset --- 全部重置

    self.BtnFilter                      = self.BtnFilter --- 筛选按钮

    self.LabelUnlockedSlotUsedInfo      = self.LabelUnlockedSlotUsedInfo --- 当前已解锁的槽位的使用情况

    self.BtnExitTravelRightSidePageView = self.BtnExitTravelRightSidePageView --- 全屏遮罩，用于点击空白时退出右侧信息页面模式
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelNew:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param uiPartnerView UIPartnerView
function UIPartnerTravelNew:OnEnter(MiniScene, uiPartnerView)
    self.MiniScene                        = MiniScene
    self.uiPartnerView                    = uiPartnerView

    -- 记录下最初的x坐标，方便后续进行偏移操作
    self.BaseX_ImgBgMap                   = UIHelper.GetPositionX(self.ImgBgMap)
    self.BaseX_WidgetTravelInfoListAnchor = UIHelper.GetPositionX(self.WidgetTravelInfoListAnchor)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        PartnerData.InitFilterDef_TravelSlot()
    end

    --- 请求下必要的数据
    self.bRequestTravelData  = false
    self.bRequestTravelClass = false
    if not g_pClientPlayer.HaveRemoteData(REMOTE_HERO_TRAVEL_DATA) then
        self.bRequestTravelData = true
        g_pClientPlayer.ApplyRemoteData(REMOTE_HERO_TRAVEL_DATA)
    end
    if not g_pClientPlayer.HaveRemoteData(REMOTE_HERO_TRAVEL_CLASS) then
        self.bRequestTravelClass = true
        g_pClientPlayer.ApplyRemoteData(REMOTE_HERO_TRAVEL_CLASS)
    end

    self:UpdateInfo()

    self:SwitchTravelRightSidePageView(false)

    Timer.AddCycle(self, 0.1, function()
        self:UpdateBtnState()
    end)

    self:TryUpdateTravelPetTryCount()
end

function UIPartnerTravelNew:OnExit()
    self.bInit = false

    self:CleanUpModelView()

    self:UnRegEvent()
end

function UIPartnerTravelNew:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        self:SwitchTravelRightSidePageView(false)
    end)

    UIHelper.BindUIEvent(self.BtnExitTravelRightSidePageView, EventType.OnClick, function()
        self:SwitchTravelRightSidePageView(false)
    end)

    UIHelper.BindUIEvent(self.BtnAllReward, EventType.OnClick, function()
        self:TakeAllReward()
    end)

    UIHelper.BindUIEvent(self.BtnAllTravel, EventType.OnClick, function()
        self:AllTravelWithLastConfig()
    end)

    UIHelper.BindUIEvent(self.BtnAllReset, EventType.OnClick, function()
        self:ResetAllKeepConfigSlots()
    end)

    UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.BOTTOM_LEFT, FilterDef.PartnerTravelSlot)
    end)
end

function UIPartnerTravelNew:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, "REMOTE_HERO_TRAVEL_DATA_EVENT", function()
        self:OnTravelDataChange()
    end)

    Event.Reg(self, "REMOTE_HERO_TRAVEL_CLASS_EVENT", function()
        self:OnTravelDataChange()
    end)

    Event.Reg(self, "On_Partner_StartTravelCallBack", function(bSuccess)
        if bSuccess then
            TipsHelper.ShowNormalTip("侠客出行成功")
        end
    end)

    Event.Reg(self, EventType.OnGetAdventurePetTryBook, function(tPetTryMap)
        for nAdvID, nTryTime in pairs(tPetTryMap) do
            PartnerData.UpdatePetTryTime(nAdvID, nTryTime)
        end
    end)

    Event.Reg(self, "PartnerTravel_AfterTakeReward", function()
        self:TryUpdateTravelPetTryCount()
    end)
end

function UIPartnerTravelNew:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTravelNew:UpdateInfo()
    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()

    -- 先重置全部节点
    for _, tWidgetTravelInfo in ipairs(self.tWidgetTravelInfoList) do
        UIHelper.RemoveAllChildren(tWidgetTravelInfo)
    end

    --- 是否有尚未解锁的已开放牌子
    local bHasLockedOpenBoard = false

    local nCurrentTravelIndex = 0

    -- 展示牌子列表
    for nBoard, tInfoList in pairs(tBoardToInfoList) do
        local tBoardInfo = Table_GetPartnerTravelTeamInfo(nBoard)
        if tBoardInfo.dwQuestID == -1 then
            --- 任务设置为-1的牌子表示尚未开放，不做处理
        else
            local bUnlocked = PartnerData.IsTravelBoardUnlocked(nBoard)

            if bUnlocked then
                -- 仅显示已解锁的牌子所对应的槽位
                for nQuestIndex, tQuestInfo in ipairs(tInfoList) do
                    nCurrentTravelIndex     = nCurrentTravelIndex + 1

                    local tWidgetTravelInfo = self.tWidgetTravelInfoList[nCurrentTravelIndex]
                    ---@see UIPartnerTravelTargetCellNew#OnEnter
                    UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelTargetCell, tWidgetTravelInfo, nBoard, nQuestIndex, self, nCurrentTravelIndex, nil)
                end
            else
                bHasLockedOpenBoard = true
            end
        end
    end

    -- 显示未解锁的信息
    UIHelper.SetVisible(self.WidgetTravelInfoLocked, bHasLockedOpenBoard)
    if bHasLockedOpenBoard then
        UIHelper.RemoveAllChildren(self.WidgetTravelInfoLocked)
        ---@see UIPartnerTravelTargetCellNew#OnEnter
        UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelTargetCell, self.WidgetTravelInfoLocked, nil, nil, self, nil, true)
    end

    self:UpdateBtnState()

    self:UpdateUnlockedSlotUsedInfo()

    self:UpdateMiniScene()
end

--- 切换到出行事件右侧页面模式（隐藏导航栏和右下角按钮，右上角变成返回）
function UIPartnerTravelNew:SwitchTravelRightSidePageView(bEnter, nTravelIndex)
    UIHelper.SetVisible(self.uiPartnerView.WidgetAniBottom, not bEnter)
    UIHelper.SetVisible(self.uiPartnerView.BtnClose, not bEnter)

    UIHelper.SetVisible(self.BtnBack, bEnter)
    UIHelper.SetVisible(self.BtnExitTravelRightSidePageView, bEnter)

    if not bEnter then
        UIHelper.RemoveAllChildren(self.widgetCardInfoAnchor)
        Event.Dispatch("PartnerTravel_UnSelectAllSlot")
    end

    -- 选中右侧会被侧边栏遮挡的几个出行按钮的时候，按钮和地图需要做个偏移
    local tRightIndexList = { 8, 10, 11, 13}
    local bMoveToLeft = bEnter and table.contain_value(tRightIndexList, nTravelIndex)
    if bMoveToLeft then
        UIHelper.SetPositionX(self.ImgBgMap, self.BaseX_ImgBgMap - 500)
        UIHelper.SetPositionX(self.WidgetTravelInfoListAnchor, self.BaseX_WidgetTravelInfoListAnchor - 500)
    else
        UIHelper.SetPositionX(self.ImgBgMap, self.BaseX_ImgBgMap)
        UIHelper.SetPositionX(self.WidgetTravelInfoListAnchor, self.BaseX_WidgetTravelInfoListAnchor)
    end

    self:UpdateBtnState()
end

function UIPartnerTravelNew:UpdateBtnState()
    local tCanTravelAgainList = self:GetCanTravelAgainList()
    UIHelper.SetButtonState(self.BtnAllTravel, #tCanTravelAgainList > 0 and BTN_STATE.Normal or BTN_STATE.Disable)

    local tCanTakeRewardList = self:CanTakeRewardList()
    UIHelper.SetButtonState(self.BtnAllReward, #tCanTakeRewardList > 0 and BTN_STATE.Normal or BTN_STATE.Disable)

    local tAllKeepConfigList = self:GetAllKeepConfigList()
    UIHelper.SetButtonState(self.BtnAllReset, #tAllKeepConfigList > 0 and BTN_STATE.Normal or BTN_STATE.Disable)

    local bHasAnyConfig  = self:HasAnyConfig()
    local bRightPageShow = UIHelper.GetChildrenCount(self.widgetCardInfoAnchor) > 0

    local bShowBtn       = bHasAnyConfig and not bRightPageShow
    UIHelper.SetVisible(self.BtnAllTravel, bShowBtn)
    UIHelper.SetVisible(self.BtnAllReward, bShowBtn)
    UIHelper.SetVisible(self.BtnAllReset, bShowBtn)
end

function UIPartnerTravelNew:GetCanTravelAgainList()
    local tCanTravelAgainList = {}
    -- 当前出行事件类别第几次出现（方便确保不超出大类次数）
    local tClassDataIndexShowCount = {}

    local tBoardToInfoList    = GDAPI_HeroTravelGetAllInfo()
    for nBoard, tQuestInfoList in pairs(tBoardToInfoList) do
        for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
            local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.ParseTravelQuestInfo(tQuestInfo)

            local bNotHasConfig                                   = nQuestState == PartnerTravelState.NotHasConfig
            local bInTravel                                       = nQuestState == PartnerTravelState.InTravel
            local bFinished                                       = nQuestState == PartnerTravelState.Finished
            local bKeepConfigAfterFinished                        = nQuestState == PartnerTravelState.KeepConfigAfterFinished

            if bKeepConfigAfterFinished then
                local bCanTravelAgain         = true
                
                local tQuest                  = Table_GetPartnerTravelTask(nQuest)

                if not tClassDataIndexShowCount[tQuest.nDataIndex] then
                    tClassDataIndexShowCount[tQuest.nDataIndex] = 0
                end
                tClassDataIndexShowCount[tQuest.nDataIndex] = tClassDataIndexShowCount[tQuest.nDataIndex] + 1

                -- 检查大类次数
                local nTravelCount, nMaxCount = GDAPI_HeroTravelGetClassCount(tQuest.nDataIndex)
                if nTravelCount + tClassDataIndexShowCount[tQuest.nDataIndex] - 1 >= nMaxCount then
                    bCanTravelAgain = false
                end

                -- 检查宠物尝试次数
                if tQuest.dwAdventureID > 0 then
                    local tTryInfo = PartnerData.tPetAdvIdToTryInfo[tQuest.dwAdventureID]
                    if tTryInfo and tTryInfo.nHasTry >= tTryInfo.nTryMax then
                        bCanTravelAgain = false
                    end
                end

                -- 检查是否已经已触发
                if PartnerData.IsTravelQuestTriggered(tQuest) then
                    bCanTravelAgain = false
                end

                if bCanTravelAgain then
                    table.insert(tCanTravelAgainList, { nBoard, nQuestIndex, nQuest, tHeroList })
                end
            end
        end
    end

    return tCanTravelAgainList
end

function UIPartnerTravelNew:GetAllKeepConfigList()
    local tAllKeepConfigList = {}

    local tBoardToInfoList   = GDAPI_HeroTravelGetAllInfo()
    for nBoard, tQuestInfoList in pairs(tBoardToInfoList) do
        for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
            local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.ParseTravelQuestInfo(tQuestInfo)

            local bNotHasConfig                                   = nQuestState == PartnerTravelState.NotHasConfig
            local bInTravel                                       = nQuestState == PartnerTravelState.InTravel
            local bFinished                                       = nQuestState == PartnerTravelState.Finished
            local bKeepConfigAfterFinished                        = nQuestState == PartnerTravelState.KeepConfigAfterFinished

            if bKeepConfigAfterFinished then
                table.insert(tAllKeepConfigList, { nBoard, nQuestIndex })
            end
        end
    end

    return tAllKeepConfigList
end

function UIPartnerTravelNew:CanTakeRewardList()
    local tCanTakeRewardList = {}

    local tBoardToInfoList   = GDAPI_HeroTravelGetAllInfo()
    for nBoard, tQuestInfoList in pairs(tBoardToInfoList) do
        for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
            local nQuestState              = PartnerData.ParseTravelQuestInfo(tQuestInfo)

            local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
            local bInTravel                = nQuestState == PartnerTravelState.InTravel
            local bFinished                = nQuestState == PartnerTravelState.Finished
            local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

            if bFinished then
                table.insert(tCanTakeRewardList, { nBoard, nQuestIndex })
            end
        end
    end

    return tCanTakeRewardList
end

function UIPartnerTravelNew:HasAnyConfig()
    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()
    for nBoard, tQuestInfoList in pairs(tBoardToInfoList) do
        for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
            local nQuestState              = PartnerData.ParseTravelQuestInfo(tQuestInfo)

            local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
            local bInTravel                = nQuestState == PartnerTravelState.InTravel
            local bFinished                = nQuestState == PartnerTravelState.Finished
            local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

            if not bNotHasConfig then
                return true
            end
        end
    end

    return false
end

function UIPartnerTravelNew:TakeAllReward()
    local tCanTakeRewardList = self:CanTakeRewardList()

    if #tCanTakeRewardList > 0 then
        UIHelper.RemoteCallToServer("On_Hero_FinishTravel", tCanTakeRewardList)
    end
end

function UIPartnerTravelNew:AllTravelWithLastConfig()
    local tCanTravelAgainList = self:GetCanTravelAgainList()

    if #tCanTravelAgainList > 0 then
        if not self:CheckTravelCost(tCanTravelAgainList) then
            return
        end

        PartnerData.TravelAgain(tCanTravelAgainList)
    end
end

function UIPartnerTravelNew:CheckTravelCost(tTravelList)
    local tQuestIdList = {}
    for _, tTravel in ipairs(tTravelList) do
        local nQuest = tTravel[3]

        table.insert(tQuestIdList, nQuest)
    end

    return PartnerData.CheckTravelCost(tQuestIdList)
end

function UIPartnerTravelNew:ResetAllKeepConfigSlots()
    local tAllKeepConfigList = self:GetAllKeepConfigList()
    if table.get_len(tAllKeepConfigList) > 0 then
        UIHelper.RemoteCallToServer("On_Hero_ClearTravel", tAllKeepConfigList)
    end
end

function UIPartnerTravelNew:UpdateUnlockedSlotUsedInfo()
    local nUsedCount       = 0
    local nMaxCount        = 0

    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()
    for nBoard, tQuestInfoList in pairs(tBoardToInfoList) do
        local bUnlocked = PartnerData.IsTravelBoardUnlocked(nBoard)
        if bUnlocked then
            nMaxCount = nMaxCount + table.get_len(tQuestInfoList)

            for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
                local nQuestState, nQuest      = PartnerData.ParseTravelQuestInfo(tQuestInfo)

                local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
                local bInTravel                = nQuestState == PartnerTravelState.InTravel
                local bFinished                = nQuestState == PartnerTravelState.Finished
                local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

                if bInTravel or bFinished then
                    nUsedCount = nUsedCount + 1
                end
            end
        end
    end

    local szCountInfo = string.format("侠客出行限制：%d/%d", nUsedCount, nMaxCount)
    UIHelper.SetString(self.LabelUnlockedSlotUsedInfo, szCountInfo)
end

function UIPartnerTravelNew:OnTravelDataChange()
    self:UpdateUnlockedSlotUsedInfo()

    if self.bRequestTravelData then
        self.bRequestTravelData = false
        self:UpdateInfo()
    end
    if self.bRequestTravelClass then
        self.bRequestTravelClass = false
        self:UpdateInfo()
    end
end

function UIPartnerTravelNew:UpdateMiniScene()
    -- 初始化 model view
    local hModelView = self.hModelView

    if PartnerData.bNotMgrSceneByNpcModelView and not self.m_scene then
        self.m_scene = PartnerData.GetOrCreateScene()
    end

    if not hModelView then
        hModelView = NpcModelView.CreateInstance(NpcModelView)
        hModelView:ctor()
        hModelView:init(self.m_scene, PartnerData.bNotMgrSceneByNpcModelView, true, PartnerData.szSceneFilePath, "PartnerTravel")
        self.MiniScene:SetScene(hModelView.m_scene)

        -- 确保三个model view都使用同一个场景实例
        self.m_scene    = hModelView.m_scene

        self.hModelView = hModelView
    end

    -- 不论是否加载模型，都要确保镜头参数位置一样
    hModelView:SetCamera(Const.MiniScene.PartnerView.tbMainCamera)
end

function UIPartnerTravelNew:CleanUpModelView()
    if self.hModelView then
        self.hModelView:release()
        self.hModelView = nil
    end

    self.m_scene = nil
end

function UIPartnerTravelNew:TryUpdateTravelPetTryCount()
    --- 确保宠物尝试数据获取到，方便判断是否可以一键再次委托
    local tPetTryList      = {}

    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()
    for nBoard, tQuestInfoList in pairs(tBoardToInfoList) do
        for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
            local nQuestState, nQuest      = PartnerData.ParseTravelQuestInfo(tQuestInfo)

            local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
            local bInTravel                = nQuestState == PartnerTravelState.InTravel
            local bFinished                = nQuestState == PartnerTravelState.Finished
            local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

            if not bNotHasConfig then
                local tInfo = Table_GetPartnerTravelTask(nQuest)
                if tInfo.dwAdventureID ~= 0 then
                    table.insert(tPetTryList, tInfo.dwAdventureID)
                end
            end
        end
    end

    if table.get_len(tPetTryList) > 0 then
        RemoteCallToServer("On_QiYu_PetTryList", tPetTryList)
    end
end

return UIPartnerTravelNew