-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeAchievementCell
-- Date: 2023-07-19 20:00:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeAchievementCell = class("UIHomeAchievementCell")

function UIHomeAchievementCell:OnEnter(nIndex, nCollected, nMaxCollect, bShowInterim, bCollected, bAward, szMoneyNum)
    self.nIndex = nIndex
    self.nCollected = nCollected
    self.nMaxCollect = nMaxCollect
    self.bShowInterim = bShowInterim
    self.bCollected = bCollected
    self.bAward = bAward
    self.szMoneyNum = szMoneyNum
    UIHelper.SetVisible(self.ImgToGetAward, false)
    UIHelper.SetTouchDownHideTips(self.BtnHomeAchievement, false)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomeAchievementCell:OnExit()
    self.bInit = false
end

function UIHomeAchievementCell:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function()
        if self.nCollected < self.nMaxCollect then
            UIMgr.Open(VIEW_ID.PanelHomeAchievementCountInputPop, self.nIndex, self.szMoneyNum,self.nCollected, self.nMaxCollect)
        else
            OutputMessage("MSG_SYS", g_tStrings.STR_SEASON_FURNITURE_SUIT_COLLECT_FULL)
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SEASON_FURNITURE_SUIT_COLLECT_FULL)
            return
        end
    end)

    UIHelper.BindUIEvent(self.BtnHomeAchievement, EventType.OnClick, function()
        if self.bAward then
            Event.Dispatch(EventType.OnHomeAchievementToAward, self.nIndex)
        else
            if UIMgr.GetView(VIEW_ID.PanelHomeAchievementRightPop) then
                Event.Dispatch(EventType.OnHomeAchievementRightPopOpen, self.nIndex, self.nCollected, self.nMaxCollect)
            else
                UIMgr.Open(VIEW_ID.PanelHomeAchievementRightPop, self.nIndex, self.nCollected, self.nMaxCollect)
            end
        end
    end)

    UIHelper.SetSwallowTouches(self.BtnHomeAchievement, false)
end

function UIHomeAchievementCell:RegEvent()

end

function UIHomeAchievementCell:UpdateInfo()
    local cc_spriteFrameCache = cc.SpriteFrameCache:getInstance()
    local tbFrames = cc_spriteFrameCache:addSpriteFramesWithJson("Resource/JYPlay/SeasonFurniture.json")

    local szLabelNum = self.nCollected .. "/" .. self.nMaxCollect
    if self.nCollected >= self.nMaxCollect then
        szLabelNum = self.nMaxCollect .. "/" .. self.nMaxCollect
    end
    local nCollecterProgress = self.nCollected / self.nMaxCollect * 100
    local szImgHomeFrame = HomeLandAchievementCellCenterImg[self.nIndex]
    local szImgHomeIcon = HomeLandAchievementCellUnderIconImg[self.nIndex]

    -- UIHelper.SetNodeGray(self.BtnHomeAchievement, false, true)

    -- if not self.bAward and not self.bCollected then
        -- UIHelper.SetNodeGray(self.BtnHomeAchievement, true, true)
    -- end
    UIHelper.SetVisible(self.ImgToGetAward, self.bCollected or self.bAward)
    UIHelper.SetVisible(self.ImgGain, self.bCollected)
    UIHelper.SetVisible(self.ImgTime, self.bShowInterim)
    UIHelper.SetSpriteFrame(self.ImgHome, szImgHomeFrame)
    UIHelper.SetSpriteFrame(self.ImgHomeAchievementIcon, szImgHomeIcon)
    UIHelper.SetSpriteFrame(self.ImgTitle, HomeLandAchievementCellTitleImg[self.nIndex])
    UIHelper.SetProgressBarPercent(self.ProgressBarHomeAchievement, nCollecterProgress)
    UIHelper.SetString(self.LabelNum, szLabelNum)
end


return UIHomeAchievementCell