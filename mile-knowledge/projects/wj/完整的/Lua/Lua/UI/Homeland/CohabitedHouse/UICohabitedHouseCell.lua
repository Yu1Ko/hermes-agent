-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICohabitedHouseCell
-- Date: 2023-07-19 16:38:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICohabitedHouseCell = class("UICohabitedHouseCell")

function UICohabitedHouseCell:OnEnter(nIndex, tbInfo, bMyHouse)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.tbInfo = tbInfo
    self.szLandID = tbInfo and tbInfo.szLandID
    self.bHasNews = tbInfo and tbInfo.bHasNews
    self.bMyHouse = bMyHouse

    self:UpdateInfo()
end

function UICohabitedHouseCell:OnExit()
    self.bInit = false
end

function UICohabitedHouseCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogHomeCell, EventType.OnClick, function ()
        if self.funcCallback then
            self.funcCallback(self.nIndex, self.tbInfo)
        end
    end)
end

function UICohabitedHouseCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICohabitedHouseCell:UpdateInfo()
    if not self.szLandID then
        UIHelper.SetVisible(self.WidgetHomeInfo, false)
        UIHelper.SetVisible(self.WidgetHomeInfo2, false)
        UIHelper.SetVisible(self.LabelNum, false)
        UIHelper.SetVisible(self.ImgRoleIcon, false)
        UIHelper.SetVisible(self.ImgGradeBg, false)
        UIHelper.SetVisible(self.LabelLeisure, true)
        UIHelper.SetVisible(self.ImgHomeIcon, false)
        return
    else
        UIHelper.SetVisible(self.WidgetHomeInfo, true)
        UIHelper.SetVisible(self.WidgetHomeInfo2, true)
        UIHelper.SetVisible(self.LabelNum, true)
        UIHelper.SetVisible(self.ImgRoleIcon, true)
        UIHelper.SetVisible(self.ImgGradeBg, true)
        UIHelper.SetVisible(self.LabelLeisure, false)
        UIHelper.SetVisible(self.ImgHomeIcon, true)
    end

	local hlMgr = GetHomelandMgr()
	local dwMapID, nCopyIndex, nLandIndex = hlMgr.ConvertLandID(self.szLandID)
	local tLandInfo = hlMgr.GetLandInfo(dwMapID, nCopyIndex, nLandIndex)
	local bIsSelling, bPrepareToSale, bIsOpen, nUILevel, nAlliedCount = hlMgr.GetLandState(dwMapID, nCopyIndex, nLandIndex)
    nUILevel = nUILevel or 1 -- 可能返回的全为 nil；下同
	nAlliedCount = nAlliedCount or 0

    local tCommunityInfo = hlMgr.GetCommunityInfo(dwMapID, nCopyIndex)
    local szAddressName = ""
    if tCommunityInfo then
        local szName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID)) .. tostring(nLandIndex) .. g_tStrings.STR_HOMELAND_NUMBER
        szAddressName = FormatString(g_tStrings.STR_LINK_LAND, szName, tCommunityInfo.nIndex)
    end

    UIHelper.SetString(self.LabelLevel, tLandInfo.nLevel)
    UIHelper.SetString(self.LabelBranching, szAddressName)
    UIHelper.SetString(self.LabelBranching2, szAddressName)
    UIHelper.SetString(self.LabelNum, nAlliedCount)
    UIHelper.SetString(self.LabelName, self:GetShortPlayerName(UIHelper.GBKToUTF8(tLandInfo.szName)))
    UIHelper.SetString(self.LabelName2, self:GetShortPlayerName(UIHelper.GBKToUTF8(tLandInfo.szName)))

    local nLevel = tLandInfo.nLevel
    nLevel = math.min(3, math.max(1, nLevel))
    nLevel = nLevel * 2 - 1
    UIHelper.SetSpriteFrame(self.ImgHomeIcon, HomelandHouseImg[nLevel])
end

function UICohabitedHouseCell:GetShortPlayerName(szFullPlayerName)
	local nBeg, nEnd = string.find(szFullPlayerName, g_tStrings.STR_PLAYER_SERVER_LOCATION_MARK)
	if nBeg then
		return string.sub(szFullPlayerName, 1, nBeg - 1)
	else
		return szFullPlayerName
	end
end

function UICohabitedHouseCell:SetClickCallback(funcCallback)
    self.funcCallback = funcCallback
end

function UICohabitedHouseCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogHomeCell, bSelected)
end

return UICohabitedHouseCell