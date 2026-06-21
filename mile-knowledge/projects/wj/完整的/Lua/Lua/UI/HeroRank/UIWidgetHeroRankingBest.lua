-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHeroRankingBest
-- Date: 2024-09-19 15:38:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetHeroRankingBest = class("UIWidgetHeroRankingBest")

function UIWidgetHeroRankingBest:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetHeroRankingBest:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHeroRankingBest:BindUIEvent()
    
end

function UIWidgetHeroRankingBest:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetHeroRankingBest:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetHeroRankingBest:UpdateInfo(nCellIndex, aNpcInfoList, nNpcIndex)
    if not aNpcInfoList then return end
    local LabelName = self["LabelName"..tostring(nCellIndex)]
    local WidgetLineWin = self["WidgetLineWin"..tostring(nCellIndex)]
    local WidgetLose = self["WidgetLose"..tostring(nCellIndex)]
    local WidgetWin = self["WidgetWin"..tostring(nCellIndex)]
    local ImgLineLose = self["ImgLineLose"..tostring(nCellIndex)]
    local WidgetNormal = self["WidgetNormal"..tostring(nCellIndex)]

    local dwNpcID, eState
	if #aNpcInfoList > 0 and nNpcIndex then
		dwNpcID, eState = aNpcInfoList[1][nNpcIndex], aNpcInfoList[2][nNpcIndex]
	else
		dwNpcID, eState = 0, HeroRankData.tNPC_CONTEST_STATE.UNKNOWN
	end

    if not self.tbNpcID then self.tbNpcID = {} end
    self.tbNpcID[nCellIndex] = dwNpcID
    local szName = UIHelper.GBKToUTF8(Table_GetWulinShenghuiDuizhenNpcInfo(dwNpcID).szName)
    UIHelper.SetString(LabelName, szName)

    if WidgetLose then  
        UIHelper.SetVisible(WidgetLose, eState == HeroRankData.tNPC_CONTEST_STATE.LOST)
    end
    if ImgLineLose then
        UIHelper.SetVisible(ImgLineLose, eState == HeroRankData.tNPC_CONTEST_STATE.LOST)
    end
    if WidgetLineWin then
        UIHelper.SetVisible(WidgetLineWin, eState == HeroRankData.tNPC_CONTEST_STATE.WON)
    end
    UIHelper.SetVisible(WidgetWin, eState == HeroRankData.tNPC_CONTEST_STATE.WON)
    UIHelper.SetVisible(WidgetNormal, true)
end

function UIWidgetHeroRankingBest:UpdateEmpty()
    for nCellIndex = 1, 2 do
        if not self.tbNpcID or not self.tbNpcID[nCellIndex] then
            local WidgetNormal = self["WidgetNormal"..tostring(nCellIndex)]
            local LabelName = self["LabelName"..tostring(nCellIndex)]
            local WidgetLineWin = self["WidgetLineWin"..tostring(nCellIndex)]
            local WidgetLose = self["WidgetLose"..tostring(nCellIndex)]
            local WidgetWin = self["WidgetWin"..tostring(nCellIndex)]
            local ImgLineLose = self["ImgLineLose"..tostring(nCellIndex)]
            UIHelper.SetString(LabelName, "")
            if ImgLineLose then 
                UIHelper.SetVisible(WidgetLose, false)
            end
            if ImgLineLose then 
                UIHelper.SetVisible(ImgLineLose, false)
            end
            if WidgetLineWin then
                UIHelper.SetVisible(WidgetLineWin, false)
            end
            UIHelper.SetVisible(WidgetWin, false)
            UIHelper.SetVisible(WidgetNormal, true)
        end
    end
end

return UIWidgetHeroRankingBest