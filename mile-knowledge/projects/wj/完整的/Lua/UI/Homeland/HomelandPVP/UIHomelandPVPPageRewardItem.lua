-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandPVPPageRewardItem
-- Date: 2023-04-04 19:24:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandPVPPageRewardItem = class("UIHomelandPVPPageRewardItem")

function UIHomelandPVPPageRewardItem:OnEnter(tbRewardInfo)
    self.tbRewardInfo = tbRewardInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandPVPPageRewardItem:OnExit()
    self.bInit = false
end

function UIHomelandPVPPageRewardItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogHomeMatch, EventType.OnClick, function ()
        if self.funcCallback then
            self.funcCallback()
        end
    end)
end

function UIHomelandPVPPageRewardItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandPVPPageRewardItem:UpdateInfo()
    local itemInfo = ItemData.GetItemInfo(ITEM_TABLE_TYPE.HOMELAND, self.tbRewardInfo.dwFurniturenIndex)
    UIHelper.SetString(self.LabelProp, UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(itemInfo)))
    UIHelper.SetString(self.LabelMoney, self.tbRewardInfo.nPrice)

    local dwFurnitureID 	= itemInfo.dwFurnitureID
    local dwUIFurnitureID 	= GetHomelandMgr().MakeFurnitureUIID(HS_FURNITURE_TYPE.FURNITURE, dwFurnitureID)
    local tItemAddInfo 		= Table_GetFurnitureAddInfo(dwUIFurnitureID)

    if tItemAddInfo then
        local szPath = string.gsub(tItemAddInfo.szPath, "ui/Image", "mui/Resource")
        szPath = string.gsub(szPath, ".tga", ".png")
        UIHelper.SetTexture(self.ImgItemIcon, szPath)
    end

end

function UIHomelandPVPPageRewardItem:SetSelectCallback(funcCallback)
    self.funcCallback = funcCallback
end


return UIHomelandPVPPageRewardItem