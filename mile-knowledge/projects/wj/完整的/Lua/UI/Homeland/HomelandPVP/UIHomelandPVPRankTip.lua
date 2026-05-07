-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandPVPRankTip
-- Date: 2023-04-07 15:58:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandPVPRankTip = class("UIHomelandPVPRankTip")

function UIHomelandPVPRankTip:OnEnter(tbInfo)
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandPVPRankTip:OnExit()
    self.bInit = false
end

function UIHomelandPVPRankTip:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnView, EventType.OnClick, function ()
        local hHomelandMgr = GetHomelandMgr()
		if not hHomelandMgr then
			return
		end
		local nMapID, nCopyIndex, nLandIndex = hHomelandMgr.ConvertLandID(self.tbInfo.uLandID)
		local bPrivateHome = hHomelandMgr.IsPrivateHomeMap(nMapID)
		if bPrivateHome then
			OutputMessage("MSG_SYS", g_tStrings.STR_HOMELAND_PVP_CLICK_PRIVATE)
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_PVP_CLICK_PRIVATE)
		else
            Event.Dispatch(EventType.OnSelectHomelandMainPage, 1)
            Event.Dispatch(EventType.OnSelectHomelandMyHomeMap, nMapID)
            UIMgr.Close(VIEW_ID.PanelHomeMatchRightPop)
		end

        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetRightPopRankingTips)
    end)

    UIHelper.SetTouchDownHideTips(self.BtnView, false)
end

function UIHomelandPVPRankTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

local Index2Name = {
    "观赏",
    "实用",
    "坚固",
    "风水",
    "趣味",
}
function UIHomelandPVPRankTip:UpdateInfo()
    local nCurCenterID = GetCenterID()

    UIHelper.SetVisible(self.WidgetHomeName, self.tbInfo.nCenterID == nCurCenterID)
    UIHelper.SetVisible(self.BtnView, self.tbInfo.nCenterID == nCurCenterID)
    if self.tbInfo.nCenterID == nCurCenterID then
        local nMapID, nCopyIndex, nLandIndex = GetHomelandMgr().ConvertLandID(self.tbInfo.uLandID)
		local tLandInfo = Table_GetMapLandInfo(nMapID, nLandIndex)
        UIHelper.SetString(self.LabelHomeName, HomelandData.Homeland_GetHomeName(nMapID, nLandIndex))
        UIHelper.SetString(self.LabelHomeQuality, string.format("品质：%s", UIHelper.GBKToUTF8(tLandInfo.szQuality)))
        UIHelper.SetString(self.LabelArea, string.format("面积：%d平米", tLandInfo.nArea))
        UIHelper.SetVisible(self.BtnView, not GetHomelandMgr().IsPrivateHomeMap(nMapID))
    end

    for i = 1, 5 do
		UIHelper.SetString(self.tbLabelAttribute[i], string.format("%s：%s", Index2Name[i], tostring((self.tbInfo["dwAttribute" .. i] or 0))))
	end

    UIHelper.LayoutDoLayout(self.ImgBg)
    UIHelper.LayoutDoLayout(self.WidgetRightPopRankingTips)
end


return UIHomelandPVPRankTip