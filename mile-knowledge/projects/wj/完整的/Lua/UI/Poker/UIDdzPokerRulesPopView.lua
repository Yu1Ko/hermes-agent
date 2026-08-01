-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerRulesPopView
-- Date: 2023-08-14 17:15:40
-- Desc: 调整规则界面
-- ---------------------------------------------------------------------------------

local UIDdzPokerRulesPopView = class("UIDdzPokerRulesPopView")
local DEFAULT_POS = 1
function UIDdzPokerRulesPopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIDdzPokerRulesPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerRulesPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOK , EventType.OnClick , function ()
		local szRuleNum = ""
		for k, v in pairs(self.tbTogDifen) do
            if UIHelper.GetSelected(v) then
                szRuleNum = szRuleNum .. k
            end
        end
    
        for k, v in pairs(self.tbTogWanfa) do
            if UIHelper.GetSelected(v) then
                szRuleNum = szRuleNum .. k
            end
        end
    
        for k, v in pairs(self.tbTogXiPai) do
            if UIHelper.GetSelected(v) then
                szRuleNum = szRuleNum .. k
            end
        end
		self:SetRule(tonumber(szRuleNum))
		UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)
    
end

function UIDdzPokerRulesPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerRulesPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDdzPokerRulesPopView:UpdateInfo()
    for k, v in pairs(self.tbTogDifen) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup_Difen, v)
    end

    for k, v in pairs(self.tbTogWanfa) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup_Wanfa, v)
    end

    for k, v in pairs(self.tbTogXiPai) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup_XiPai, v)
    end
    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup_Difen, self.tbTogDifen[DdzPokerData.DataModel.tRule.nDiFen])
    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup_Wanfa, self.tbTogWanfa[DdzPokerData.DataModel.tRule.nWanFa])
    UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup_XiPai, self.tbTogXiPai[DdzPokerData.DataModel.tRule.nXiPai])
end

function UIDdzPokerRulesPopView:SetRule(nRuleNum)
	GetHomelandMgr().CallEightDwordScript(DdzPokerData.DataModel.nFurnitureID, DEFAULT_POS, 0, 
		self:GetDecimalPosNum(nRuleNum, 3), self:GetDecimalPosNum(nRuleNum, 2), self:GetDecimalPosNum(nRuleNum, 1), 
		0, 0, 0, 0)
end

function UIDdzPokerRulesPopView:GetDecimalPosNum(nNum, nPos)
	nNum = math.floor(nNum)
	local nRetNum = math.floor(nNum / math.pow(10, nPos - 1))
	nRetNum = nRetNum % 10
	return nRetNum
end

return UIDdzPokerRulesPopView