-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerUpItem
-- Date: 2023-03-30 15:16:34
-- Desc: 侠客-升级道具
-- Prefab: WidgetPartnerUpItem
-- ---------------------------------------------------------------------------------

---@class UIPartnerUpItem
local UIPartnerUpItem = class("UIPartnerUpItem")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerUpItem:_LuaBindList()
    self.LabelName        = self.LabelName --- 道具名称
    self.LabelNum         = self.LabelNum --- 道具数目
    self.ImgTips          = self.ImgTips --- 右上角tips（目前不会同时使用多个道具，先隐藏掉这个）
    self.ImgTag           = self.ImgTag --- 左上角tips（没看出有啥用，先隐藏掉）
    self.TogPartnerUpItem = self.TogPartnerUpItem --- 是否选中的toggle

    self.WidgetItemIcon   = self.WidgetItemIcon --- 道具图标组件
end

function UIPartnerUpItem:OnEnter(nType, dwIndex)
    self.nType   = nType
    self.dwIndex = dwIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerUpItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerUpItem:BindUIEvent()

end

function UIPartnerUpItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerUpItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerUpItem:UpdateInfo()
    local tItemInfo  = ItemData.GetItemInfo(self.nType, self.dwIndex)
    local szItemName = ItemData.GetItemNameByItemInfo(tItemInfo)
    szItemName       = UIHelper.GBKToUTF8(szItemName)

    local nCount     = ItemData.GetItemAmountInPackage(self.nType, self.dwIndex)

    UIHelper.SetString(self.LabelName, szItemName)
    UIHelper.SetString(self.LabelNum, nCount)

    UIHelper.SetVisible(self.ImgTips, false)
    UIHelper.SetVisible(self.ImgTag, false)

    UIHelper.SetSelected(self.TogPartnerUpItem, false)

    if not self.scriptItemIcon then
        ---@type UIItemIcon
        self.scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItemIcon)
        self.scriptItemIcon:SetClickNotSelected(true)
        self.scriptItemIcon:SetLabelCountVisible(false)
    end
    self.scriptItemIcon:OnInitWithTabID(self.nType, self.dwIndex)

    self.scriptItemIcon:SetClickCallback(function()
        self.scriptItemIcon:ShowItemTips()
    end)

    UIHelper.SetToggleGroupIndex(self.TogPartnerUpItem, ToggleGroupIndex.PartnerUpgradeItem)
end

return UIPartnerUpItem