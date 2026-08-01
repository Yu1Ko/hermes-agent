-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPersonalTitleView
-- Date: 2023-03-08 17:51:27
-- Desc: PanelPersonalTitle
-- ---------------------------------------------------------------------------------

local UIPersonalTitleView = class("UIPersonalTitleView")

local UPDATE_TYPE = {
    NONE = 1,
    UPDATE_CELL = 2,
    RESET = 3,
    RELOAD = 4,
}

local bLogSelectID = false
----------------------------------------------------- DataModel ---------------------------------------------------------------

local DataModel = {}
local TOTAL_VERSION_INDEX = 0
local TOTAL_VERSION_COUNT = 7

function DataModel.Init()
    DataModel.tDesignationList 		 = {}
    DataModel.tMyPrefixDesignation   = {}
    DataModel.tMyPostfixDesignation  = {}
    DataModel.tVersionDesignationNum = {}
    DataModel.tTypeDesignationNum	 = {}
    DataModel.nAllVersionHave		 = nil
    DataModel.nAllVersionNum		 = nil
    DataModel.nCDCount 				 = nil
    DataModel.nFilterType			 = nil
    DataModel.nFilterHave			 = nil
    DataModel.nFilterOther			 = nil
    DataModel.szSearchText 			 = nil
    DataModel.nSelVersion 			 = nil
    DataModel.nSelDesignationTitle 	 = nil
    DataModel.nSelDesignationType    = nil
    DataModel.nEditPrefixID	 		 = nil
    DataModel.nEditPostfixID	 	 = nil
    DataModel.nEditCourtesyID	 	 = nil

    DataModel.m_tDesignationPrefix   = nil
    DataModel.m_tDesignationPostfix  = nil
    DataModel.m_tDesignationForce    = nil

    DataModel.nSelVersion = TOTAL_VERSION_INDEX
    DataModel.UpdataMyDesignationList()
    DataModel.InitVersionDesignationNum()
end

function DataModel.UnInit()
    DataModel.tDesignationList 		 = nil
    DataModel.tMyPrefixDesignation   = nil
    DataModel.tMyPostfixDesignation  = nil
    DataModel.tVersionDesignationNum = nil
    DataModel.tTypeDesignationNum	 = nil
    DataModel.nAllVersionHave		 = nil
    DataModel.nAllVersionNum		 = nil
    DataModel.nCDCount 				 = nil
    DataModel.nFilterType			 = nil
    DataModel.nFilterHave			 = nil
    DataModel.nFilterOther			 = nil
    DataModel.szSearchText 			 = nil
    DataModel.nSelVersion 			 = nil
    DataModel.nSelDesignationTitle 	 = nil
    DataModel.nSelDesignationType    = nil
    DataModel.nEditPrefixID	 		 = nil
    DataModel.nEditPostfixID	 	 = nil
    DataModel.nEditCourtesyID	 	 = nil

    DataModel.m_tDesignationPrefix   = nil
    DataModel.m_tDesignationPostfix  = nil
    DataModel.m_tDesignationForce    = nil
end

--几个配置表封了一层get函数并且clone再拿出来，不然按照之前的写法会在配置表里写一些tLine.bHave之类的，重登之后就会导致本来的没有的称号显示拥有
--2024.1.4 改为在DesignationMgr.lua中在账号退出登录时重置配置表
function DataModel.Table_GetDesignationPrefix()
    if not DataModel.m_tDesignationPrefix then
        DataModel.m_tDesignationPrefix = clone(Table_GetDesignationPrefix())
    end
    return DataModel.m_tDesignationPrefix
end

function DataModel.Table_GetDesignationPostfix()
    if not DataModel.m_tDesignationPostfix then
        DataModel.m_tDesignationPostfix = clone(Table_GetDesignationPostfix())
    end
    return DataModel.m_tDesignationPostfix
end

function DataModel.Table_GetDesignationForce(dwForceID)
    if not DataModel.m_tDesignationForce then
        DataModel.m_tDesignationForce = {}
    end
    if not DataModel.m_tDesignationForce[dwForceID] then
        DataModel.m_tDesignationForce[dwForceID] = clone(Table_GetDesignationForce(dwForceID))
    end
    return DataModel.m_tDesignationForce[dwForceID]
end

function DataModel.Table_Clear()
    DataModel.m_tDesignationPrefix   = nil
    DataModel.m_tDesignationPostfix  = nil
    DataModel.m_tDesignationForce    = nil
end

function DataModel.UpdataMyDesignationList()
    DataModel.UpdateMyPrefixDesignation()
    DataModel.UpdateMyPostfixDesignation()
end

function DataModel.UpdateSelectDesignation() --筛选排序
    local function fnCmp(a, b)
        if (a.bHave and b.bHave) or (not a.bHave and not b.bHave) then
            if a.bIsEffect and  b.bIsEffect or (not a.bIsEffect and not b.bIsEffect) then
                return a.nQuality > b.nQuality
            elseif a.bIsEffect then
                return true
            elseif b.bIsEffect then
                return false
            end
        elseif a.bHave then
            return true
        elseif b.bHave then
            return false
        end

        --[[
        local bIsNewA = RedpointHelper.PersonalTitle_IsNew(a)
        local bIsNewB = RedpointHelper.PersonalTitle_IsNew(b)

        if (bIsNewA and bIsNewB) or (not bIsNewA and not bIsNewB) then
            if (a.bHave and b.bHave) or (not a.bHave and not b.bHave) then
                if a.bIsEffect and  b.bIsEffect or (not a.bIsEffect and not b.bIsEffect) then
                    return a.nQuality > b.nQuality
                elseif a.bIsEffect then
                    return true
                elseif b.bIsEffect then
                    return false
                end
            elseif a.bHave then
                return true
            elseif b.bHave then
                return false
            end
        elseif bIsNewA then
            return true
        else
            return false
        end
        ]]
    end
    local tDesignationList = {}
    local nSelType = DataModel.nSelDesignationType
    if nSelType == DESIGNATION_TYPE.ALL then
        DataModel.GetPrefixDesignationList(tDesignationList, DESIGNATION_TYPE.ALL)
        DataModel.GetPostfixDesignationList(tDesignationList)
        DataModel.GetCourtesyDesignationList(tDesignationList)
    elseif nSelType == DESIGNATION_TYPE.POSTFIX then
        DataModel.GetPostfixDesignationList(tDesignationList)
    elseif nSelType == DESIGNATION_TYPE.COURTESY then
        DataModel.GetCourtesyDesignationList(tDesignationList)
    else
        DataModel.GetPrefixDesignationList(tDesignationList, nSelType)
    end
    table.sort(tDesignationList, fnCmp)
    DataModel.tDesignationList = tDesignationList
end

function DataModel.GetPostfixDesignationList(tDesignationList)
    local tDesignationPostfix = DataModel.Table_GetDesignationPostfix()
    for _, tLine in pairs(tDesignationPostfix) do
        local dwID = tLine.dwID
        if DataModel.tMyPostfixDesignation[dwID] then
            tLine.bHave = true
        end
        tLine.nType = DESIGNATION_TYPE.POSTFIX
        if dwID ~= 0 then
            local tInfo = GetDesignationPostfixInfo(dwID)
            if tInfo and tInfo.nOwnDuration and tInfo.nOwnDuration ~= 0 then
                tLine.bLimit = true
            end
        end
        local bMatchFilter = DataModel.FilterDesignation(tLine)
        if bMatchFilter then
            table.insert(tDesignationList, tLine)
        end
    end
end

function DataModel.GetCourtesyDesignationList(tDesignationList)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tGen = DataModel.GetGenerationDesignation()
    local tDesignationForce = DataModel.Table_GetDesignationForce(pPlayer.dwForceID)
    if tDesignationForce then
        for _, tLine in pairs(tDesignationForce) do
            if tGen and tLine.dwGeneration == tGen.dwGeneration then
                tGen.nQuality = 1
                tGen.dwID = tGen.dwGeneration
                tGen.nType = DESIGNATION_TYPE.COURTESY
                local bMatchFilter = DataModel.FilterDesignation(tGen)
                if bMatchFilter then
                    table.insert(tDesignationList, tGen)
                end
            else
                tLine.nQuality = 1
                tLine.bDisable = true
                tLine.dwID = tLine.dwGeneration
                tLine.nType = DESIGNATION_TYPE.COURTESY
                local bMatchFilter = DataModel.FilterDesignation(tLine)
                if bMatchFilter then
                    table.insert(tDesignationList, tLine)
                end
            end
        end
    end
end

function DataModel.GetPrefixDesignationList(tDesignationList, nSelDesignationType)
    local tDesignationPrefix = DataModel.Table_GetDesignationPrefix()
    for _, tLine in pairs(tDesignationPrefix) do
        local dwID = tLine.dwID
        if DataModel.tMyPrefixDesignation[dwID] then
            tLine.bHave = true
        end
        local tInfo
        if dwID ~= 0 then
            tInfo = GetDesignationPrefixInfo(dwID)
            if tInfo and tInfo.nOwnDuration and tInfo.nOwnDuration ~= 0 then
                tLine.bLimit = true
            end
        end
        local bMatchFilter = DataModel.FilterDesignation(tLine)
        if tInfo and bMatchFilter then
            if tInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
                tLine.nType = DESIGNATION_TYPE.WORLD
                if nSelDesignationType == DESIGNATION_TYPE.WORLD then
                    table.insert(tDesignationList, tLine)
                end
            elseif tInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
                tLine.nType = DESIGNATION_TYPE.CAMP
                if not tLine.bHave then
                    tLine.bDisable = true
                end
                if nSelDesignationType == DESIGNATION_TYPE.CAMP then
                    table.insert(tDesignationList, tLine)
                end
            else
                tLine.nType = DESIGNATION_TYPE.PREFIX
                if nSelDesignationType == DESIGNATION_TYPE.PREFIX then
                    table.insert(tDesignationList, tLine)
                end
            end
            if nSelDesignationType == DESIGNATION_TYPE.ALL then
                table.insert(tDesignationList, tLine)
            end
        end
    end
end

function DataModel.FilterDesignation(tDesignation)
    local szSearchText  = DataModel.szSearchText
    local nFilterOther  = DataModel.nFilterOther
    local nFilterHave   = DataModel.nFilterHave
    local bMatchSearch  = not szSearchText or string.find(UIHelper.GBKToUTF8(tDesignation.szName), szSearchText) --StringMatchW(tDesignation.szName, szSearchText)
    local bMatchVersion	= DataModel.nSelVersion == TOTAL_VERSION_INDEX or tDesignation.nVersion == DataModel.nSelVersion
    local bMatchGainWay = not DataModel.nFilterType or tDesignation.nGainWayType == DataModel.nFilterType
    local bMatchOther
    local bMatchHave
    if not nFilterOther then
        bMatchOther = true
    elseif nFilterOther == 2 then
        bMatchOther = tDesignation.bIsEffect
    elseif nFilterOther == 3 then
        bMatchOther = tDesignation.bLimit
    elseif nFilterOther == 4 then
        bMatchOther = tDesignation.bChatShow
    end
    if not nFilterHave then
        bMatchHave = true
    elseif nFilterHave == 1 then
        bMatchHave = tDesignation.bHave
    elseif nFilterHave == 2 then
        bMatchHave = not tDesignation.bHave
    end
    return bMatchSearch and bMatchVersion and bMatchGainWay and bMatchOther and bMatchHave
end

function DataModel.GetGenerationDesignation()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tGen = g_tTable.Designation_Generation:Search(pPlayer.dwForceID, pPlayer.GetDesignationGeneration())
    tGen = clone(tGen) --上面Search里有第二个返回值，会导致clone把MetaTable也复制了，这里换了一行再clone
    if tGen then
        tGen.bHave = true
        if tGen.szCharacter and tGen.szCharacter ~= "" and not tGen.bSetNewName then
            local tCharacter = g_tTable[tGen.szCharacter]:Search(pPlayer.GetDesignationByname())
            if tCharacter then
                tGen.szName = tGen.szName .. tCharacter.szName
                tGen.bSetNewName = true
            end
        end
    end
    return tGen
end

function DataModel.UpdateMyPrefixDesignation()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tPrefixAll = pPlayer.GetAcquiredDesignationPrefix()
    DataModel.tMyPrefixDesignation = {}
    for i, dwID in ipairs(tPrefixAll) do
        local tInfo
        if dwID ~= 0 then
            tInfo = GetDesignationPrefixInfo(dwID)
        end
        if tInfo then
            DataModel.tMyPrefixDesignation[dwID] = {}
            if tInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
                DataModel.tMyPrefixDesignation[dwID].nType = DESIGNATION_TYPE.WORLD
            elseif tInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
                DataModel.tMyPrefixDesignation[dwID].nType = DESIGNATION_TYPE.CAMP
            else
                DataModel.tMyPrefixDesignation[dwID].nType = DESIGNATION_TYPE.PREFIX
            end
        end
    end
end

function DataModel.UpdateMyPostfixDesignation()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tPostfixAll = pPlayer.GetAcquiredDesignationPostfix()
    DataModel.tMyPostfixDesignation = {}
    for i, dwID in ipairs(tPostfixAll) do
        DataModel.tMyPostfixDesignation[dwID] = {}
        DataModel.tMyPostfixDesignation[dwID].nType = DESIGNATION_TYPE.POSTFIX
    end
end

function DataModel.InitCurrentDesignationType(dwLinkID, bPrefixLink)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local nPrefix = 0
    local nPostfix = 0
    local nCurrentPrefix  	 = pPlayer.GetCurrentDesignationPrefix()
    local nCurrentPostfix 	 = pPlayer.GetCurrentDesignationPostfix()
    local tCurrentPrefixInfo
    if nCurrentPrefix ~= 0 then
        tCurrentPrefixInfo = GetDesignationPrefixInfo(nCurrentPrefix)
    end
    if tCurrentPrefixInfo then
        nPrefix = nCurrentPrefix
        if DataModel.IsDesignationNeedCD(tCurrentPrefixInfo.dwCoolDownID) then
            DataModel.nCDCount = 0
        end
    end
    local tCurrentPostfixInfo
    if nCurrentPostfix ~= 0 then
        tCurrentPostfixInfo = GetDesignationPostfixInfo(nCurrentPostfix)
    end
    if tCurrentPostfixInfo then
        nPostfix = nCurrentPostfix
        if DataModel.IsDesignationNeedCD(tCurrentPostfixInfo.dwCoolDownID) then
            DataModel.nCDCount = 0
        end
    end
    if dwLinkID then
        if bPrefixLink then
            nPrefix = dwLinkID
        else
            nPostfix = dwLinkID
            local tInfo
            if nPrefix ~= 0 then
                tInfo = GetDesignationPrefixInfo(nPrefix)
            end
            if tInfo and tInfo.nType ~= DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
                nPrefix = 0
            end
        end
    end
    DataModel.nSelDesignationType  = DataModel.nSelDesignationType or DESIGNATION_TYPE.ALL
    DataModel.nSelDesignationTitle = DESIGNATION_TITLE.UNIQUE
    DataModel.nEditPrefixID   	   = nPrefix
    DataModel.nEditPostfixID  	   = nPostfix
    DataModel.nEditCourtesyID  	   = 0
    local tPrefixInfo
    if nPrefix ~= 0 then
        tPrefixInfo = GetDesignationPrefixInfo(nPrefix)
    end
    if tPrefixInfo then
        if tPrefixInfo.nType == DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
            DataModel.nSelDesignationTitle = DESIGNATION_TITLE.COMPOSE
        else
            DataModel.nEditPostfixID = 0
            DataModel.nEditCourtesyID = 0
            return
        end
    end

    local tPostInfo
    if nPostfix ~= 0 then
        tPostInfo = GetDesignationPostfixInfo(nPostfix)
    end
    if tPostInfo then
        DataModel.nSelDesignationTitle = DESIGNATION_TITLE.COMPOSE
    end

    if pPlayer.GetDesignationBynameDisplayFlag() then
        DataModel.nSelDesignationTitle = DESIGNATION_TITLE.COMPOSE
        DataModel.nEditCourtesyID	   = pPlayer.GetDesignationGeneration()
    end
end

function DataModel.CountVersionDesignationNum(tDesignationList, tVersionNum, bPrefix)
    local tMyDesignation
    if bPrefix then
        tMyDesignation = DataModel.tMyPrefixDesignation
    else
        tMyDesignation = DataModel.tMyPostfixDesignation
    end
    for _, tLine in pairs(tDesignationList) do
        local dwID = tLine.dwID
        local nVersion = tLine.nVersion
        if bPrefix and dwID ~= 0 then
            local tInfo = GetDesignationPrefixInfo(dwID)
            if not tInfo then
                LOG.ERROR("GetDesignationPrefixInfo Error: %s", tostring(dwID))
            end
            if tInfo and tInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then --战阶称号特判
                tLine.bDisable = true
            end
        end
        if tMyDesignation[dwID] then
            DataModel.nAllVersionHave = DataModel.nAllVersionHave + 1
            DataModel.nAllVersionNum = DataModel.nAllVersionNum + 1
            if tVersionNum[nVersion] then
                tVersionNum[nVersion].nHaveNum = tVersionNum[nVersion].nHaveNum + 1
                tVersionNum[nVersion].nAllNum = tVersionNum[nVersion].nAllNum + 1
            end
        elseif not tLine.bOutOfPrint and not tLine.bDisable then
            DataModel.nAllVersionNum = DataModel.nAllVersionNum + 1
            if tVersionNum[nVersion] then
                tVersionNum[nVersion].nAllNum = tVersionNum[nVersion].nAllNum + 1
            end
        end
    end
end

function DataModel.InitVersionDesignationNum()
    local tVersionNum = {}
    DataModel.nAllVersionHave = 0
    DataModel.nAllVersionNum  = 0
    local tVersionInfo = Table_GetDesignationVersionInfo()
    for _, tInfo in ipairs(tVersionInfo) do
        local nIndex = tInfo.nIndex
        tVersionNum[nIndex] = {}
        tVersionNum[nIndex].nHaveNum = 0
        tVersionNum[nIndex].nAllNum  = 0
    end
    local tDesignationPrefix  = DataModel.Table_GetDesignationPrefix()
    local tDesignationPostfix = DataModel.Table_GetDesignationPostfix()
    DataModel.CountVersionDesignationNum(tDesignationPrefix, tVersionNum, true)
    DataModel.CountVersionDesignationNum(tDesignationPostfix, tVersionNum)
    if DataModel.GetGenerationDesignation() then
        DataModel.nAllVersionHave = DataModel.nAllVersionHave + 1
        DataModel.nAllVersionNum  = DataModel.nAllVersionNum + 1
    end
    DataModel.tVersionDesignationNum = tVersionNum
end

function DataModel.CountTypeDesignationNum(tDesignationList, tTypeNum)
    local nAllType = DESIGNATION_TYPE.ALL
    for _, tLine in pairs(tDesignationList) do
        local dwID = tLine.dwID
        local nType = tLine.nType
        if tLine.bHave then
            tTypeNum[nAllType].nHaveNum = tTypeNum[nAllType].nHaveNum + 1
            tTypeNum[nAllType].nAllNum = tTypeNum[nAllType].nAllNum + 1
            if tTypeNum[nType] then
                tTypeNum[nType].nHaveNum = tTypeNum[nType].nHaveNum + 1
                tTypeNum[nType].nAllNum = tTypeNum[nType].nAllNum + 1
            end
        elseif not tLine.bOutOfPrint and not tLine.bDisable then
            tTypeNum[nAllType].nAllNum = tTypeNum[nAllType].nAllNum + 1
            if tTypeNum[nType] then
                tTypeNum[nType].nAllNum = tTypeNum[nType].nAllNum + 1
            end
        end
    end
end

function DataModel.InitTypeDesignationNum()
    local tTypeNum = {}
    for _, nType in pairs(DESIGNATION_TYPE) do
        tTypeNum[nType] = {}
        tTypeNum[nType].nHaveNum = 0
        tTypeNum[nType].nAllNum  = 0
    end
    local tDesignationList = {}
    DataModel.GetPrefixDesignationList(tDesignationList, DESIGNATION_TYPE.ALL)
    DataModel.GetPostfixDesignationList(tDesignationList)
    DataModel.GetCourtesyDesignationList(tDesignationList)
    DataModel.CountTypeDesignationNum(tDesignationList, tTypeNum)
    DataModel.tTypeDesignationNum = tTypeNum
end

function DataModel.IsDesignationNeedCD(dwCoolDownID)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local nTime = pPlayer.GetCDLeft(dwCoolDownID)
    if nTime and nTime > 0 then
        return true
    end
    return false
end

function DataModel.IsEditDesignationChange(nEditPrefixID, nEditPostfixID, nEditCourtesyID)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    nEditPrefixID = nEditPrefixID or DataModel.nEditPrefixID
    nEditPostfixID = nEditPostfixID or DataModel.nEditPostfixID
    nEditCourtesyID = nEditCourtesyID or DataModel.nEditCourtesyID

    local nCurrentPrefix    = pPlayer.GetCurrentDesignationPrefix()
    local nCurrentPostfix   = pPlayer.GetCurrentDesignationPostfix()
    local bEquipCourtesy    = pPlayer.GetDesignationBynameDisplayFlag()
    local bPrefixChange     = nEditPrefixID ~= nCurrentPrefix
    local bPostfixChange    = nEditPostfixID ~= nCurrentPostfix
    local bCourtesyChange   = false
    if bEquipCourtesy then
        bCourtesyChange = nEditCourtesyID ~= pPlayer.GetDesignationGeneration()
    else
        bCourtesyChange = nEditCourtesyID ~= 0
    end
    return bPrefixChange, bPostfixChange, bCourtesyChange
end

---------------- 以下新增 ----------------

function DataModel.GetPlayerCurrentDesignation()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local nCurrentPrefixID   = pPlayer.GetCurrentDesignationPrefix()
    local nCurrentPostfixID  = pPlayer.GetCurrentDesignationPostfix()
    local nCurrentCourtesyID = pPlayer.GetDesignationBynameDisplayFlag() and pPlayer.GetDesignationGeneration() or 0

    return nCurrentPrefixID, nCurrentPostfixID, nCurrentCourtesyID
end

--若当前正在Edit的称号玩家未获得，则替换为0返回
function DataModel.GetRealDesignation(nPrefixID, nPostfixID, nCourtesyID)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    nPrefixID = nPrefixID or DataModel.nEditPrefixID
    nPostfixID = nPostfixID or DataModel.nEditPostfixID
    nCourtesyID = nCourtesyID or DataModel.nEditCourtesyID

    local tGen = g_tTable.Designation_Generation:Search(pPlayer.dwForceID, pPlayer.GetDesignationGeneration())
    local bPrefixHave = nPrefixID == 0 or DataModel.tMyPrefixDesignation[nPrefixID]
    local bPostfixHave = nPostfixID == 0 or DataModel.tMyPostfixDesignation[nPostfixID]
    local bCourtesyHave = nCourtesyID == 0 or (tGen and tGen.dwGeneration == nCourtesyID)

    if not bPrefixHave then nPrefixID = 0 end
    if not bPostfixHave then nPostfixID = 0 end
    if not bCourtesyHave then nCourtesyID = 0 end

    return nPrefixID, nPostfixID, nCourtesyID
end

------------------------------------------------------------------------------------------------------------------------------------

function UIPersonalTitleView:OnEnter(dwLinkID, bPrefixLink)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.scriptDetail = UIHelper.GetBindScript(self.WidgetAnchorRight) --UIWidgetPersonalTitleDetail

        --UIHelper.SetSwallowTouches(self.ScrollViewLeft, false)

        Timer.AddFrameCycle(self, 1, function()
            self:OnUpdate()
        end)
    end

    self:InitUI()
    self:UpdateInfo(dwLinkID, bPrefixLink)

    UIMgr.HideView(VIEW_ID.PanelCharacter)
end

function UIPersonalTitleView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    self:UnInitScrollList()
    DataModel.UnInit()

    RedpointHelper.PersonalTitle_ClearAll()
    UIMgr.ShowView(VIEW_ID.PanelCharacter)
end

function UIPersonalTitleView:OnUpdate()
    if DataModel.nCDCount then
        if DataModel.nCDCount == 0 then
            DataModel.nCDCount = 10
            self:UpdateCDInfo()
        else
            DataModel.nCDCount = DataModel.nCDCount - 1
        end
    end
end

function UIPersonalTitleView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnPurchase, EventType.OnClick, function()
        DataModel.nEditPrefixID = 0
        DataModel.nEditPostfixID = 0
        DataModel.nEditCourtesyID = 0
        self:ChangeCurrentDesignation() --直接生效
    end)
    UIHelper.BindUIEvent(self.BtnPurchase01, EventType.OnClick, function()
        self:ChangeCurrentDesignation()
    end)
    UIHelper.BindUIEvent(self.BtnMask, EventType.OnClick, function()
        self:CloseTips()
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        --取消搜索
        UIHelper.SetString(self.WidgetEdit, "")
        self:UpdateDesignationList(UPDATE_TYPE.RESET)
        self:UpdateDesignationTypeNum()
        self:UpdateRedPointArrow()
    end)
    UIHelper.BindUIEvent(self.BtnScreen, EventType.OnClick, function(_, bSelected)
        local tips, _ = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnScreen, TipsLayoutDir.BOTTOM_LEFT, FilterDef.Designation)
        local nWidth = UIHelper.GetWidth(self.BtnScreen)
        tips:SetOffset(-nWidth)
        tips:Update()
    end)
    UIHelper.BindUIEvent(self.BtnDLC, EventType.OnClick, function(_, bSelected)
        local tips, _ = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnDLC, TipsLayoutDir.BOTTOM_LEFT, FilterDef.Designation_DLC)
        local nWidth = UIHelper.GetWidth(self.BtnDLC)
        tips:SetOffset(-nWidth)
        tips:Update()
    end)
    UIHelper.BindUIEvent(self.LayoutMiddle, EventType.OnClick, function()
        self:CloseTips()
    end)
    UIHelper.RegisterEditBoxChanged(self.WidgetEdit, function()
        self:UpdateDesignationList(UPDATE_TYPE.RESET)
        self:UpdateDesignationTypeNum()
        self:UpdateRedPointArrow()
    end)

    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function()
        self:GoToCorationView(true)
    end)

    UIHelper.BindUIEvent(self.BtnAddDecorationItem, EventType.OnClick,  function()
        self:GoToCorationView(true)
    end)

    UIHelper.BindUIEvent(self.BtnDecoration, EventType.OnClick,  function()
        self:GoToCorationView()
    end)


    UIHelper.SetVisible(self.BtnDecoration, Const.EnableDesignationDecoration)
    UIHelper.SetVisible(self.BtnAddDecorationItem, Const.EnableDesignationDecoration)
    UIHelper.SetVisible(self.BtnChange, Const.EnableDesignationDecoration)
    UIHelper.SetVisible(self.ImgDecorationEmpty, Const.EnableDesignationDecoration)
    
end

function UIPersonalTitleView:RegEvent()
    Event.Reg(self, "SYNC_DESIGNATION_DATA", function(dwPlayerID)
        print("[Designation] SYNC_DESIGNATION_DATA", dwPlayerID)
        self:OnCheckUpdateDesignation(dwPlayerID, UPDATE_TYPE.RESET)
    end)
    Event.Reg(self, "SET_CURRENT_DESIGNATION", function(dwPlayerID, nPrefix, nPostfix, bBynameDisplay)
        print("[Designation] SET_CURRENT_DESIGNATION", dwPlayerID, nPrefix, nPostfix, bBynameDisplay)
        self:OnCheckUpdateDesignation(dwPlayerID, UPDATE_TYPE.UPDATE_CELL)
    end)
    Event.Reg(self, "SET_GENERATION_NOTIFY", function(dwPlayerID, nGenerationIndex, nNameInForceIndex)
        print("[Designation] SET_GENERATION_NOTIFY", dwPlayerID, nGenerationIndex, nNameInForceIndex)
        self:OnCheckUpdateDesignation(dwPlayerID, UPDATE_TYPE.UPDATE_CELL)
    end)
    Event.Reg(self, "ACQUIRE_DESIGNATION", function(nPrefix, nPostfix)
        print("[Designation] ACQUIRE_DESIGNATION", nPrefix, nPostfix)
        self:OnUpdateDesignation(nPrefix, nPostfix)
    end)
    Event.Reg(self, "REMOVE_DESIGNATION", function(nPrefix, nPostfix)
        print("[Designation] REMOVE_DESIGNATION", nPrefix, nPostfix)
        self:OnUpdateDesignation(nPrefix, nPostfix, true)
    end)
    Event.Reg(self, EventType.OnTouchViewBackGround, function(tInfo)
        self:CloseTips()
    end)
    Event.Reg(self, EventType.OnUIScrollListTouchMove, function()
        self:UpdateRedPointArrow()
    end)
    Event.Reg(self, EventType.OnUIScrollListTouchEnd, function()
        self:UpdateRedPointArrow()
    end)
    Event.Reg(self, EventType.OnUIScrollListMouseWhell, function()
        self:UpdateRedPointArrow()
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        local nWidth, _ = UIHelper.GetContentSize(self.LayoutMiddle)
        UIHelper.SetContentSize(self.tScrollList.m.contentNode, nWidth, 0) --设置宽度，用于宽屏Layout适配
        self:UpdateRedPointArrow()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.Designation.Key then
            self:OnFilterConfirmClick(tbSelected)
        elseif szKey == FilterDef.Designation_DLC.Key then
            self:OnFilterConfirmClick_DLC(tbSelected)
        end
    end)
end

function UIPersonalTitleView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPersonalTitleView:InitUI()
    CharacterAvartarData.bOpenThisAfterCloseAccessory = false

    DataModel.Init()
    DataModel.InitCurrentDesignationType()

    self:InitTypeToggle()
    self:InitScrollList()

    FilterDef.Designation.Reset()
    FilterDef.Designation_DLC.Reset()

    self:CloseTips()
    self:UpdateCDInfo()
    self:UpdateFilterBtnState()
end

--左边称号类型
function UIPersonalTitleView:InitTypeToggle()
    -- UIHelper.RemoveAllChildren(self.LayoutAllCell)
    -- UIHelper.RemoveAllChildren(self.LayoutUniqueCell)
    -- UIHelper.RemoveAllChildren(self.LayoutGroupCell)
    -- self.tScriptTogType = {}
    -- self.tScriptTogType[DESIGNATION_TYPE.ALL] = UIMgr.AddPrefab(PREFAB_ID.WidgetPersonalTitleTog, self.LayoutAllCell)
    -- self.tScriptTogType[DESIGNATION_TYPE.WORLD] = UIMgr.AddPrefab(PREFAB_ID.WidgetPersonalTitleTog, self.LayoutUniqueCell)
    -- self.tScriptTogType[DESIGNATION_TYPE.CAMP] = UIMgr.AddPrefab(PREFAB_ID.WidgetPersonalTitleTog, self.LayoutUniqueCell)
    -- self.tScriptTogType[DESIGNATION_TYPE.PREFIX] = UIMgr.AddPrefab(PREFAB_ID.WidgetPersonalTitleTog, self.LayoutGroupCell)
    -- self.tScriptTogType[DESIGNATION_TYPE.POSTFIX] = UIMgr.AddPrefab(PREFAB_ID.WidgetPersonalTitleTog, self.LayoutGroupCell)
    -- self.tScriptTogType[DESIGNATION_TYPE.COURTESY] = UIMgr.AddPrefab(PREFAB_ID.WidgetPersonalTitleTog, self.LayoutGroupCell)

    self.tScriptTogType = {}
    for _, nType in pairs(DESIGNATION_TYPE) do
        self.tScriptTogType[nType] = UIHelper.GetBindScript(self.tTogType[nType])
    end

    for nType, scriptTogType in ipairs(self.tScriptTogType) do
        scriptTogType:RegisterToggleGroup(self.ToggleGroupLeft)
        scriptTogType:SetText(g_tStrings.tDesignationTitleShort[nType])
        scriptTogType:SetSelectedCallback(function(bSelected)
            self:OnTypeToggleSelected(nType, bSelected)
        end)
    end

    -- UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewLeft, true, true)
    -- UIHelper.ScrollViewDoLayout(self.ScrollViewLeft)
    -- UIHelper.ScrollToTop(self.ScrollViewLeft, 0)
end

function UIPersonalTitleView:InitScrollList()
    self:UnInitScrollList()
    self.tScrollList = UIScrollList.Create({
        listNode = self.LayoutMiddle,
        bSlowRebound = true,
        fnGetCellType = function() return PREFAB_ID.WidgetPersonalTitleContentDoubleTog end,
        fnUpdateCell = function(cell, nIndex)
            self:OnScrollListCellUpdate(cell, nIndex)
        end,
    })
    self.tScrollList:SetScrollBarEnabled(true)

    local nWidth, _ = UIHelper.GetContentSize(self.LayoutMiddle)
    UIHelper.SetContentSize(self.tScrollList.m.contentNode, nWidth, 0) --设置宽度，用于宽屏Layout适配
end

function UIPersonalTitleView:UnInitScrollList()
    if self.tScrollList then
        self.tScrollList:Destroy()
        self.tScrollList = nil
    end
end

function UIPersonalTitleView:OnScrollListCellUpdate(cell, nIndex)
    if not cell then return end

    --因为ScrollList不支持一行显示多个，所以通过将一排多个Prefab组成一个Prefab的方式来实现需求
    local nIndex1 = nIndex * 3 - 2
    local nIndex2 = nIndex * 3 - 1
    local nIndex3 = nIndex * 3

    local tData1 = self.tViewList[nIndex1]
    local tData2 = self.tViewList[nIndex2] --可空
    local tData3 = self.tViewList[nIndex3] --可空

    local fnSelectedCallback1 = tData1 and function(bSelected)
        self:OnScrollListCellSelected(nIndex1, bSelected)
    end

    local fnSelectedCallback2 = tData2 and function(bSelected)
        self:OnScrollListCellSelected(nIndex2, bSelected)
    end

    local fnSelectedCallback3 = tData3 and function(bSelected)
        self:OnScrollListCellSelected(nIndex3, bSelected)
    end

    cell:UpdateInfo(tData1, tData2, tData3, fnSelectedCallback1, fnSelectedCallback2, fnSelectedCallback3)
end

--中间列表项选中
function UIPersonalTitleView:OnScrollListCellSelected(nIndex, bSelected)
    local tData = self.tViewList[nIndex]
    if not tData then return end

    if bLogSelectID then
        LOG.INFO(tostring(nIndex))
    end

    self:UpdateDesignationDetail(tData)
    self:ChangeEditDesignation(tData)

    --记录当前的选择，使列表刷新后保持选择
    self.nTempPrefixID = DataModel.nEditPrefixID
    self.nTempPostfixID = DataModel.nEditPostfixID
    self.nTempCourtesyID = DataModel.nEditCourtesyID
    self.nTempTitle = DataModel.nSelDesignationTitle
end

--点击左边称号类型Toggle
function UIPersonalTitleView:OnTypeToggleSelected(nType, bSelected)
    if self.bSelectingFlag then return end
    self.bSelectingFlag = true
    if bSelected then
        self:SelectDesignationType(nType)
    end
    self.bSelectingFlag = false
end

--确认筛选
function UIPersonalTitleView:OnFilterConfirmClick(tbSelected)
    DataModel.nFilterOther = (tbSelected[1][1] ~= 1) and tbSelected[1][1] or nil
    DataModel.nFilterHave = (tbSelected[2][1] ~= 1) and (tbSelected[2][1] - 1) or nil
    DataModel.nFilterType = (tbSelected[3][1] ~= 1) and (tbSelected[3][1] - 1) or nil
    -- DataModel.nSelVersion = (tbSelected[4][1] ~= 1) and (tbSelected[4][1] - 1) or TOTAL_VERSION_INDEX

    self:UpdateFilterBtnState()
    self:UpdateDesignationList(UPDATE_TYPE.RESET)
    self:UpdateDesignationTypeNum()
    self:UpdateRedPointArrow()
end

function UIPersonalTitleView:OnFilterConfirmClick_DLC(tbSelected)
    DataModel.nSelVersion = (tbSelected[1][1] ~= 1) and (tbSelected[1][1] - 1) or TOTAL_VERSION_INDEX

    self:UpdateDesignationList(UPDATE_TYPE.RESET)
    self:UpdateDesignationTypeNum()
    self:UpdateRedPointArrow()
end

--因为ScrollList不支持一行显示多个，所以通过将一排多个Prefab组成一个Prefab的方式来实现需求，这里做索引变换
function UIPersonalTitleView:TableIndexToScrollListIndex(nTableIndex)
    return math.ceil(nTableIndex / 3)
end

----------------------------------------------------- View ---------------------------------------------------------------

function UIPersonalTitleView:UpdateInfo(dwLinkID, bPrefixLink)
    if dwLinkID then
        self:UpdateLinkShow(dwLinkID, bPrefixLink)
    else
        DataModel.InitCurrentDesignationType()
        self:UpdateDesignationTypeNum()

        --self:Update(UPDATE_TYPE.NONE)
        self:UpdateDesignationTitleContent()
    end
    self:SelectDesignationType(DESIGNATION_TYPE.ALL, true)
end

--收到事件后判断角色ID并更新
function UIPersonalTitleView:OnCheckUpdateDesignation(dwID, nUpdateType)
    local player = GetClientPlayer()
    if player and player.dwID == dwID then
        DataModel.InitCurrentDesignationType()

        --还原卸下/应用称号前的选中项
        if self.nTempPrefixID then DataModel.nEditPrefixID = self.nTempPrefixID end
        if self.nTempPostfixID then DataModel.nEditPostfixID = self.nTempPostfixID end
        if self.nTempCourtesyID then DataModel.nEditCourtesyID = self.nTempCourtesyID end
        if self.nTempTitle then DataModel.nSelDesignationTitle = self.nTempTitle end

        self:Update(nUpdateType)
    end
end

function UIPersonalTitleView:OnUpdateDesignation(nPrefix, nPostfix, bRemove)
    local bPrefixLink, dwLinkID
    if nPrefix ~= 0 then
        bPrefixLink = true
        dwLinkID 	 = nPrefix
    elseif nPostfix ~= 0 then
        bPrefixLink = false
        dwLinkID 	 = nPostfix
    end

    DataModel.UpdataMyDesignationList()
    DataModel.InitVersionDesignationNum()

    self:UpdateLinkShow(dwLinkID, bPrefixLink, bRemove)
end

function UIPersonalTitleView:Update(nUpdateType)
    self:UpdateDesignationTitleContent()
    self:UpdateDesignationList(nUpdateType)
    self:UpdateRedPointArrow()
end

--称号数量统计；注意战阶称号和门派称号显示1/1或者0/0这种是正常的
function UIPersonalTitleView:UpdateDesignationTypeNum()
    DataModel.InitTypeDesignationNum()
    local tTypeNum = DataModel.tTypeDesignationNum
    for nType, scriptTogType in ipairs(self.tScriptTogType) do
        local nHaveNum = tTypeNum[nType].nHaveNum
        local nAllNum  = tTypeNum[nType].nAllNum
        scriptTogType:SetNumberText(nHaveNum .. "/" .. nAllNum)
    end

    local nSelType = DataModel.nSelDesignationType
    if not nSelType then
        return
    end

    local tTypeNum = DataModel.tTypeDesignationNum
    local nHaveNum = tTypeNum[nSelType].nHaveNum
    local nAllNum = tTypeNum[nSelType].nAllNum

    UIHelper.SetString(self.LabelCategory, g_tStrings.tDesignationTitleLong[nSelType])
    UIHelper.SetString(self.LabelNum, "（" .. nHaveNum .. "/" .. nAllNum .. "）")
    UIHelper.LayoutDoLayout(self.LayoutNum)
end

--根据ID获取战阶名字和类型
function UIPersonalTitleView:GetDesignationInfo(nPrefixID, nPostfixID, nCourtesyID)
    local szName, szType

    local tPrefixInfo = nPrefixID and nPrefixID ~= 0 and GetDesignationPrefixInfo(nPrefixID)
    if tPrefixInfo and tPrefixInfo.nType ~= DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
        local t = Table_GetDesignationPrefixByID(nPrefixID, UI_GetPlayerForceID())
        szName = t and UIHelper.GBKToUTF8(t.szName) or ""
        if tPrefixInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
            szType = "世界称号"
        elseif tPrefixInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
            szType = "战阶称号"
        end
    else
        local szPrefixName    = ""
        local szPostfixName   = ""
        local szCourtesyName  = ""
        if nPrefixID and nPrefixID ~= 0 then
            if tPrefixInfo.nType == DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
                local t = Table_GetDesignationPrefixByID(nPrefixID, UI_GetPlayerForceID())
                szPrefixName = t and t.szName or ""
            end
        end
        if nPostfixID and nPostfixID ~= 0 then
            szPostfixName = g_tTable.Designation_Postfix:Search(nPostfixID).szName
        end
        local tGen = DataModel.GetGenerationDesignation()
        if nCourtesyID and nCourtesyID ~= 0 then
            szCourtesyName = tGen.szName
        end
        szName = UIHelper.GBKToUTF8(szPrefixName .. szPostfixName .. szCourtesyName)
        szType = "组合称号"
    end
    return szName, szType
end

--更新下方当前称号和称号预览，注意这里在将称号从独占和组合互切时会清掉DataModel中部分数据
function UIPersonalTitleView:UpdateDesignationTitleContent()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local nTitle = DataModel.nSelDesignationTitle

    local nPrefixID, nPostfixID, nCourtesyID = DataModel.GetRealDesignation()
    local nCurPrefixID, nCurPostfixID, nCurCourtesyID = DataModel.GetPlayerCurrentDesignation()

    local bPrefixChange, bPostfixChange, bCourtesyChange = DataModel.IsEditDesignationChange(nPrefixID, nPostfixID, nCourtesyID)
    local bChange = bPrefixChange or bPostfixChange or bCourtesyChange
    local bShowTime = DataModel.nCDCount ~= nil

    --应用称号按钮状态
    local bEnabled
    if nTitle == DESIGNATION_TITLE.UNIQUE then
        --若从组合称号切到独占称号，将另外两个ID清掉
        nPostfixID = 0
        nCourtesyID = 0
        DataModel.nEditPostfixID  = 0
        DataModel.nEditCourtesyID = 0
        bEnabled = bPrefixChange and not bShowTime and nPrefixID ~= 0
    elseif nTitle == DESIGNATION_TITLE.COMPOSE then
        --若从独占称号切到组合称号，且当前前缀是世界称号或战阶称号（即独占称号类型的前缀）则清掉
        local nEditPrefixID = DataModel.nEditPrefixID
        if nEditPrefixID ~= 0 then
            local tInfo = GetDesignationPrefixInfo(nEditPrefixID)
            if tInfo.nType ~= DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
                nPrefixID = 0
                DataModel.nEditPrefixID = 0
            end
        end
        bEnabled = bChange and not bShowTime and (nPrefixID ~= 0 or nPostfixID ~= 0 or nCourtesyID ~= 0)
    end

    local szCurrentName, szCurrentType = self:GetDesignationInfo(nCurPrefixID, nCurPostfixID, nCurCourtesyID)
    local bNotEmpty = szCurrentName and szCurrentName ~= ""
    if szCurrentName and szCurrentName ~= "" then
        UIHelper.SetString(self.LabelSky02, szCurrentName)
        UIHelper.SetString(self.LabelSwitchTitel, szCurrentType)
    end
    local dwNowID = pPlayer.GetDesignationDecoration() or 1
    local tDecorationInfo = Table_GetDesignationDecorationInfo(dwNowID)
    if not IsVersionExp() then
        UIHelper.RichTextIgnoreContentAdaptWithSize(self.LabelSky, true)
        local width = 0
        if tDecorationInfo and dwNowID ~= 0 then
            UIHelper.SetVisible(self.ImgDecorationEmpty, false)
            UIHelper.SetVisible(self.BtnAddDecorationItem,  false)
            UIHelper.SetVisible(self.BtnChange, Const.EnableDesignationDecoration and true)
            UIHelper.UpdateDesignationDecorationFarme(tDecorationInfo, self.ImgDecoration_Private, self.Eff_Decoration_Private,self.LabelSky, szCurrentName)
            if tDecorationInfo.szImgPath ~= "" then
                width = UIHelper.GetWidth(self.ImgDecoration_Private)
            elseif tDecorationInfo.szSfxPath ~= "" then
                width = UIHelper.GetWidth(self.ImgDecoration_Private)
            end
        else
            UIHelper.SetVisible(self.ImgDecorationEmpty, Const.EnableDesignationDecoration and true)
            UIHelper.SetVisible(self.BtnAddDecorationItem, Const.EnableDesignationDecoration and true)
            UIHelper.SetVisible(self.BtnChange, false)
            
            UIHelper.SetRichText(self.LabelSky, string.format("<color=#ffffff><shadow=#00003232&0&1>%s</shadow></c>",szCurrentName))
        end
        if width > 0 then
            UIHelper.SetPositionX(self.LayoutTitle, (width - UIHelper.GetWidth(self.LabelSky))*0.5)
        end
    else
        UIHelper.SetRichText(self.LabelSky, string.format("<color=#ffffff><shadow=#00003232&0&1>%s</shadow></c>",szCurrentName))
    end
   

    local bShowSwitch = false
    if bChange then
        local width = 0
        local szSwitchName, szSwitchType = self:GetDesignationInfo(nPrefixID, nPostfixID, nCourtesyID)
       -- UIHelper.SetString(self.LabelSky01, szSwitchName)
        UIHelper.SetString(self.LabelSwitchTitel01, szSwitchType)
        bShowSwitch = szSwitchName and szSwitchName ~= "" and szSwitchName ~= szCurrentName

        if not IsVersionExp() then
            UIHelper.RichTextIgnoreContentAdaptWithSize(self.LabelSky01, true)
            if tDecorationInfo then
                UIHelper.UpdateDesignationDecorationFarme(tDecorationInfo, self.ImgDecoration_Preview, self.Eff_Decoration_Preview,self.LabelSky01,szSwitchName)
                if tDecorationInfo.szImgPath ~= "" then
                    width = UIHelper.GetWidth(self.ImgDecoration_Preview)
                elseif tDecorationInfo.szSfxPath ~= "" then
                    width = UIHelper.GetWidth(self.ImgDecoration_Preview)
                end
            else
                UIHelper.SetRichText(self.LabelSky01, string.format("<color=#ffffff><shadow=#00003232&0&1>%s</shadow></c>",szSwitchName))
            end
            if width > 0 then
                UIHelper.SetPositionX(self.LabelSky01, (width - UIHelper.GetWidth(self.LabelSky01))*0.5)
            end
        else
            UIHelper.SetRichText(self.LabelSky01, string.format("<color=#ffffff><shadow=#00003232&0&1>%s</shadow></c>",szSwitchName))
        end
    end

    UIHelper.SetVisible(self.ImgSky, not bNotEmpty) --暂无配置称号
    UIHelper.SetVisible(self.WidgetPrevious, bNotEmpty)
    UIHelper.SetVisible(self.WidgetPreview, bShowSwitch)
    UIHelper.SetVisible(self.ImgSwitch, bShowSwitch)

    UIHelper.CascadeDoLayoutDoWidget(self.WidgetSwitch, true, true)

    UIHelper.SetButtonState(self.BtnPurchase, (bNotEmpty and not bShowTime) and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnPurchase01, bEnabled and BTN_STATE.Normal or BTN_STATE.Disable)

    UIHelper.SetVisible(self.WidgetBottomBtn, not bShowTime)
end

--更新右侧称号详细信息
function UIPersonalTitleView:UpdateDesignationDetail(tData, bLink, bInit)
    UIHelper.SetVisible(self.WidgetAnchorRight, true)
    if self.scriptDetail then
        self.scriptDetail:UpdateInfo(tData, bLink, bInit) --拆出去了，不然代码太多了：UIWidgetPersonalTitleDetail
    end
end

--获得/失去称号时刷新显示
function UIPersonalTitleView:UpdateLinkShow(dwLinkID, bPrefixLink, bRemove)
    if not dwLinkID then
        return
    end

    if bRemove then
        DataModel.Table_Clear()
    end

    DataModel.nSelVersion = TOTAL_VERSION_INDEX
    DataModel.InitCurrentDesignationType(dwLinkID, bPrefixLink)
    self:UpdateDesignationTypeNum()
    self:Update(UPDATE_TYPE.RELOAD)

    if bRemove then
        if #self.tViewList > 0 then
            self.tScrollList:ScrollToIndex(1)
        end
    else
        for i, tData in ipairs(self.tViewList) do
            local bPrefix = tData.nType ~= DESIGNATION_TYPE.POSTFIX
            if tData.dwID == dwLinkID and bPrefix == bPrefixLink then
                self:UpdateDesignationDetail(tData)
                local nIndex = self:TableIndexToScrollListIndex(i)
                Timer.AddFrame(self, 1, function()
                    self.tScrollList:ScrollToIndexImmediately(nIndex)
                end)
                break
            end
        end
    end
end

--更新称号列表
function UIPersonalTitleView:UpdateDesignationList(nUpdateType)
    nUpdateType = nUpdateType or UPDATE_TYPE.RELOAD

    local szSearchText = UIHelper.GetString(self.WidgetEdit)
    if szSearchText == "" then
        DataModel.szSearchText = nil
    else
        DataModel.szSearchText = szSearchText
    end
    DataModel.UpdataMyDesignationList()
    DataModel.UpdateSelectDesignation()

    local tDesignationList = DataModel.tDesignationList
    local nHaveNum = 0
    local nAllNum  = 0

    local tViewLineList = {}
    self.tViewList = {}
    for _, tLine in pairs(tDesignationList) do
        local nType = tLine.nType
        local cell
        if tLine.bHave then
            table.insert(tViewLineList, tLine)
            nHaveNum = nHaveNum + 1
            nAllNum = nAllNum + 1
        elseif not tLine.bOutOfPrint then
            table.insert(tViewLineList, tLine)
            if nType ~= DESIGNATION_TYPE.CAMP and nType ~= DESIGNATION_TYPE.COURTESY then
                nAllNum = nAllNum + 1
            end
        end
    end

    for nIndex, tLine in ipairs(tViewLineList) do
        local tData = self:SetDesignationData(tLine)
        self.tViewList[nIndex] = tData
    end

    local nDataLen = self:TableIndexToScrollListIndex(#self.tViewList)
    if nUpdateType == UPDATE_TYPE.RESET then
        self.tScrollList:Reset(nDataLen) --完全重置，包括速度、位置
    elseif nUpdateType == UPDATE_TYPE.RELOAD then
        self.tScrollList:Reload(nDataLen) --刷新数量
    elseif nUpdateType == UPDATE_TYPE.UPDATE_CELL then
        self.tScrollList:UpdateAllCell() --仅更新当前所有的Cell
    end

    local bEmpty = #self.tViewList <= 0
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)

    UIHelper.SetVisible(self.WidgetAnchorRight, not bEmpty)
end

--从配置获取称号数据
function UIPersonalTitleView:SetDesignationData(tLine)
    if not tLine then return end

    local player = GetClientPlayer()
    if not player then return end

    local tData = {}

    local dwID = tLine.dwID
    local nType = tLine.nType
    tData.nType = nType

    tData.bDisable = not not tLine.bDisable --not not: nil -> false
    tData.bIsEffect = not not tLine.bIsEffect
    tData.szName = UIHelper.GBKToUTF8(tLine.szName)
    tData.nQuality = tLine.nQuality
    tData.bTimeLimit = false

    if nType == DESIGNATION_TYPE.COURTESY then
        tData.bHave = tLine.bHave
        tData.dwID = dwID
    elseif dwID ~= 0 then
        local tInfo
        if nType == DESIGNATION_TYPE.POSTFIX then
            tInfo = GetDesignationPostfixInfo(dwID)
        else
            tInfo = GetDesignationPrefixInfo(dwID)
        end
        tData.dwID  = dwID
        tData.bHave = tLine.bHave
        if tInfo.nOwnDuration ~= 0 then
            tData.bTimeLimit = true
        end
        if tLine.bChatShow then
            --聊天显示图标？这里端游是注释掉的
        end
    end

    --是否应用称号
    local nCurrentID
    if nType == DESIGNATION_TYPE.POSTFIX then
        nCurrentID = player.GetCurrentDesignationPostfix()
    else
        nCurrentID = player.GetCurrentDesignationPrefix()
    end
    if nType == DESIGNATION_TYPE.COURTESY then
        tData.bEquip = player.GetDesignationBynameDisplayFlag() and tData.bHave
    else
        tData.bEquip = nCurrentID == dwID
    end

    --是否选择
    local nEditPrefixID   = DataModel.nEditPrefixID
    local nEditPostfixID  = DataModel.nEditPostfixID
    local nEditCourtesyID = DataModel.nEditCourtesyID
    if nType == DESIGNATION_TYPE.POSTFIX then
        tData.bSel = nEditPostfixID == dwID
    elseif nType == DESIGNATION_TYPE.COURTESY then
        tData.bSel = nEditCourtesyID == dwID
    else
        tData.bSel = nEditPrefixID == dwID
    end

    return tData
end

--选中状态切换
function UIPersonalTitleView:UpdateSelectState(tData, dwID)
    local nType = tData.nType
    if tData.bSel then
        tData.bSel = false
    else
        tData.bSel = true
        if dwID ~= 0 then
            for i, tData in ipairs(self.tViewList) do
                if tData.nType == nType and tData.dwID == dwID then
                    tData.bSel = not tData.bSel
                end
            end
        end
    end
end

function UIPersonalTitleView:UpdateFilterBtnState()
    local bFilter = DataModel.nFilterOther or DataModel.nFilterHave or DataModel.nFilterType
    local szImgPath = bFilter and "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen_ing" or "UIAtlas2_Public_PublicButton_PublicButton1_icon_screen"
    UIHelper.SetSpriteFrame(self.ImgScreen, szImgPath)
end

--选中/取消选中当前点击的称号
function UIPersonalTitleView:ChangeEditDesignation(tData)
    if not tData then return end

    local dwID = tData.dwID
    local nSelDesignationType = tData.nType
    if nSelDesignationType == DESIGNATION_TYPE.POSTFIX then
        DataModel.nSelDesignationTitle = DESIGNATION_TITLE.COMPOSE
        self:UpdateSelectState(tData, DataModel.nEditPostfixID)
        if not tData.bSel then
            DataModel.nEditPostfixID = 0
        else
            DataModel.nEditPostfixID = dwID
        end
    elseif nSelDesignationType == DESIGNATION_TYPE.COURTESY then
        DataModel.nSelDesignationTitle = DESIGNATION_TITLE.COMPOSE
        self:UpdateSelectState(tData, DataModel.nEditCourtesyID)
        if not tData.bSel then
            DataModel.nEditCourtesyID = 0
        else
            DataModel.nEditCourtesyID = dwID
        end
    else
        if nSelDesignationType == DESIGNATION_TYPE.WORLD or nSelDesignationType == DESIGNATION_TYPE.CAMP then
            DataModel.nSelDesignationTitle = DESIGNATION_TITLE.UNIQUE
        elseif nSelDesignationType == DESIGNATION_TYPE.PREFIX then
            DataModel.nSelDesignationTitle = DESIGNATION_TITLE.COMPOSE
        end
        self:UpdateSelectState(tData, DataModel.nEditPrefixID)
        if not tData.bSel then
            DataModel.nEditPrefixID = 0
        else
            DataModel.nEditPrefixID = dwID
        end
    end
    self:Update(UPDATE_TYPE.UPDATE_CELL)
end

--点击按钮确认改变称号
function UIPersonalTitleView:ChangeCurrentDesignation()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local bChange = false
    local nPrefixID, nPostfixID, nCourtesyID = DataModel.GetRealDesignation()

    local nCurTitle = DataModel.nSelDesignationTitle
    local nCurPrefixID, nCurPostfixID, nCurCourtesyID = DataModel.GetPlayerCurrentDesignation()

    if nCurTitle == DESIGNATION_TITLE.UNIQUE then
        if nCurPrefixID ~= nPrefixID or nPostfixID ~= 0 or nCurCourtesyID ~= 0 then
            bChange  = true
            nPostfixID = 0
            nCourtesyID = 0
        end
    elseif nCurTitle == DESIGNATION_TITLE.COMPOSE then
        if nCurPrefixID ~= nPrefixID then
            bChange = true
        end
        if nCurPostfixID ~= nPostfixID then
            bChange = true
        end
        if nCurCourtesyID ~= nCourtesyID then
            bChange = true
        end
    end
    local tInfo
    if nPrefixID ~= 0 then
        tInfo = GetDesignationPrefixInfo(nPrefixID)
        if DataModel.IsDesignationNeedCD(tInfo.dwCoolDownID) then
            DataModel.nCDCount = 0
        end
    end
    if nPostfixID ~= 0 then
        tInfo = GetDesignationPostfixInfo(nPostfixID)
        if DataModel.IsDesignationNeedCD(tInfo.dwCoolDownID) then
            DataModel.nCDCount = 0
        end
    end

    if bChange then
        pPlayer.SetCurrentDesignation(nPrefixID, nPostfixID, nCourtesyID ~= 0)
    end
end

--选中左边称号类型
function UIPersonalTitleView:SelectDesignationType(nType, bInit)
    DataModel.nSelDesignationType = nType
    self:UpdateDesignationList(UPDATE_TYPE.RESET)
    self:UpdateRedPointArrow()

    local tTypeNum = DataModel.tTypeDesignationNum
    local nHaveNum = tTypeNum[nType].nHaveNum
    local nAllNum = tTypeNum[nType].nAllNum

    UIHelper.SetString(self.LabelCategory, g_tStrings.tDesignationTitleLong[nType])
    UIHelper.SetString(self.LabelNum, "（" .. nHaveNum .. "/" .. nAllNum .. "）")
    UIHelper.LayoutDoLayout(self.LayoutNum)

    local nSelIndex
    for i, tData in ipairs(self.tViewList) do
        if tData.bSel and tData.bEquip then --若同时选中并装备，优先级最高
            nSelIndex = i
            break
        end
        if tData.bSel and not nSelIndex then
            nSelIndex = i
        end
    end

    local tData = nSelIndex and self.tViewList[nSelIndex]
    self:UpdateDesignationDetail(tData, false, bInit)
end

function UIPersonalTitleView:UpdateCDInfo()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    local bPrefix, bPostfix

    local szPrefixCD = ""
    local nPrefix = pPlayer.GetCurrentDesignationPrefix()
    if nPrefix ~= 0 then
        local tInfo = GetDesignationPrefixInfo(nPrefix)
        if tInfo then
            local nTime = pPlayer.GetCDLeft(tInfo.dwCoolDownID)
            if nTime and nTime > 0 then
                szPrefixCD = TimeLib.GetTimeText(nTime, true, false, true, false)
                bPrefix = true
            end
        end
    end

    local szPostfixCD = ""
    local nPostfix = pPlayer.GetCurrentDesignationPostfix()
    if nPostfix ~= 0 then
        local tInfo = GetDesignationPostfixInfo(nPostfix)
        if tInfo then
            local nTime = pPlayer.GetCDLeft(tInfo.dwCoolDownID)
            if nTime and nTime > 0 then
                szPostfixCD = TimeLib.GetTimeText(nTime, true, false, true, false)
                bPostfix = true
            end
        end
    end

    local bShowTime
    if bPrefix then
        UIHelper.SetString(self.LabelTime2, szPrefixCD)
        bShowTime = true
    elseif bPostfix then
        UIHelper.SetString(self.LabelTime2, szPostfixCD)
        bShowTime = true
    else
        DataModel.nCDCount = nil
        UIHelper.SetSelected(self.TogTips, false)
        bShowTime = false
    end

    UIHelper.SetVisible(self.WidgetCountDown, bShowTime)

    local bPrefixChange, bPostfixChange, bCourtesyChange = DataModel.IsEditDesignationChange()
    local bChange
    if DataModel.nSelDesignationTitle == DESIGNATION_TITLE.UNIQUE then
        bChange = bPrefixChange
    elseif DataModel.nSelDesignationTitle == DESIGNATION_TITLE.COMPOSE then
        bChange = bPrefixChange or bPostfixChange or bCourtesyChange
    end
    local bEnabled = not (bPrefix or bPostfix) and bChange

    UIHelper.SetButtonState(self.BtnPurchase01, bEnabled and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UIPersonalTitleView:CloseTips()
    UIHelper.SetSelected(self.TogTips, false)
end

function UIPersonalTitleView:UpdateRedPointArrow()
    local bHasRedPointBelow = false

    local nMaxLineIndex = 0
    for nLineIndex, _ in pairs(self.tScrollList.m.tCells) do
        if nLineIndex > nMaxLineIndex then
            nMaxLineIndex = nLineIndex
        end
    end

    local nMaxTableIndex = nMaxLineIndex * 3
    for i = nMaxTableIndex + 1, #self.tViewList do
        local tData = self.tViewList[i]
        if RedpointHelper.PersonalTitle_IsNew(tData) then
            bHasRedPointBelow = true
            break
        end
    end

    UIHelper.SetVisible(self.WidgetRedPointArrow, bHasRedPointBelow)
end

function UIPersonalTitleView:GoToCorationView(bAfterOpen)
    CharacterAvartarData.bOpenThisAfterCloseAccessory = bAfterOpen
    UIMgr.CloseWithCallBack(VIEW_ID.PanelPersonalTitle, function ()
        if not UIMgr.GetView(VIEW_ID.PanelCharacter) then
            UIMgr.Open(VIEW_ID.PanelCharacter)
        end
        CharacterAvartarData.SetInitTitle(CharacterAvartarData.TITLE.DESIGNATIONDECORATION)
        UIMgr.Open(VIEW_ID.PanelAccessory, true,  4)
        CharacterAvartarData.SetInitTitle(CharacterAvartarData.TITLE.NORMAL)
    end)
end

return UIPersonalTitleView