-- ---------------------------------------------------------------------------------
-- Author: Liu yu min
-- Name: CrossingLevelCell
-- Date: 2023-03-15 19:18:50
-- Desc:
-- ---------------------------------------------------------------------------------

local CrossingLevelCell = class("CrossingLevelCell")

local tImageTestPlace = 
{
    "UIAtlas2_TestPlace_TestPlace_Img_Normal_001.png",
    "UIAtlas2_TestPlace_TestPlace_Img_Normal_002.png",
    "UIAtlas2_TestPlace_TestPlace_Img_Normal_003.png",
    "UIAtlas2_TestPlace_TestPlace_Img_Normal_004.png",
    "UIAtlas2_TestPlace_TestPlace_Img_Normal_005.png",
}

local tImageSiShiLunWu = 
{
    "UIAtlas2_TestPlace_TestPlace_Img_Normal.png",
    "UIAtlas2_TestPlace_TestPlace_Img_Normal_1.png",
}

function CrossingLevelCell:OnEnter(cellIndex, nLevel, tbLevelInfo , bVisible , nType)
    self.tbLevelInfo = tbLevelInfo
    self.cellIndex = cellIndex
    self.nLevel = nLevel
    self.bVisible = bVisible
    self.nType = nType
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function CrossingLevelCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function CrossingLevelCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTestPlaceCell, EventType.OnClick, function()
        if CrossingData.nState == CrossingStateType.SiShiLunWu then
            if not self.bVisible then
                TipsHelper.ShowNormalTip("暂未开启")
                return
            end
        end
        Timer.AddFrame(self, 1, function()
            UIMgr.Open(VIEW_ID.PanelTestPlaceInfoPop,self.nLevel , self.tbLevelInfo)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function()
        if self.nGift ~= 2 then
            RemoteCallToServer("On_Trial_Get5StarGift", self.nLevel)
            self.nGift = 2
            UIHelper.SetVisible(self.ImgRewardOver , true)
            UIHelper.SetVisible(self.ImgReward , false)
        end
    end)
end

function CrossingLevelCell:RegEvent()

end

function CrossingLevelCell:UnRegEvent()
   
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓�?
-- ----------------------------------------------------------

function CrossingLevelCell:UpdateInfo()
    UIHelper.SetVisible(self.BtnReward , false)
    UIHelper.SetVisible(self.LayoutRank,CrossingData.nState == CrossingStateType.TestPlace)
    UIHelper.SetVisible(self.LayoutRankBg,CrossingData.nState == CrossingStateType.TestPlace)
    UIHelper.SetVisible(self.ImgRankBg,CrossingData.nState == CrossingStateType.TestPlace)
    if CrossingData.nState == CrossingStateType.TestPlace then
        UIHelper.SetSpriteFrame(self.ImgTestPlaceCellBg, tImageTestPlace[(self.cellIndex-1)%5+1])
        UIHelper.SetVisible(self.LayoutRank,true)
        UIHelper.SetString(self.LabelTestPlaceCell, string.format("第%s层",UIHelper.NumberToChinese(self.nLevel)) )
        self.nStar = 0
        self.nGift = 0
        if self.tbLevelInfo[self.nLevel] then 
            self.nStar = self.tbLevelInfo[self.nLevel].nStar
            self.nGift = self.tbLevelInfo[self.nLevel].nGift
        end

        if self.nGift ~= 0 then 
            --UIHelper.SetVisible(self.BtnReward , true)
            UIHelper.SetVisible(self.ImgRewardOver , self.nGift == 2)
            UIHelper.SetVisible(self.ImgReward , self.nGift ~= 2)
        end

        for key, value in pairs(self.tbCellDifficultRank) do
            UIHelper.SetVisible(value, key <= self.nStar)
        end
        UIHelper.LayoutDoLayout(self.LayoutRank) --刷新
        UIHelper.SetActiveAndCache(self ,self._rootNode, self.nLevel <= self.tbLevelInfo.nTopLevel)
    elseif CrossingData.nState == CrossingStateType.SiShiLunWu then
        --四时论武
        UIHelper.SetSpriteFrame(self.ImgTestPlaceCellBg, tImageSiShiLunWu[self.nType])
        UIHelper.SetString(self.LabelTestPlaceCell,string.format("第%s层",  UIHelper.NumberToChinese(self.cellIndex)))
        UIHelper.SetVisible(self.LayoutRank,false)
        UIHelper.SetVisible(self.LabelTestPlaceChallenge,false)
        UIHelper.SetVisible(self.ImgTestPlaceChallenge, false)
    end
    local posY = CrossingData.WidgetTestPlaceCellPosionY
    if self.cellIndex % 2 == 0 then
        posY = posY + CrossingData.CellSpacingAddPosionY
    end
    UIHelper.SetPositionY(self.WidgetTestPlaceCellPosion , posY)
    self:ChangeCellState()
end

function CrossingLevelCell:ChangeCellState()
    if CrossingData.nState == CrossingStateType.TestPlace then
        if self.tbLevelInfo.nCurrentLevel == self.nLevel then
            UIHelper.SetVisible(self.ImgTestPlaceChallenge, true)
            UIHelper.SetVisible(self.LabelTestPlaceChallenge, true)
            
            UIHelper.SetString(self.LabelTestPlaceChallenge, string.format("%d/%d", self.tbLevelInfo.tCurrentLevelData.nCurrentMission, self.tbLevelInfo.tCurrentLevelData.nMaxCurrentMission))
        else
            UIHelper.SetVisible(self.ImgTestPlaceChallenge, false)
        end
    elseif CrossingData.nState == CrossingStateType.SiShiLunWu then
        UIHelper.SetVisible(self.ImgTestPlaceChallenge, self.tbLevelInfo.nCurrentLevel == self.nLevel)
        UIHelper.SetString(self.LabelTestPlaceChallenge, "")
        UIHelper.SetVisible(self.ImgTestLock , not self.bVisible)
    end
end

return CrossingLevelCell
