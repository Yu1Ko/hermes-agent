-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildJoinMatchView
-- Date: 2023-06-20 19:40:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildJoinMatchView = class("UIHomelandBuildJoinMatchView")
local LAST_WEEK = 0
local THIS_WEEK = 1

-----------------------------DataModel------------------------------
local DataModel = {}
function DataModel.Init()
    local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
	DataModel.dwMapID 		= dwMapID
	DataModel.nCopyIndex 	= nCopyIndex
	DataModel.nLandIndex 	= nLandIndex
    GetHomelandMgr().ApplyMyHomelandRank(THIS_WEEK)
	GetHomelandMgr().ApplyLandRankActiveScore(nLandIndex)
end

function DataModel.Set(szName, value)
    DataModel[szName] = value
end

function DataModel.SetRankInfo(nType, nInfo)
	DataModel.nType = nType
	DataModel.nInfo = nInfo
end

function DataModel.GetRewardLevel(nIndex, nInfo)
	if nIndex ~= 0 then
		return g_tTable.HomelandRewardLevel:Search(1)
	end
	if nInfo == 0 then
		return g_tTable.HomelandRewardLevel:Search(0)
	end
	local nCount = g_tTable.HomelandRewardLevel:GetRowCount()
	for i = 2, nCount do
		local tLine = g_tTable.HomelandRewardLevel:GetRow(i)
		if nInfo > tLine.nMinPercentage and nInfo <= tLine.nMaxPercentage then
			return tLine
		end
	end
end

function DataModel.CalculationScore(t, key)
	local nScore = 0
	for i = 1, 5 do
		nScore = nScore + (t[key .. i] or 0)
	end
	return nScore
end

function DataModel.IsTimeOK()
	local nTime 		= GetCurrentTime()

	local nStartTime 	= DateToTime(2020, 7, 20, 5, 0, 0)
	local nEndTime 		= DateToTime(2020, 7, 20, 7, 0, 0)

	local nWeek 		= math.floor((nTime - nStartTime) / (7 * 24 * 3600))
	nStartTime 			= nStartTime + nWeek * (7 * 24 * 3600)
	nEndTime 			= nEndTime + nWeek * (7 * 24 * 3600)
	if nTime > nStartTime and nTime < nEndTime then
		return false
	end
	return true
end

function UIHomelandBuildJoinMatchView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.Init()
    self:UpdateBaseInfo()
end

function UIHomelandBuildJoinMatchView:OnExit()
    self.bInit = false
end

function UIHomelandBuildJoinMatchView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnDetails, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelHome, 2)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSubmit, EventType.OnClick, function ()
        GetHomelandMgr().SubmitToRank(DataModel.nLandIndex)
        UIMgr.Close(self)
    end)
end

function UIHomelandBuildJoinMatchView:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function()
        local nRetCode = arg0
        if arg0 == HOMELAND_RESULT_CODE.APPLY_HL_RANK_INFO_RESPOND then
			if arg1 == THIS_WEEK then
				DataModel.SetRankInfo(arg2, arg3)
                self:UpdateRankInfo(arg2, arg3)
                self:UpdateBaseInfo()
			end
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_LEVEL_UP then
			local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
			if DataModel.dwMapID == dwMapID and DataModel.nCopyIndex == nCopyIndex and DataModel.nLandIndex == nLandIndex then
				if DataModel.nType and DataModel.nInfo then
                    self:UpdateRankInfo(DataModel.nType , DataModel.nInfo)
				end
                self:UpdateBaseInfo()
			end
		end
    end)
end

function UIHomelandBuildJoinMatchView:UpdateRankInfo(nIndex, nInfo)
    local szDesc = self:GetIndexName(nIndex, nInfo)
    UIHelper.SetString(self.LabelRanking01, string.format("本周排名：%s", szDesc))
end

function UIHomelandBuildJoinMatchView:UpdateBaseInfo()
	local tInfo = GetHomelandMgr().GetLandRankActiveScore(DataModel.nLandIndex)
	if not tInfo then
		return
	end
	local nNowScore = DataModel.CalculationScore(tInfo, "dwRankDecorateInfo")
	local nLastScore = DataModel.CalculationScore(tInfo, "dwRankSubmitDecorateInfo")
	DataModel.Set("nLastScore", nLastScore)

    UIHelper.SetString(self.LabelNum01, tostring(nLastScore))
    UIHelper.SetString(self.LabelNum02, tostring(nNowScore))

    local bCanJoin = nNowScore ~= 0 and nNowScore > nLastScore and DataModel.IsTimeOK()
    if bCanJoin then
        UIHelper.SetButtonState(self.BtnSubmit, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnSubmit, BTN_STATE.Disable)
    end
end

function UIHomelandBuildJoinMatchView:GetIndexName(nIndex, nInfo)
	if nInfo == 0 then
		return g_tStrings.STR_HOMELAND_PVP_NOT_JOIN
	elseif nIndex ~= 0 then
		return FormatString(g_tStrings.STR_HOMELAND_PVP_RANK, nIndex)
	else
		return FormatString(g_tStrings.STR_HOMELAND_PVP_RANK_PERCENTAGE, nInfo)
	end
end


return UIHomelandBuildJoinMatchView