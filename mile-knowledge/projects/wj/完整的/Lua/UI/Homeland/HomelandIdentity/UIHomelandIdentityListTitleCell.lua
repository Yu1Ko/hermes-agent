-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityListTitleCell
-- Date: 2024-01-22 19:47:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandIdentityListTitleCell = class("UIHomelandIdentityListTitleCell")

function UIHomelandIdentityListTitleCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    -- self.dwActiveID = dwActiveID
    self:UpdateInfo()
end

function UIHomelandIdentityListTitleCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityListTitleCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTrack, EventType.OnClick, function()
        if table.is_empty(self.tLink) then
            return
        end
        local tLinkInfo       = self.tLink
        local tbInfo          = self.tbInfo
        local nLinkID         = tLinkInfo.nLinkID
        local dwMapID         = tbInfo.dwMapID
        local nCopyIndex      = tbInfo.nCopyIndex
        if IsHomelandCommunityMap(dwMapID) then
            HomelandData.CheckIsHomelandMapTeleportGo(nLinkID, dwMapID, nil, nCopyIndex, function ()
                UIMgr.CloseAllInLayer("UIPageLayer")
                UIMgr.CloseAllInLayer("UIPopupLayer")
            end)
        else
            MapMgr.CheckTransferCDExecute(function()
                RemoteCallToServer("On_Teleport_Go", nLinkID, dwMapID)
                UIMgr.CloseAllInLayer("UIPageLayer")
                UIMgr.CloseAllInLayer("UIPopupLayer")
            end, dwMapID)
        end
    end)
end

function UIHomelandIdentityListTitleCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityListTitleCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityListTitleCell:UpdateInfo()
    local tbInfo = self.tbInfo
    local nLinkID         = tbInfo.nLinkID
    local dwMapID         = tbInfo.dwMapID
    local nCommunityIndex = tbInfo.nCommunityIndex
    local szMapName       = Table_GetMapName(dwMapID) or ""
    szMapName             = UIHelper.GBKToUTF8(szMapName)
    self.tLink            = Table_GetCareerLinkNpcInfo(nLinkID, dwMapID) or {}
    if HomelandData.IsHomelandMap(dwMapID) then
        szMapName = szMapName..FormatString(g_tStrings.STR_HOMELAND_COMMUNITY_INDEX, nCommunityIndex or 1)
    end
    UIHelper.SetString(self.LabelTypeName, szMapName)
end

-- function UIHomelandIdentityListTitleCell:UpdateInfo()
--     local dwActiveID    = self.dwActiveID
--     local tInfo         = Table_GetCalenderActivity(dwActiveID)
--     local fn = function ()
--         local szTime, bOpen = GetActivityTimeDesc(dwActiveID)
--         UIHelper.SetVisible(self.BtnTrack, bOpen)
--         UIHelper.SetVisible(self.LabelTypeState, not bOpen)
--         UIHelper.SetString(self.LabelTypeState, szTime)
--     end

--     UIHelper.SetString(self.LabelTypeName, UIHelper.GBKToUTF8(tInfo.szName))
--     Timer.AddCycle(self, 1, function ()
--         fn()
--     end)
--     fn()
-- end


return UIHomelandIdentityListTitleCell