-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelLeagueInvitationPop
-- Date: 2023-02-28
-- Desc: 
-- ---------------------------------------------------------------------------------

local UIPanelLeagueInvitationPop = class("UIPanelLeagueInvitationPop")


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
    "ToggleGroupFaction",
    "LabelCdWarning",
}



function UIPanelLeagueInvitationPop:OnEnter()
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

function UIPanelLeagueInvitationPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self.m = nil
end

function UIPanelLeagueInvitationPop:BindUIEvent()
    local tNodes = self.m.tNodes
    UIHelper.BindUIEvent(tNodes.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
    UIHelper.BindUIEvent(tNodes.BtnCancel, EventType.OnClick, function()
        local tData = self.m.tDataArr[self.m.nSelectIndex]
        assert(tData)
        RemoteCallToServer("On_Tong_RefuseAllyRequest", tData.dwSrcTongID)
        self:Close()
    end)
    UIHelper.BindUIEvent(tNodes.BtnAccept, EventType.OnClick, function()
        local tData = self.m.tDataArr[self.m.nSelectIndex]
        assert(tData)
        RemoteCallToServer("On_Tong_AgreeAllyRequest", tData.dwSrcTongID)        
        self:Close()
    end)
    tNodes.ToggleGroupFaction:addEventListener(function (toggle, nIndexBaseZero)
        self.m.nSelectIndex	= nIndexBaseZero + 1
    end)	
end


function UIPanelLeagueInvitationPop:Close()
    UIMgr.Close(self)
end

function UIPanelLeagueInvitationPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelLeagueInvitationPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelLeagueInvitationPop:UpdateUI(bInit)
    local tNodes = self.m.tNodes
    if bInit then
        
    end

    self:UpdateList() 
    self:UpdateBtn()   
end

function UIPanelLeagueInvitationPop:UpdateBtn()
    local tNodes = self.m.tNodes
    local bEnable = self.m.tDataArr ~= nil and #self.m.tDataArr > 0

    UIHelper.SetVisible(tNodes.BtnAccept, bEnable)
    UIHelper.SetVisible(tNodes.BtnCancel, bEnable)
end

function UIPanelLeagueInvitationPop:UpdateList()
    local tNodes = self.m.tNodes
	local list = tNodes.ScrollViewRecordFactionRecord01
	assert(list)
    UIHelper.ToggleGroupRemoveAllToggle(tNodes.ToggleGroupFaction)
	UIHelper.RemoveAllChildren(list)		

	local arr = TongData.GetLeagueDataArr()
    self.m.tDataArr = arr
	local bEmpty = #arr == 0
	
    UIHelper.SetVisible(tNodes.WidgetDescibe, bEmpty)
    UIHelper.SetVisible(tNodes.LabelCdWarning, not bEmpty)

	if bEmpty then return end

	for i, tData in ipairs(arr) do
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetLeagueInvitationCell, list)
		assert(cell)
        UIHelper.ToggleGroupAddToggle(tNodes.ToggleGroupFaction, cell)		
		self:UpdateCell(cell, tData)
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0, false)  
    
    UIHelper.SetToggleGroupSelected(tNodes.ToggleGroupFaction, (self.m.nSelectIndex or 1) - 1)
end

local _tCellFieldNameArr = {
	"ImgSelect",
	"LabelFactionName",
	"LabelFactionLevel",
	"LabelCamp",
	"LabelMenberNum",
}
function UIPanelLeagueInvitationPop:UpdateCell(cell, tData)
	assert(cell)
	assert(tData)
    local tNodes = {}
    UIHelper.FindNodeByNameArr(cell, tNodes, _tCellFieldNameArr)
    
    local tInfo = GetTongSimpleInfo(tData.dwSrcTongID)
    assert(tInfo)
    UIHelper.SetString(tNodes.LabelFactionName, g2u(tInfo.szTongName))
    UIHelper.SetString(tNodes.LabelCamp, g_tStrings.STR_CAMP_TITLE[tInfo.nCamp])
    local nLeftTime = math.max(tData.nEndTime - GetCurrentTime(), 0)
    UIHelper.SetString(tNodes.LabelMenberNum, tInfo.nMemberCount)
    UIHelper.SetString(tNodes.LabelFactionLevel, 0)
    
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
end


return UIPanelLeagueInvitationPop