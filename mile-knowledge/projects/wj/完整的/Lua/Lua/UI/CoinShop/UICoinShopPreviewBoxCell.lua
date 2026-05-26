-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopPreviewBoxCell
-- Date: 2025-04-11 16:12:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopPreviewBoxCell = class("UICoinShopPreviewBoxCell")

function UICoinShopPreviewBoxCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICoinShopPreviewBoxCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopPreviewBoxCell:BindUIEvent()

end

function UICoinShopPreviewBoxCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopPreviewBoxCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UICoinShopPreviewBoxCell:OnInitWithBox()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetVisible(self.TogItemBox, true)
    UIHelper.SetVisible(self.TogItemCell, false)
    self.ItemBoxScript = self.ItemBoxScript or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItemBox)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UICoinShopPreviewBoxCell:OnInitWithCell(nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetVisible(self.TogItemBox, false)
    UIHelper.SetVisible(self.TogItemCell, true)
    self.ItemCellScript = self.ItemCellScript or UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItemCell)
    UIHelper.SetVisible(self.ImgLineTop, nIndex == 1)
    UIHelper.SetVisible(self.ImgLine, nIndex ~= 1)
    UIHelper.LayoutDoLayout(self._rootNode)
end

return UICoinShopPreviewBoxCell