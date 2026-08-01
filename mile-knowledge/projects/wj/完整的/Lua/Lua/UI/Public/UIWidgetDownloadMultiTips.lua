-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetDownloadMultiTips
-- Date: 2023-11-28 09:55:20
-- Desc: WidgetDownloadMultiTips
-- ---------------------------------------------------------------------------------

local UIWidgetDownloadMultiTips = class("UIWidgetDownloadMultiTips")

function UIWidgetDownloadMultiTips:OnEnter(tPackIDListInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tPackIDListInfo = tPackIDListInfo
    self:UpdateInfo()
end

function UIWidgetDownloadMultiTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetDownloadMultiTips:BindUIEvent()
    
end

function UIWidgetDownloadMultiTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetDownloadMultiTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetDownloadMultiTips:UpdateInfo()
    for _, tInfo in ipairs(self.tPackIDListInfo or {}) do
        local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tInfo.tPackIDList)
        if tStateInfo.nState ~= DOWNLOAD_STATE.COMPLETE and tStateInfo.dwTotalSize > 0 and tStateInfo.dwDownloadedSize < tStateInfo.dwTotalSize then
            UIHelper.AddPrefab(PREFAB_ID.WidgetDownloadMultiBtn, self.LayoutBtnList, tInfo.szName, tInfo.tPackIDList)
        end
    end
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end


return UIWidgetDownloadMultiTips