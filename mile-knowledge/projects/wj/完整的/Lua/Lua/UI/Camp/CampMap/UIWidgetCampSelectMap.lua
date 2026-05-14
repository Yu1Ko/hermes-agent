-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetCampSelectMap
-- Date: 2024-04-20 18:00:20
-- Desc: 端游SelectCampPlanes.lua
-- ---------------------------------------------------------------------------------

local UIWidgetCampSelectMap = class("UIWidgetCampSelectMap")

local RANK_LIST_ID = 282 --大攻防分线排行榜
local YINSHAN_MAP = CampData.YINSHAN_MAP --216
local GOOD_MAP = CampData.CAMP_MAP_ID[CAMP.GOOD] --25
local EVIL_MAP = CampData.CAMP_MAP_ID[CAMP.EVIL] --27

local MAX_PEOPLE = 500
local DEFAULT_COPY = 1
-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(dwMapID, bActicity, tMapList)
    DataModel.dwMapID       = dwMapID
    DataModel.bActivity     = bActicity
    DataModel.nSelectCopy   = 0
    DataModel.dwSelectMapID = 0
    DataModel.tCopyInfo     = {}
    DataModel.tBranchNumber = {}
    DataModel.tFightMap     = {}
    DataModel.tMapList      = tMapList
    ApplyCustomRankList(RANK_LIST_ID)
end

function DataModel.Update()
    local dwID = DataModel.dwMapID
    local nRankSubID = 1
    if dwID == YINSHAN_MAP then
        nRankSubID = 1
    else
        nRankSubID = 2
    end
    DataModel.tCopyInfo = GetCustomRankListByID(RANK_LIST_ID, nRankSubID)
    DataModel.nCopyIndexNum = DataModel.tCopyInfo and DataModel.tCopyInfo.nKey or 0
    if dwID ~= 0 and (DataModel.bActivity or dwID == GOOD_MAP or dwID == EVIL_MAP) then
        DataModel.nCopyIndexNum = DataModel.nCopyIndexNum + 1
    end
    DataModel.UpdateBranchPlayerNum()
end

function DataModel.UpdateBranchPlayerNum()
    local tMapNumber = GetCampPlayerCountPerMap()
    if not tMapNumber or IsTableEmpty(tMapNumber) then
        return
    end
    local tBranchNumber = {}
    for i = 1, DataModel.nCopyIndexNum do
        for _, tNumber in pairs(tMapNumber) do
            if tNumber.dwMapID == DataModel.dwMapID and tNumber.nCopyIndex == i then
                tBranchNumber[i] = tNumber
                break
            end
        end
    end
    DataModel.tBranchNumber = tBranchNumber
end

function DataModel.GetRegularMap()
    local dwMapID   = DataModel.dwMapID
    local bActicity = DataModel.bActivity
    local tFightMap = DataModel.tFightMap
    local tMapList  = DataModel.tMapList
    local tResMap   = {}
    local hPlayer   = GetClientPlayer()
    local nCamp     = CAMP.NEUTRAL
    if hPlayer then
        nCamp = hPlayer.nCamp
    end

    if dwMapID == GOOD_MAP and bActicity then
        table.insert(tResMap, EVIL_MAP)
    elseif dwMapID == EVIL_MAP and bActicity then
        table.insert(tResMap, GOOD_MAP)
    elseif dwMapID == YINSHAN_MAP then
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

function DataModel.UnInit()
    for i, v in pairs(DataModel) do
        if type(v) ~= "function" then
            DataModel[i] = nil
        end
    end
end

function UIWidgetCampSelectMap:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetCampSelectMap:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCampSelectMap:BindUIEvent()
    
end

function UIWidgetCampSelectMap:RegEvent()
    Event.Reg(self, "CUSTOM_RANK_UPDATE", function(nRankListID)
        if not DataModel.dwMapID then
            return
        end
        
        if nRankListID == RANK_LIST_ID then
            DataModel.Update()
            self:UpdateList()
        end
    end)
    Event.Reg(self, "On_Camp_CastleFightMapList", function(tFightMap)
        DataModel.tFightMap = tFightMap
        self:UpdateList()
    end)
    Event.Reg(self, "ON_MAP_PLAYER_COUNT_UPDATE", function()
        DataModel.Update()
        self:UpdateList(true)
    end)
end

function UIWidgetCampSelectMap:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetCampSelectMap:UpdateInfo(dwMapID, bActicity, tMapList)
    DataModel.Init(dwMapID, bActicity, tMapList)
    self:UpdateList()
    RemoteCallToServer("On_Camp_CastleFightMapList")
end

function UIWidgetCampSelectMap:UpdateList(bUpdateCount)
    if not DataModel.dwMapID then
        return
    end

    local tCopyList   = DataModel.tCopyInfo or {}
    local tPeopleNum  = DataModel.tBranchNumber
    local dwMapID     = DataModel.dwMapID
    local bActivity   = DataModel.bActivity
    local nCount      = DataModel.nCopyIndexNum or 0
    local szMapName   = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
    local hPlayer     = GetClientPlayer()
    local nCamp       = CAMP.NEUTRAL
    local tMapNumber  = GetCampPlayerCountPerMap()
    local tRegularMap = DataModel.GetRegularMap()
    local nLineIndex  = 0
    if hPlayer then
        nCamp = hPlayer.nCamp
    end

    UIHelper.RemoveAllChildren(self.ScrollViewSelectMap)

    local szTitle
    if bActivity then
        szTitle = "阵营攻防战"
    elseif dwMapID == YINSHAN_MAP then
        szTitle = "逐鹿中原"
    else
        szTitle = szMapName
    end
    UIHelper.SetString(self.LabelSelectMapSubTitle, szTitle)

    --固定地图
    for _, dwRegularMapID in pairs(tRegularMap) do
        local szPerson
        local tData
        for _, v in pairs(tMapNumber) do
            if v.dwMapID == dwRegularMapID then
                tData = v
                break
            end
        end

        if tData then
            local nNumber, nLimit
            if nCamp == CAMP.GOOD then
                nNumber = tData.nGoodPlayerCount
                nLimit = tData.nMaxGoodPlayerCount
            elseif nCamp == CAMP.EVIL then
                nNumber = tData.nEvilPlayerCount
                nLimit = tData.nMaxEvilPlayerCount
            end

            szPerson = nNumber .. "/" .. nLimit .. g_tStrings.STR_PERSON
            if nNumber < 100 then
                szPerson = UIHelper.AttachTextColor(szPerson, FontColorID.ImportantGreen)
            elseif nNumber < 150 then
                szPerson = UIHelper.AttachTextColor(szPerson, FontColorID.ImportantYellow)
            elseif nNumber < 180 then
                szPerson = UIHelper.AttachTextColor(szPerson, FontColorID.Backup2_Orange)
            else
                szPerson = UIHelper.AttachTextColor(szPerson, FontColorID.ImportantRed)
            end
        end

        local nTipType = dwMapID ~= 0 and 1 --主战场
        UIMgr.AddPrefab(PREFAB_ID.WidgetLineupCity, self.ScrollViewSelectMap, dwRegularMapID, szPerson, nil, nTipType)
    end

    --分线
    for i = 1, nCount do
        local tNumber = tPeopleNum[i]
        local nNum = 0
        local nMaxCount = MAX_PEOPLE
        if tNumber then
            if nCamp == CAMP.GOOD then
                nNum = tNumber.nGoodPlayerCount
                nMaxCount = tNumber.nMaxGoodPlayerCount
            elseif nCamp == CAMP.EVIL then
                nNum = tNumber.nEvilPlayerCount
                nMaxCount = tNumber.nMaxEvilPlayerCount
            end
        end

        local szNum
        local nTipType
        if bActivity then
            nTipType = 2 --奇袭场
        elseif dwMapID == YINSHAN_MAP then
            nTipType = 3 --分线
        else
            szNum = FormatString(g_tStrings.STR_NEW_PQ_TYPE2, nNum, nMaxCount)
        end

        UIMgr.AddPrefab(PREFAB_ID.WidgetLineupCity, self.ScrollViewSelectMap, dwMapID, szNum, i, nTipType)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewSelectMap)
    if not bUpdateCount then
        UIHelper.ScrollToTop(self.ScrollViewSelectMap, 0)
    end
end


return UIWidgetCampSelectMap