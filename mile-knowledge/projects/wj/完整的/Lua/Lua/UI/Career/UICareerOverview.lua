-- WidgetMarkOverview

local UICareerOverview = class("UICareerOverview")
local minSelectedID = 1
local maxSelectedID = 3

local szTitle = {
    [1] = "战力篇",
    [2] = "外观篇",
    [3] = "休闲篇"
}

local szTime = "2025年10月30日~2026年4月23日"
local szImgPath = "UIAtlas2_Career_CareerTitle_QunXiaWanBian"

local tImgPath = {
    [0] = "UIAtlas2_Career_CareerIcon_ZhuangFenJin.png",
    [1] = "UIAtlas2_Career_CareerIcon_ZhuangFenZi.png",
    [2] = "UIAtlas2_Career_CareerIcon_MiJingZi.png",
    [3] = "UIAtlas2_Career_CareerIcon_JiShaZi.png",
    [4] = "UIAtlas2_Career_CareerIcon_JJCZi.png",
    [5] = "UIAtlas2_Career_CareerIcon_JJCBlue.png",
    [6] = "UIAtlas2_Career_CareerIcon_ChiJiZi.png",
    [7] = "UIAtlas2_Career_CareerIcon_ZhanChangBlue.png",
    [8] = "UIAtlas2_Career_CareerIcon_ZhenYingZi.png",
    [9] = "UIAtlas2_Career_CareerIcon_ZhenYingBlue.png",
    [10] = "UIAtlas2_Career_CareerIcon_YSWZ.png",
    [11] = "UIAtlas2_Career_CareerIcon_WaiGuanJin.png",
    [12] = "UIAtlas2_Career_CareerIcon_HongFaZi.png",
    [13] = "UIAtlas2_Career_CareerIcon_JinFaZi.png",
    [14] = "UIAtlas2_Career_CareerIcon_PiFengZi.png",
    [15] = "UIAtlas2_Career_CareerIcon_ChengHaoZi.png",
    [16] = "UIAtlas2_Career_CareerIcon_ChengHaoBlue.png",
    [17] = "UIAtlas2_Career_CareerIcon_XWYZi.png",
    [18] = "UIAtlas2_Career_CareerIcon_XWYBlue.png",
    [19] = "UIAtlas2_Career_CareerIcon_ZuoQiZi.png",
    [20] = "UIAtlas2_Career_CareerIcon_ZuoQiBlue.png",
    [21] = "UIAtlas2_Career_CareerIcon_PSWH.png",
    [22] = "UIAtlas2_Career_CareerIcon_QiYuJin.png",
    [23] = "UIAtlas2_Career_CareerIcon_QiYuZi.png",
    [24] = "UIAtlas2_Career_CareerIcon_ChongWuQiyuZi.png",
    [25] = "UIAtlas2_Career_CareerIcon_XYQYZi.png",
    [26] = "UIAtlas2_Career_CareerIcon_ChengJiuZi.png",
    [27] = "UIAtlas2_Career_CareerIcon_ChengJiuBlue.png",
    [28] = "UIAtlas2_Career_CareerIcon_ChongWuZi.png",
    [29] = "UIAtlas2_Career_CareerIcon_ChongWuBlue.png",
    [30] = "UIAtlas2_Career_CareerIcon_ShengWangZi.png",
    [31] = "UIAtlas2_Career_CareerIcon_ShengWangBlue.png",
    [32] = "UIAtlas2_Career_CareerIcon_JiaYuanZi.png",
    [33] = "UIAtlas2_Career_CareerIcon_JiaYuanBlue.png",
    [34] = "UIAtlas2_Career_CareerIcon_XiaYuanZi.png",
    [35] = "UIAtlas2_Career_CareerIcon_ShiTuBlue.png",
    [36] = "UIAtlas2_Career_CareerIcon_ZhongShangBlue.png",
    [37] = "UIAtlas2_Career_CareerIcon_XYZW.png",
    [38] = "UIAtlas2_Career_CareerIcon_XYZi.png",
}

local tImgBack = {
    [0] = "UIAtlas2_Career_CareerReport_YinJiGold.png",
    [1] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [2] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [3] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [4] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [5] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [6] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [7] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [8] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [9] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [10] = "UIAtlas2_Career_CareerReport_YinJiGreen.png",
    [11] = "UIAtlas2_Career_CareerReport_YinJiGold.png",
    [12] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [13] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [14] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [15] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [16] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [17] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [18] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [19] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [20] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [21] = "UIAtlas2_Career_CareerReport_YinJiGreen.png",
    [22] = "UIAtlas2_Career_CareerReport_YinJiGold.png",
    [23] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [24] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [25] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [26] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [27] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [28] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [29] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [30] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [31] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [32] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [33] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [34] = "UIAtlas2_Career_CareerReport_YinJiPurple.png",
    [35] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [36] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
    [37] = "UIAtlas2_Career_CareerReport_YinJiGreen.png",
    [38] = "UIAtlas2_Career_CareerReport_YinJiBlue.png",
}

local tImgName = {
    [1] = "UIAtlas2_Career_CareerBigBg_ImgSealZL.png",
    [2] = "UIAtlas2_Career_CareerBigBg_ImgSealWG.png",
    [3] = "UIAtlas2_Career_CareerBigBg_ImgSealXX.png",
}

function UICareerOverview:OnEnter()
    self.player = GetClientPlayer()
    self:InitView()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UICareerOverview:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerOverview:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function ()
        self:UpdateLeft()
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function ()
        self:UpdateRight()
    end)

    UIHelper.BindUIEvent(self.BtnProspect, EventType.OnClick, function ()
        --UIMgr.Open(VIEW_ID.PanelOperationCenter, 130)
        UIMgr.Open(VIEW_ID.PanelSeasonLevel, 1)
    end)

end

function UICareerOverview:RegEvent()
    --
end

function UICareerOverview:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerOverview:InitView()
    self.nSelectedID = 1
    UIHelper.SetVisible(self.BtnLeft, false)
    UIHelper.SetVisible(self.BtnRight, true)

    UIHelper.SetVisible(self.tbImgPoint[1], true)
    UIHelper.SetVisible(self.tbImgPoint[2], false)
    UIHelper.SetVisible(self.tbImgPoint[3], false)

    for _, point in pairs(self.tbPoint) do
        UIHelper.SetVisible(point, true)
    end

    if self.player then
        local szOverView = FormatString(g_tStrings.STR_SEASON_SUMMART_TITLE, UIHelper.GBKToUTF8(self.player.szName))
        UIHelper.SetString(self.LabelMarkOverviewPlayer, szOverView)
    else
        local szOverView = FormatString(g_tStrings.STR_SEASON_SUMMART_TITLE, "")
        UIHelper.SetString(self.LabelMarkOverviewPlayer, szOverView)
    end

    UIHelper.SetString(self.LabelMarkOverviewTime, szTime)
    UIHelper.SetSpriteFrame(self.ImgTitle, szImgPath)

    UIHelper.SetString(self.LabelMarkOverviewTitle, szTitle[self.nSelectedID])
end

function UICareerOverview:UpdateLeft()
    UIHelper.SetVisible(self.tbImgPoint[self.nSelectedID], false)
    if self.nSelectedID == minSelectedID + 1 then
        UIHelper.SetVisible(self.BtnLeft, false)
    end
    if self.nSelectedID == maxSelectedID then
        UIHelper.SetVisible(self.BtnRight, true)
    end
    self.nSelectedID = self.nSelectedID - 1
    UIHelper.SetVisible(self.tbImgPoint[self.nSelectedID], true)
    UIHelper.SetString(self.LabelMarkOverviewTitle, szTitle[self.nSelectedID])
    self:UpdateInfo()
end

function UICareerOverview:UpdateRight()
    UIHelper.SetVisible(self.tbImgPoint[self.nSelectedID], false)
    if self.nSelectedID == maxSelectedID - 1 then
        UIHelper.SetVisible(self.BtnRight, false)
    end
    if self.nSelectedID == minSelectedID then
        UIHelper.SetVisible(self.BtnLeft, true)
    end
    self.nSelectedID = self.nSelectedID + 1
    UIHelper.SetVisible(self.tbPoint[self.nSelectedID], true)
    UIHelper.SetVisible(self.tbImgPoint[self.nSelectedID], true)
    UIHelper.SetString(self.LabelMarkOverviewTitle, szTitle[self.nSelectedID])
    self:UpdateInfo()
end

function UICareerOverview:UpdateData()
    CareerData.UpdateOverViewData()
    self.tInfo = CareerData.tOverViewInfo[self.nSelectedID]
end

function UICareerOverview:UpdateInfo()
    self:UpdateData()
    self:HideMark()

    UIHelper.SetSpriteFrame(self.ImgName, tImgName[self.nSelectedID])

    local maxLevel = 0
    local markId = 0
    local choosePos = 0
    local tArg = {}
    for _, v in pairs(self.tInfo) do
        local tMark = CareerData.GetOverViewInfo(v.dwID)
        if tMark then
            if tMark.nPos <= 7 then
                UIHelper.SetSpriteFrame(self.tbMarkImg[tMark.nPos], tImgPath[tMark.nFrame])
                UIHelper.SetVisible(self.tbMarkImg[tMark.nPos], true)
                UIHelper.SetString(self.tbMarkLabel[tMark.nPos], UIHelper.GBKToUTF8(tMark.szName))
                UIHelper.SetVisible(self.tbMarkLabel[tMark.nPos], true)
                UIHelper.SetVisible(self.tbMarkBack[tMark.nPos], true)

                UIHelper.SetVisible(self.tbMarkBtn[tMark.nPos], true)
                UIHelper.BindUIEvent(self.tbMarkBtn[tMark.nPos], EventType.OnClick, function ()
                    self:UpdateChooseType(tMark.nPos)
                    self:UpdateSummary(v.dwID, v.tArg)
                end)
            end
            if tMark.nLevel > maxLevel then
                markId = v.dwID
                tArg = v.tArg
                choosePos = tMark.nPos
                maxLevel = tMark.nLevel
            end
        end
    end

    local tMark = CareerData.GetOverViewInfo(markId)

    if tMark then
        UIHelper.SetSpriteFrame(self.ImgMark, tImgPath[tMark.nFrame])
        UIHelper.UpdateMask(self.Mask)
        UIHelper.SetSpriteFrame(self.ImgMarkOverviewTitleBg, tImgBack[tMark.nFrame])
        UIHelper.SetString(self.LabelMarkOverviewRight1, UIHelper.GBKToUTF8(tMark.szName))
        local szDesc = self:GenerateString(tMark.szDesc, tArg)
        UIHelper.SetRichText(self.LabelMarkInfo, UIHelper.GBKToUTF8(szDesc))

        UIHelper.SetVisible(self.ImgMark, true)
        UIHelper.SetVisible(self.LabelMarkInfo, true)
        UIHelper.SetVisible(self.ImgMarkOverviewTitleBg, true)
        UIHelper.SetVisible(self.LabelMarkOverviewRight1, true)
    else
        UIHelper.SetVisible(self.ImgMark, false)
        UIHelper.SetVisible(self.LabelMarkInfo, false)
        UIHelper.SetVisible(self.ImgMarkOverviewTitleBg, false)
        UIHelper.SetVisible(self.LabelMarkOverviewRight1, false)
    end

    self:UpdateChooseType(choosePos)
end

function UICareerOverview:GenerateString(szDesc, tArg)
    local Desc
    Desc = string.gsub(szDesc, '<text>text="', "");
    Desc = string.gsub(Desc, '".font=%d+.</text>', "");
    Desc = string.gsub(Desc, ' ', "");
    Desc = string.gsub(Desc, '"', "");

    if tArg == nil or #tArg == 0 then
        Desc = string.gsub(Desc, "|", "");
    else
        local t = {}
        local tszDesc = SplitString(Desc, "|")
        for i, v in ipairs(tArg) do
            if v ~= 0 then
                table.insert(t, tszDesc[i])
            end
        end
        Desc = table.concat(t, "")
        Desc  = FormatString(Desc, unpack(tArg))
    end

    return Desc
end

function UICareerOverview:HideMark()
    for _, img in pairs(self.tbMarkImg) do
        UIHelper.SetVisible(img, false)
    end

    for _, label in pairs(self.tbMarkLabel) do
        UIHelper.SetVisible(label, false)
    end

    for _, back in pairs(self.tbMarkBack) do
        UIHelper.SetVisible(back, false)
    end

    for _, btn in pairs(self.tbMarkBtn) do
        UIHelper.SetVisible(btn, false)
    end
end

function UICareerOverview:UpdateSummary(markId, Arg)
    local tMark = CareerData.GetOverViewInfo(markId)
    if tMark then
        UIHelper.SetSpriteFrame(self.ImgMark, tImgPath[tMark.nFrame])
        UIHelper.SetSpriteFrame(self.ImgMarkOverviewTitleBg, tImgBack[tMark.nFrame])
        UIHelper.SetString(self.LabelMarkOverviewRight1, UIHelper.GBKToUTF8(tMark.szName))
        local szDesc = self:GenerateString(tMark.szDesc, Arg)
        UIHelper.SetRichText(self.LabelMarkInfo, UIHelper.GBKToUTF8(szDesc))

        UIHelper.SetVisible(self.ImgMark, true)
        UIHelper.SetVisible(self.LabelMarkInfo, true)
        UIHelper.SetVisible(self.ImgMarkOverviewTitleBg, true)
        UIHelper.SetVisible(self.LabelMarkOverviewRight1, true)
    else
        UIHelper.SetVisible(self.ImgMark, false)
        UIHelper.SetVisible(self.LabelMarkInfo, false)
        UIHelper.SetVisible(self.ImgMarkOverviewTitleBg, false)
        UIHelper.SetVisible(self.LabelMarkOverviewRight1, false)
    end
end

function UICareerOverview:UpdateChooseType(nPos)
    if self.prePos then
        UIHelper.SetVisible(self.tbImgSelect[self.prePos] , false)
    end
    UIHelper.SetVisible(self.tbImgSelect[nPos] , true)
    self.prePos = nPos
end

return UICareerOverview