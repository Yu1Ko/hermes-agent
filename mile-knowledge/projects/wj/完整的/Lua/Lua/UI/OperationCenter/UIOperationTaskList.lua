-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationTaskList
-- Date: 2026-03-20
-- ---------------------------------------------------------------------------------

local UIOperationTaskList = class("UIOperationTaskList")

-- 一个非常特殊的活动，task不读表，根据任务追踪显示
local QUEST_ITEM_INDEX = 85674
local QUEST_ID = 29083

--------------------------------------------------------
-- 状态枚举
--------------------------------------------------------
UIOperationTaskList.TASK_STATE = {
    NON_GET     = 0,  -- 未领取
    CAN_GET     = 1,  -- 可领取，有特效
    ALREADY_GOT = 2,  -- 已完成，已角色+对勾
}

-- 奖励物品静态模式最大数量（<=3使用静态模式，>3使用滚动模式）
local REWARD_STATIC_MAX = 3

--------------------------------------------------------
-- 生命周期
--------------------------------------------------------
function UIOperationTaskList:OnEnter(nOperationID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID

    self:UpdateInfo()
end

function UIOperationTaskList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationTaskList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTaskList, EventType.OnClick, function(btn)
        if self.fnCallBack then
            self.fnCallBack()
        end
    end)
end

function UIOperationTaskList:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if not self.SelectToggle then
            return
        end
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
        self.SelectToggle = nil
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function()
        if self.nOperationID == 250 then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "QUEST_ACCEPTED", function()
        if self.nOperationID == 250 then
            self:UpdateInfo()
        end
    end)
end

function UIOperationTaskList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

--------------------------------------------------------
-- 自动初始化（从配置表读取）
--------------------------------------------------------
local function GetTaskTitleAndSubtitle(dwOperationID)
    if dwOperationID ~= 250 then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local szTitle    = ""
    local szSubtitle = ""
    local szLink     = ""
    local nCount     = hPlayer.GetItemAmountInPackage(ITEM_TABLE_TYPE.OTHER, QUEST_ITEM_INDEX)
    if hPlayer.GetQuestPhase(QUEST_ID) ~= QUEST_PHASE.UNACCEPT then
        szTitle    = g_tStrings.STR_ACTIVITY_SIGN_IN_TITLE[3][1]
        szSubtitle = g_tStrings.STR_ACTIVITY_SIGN_IN_TITLE[3][2]
        szLink = nil
    elseif nCount > 0 then
        szTitle    = g_tStrings.STR_ACTIVITY_SIGN_IN_TITLE[2][1]
        szSubtitle = g_tStrings.STR_ACTIVITY_SIGN_IN_TITLE[2][2]
        szLink = "PanelLink/OpenBigBagPanel"
    else
        szTitle    = g_tStrings.STR_ACTIVITY_SIGN_IN_TITLE[1][1]
        szSubtitle = g_tStrings.STR_ACTIVITY_SIGN_IN_TITLE[1][2]
        szLink = "PanelLink/OpenMailPanel"
    end
    return szTitle, szSubtitle, szLink
end


function UIOperationTaskList:UpdateInfo()
    local tConfig = OperationSimpleTmplData.GetConfig(self.nOperationID)
    if not tConfig then
        return
    end

    local szTaskTitle = UIHelper.GBKToUTF8(tConfig.szTaskTitle or "")
    local szTaskSubtitle = tConfig.szTaskSubtitle and UIHelper.GBKToUTF8(tConfig.szTaskSubtitle) or ""
    local szTaskReward = tConfig.szTaskReward or ""

    -- 解析奖励字符串 "type_index_count;type_index_count;..."
    local tRewardList = OperationSimpleTmplData.ParseReward(szTaskReward)

    -- 设置任务链接回调
    local szTaskLink = tConfig.szTaskLink or ""
    if szTaskLink ~= "" then
        self:SetfnCallBack(function()
            Event.Dispatch("EVENT_LINK_NOTIFY", szTaskLink)
        end)
    end

    if self.nOperationID == 250 then
        local szTitle, szSubtitle, szLink = GetTaskTitleAndSubtitle(self.nOperationID)
        szTaskTitle = szTitle or ""
        szTaskSubtitle = szSubtitle or ""
        if szLink and szLink ~= "" then
            self:SetfnCallBack(function()
                Event.Dispatch("EVENT_LINK_NOTIFY", szLink)
            end)
        end
    end

    -- 构建 UpdateTaskItem 所需的数据表
    local tTaskData = {
        szTitle    = szTaskTitle,
        szSubtitle = szTaskSubtitle,
        bShowArrow = true,
        tRewards   = tRewardList,
        szBgImg    = tConfig.szvkBgPath or ""
    }

    self:UpdateTaskItem(tTaskData)
end

--------------------------------------------------------
-- 内部工具函数
--------------------------------------------------------

-- 判断是否为 TaskList100 类型（nType=2）
function UIOperationTaskList:IsTaskList100()
    return tonumber(self.nType) == 2
end

-- 统一奖励物品数据格式
local function NormalizeRewardItem(tItem)
    local dwTabType = tItem.dwTabType or tItem[1]
    local dwIndex = tItem.dwIndex or tItem[2]
    local nCount = tItem.nCount or tItem[3]
    return dwTabType, dwIndex, nCount
end

--------------------------------------------------------
-- 细粒度更新 API
--------------------------------------------------------

-- 更新任务标题（szSubtitle仅100类型有效）
function UIOperationTaskList:UpdateTaskTitle(szTitle, szSubtitle)
    if not szTitle then
        return
    end

    if self:IsTaskList100() then
        UIHelper.SetRichText(self.LabelContent1, szTitle)
        UIHelper.SetRichText(self.LabelContent2, szSubtitle)
        UIHelper.SetVisible(self.LabelContent2, szSubtitle and szSubtitle ~= "")
    else
        UIHelper.SetRichText(self.LabelContent1, szTitle)
    end
end

-- 更新任务进度提示文本
function UIOperationTaskList:UpdateTaskHint(szHintText)
    if szHintText and szHintText ~= "" then
        UIHelper.SetString(self.LabelHint, szHintText)
        UIHelper.SetVisible(self.LabelHint, true)
    else
        UIHelper.SetVisible(self.LabelHint, false)
    end
end

-- 更新任务状态：NON_GET / CAN_GET / ALREADY_GOT
function UIOperationTaskList:UpdateTaskState(nState)
    local bFinish = (nState == self.TASK_STATE.ALREADY_GOT)
    local bGet = (nState == self.TASK_STATE.CAN_GET)

    UIHelper.SetVisible(self.ImgTaskListBgFinish, bFinish)
    UIHelper.SetVisible(self.ImgRewardGet, bGet)
end

-- 更新右上角标签（szMarkTag为nil或""时隐藏）
function UIOperationTaskList:UpdateTaskMark(szMarkFrame)
    if szMarkFrame and szMarkFrame ~= "" then
        -- TODO: 如果有独立的Mark标签节点，在此设置
        UIHelper.SetVisible(self.ImgMark, true)
        UIHelper.SetSpriteFrame(self.ImgMark, szMarkFrame, false)

    else
        UIHelper.SetVisible(self.ImgMark, false)
    end
end

-- 更新右侧箭头可见性
function UIOperationTaskList:UpdateTaskArrow(bShow)
    UIHelper.SetVisible(self.ImgTaskArrow, bShow == true)
end

-- 更新背景
function UIOperationTaskList:UpdateBgImg(szImg)
    if self.ImgTaskListBg and szImg and szImg ~= "" then
        UIHelper.SetSpriteFrame(self.ImgTaskListBg, szImg)
    end
end

--------------------------------------------------------
-- 奖励物品更新 API（仅100类型有效）
--------------------------------------------------------

-- 填充静态模式奖励列表（<=3个奖励）
function UIOperationTaskList:FillStaticRewards(tRewards, tRewardState)
    local hRewardList = self.LayOutRewardItem
    if not hRewardList then
        return
    end

    UIHelper.RemoveAllChildren(hRewardList)
    UIHelper.SetVisible(hRewardList, true)

    for i, tItem in ipairs(tRewards) do
        local dwTabType, dwIndex, nItemCount = NormalizeRewardItem(tItem)
        local tItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, hRewardList)
        local bReceived = tRewardState and tRewardState[i] == true
        if tItemScript then
            tItemScript:OnInitWithTabID(dwTabType, dwIndex, nItemCount)
            tItemScript:SetItemGray(bReceived)
            tItemScript:SetItemReceived(bReceived)
            tItemScript:SetClickCallback(function(nTabType, nTabID)
                if nTabType and nTabID then
                    self.SelectToggle =  tItemScript.ToggleSelect
                    TipsHelper.ShowItemTips(self.WidgetItem, nTabType, nTabID)
                end
                if self.fnRewardClickCallback then
                    self.fnRewardClickCallback(i)
                end
            end)
        end
    end

    UIHelper.LayoutDoLayout(hRewardList)
end

-- 填充滚动模式奖励列表（>3个奖励）
function UIOperationTaskList:FillScrollRewards(tRewards, tRewardState)
    local hScroll = self.WidgetScrollViewRewardListMore
    local hContainer = self.LayOutScrollRewardItem
    if not hScroll or not hContainer then
        return
    end

    UIHelper.RemoveAllChildren(hContainer)
    UIHelper.SetVisible(hScroll, true)

    for i, tItem in ipairs(tRewards) do
        local dwTabType, dwIndex, nItemCount = NormalizeRewardItem(tItem)
        local tItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, hContainer)
        UIHelper.SetAnchorPoint(tItemScript._rootNode, 0, 0)
        local bReceived = tRewardState and tRewardState[i] == true
        if tItemScript then
            tItemScript:OnInitWithTabID(dwTabType, dwIndex, nItemCount)
            tItemScript:SetItemGray(bReceived)
            tItemScript:SetItemReceived(bReceived)
            tItemScript:SetClickCallback(function(nTabType, nTabID)
                if nTabType and nTabID then
                    self.SelectToggle =  tItemScript.ToggleSelect
                    TipsHelper.ShowItemTips(self.WidgetItem, nTabType, nTabID)
                end
                if self.fnRewardClickCallback then
                    self.fnRewardClickCallback(i)
                end
            end)
        end
    end

    UIHelper.ScrollViewDoLayout(hScroll)
end

-- 清除奖励物品
function UIOperationTaskList:ClearRewardItems()
    -- 清除静态奖励列表
    if self.LayOutRewardItem then
        UIHelper.RemoveAllChildren(self.LayOutRewardItem)
        UIHelper.SetVisible(self.LayOutRewardItem, false)
    end

    -- 清除滚动奖励列表
    if self.WidgetScrollViewRewardListMore then
        UIHelper.SetVisible(self.WidgetScrollViewRewardListMore, false)
    end
    if self.LayOutScrollRewardItem then
        UIHelper.RemoveAllChildren(self.LayOutScrollRewardItem)
    end
end

-- 更新奖励物品（自动选择静态/滚动模式）
-- tRewards: {{dwTabType, dwIndex, nCount}, ...} 或 {{dwTabType=x, dwIndex=y, nCount=z}, ...}
-- tRewardState: {[1]=true, [2]=false, ...}  true=已领取状态
function UIOperationTaskList:UpdateRewardItems(tRewards, tRewardState)
    if not tRewards or #tRewards == 0 then
        self:ClearRewardItems()
        return
    end

    local nCount = #tRewards
    if nCount <= REWARD_STATIC_MAX then
        -- <=3个奖励，使用静态模式
        if self.WidgetScrollViewRewardListMore then
            UIHelper.SetVisible(self.WidgetScrollViewRewardListMore, false)
        end
        self:FillStaticRewards(tRewards, tRewardState)
    else
        -- >3个奖励，使用滚动模式
        if self.LayOutRewardItem then
            UIHelper.SetVisible(self.LayOutRewardItem, false)
        end
        self:FillScrollRewards(tRewards, tRewardState)
    end
end

-- 获取奖励点击信息（返回奖励索引）
function UIOperationTaskList:GetRewardClickInfo(nRewardIndex)
    if nRewardIndex then
        return {nRewardIndex = nRewardIndex}
    end
    return nil
end

--------------------------------------------------------
-- 一键更新 API
--------------------------------------------------------

-- tTaskData = {
--     szTitle       = "标题",            -- 任务标题
--     szSubtitle    = "副标题",          -- 可选，仅100类型有效
--     szHintText    = "进度 0/2",        -- 可选，右下角进度文本
--     nTaskState    = TASK_STATE.XXX,    -- 可选，默认 NON_GET
--     szMarkFrame     = "角标",            -- 可选，右上角标签
--     bShowArrow    = true,              -- 可选，是否显示箭头
--     tRewards      = {...},              -- 可选，奖励列表，仅100类型有效
--     tRewardState  = {[1]=true, ...},   -- 可选，奖励领取状态
--     szBgImg       = "UIAtlas2_Public_PublicButton_PublicNavigation_ContentListFather100_Light.png" --默认是这个 task的背景
-- }
function UIOperationTaskList:UpdateTaskItem(tTaskData)
    if not tTaskData then
        return
    end

    self:UpdateTaskTitle(tTaskData.szTitle, tTaskData.szSubtitle)
    self:UpdateTaskHint(tTaskData.szHintText)
    self:UpdateTaskState(tTaskData.nTaskState or self.TASK_STATE.NON_GET)
    self:UpdateTaskMark(tTaskData.szMarkFrame)
    self:UpdateTaskArrow(tTaskData.bShowArrow)
    self:UpdateBgImg(tTaskData.szBgImg)

    if tTaskData.tRewards and #tTaskData.tRewards > 0 then
        self:UpdateRewardItems(tTaskData.tRewards, tTaskData.tRewardState)
    else
        self:ClearRewardItems()
    end
end

--------------------------------------------------------
-- 回调设置
--------------------------------------------------------

-- 设置任务项点击回调
function UIOperationTaskList:SetfnCallBack(fnCallBack)
    self.fnCallBack = fnCallBack
end

-- 设置奖励物品点击回调
function UIOperationTaskList:SetRewardClickCallback(fnCallback)
    self.fnRewardClickCallback = fnCallback
end

return UIOperationTaskList
