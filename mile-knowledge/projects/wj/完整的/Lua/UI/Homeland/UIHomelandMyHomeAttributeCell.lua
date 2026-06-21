-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeAttributeCell
-- Date: 2023-03-29 19:17:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeAttributeCell = class("UIHomelandMyHomeAttributeCell")

local Index2Name = {
    "观赏",
    "实用",
    "坚固",
    "风水",
    "趣味",
    "装修评分",
}
function UIHomelandMyHomeAttributeCell:OnEnter(nIndex, nValue)
    self.nIndex = nIndex
    self.nValue = nValue

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMyHomeAttributeCell:OnExit()
    self.bInit = false
end

function UIHomelandMyHomeAttributeCell:BindUIEvent()

end

function UIHomelandMyHomeAttributeCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandMyHomeAttributeCell:UpdateInfo()
    UIHelper.SetString(self.LabelHomeAttribute, string.format("%s：%d", Index2Name[self.nIndex], self.nValue))
    -- UIHelper.SetSpriteFrame(self.ImgAttributeIcon, Index2Img[self.nIndex])
end


return UIHomelandMyHomeAttributeCell