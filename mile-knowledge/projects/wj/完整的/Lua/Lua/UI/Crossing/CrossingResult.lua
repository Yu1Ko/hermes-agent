-- ---------------------------------------------------------------------------------
-- Author: Liu yu min
-- Name: CrossingResult
-- Date: 2023-03-21 17:29:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local CrossingResult = class("CrossingResult")

function CrossingResult:OnEnter(tData, nXiuWei, bVisible)
  --  if not nState then return end
  --  self.nState = nState
    self.nXiuWei = nXiuWei
    self.tbInfo = tData
    self.bVisible = bVisible
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function CrossingResult:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function CrossingResult:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnEsc, EventType.OnClick, function()
        RemoteCallToServer("On_Trial_QuitBattle")
        self:CloseAll()
    end)

    UIHelper.BindUIEvent(self.BtnReStart, EventType.OnClick, function()
        RemoteCallToServer("On_Trial_ReStartLevel", self.nCurrentLevel)
        self:CloseAll()
    end)

    UIHelper.BindUIEvent(self.BtnContinue, EventType.OnClick, function()
        if CrossingData.nState == CrossingStateType.TestPlace then
            RemoteCallToServer("On_Trial_Continue")
            self:CloseAll()
        end
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        
        -- if UIMgr.GetView(VIEW_ID.PanelTestPlaceRewardSelect) then
        --     UIMgr.Close(VIEW_ID.PanelTestPlaceRewardSelect) 
        -- end
        -- UIMgr.Open(VIEW_ID.PanelTestPlaceRewardSelect)
        UIMgr.Close(self)
    end)
end

function CrossingResult:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function CrossingResult:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function CrossingResult:UpdateInfo()
    if CrossingData.nState == CrossingStateType.TestPlace then
        UIHelper.SetString(self.LabelRewardTitle,"额外奖励")
        self.nCurrentLevel = self.tbInfo.nLevel
        UIHelper.SetString(self.LabelTitleCount , string.format("第%s层",UIHelper.NumberToChinese(self.nCurrentLevel)) )
        self:UpdateStar(self.tbInfo.nStar)
        UIHelper.SetString(self.LabelProgressScore , self.tbInfo.nCurrentPoint)
        UIHelper.SetString(self.LabelHistoryScore , self.tbInfo.nHistoryPoint)
        UIHelper.SetActiveAndCache(self , self.ImgRecodeNew , self.tbInfo.nCurrentPoint >= self.tbInfo.nHistoryPoint )
    
        for k, v in pairs(self.ScoreInfoList) do
            UIHelper.SetString(v , self.tbInfo.tMissionPoint[k])
        end
    
        local awardItemLua = UIHelper.GetBindScript(self.WidgetAwardItem1)
        awardItemLua:SetCurrency(CurrencyType.Train , self.nXiuWei or 0)
    
        UIHelper.SetActiveAndCache(self , self.BtnReStart , not self.bVisible)
        UIHelper.SetActiveAndCache(self , self.BtnContinue , not self.bVisible)
        UIHelper.LayoutDoLayout(self.LayoutButton)
    end
end

function CrossingResult:UpdateStar(nStarCount)
    if nStarCount > 5 then
		nStarCount = 5
	elseif nStarCount < 0 then
		nStarCount = 0
	end
    for i, v in ipairs(self.tbStar) do
        UIHelper.SetActiveAndCache(self , v , i <= nStarCount)
    end
end

function CrossingResult:CloseAll()
    if UIMgr.GetView(VIEW_ID.PanelTestPlaceRewardSelect) then
        UIMgr.Close(VIEW_ID.PanelTestPlaceRewardSelect) 
    end
    UIMgr.Close(self)
end

return CrossingResult