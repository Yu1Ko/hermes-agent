-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetYangDaoLevelIconCell
-- Date: 2026-03-02 10:56:37
-- Desc: 扬刀大会-挑战进度分页-全景地图 按钮 WidgetYangDaoLevelIconCell (PanelYangDaoOverview/WidgetPageProgress)
-- ---------------------------------------------------------------------------------

local UIWidgetYangDaoLevelIconCell = class("UIWidgetYangDaoLevelIconCell")

local tImgBgPath = {
    [ArenaTowerDiffMode.Practice] = "UIAtlas2_YangDao_YangDaoPanel01_Img_OverView_Bg_Practice.png",
    [ArenaTowerDiffMode.Challenge] = "UIAtlas2_YangDao_YangDaoPanel01_Img_OverView_Bg_Challenge.png",
}

local szDefaultImgNumBgPath = "UIAtlas2_YangDao_YangDaoPanel01_Img_OverView_BgNum_NotFighted.png"
local tImgNumBgPath = {
    [ArenaTowerDiffMode.Practice] = "UIAtlas2_YangDao_YangDaoPanel01_Img_OverView_BgNum_Pracitce.png",
    [ArenaTowerDiffMode.Challenge] = "UIAtlas2_YangDao_YangDaoPanel01_Img_OverView_BgNum_Challenge.png",
}

function UIWidgetYangDaoLevelIconCell:OnEnter(nLevelIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nLevelIndex = nLevelIndex
    self:UpdateInfo()
end

function UIWidgetYangDaoLevelIconCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetYangDaoLevelIconCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAll, EventType.OnClick, function()
        if self.fnCallback then
            self.fnCallback()
        end
    end)
end

function UIWidgetYangDaoLevelIconCell:RegEvent()
    Event.Reg(self, EventType.OnArenaTowerOverviewMapScale, function(nScale)
        self:UpdateMapScale(nScale)
    end)
end

function UIWidgetYangDaoLevelIconCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetYangDaoLevelIconCell:UpdateInfo()
    local tLevelConfig = ArenaTowerData.GetLevelConfig(self.nLevelIndex)
    if not tLevelConfig then
        return
    end

    UIHelper.SetVisible(self.WidgetNum, self.nLevelIndex > 0)
    UIHelper.SetString(self.LabelNum, self.nLevelIndex)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tLevelConfig.szName))
    UIHelper.SetSpriteFrame(self.ImgIcon, tLevelConfig.szVKImage)
    UIHelper.LayoutDoLayout(self.LayoutContent)
end

function UIWidgetYangDaoLevelIconCell:SetCurrent(bCurrent)
    UIHelper.SetVisible(self.ImgIconCurrent, bCurrent)
end

function UIWidgetYangDaoLevelIconCell:SetUnlock(bUnlock)
    UIHelper.SetVisible(self.ImgIconLocked, not bUnlock)
end

function UIWidgetYangDaoLevelIconCell:SetSpecial(bSpecial)
    UIHelper.SetVisible(self.ImgSpecialIcon, bSpecial)
end

function UIWidgetYangDaoLevelIconCell:SetProgressState(nDiffMode, bClearLevel, bCurrentLevel)
    nDiffMode = nDiffMode or ArenaTowerDiffMode.Practice
    local szImgBgPath = tImgBgPath[nDiffMode]
    local szImgNumBgPath = (bClearLevel or bCurrentLevel) and tImgNumBgPath[nDiffMode] or szDefaultImgNumBgPath

    UIHelper.SetSpriteFrame(self.ImgBgFinished, szImgBgPath)
    UIHelper.SetSpriteFrame(self.ImgNumBg, szImgNumBgPath)
    UIHelper.SetVisible(self.WidgetBgUnfinished, not bClearLevel and not bCurrentLevel)
    UIHelper.SetVisible(self.WidgetBgFinished, bClearLevel or bCurrentLevel)
    UIHelper.SetVisible(self.ImgCheck, bClearLevel)
end

-- ArenaTowerLevelState
function UIWidgetYangDaoLevelIconCell:SetLevelState(nLevelState)
    if not nLevelState then
        -- 驿站
        UIHelper.SetVisible(self.ImgCheck, false)
        UIHelper.SetVisible(self.ImgIconLocked, false)
        UIHelper.SetVisible(self.WidgetRewardIcon, false)
        UIHelper.SetVisible(self.LayoutRewardIcon, false)
        -- UIHelper.SetVisible(self.WidgetBgUnfinished, true)
        -- UIHelper.SetVisible(self.WidgetBgFinished, false)
    elseif nLevelState == ArenaTowerLevelState.Incomplete then
        UIHelper.SetVisible(self.ImgIconLocked, true)
        UIHelper.SetVisible(self.WidgetRewardIcon, false)
        UIHelper.SetVisible(self.LayoutRewardIcon, true)
        -- UIHelper.SetVisible(self.WidgetBgUnfinished, true)
        -- UIHelper.SetVisible(self.WidgetBgFinished, false)
    else
        UIHelper.SetVisible(self.ImgIconLocked, false)
        UIHelper.SetVisible(self.WidgetRewardIcon, true)
        UIHelper.SetVisible(self.LayoutRewardIcon, true)
        -- UIHelper.SetVisible(self.WidgetBgUnfinished, nLevelState == ArenaTowerLevelState.PracticeCompleted)
        -- UIHelper.SetVisible(self.WidgetBgFinished, nLevelState == ArenaTowerLevelState.ChallengeCompleted)

        local szPracticeIconPath, szChallengeIconPath = ArenaTowerData.GetDiffIcon(nLevelState)
        UIHelper.SetSpriteFrame(self.ImgIconPractice, szPracticeIconPath)
        UIHelper.SetSpriteFrame(self.ImgIconChallenge, szChallengeIconPath)
    end

    if UIHelper.GetVisible(self.ImgCheck) then
        UIHelper.SetVisible(self.ImgIconLocked, false)
    end
end

function UIWidgetYangDaoLevelIconCell:UpdateMapScale(nScale)
    UIHelper.SetScale(self._rootNode, 1 / nScale, 1 / nScale)
end

function UIWidgetYangDaoLevelIconCell:SetClickCallback(fnCallback)
    self.fnCallback = fnCallback
end

return UIWidgetYangDaoLevelIconCell