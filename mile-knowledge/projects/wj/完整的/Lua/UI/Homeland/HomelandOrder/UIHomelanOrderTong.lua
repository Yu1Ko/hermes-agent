-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelanOrderTong
-- Date: 2024-01-15 16:54:24
-- Desc: ?
-- ---------------------------------------------------------------------------------
local TONGFIELD_LINK_ID = 2530
local TONGFIELD_MAPID = 74
local MAX_TONG_ORDER_COUNT = 3
local function IsClientPlayerHaveTong()
	local hPlayer = GetClientPlayer()
	if not hPlayer or not hPlayer.dwTongID or hPlayer.dwTongID == 0 then
		return false
	end
	return true
end
local UIHomelanOrderTong = class("UIHomelanOrderTong")

function UIHomelanOrderTong:OnEnter(DataModel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.DataModel = DataModel
    self:UpdatePageInfo()
end

function UIHomelanOrderTong:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelanOrderTong:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeaveFor, EventType.OnClick, function ()
        local bHaveTong = IsClientPlayerHaveTong()
        if not bHaveTong then
            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_JOIN_TONG)
            return
        end
        local tLink = Table_GetCareerLinkNpcInfo(TONGFIELD_LINK_ID, TONGFIELD_MAPID)
        if not tLink then
            return
        end
        local tTrack = {
            nID      = TONGFIELD_LINK_ID,
            dwMapID  = TONGFIELD_MAPID,
            szName   = UIHelper.GBKToUTF8(tLink.szNpcName),
            nX       = tLink.fX,
            nY       = tLink.fY,
            nZ       = tLink.fZ,
            szSource = "Custom",
        }
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelHomeIdentity)
        MapMgr.SetTracePoint(tTrack.szName, tTrack.dwMapID, {tTrack.nX, tTrack.nY, tTrack.nZ})
        MapMgr.TryTransfer(TONGFIELD_MAPID)
    end)
end

function UIHomelanOrderTong:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelanOrderTong:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelanOrderTong:UpdatePageInfo(nTypeIndex)
    UIHelper.SetVisible(self.WidgetAffiche, false)
    UIHelper.SetVisible(self._rootNode, false)
    if nTypeIndex ~= HLORDER_TYPE.TONG then
        return
    end
    UIHelper.SetVisible(self._rootNode, true)
    local hPlayer = GetClientPlayer()
	if not hPlayer or not hPlayer.dwTongID or hPlayer.dwTongID == 0 then
        -- OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_JOIN_TONG)
        self.bHaveTong = false
    else
        self.bHaveTong = true
        if hPlayer.GetMapID() ~= TONGFIELD_MAPID then
            -- UIHelper.SetVisible(self.WidgetAffiche, true)
        end
	end
end

function UIHomelanOrderTong:UpdateInfo(tTongInfos)
    UIHelper.RemoveAllChildren(self.LayoutFactionOrder)
    -- if not tTongInfos or #tTongInfos == 0 or tTongInfos[1].dwID == 0 then
    --     UIHelper.SetVisible(self.WidgetAffiche, true)
    --     return
    -- end

    self.tTongInfos = tTongInfos
    for i = 1, MAX_TONG_ORDER_COUNT, 1 do
        local tInfo = self.DataModel.GetOrderInfo(tTongInfos[i].dwID, HLORDER_TYPE.TONG)
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetFactionOrder, self.LayoutFactionOrder)
        script:OnEnter(self.bHaveTong, tTongInfos[i], tInfo, i)
    end
    UIHelper.LayoutDoLayout(self.LayoutFactionOrder)
end


return UIHomelanOrderTong