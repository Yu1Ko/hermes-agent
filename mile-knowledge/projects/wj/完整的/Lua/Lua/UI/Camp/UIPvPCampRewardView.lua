-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPvPCampRewardView
-- Date: 2023-03-02 14:37:04
-- Desc: UIPvPCampRewardView
-- ---------------------------------------------------------------------------------

local UIPvPCampRewardView = class("UIPvPCampRewardView")

local RICH_TEXT_COLOR = "#FFEFA2"

function UIPvPCampRewardView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitUI()
    self:UpdateInfo()
    --self:Test() --ScrollViewTree相关接口示例测试
end

function UIPvPCampRewardView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.scriptItemTip then
        self.scriptItemTip:OnInit()
        self.scriptItemTip = nil
    end

    self.lastItemScript = nil
end

function UIPvPCampRewardView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.WidgetItemTipCloseBtn, EventType.OnClick, function()
        self:CloseTips()
    end)
end

function UIPvPCampRewardView:RegEvent()
    Event.Reg(self, EventType.OnUpdateCampRewardTips, function(dwTabType, dwIndex)
        if dwTabType and dwIndex then
            self:ShowRewardItemTips(dwTabType, dwIndex)
        else
            UIHelper.SetVisible(self.WidgetCampRewardItemTip, false)
        end
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTips()
    end)
end

function UIPvPCampRewardView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPvPCampRewardView:AddRewardList(szTitle, tRewardListInfo)
    if self.scriptScrollViewTree then
        self.scriptScrollViewTree:AddContainer({
            szTitle = szTitle
        }, tRewardListInfo)
    end
end

function UIPvPCampRewardView:UpdateRewardList()
    if self.scriptScrollViewTree then
        self.scriptScrollViewTree:UpdateInfo()
        Timer.AddFrame(self, 1, function()
            self.scriptScrollViewTree:SetContainerSelected(1, true)
        end)
        --动画导致LayoutMask的位置偏移，延迟几帧执行
        Timer.AddFrame(self, 5, function()
            self.scriptScrollViewTree:InitLayoutMask()
        end)
    end
end

function UIPvPCampRewardView:AddLabelInfoToList(tList, szContent)
    local nLabelPrefabID = PREFAB_ID.WidgetPvPCampRewardListLabel
    table.insert(tList, {
        nPrefabID = nLabelPrefabID,
        tArgs = { szContent = szContent }
    })
end

function UIPvPCampRewardView:AddNormalInfoToList(tList, nPrefabID, szTitle, szContent)
    table.insert(tList, {
        nPrefabID = nPrefabID,
        tArgs = { szTitle = szTitle, szContent = szContent }
    })
end

function UIPvPCampRewardView:AddTitleRankRewardInfoToList(tList, szText, tReward)
    local nTitleRankRewardInfoPrefabID = PREFAB_ID.WidgetPvPCampRewardListRank
    table.insert(tList, {
        nPrefabID = nTitleRankRewardInfoPrefabID,
        tArgs = { szText = szText, tReward = tReward }
    })
end

function UIPvPCampRewardView:CheckAddEmptyInfoToList(tList, szContent)
    if #tList > 0 then
        return
    end

    local nEmptyPrefabID = PREFAB_ID.WidgetPvPCampRewardListEmpty
    table.insert(tList, {
        nPrefabID = nEmptyPrefabID,
        tArgs = { szContent = szContent }
    })
end

function UIPvPCampRewardView:InitUI()
    self.scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetContent)
    if self.scriptScrollViewTree then
        self.scriptScrollViewTree:OnInit(PREFAB_ID.WidgetPvPCampRewardList, function(scriptContainer, tArgs)
            UIHelper.SetString(scriptContainer.LabelName, tArgs.szTitle)
            UIHelper.SetString(scriptContainer.LabelNameSelect, tArgs.szTitle)
        end)
    end
end

function UIPvPCampRewardView:UpdateInfo()
    local tAttrReward, tEquipReward, tExtraReward, tRankReward = self:GetTitleRewardInfo()

    --空状态
    self:CheckAddEmptyInfoToList(tAttrReward, "当前战阶等级暂无")
    self:CheckAddEmptyInfoToList(tEquipReward, "当前战阶等级暂无")
    self:CheckAddEmptyInfoToList(tExtraReward, "当前战阶等级暂无")
    self:CheckAddEmptyInfoToList(tRankReward, "当前战阶等级暂无")

    self:AddRewardList("战阶属性奖励", tAttrReward)
    self:AddRewardList("战阶商人解锁", tEquipReward)
    self:AddRewardList("威名点周上限奖励", tExtraReward)
    self:AddRewardList("战阶积分排名奖励", tRankReward)

    self:UpdateRewardList()
end

function UIPvPCampRewardView:GetTitleRewardInfo()
    local player = GetClientPlayer()
    if not player then return end

    local tAttrReward, tEquipReward, tExtraReward, tRankReward = {}, {}, {}, {}

    --tAttrReward & tEquipReward: 

    --个人战阶
    local nTitle = player.nTitle
    local nNextTitle = nTitle + 1
    local szAttr, szEquip = self:ParseTitleReward(nTitle)
    local szNextAttr, szNextEquip = self:ParseTitleReward(nNextTitle)

    --世界战阶
    local nWorldTitleLevel, nNextDay = On_CampGetWorldTitleLv() --"scripts/Include/UIscript/UIscript_Camp.lua"
    local nWorldNextTitle = nWorldTitleLevel + 1
    local szWorldAttr, szWorldEquip = self:ParseTitleReward(nWorldTitleLevel)
    local szWorldNextAttr, szWorldNextEquip = self:ParseTitleReward(nWorldNextTitle)
    local bShowNext = nNextDay and nNextDay ~= -1

    if nTitle > 0 then
        local _, szTitle, _ = CampData.GetPlayerTitleDesc(nTitle)
        self:AddLabelInfoToList(tAttrReward, "当前战阶称号：" .. szTitle)
    end

    local szAttrTitle = FormatString(g_tStrings.STR_CAMP_TITLE_POINT_NOW, nTitle)
    local szNextAttrTitle = FormatString(g_tStrings.STR_CAMP_TITLE_POINT_NEXT, nTitle + 1)
    local szWorldAttrTitle = FormatString(g_tStrings.STR_WORLD_CAMP_TITLE_POINT, nWorldTitleLevel)
    local szWorldNextAttrTitle
    if bShowNext then
        szWorldNextAttrTitle = FormatString(g_tStrings.STR_WORLD_CAMP_TITLE_POINT_NEXT, nNextDay)
    else
        szWorldNextAttrTitle = g_tStrings.STR_WORLD_CAMP_TITLE_POINT_NOMORE
    end

    local szEquipTitle = FormatString(g_tStrings.STR_CAMP_TITLE_POINT_NOW, nTitle)
    local szNextEquipTitle = FormatString(g_tStrings.STR_CAMP_TITLE_POINT_NEXT, nTitle + 1)
    local szWorldEquipTitle = FormatString(g_tStrings.STR_WORLD_CAMP_TITLE_POINT_NOW, nWorldTitleLevel)
    local szWorldNextEquipTitle
    if bShowNext then
        szWorldNextEquipTitle = FormatString(g_tStrings.STR_WORLD_CAMP_TITLE_POINT_NEXT, nNextDay)
    else
        szWorldNextEquipTitle = g_tStrings.STR_WORLD_CAMP_TITLE_POINT_NOMORE
    end

    --1.tAttrReward
    local nAttrPrefabID = PREFAB_ID.WidgetPvPCampRewardListAttribute
    if szAttr then self:AddNormalInfoToList(tAttrReward, nAttrPrefabID, szAttrTitle, "战阶称号属性：" .. self:AttachRichTextColor(szAttr)) end
    if szNextAttr then self:AddNormalInfoToList(tAttrReward, nAttrPrefabID, szNextAttrTitle, "战阶称号属性：" .. self:AttachRichTextColor(szNextAttr)) end
    if szWorldAttr then self:AddNormalInfoToList(tAttrReward, nAttrPrefabID, szWorldAttrTitle, "战阶称号属性：" .. self:AttachRichTextColor(szWorldAttr)) end
    if szWorldNextAttr then
        if bShowNext then
            self:AddNormalInfoToList(tAttrReward, nAttrPrefabID, szWorldNextAttrTitle, "战阶称号属性：" .. self:AttachRichTextColor(szWorldNextAttr))
        else
            self:AddNormalInfoToList(tAttrReward, nAttrPrefabID, szWorldNextAttrTitle)
        end
    end

    --2.tEquipReward
    local nEquipPrefabID = PREFAB_ID.WidgetPvPCampRewardListEquip
    if szEquip then self:AddNormalInfoToList(tEquipReward, nEquipPrefabID, szEquipTitle, szEquip) end
    if szNextEquip then self:AddNormalInfoToList(tEquipReward, nEquipPrefabID, szNextEquipTitle, szNextEquip) end
    if szWorldEquip then self:AddNormalInfoToList(tEquipReward, nEquipPrefabID, szWorldEquipTitle, szWorldEquip) end
    if szWorldNextEquip then
        if bShowNext then
            self:AddNormalInfoToList(tEquipReward, nEquipPrefabID, szWorldNextEquipTitle, szWorldNextEquip)
        else
            self:AddNormalInfoToList(tEquipReward, nEquipPrefabID, szWorldNextEquipTitle)
        end
    end

    -- tExtraReward & tRankReward: 

    local nTitlePoint = player.nTitlePoint
    local szExtraLabel = "战阶提升后奖励将通过邮件发放。该奖励可以同阵营共账号角色共享，获得过共享的角色提升战阶时，不再重复获得奖励"
    local szRankLabel1 = "战阶排名前500名的玩家可领取奖励列表"
    local szRankLabel2 = "未进入排名的侠士可根据战阶积分领取相应奖励"

    --3.tExtraReward
    self:AddLabelInfoToList(tExtraReward, szExtraLabel)
    for i, tInfo in ipairs(CampData.TITLE_POINT_REAL_SEND or {}) do
        local szText = FormatString(g_tStrings.RANK_POINT_INFO_TIP, self:GetSimpleTextByNum(tInfo.nMinPoint))
        --local bShow = nTitlePoint >= tInfo.nMinPoint and nTitlePoint < tInfo.nMaxPoint
        self:AddTitleRankRewardInfoToList(tExtraReward, szText, tInfo.tReward)
    end

    --4.tRankReward
    self:AddLabelInfoToList(tRankReward, szRankLabel1)
    for i, tInfo in ipairs(CampData.TITLE_POINT_RANK_REWARD or {}) do
        local szText = FormatString(g_tStrings.RANK_INFO_TIP, tInfo.s, tInfo.e)
        --local bShow = nRank >= tInfo.s and nRank <= tInfo.e
        self:AddTitleRankRewardInfoToList(tRankReward, szText, tInfo.tReward)
    end
    self:AddLabelInfoToList(tRankReward, szRankLabel2)
    for i, tInfo in ipairs(CampData.TITLE_POINT_COUNT_REWARD or {}) do
		local szText = FormatString(g_tStrings.RANK_POINT_INFO_TIP, self:GetSimpleTextByNum(tInfo.s))
        --local bShow = nLastPoint >= tInfo.s and nLastPoint < tInfo.e
        self:AddTitleRankRewardInfoToList(tRankReward, szText, tInfo.tReward)
	end

    return tAttrReward, tEquipReward, tExtraReward, tRankReward
end

function UIPvPCampRewardView:AttachRichTextColor(szText, szColor)
    if not szText then return end
    szColor = szColor or RICH_TEXT_COLOR

    --将百分数数字加颜色
    return string.gsub(szText, "(%d+)%%", "<color=" .. szColor .. ">%1%%</color>")
end

--<text>text="当前战阶称号属性：化劲等级提高2%，移动速度提高1%\\\n"font=100</text><text>text="当前战阶可购买的装备：可以购买碧霄古玉·腰带" font=100 </text>
--例：从上面文字中拆分出以下信息："化劲等级提高2%，移动速度提高1%" 和 "可以购买碧霄古玉·腰带"
function UIPvPCampRewardView:ParseTitleReward(nTitle)
    local szTip = Table_GetTitleRankTip(nTitle)
    if not szTip or szTip == "" then
        return
    end

    szTip = string.pure_text(UIHelper.GBKToUTF8(szTip))

    local szAttr, szEquip

    local tReward = string.split(szTip, '\n')
    if #tReward == 1 then
        szEquip = tReward[1]
    elseif #tReward == 2 then
        szAttr = string.split(tReward[1], "：")[2]
        szEquip = string.split(tReward[2], "：")[2]
    end
    return szAttr, szEquip
end

--例：65000 -> 6.5万；5000 -> 5千
function UIPvPCampRewardView:GetSimpleTextByNum(nData)
    local szData = ""
    if nData >= 10000 then
        if nData % 10000 == 0 then
            szData = nData / 10000 .. g_tStrings.DIGTABLE.tCharDiH[2]
        else
            szData = string.format("%.1f", nData / 10000) .. g_tStrings.DIGTABLE.tCharDiH[2]
        end
    elseif nData >= 1000 then
        if nData % 1000 == 0 then
            szData = nData / 1000 .. g_tStrings.DIGTABLE.tCharDiL[4]
        else
            szData = string.format("%.1f", nData / 1000) .. g_tStrings.DIGTABLE.tCharDiL[4]
        end
    end
    return szData
end

function UIPvPCampRewardView:ShowRewardItemTips(dwTabType, dwIndex)
    if not self.scriptItemTip then
        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetCampRewardItemTip)
    end

    UIHelper.SetVisible(self.WidgetItemTipCloseBtn, true)
    UIHelper.SetVisible(self.WidgetCampRewardItemTip, true)

    self.scriptItemTip:OnInitWithTabID(dwTabType, dwIndex)
    self.scriptItemTip:SetBtnState({})
end

function UIPvPCampRewardView:CloseTips()
    UIHelper.SetVisible(self.WidgetItemTipCloseBtn, false)
    UIHelper.SetVisible(self.WidgetCampRewardItemTip, false)
    Event.Dispatch(EventType.OnClearUIItemIconSelect)
end

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

function UIPvPCampRewardView:Test()
    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetContent)
    local tData = {
        [1] = {
            tArgs = {szTitle = "TestTitle1"},
            tItemList = {
                {tArgs = {szTitle = "Item1_1", szContent = "Test1"}},
                {nPrefabID = PREFAB_ID.WidgetPvPCampRewardListLabel, tArgs = {szContent = "TestLabel1"}},
                {tArgs = {szTitle = "Item1_2", szContent = "Test2"}},
                {tArgs = {szTitle = "Item1_3", szContent = "Test3"}},
            }
        },
        [2] = {
            tArgs = {szTitle = "TestTitle2"},
            tItemList = {
                {nPrefabID = PREFAB_ID.WidgetPvPCampRewardListLabel, tArgs = {szContent = "TestLabel2"}},
                {tArgs = {szTitle = "Item2_1", szContent = "Test1"}},
                {tArgs = {szTitle = "Item2_2", szContent = "Test2"}},
                {tArgs = {szTitle = "Item2_3", szContent = "Test3"}},
                {tArgs = {szTitle = "Item2_4", szContent = "Test4"}},
                {nPrefabID = PREFAB_ID.WidgetPvPCampRewardListLabel, tArgs = {szContent = "TestLabel3"}},
                {tArgs = {szTitle = "Item2_5", szContent = "Test5"}},
                {tArgs = {szTitle = "Item2_6", szContent = "Test6"}},
                {tArgs = {szTitle = "Item2_7", szContent = "Test7"}},
                {tArgs = {szTitle = "Item2_8", szContent = "Test8"}},
            }
        },
        [3] = {
            tArgs = {szTitle = "TestTitle3"},
            tItemList = {
                {tArgs = {szTitle = "Item3_1", szContent = "Test1"}},
                {tArgs = {szTitle = "Item3_2", szContent = "Test2"}},
            }
        },
    }
    UIHelper.SetupScrollViewTree(scriptScrollViewTree, PREFAB_ID.WidgetPvPCampRewardList, PREFAB_ID.WidgetPvPCampRewardListAttribute, 
    function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelName, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelNameSelect, tArgs.szTitle)
    end, tData)
end

return UIPvPCampRewardView