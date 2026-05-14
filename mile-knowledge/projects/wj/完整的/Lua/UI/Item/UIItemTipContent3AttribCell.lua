-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent3AttribCell
-- Date: 2023-01-06 17:14:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent3AttribCell = class("UIItemTipContent3AttribCell")

function UIItemTipContent3AttribCell:OnEnter(tbInfo)
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemTipContent3AttribCell:OnExit()
    self.bInit = false
end

function UIItemTipContent3AttribCell:BindUIEvent()

end

function UIItemTipContent3AttribCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent3AttribCell:UpdateInfo()
    UIHelper.RemoveAllChildren(self.WidgetItem)
    local item = self.tbInfo.diamon
    if item then
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetItem)
        scriptItem:OnInitWithTabID(self.tbInfo.nType, self.tbInfo.nTabIndex)
        scriptItem:SetSelectEnable(false)
    end

    local szEnchantIconImg = self.tbInfo.szEnchantIconImg
    if szEnchantIconImg then
        UIHelper.SetVisible(self.ImgEnchantIcon, true)
        UIHelper.SetSpriteFrame(self.ImgEnchantIcon, szEnchantIconImg)
    end

    if self.tbInfo.bActived then
        UIHelper.SetRichText(self.RichTextAttri1, string.format("<color=#95FF95>%s</c>", self.tbInfo.szAttr))
    else
        UIHelper.SetRichText(self.RichTextAttri1, string.format("<color=#AFC1D4>%s</c>", self.tbInfo.szAttr))
    end

    UIHelper.LayoutDoLayout(self._rootNode)
    UIHelper.WidgetFoceDoAlign(self)
end


return UIItemTipContent3AttribCell