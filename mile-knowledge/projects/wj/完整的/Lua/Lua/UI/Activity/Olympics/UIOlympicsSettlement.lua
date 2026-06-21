-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIOlympicsSettlement
-- Date: 2024-08-21 17:24:33
-- Desc: PanelOlympics-WidgetAnchorRight 音游结算
-- ---------------------------------------------------------------------------------

local UIOlympicsSettlement = class("UIOlympicsSettlement")

local tEvaluateImg = {
    [1] = "Resource_UITga_Olympics3_白璧无瑕7_1.png",
    [2] = "Resource_UITga_Olympics2_(new)名动四方0_1.png",
    [3] = "Resource_UITga_Olympics2_(new)流风回雪2_1.png",
    [4] = "Resource_UITga_Olympics2_(new)轻云蔽月3_1.png",
    [5] = "Resource_UITga_Olympics2_(new)嬿婉回风4_1.png",
    [6] = "Resource_UITga_Olympics2_平平无奇5_1.png",
    [7] = "Resource_UITga_Olympics_(new)手足无惜6_1.png",
}

local DataModel

function UIOlympicsSettlement:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIOlympicsSettlement:OnExit()
    self.bInit = false
    self:UnRegEvent()

    Event.Dispatch(EventType.HideAllHoverTips)
end

function UIOlympicsSettlement:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnExit, EventType.OnClick, function()
        self.scriptView:Close()
    end)
    
end

function UIOlympicsSettlement:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.scriptIcon then
            self.scriptIcon:RawSetSelected(false)
            self.scriptIcon = nil
        end
    end)
end

function UIOlympicsSettlement:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIOlympicsSettlement:OnInit(scriptView, dataModel)
    DataModel = dataModel
    self.scriptView = scriptView
end

function UIOlympicsSettlement:UpdateSettlement(tPersonalRecord, tRankList, tItem)
    UIHelper.SetVisible(self.LayoutResult, true)
    UIHelper.SetVisible(self.LayoutTeam, false)

    self:UpdateSettlementTitle(DataModel.nEvaluate)

    UIHelper.SetString(self.LabelScore, "分数")
    UIHelper.SetString(self.LabelScoreNum, DataModel.nScore)
    UIHelper.SetVisible(self.ImgNew, DataModel.nScore >= tPersonalRecord.nRecord)
    UIHelper.LayoutDoLayout(self.LayoutScore)

    local fAcurracy = DataModel.nTotalNode > 0 and DataModel.nAccuracy / (DataModel.nTotalNode) or 0
    UIHelper.SetString(self.LabelAccuracy, "准确率")
    UIHelper.SetString(self.LabelAccuracyNum, string.format("%.2f%%", fAcurracy))

    UIHelper.SetString(self.LabelPerfectNum, DataModel.tRecord.Perfect)
    UIHelper.SetString(self.LabelExcellenceNum, DataModel.tRecord.Nice)
    UIHelper.SetString(self.LabelNormalNum, DataModel.tRecord.Good)
    UIHelper.SetString(self.LabelMissNum, DataModel.tRecord.Miss)
    UIHelper.SetString(self.LabelDoubleNum, DataModel.nMaxCombo)

    UIHelper.SetString(self.LabelBest, g_tStrings.FancySkatingEvalue[tPersonalRecord.nRating])
    UIHelper.SetString(self.LabelHistoryNum, tPersonalRecord.nRecord)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewInfo)

    self:UpdateSettlementReward(tItem)
end

function UIOlympicsSettlement:UpdateSettlementPair(tPersonalRecord, tItem, tOtherData)
    UIHelper.SetVisible(self.LayoutResult, false)
    UIHelper.SetVisible(self.LayoutTeam, true)

    self:UpdateSettlementTitle(tOtherData.nEvaluate)

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    UIHelper.SetString(self.LabelPlayerName1, UIHelper.GBKToUTF8(hPlayer.szName))
    UIHelper.SetString(self.LabelPlayerName2, UIHelper.GBKToUTF8(tOtherData.szName))

    UIHelper.SetString(self.LabelScore, "队伍得分")
    UIHelper.SetString(self.LabelScore1, DataModel.nScore)
    UIHelper.SetString(self.LabelScore2, tOtherData.nScore)
    UIHelper.SetString(self.LabelScoreNum, DataModel.nScore + tOtherData.nScore)
    UIHelper.SetVisible(self.ImgNew, DataModel.nScore + tOtherData.nScore >= tPersonalRecord.nRecord)
    UIHelper.LayoutDoLayout(self.LayoutScore)

    local fAcurracy = DataModel.nTotalNode > 0 and DataModel.nAccuracy / (DataModel.nTotalNode) or 0
    UIHelper.SetString(self.LabelAccuracy, "队伍准确率")
    UIHelper.SetString(self.LabelAccuracy1, string.format("%.2f%%", fAcurracy))
    UIHelper.SetString(self.LabelAccuracy2, string.format("%.2f%%", tOtherData.fAccuracy * 100))
    UIHelper.SetString(self.LabelAccuracyNum, string.format("%.2f%%", (tOtherData.fAccuracy * 100 + fAcurracy) / 2))

    UIHelper.SetString(self.LabelPerfect_Player1, DataModel.tRecord.Perfect)
    UIHelper.SetString(self.LabelPerfect_Player2, tOtherData.nPerfect)
    UIHelper.SetString(self.LabelExcellence_Player1, DataModel.tRecord.Nice)
    UIHelper.SetString(self.LabelExcellence_Player2, tOtherData.nNice)
    UIHelper.SetString(self.LabelNormal_Player1, DataModel.tRecord.Good)
    UIHelper.SetString(self.LabelNormal_Player2, tOtherData.nGood)
    UIHelper.SetString(self.LabelMiss_Player1, DataModel.tRecord.Miss)
    UIHelper.SetString(self.LabelMiss_Player2, tOtherData.nMiss)
    UIHelper.SetString(self.LabelDouble_Player1, DataModel.nMaxCombo)
    UIHelper.SetString(self.LabelDouble_Player2, tOtherData.nCombo)

    UIHelper.SetString(self.LabelBest, g_tStrings.FancySkatingEvalue[tPersonalRecord.nRating])
    UIHelper.SetString(self.LabelHistoryNum, tPersonalRecord.nRecord)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewInfo)

    self:UpdateSettlementReward(tItem)
end

function UIOlympicsSettlement:UpdateSettlementTitle(nEvaluate)
    UIHelper.SetString(self.LabelMusicName, UIHelper.GBKToUTF8(DataModel.tMusicInfo.szMusicName))
    for i = 1, #self.tImgStarlevel do
        UIHelper.SetVisible(self.tImgStarlevel[i], i <= DataModel.tMusicInfo.nDifficulty)
    end
    UIHelper.LayoutDoLayout(self.LayoutStarlevel)
    UIHelper.SetSpriteFrame(self.ImgAchievement, tEvaluateImg[nEvaluate])
    -- UIHelper.PlaySFX(self.Eff_Continuous)
end

function UIOlympicsSettlement:UpdateSettlementReward(tItem)
    UIHelper.RemoveAllChildren(self.ScrollViewDetailsList)
    UIHelper.SetVisible(self.WidgetReward, #tItem > 0)
    for _, v in ipairs(tItem) do
        local dwTabType = v[1]
        local dwIndex = v[2]
        local nCount = v[3]
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewDetailsList)
        UIHelper.SetAnchorPoint(itemScript._rootNode, 0, 0)
        itemScript:OnInitWithTabID(dwTabType, dwIndex)
        itemScript:SetLabelCount(nCount)
        itemScript:SetSelectChangeCallback(function(nItemID, bSelected, nTabType, nTabID)
            if bSelected then
                local tips, scriptTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.WidgetRewardTip1, TipsLayoutDir.LEFT_CENTER)
                scriptTip:OnInitWithTabID(dwTabType, dwIndex)
                self.scriptIcon = itemScript
            else
                self.scriptIcon = nil
            end
        end)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewDetailsList)
    UIHelper.ScrollToLeft(self.ScrollViewDetailsList, 0)
end

return UIOlympicsSettlement