-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSeasonLevelReward
-- Date: 2026-03-12 15:51:15
-- Desc: ?
-- ---------------------------------------------------------------------------------
local CHECK_STATE = {
    CAN_GET = 1,
    NOT_REACH = 0,
    ALREADY_GET = 2,
    REACH_CANT_GET = 3,
}

local CLASS2PAGE = {
    [1] = COLLECTION_PAGE_TYPE.SECRET,
    [2] = COLLECTION_PAGE_TYPE.CAMP,
    [3] = COLLECTION_PAGE_TYPE.ATHLETICS,
    [4] = COLLECTION_PAGE_TYPE.ATHLETICS,
    [5] = COLLECTION_PAGE_TYPE.ATHLETICS,
    [6] = COLLECTION_PAGE_TYPE.REST,
    [7] = COLLECTION_PAGE_TYPE.REST,
}

local LEVEL2REWARDNUM = {
    [1] = 3,
    [2] = 3,
    [3] = 3,
    [4] = 1,
    [5] = 3,
    [6] = 1,
    [7] = 3,
    [8] = 3,
    [9] = 1,
    [10] = 3,
    [11] = 3,
    [12] = 3,
    [13] = 3,
    [14] = 1,
    [15] = 1,
    [16] = 3,
}

local UIWidgetSeasonLevelReward = class("UIWidgetSeasonLevelReward")

function UIWidgetSeasonLevelReward:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end
function UIWidgetSeasonLevelReward:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSeasonLevelReward:BindUIEvent()
    -- self:BindDirectionalLock(self.ScrollViewRewardTitleList)

    UIHelper.BindUIEvent(self.ScrollViewRewardTitleList, EventType.OnScrollingScrollView, function(_, eventType)
        self:RefreshPreviewByScroll()
        self:SyncScrollViews(self.ScrollViewRewardTitleList)
    end)


    UIHelper.BindUIEvent(self.BtnGetAll, EventType.OnClick, function()
        RemoteCallToServer("On_SA_GetAllReward")
    end)
end

function UIWidgetSeasonLevelReward:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTip()
    end)

    Event.Reg(self, "OnUpdateSimpleReward", function(tSendList)
        if tSendList and tSendList.tItem then
            local tNewInfo = {}
            for _, tItem in ipairs(tSendList.tItem) do
                local tData = {}
                tData.nTabType = tItem[1]
                tData.nTabID = tItem[2]
                tData.nCount = tItem[3]
                table.insert(tNewInfo, tData)
            end
            TipsHelper.ShowRewardList(tNewInfo)
        end
        -- self:RefreshRewardState()
    end)

    Event.Reg(self, "CB_SA_TaskUpdate", function()
        self:RefreshRewardState()
    end)
    
    Event.Reg(self, "CB_SA_SetPersonReward", function()
        self:RefreshRewardState()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 5, function ()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSeasonTypeFinishList)
        end)
    end)
end

function UIWidgetSeasonLevelReward:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetSeasonLevelReward:SyncScrollViews(sourceScrollView)
    if self.bIsSyncingScroll then return end
    self.bIsSyncingScroll = true
    
    local sourceX, sourceY = UIHelper.GetScrolledPosition(sourceScrollView)
    
    for _, scrollView in ipairs(self.tbSyncScrollViews or {}) do
        if scrollView ~= sourceScrollView then
            local targetX, targetY = UIHelper.GetScrolledPosition(scrollView)
            if targetX ~= sourceX then
                if scrollView.stopAutoScroll then
                    scrollView:stopAutoScroll()
                end
                UIHelper.SetScrolledPosition(scrollView, sourceX, targetY)
            end
        end
    end
    
    self.bIsSyncingScroll = false
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSeasonLevelReward:UpdateInfo()
    self:UpdateRewardList()
    self:UpdateFinishedCheck()
    self:UpdatePreviewRewardImg()
    self:UpdateBtnAllState()
end


function UIWidgetSeasonLevelReward:UpdateBtnAllState()
    local bHasReward = CollectionData.AllSeasonLevelHasCanGet()
    UIHelper.SetEnable(self.BtnGetAll, bHasReward)
    UIHelper.SetNodeGray(self.BtnGetAll, not bHasReward, true)

end

local function FormatRankInfo(tSourceInfo)
    local tbFormattedInfo = {}
    local tbRankMap = {}

    for _, tbInfo in ipairs(tSourceInfo) do
        local szRankName = tbInfo.szRankFullName
        local nImageFrame = tbInfo.nImageFrame
        
        if not tbRankMap[szRankName] then
            local tbNewGroup = {
                szRankName = szRankName,
                nImageFrame = nImageFrame,
                tbRankPointList = {},
            }
            table.insert(tbFormattedInfo, tbNewGroup)
            tbRankMap[szRankName] = #tbFormattedInfo
        end
        
        local nGroupIndex = tbRankMap[szRankName]
        table.insert(tbFormattedInfo[nGroupIndex].tbRankPointList, {
            nRankPoint = tbInfo.nRankPoint,
            nRankLv = tbInfo.nRankLv, 
        })
    end
    
    return tbFormattedInfo
end

function UIWidgetSeasonLevelReward:UpdateRewardList()
    UIHelper.RemoveAllChildren(self.ScrollViewRewardTitleList)
    self.tbCellList = {}
    self.tbRewardListWidths = {}
    self.tbRewardCellScripts = {}
    self.tbRewardItemScripts = {}
    local tRankInfo = Table_GetRankInfo()
    tRankInfo = FormatRankInfo(tRankInfo)

    for i, tRank in ipairs(tRankInfo) do
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonRankRewardList, self.ScrollViewRewardTitleList)
        UIHelper.SetAnchorPoint(tbScript._rootNode, 0, 0)
        local nWidth = self:UpdateRewardCellList(tbScript, tRank)
        local tbFontColor = RANK_FONTCOLOR[tRank.nImageFrame]
        table.insert(self.tbRewardListWidths, nWidth)

        for i, tbItem in ipairs(tRank.tbRankPointList) do
            local szLevel = UIHelper.GBKToUTF8(tRank.szRankName)
            local nRankLv = tbItem.nRankLv
            local nRankPoint = tbItem.nRankPoint
            local tbItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonRankRewardCell, tbScript.LayOutImgRankBg)
            self.tbRewardCellScripts[nRankLv] = tbItemScript
            local tbRewardInfo = CollectionData.GetLevelRewardListByLevel(nRankLv)
            -- if nRankPoint > 0 then
            --     szLevel = szLevel .. string.format("%s段", UIHelper.NumberToChinese(nRankPoint))
            -- end
            self:UpdateRewardCell(tbItemScript, tbRewardInfo, szLevel, tbFontColor, nRankLv)
            local tbPreviewItemInfo = {
                szLevel = szLevel,
                tbItemList = tbRewardInfo.reward,
                nImageFrame = tRank.nImageFrame
            }
            table.insert(self.tbCellList, { node = tbItemScript._rootNode, data = tbPreviewItemInfo })
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewRewardTitleList)
    UIHelper.ScrollToLeft(self.ScrollViewRewardTitleList)


    self:RefreshPreviewByScroll()
end

function UIWidgetSeasonLevelReward:UpdateRewardCellList(tbScript, tbRank)
    local nImageFrame  = tbRank.nImageFrame
    local tbBgColor = RANK_BGCOLOR[nImageFrame]
    local nCount = table.get_len(tbRank.tbRankPointList)
    local ImgSeasonLevelBg = nCount == 1 and tbScript.ImgSeasonLevelBgOne or tbScript.ImgSeasonLevelBgTwo
    local nWidth = UIHelper.GetWidth(ImgSeasonLevelBg)
    UIHelper.SetSpriteFrame(tbScript.ImgSeasonLevelMark, RANK_IMG[nImageFrame], false)
    UIHelper.SetWidth(tbScript._rootNode, nWidth)
    UIHelper.WidgetFoceDoAlignAssignNode(tbScript, ImgSeasonLevelBg)
    UIHelper.SetVisible(ImgSeasonLevelBg, true)
    UIHelper.SetColor(ImgSeasonLevelBg, cc.c3b(tbBgColor[1], tbBgColor[2], tbBgColor[3]))
    UIHelper.WidgetFoceDoAlignAssignNode(tbScript, tbScript.LayOutImgRankBg)
    UIHelper.WidgetFoceDoAlignAssignNode(tbScript, tbScript.ImgSeasonLevelMark)
    return nWidth
end

function UIWidgetSeasonLevelReward:UpdateRewardCell(tbItemScript, tbRewardInfo, szLevel, tbFontColor, nRankLv)
    local score = tbRewardInfo.score
    local reward = tbRewardInfo.reward


    local nRewardNum = self:GetLevelRewardNum(nRankLv)
    local nTotalNum = LEVEL2REWARDNUM[nRankLv] or 3
    local bAllGot = nRewardNum >= nTotalNum
    UIHelper.SetString(tbItemScript.LabelSeasonRewardinfo, nRankLv > 1 and string.format("已领 %d/%d", nRewardNum, nTotalNum) or "暂无")
    UIHelper.SetString(tbItemScript.LabelSeasonLevelinfo, szLevel)
    UIHelper.SetColor(tbItemScript.LabelSeasonLevelinfo, cc.c3b(tbFontColor[1], tbFontColor[2], tbFontColor[3]))
    self.tbRewardItemScripts[nRankLv] = self.tbRewardItemScripts[nRankLv] or {}
    for i, tbItemData in ipairs(reward) do
        local nTabType = tbItemData[1]
        local nTabID = tbItemData[2]
        local nStackNum = tbItemData[3]
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, tbItemScript.LayoutRewardItemIcon60)
        UIHelper.SetSwallowTouches(script.ToggleSelect, false)
        script:OnInitWithTabID(nTabType, nTabID, nStackNum)
        if script.WidgetGot then
            UIHelper.SetVisible(script.WidgetGot, bAllGot)
        end
        table.insert(self.tbRewardItemScripts[nRankLv], script)
        script:SetClickCallback(function(nTabType, nTabID)
            self:OpenTip(script, nTabType, nTabID)
        end)
        if nStackNum == 1 then
            script:SetLabelCount()
        end
    end
end

function UIWidgetSeasonLevelReward:OpenTip(script, nTabType, nTabID)
    self:CloseTip()
    local tip, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, script._rootNode, TipsLayoutDir.BOTTOM_CENTER)
    scriptItemTip:OnInitWithTabID(nTabType, nTabID)
    scriptItemTip:SetBtnState({})
    self.scriptIcon = script
end

function UIWidgetSeasonLevelReward:CloseTip()
    if self.scriptIcon then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.scriptIcon:RawSetSelected(false)
        self.scriptIcon = nil
    end
end

function UIWidgetSeasonLevelReward:RefreshPreviewByScroll()
    if not self.tbCellList or #self.tbCellList == 0 then return end
        
    local sizeSV = self.ScrollViewRewardTitleList:getContentSize()
    local widthSV = sizeSV.width
    local nLastVisibleIdx = 1

    for i, info in ipairs(self.tbCellList) do
        local node = info.node
        -- 将节点位置转换为滑动容器的本地坐标体系
        local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local localPos = self.ScrollViewRewardTitleList:convertToNodeSpace(worldPos)
        -- local parent = UIHelper.GetParent(UIHelper.GetParent(node))
        local sizeNode = node:getContentSize()
        local nWidth = sizeNode.width
        
        -- 判断当前cell的左边缘是否在可视范围内
        if localPos.x - nWidth / 2 <= widthSV then
            nLastVisibleIdx = i
        else
            break
        end
    end

    -- 获取下一个cell的索引（如果已是最后一个则保持最后一个）
    local nNextIdx = math.min(nLastVisibleIdx + 1, #self.tbCellList)
    local targetData = self.tbCellList[nNextIdx].data

    -- 避免重复刷新相同的数据
    if self.tbCurrentPreviewData == targetData then
        return
    end
    self.tbCurrentPreviewData = targetData

    self:UpdatePreviewUI(targetData)
end

function UIWidgetSeasonLevelReward:UpdatePreviewUI(tbItem)
    if not tbItem then return end

    self:CloseTip()

    local tbBgColor = RANK_BGCOLOR[tbItem.nImageFrame]
    local tbFontColor = RANK_FONTCOLOR[tbItem.nImageFrame]
    UIHelper.SetColor(self.ImgBgNew, cc.c3b(tbBgColor[1], tbBgColor[2], tbBgColor[3]))
    UIHelper.SetString(self.LabelSeasonLevelinfo, tbItem.szLevel)
    UIHelper.SetColor(self.LabelSeasonLevelinfo, cc.c3b(tbFontColor[1], tbFontColor[2], tbFontColor[3]))
    UIHelper.SetSpriteFrame(self.ImgSeasonLevelMark, RANK_IMG[tbItem.nImageFrame], false)
    UIHelper.RemoveAllChildren(self.LayoutRewardItemIcon60)

    for _, tbItemData in ipairs(tbItem.tbItemList) do
        local nTabType = tbItemData[1]
        local nTabID = tbItemData[2]
        local nStackNum = tbItemData[3]
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutRewardItemIcon60)
        script:SetToggleSwallowTouches(true)
        script:OnInitWithTabID(nTabType, nTabID, nStackNum)
        script:SetClickCallback(function(nClickTabType, nClickTabID)
            self:OpenTip(script, nClickTabType, nClickTabID)
        end)
        if nStackNum == 1 then
            script:SetLabelCount()
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutRewardItemIcon60)
end

function UIWidgetSeasonLevelReward:UpdateFinishedCheck()
    UIHelper.RemoveAllChildren(self.ScrollViewSeasonTypeFinishList)
    UIHelper.SetScrollViewCombinedBatchEnabled(self.ScrollViewSeasonTypeFinishList, false)
    self.tbSyncScrollViews = {self.ScrollViewRewardTitleList}
    self.tbCheckCellScripts = {} 
    self.tbHorizontalScrollViews = {}
    local nTargetClassIndex = nil
    local nTargetRankGroupIndex = nil

    local tbLevelList = CollectionData.GetRankInfo()
    for i, tbLevelInfo in ipairs(tbLevelList) do
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetFinishedChecklis, self.ScrollViewSeasonTypeFinishList)
        if tbScript then
            local bShowBg = i <= 3
            local nClass = tbLevelInfo.nClass
            self.tbCheckCellScripts[nClass] = {}
            local szImgPath = CLASS_IMG[nClass]
            local tbLevelScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonLevelBtn, tbScript.WidgetSeasonLevelBtn)
            self:UpdateLevelBtn(tbLevelScript, tbLevelInfo)
            UIHelper.SetSwallowTouches(tbLevelScript._rootNode, false)
            UIHelper.SetSpriteFrame(tbScript.ImgTypeTitle, szImgPath)
            UIHelper.SetVisible(tbScript.ImgTypeTitleLight, bShowBg)
            
            table.insert(self.tbSyncScrollViews, tbScript.ScrollViewFinishedChecklis)
            table.insert(self.tbHorizontalScrollViews, tbScript.ScrollViewFinishedChecklis)
            UIHelper.SetScrollRightMouseEnable(tbScript.ScrollViewFinishedChecklis, false)
    --         -- 为每个生成的横向 ScrollView 绑定方向锁
            self:BindDirectionalLock(tbScript.ScrollViewFinishedChecklis)
            UIHelper.BindUIEvent(tbScript.ScrollViewFinishedChecklis, EventType.OnScrollingScrollView, function(_, eventType)
                self:SyncScrollViews(tbScript.ScrollViewFinishedChecklis)
            end)

            UIHelper.BindUIEvent(tbScript.BtnLink, EventType.OnClick, function()
                if CLASS2PAGE[nClass] == COLLECTION_PAGE_TYPE.CAMP and g_pClientPlayer.nCamp == CAMP.NEUTRAL then
                    UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
                else
                    UIMgr.Close(VIEW_ID.PanelSeasonLevel)
                    CollectionData.LinkToCardByID(CLASS2PAGE[nClass])
                end
            end)

            UIHelper.BindUIEvent(tbScript.BtnLink, EventType.OnTouchBegan, function()
                self:StopAllScrollInertia(tbScript.ScrollViewFinishedChecklis)
                self:ResetDirectionalLock(tbScript.ScrollViewFinishedChecklis)
            end)

            local tRankInfo = GDAPI_SA_GetAllRankBaseInfo()
            local tClassInfo = tRankInfo[nClass]
            local tGroupedList = self:FormatStateList(tClassInfo.tList)
            for k, v in ipairs(tGroupedList) do
                local tbItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetLayoutFinishedChecklis, tbScript.ScrollViewFinishedChecklis)
                if tbItemScript then
                    if self.tbRewardListWidths and self.tbRewardListWidths[k] then
                        UIHelper.SetWidth(tbItemScript._rootNode, self.tbRewardListWidths[k])
                        UIHelper.WidgetFoceDoAlignAssignNode(tbItemScript, tbItemScript.WidgetLayoutFinish)
                        UIHelper.WidgetFoceDoAlignAssignNode(tbItemScript, tbItemScript.LayoutFinish)
                    end
                    self:UpdateCheckCellState(v, tbItemScript, nClass)
                end

                for _, stateItem in ipairs(v) do
                    if stateItem.nState == CHECK_STATE.CAN_GET then
                        if not nTargetRankGroupIndex or k < nTargetRankGroupIndex then
                            nTargetClassIndex = i
                            nTargetRankGroupIndex = k
                        end
                        break
                    end
                end
            end
            UIHelper.ScrollViewDoLayout(tbScript.ScrollViewFinishedChecklis)
        end

    end
    if nTargetClassIndex and nTargetRankGroupIndex then
        UIHelper.ScrollViewDoLayout(self.ScrollViewSeasonTypeFinishList)
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollToIndex(self.ScrollViewSeasonTypeFinishList, nTargetClassIndex - 1, 0)
            UIHelper.ScrollToIndex(self.ScrollViewRewardTitleList, nTargetRankGroupIndex - 1, 0)
            for _, sv in ipairs(self.tbHorizontalScrollViews or {}) do
                UIHelper.ScrollToIndex(sv, nTargetRankGroupIndex - 1, 0)
            end
        end)
    else
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSeasonTypeFinishList)
    end
end

-- 添加一个核心的方向锁函数
function UIWidgetSeasonLevelReward:BindDirectionalLock(horizontalScrollView)
    UIHelper.BindUIEvent(horizontalScrollView, EventType.OnTouchBegan, function(sender, x, y)
        self:StopAllScrollInertia(sender)
        self:ResetDirectionalLock(sender)
        self.scrollStartPos = { x = x, y = y }
    end)

    UIHelper.BindUIEvent(horizontalScrollView, EventType.OnTouchMoved, function(sender, x, y)
        if not self.scrollStartPos or self.bScrollDirLocked then
            return
        end

        local dx = math.abs(x - self.scrollStartPos.x)
        local dy = math.abs(y - self.scrollStartPos.y)
        if dx > dy then
            -- 横向手势：停掉纵向惯性
            self:StopScrollInertia(self.ScrollViewSeasonTypeFinishList)
            UIHelper.SetScrollEnabled(self.ScrollViewSeasonTypeFinishList, false)
        else
            -- 纵向手势：停掉当前横向惯性
            self:StopScrollInertia(sender)
            UIHelper.SetScrollEnabled(sender, false)
        end
        if dx > 5 or dy > 5 then
            self.bScrollDirLocked = true
            self.lockedScrollView = sender
            if dx > dy then
                UIHelper.SetScrollEnabled(self.ScrollViewSeasonTypeFinishList, false)
            else
                UIHelper.SetScrollEnabled(sender, false)
            end
        end
    end)

    local function onTouchEndOrCancel(sender)
        self:ResetDirectionalLock(sender)
    end
    UIHelper.BindUIEvent(horizontalScrollView, EventType.OnTouchEnded, onTouchEndOrCancel)
    UIHelper.BindUIEvent(horizontalScrollView, EventType.OnTouchCancelled, onTouchEndOrCancel)
end

function UIWidgetSeasonLevelReward:UpdateCheckCellState(tbStateList, parentScript, nClass)
    if not tbStateList or not parentScript then
        return
    end

    local bHasValidCell = false

    for i, v in ipairs(tbStateList) do
        local nState = v.nState
        local nRankLv = v.nRankLv
            
        if CHECK_STATE.NOT_REACH ~= nState or bHasValidCell then 
            bHasValidCell = true
            local tbCellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetLayoutFinishedChecklisCell, parentScript.LayoutFinish)
            
            if self.tbCheckCellScripts and self.tbCheckCellScripts[nClass] then
                self.tbCheckCellScripts[nClass][nRankLv] = tbCellScript
            end

            local bCanGet = (nState == CHECK_STATE.CAN_GET)
            local bAlreadyGet = (nState == CHECK_STATE.ALREADY_GET)
            local bReachCantGet = (nState == CHECK_STATE.REACH_CANT_GET)

            UIHelper.SetVisible(tbCellScript.BtnGet, bCanGet)
            UIHelper.SetVisible(tbCellScript.imgFinish, bAlreadyGet)
            UIHelper.SetVisible(tbCellScript.imgFinishGet, bReachCantGet)

            if bCanGet then
                UIHelper.SetSwallowTouches(tbCellScript.BtnGet, false)
                UIHelper.BindUIEvent(tbCellScript.BtnGet, EventType.OnClick, function()
                    RemoteCallToServer("On_SA_GetReward", nClass, nRankLv)
                end)
            end
        end
    end

    if bHasValidCell then
        UIHelper.SetVisible(parentScript.WidgetNon, false)
        UIHelper.SetVisible(parentScript.WidgetLayoutFinish, true)
    else
        UIHelper.SetVisible(parentScript.WidgetNon, true)
        UIHelper.WidgetFoceDoAlignAssignNode(parentScript, parentScript.WidgetNon)
        UIHelper.SetVisible(parentScript.WidgetLayoutFinish, false)
    end

    UIHelper.LayoutDoLayout(parentScript._rootNode)

end

function UIWidgetSeasonLevelReward:UpdateLevelBtn(scriptView, tbLevelInfo)
    local nClass = tbLevelInfo.nClass
    local tRankInfo = Table_GetRankInfoByLevel(tbLevelInfo.nRankLv)
    local szSfxPath = string.gsub(tRankInfo.szSFXPath, "/", "\\\\")
    local nRankPoint = tRankInfo.nRankPoint
    local szTitle = g_tStrings.STR_RANK_TITLE_NAMA[nClass]
    local nImageFrame = tRankInfo.nImageFrame
    local szImagePath = RANK_IMG[nImageFrame]
    local tbFontColor = RANK_FONTCOLOR[nImageFrame]
    local nR, nG, nB = tbFontColor[1], tbFontColor[2], tbFontColor[3]

    UIHelper.SetString(scriptView.LabelSeasonLevel, UIHelper.GBKToUTF8(tRankInfo.szRankName))
    UIHelper.SetVisible(scriptView.LabelSeasonLevelName, false)
    UIHelper.SetColor(scriptView.LabelSeasonLevel, cc.c3b(nR, nG, nB))
    UIHelper.SetSpriteFrame(scriptView.ImgSeasonLevelMark, szImagePath, false)
    for k, tbImg in ipairs(scriptView.tbPointList) do
        UIHelper.SetVisible(tbImg, k <= nRankPoint)
    end
    UIHelper.BindUIEvent(scriptView._rootNode, EventType.OnClick, function()
        -- UIMgr.Open(VIEW_ID.PanelSeasonLevel)
    end)
    if szSfxPath then
        UIHelper.SetSFXPath(scriptView.SFX_Leve, szSfxPath)
        UIHelper.PlaySFX(scriptView.SFX_Leve)
    end
end

function UIWidgetSeasonLevelReward:FormatStateList(tList)
    local tbRankTemplate = FormatRankInfo(Table_GetRankInfo())

    local tGroupedList = {}
    local nCurIdx = 1
    for _, tMajorRank in ipairs(tbRankTemplate) do
        local tbSubGroup = {}
        for j, tMinorRank in ipairs(tMajorRank.tbRankPointList) do
            table.insert(tbSubGroup, {
                nState = tList[nCurIdx] or 0,
                nRankLv = tMinorRank.nRankLv
            })
            nCurIdx = nCurIdx + 1
        end
        table.insert(tGroupedList, tbSubGroup)
    end
    return tGroupedList
end

function UIWidgetSeasonLevelReward:GetLevelRewardNum(nRankLv)   --获取当前段位剩余奖励数量
    local nClaimedNum = 0
    local nMaxRewardNum = 3 -- 每个段位至多领奖3次
    
    -- 获取所有 class 的段位状态数据
    local tRankInfo = GDAPI_SA_GetAllRankBaseInfo()
    if not tRankInfo then return nMaxRewardNum end
    
    -- 遍历所有 class，检查当前段位（nRankLv）是否已经领取
    for nClass, tClassInfo in pairs(tRankInfo) do
        -- tList 的索引对应段位（1~16）
        if tClassInfo.tList and tClassInfo.tList[nRankLv] == CHECK_STATE.ALREADY_GET then
            nClaimedNum = nClaimedNum + 1
        end
    end
    
    return nClaimedNum
end

function UIWidgetSeasonLevelReward:RefreshRewardState()
    self:UpdateBtnAllState()
    
    local tRankInfo = GDAPI_SA_GetAllRankBaseInfo()
    if not tRankInfo then return end
    
    -- 1. 更新底部所有 class 对应 WidgetLayoutFinishedChecklisCell 的状态
    if self.tbCheckCellScripts then
        for nClass, tClassInfo in pairs(tRankInfo) do
            local tbClassScripts = self.tbCheckCellScripts[nClass]
            if tbClassScripts and tClassInfo.tList then
                for nRankLv, tbCellScript in pairs(tbClassScripts) do
                    local nState = tClassInfo.tList[nRankLv] or 0
                    local bCanGet = (nState == CHECK_STATE.CAN_GET)
                    local bAlreadyGet = (nState == CHECK_STATE.ALREADY_GET)
                    local bReachCantGet = (nState == CHECK_STATE.REACH_CANT_GET)

                    UIHelper.SetVisible(tbCellScript.BtnGet, bCanGet)
                    UIHelper.SetVisible(tbCellScript.imgFinish, bAlreadyGet)
                    UIHelper.SetVisible(tbCellScript.imgFinishGet, bReachCantGet)
                end
            end
        end
    end

    if self.tbRewardCellScripts then
        for nRankLv, tbItemScript in pairs(self.tbRewardCellScripts) do
            local nRewardNum = self:GetLevelRewardNum(nRankLv)
            local nTotalNum = LEVEL2REWARDNUM[nRankLv] or 3
            local bAllGot = nRewardNum >= nTotalNum

            UIHelper.SetString(tbItemScript.LabelSeasonRewardinfo, nRankLv > 1 and string.format("已领 %d/%d", nRewardNum, nTotalNum) or "暂无")

            -- 新增：同步刷新该段位下所有 WidgetItem_60 的 WidgetGot
            local tbItemScripts = self.tbRewardItemScripts and self.tbRewardItemScripts[nRankLv]
            if tbItemScripts then
                for _, tbRewardItemScript in ipairs(tbItemScripts) do
                    if tbRewardItemScript.WidgetGot then
                        UIHelper.SetVisible(tbRewardItemScript.WidgetGot, bAllGot)
                    end
                end
            end
        end
    end
end


function UIWidgetSeasonLevelReward:ResetDirectionalLock(sender)
    self.bScrollDirLocked = false
    self.scrollStartPos = nil

    UIHelper.SetScrollEnabled(self.ScrollViewSeasonTypeFinishList, true)

    if sender then
        UIHelper.SetScrollEnabled(sender, true)
    end
    if self.lockedScrollView and self.lockedScrollView ~= sender then
        UIHelper.SetScrollEnabled(self.lockedScrollView, true)
    end
    self.lockedScrollView = nil
end

function UIWidgetSeasonLevelReward:StopScrollInertia(scrollView)
    if scrollView and scrollView.stopAutoScroll then
        scrollView:stopAutoScroll()
    end
end

function UIWidgetSeasonLevelReward:StopAllScrollInertia(exceptScrollView)
    self:StopScrollInertia(self.ScrollViewSeasonTypeFinishList)
    self:StopScrollInertia(self.ScrollViewRewardTitleList)

    for _, sv in ipairs(self.tbHorizontalScrollViews or {}) do
        if sv ~= exceptScrollView then
            self:StopScrollInertia(sv)
        end
    end

    if exceptScrollView then
        self:StopScrollInertia(exceptScrollView)
    end
end

local function GetSeasonRewardPath(tSeasonReward)
    if not tSeasonReward then
        return
    end

    if not tSeasonReward.bRoleType then
        return tSeasonReward.szMobilePath
    end

    local pPlayer = GetClientPlayer()
    local nRoleType = pPlayer and pPlayer.nRoleType or ROLE_TYPE.STANDARD_MALE
    if nRoleType == ROLE_TYPE.STANDARD_MALE then
        return tSeasonReward.szMobileStandardMan
    elseif nRoleType == ROLE_TYPE.STANDARD_FEMALE then
        return tSeasonReward.szMobileStandardFemale
    elseif nRoleType == ROLE_TYPE.LITTLE_BOY then
        return tSeasonReward.szMobileLittleBoy
    elseif nRoleType == ROLE_TYPE.LITTLE_GIRL then
        return tSeasonReward.szMobileLittleGirl
    end
end

function UIWidgetSeasonLevelReward:UpdatePreviewRewardImg()
    local tbRewardInfoList = Table_GetSeasonReward("RankPanel")
    if not tbRewardInfoList then
        return
    end
    local szImgPath = GetSeasonRewardPath(tbRewardInfoList[1])
    UIHelper.SetTexture(self.ImgIconReward, szImgPath)
end

return UIWidgetSeasonLevelReward