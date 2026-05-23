-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelBefightListPop
-- Date: 2023-02-28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelBefightListPop = class("UIPanelBefightListPop")


local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK
local get = TableGet
local set = TableSet

local _tNodeNameArr = {
	"BtnClose",
	"ScrollViewRecordFactionRecord01",
    "WidgetDescibe",

}



function UIPanelBefightListPop:OnEnter()
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

function UIPanelBefightListPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self.m = nil
end

function UIPanelBefightListPop:BindUIEvent()
    local tNodes = self.m.tNodes
    UIHelper.BindUIEvent(tNodes.BtnClose, EventType.OnClick, function()
        self:Close()
    end)
    -- UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
    --     self:Close()
    -- end)
    -- UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
    --     self:Close()
    -- end)
    -- UIHelper.BindUIEvent(self.TogTips, EventType.OnClick, function()
	-- 	UIHelper.SetTouchLikeTips(self.WidgetTips01, self._rootNode, function ()
	-- 		UIHelper.SetSelected(self.TogTips, false)
	-- 	end)        
    -- end)

    -- UIHelper.RegisterEditBoxEnded(self.EditBox, function()
    --     self:OnEditEnded()
    -- end)



end


function UIPanelBefightListPop:Close()
    UIMgr.Close(self)
end

function UIPanelBefightListPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelBefightListPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelBefightListPop:UpdateUI(bInit)
    local tNodes = self.m.tNodes
    if bInit then
        
    end

    self:UpdateList()    
end

function UIPanelBefightListPop:UpdateList()
    local tNodes = self.m.tNodes
	local list = tNodes.ScrollViewRecordFactionRecord01
	assert(list)
	UIHelper.RemoveAllChildren(list)		

	local arr = TongData.GetDiplomacyRelationList("宣战")
	local bEmpty = not arr or #arr == 0
	UIHelper.SetVisible(tNodes.WidgetDescibe, bEmpty)
	if bEmpty then return end

	for i, tData in ipairs(arr) do
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetBeFightListCell, list)
		assert(cell)		
		self:UpdateCell(cell, tData)
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0, false)    
end

local _tCellFieldNameArr = {
	"LabelFactionName",
	"LabelFactionLevel",
	"LabelCamp",
	"LabelMenberNum",
}
function UIPanelBefightListPop:UpdateCell(cell, tData)
	assert(cell)
	assert(tData)
    local tNodes = {}
    UIHelper.FindNodeByNameArr(cell, tNodes, _tCellFieldNameArr)

    local dwTongID = g_pClientPlayer.dwTongID == tData.dwSrcTongID and tData.dwDstTongID or tData.dwSrcTongID
    local tInfo = GetTongSimpleInfo(dwTongID)
    assert(tInfo)
    UIHelper.SetString(tNodes.LabelFactionName, g2u(tInfo.szTongName))
    UIHelper.SetString(tNodes.LabelCamp, g_tStrings.STR_CAMP_TITLE[tInfo.nCamp])
    local nLeftTime = math.max(tData.nEndTime - GetCurrentTime(), 0)
    UIHelper.SetString(tNodes.LabelMenberNum, UIHelper.GetHeightestTimeText(nLeftTime))
    UIHelper.SetString(tNodes.LabelFactionLevel, nLeftTime > 0 and "宣战中" or "已结束")

end


return UIPanelBefightListPop