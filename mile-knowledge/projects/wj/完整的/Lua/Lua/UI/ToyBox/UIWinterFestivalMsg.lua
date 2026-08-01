-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWinterFestivalMsg
-- Date: 2024-04-17 10:06:51
-- Desc: ?
-- ---------------------------------------------------------------------------------
local szNpcHeadPath = "UIAtlas2_ToyPuzzle_ToyDongzhi_" -- .. nFrame

local UIWinterFestivalMsg = class("UIWinterFestivalMsg")
local nStartFadedTime = 2
local nFadedDuration = 1

function UIWinterFestivalMsg:OnEnter(dwID)
	self.dwID = dwID
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIWinterFestivalMsg:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWinterFestivalMsg:BindUIEvent()
	
end

function UIWinterFestivalMsg:RegEvent()
	Event.Reg(self, EventType.OnShieldTip, function(szEvent, tbData)
        local bClose = tbData.bClose
        if bClose then
            -- self[string.format("Close", ...)]()--关闭
        else
            local func = self[string.format("Update%sVis", szEvent)]
            if func then func(self) end
        end
    end)

    Event.Reg(self, EventType.OnUnShieldTip, function(szEvent, bClose)
        if not bClose then
            local func = self[string.format("Update%sVis", szEvent)]
            if func then func(self) end
        end
    end)
end

function UIWinterFestivalMsg:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWinterFestivalMsg:UpdateInfo()
	local tInfo = Table_GetSkillMsgInfo(self.dwID)
	if tInfo then
		UIHelper.SetString(self.LabelTaskTitle, UIHelper.GBKToUTF8(tInfo.szText))
		UIHelper.SetSpriteFrame(self.ImgNpcHead, szNpcHeadPath .. tInfo.nFrame)

		self.bShowHint = true
		self:UpdateShowHintVis()

		self:StartAutoClose()
	end
end

function UIWinterFestivalMsg:UpdateShowHintVis()
	local bVis = not TipsHelper.IsTipShield(EventType.ShowWinterFestivalTip) and self.bShowHint
    UIHelper.SetVisible(self._rootNode, bVis)
end

function UIWinterFestivalMsg:StartAutoClose()
	self:StopAutoClose()

    UIHelper.FadeNode(self._rootNode, 255, 0)
    self.nAutoClose = Timer.Add(self, nStartFadedTime, function()
        UIHelper.FadeNode(self._rootNode, 0, nFadedDuration, function()
            self:HideHint()
        end)
        self.nAutoClose = nil
    end)
end

function UIWinterFestivalMsg:HideHint()
	self.bShowHint = false
    self:UpdateShowHintVis()
    self:StopAutoClose()
end

function UIWinterFestivalMsg:StopAutoClose()
	if self.nAutoClose then
        Timer.DelTimer(self, self.nAutoClose)
        self.nAutoClose = nil
    end
    UIHelper.StopAllActions(self._rootNode)
end

return UIWinterFestivalMsg