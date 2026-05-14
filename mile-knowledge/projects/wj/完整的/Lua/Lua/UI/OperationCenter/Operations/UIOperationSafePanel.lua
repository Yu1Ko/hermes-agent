-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationSafePanel
-- Date: 2026-03-29 22:29:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationSafePanel = class("UIOperationSafePanel")

local MARK_FRAME = {
    ADVANCED = "UIAtlas2_OperationCenter_Safe_img_gj.png", -- 高级
    BASIC    = "UIAtlas2_OperationCenter_Safe_img_jc.png", -- 基础
    APP      = "UIAtlas2_OperationCenter_Safe_img_tl.png", -- 推栏
    WEIBO    = "UIAtlas2_OperationCenter_Safe_img_wb.png", -- 微博
    WECHAT   = "UIAtlas2_OperationCenter_Safe_img_wx.png", -- 微信
}

-- nMarkFrame 表值 → 帧名映射
local MARK_FRAME_BY_INDEX = {
    [0] = MARK_FRAME.ADVANCED,
    [1] = MARK_FRAME.BASIC,
    [2] = MARK_FRAME.APP,
    [3] = MARK_FRAME.WEIBO,
    [4] = MARK_FRAME.WECHAT,
}

-- ----------------------------------------------------------
-- 安全项函数定义 (fnCheck / fnCheckOtherBound / fnAction)
-- 静态数据（标题/奖励/标签等）从 SafePanelInfo.txt 读取
-- ----------------------------------------------------------
local SAFE_ITEM_FUNCS = {
    email = {
        fnCheck = function() return ServiceCenterData:IsEMailBind() end,
        fnAction = function() UIHelper.OpenWebWithDefaultBrowser(tUrl.EmailBind) end,
    },
    phone = {
        fnCheck = function() return ServiceCenterData:IsPhoneBind() end,
        fnAction = function() UIHelper.OpenWebWithDefaultBrowser(tUrl.MobileBind) end,
    },
    safelock = {
        fnCheck = function() return ServiceCenterData:IsSafeLockBind() end,
        fnAction = function() UIMgr.Open(VIEW_ID.PanelSetPasswordPop) end,
    },
    passpod_phone = {
        fnCheck = function() return ServiceCenterData:GetMibaoMode() == PASSPOD_MODE.PHONE end,
        fnCheckOtherBound = function()
            local n = ServiceCenterData:GetMibaoMode()
            return n == PASSPOD_MODE.TOKEN or n == PASSPOD_MODE.MATRIX
        end,
        fnAction = function() UIHelper.OpenWebWithDefaultBrowser(tUrl.ShoujibanCard) end,
    },
    wx_service = {
        fnCheck = function()
            local hPlayer = GetClientPlayer()
            return hPlayer and hPlayer.GetSNSBindFlag(SNS_BIND_TYPE.FOLLOW_WECHAT_JX3_SERVICE_ACCOUNT)
        end,
        fnAction = function() UIHelper.OpenWeb(tUrl.WeiXinServer) end,
    },
    wx_subscribe = {
        fnCheck = function()
            local hPlayer = GetClientPlayer()
            return hPlayer and hPlayer.GetSNSBindFlag(SNS_BIND_TYPE.FOLLOW_WECHAT_JX3_SUBSCRIPTION_ACCOUNT)
        end,
        fnAction = function() UIHelper.OpenWeb(tUrl.WeiXinDetail) end,
    },
    wx_manager = {
        fnCheck = function()
            local hPlayer = GetClientPlayer()
            return hPlayer and hPlayer.GetSNSBindFlag(SNS_BIND_TYPE.BIND_JX3_WECHAT_MANAGER)
        end,
        fnAction = function()
            UIHelper.OpenWeb(tUrl.WeiXinManager)
            -- 关闭微信管理红点
            -- if SafePanel then
            --     SafePanel.bShowMgrWeChatRedPoint = false
            -- end
        end,
    },
    sina_weibo = {
        fnCheck = function()
            return OperationSafeData.IsSinaBind()
        end,
        fnAction = function()
            local bBind = OperationSafeData.IsSinaBind()
            if bBind then
                UIHelper.ShowConfirm(
                    FormatString(g_tStrings.tWeiBo.UNBING, g_tStrings.WEI_BO_S_NAME),
                    function() GetClientPlayer().UnbindWeibo(WEIBO_TYPE.SINA) end,
                    function() end
                )
            else
                OperationSafeData.sns_enter_openurl()
            end
        end,
    },
    jx3_app = {
        fnCheck = function()
            local hPlayer = GetClientPlayer()
            return hPlayer and hPlayer.GetSNSBindFlag(SNS_BIND_TYPE.BIND_JX3_ASSISTANT_APP)
        end,
        fnAction = function() UIHelper.OpenWeb(tUrl.JX3APPBind) end,
    },
}

------------------------------------------------------------
-- 从 SafePanelInfo.txt 读取项目数据
------------------------------------------------------------
local SAFE_ITEMS = nil

local function BuildSafeItems()
    if SAFE_ITEMS then
        return
    end
    local tRows = Table_GetSafePanelInfo()
    SAFE_ITEMS = {}
    for _, tLine in ipairs(tRows) do
        local tFuncs = SAFE_ITEM_FUNCS[tLine.szKey] or {}
        local tItem = {
            nTab        = tLine.nTab,
            szKey       = tLine.szKey,
            szTitle     = tLine.szDsc,
            bShowMark   = tLine.bShowMark == 1,
            szMarkFrame = MARK_FRAME_BY_INDEX[tLine.nMarkFrame],
            tRewards    = tLine.tRewards,
            fnCheck           = tFuncs.fnCheck,
            fnCheckOtherBound = tFuncs.fnCheckOtherBound,
            fnAction          = tFuncs.fnAction,
        }
        table.insert(SAFE_ITEMS, tItem)
    end
end

------------------------------------------------------------
-- 任务状态枚举 (与 UIOperationTaskList.TASK_STATE 保持一致)
------------------------------------------------------------
local TASK_STATE = {
    NON_GET     = 0,  -- 未领取
    CAN_GET     = 1,  -- 可领取
    ALREADY_GOT = 2,  -- 已完成
}

------------------------------------------------------------
-- 获取项目状态
-- 返回: (bBound, nTaskState)
------------------------------------------------------------
local function GetItemState(tItemDef)
    local bBound = tItemDef.fnCheck and tItemDef.fnCheck()
    if bBound then
        return true, TASK_STATE.ALREADY_GOT
    end
    -- 如果其他密保方式已绑定，则该项目不可领取
    if tItemDef.fnCheckOtherBound and tItemDef.fnCheckOtherBound() then
        return false, TASK_STATE.NON_GET
    end
    return false, TASK_STATE.CAN_GET
end

------------------------------------------------------------
-- 判断是否应显示箭头和可执行操作
------------------------------------------------------------
local function IsActionable(tItemDef, nTaskState)
    if nTaskState == TASK_STATE.NON_GET then
        return false
    end
    local szKey = tItemDef.szKey
    -- 邮箱/手机/安全锁未绑时才可操作
    if szKey == "email" or szKey == "phone" or szKey == "safelock" then
        return nTaskState == TASK_STATE.CAN_GET
    end
    -- 社交平台绑定后也应该不可操作
    return nTaskState == TASK_STATE.CAN_GET
end

------------------------------------------------------------
-- 执行绑定动作
------------------------------------------------------------
local function ExecuteAction(tItemDef, bBound)
    if tItemDef.fnAction then
        tItemDef.fnAction()
    end
end

------------------------------------------------------------
-- 判断基础安全是否完成: 邮箱 + 手机 + 安全锁
------------------------------------------------------------
local function IsBasicComplete()
    return ServiceCenterData:IsEMailBind() and ServiceCenterData:IsPhoneBind() and ServiceCenterData:IsSafeLockBind()
end

------------------------------------------------------------
-- 判断高级安全是否完成: 基础安全 + 密保手机/密保卡/将军令
------------------------------------------------------------
local function IsAdvancedComplete()
    if not IsBasicComplete() then
        return false
    end
    local n = ServiceCenterData:GetMibaoMode()
    return n == PASSPOD_MODE.PHONE or n == PASSPOD_MODE.TOKEN or n == PASSPOD_MODE.MATRIX
end

------------------------------------------------------------
-- 获取当前Tab的项目数据
------------------------------------------------------------
local function GetCurrentSafeItems(nTab)
    if not SAFE_ITEMS then
        BuildSafeItems()
    end
    local tResult = {}
    for _, tItem in ipairs(SAFE_ITEMS) do
        if tItem.nTab == nTab then
            table.insert(tResult, tItem)
        end
    end
    return tResult
end


function UIOperationSafePanel:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    local tScriptTop = tComponentContext and tComponentContext.tScriptLayoutTop
    self.scriptContentTitleTog = tScriptTop and tScriptTop[1] --WidgetContentTitleTog100's script

    if self.scriptContentTitleTog then
        self.scriptContentTitleTog:SetToggleSelectCallback(function(nIndex)
            self:OnTabChanged(nIndex)
        end)
    end

    -- 初始化Tab状态
    self.m_nActiveTab = 1

    self:UpdateInfo()
end

function UIOperationSafePanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationSafePanel:BindUIEvent()
end

function UIOperationSafePanel:RegEvent()
end

function UIOperationSafePanel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

------------------------------------------------------------
-- 刷新任务列表
------------------------------------------------------------
function UIOperationSafePanel:RefreshList()
    if not self.scriptContentTitleTog or not self.scriptContentTitleTog.tScriptTaskList then
        return
    end

    local tTaskList = self.scriptContentTitleTog.tScriptTaskList
    local tSafeItems = GetCurrentSafeItems(self.m_nActiveTab)

    if not tSafeItems then
        return
    end

    -- 已完成(ALREADY_GOT)的置底，其余保持原顺序
    local tSorted = {}
    local tDone = {}
    for _, tItemDef in ipairs(tSafeItems) do
        local _, nTaskState = GetItemState(tItemDef)
        if nTaskState == TASK_STATE.ALREADY_GOT then
            table.insert(tDone, tItemDef)
        else
            table.insert(tSorted, tItemDef)
        end
    end
    for _, tItemDef in ipairs(tDone) do
        table.insert(tSorted, tItemDef)
    end

    for nIndex, tItemDef in ipairs(tSorted) do
        local scriptTask = tTaskList[nIndex]
        if scriptTask then
            local bBound, nTaskState = GetItemState(tItemDef)
            local bActionable = IsActionable(tItemDef, nTaskState)

            local tRewardState = {}
            for i in ipairs(tItemDef.tRewards) do
                tRewardState[i] = nTaskState == TASK_STATE.ALREADY_GOT
            end

            scriptTask:UpdateTaskItem({
                szTitle = UIHelper.GBKToUTF8(tItemDef.szTitle) or "",
                szHintText = UIHelper.GBKToUTF8(tItemDef.szHintText) or "",
                nTaskState = nTaskState,
                bShowMark = tItemDef.bShowMark,
                szMarkFrame = tItemDef.bShowMark and tItemDef.szMarkFrame or "",
                bShowArrow = bActionable and true or false,
                tRewards = tItemDef.tRewards,
                tRewardState = tRewardState
            })

            -- 隐藏领取按钮
            UIHelper.SetVisible(scriptTask.ImgRewardGet, false)

            -- 设置点击回调
            scriptTask:SetfnCallBack(function()
                local bItemBound, nItemState = GetItemState(tItemDef)
                if IsActionable(tItemDef, nItemState) then
                    ExecuteAction(tItemDef, bItemBound)
                end
            end)

            -- 显示任务单元
            UIHelper.SetVisible(scriptTask._rootNode, true)
        end
    end

    -- 隐藏多余的TaskList单元
    for i = #tSorted + 1, #tTaskList do
        if tTaskList[i] then
            UIHelper.SetVisible(tTaskList[i]._rootNode, false)
        end
    end

    UIHelper.SetVisible(self.scriptNone._rootNode, self.m_nActiveTab ~= 1)
    UIHelper.SetVisible(self.scriptSafeReward._rootNode, self.m_nActiveTab == 1)
    --UIHelper.SetVisible(self.scriptLabelContent._rootNode, self.m_nActiveTab == 1)
    UIHelper.LayoutDoLayout(self.scriptContentTitleTog.LayoutContentTopWide)
end

------------------------------------------------------------
-- Tab切换处理
------------------------------------------------------------
function UIOperationSafePanel:OnTabChanged(nTab)
    self.m_nActiveTab = nTab
    self:RefreshList()
end

------------------------------------------------------------
-- 刷新安全奖励显示
------------------------------------------------------------
function UIOperationSafePanel:RefreshReward()
    if not self.scriptSafeReward then
        return
    end

    local bBasicComplete = IsBasicComplete()
    local bAdvancedComplete = IsAdvancedComplete()

    -- BtnSafeReward1: 基础安全奖励
    if self.scriptSafeReward.BtnSafeReward1 then
        UIHelper.SetVisible(self.scriptSafeReward.BtnSafeReward1, true)
        -- 根据是否完成显示不同状态
        UIHelper.SetVisible(self.scriptSafeReward.WidgetGot1, bBasicComplete)
    end

    -- BtnSafeReward2: 高级安全奖励
    if self.scriptSafeReward.BtnSafeReward2 then
        UIHelper.SetVisible(self.scriptSafeReward.BtnSafeReward2, true)
        -- 根据是否完成显示不同状态
        UIHelper.SetVisible(self.scriptSafeReward.WidgetGot2, bAdvancedComplete)
    end
end

------------------------------------------------------------
-- 刷新全部
------------------------------------------------------------
function UIOperationSafePanel:RefreshAll()
    self:RefreshList()
    self:RefreshReward()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationSafePanel:UpdateInfo()
    -- 添加描述文本
    -- self.scriptLabelContent = UIHelper.AddPrefab(PREFAB_ID.WidgetLabelContent, self.scriptContentTitleTog.LayoutContentTopWide, self.nOperationID, self.nID)
    -- UIHelper.SetLocalZOrder(self.scriptLabelContent._rootNode, -1)
    -- self.scriptLabelContent:UpdateInfo("操作完成后, 需要重新登录游戏才能获得奖励")

    self.scriptNone = UIHelper.AddPrefab(PREFAB_ID.WidgetNon, self.scriptContentTitleTog.LayoutContentTopWide)
    UIHelper.SetLocalZOrder(self.scriptNone._rootNode, -1)

    -- 添加安全奖励模块
    self.scriptSafeReward = UIHelper.AddPrefab(PREFAB_ID.WidgetSafeReward, self.scriptContentTitleTog.LayoutContentTopWide, self.nOperationID, self.nID)
    UIHelper.SetLocalZOrder(self.scriptSafeReward._rootNode, -1)
    UIHelper.SetAnchorPoint(self.scriptSafeReward._rootNode, 0, 0.5)

    -- 刷新任务列表和奖励状态
    self:RefreshAll()

    UIHelper.LayoutDoLayout(self.scriptContentTitleTog.LayoutContentTopWide)
end


return UIOperationSafePanel