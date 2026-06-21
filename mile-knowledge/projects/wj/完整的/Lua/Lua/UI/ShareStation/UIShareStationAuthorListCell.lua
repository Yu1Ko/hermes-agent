-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationAuthorListCell
-- Date: 2025-10-22 15:31:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShareStationAuthorListCell = class("UIShareStationAuthorListCell")

function UIShareStationAuthorListCell:OnEnter(nDataType, tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nDataType = nDataType
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIShareStationAuthorListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationAuthorListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogAuthor, EventType.OnClick, function()
        Event.Dispatch(EventType.OnClickShareStationAuthorCell, self.nDataType, self.tbInfo)
    end)
end

function UIShareStationAuthorListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShareStationAuthorListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShareStationAuthorListCell:UpdateInfo()
    if not self.tbInfo then
        return
    end

    local nDataType = self.nDataType
    local nWorksNum = self.tbInfo.nWorksNum
    local szUser = self.tbInfo.szUser
    UIHelper.SetString(self.LabelName, szUser)
    UIHelper.SetString(self.LabelNameSelected, szUser)

    local szNum = string.format("%s%d个", g_tStrings.tShareStationTitle[nDataType], nWorksNum)
    UIHelper.SetRichText(self.LabelCount, szNum)
    UIHelper.SetRichText(self.LabelCountSelected, szNum)
end

function UIShareStationAuthorListCell:SetBatchSelecte(bSelected)
    self.bBatchSelected = bSelected
end

return UIShareStationAuthorListCell