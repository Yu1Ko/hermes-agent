-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationFameAndPunishEvil
-- Date: 2026-04-14 09:58:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationFameAndPunishEvil = class("UIOperationFameAndPunishEvil")

local TAB_FAME = 1  -- 名望
local TAB_EVIL = 2  -- 诸恶

function UIOperationFameAndPunishEvil:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    self.scriptContentTitleTog = tComponentContext.tScriptLayoutTop[1]
    local parentLayout = UIHelper.GetParent(self.scriptContentTitleTog._rootNode)
    self.scriptTask =  UIHelper.AddPrefab(PREFAB_ID.WidgetTaskList80, parentLayout)
    self.scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetNewInfoMingWang, parentLayout, function(nIndex)
        self:OnSelectSubTab(nIndex)
    end)
    UIHelper.SetAnchorPoint(self.scriptBtn._rootNode, 0, 0)

    self.scriptContentTitleTog:SetToggleSelectCallback(function(nIndex)
         self:OnTabChanged(nIndex)
    end)
    self.m_nActiveTab = 1

    self:InitDataModel()
    self:UpdateInfo()
end

function UIOperationFameAndPunishEvil:OnExit()
    self.bInit = false
    self.tLatestFame = nil
    self:UnRegEvent()
end

function UIOperationFameAndPunishEvil:BindUIEvent()

end

function UIOperationFameAndPunishEvil:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationFameAndPunishEvil:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationFameAndPunishEvil:InitDataModel()
    local tInfo = Table_GetFameInfo()
    if not tInfo or #tInfo == 0 then
        return
    end
    local tLatest = tInfo[#tInfo]
    -- szMapChapter 格式: "mapID;questID;chapterID|..."，取第一个段的 mapID
    local szFirstChapter = string.split(tLatest.szMapChapter, "|")[1] or ""
    local tChapterParts  = string.split(szFirstChapter, ";")
    local nMapID = tonumber(tChapterParts[1]) or 0
    local nMainChapter = tonumber(tChapterParts[3]) or 0

    -- szRewardShopInfo 格式: "szName;dwGroupID;dwShopID|..."
    local tShopInfos = {}
    local tShopSegs  = string.split(tLatest.szRewardShopInfo, "|")
    for _, szSeg in ipairs(tShopSegs) do
        local tParts = string.split(szSeg, ";")
        if tParts[1] then
            tShopInfos[#tShopInfos + 1] = {
                szName    = tParts[1],
                dwGroupID = tonumber(tParts[2]) or 0,
                dwShopID  = tonumber(tParts[3]) or 0,
            }
        end
    end

    self.tLatestFame = {
        dwID              = tLatest.dwID,
        nMapID            = nMapID,
        nMainChapter      = nMainChapter,
        tShopInfos        = tShopInfos,
        nExtPointIndex    = tLatest.nExtPointIndex,
        nExtPointBitIndex = tLatest.nExtPointBitIndex,
        nExtPointLength   = tLatest.nExtPointLength,
    }
end

function UIOperationFameAndPunishEvil:IsLatestFameLocked()
    local t = self.tLatestFame
    if not t then
        return true
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return true
    end
    return hPlayer.GetExtPointByBits(t.nExtPointIndex, t.nExtPointBitIndex, t.nExtPointLength) == 0
end

function UIOperationFameAndPunishEvil:OnTabChanged(nTab)
    self.m_nActiveTab = nTab
    self:RefreshList()
end

function UIOperationFameAndPunishEvil:UpdateInfo()
end

function UIOperationFameAndPunishEvil:RefreshList()
    local szTitle
    if self.m_nActiveTab == TAB_FAME then
        if self:IsLatestFameLocked() then
            szTitle = g_tStrings.STR_FAME_PUNISH_EVIL_LOCK_FAME
        else
            szTitle = g_tStrings.STR_FAME_PUNISH_EVIL_GOTO_FAME
        end
    else
        szTitle = g_tStrings.STR_FAME_PUNISH_EVIL_GOTO_EVIL
    end
    self.scriptTask:UpdateTaskItem({
        szTitle    = szTitle,
        bShowArrow = true,
    })
    self.scriptTask:SetfnCallBack(function()
        local tFame = self.tLatestFame
        if not tFame then
            return
        end
        if self.m_nActiveTab == TAB_FAME and self:IsLatestFameLocked() then
            UIMgr.Open(VIEW_ID.PanelSwordMemories, self.tLatestFame.nMainChapter)
        else
            Event.Dispatch("EVENT_LINK_NOTIFY", "MiddleMap/" .. tFame.nMapID .. "/0")
        end
    end)

    UIHelper.SetVisible(self.scriptBtn._rootNode, self.m_nActiveTab == TAB_FAME)

    self:OnSelectSubTab(1)
end

function UIOperationFameAndPunishEvil:OnSelectSubTab(nIndex)
    local tInfo = Table_GetFameAndPunishEvilInfo()[self.m_nActiveTab]
    local scriptCenter = self.tComponentContext.scriptCenter
    local szImgPath = nIndex == 1 and tInfo.szMobileImage1 or tInfo.szMobileImage2
    scriptCenter:ShowItemBg(szImgPath, true)
    Event.Dispatch(EventType.OnOperationSelectFameBtn, nIndex)
end


return UIOperationFameAndPunishEvil