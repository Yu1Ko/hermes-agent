-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandCommunityTipsCell
-- Date: 2023-04-03 17:14:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandCommunityTipsCell = class("UIHomelandCommunityTipsCell")

function UIHomelandCommunityTipsCell:OnEnter(szName, nMapID, funcCallback)
    self.szName = szName
    self.nMapID = nMapID
    self.funcCallback = funcCallback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandCommunityTipsCell:OnExit()
    self.bInit = false
end

function UIHomelandCommunityTipsCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCutMap, EventType.OnClick, function ()
        if self.funcCallback then
            self.funcCallback()
            Event.Dispatch(EventType.HideAllHoverTips)
        end
    end)
end

function UIHomelandCommunityTipsCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandCommunityTipsCell:UpdateInfo()
    UIHelper.SetString(self.LabelNormal, self.szName)
    UIHelper.SetString(self.LabelSelect, self.szName)
    UIHelper.SetTouchDownHideTips(self.TogCutMap, false)
    UIHelper.SetVisible(self.ImgNewIcon, self.nMapID and HomelandData.IsNewCommunityMap(self.nMapID))
end

function UIHomelandCommunityTipsCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogCutMap, bSelected)
end


return UIHomelandCommunityTipsCell