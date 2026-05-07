-- ---------------------------------------------------------------------------------
-- Author: luwenhao
-- Name: UIUpdateAbroadView
-- Date: 2023-08-21 17:05:38
-- Desc: PanelUpdateAbroad 更新日志界面
-- ---------------------------------------------------------------------------------

local UIUpdateAbroadView = class("UIUpdateAbroadView")

local tFontConvert = {
    ["#b22222"] = "<font size='30'><color=#ffffff>%s</color></font>",
    ["#0000ff"] = "<font size='26'><color=#d7f6ff>%s</color></font>",
    ["#ff0000"] = "<color=#ffe26e>%s</color>",
}

function UIUpdateAbroadView:OnEnter(szBulletinType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tBulletinCache = {}

    --界面打开一次后刷新存储公告内容
    BulletinData.UpdateBulletinStorage()

    -- local text1 = "hello worldd   <div>hello world</div> 你好 <div fontName='nihao' fontSize=#123456>hello,world</div><div></div>"
    -- local parsedtable = labelparser.parse(text1)
    -- print_table_utf8(parsedtable)

    if AppReviewMgr.IsReview() then
        UIHelper.SetVisible(self.TogList1, true)
        UIHelper.SetSelected(self.TogList1, true)

        UIHelper.SetVisible(self.TogList2, false)
        UIHelper.SetVisible(self.TogList3, false)
        UIHelper.SetVisible(self.TogList4, false)
        UIHelper.SetVisible(self.TogList5, false)
    else
        self.szBulletinType = szBulletinType or BulletinType.UpdateLog
        self:InitTog()

        if self.szBulletinType == BulletinType.UpdateLog then
            UIHelper.SetSelected(self.TogList1, true)
        elseif self.szBulletinType == BulletinType.Announcement then
            UIHelper.SetSelected(self.TogList2, true)
        elseif self.szBulletinType == BulletinType.System then
            UIHelper.SetSelected(self.TogList3, true)
        elseif self.szBulletinType == BulletinType.Recharge then
            UIHelper.SetSelected(self.TogList4, true)
        elseif self.szBulletinType == BulletinType.SkillUpdate then
            UIHelper.SetSelected(self.TogList5, true)
        end
    end

    if Channel.Is_WLColud() then
        UIHelper.SetVisible(self.TogList2, false)
    end
end

function UIUpdateAbroadView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIUpdateAbroadView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.TogList1, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateInfo(BulletinType.UpdateLog)
            self.bRefreshScrollView = true
        end
    end)
    UIHelper.BindUIEvent(self.TogList2, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateInfo(BulletinType.Announcement)
            self.bRefreshScrollView = true
        end
    end)
    UIHelper.BindUIEvent(self.TogList3, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateInfo(BulletinType.System)
            self.bRefreshScrollView = true
        end
    end)
    UIHelper.BindUIEvent(self.TogList4, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateInfo(BulletinType.Recharge)
            self.bRefreshScrollView = true
        end
    end)
    UIHelper.BindUIEvent(self.TogList5, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            self:UpdateInfo(BulletinType.SkillUpdate)
            self.bRefreshScrollView = true
        end
    end)
end

function UIUpdateAbroadView:RegEvent()
    Event.Reg(self, EventType.OnBulletinUpdate, function()
        self:OnBulletinUpdate()
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        --窗口大小变化时，刷新一下，不然可能公告边缘的文字会被遮挡
        if self.tBulletinCache[self.szBulletinType] then
            self:OnBulletinUpdate()
        end
    end)

    Event.Reg(self, EventType.OnRichTextOpenUrl, function (szUrl, node)
        UIHelper.OpenWebWithDefaultBrowser(szUrl)
    end)
end

function UIUpdateAbroadView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIUpdateAbroadView:InitTog()
    local _, szAnnouncement = BulletinData.GetBulletin(BulletinType.Announcement)
    local _, szSystemBulletin = BulletinData.GetBulletin(BulletinType.System)
    local _, szRechargeBulletin = BulletinData.GetBulletin(BulletinType.Recharge)
    local _, szSkillUpdate = BulletinData.GetBulletin(BulletinType.SkillUpdate)

    --无系统公告，则不显示系统公告切页
    --游戏公告与系统公告内容相同，则不显示系统公告切页

    local function IsBlankString(str)
        return string.is_nil(str) or str:match("^%s*$") ~= nil
    end

    local bHasSystemBulletin = not IsBlankString(szSystemBulletin)
    local bHasRechargeBulletin = not IsBlankString(szRechargeBulletin) and BulletinData.IsInShowTime(BulletinType.Recharge)
    local bHasSkillUpdate = not IsBlankString(szSkillUpdate) and BulletinData.IsInShowTime(BulletinType.SkillUpdate)
    self.bSameContent = bHasSystemBulletin and string.trim(szAnnouncement) == string.trim(szSystemBulletin)

    if self.szBulletinType == BulletinType.System then
        if not bHasSystemBulletin then
            self.szBulletinType = BulletinType.UpdateLog
        elseif self.bSameContent then
            self.szBulletinType = BulletinType.Announcement
        end
    elseif (self.szBulletinType == BulletinType.Recharge and not bHasRechargeBulletin) or (self.szBulletinType == BulletinType.SkillUpdate and not bHasSkillUpdate) then
        self.szBulletinType = BulletinType.UpdateLog
    end

    UIHelper.SetVisible(self.TogList3, bHasSystemBulletin and not self.bSameContent)
    UIHelper.SetVisible(self.TogList4, bHasRechargeBulletin)
    UIHelper.SetVisible(self.TogList5, bHasSkillUpdate)
    UIHelper.LayoutDoLayout(self.LayoutTab)
end

function UIUpdateAbroadView:UpdateInfo(szBulletinType)
    UIHelper.SetVisible(self.WidgetAnchorContent, false)
    UIHelper.SetVisible(self.WidgetPCAnnouncement, false)
    UIHelper.SetVisible(self.WidgetLoading, true)
    UIHelper.SetVisible(self.WidgetFail, false)
    UIHelper.SetVisible(self.WidgetEmpty, false)

    self.szBulletinType = szBulletinType

    if not self.tBulletinCache[szBulletinType] then
        BulletinData.RequestBulletin(szBulletinType)
    else
        self:OnBulletinUpdate()
    end
end

function UIUpdateAbroadView:OnBulletinUpdate()
    local szBulletinType = self.szBulletinType

    UIHelper.SetVisible(self.WidgetLoading, false)
    UIHelper.SetVisible(self.WidgetFail, false)
    UIHelper.SetVisible(self.WidgetEmpty, false)

    local bSuccess, szContent = BulletinData.GetBulletin(szBulletinType)

    if bSuccess == nil and not szContent then
        UIHelper.SetVisible(self.WidgetLoading, true)
        return
    end

    if bSuccess == false and not szContent then
        UIHelper.SetVisible(self.WidgetFail, true)
        return
    end

    if not szContent or szContent == "" then
        UIHelper.SetVisible(self.WidgetEmpty, true)
        return
    end

    self.tBulletinCache[szBulletinType] = true

    if szBulletinType == BulletinType.UpdateLog then
        self:UpdateUpdateLog(szContent)
    elseif szBulletinType == BulletinType.Announcement then
        self:UpdateAnnouncement(szContent)
    elseif szBulletinType == BulletinType.System then
        self:UpdateSystemBulletin(szContent)
    elseif szBulletinType == BulletinType.Recharge then
        self:UpdateRechargeBulletin(szContent)
    elseif szBulletinType == BulletinType.SkillUpdate then
        self:UpdateSkillUpdate(szContent)
    end

    --TODO 设置图片？ImgBanner
end

function UIUpdateAbroadView:SetContentWithTitle(szContent, bTitle, bDate, bVersion)
    local tParse = labelparser.parse(szContent)
    if not tParse then
        UIHelper.SetVisible(self.WidgetFail, true)
        return
    end

    UIHelper.SetVisible(self.WidgetAnchorContent, true)
    UIHelper.SetVisible(self.WidgetPCAnnouncement, false)

    local szTitle
    local szUpdateTime
    local szUpdateVersion
    local szText = ""

    -- print_table(tParse)

    for k, v in ipairs(tParse) do
        local szParseContent = v.content
        local szStyle = v.style
        local szLabelName = v.labelname
        local href = v.href
        if not string.is_nil(szParseContent) then
            szParseContent = UIHelper.RichTextEscape(szParseContent)
            szParseContent = string.gsub(szParseContent, "\r\n", "\n")
            szParseContent = string.trim(szParseContent, " ") --去除行首空格

            if szStyle then
                szStyle = string.gsub(szStyle, " ", "")
            end
            if (not bTitle or szTitle) and (not bDate or szUpdateTime) and (not bVersion or szUpdateVersion) then
                --去除全文开头的换行
                if szText ~= "" or szParseContent ~= "\n" then
                    local szColor
                    if szStyle then
                        szColor = string.match(szStyle, "color:(#.-);")
                        if not szColor then
                            --颜色的html格式还有一种这样的：color: rgb(255, 0, 0)
                            local nR, nG, nB = string.match(szStyle, "color:rgb%((.-),(.-),(.-)%);")
                            if nR and nG and nB then
                                szColor = "#" .. string.format("%02x", nR) .. string.format("%02x", nG) .. string.format("%02x", nB)
                            end
                        end
                    end

                    if szColor and tFontConvert[szColor] then
                        szParseContent = string.format(tFontConvert[szColor], szParseContent)
                    elseif href then
                        --默认蓝色
                        szParseContent = UIHelper.AttachTextColor(szParseContent, FontColorID.ImportantBlue)
                    else
                        szParseContent = UIHelper.AttachTextColor(szParseContent, FontColorID.Text_Level2)
                    end

                    if href then
                        szParseContent = string.format("<a href='%s'>%s</a>", href, szParseContent)
                    end

                    if string.match(szLabelName, "<strong>") then
                        szParseContent = "<b>" .. szParseContent .. "</b>"
                    end
                    szText = szText .. szParseContent
                end
            end

            szTitle = szTitle or string.match(szParseContent, "%[title%](.*)%[title%]")
            szUpdateTime = szUpdateTime or string.match(szParseContent, "(更新时间：.*)")
            szUpdateVersion = szUpdateVersion or string.match(szParseContent, "(更新版本：.*)")
        end
    end

    szTitle = szTitle and string.gsub(szTitle, " ", "")
    szUpdateTime = szUpdateTime and string.gsub(szUpdateTime, " ", "")
    szUpdateVersion = szUpdateVersion and string.gsub(szUpdateVersion, " ", "")

    UIHelper.SetString(self.LabelTitle, szTitle or "剑网3无界")
    UIHelper.SetString(self.LabelUpdateTime, szUpdateTime)
    UIHelper.SetVisible(self.LabelUpdateTime, not AppReviewMgr.IsReview())
    UIHelper.SetString(self.LabelUpdateVision, "")--szUpdateVersion)
    UIHelper.SetRichText(self.LabelContent, szText)

    if self.bRefreshScrollView then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        self.bRefreshScrollView = false
    end
end

function UIUpdateAbroadView:SetContentWithoutTitle(szContent)
    UIHelper.SetVisible(self.WidgetAnchorContent, false)
    UIHelper.SetVisible(self.WidgetPCAnnouncement, true)


    local szText, szDate = string.match(szContent, "(.*)\n(.*)$")
    if szText and szDate then
        UIHelper.SetRichText(self.LabelPCAnnouncement, szText)
        UIHelper.SetRichText(self.LabelData, szDate)
        UIHelper.SetVisible(self.LabelData, true)
    else
        UIHelper.SetRichText(self.LabelPCAnnouncement, szContent)
        UIHelper.SetVisible(self.LabelData, false)
    end

    if self.bRefreshScrollView then
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent2)
        self.bRefreshScrollView = false
    end
end

function UIUpdateAbroadView:UpdateUpdateLog(szContent)
    szContent = ParseTextHelper.HtmlTextUnescape(szContent)
    self:SetContentWithTitle(szContent, false, true, true)

    local szUpdateLogMD5 = UIHelper.MD5(szContent)
    if self.szUpdateLogMD5 ~= szUpdateLogMD5 then
        self.szUpdateLogMD5 = szUpdateLogMD5
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        end)
    end

    RedpointHelper.Bulletin_Update(BulletinType.UpdateLog)
end

function UIUpdateAbroadView:UpdateAnnouncement(szContent)
    self:SetContentWithoutTitle(szContent)

    local szAnnouncementMD5 = UIHelper.MD5(szContent)
    if self.szAnnouncementMD5 ~= szAnnouncementMD5 then
        self.szAnnouncementMD5 = szAnnouncementMD5
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent2)
        end)
    end

    RedpointHelper.Bulletin_Update(BulletinType.Announcement)

    --若系统公告与游戏公告内容相同，也记录系统公告的点击状态
    if self.bSameContent then
        RedpointHelper.Bulletin_Update(BulletinType.System)
    end
end

function UIUpdateAbroadView:UpdateSystemBulletin(szContent)
    self:SetContentWithoutTitle(szContent)

    local szSystemMD5 = UIHelper.MD5(szContent)
    if self.szSystemMD5 ~= szSystemMD5 then
        self.szSystemMD5 = szSystemMD5
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent2)
        end)
    end

    RedpointHelper.Bulletin_Update(BulletinType.System)
end

function UIUpdateAbroadView:UpdateRechargeBulletin(szContent)
    szContent = ParseTextHelper.HtmlTextUnescape(szContent)
    self:SetContentWithTitle(szContent, true)

    local szRechargeMD5 = UIHelper.MD5(szContent)
    if self.szRechargeMD5 ~= szRechargeMD5 then
        self.szRechargeMD5 = szRechargeMD5
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent2)
        end)
    end

    RedpointHelper.Bulletin_Update(BulletinType.Recharge)
end

function UIUpdateAbroadView:UpdateSkillUpdate(szContent)
    szContent = ParseTextHelper.HtmlTextUnescape(szContent)
    self:SetContentWithTitle(szContent, true)

    local szSkillUpdateMD5 = UIHelper.MD5(szContent)
    if self.szSkillUpdateMD5 ~= szSkillUpdateMD5 then
        self.szSkillUpdateMD5 = szSkillUpdateMD5
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent2)
        end)
    end

    RedpointHelper.Bulletin_Update(BulletinType.SkillUpdate)
end

return UIUpdateAbroadView