-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravel
-- Date: 2024-11-21 11:06:16
-- Desc: 侠客出行
-- Prefab: WidgetPartnerTravel
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravel
local UIPartnerTravel          = class("UIPartnerTravel")

local REMOTE_HERO_TRAVEL_DATA  = 1174    --侠客出行数据信息，配套修改scripts/Include/UIscript/UIscript_HeroTravel.lua
local REMOTE_HERO_TRAVEL_CLASS = 1175    --侠客出行大类信息，配套修改scripts/Include/UIscript/UIscript_HeroTravel.lua

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravel:_LuaBindList()
    self.tWidgetTravelList         = self.tWidgetTravelList --- 左侧出行牌子的挂载点列表

    self.tWidgetTravelQuestList    = self.tWidgetTravelQuestList --- 右侧未出行时的可选任务类型的挂载点列表

    self.WidgetPartnerTravelTarget = self.WidgetPartnerTravelTarget --- 任务类型列表的上层节点
    self.WidgetPartnerTravelInfo   = self.WidgetPartnerTravelInfo --- 某个任务类型具体信息的上层节点

    self.LabelTravelInfoName       = self.LabelTravelInfoName --- 名称
    self.BtnChange                 = self.BtnChange --- 切换为类别列表
    self.LayoutReward              = self.LayoutReward --- 奖励列表
    self.LayoutTravelInfoList      = self.LayoutTravelInfoList --- 出行事件列表
    self.BtnAllReward              = self.BtnAllReward --- 一键领奖按钮
    self.BtnAllTravel              = self.BtnAllTravel --- 再次派遣按钮
    self.BtnAllReset               = self.BtnAllReset --- 全部重置按钮
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravel:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravel:OnEnter()
    self.nCurrentBoard  = nil

    ---@type table<number, UIPartnerTravelListTog>
    self.tBoardToScript = {}

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    --- 请求下必要的数据
    if not g_pClientPlayer.HaveRemoteData(REMOTE_HERO_TRAVEL_DATA) then
        g_pClientPlayer.ApplyRemoteData(REMOTE_HERO_TRAVEL_DATA)
    end
    if not g_pClientPlayer.HaveRemoteData(REMOTE_HERO_TRAVEL_CLASS) then
        g_pClientPlayer.ApplyRemoteData(REMOTE_HERO_TRAVEL_CLASS)
    end

    self:UpdateInfo()
    
    Timer.AddCycle(self, 0.1, function() 
        self:UpdateBtnState()
    end)
end

function UIPartnerTravel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function()
        -- 仅在没有已出行，或者待领奖的配置时，允许切换目标
        local bInTravelOrFinished = PartnerData.IsBoardInTravelOrFinished(self.nCurrentBoard)
        if bInTravelOrFinished then
            TipsHelper.ShowNormalTip("当前已有出行事件，无法切换")
            return
        end

        -- 切换时清除数据
        self:ClearTravelOnChange()

        self.nCurrentClass = nil

        self:ShowAllQuestTypeList()

        -- 空牌子切换为类别列表时，取消左侧的预览状态
        local scriptBoard = self.tBoardToScript[self.nCurrentBoard]
        scriptBoard:SetClass(nil)
    end)
    
    UIHelper.BindUIEvent(self.BtnAllReset, EventType.OnClick, function()
        -- 仅在没有已出行，或者待领奖的配置时，允许切换目标
        local bInTravelOrFinished = PartnerData.IsBoardInTravelOrFinished(self.nCurrentBoard)
        if bInTravelOrFinished then
            TipsHelper.ShowNormalTip("当前已有出行事件，无法重置")
            return
        end

        -- 切换时清除数据
        self:ClearTravelOnChange()
    end)

    UIHelper.BindUIEvent(self.BtnAllReward, EventType.OnClick, function()
        self:TakeAllReward()
    end)

    UIHelper.BindUIEvent(self.BtnAllTravel, EventType.OnClick, function()
        self:AllTravelWithLastConfig()
    end)
end

function UIPartnerTravel:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelPartnerTravelSetting or nViewID == VIEW_ID.PanelPartnerTravelInfoPop then
            -- todo: 等有派遣成功的远程回调后，也要刷新下
            Timer.Add(self, 0.5, function()
                self:UpdateQuestInfoList()
            end)
        end
    end)

    Event.Reg(self, "REMOTE_HERO_TRAVEL_DATA_EVENT", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "REMOTE_HERO_TRAVEL_CLASS_EVENT", function()
        self:UpdateInfo()
    end)
end

function UIPartnerTravel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTravel:UpdateInfo()
    local tBoardToInfoList    = GDAPI_HeroTravelGetAllInfo()

    local bHasAnyUnlocked     = false

    -- 勾选第一个有可领取奖励的牌子，若无，则选中第一个
    local nDefaultSelectBoard = self.nCurrentBoard

    -- 展示牌子列表
    for nBoard, tInfoList in pairs(tBoardToInfoList) do
        local widgetTravel = self.tWidgetTravelList[nBoard]
        UIHelper.RemoveAllChildren(widgetTravel)
        ---@type UIPartnerTravelListTog
        local script                = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelListTog, widgetTravel, nBoard)

        self.tBoardToScript[nBoard] = script

        UIHelper.BindUIEvent(script.ToggleTravel, EventType.OnClick, function()
            self.nCurrentClass = PartnerData.GetBoardTravelQuestClass(nBoard)
            self:ShowBoardInfo(nBoard)

            self:UpdateBoardInfoTitleList()
        end)

        local tBoardInfo = Table_GetPartnerTravelTeamInfo(nBoard)
        if tBoardInfo.dwQuestID == -1 then
            -- 如果设置为-1，直接隐藏挂载点
            UIHelper.SetVisible(widgetTravel, false)
        end

        local bUnlocked = PartnerData.IsTravelBoardUnlocked(nBoard)
        if bUnlocked then
            bHasAnyUnlocked = true

            for nQuestIndex, tQuestInfo in ipairs(tInfoList) do
                local nQuestState, nQuest      = PartnerData.ParseTravelQuestInfo(tQuestInfo)

                local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
                local bInTravel                = nQuestState == PartnerTravelState.InTravel
                local bFinished                = nQuestState == PartnerTravelState.Finished
                local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

                -- 若有可领取奖励，则修改为该值
                if bFinished and nDefaultSelectBoard == nil then
                    nDefaultSelectBoard = nBoard
                end
            end
        end
    end

    if nDefaultSelectBoard == nil then
        nDefaultSelectBoard = 1
    end

    -- 默认选中一个牌子，并展示其信息
    for nBoard, tInfoList in pairs(tBoardToInfoList) do
        local script        = self.tBoardToScript[nBoard]

        local bShouldSelect = nBoard == nDefaultSelectBoard
        UIHelper.SetSelected(script.ToggleTravel, bShouldSelect)
        if bShouldSelect then
            self:ShowBoardInfo(nBoard)
        end
    end

    if not bHasAnyUnlocked then
        UIHelper.SetVisible(self.WidgetPartnerTravelTarget, false)
        UIHelper.SetVisible(self.WidgetPartnerTravelInfo, false)
    end
end

function UIPartnerTravel:ShowBoardInfo(nBoard)
    self.nCurrentBoard       = nBoard

    local nCurrentQuestClass = self.nCurrentClass or PartnerData.GetBoardTravelQuestClass(self.nCurrentBoard)

    if nCurrentQuestClass == nil then
        self:ShowAllQuestTypeList()
    else
        self:ShowCurrentQuestType(nCurrentQuestClass)
    end
end

--- 展示可选的出行事件类型
function UIPartnerTravel:ShowAllQuestTypeList()
    UIHelper.SetVisible(self.WidgetPartnerTravelTarget, true)
    UIHelper.SetVisible(self.WidgetPartnerTravelInfo, false)

    local tClassList = PartnerData.GetPartnerTravelClassList()
    for nIndex, nClass in ipairs(tClassList) do
        local widgetQuest = self.tWidgetTravelQuestList[nIndex]

        UIHelper.RemoveAllChildren(widgetQuest)
        ---@type UIPartnerTravelTargetCell
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelTargetCell, widgetQuest, nClass)

        UIHelper.BindUIEvent(script.BtnQuest, EventType.OnClick, function()
            self:ShowCurrentQuestType(nClass)
        end)
    end
end

--- 切换为预览出行事件类别信息的界面
function UIPartnerTravel:ShowCurrentQuestType(nClass)
    local tClassInfo = Table_GetPartnerTravelClass(nClass)

    UIHelper.SetVisible(self.WidgetPartnerTravelTarget, false)
    UIHelper.SetVisible(self.WidgetPartnerTravelInfo, true)

    local scriptBoard = self.tBoardToScript[self.nCurrentBoard]
    scriptBoard:SetClass(nClass)

    UIHelper.SetString(self.LabelTravelInfoName, UIHelper.GBKToUTF8(tClassInfo.szClassName))

    -- 奖励信息
    UIHelper.RemoveAllChildren(self.LayoutReward)

    local tRewardList = PartnerData.GetItemRewardList(tClassInfo.szGiftItem)
    for _, tReward in ipairs(tRewardList) do
        ---@type UIItemIcon
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, self.LayoutReward)
        script:OnInitWithTabID(tReward.dwType, tReward.dwIndex)
        script:SetLabelCount(tReward.nCount)
        script:SetClickNotSelected(true)
        script:SetClickCallback(function(dwItemTabType, dwItemTabIndex)
            TipsHelper.ShowItemTips(script._rootNode, tReward.dwType, tReward.dwIndex)
        end)
    end

    UIHelper.LayoutDoLayout(self.LayoutReward)

    self.nCurrentClass = nClass
    self:UpdateQuestInfoList()
end

function UIPartnerTravel:UpdateQuestInfoList()
    UIHelper.RemoveAllChildren(self.LayoutTravelInfoList)

    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()
    local tQuestInfoList   = tBoardToInfoList[self.nCurrentBoard]

    for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
        ---@type UIPartnerTravelInfoListCell
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerTravelInfoListCell, self.LayoutTravelInfoList, tQuestInfo, self.nCurrentBoard, nQuestIndex, self.nCurrentClass)
    end
    
    self:UpdateBtnState()
end

function UIPartnerTravel:UpdateBtnState()
    local tCanTravelAgainList = self:GetCanTravelAgainList()
    UIHelper.SetButtonState(self.BtnAllTravel, #tCanTravelAgainList > 0 and BTN_STATE.Normal or BTN_STATE.Disable)

    local tCanTakeRewardList = self:CanTakeRewardList()
    UIHelper.SetButtonState(self.BtnAllReward, #tCanTakeRewardList > 0 and BTN_STATE.Normal or BTN_STATE.Disable)
    
    local bHasNoConfig = PartnerData.GetBoardTravelQuestClass(self.nCurrentBoard) == nil
    UIHelper.SetVisible(self.BtnAllReset, not bHasNoConfig)
end

function UIPartnerTravel:TakeAllReward()
    local tCanTakeRewardList = self:CanTakeRewardList()

    LOG.TABLE({
                  "DEBUG: 本地测试 一键领奖",
                  tCanTakeRewardList,
              })
    if #tCanTakeRewardList > 0 then
        UIHelper.RemoteCallToServer("On_Hero_FinishTravel", tCanTakeRewardList)
    end
end

function UIPartnerTravel:CanTakeRewardList()
    local tCanTakeRewardList = {}

    local tBoardToInfoList   = GDAPI_HeroTravelGetAllInfo()
    local tQuestInfoList     = tBoardToInfoList[self.nCurrentBoard]

    for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
        local nQuestState              = PartnerData.ParseTravelQuestInfo(tQuestInfo)

        local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
        local bInTravel                = nQuestState == PartnerTravelState.InTravel
        local bFinished                = nQuestState == PartnerTravelState.Finished
        local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

        if bFinished then
            table.insert(tCanTakeRewardList, { self.nCurrentBoard, nQuestIndex })
        end
    end

    return tCanTakeRewardList
end

function UIPartnerTravel:AllTravelWithLastConfig()
    local tCanTravelAgainList = self:GetCanTravelAgainList()

    LOG.TABLE({
                  "DEBUG: 本地测试 再次派遣",
                  tCanTravelAgainList,
              })
    if #tCanTravelAgainList > 0 then
        if not self:CheckTravelCost(tCanTravelAgainList) then
            return
        end

        UIHelper.RemoteCallToServer("On_Hero_StartTravel", tCanTravelAgainList)
    end
end

function UIPartnerTravel:GetCanTravelAgainList()
    local tCanTravelAgainList = {}

    local tBoardToInfoList    = GDAPI_HeroTravelGetAllInfo()
    local tQuestInfoList      = tBoardToInfoList[self.nCurrentBoard]

    for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
        local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.ParseTravelQuestInfo(tQuestInfo)

        local bNotHasConfig                                   = nQuestState == PartnerTravelState.NotHasConfig
        local bInTravel                                       = nQuestState == PartnerTravelState.InTravel
        local bFinished                                       = nQuestState == PartnerTravelState.Finished
        local bKeepConfigAfterFinished                        = nQuestState == PartnerTravelState.KeepConfigAfterFinished

        if bKeepConfigAfterFinished then
            table.insert(tCanTravelAgainList, { self.nCurrentBoard, nQuestIndex, nQuest, tHeroList })
        end
    end

    return tCanTravelAgainList
end

function UIPartnerTravel:UpdateBoardInfoTitleList()
    --- 由于牌子选择class预览时，名字会变化，若未实际设置，跳转到其他牌子时应该变回来，这里做下处理
    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()

    for nBoard, tInfoList in pairs(tBoardToInfoList) do
        local script = self.tBoardToScript[nBoard]

        local nClass = PartnerData.GetBoardTravelQuestClass(nBoard)
        script:SetClass(nClass)
    end
end

function UIPartnerTravel:CheckTravelCost(tTravelList)
    local tQuestIdList = {}
    for _, tTravel in ipairs(tTravelList) do
        local nQuest     = tTravel[3]
        
        table.insert(tQuestIdList, nQuest)
    end

    return PartnerData.CheckTravelCost(tQuestIdList)
end

function UIPartnerTravel:ClearTravelOnChange()
    local tClearList       = {}

    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()
    local tQuestInfoList   = tBoardToInfoList[self.nCurrentBoard]

    for nIndex, tQuestInfo in ipairs(tQuestInfoList) do
        local nQuestState, nQuest      = PartnerData.ParseTravelQuestInfo(tQuestInfo)

        local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
        local bInTravel                = nQuestState == PartnerTravelState.InTravel
        local bFinished                = nQuestState == PartnerTravelState.Finished
        local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

        if bKeepConfigAfterFinished then
            table.insert(tClearList, {
                self.nCurrentBoard, nIndex,
            })
        end
    end

    if table.get_len(tClearList) > 0 then
        LOG.TABLE({
                      "本地调试日志：清除数据",
                      tClearList
                  })

        UIHelper.RemoteCallToServer("On_Hero_ClearTravel", tClearList)
    end
end

return UIPartnerTravel