-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIArenaMasterNoteView
-- Date: 2025-02-25 10:01:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIArenaMasterNoteView = class("UIArenaMasterNoteView")

local szTitle = "第一届竞技群英赛"

function UIArenaMasterNoteView:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbInfo = tbInfo or {}
    self:UpdateInfo()
end

function UIArenaMasterNoteView:OnExit()
    self.bInit = false
end

function UIArenaMasterNoteView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

end

function UIArenaMasterNoteView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIArenaMasterNoteView:UpdateInfo()
    local nRank = self.tbInfo.nRank
    local szTeamName = self.tbInfo.szTeamName

    if nRank then
        UIHelper.SetVisible(self.WidgetLabelNormal, false)
        UIHelper.SetVisible(self.WidgetLabelTop64, true)
        UIHelper.SetString(self.Label2_64, string.format("%d强", nRank))
    else
        UIHelper.SetVisible(self.WidgetLabelNormal, true)
        UIHelper.SetVisible(self.WidgetLabelTop64, false)
    end

    UIHelper.SetString(self.Label2, szTitle)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(PlayerData.GetPlayerName()))
    UIHelper.LayoutDoLayout(self.LayoutPlayerName)

end


return UIArenaMasterNoteView