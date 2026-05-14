-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPersonalHomeCardView
-- Date: 2024-03-25 14:27:38
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_SHOW_NUM = 10000

local UIPersonalHomeCardView = class("UIPersonalHomeCardView")
local DataModel = {}
DataModel.Init = function ()
    DataModel.nRecord 		        = 0
    DataModel.tMyHomeData 		    = {}
    DataModel.tMyPrivateHomeData    = {}
    DataModel.bIsHaveOwnHomeland    = false
end

DataModel.UnInit = function ()
    DataModel.nRecord 		        = nil
    DataModel.tMyHomeData 		    = nil
    DataModel.tMyPrivateHomeData    = nil
    DataModel.bIsHaveOwnHomeland    = nil
end

DataModel.GetHomelandRecordInfo = function ()
    local pPlayer = PlayerData.GetClientPlayer()
    DataModel.nRecord = pPlayer.GetHomelandRecord()
end

DataModel.GetHomelandBaseInfo = function ()
    local tLandHash = GetHomelandMgr().GetAllMyLand()
    local tMyHomeData = {}
	local tMyPrivateHomeData = {}
	for _, tHash in ipairs(tLandHash) do
		local nMapID, nCopyIndex, nLandIndex = GetHomelandMgr().ConvertLandID(tHash.uLandID)
		if not tHash.bAllied and not tHash.bPrivateLand then
			tMyHomeData.nMapID = nMapID
            tMyHomeData.nCopyIndex = nCopyIndex
            tMyHomeData.nLandIndex = nLandIndex
            local bIsSelling, bPrepareToSale, bIsOpen, nLevel, nAllyCount, eMarketType = GetHomelandMgr().GetLandState(nMapID, nCopyIndex, nLandIndex)
            tMyHomeData.eMarketType = eMarketType
		end
	end
    local tPrivateHash = GetHomelandMgr().GetAllMyPrivateHome()
	for _, tHash in ipairs(tPrivateHash) do
        tMyPrivateHomeData.nMapID = tHash.dwMapID
        tMyPrivateHomeData.nCopyIndex = tHash.nCopyIndex
        GetHomelandMgr().ApplyPrivateHomeInfo(tHash.dwMapID, tHash.nCopyIndex)
	end
    DataModel.bIsHaveOwnHomeland = true
    if (not tMyHomeData.nMapID or not tMyHomeData.nCopyIndex or not tMyHomeData.nLandIndex ) then
        if (not tMyPrivateHomeData.nMapID or not tMyPrivateHomeData.nCopyIndex) then
            DataModel.bIsHaveOwnHomeland = false
        else
            GetHomelandMgr().ApplyLandInfo(tMyPrivateHomeData.nMapID, tMyPrivateHomeData.nCopyIndex, 1)
        end
    end
    DataModel.tMyHomeData = tMyHomeData
    DataModel.tMyPrivateHomeData = tMyPrivateHomeData
end

function UIPersonalHomeCardView:OnEnter()
    if not self.bInit then
        DataModel.Init()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bIsHaveOwnHomeland = false
    self:Init()
end

function UIPersonalHomeCardView:OnExit()
    self.bInit = false
    DataModel.UnInit()
    self:UnRegEvent()
end

function UIPersonalHomeCardView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelHome, 1)
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    -- UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
    --     UIMgr.Close(self)
    -- end)
end

function UIPersonalHomeCardView:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE", function ()
        local nResultType = arg0
        if nResultType == HOMELAND_RESULT_CODE.APPLY_ESTATE_SUCCEED then
            DataModel.GetHomelandBaseInfo()
            DataModel.GetHomelandRecordInfo()
			self:UpdateInfo()
        end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function ()
        local nResultType = arg0
        if nResultType == HOMELAND_RESULT_CODE.APPLY_PRIVATE_HOME_INFO_RESPOND then
            local nMapID, nCopyIndex = arg1, arg2
			if nMapID == DataModel.tMyPrivateHomeData.nMapID and nCopyIndex == DataModel.tMyPrivateHomeData.nCopyIndex then
				local tPrivateInfo = GetHomelandMgr().GetPrivateHomeInfo(nMapID, nCopyIndex)
                DataModel.tMyPrivateHomeData.dwSkinID = tPrivateInfo.dwSkinID
                self:UpdateInfo()
            end
        elseif nResultType == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then
            local nMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
            if nMapID == DataModel.tMyPrivateHomeData.nMapID and nCopyIndex == DataModel.tMyPrivateHomeData.nCopyIndex then
				local tInfo = GetHomelandMgr().GetLandInfo(nMapID, nCopyIndex, nLandIndex)
                if not tInfo then
                    return
                end
                DataModel.tMyPrivateHomeData.eMarketType = tInfo.uMarketType
                self:UpdateInfo()
            end
        end
    end)
end

function UIPersonalHomeCardView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPersonalHomeCardView:Init()
    GetHomelandMgr().ApplyEstate()

    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.SetVisible(self.LayoutContent, false)
    UIHelper.SetString(self.LabelScoreNum, 0)
end

function UIPersonalHomeCardView:UpdateInfo()
    if not DataModel.bIsHaveOwnHomeland then
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.LayoutContent, false)
        return
    end
    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.SetVisible(self.LayoutContent, true)
    self:UpdateHomelandRecordInfo()
    self:UpdateHomelandInfo()
end

function UIPersonalHomeCardView:UpdateHomelandRecordInfo()
    local nRecord = DataModel.nRecord or 0
    local szText = nRecord
    local fData = nRecord
    if fData > MAX_SHOW_NUM then
        fData = math.floor(fData / MAX_SHOW_NUM * 100) / 100
        szText = FormatString(g_tStrings.MPNEY_TENTHOUSAND, fData)
    end
    UIHelper.SetString(self.LabelScoreNum, szText)
end

function UIPersonalHomeCardView:UpdateHomelandInfo()
    UIHelper.RemoveAllChildren(self.LayoutContent)
    self:UpdatePrivateHomelandInfo()
    self:UpdateCommunutyHomelandInfo()
end

function UIPersonalHomeCardView:UpdateCommunutyHomelandInfo()
    local tMyHomeData = DataModel.tMyHomeData
    if not DataModel.bIsHaveOwnHomeland then
        return
    end
    tMyHomeData.dwPlayerID = PlayerData.GetPlayerID()

    self.scriptCommunutyHome = UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterHomeCell, self.LayoutContent)
    self.scriptCommunutyHome:OnEnter(tMyHomeData, true, false)
end

function UIPersonalHomeCardView:UpdatePrivateHomelandInfo()
    local tMyPrivateHomeData = DataModel.tMyPrivateHomeData
    if not DataModel.bIsHaveOwnHomeland then
        return
    end
    tMyPrivateHomeData.dwPlayerID = PlayerData.GetPlayerID()

    self.scriptPrivateHome = UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterHomeCell, self.LayoutContent)
    self.scriptPrivateHome:OnEnter(tMyPrivateHomeData, false, false)
end

return UIPersonalHomeCardView