-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSeasonLevelTitle
-- Date: 2026-03-17 16:19:03
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbSeasonLevelBgList = {
    [CLASS_MODE.FB] =  "UIAtlas2_Collection_CollectionNewIcon_TitleBgMijing",
    [CLASS_TYPE.JJC] = "UIAtlas2_Collection_CollectionNewIcon_TitleBgJingji",
    [CLASS_TYPE.BATTLEFIELD] = "UIAtlas2_Collection_CollectionNewIcon_TitleBgJingji",
    [CLASS_TYPE.DESERTSTORM] = "UIAtlas2_Collection_CollectionNewIcon_TitleBgJingji",
    [CLASS_MODE.CAMP] = "UIAtlas2_Collection_CollectionNewIcon_TitleBgZhenying",
    [CLASS_TYPE.HOME] = "UIAtlas2_Collection_CollectionNewIcon_TitleBgJiayuan",
    [CLASS_TYPE.REST] = "UIAtlas2_Collection_CollectionNewIcon_TitleBgXiuxian",
}
local UIWidgetSeasonLevelTitle = class("UIWidgetSeasonLevelTitle")

function UIWidgetSeasonLevelTitle:OnEnter(nClass, tbSeasonLevelInfo, nTotalScores, bDay)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nClass = nClass
    self.bDay = bDay
    self:UpdateInfo(nClass, tbSeasonLevelInfo, nTotalScores)
    self:UpdateRedPoint()
end

function UIWidgetSeasonLevelTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSeasonLevelTitle:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelSeasonLevel, self.nClass)
    end)
end

function UIWidgetSeasonLevelTitle:RegEvent()
    Event.Reg(self, "CB_SA_TaskUpdate", function()
        self:UpdateRedPoint()
    end)
    
    Event.Reg(self, "CB_SA_SetPersonReward", function()
        self:UpdateRedPoint()
    end)
end

function UIWidgetSeasonLevelTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSeasonLevelTitle:UpdateInfo(nClass, tRankInfo, nTotalScores)
    if not tRankInfo then
        return
    end

    local nImageFrame = tRankInfo.nImageFrame
    local szImagePath = RANK_IMG[nImageFrame]
    local szTitle = g_tStrings.STR_RANK_TITLE_NAMA[nClass]
    local tbColorInfo = RANK_FONTCOLOR[nImageFrame]
    local nR, nG, nB = tbColorInfo[1], tbColorInfo[2], tbColorInfo[3]
    local szSfxPath = string.gsub(tRankInfo.szSFXPath, "/", "\\\\")
    local nRankPoint = tRankInfo.nRankPoint
    local szTotalScores = nTotalScores and tostring(nTotalScores).."分" or ""
    local bShowBg = nTotalScores ~= nil
    local szTips = string.format("%s %s", UIHelper.GBKToUTF8(tRankInfo.szRankName), szTotalScores)
    UIHelper.SetString(self.LabelSeasonLevelinfo, szTips)
    UIHelper.SetString(self.LabelSeasonLevelTypeName, szTitle)
    UIHelper.SetColor(self.LabelSeasonLevelinfo, cc.c3b(nR, nG, nB))
    UIHelper.SetColor(self.LabelSeasonLevelTypeName, cc.c3b(nR, nG, nB))
    UIHelper.SetVisible(self.ImgSeasonType, bShowBg)
    UIHelper.SetSpriteFrame(self.ImgSeasonLevelMark, szImagePath, false)
    for k, tbImg in ipairs(self.tbPointList) do
        UIHelper.SetVisible(tbImg, k <= nRankPoint)
    end

    if szSfxPath then
        UIHelper.SetSFXPath(self.SFX_Leve, szSfxPath)
        UIHelper.PlaySFX(self.SFX_Leve)
    end
    local szSeasonLevelBg = tbSeasonLevelBgList[nClass]
    UIHelper.SetSpriteFrame(self.ImgSeasonType, szSeasonLevelBg, false)
end

function UIWidgetSeasonLevelTitle:UpdateRedPoint()
    if self.bDay then
        return
    end
    local nClass = self.nClass
    local bShowRed = CollectionData.SeasonLevelHasCanGet(nClass)
    UIHelper.SetVisible(self.ImgRedPoint, bShowRed)
end

return UIWidgetSeasonLevelTitle