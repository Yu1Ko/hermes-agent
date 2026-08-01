-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIResourcesDownloadPop
-- Date: 2023-04-06 11:17:33
-- Desc: PanelResourcesDownloadPop
-- ---------------------------------------------------------------------------------

local UIResourcesDownloadPop = class("UIResourcesDownloadPop")

function UIResourcesDownloadPop:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        -- Timer.AddCycle(self, 1, function()
        --     self:UpdateDownloadSpeed()
        -- end)
    end

    self:UpdateInfo()
    --self:UpdateDownloadSpeed()
end

function UIResourcesDownloadPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIResourcesDownloadPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UIResourcesDownloadPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIResourcesDownloadPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIResourcesDownloadPop:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewList)

    local tList = PakDownloadMgr.GetBasicPackIDList()
    if not tList then
        return
    end

    for _, nPackID in ipairs(tList) do
        UIMgr.AddPrefab(PREFAB_ID.WidgetResourcesCell_Small, self.ScrollViewList, nPackID, ResourcesCellType.Resource)
    end

    Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewDoLayout(self.ScrollViewList)
        UIHelper.ScrollToTop(self.ScrollViewList, 0)
    end)

    UIHelper.SetVisible(self.LayoutSpeed, false)
end

--下载速度每秒刷新一次
function UIResourcesDownloadPop:UpdateDownloadSpeed()
    local tTotalInfo = PakDownloadMgr.GetTotalDownloadInfo()
    local bDownloading = tTotalInfo.nTotalState == TOTAL_DOWNLOAD_STATE.DOWNLOADING
    UIHelper.SetVisible(self.LayoutSpeed, bDownloading)
    if bDownloading then
        UIHelper.SetString(self.LabelSpeed, PakDownloadMgr.FormatSize(tTotalInfo.dwTotalDownloadSpeed, 2) .. "/s（" .. PakDownloadMgr.FormatTime(tTotalInfo.nLeftTime) .. "）")
    end
end

return UIResourcesDownloadPop