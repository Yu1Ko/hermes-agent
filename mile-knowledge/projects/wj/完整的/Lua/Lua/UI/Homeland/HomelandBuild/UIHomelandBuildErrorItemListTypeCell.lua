-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildErrorItemListTypeCell
-- Date: 2023-05-29 10:39:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildErrorItemListTypeCell = class("UIHomelandBuildErrorItemListTypeCell")

function UIHomelandBuildErrorItemListTypeCell:OnEnter(DataModel, tbInfo)
    self.DataModel = DataModel
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildErrorItemListTypeCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildErrorItemListTypeCell:BindUIEvent()

end

function UIHomelandBuildErrorItemListTypeCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildErrorItemListTypeCell:UpdateInfo()
    UIHelper.SetString(self.LabelTypeName, UIHelper.GBKToUTF8(self.tbInfo.szName))
    UIHelper.SetString(self.LabelLevelRequirementNum, self.tbInfo.nNeedLevel)
    UIHelper.SetRichText(self.RichTextLimitNum, string.format("<color=#F76A6A>%d</c><color=#b6d4dc>/%d</c>", self.tbInfo.nUsedCount, self.tbInfo.nLimitAmount))

    if self.tbInfo.tUITexInfo and self.tbInfo.tUITexInfo.szPath and self.tbInfo.tUITexInfo.nFrame then
        local szPath = HomelandChildTypeIcon[self.tbInfo.tUITexInfo.szPath] and HomelandChildTypeIcon[self.tbInfo.tUITexInfo.szPath][self.tbInfo.tUITexInfo.nFrame]
        if szPath and szPath ~= "" then
            UIHelper.SetSpriteFrame(self.ImgType, szPath)
        end
    end

end


return UIHomelandBuildErrorItemListTypeCell