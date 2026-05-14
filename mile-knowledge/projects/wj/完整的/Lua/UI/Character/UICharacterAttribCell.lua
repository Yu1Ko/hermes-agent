-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterAttribCell
-- Date: 2022-11-08 19:29:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterAttribCell = class("UICharacterAttribCell")

function UICharacterAttribCell:OnEnter(nIndex, tbInfo)
    self.nIndex = nIndex
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UICharacterAttribCell:OnExit()
    self.bInit = false
end

function UICharacterAttribCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCell, EventType.OnClick, function(btn)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetAttriTips, self.TogCell, TipsLayoutDir.LEFT_CENTER, self.tbInfo)
    end)

end

function UICharacterAttribCell:RegEvent()

end

function UICharacterAttribCell:UpdateInfo()
    UIHelper.SetVisible(self.BgAttri, self.nIndex % 2 == 1)
    UIHelper.SetString(self.LabelAttri, self.tbInfo.szName)
    UIHelper.SetString(self.LabelAttriNum, self.tbInfo.szValue)
end


return UICharacterAttribCell