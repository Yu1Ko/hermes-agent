-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelCompetitionInvitationPop
-- Date: 2023-03-24
-- Desc: 
-- ---------------------------------------------------------------------------------

local UIPanelCompetitionInvitationPop = class("UIPanelCompetitionInvitationPop")


local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK
local get = TableGet
local set = TableSet

local _tNodeNameArr = {
	"BtnClose",
	"BtnCancel",
	"BtnAccept",
	"ScrollViewRecordFactionRecord01",
    "WidgetDescibe",
    "LabelNumTick",
    "ToggleGroupFaction",
    "LabelCdWarning",
}



function UIPanelCompetitionInvitationPop:OnEnter()
    self.m = {}
    
    local tNodes = {}
    UIHelper.FindNodeByNameArr(self._rootNode, tNodes, _tNodeNameArr)
    self.m.tNodes = tNodes

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateUI(true)
end

function UIPanelCompetitionInvitationPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self.m = nil
end

function UIPanelCompetitionInvitationPop:BindUIEvent()
    local tNodes = self.m.tNodes
    UIHelper.BindUIEvent(tNodes.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
    UIHelper.BindUIEvent(tNodes.BtnCancel, EventType.OnClick, function()
        local tData = self.m.tDataArr[self.m.nSelectIndex]
        assert(tData)
        RemoteCallToServer("On_Tong_CancalCWRequest", tData.dwSrcTongID, tData.dwDstTongID)        
        self:Close()
    end)
    UIHelper.BindUIEvent(tNodes.BtnAccept, EventType.OnClick, function()
        local tData = self.m.tDataArr[self.m.nSelectIndex]
        assert(tData)
        RemoteCallToServer("On_Tong_AgreeCWRequest", tData.dwSrcTongID, tData.dwDstTongID)        
        self:Close()
    end)
    -- tNodes.ToggleGroupFaction:addEventListener(function (toggle, nIndexBaseZero)
    --     self.m.nSelectIndex	= nIndexBaseZero + 1
    -- end)	
end

function UIPanelCompetitionInvitationPop:SelectAllCell(bSelect)
    local arr = self.m.tCellArr
    assert(arr)
    for _, cell in ipairs(arr) do
        UIHelper.SetSelected(cell, bSelect == true)
    end   
end

function UIPanelCompetitionInvitationPop:Close()
    UIMgr.Close(self)
end

function UIPanelCompetitionInvitationPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelCompetitionInvitationPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelCompetitionInvitationPop:UpdateUI(bInit)
    local tNodes = self.m.tNodes
    if bInit then
       
    end

    self:UpdateList() 
    self:UpdateBtn()   
end

function UIPanelCompetitionInvitationPop:UpdateBtn()
    local tNodes = self.m.tNodes
    local bEnable = self.m.tDataArr ~= nil and #self.m.tDataArr > 0 and self.m.nSelectIndex ~= nil

    UIHelper.SetVisible(tNodes.BtnAccept, bEnable)
    UIHelper.SetVisible(tNodes.BtnCancel, bEnable)
    
end

function UIPanelCompetitionInvitationPop:UpdateList()
    local tNodes = self.m.tNodes
	local list = tNodes.ScrollViewRecordFactionRecord01
	assert(list)
	UIHelper.RemoveAllChildren(list)		

	local arr = TongData.GetContractWarInvitedDataArr()
    self.m.tDataArr = arr
	local bEmpty = #arr == 0
	
    UIHelper.SetVisible(tNodes.WidgetDescibe, bEmpty)
	UIHelper.SetVisible(tNodes.TogChooseIncitation, not bEmpty)
    UIHelper.SetVisible(tNodes.LabelCdWarning, not bEmpty)
    
    self.m.tCellArr = {}        
	if bEmpty then return end

	for i, tData in ipairs(arr) do
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetCompetitionFactionCell, list)
		assert(cell)
        table.insert(self.m.tCellArr, cell)        
		self:UpdateCell(i)
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0, false) 
    
    self:OnCellSelect(1)
end

local lc_GetThisWeekStarTime = function ()
    local nTime = GetCurrentTime()
    local tTime = TimeToDate(nTime)

    if tTime.weekday == 0 then
        nTime = BigIntSub(nTime, 6 * 3600 * 24)
    else
        nTime = BigIntSub(nTime, (tTime.weekday - 1) * 3600 * 24)
    end

    nTime = BigIntSub(nTime, tTime.hour * 3600)
    nTime = BigIntSub(nTime, tTime.minute * 60)
    nTime = BigIntSub(nTime, tTime.second)
    return nTime
end

local _tCellFieldNameArr = {
	"ImgSelect",
	"LabelFactionName",
	"LabelContractTime",
	"LabelStartTime",
	"LabelMode",
    "LayoutCompetitionCost",
	"LabelCompetitionCost",
	"BtnSelect",
}
function UIPanelCompetitionInvitationPop:UpdateCell(nIndex)
    local cell = self.m.tCellArr[nIndex]    
	assert(cell)
    local tData = self.m.tDataArr[nIndex]
	assert(tData)
    local tNodes = {}
    UIHelper.FindNodeByNameArr(cell, tNodes, _tCellFieldNameArr)

    local tWarTiemSegment = GetTongContractWarTimeSegment()
    local nFightTime = lc_GetThisWeekStarTime() + tWarTiemSegment[tData.wTimeSegment]

    local tMoneyArr = GetTongContractWarCastMoney()
    local nMoney = tMoneyArr[tData.wSubType]
    assert(nMoney, "nMoney is nil, index: " .. tData.wSubType)
    
    local tInfo = GetTongSimpleInfo(tData.dwSrcTongID)
    assert(tInfo)
    UIHelper.SetString(tNodes.LabelFactionName, g2u(tInfo.szTongName))
    UIHelper.SetString(tNodes.LabelContractTime, TongData.GetDateString(nFightTime))
    UIHelper.SetString(tNodes.LabelStartTime, TongData.GetTimeString(nFightTime))
    UIHelper.SetString(tNodes.LabelMode, tData.wSubType == 1 and "切磋" or "对决") -- wSubType的值由1到4
    UIHelper.SetString(tNodes.LabelCompetitionCost, nMoney)
    UIHelper.LayoutDoLayout(tNodes.LayoutCompetitionCost)
    UIHelper.SetVisible(tNodes.ImgSelect, nIndex == self.m.nSelectIndex)

    local tCDTime = TimeToDate(tData.nCDEndTime)
    local szCDTime = FormatString(
            g_tStrings.STR_TONG_CD_WARMING,
            tCDTime.year,
            tCDTime.month,
            tCDTime.day,
            tCDTime.hour,
            tCDTime.minute
    )
    UIHelper.SetString(self.m.tNodes.LabelCdWarning, szCDTime)
    
    UIHelper.BindUIEvent(tNodes.BtnSelect, EventType.OnClick, function()
        self:OnCellSelect(nIndex)        
    end)  

end

function UIPanelCompetitionInvitationPop:OnCellSelect(nIndex)
    local nLastIndex = self.m.nSelectIndex
    self.m.nSelectIndex = nIndex
    if nLastIndex and nLastIndex ~= nIndex then
        self:UpdateCell(nLastIndex)
    end

    self:UpdateCell(nIndex)    
end


return UIPanelCompetitionInvitationPop