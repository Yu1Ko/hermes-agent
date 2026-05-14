-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: DesignationMgr
-- Date: 2023-12-20 20:53:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

DesignationMgr = DesignationMgr or {className = "DesignationMgr"}
local self = DesignationMgr

function DesignationMgr.Init()
    Event.Reg(self, EventType.OnAccountLogout, function ()
        g_tTable.Designation_Prefix = nil
        g_tTable.Designation_Postfix = nil
        g_tTable.Designation_Generation = nil
    end)
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelPersonalTitle then
            CharacterEffectData.Init()
        end
    end)
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelPersonalTitle then
            CharacterEffectData.UnInit()
        end
    end)

    self.InitTips()
end

function DesignationMgr.InitTips()
    --称号类型
    for nType, szName in ipairs(g_tStrings.tDesignationSpecialType) do
        table.insert(FilterDef.Designation[1].tbList, szName)
    end

    --拥有情况
    table.insert(FilterDef.Designation[2].tbList, g_tStrings.STR_DESIGNATION_ALL_SHOW)
    table.insert(FilterDef.Designation[2].tbList, g_tStrings.tDesignationFilterHave[1])
    table.insert(FilterDef.Designation[2].tbList, g_tStrings.tDesignationFilterHave[2])

    --获取途径
    table.insert(FilterDef.Designation[3].tbList, g_tStrings.STR_DESIGNATION_ALL_GAIN_WAY)
    local tGainWayList = Table_GetDesignationGainWayList()
    for _, tLine in ipairs(tGainWayList) do
        table.insert(FilterDef.Designation[3].tbList, UIHelper.GBKToUTF8(tLine.szTypeName))
    end

    --资料片
    local tVersionInfo = Table_GetDesignationVersionInfo()
    -- table.insert(FilterDef.Designation[4].tbList, g_tStrings.STR_ALL)
    -- for _, tLine in ipairs(tVersionInfo) do
    --     table.insert(FilterDef.Designation[4].tbList, UIHelper.GBKToUTF8(tLine.szVersionName))
    -- end
    table.insert(FilterDef.Designation_DLC[1].tbList, g_tStrings.STR_ALL)
    for _, tLine in ipairs(tVersionInfo) do
        table.insert(FilterDef.Designation_DLC[1].tbList, UIHelper.GBKToUTF8(tLine.szVersionName))
    end
end

function DesignationMgr.UnInit()

end

function DesignationMgr.OnLogin()

end

function DesignationMgr.OnFirstLoadEnd()

end

-- function DesignationMgr.CreateNewDesignationPanel(nID, bPrefix)
--     local aDesignation = nil
--     local bWorld = false
--     local bMilitary = false
--     if bPrefix then
--         aDesignation = g_tTable.Designation_Prefix:Search(nID)
--         local tInfo = GetDesignationPrefixInfo(nID)
--         bWorld = tInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION
--         bMilitary = tInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION
--     else
--         aDesignation = g_tTable.Designation_Postfix:Search(nID)
--     end
--     if not aDesignation then
--         return
--     end
--     local szText
--     if bMilitary then
--         szText = g_tStrings.GET_DESGNATION_TITLE1
--     elseif bWorld then
--         szText = g_tStrings.GET_DESGNATION_WORLD1
--     elseif bPrefix then
--         szText = g_tStrings.GET_DESGNATION_PREFIX1
--     else
--         szText = g_tStrings.GET_DESGNATION_POSTFIX1
--     end
--     szText = szText .. self.GetDesignationText(aDesignation)

--     TipsHelper.ShowNormalTip(szText, true)
-- end

function DesignationMgr.GetDesignationText(aDesignation)
    if not aDesignation then
        return
    end
    local r, g, b = GetItemFontColorByQuality(aDesignation.nQuality)
    local szName = GetFormatText(aDesignation.szName, nil, r, g, b)
    return UIHelper.GBKToUTF8(szName)
end

--根据称号名称获取同名特效
function DesignationMgr.GetDesignationEffectPage(szName)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local nMaxPageCount = 4 -- 1脚印,2环身,3左手,4右手
    for nPage = 1, nMaxPageCount do
        CharacterEffectData.SetSelectType(nPage)
        local _, _, tList, _, _ = CharacterEffectData.GetSelectList(nPage)
        for nIndex, tInfo in pairs(tList or {}) do
            if CharacterEffectData.IsEffectAcquired(tInfo.dwEffectID, player) and UIHelper.GBKToUTF8(tInfo.szName) == szName then
                local nPageSize = CharacterEffectData.GetMaxShowCount()
                local nSubPage = math.ceil(nIndex / nPageSize)
                local nSubIndex = nIndex % nPageSize
                if nSubIndex == 0 and nIndex > 0 then
                    nSubIndex = nPageSize
                end
                return nPage, nSubPage, nSubIndex
            end
        end
    end

    return
end

--跳转到挂饰秘鉴-特效
function DesignationMgr.ShowEffectView(szName)
    local function _openView()
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelAccessory)
        if not scriptView then
            scriptView = UIMgr.Open(VIEW_ID.PanelAccessory)
        end
        if not scriptView then
            return
        end

        if not szName then
            return
        end

        local nPage, nSubPage, nSubIndex = self.GetDesignationEffectPage(szName)
        if not nPage then
            return
        end

        local nodeEffect = UIHelper.GetChildByName(scriptView._rootNode, "AniAll/WidgetAniMiddle/WidgetAnchorEffectContent")
        local scriptEffect = UIHelper.GetBindScript(nodeEffect)
        if not scriptEffect then
            return
        end

        Timer.AddFrame(self, 5, function()
            if not scriptView or not scriptEffect then
                return
            end
            UIHelper.SetSelected(scriptView.tbTogPage[2], true)
            UIHelper.SimulateClick(scriptEffect.tbTogType[nPage + 1])
            UIHelper.SetToggleGroupSelected(scriptEffect.ToggleGroupRightNav, nPage)
            CharacterEffectData.SetCurrentPage(nSubPage)
            scriptEffect:UpdateListInfo()
            UIHelper.SimulateClick(scriptEffect.tbScriptEffectCell[nSubIndex] and scriptEffect.tbScriptEffectCell[nSubIndex].TogAccessoryEffect)
        end)
    end

    UIMgr.Close(VIEW_ID.PanelPersonalTitle)
    if UIMgr.IsViewOpened(VIEW_ID.PanelCharacter) then
        Timer.Add(self, 0.5, _openView)
    else
        UIMgr.Open(VIEW_ID.PanelCharacter)
        Timer.Add(self, 0.7, _openView)
    end
end