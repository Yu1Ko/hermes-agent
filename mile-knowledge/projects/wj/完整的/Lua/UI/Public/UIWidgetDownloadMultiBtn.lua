-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetDownloadMultiBtn
-- Date: 2023-11-28 10:06:10
-- Desc: WidgetDownloadMultiBtn
-- ---------------------------------------------------------------------------------

local UIWidgetDownloadMultiBtn = class("UIWidgetDownloadMultiBtn")

function UIWidgetDownloadMultiBtn:OnEnter(szName, tPackIDList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szName = szName or ""
    self.tPackIDList = tPackIDList or {}

    self:UpdateInfo()
end

function UIWidgetDownloadMultiBtn:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetDownloadMultiBtn:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDownloadInfo, EventType.OnClick, function()
        
    end)
    
end

function UIWidgetDownloadMultiBtn:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetDownloadMultiBtn:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetDownloadMultiBtn:UpdateInfo()
    local tStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(self.tPackIDList)
    UIHelper.SetString(self.LabelCount, self.szName .. "(" .. PakDownloadMgr.FormatSize(tStateInfo.dwTotalSize) .. ")")
end


return UIWidgetDownloadMultiBtn