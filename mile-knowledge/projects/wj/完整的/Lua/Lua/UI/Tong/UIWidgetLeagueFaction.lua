-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetLeagueFaction
-- Date: 2023-03-22
-- Desc: 帮会外交同盟
-- Prefab: PREFAB_ID.WidgetLeagueFaction
-- Mark: GuildMainPanel.UpdateAllianceMemberList 成员列表数据来源
-- ---------------------------------------------------------------------------------

local UIWidgetLeagueFaction = class("UIWidgetLeagueFaction")

local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK
local get = TableGet
local set = TableSet

local _NodeNameArr = {
	"WidgetAnchorLeague",
	"WidgetAnchorMember",
	"BtnLeagueInvitation",
	"EditBox",
	"BtnLeague",

}



function UIWidgetLeagueFaction:Init()
	self.m = {}

    if table_is_empty(Storage.Tong.League) then
        Storage.Tong.League = {
            bShowOffline = true,
            szSort = "level",
            bDescend = false,
            nSchoolFilter = -1,
        }
    end

	local tNodes = {}
	UIHelper.FindNodeByNameArr(self._rootNode, tNodes, _NodeNameArr)
	self.m.tNodes = tNodes

	self:RegEvent()
	self:BindUIEvent()

	if TongData.IsLeagued() then		
		TongData.RequestTongMemberData(TongData.GetAllianceTongID())
	end
	
	self:UpdateUI(true)
end

function UIWidgetLeagueFaction:UnInit()
	self:UnRegEvent()

	UIHelper.RemoveFromParent(self._rootNode)
	self.m = nil
end

function UIWidgetLeagueFaction:OnShow()
    -- 是否已结盟	
    if TongData.IsLeagued() then
        UIHelper.StopAni(self, self._rootNode, "AniLeagueFaction")
    end
end

function UIWidgetLeagueFaction:BindUIEvent()
	local tNodes = self.m.tNodes
	UIHelper.BindUIEvent(tNodes.BtnLeagueInvitation, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelLeagueInvitationPop)		
	end)	
	UIHelper.BindUIEvent(tNodes.BtnLeague, EventType.OnClick, function()
		local szTargetName = UIHelper.GetText(tNodes.EditBox)
		-- 请求结成同盟
		RemoteCallToServer("On_Tong_LaunchAllyRequest", u2g(szTargetName))
	end)	
	UIHelper.RegisterEditBoxEnded(tNodes.EditBox, function()
		self.m.szTargetName = UIHelper.GetText(tNodes.EditBox)
		self:UpdateUI()
	end)	
end

function UIWidgetLeagueFaction:RegEvent()	
	Event.Reg(self, "UPDATE_OTHER_TONG_ROSTER_FINISH", function ()		
		self:UpdateUI()
	end)
	Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function ()		
		if TongData.IsLeagued() then		
			TongData.RequestTongMemberData(TongData.GetAllianceTongID())
		else
			self:UpdateUI()
		end	
	end)
	Event.Reg(self, "UPDATE_TONG_DIPLOMACY_INFO", function ()		
		TongData.RequestBaseData()
	end)	
end

function UIWidgetLeagueFaction:UnRegEvent()
	Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetLeagueFaction:UpdateUI(bInit)
	local tNodes = self.m.tNodes
	if bInit then
	end
	UIHelper.SetVisible(tNodes.WidgetAnchorLeague, false)	
	UIHelper.SetVisible(tNodes.WidgetAnchorMember, false)
	
	-- 是否已结盟	
	if TongData.IsLeagued() then
		self:UpdateUIForLeagued(bInit)
	else
		self:UpdateUIForNeverLeague(bInit)
	end
end

function UIWidgetLeagueFaction:UpdateUIForNeverLeague(bInit)
	local tNodes = self.m.tNodes
	if bInit then
		UIHelper.SetText(tNodes.EditBox, "")
	end

	UIHelper.SetVisible(tNodes.WidgetAnchorLeague, true)
	
	self:UpdateBtnForNeverLeague()
end

local _tWidgetLeagueFactionMenberNameArr = {
	"LabelLeagueFactionName",
	"ImgLeagueFactionCamp",
	"BtnFilter",
	"ScrollViewMemberInformation",
	"TogDisplayOfflineMember",
	"LabelMemderNum",
	"LabelLeagueTime",
	"BtnCancelLeague",
	"WidgetSchoolFilter",
	"ToggleGroupTabFilter",
	"ScrollViewFilter",
}

function UIWidgetLeagueFaction:UpdateUIForLeagued(bInit)
	local tNodes = self.m.tNodes	
	if bInit then
	end

	if not tNodes.WidgetAnchorMember:getChildByName("WidgetLeagueFactionMenber") then
		local node = UIHelper.AddPrefab(PREFAB_ID.WidgetLeagueFactionMenber, tNodes.WidgetAnchorMember)
		assert(node)
		tNodes.WidgetLeagueFactionMenber = node

		UIHelper.FindNodeByNameArr(node, tNodes, _tWidgetLeagueFactionMenberNameArr)

		UIHelper.BindUIEvent(tNodes.TogDisplayOfflineMember, EventType.OnClick, function()
			set(UIHelper.GetSelected(tNodes.TogDisplayOfflineMember), Storage.Tong.League, "bShowOffline")		
			self:UpdateMemberList()
		end)
		UIHelper.BindUIEvent(tNodes.BtnFilter, EventType.OnClick, function()
			self:ShowSchoolFilterMenu()			
		end)
		UIHelper.BindUIEvent(tNodes.BtnCancelLeague, EventType.OnClick, function()
			UIHelper.ShowConfirm(g_tStrings.STR_REMOVE_TONG_UNION_WARMING, function ()
				RemoteCallToServer("On_Tong_StopAllianceRequest")
			end)			
		end)

	end

	UIHelper.SetVisible(tNodes.WidgetAnchorMember, true)
	
	local tInfo = GetTongSimpleInfo(TongData.GetAllianceTongID())	
	assert(tInfo)
	UIHelper.SetString(tNodes.LabelLeagueFactionName, g2u(tInfo.szTongName))
	local szCampImage = CampData.GetCampImgPath(tInfo.nCamp, false, true)
	UIHelper.SetSpriteFrame(tNodes.ImgLeagueFactionCamp, szCampImage)

	local bShowOffline = get(Storage.Tong.League, "bShowOffline")
	UIHelper.SetSelected(tNodes.TogDisplayOfflineMember, bShowOffline)	

	local nTotal, nOnline = TongData.GetMemberCount(TongData.GetAllianceTongID())
	if nTotal then
		UIHelper.SetRichText(tNodes.LabelMemderNum, string.format("%d/%d", nOnline, nTotal))
	end
	
	UIHelper.SetString(tNodes.LabelLeagueTime, TongData.GetLeagueTimeString())

	self:UpdateMemberList()
end

function UIWidgetLeagueFaction:ShowSchoolFilterMenu()
	local tNodes = self.m.tNodes

	local fnClose = function()
		UIHelper.SetVisible(tNodes.WidgetSchoolFilter, false)
	end

	UIHelper.SetVisible(tNodes.WidgetSchoolFilter, true)
	UIHelper.SetTouchLikeTips(tNodes.WidgetSchoolFilter, UIMgr.GetLayer(UILayer.Page), fnClose)

	local list = tNodes.ScrollViewFilter
	assert(list)    
	UIHelper.RemoveAllChildren(list)		

	local arr = TongData.GetFilterSchoolArr()
	local nCurType = Storage.Tong.League.nSchoolFilter or -1
	local nCurIndex = 1
	for i, nType in ipairs(arr) do
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetTogSchoolFilterCell, list)
		assert(cell)
		UIHelper.SetSelected(cell, nType == nCurType)
		local szTitle = nType == -1 and g_tStrings.STR_GUILD_ALL or Table_GetForceName(nType)
		UIHelper.SetString(UIHelper.FindChildByName(cell, "LabelStyleFilterMain"), szTitle)
		UIHelper.SetString(UIHelper.FindChildByName(cell, "LabelStyleFilterMainUp"), szTitle)

		local key = nType
		UIHelper.BindUIEvent(cell, EventType.OnClick, function()
			Storage.Tong.League.nSchoolFilter = key
			self:UpdateMemberList()
			fnClose()
		end)
		if nType == nCurType then
			nCurIndex = i
		end		
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToIndex(list, nCurIndex - 1, 0.5, false)	
end	

function UIWidgetLeagueFaction:UpdateMemberList()
    local tNodes = self.m.tNodes
	local list = tNodes.ScrollViewMemberInformation
	assert(list)    
	UIHelper.RemoveAllChildren(list)		

	local dwAllianceTongID = TongData.GetAllianceTongID()
	local tSort = Storage.Tong.League
	local arr = TongData.GetMemberList(
		tSort.bShowOffline,
		tSort.szSort,
		not tSort.bDescend,
		-1,
		tSort.nSchoolFilter,
		dwAllianceTongID		
	)
    
	local bEmpty = not arr or #arr == 0
	if tNodes.WidgetDescibe then UIHelper.SetVisible(tNodes.WidgetDescibe, bEmpty) end
	if bEmpty then return end

	for i, nID in ipairs(arr) do
		local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetLeagueMemberInformation, list)
		assert(cell)
        UIHelper.ToggleGroupAddToggle(tNodes.ToggleGroupFaction, cell)
		local tData = GetTongClient().GetMemberInfo(nID, dwAllianceTongID)
		assert(tData) 
		self:UpdateMemberCell(cell, tData)
	end
	UIHelper.ScrollViewDoLayout(list)
	UIHelper.ScrollToTop(list, 0, false)  	
end

local _tMemberCellNodeNameArr = {
	"ImgSchoolIcon",
	"LabelGrade",
	"LabelMemberName",
	"LabelEquipment",
	"LabelIntegral",
	"LabelLocation",
	"LabelRemark",
    "ImgPlayer",
    "AnimatePlayerIcon",
    "SFXPlayerIcon",
}
function UIWidgetLeagueFaction:UpdateMemberCell(cell, tData)
	assert(cell)
	assert(tData)	
	local tNodes = {}
	UIHelper.FindNodeByNameArr(cell, tNodes, _tMemberCellNodeNameArr)

	UIHelper.SetVisible(tNodes.WidgetText, false)	

	UIHelper.SetString(tNodes.LabelMemberName, g2u(tData.szName))

	UIHelper.SetString(tNodes.LabelGrade, tostring(tData.nLevel))
	
	--UIHelper.SetSpriteFrame(tNodes.ImgSchoolIcon, PlayerForceID2SchoolImg[tData.nForceID or FORCE_TYPE.CHUN_YANG])

	UIHelper.SetString(tNodes.LabelEquipment, tostring(tData.nEquipScore))		
	UIHelper.SetString(tNodes.LabelIntegral, tostring(tData.nTitlePoint))

	-- 所在地
	local sz = tData.bIsOnline and g2u(Table_GetMapName(tData.dwMapID)) or g_tStrings.STR_GUILD_OFFLINE
	UIHelper.SetString(tNodes.LabelLocation, sz)		


	UIHelper.SetString(tNodes.LabelRemark, UIHelper.LimitUtf8Len(g2u(tData.szRemark), 7))
	

	-- 头像
	if tData.nForceID then
        local dwMiniAvatarID = 0
        local nRoleType      = nil
        local dwForceID      = tData.nForceID

        UIHelper.RoleChange_UpdateAvatar(tNodes.ImgPlayer, dwMiniAvatarID, tNodes.SFXPlayerIcon, tNodes.AnimatePlayerIcon, nRoleType, dwForceID, true)
        UIHelper.SetNodeGray(tNodes.ImgPlayer, not tData.bIsOnline)
	end	
	
	
end

function UIWidgetLeagueFaction:UpdateBtnForLeagued()
	local tNodes = self.m.tNodes
end

function UIWidgetLeagueFaction:UpdateBtnForNeverLeague()
	local tNodes = self.m.tNodes
	local szTargetName = UIHelper.GetText(tNodes.EditBox)
	local bEnable = szTargetName ~= ""
	UIHelper.SetEnable(tNodes.BtnLeague, bEnable)
	UIHelper.SetNodeGray(tNodes.BtnLeague, not bEnable, true)

end



return UIWidgetLeagueFaction

