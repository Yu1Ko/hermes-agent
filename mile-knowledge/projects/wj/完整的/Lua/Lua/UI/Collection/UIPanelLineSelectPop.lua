-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelLineSelectPop
-- Date: 2024-03-20 19:32:25
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nGongFangType = 282
local MAX_PEOPLE = 500

local MAPID_TO_TITLE = {
    [25]   = "浩气盟",
    [27]   = "恶人谷",
    [216]  = "逐鹿中原",
    [1]    = "阵营攻防战",
}

local UIPanelLineSelectPop = class("UIPanelLineSelectPop")

function UIPanelLineSelectPop:OnEnter(nMapID, bActivity, tbMapList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(nMapID, bActivity, tbMapList)
    ApplyCustomRankList(nGongFangType)
    RemoteCallToServer("On_Camp_CastleFightMapList")
end

function UIPanelLineSelectPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelLineSelectPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        if not self.nSelectLine then return end
        CampData.CampTransfer(self.nSelectMapID, self.nSelectLine)
    end)


end

function UIPanelLineSelectPop:RegEvent()
    Event.Reg(self, "CUSTOM_RANK_UPDATE", function(nType, nTotalNum)
        if nType == nGongFangType then
            self:UpdateRankList()
        end
    end)

    Event.Reg(self, EventType.OnSelectLineType, function(nIndex, nMapID)
        self.nSelectLine = nIndex
        self.nSelectMapID = nMapID
        self:UpdateBtnState()
    end)

    Event.Reg(self, "On_Camp_CastleFightMapList", function(tMapList)
        self:UpdateMapList(tMapList)
    end)
end

function UIPanelLineSelectPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIPanelLineSelectPop:Init(nMapID, bActivity, tbMapList)
    self.nMapID = nMapID

    self.tFightMap = {}
    self.bActivity = bActivity
    self.tbMapList = tbMapList
    self.nSelectLine = 0
    self.nSelectMapID = 0
    self:UpdateInfo()
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelLineSelectPop:UpdateInfo()
    local szCampName = MAPID_TO_TITLE[self.nMapID]
    if self.bActivity then szCampName = MAPID_TO_TITLE[1] end
    UIHelper.SetString(self.LabelTitle, szCampName)

    UIHelper.RemoveAllChildren(self.ScrollViewType)
    local tbRegularMap = self:GetRegularMap()
    for nIndex, nMapID in ipairs(tbRegularMap) do
        local tbInfo = {}
        tbInfo.szNum = ""
        tbInfo.szName = UIHelper.GBKToUTF8(Table_GetMapName(nMapID))
        tbInfo.nIndex = nIndex
        tbInfo.nMapId = nMapID
        tbInfo.bMainBattleField = self.nMapID ~= 0 
        UIHelper.AddPrefab(PREFAB_ID.WidgetLineSelectType, self.ScrollViewType, tbInfo)
    end

    if not self.nCopyIndexNum then return end
    for nIndex = 1, self.nCopyIndexNum do
        local tbInfo = {}
        local nNum = 0
        local nMaxCount = MAX_PEOPLE
        local tNumber = self.tbBranchNumber and self.tbBranchNumber[nIndex] or nil
        if tNumber then
            if g_pClientPlayer.nCamp == CAMP.GOOD then
                nNum = tNumber.nGoodPlayerCount
                nMaxCount = tNumber.nMaxGoodPlayerCount
            elseif g_pClientPlayer.nCamp == CAMP.EVIL then
                nNum = tNumber.nEvilPlayerCount
                nMaxCount = tNumber.nMaxEvilPlayerCount
            end
        end
        local bShowNum = not self.bActivity and self.nMapID ~= CampData.YINSHAN_MAP
        tbInfo.szNum = bShowNum and FormatString(g_tStrings.STR_NEW_PQ_TYPE2, nNum, nMaxCount) or ""
        tbInfo.szName = FormatString(g_tStrings.STR_CAMP_BATTLE_BRANCH_NAME, UIHelper.GBKToUTF8(Table_GetMapName(self.nMapID)), nIndex)
        tbInfo.nIndex = nIndex
        tbInfo.nMapId = self.nMapID
        tbInfo.bQixi = self.bActivity
        UIHelper.AddPrefab(PREFAB_ID.WidgetLineSelectType, self.ScrollViewType, tbInfo)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewType)
    self:UpdateBtnState()
end

function UIPanelLineSelectPop:UpdateRankList()

    local dwID = self.nMapID
    local nRankSubID = 1
    if dwID == CampData.YINSHAN_MAP then
        nRankSubID = 1
    else
        nRankSubID = 2
    end 
    local GOOD_MAP = CampData.CAMP_MAP_ID[CAMP.GOOD] --25 --浩气盟地图
    local EVIL_MAP = CampData.CAMP_MAP_ID[CAMP.EVIL] --27 --恶人谷地图
    self.tbCopyInfo = GetCustomRankListByID(nGongFangType, nRankSubID)
    self.nCopyIndexNum = self.tbCopyInfo and self.tbCopyInfo.nKey or 0--分线数量
    if dwID ~= 0 and (self.bActivity or dwID == GOOD_MAP or dwID == EVIL_MAP) then
        self.nCopyIndexNum = self.nCopyIndexNum + 1
    end
    self:UpdateBranchPlayerNum()
    self:UpdateInfo()
end

function UIPanelLineSelectPop:UpdateBranchPlayerNum()
    local tbMapNumber = GetCampPlayerCountPerMap()
	if not tbMapNumber or IsTableEmpty(tbMapNumber) then
		return
	end
	local tbBranchNumber = {}
    for i = 1, self.nCopyIndexNum do
        for _, tbNumber in pairs(tbMapNumber) do
            if tbNumber.dwMapID == self.dwMapID then
                tbBranchNumber[i] = tbNumber
                break
            end
        end
    end
    self.tbBranchNumber = tbBranchNumber--各分线人数
end

function UIPanelLineSelectPop:UpdateBtnState()
    local dwSelectMap = self.nSelectMapID
    local nState = (dwSelectMap and dwSelectMap ~= 0) and BTN_STATE.Normal or BTN_STATE.Disable
    UIHelper.SetButtonState(self.BtnAccept, nState, nil, true)
end

function UIPanelLineSelectPop:UpdateMapList(tFightMap)
    self.tFightMap = tFightMap
    self:UpdateInfo()
end

function UIPanelLineSelectPop:GetRegularMap()
    local dwMapID   = self.nMapID
    local bActicity = self.bActivity
    local tFightMap = self.tFightMap
    local tMapList  = self.tbMapList
    local tResMap   = {}
    local hPlayer   = g_pClientPlayer

    local nGoodMapId = CampData.CAMP_MAP_ID[CAMP.GOOD]
    local nEvilMapID = CampData.CAMP_MAP_ID[CAMP.EVIL]

    if dwMapID == nGoodMapId and bActicity then
        table.insert(tResMap, nEvilMapID)
    elseif dwMapID == nEvilMapID and bActicity then
        table.insert(tResMap, nGoodMapId)
    elseif dwMapID == CampData.YINSHAN_MAP then
        for i, v in pairs(tFightMap) do
            if i ~= 0 then
                table.insert(tResMap, i)
            end
        end
    elseif tMapList then
        for _, v in pairs(tMapList) do
            if v ~= 0 then
                table.insert(tResMap, v)
            end
        end
    end
    return tResMap
end

return UIPanelLineSelectPop