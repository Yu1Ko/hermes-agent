-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRoomProgressView
-- Date: 2024-02-18 14:28:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.ApplyRoomDetailInfo()
    GetGlobalRoomClient().ApplyDetailInfo()
end

function DataModel.Update()
    local tRoomInfo = GetGlobalRoomClient().GetGlobalRoomInfo()

    local tPlayerList = {}
    for _, v in pairs(tRoomInfo) do
        if type(v) == "table" and v.szGlobalID then
            table.insert(tPlayerList, v)
        end
    end

    DataModel.tPlayerList = tPlayerList
    DataModel.dwTargetMapID = tRoomInfo.nTargetMapID
    DataModel.nPublicProcess = tRoomInfo.nRoomProgress

    --目标地图副本信息
    DataModel.tProcessInfo = {}
    if tRoomInfo.nTargetMapID then
        DataModel.tProcessInfo = GetCDProcessInfo(tRoomInfo.nTargetMapID) or {}
    end
end

function DataModel.GetProcess(nProgressInfo)
    local tRes = {}
    for i = 1, #DataModel.tProcessInfo do
        local bFlag = GetDungeonRoleSimpleProgress(nProgressInfo, i)
        tRes[i] = bFlag
    end
    return tRes
end

-----------------------------View------------------------------
local UIRoomProgressView = class("UIRoomProgressView")

function UIRoomProgressView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    DataModel.ApplyRoomDetailInfo()
end

function UIRoomProgressView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRoomProgressView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.LayoutProgress, EventType.OnClick, function()
        local szTips = string.format("<color=#FEFEFE>%s</color>", g_tStrings.STR_ROOM_PROCESS_TIP)
        local tips, tipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnRule, szTips)
        local nWidth, nHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(nWidth, nHeight)
        tips:UpdatePosByNode(self.BtnRule)
    end)
end

function UIRoomProgressView:RegEvent()
    Event.Reg(self, "LOADING_END", function ()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "GLOBAL_ROOM_DESTROY", function ()
        UIMgr.Close(self)
    end)

    Event.Reg(self, "GLOBAL_ROOM_BASE_INFO", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_DETAIL_INFO", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, "GLOBAL_ROOM_MEMBER_CHANGE", function()
        self:UpdateInfo()
    end)
end

function UIRoomProgressView:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRoomProgressView:UpdateInfo()
    local hPlayer = GetClientPlayer()
	if not hPlayer or not hPlayer.GetGlobalRoomID() then
		return
	end

    DataModel.Update()

    if MonsterBookData.IsBaiZhanMap(DataModel.dwTargetMapID) then
        OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_OPEN_WITH_REMOTE_BAIZHAN)
        UIMgr.Close(self)
        return 
    end

    self:UpdateRoomProcess()
    self:UpdateRoommateDetail()
    self:UpdateRoomBtnList()
end

function UIRoomProgressView:UpdateRoomProcess()
    if DataModel.dwTargetMapID and DataModel.dwTargetMapID ~= 0 then
        UIHelper.SetString(self.LabelTargetName, UIHelper.GBKToUTF8(Table_GetMapName(DataModel.dwTargetMapID)))
        UIHelper.SetVisible(self.WidgetChosen, true)
        UIHelper.SetVisible(self.LabelEmpty, false)
    else
        UIHelper.SetString(self.LabelTargetName, g_tStrings.STR_ROOM_NO_TARGET)
        UIHelper.SetVisible(self.WidgetChosen, false)
        UIHelper.SetVisible(self.LabelEmpty, true)
    end

    local tProgress = DataModel.GetProcess(DataModel.nPublicProcess)
    for i = 1, #self.tImgPointsBg do
        if i <= #tProgress then
            local bFlag = tProgress[i]
            local imgKill = UIHelper.GetChildByName(self.tImgPointsBg[i], "ImgPoint")
            local imgNotKill = UIHelper.GetChildByName(self.tImgPointsBg[i], "ImgPointBg")
            UIHelper.SetVisible(imgKill, bFlag)
            UIHelper.SetVisible(imgNotKill, not bFlag)
            UIHelper.SetVisible(self.tImgPointsBg[i], true)
        else
            UIHelper.SetVisible(self.tImgPointsBg[i], false)
        end
    end
    UIHelper.LayoutDoLayout(self.WidgetPoints)
    UIHelper.LayoutDoLayout(self.LayoutProgress)
end

function UIRoomProgressView:UpdateRoommateDetail()
    UIHelper.RemoveAllChildren(self.ScrollViewRoommateList)
    local tPlayerList = DataModel.tPlayerList
    for i = 1, #tPlayerList do
        local tPlayer = tPlayerList[i]
        local tProgress = DataModel.GetProcess(tPlayer.nProcess)
        UIHelper.AddPrefab(PREFAB_ID.WidgetRoomProgressCell, self.ScrollViewRoommateList, tPlayer, tProgress)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRoommateList)
end

function UIRoomProgressView:UpdateRoomBtnList()
end


return UIRoomProgressView