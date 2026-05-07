-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UITutorialLiteView
-- Date: 2024-02-26 17:09:18
-- Desc: PanelTutorialLite
-- ---------------------------------------------------------------------------------

local UITutorialLiteView = class("UITutorialLiteView")

function UITutorialLiteView:OnEnter(...)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tPageInfo = {}

    local tIDList = {...}
    for _, nID in ipairs(tIDList) do
        local tLine = TabHelper.GetUITeachBoxTab(nID)
        if tLine then
            TeachBoxData.UpdateTeachInfo(nID)

            local nPageCount = #TeachBoxData.tbImgList
            local szName = tLine.szName
            local nEndPageIndex = #self.tPageInfo + nPageCount

            for i = 1, nPageCount do
                local tInfo = {
                    nID = nID,
                    nEndPageIndex = nEndPageIndex,
                    szName = szName,
                    szDesc = TeachBoxData.tbDescList[i],
                    szImgPath = TeachBoxData.tbImgList[i],
                }
                table.insert(self.tPageInfo, tInfo)
            end
        else
            LOG.ERROR("UITutorialLiteView, UITeachBoxTab.nID Error: %s", tostring(nID))
        end
    end

    self.nPageIndex = 1
    self:UpdateInfo()
end

function UITutorialLiteView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITutorialLiteView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPrevious, EventType.OnClick, function()
        if self.nPageIndex > 1 then
            self.nPageIndex = self.nPageIndex - 1
            self:UpdateInfo()
        end
    end)
    UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function()
        local nPageCount = #self.tPageInfo
        if self.nPageIndex < nPageCount then
            self.nPageIndex = self.nPageIndex + 1
            self:UpdateInfo()
        end
    end)
    UIHelper.BindUIEvent(self.BtnBtnConfirm, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UITutorialLiteView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITutorialLiteView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITutorialLiteView:UpdateInfo()
    local tInfo = self.tPageInfo[self.nPageIndex]
    if not tInfo then
        return
    end

    UIHelper.SetString(self.LabelTitle09, tInfo.szName)
    UIHelper.SetRichText(self.RichTextMessage, tInfo.szDesc)

    local szFileName = tInfo.szImgPath
    local tbPathInfo = {}
    for part in string.gmatch(szFileName, "[^%.]+") do
        table.insert(tbPathInfo, part)
    end
    UIHelper.SetVisible(self.ImgTutorial, false)
    UIHelper.SetVisible(self.VideoPlayerTutorial, false)
    if tbPathInfo[#tbPathInfo] == "png" then
        UIHelper.SetVisible(self.ImgTutorial, true)
        szFileName = string.format("Resource/%s", szFileName)
        UIHelper.SetTexture(self.ImgTutorial, szFileName)
    elseif tbPathInfo[#tbPathInfo] == "bk2" then
        UIHelper.SetVisible(self.VideoPlayerTutorial, true)
        self.VideoPlayerTutorial:setUserInputEnabled(false)  -- 禁止暂停
        UIHelper.SetVideoPlayerModel(self.VideoPlayerTutorial , VIDEOPLAYER_MODEL.BINK)
        szFileName = UIHelper.ParseVideoPlayerFile(szFileName , VIDEOPLAYER_MODEL.BINK)
        UIHelper.SetVideoLooping(self.VideoPlayerTutorial, true)
        UIHelper.PlayVideo(self.VideoPlayerTutorial, szFileName, true, function(nVideoPlayerEvent, szMsg)
            if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED then
            elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
                TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
            end
        end)
    end

    local nPageCount = #self.tPageInfo
    if self.nPageIndex >= tInfo.nEndPageIndex then
        Storage.TeachBox.tbNewTeachLine[tInfo.nID] = true
        Storage.TeachBox.Flush()
    end

    UIHelper.SetVisible(self.BtnPrevious, self.nPageIndex > 1)
    UIHelper.SetVisible(self.BtnNext, self.nPageIndex < nPageCount)
    --UIHelper.SetVisible(self.BtnBtnConfirm, not not Storage.TeachBox.tbNewTeachLine[tInfo.nID]) -- not not: nil -> false
    UIHelper.SetVisible(self.BtnBtnConfirm, true) --2024.6.26 确定按钮默认显示

    UIHelper.SetVisible(self.WidgetPaginate, nPageCount ~= 1)
    UIHelper.SetString(self.LabelPage, string.format("%d/%d", self.nPageIndex, nPageCount))

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetail)
end


return UITutorialLiteView