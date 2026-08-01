-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIDownloadView
-- Date: 2022-11-30 09:48:37
-- Desc: 登录资源下载界面 PanelDownload
-- ---------------------------------------------------------------------------------

local UIDownloadView = class("UIDownloadView")

-- local AUTO_TURN_PAGE_TIME = 5
-- local PAGE_TURNING_TIME = 1

-- local m_nProgerssTimerID
-- local m_nPageTimerID

function UIDownloadView:OnEnter(fnCompleteCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        --2023.4.11: 这个界面暂时不用

        -- self.fnCompleteCallback = fnCompleteCallback
        -- self.moduleDownload = LoginMgr.GetModule(LoginModule.LOGIN_DOWNLOAD)
        -- --self:StartAutoTurnPage() --手机上加载场景时翻页可能会翻到一半卡住，先把自动翻页先关了

        -- --TODO 判断有无需要下载的内容，若有则询问是否下载，开始下载后再更新下载进度
        -- if self.moduleDownload.CheckNeedDownload() then
        --     --TODO 询问是否下载
        --     self.moduleDownload.StartDownload(function()
        --         self:StopUpdateProgress()
        --         if self.fnCompleteCallback then
        --             self.fnCompleteCallback()
        --         end
        --     end)
        --     self:StartUpdateProgress()
        -- end
    end
end

function UIDownloadView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDownloadView:BindUIEvent()
    
end

function UIDownloadView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDownloadView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- function UIDownloadView:StartAutoTurnPage()
--     --TODO 加载要显示的图片

--     local nMaxPageCount = #UIHelper.GetListViewItems(self.PageViewImg)
--     if nMaxPageCount <= 0 then return end

--     UIHelper.SetPageIndex(self.PageViewImg, 0)

--     m_nPageTimerID = Timer.AddCycle(self, AUTO_TURN_PAGE_TIME, function()
--         local nPageIndex = UIHelper.GetPageIndex(self.PageViewImg)
--         nPageIndex = nPageIndex + 1
--         if nPageIndex >= nMaxPageCount then
--             nPageIndex = 0
--         end
        
--         UIHelper.ScrollToPage(self.PageViewImg, nPageIndex, PAGE_TURNING_TIME)
--     end)
-- end

-- function UIDownloadView:StartUpdateProgress()
--     self:StopUpdateProgress()
--     m_nProgerssTimerID = Timer.AddFrameCycle(self, 1, function()
--         self:UpdateProgress()
--     end)
-- end

-- function UIDownloadView:StopUpdateProgress()
--     if m_nProgerssTimerID then
--         Timer.DelTimer(self, m_nProgerssTimerID)
--     end
-- end

-- function UIDownloadView:UpdateProgress()
--     local nProgress = self.moduleDownload.GetDownloadProgress() * 100
--     UIHelper.SetString(self.LabelBar, string.format("%d%%", nProgress))
--     UIHelper.SetProgressBarPercent(self.ProgressBar, nProgress) 
-- end

return UIDownloadView