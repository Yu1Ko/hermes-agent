-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICheckoutHairDyeItem
-- Date: 2025-10-16 19:01:16
-- Desc: ?
-- ---------------------------------------------------------------------------------
local ICON_PATH = "Resource/icon/armor/Hairstyle/FXRS.png"
local UICheckoutHairDyeItem = class("UICheckoutHairDyeItem")

function UICheckoutHairDyeItem:OnEnter(nHairID, tbColorInfo, tbCostItem, nDyeingIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nHairID = nHairID
    self.tbColorInfo = tbColorInfo
    self.tbCostItem = tbCostItem
    self.nDyeingIndex = nDyeingIndex
    self:UpdateInfo()
end

function UICheckoutHairDyeItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICheckoutHairDyeItem:BindUIEvent()
    
end

function UICheckoutHairDyeItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICheckoutHairDyeItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICheckoutHairDyeItem:UpdateInfo()
    local szTitle = g_tStrings.CHAT_NEW_NAME
    if self.nDyeingIndex > 0 then
        szTitle = "修改"
    end

    local scriptIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
    scriptIcon:SetClickNotSelected(true)
    scriptIcon:OnInitWithIconID(10775, 2, 1)
    UIHelper.SetTexture(scriptIcon.ImgIcon, ICON_PATH)

    UIHelper.SetString(self.LabelType, szTitle)
    for i, img in ipairs(self.tbColorImg) do
        local tColor = self.tbColorInfo[i]
        if tColor and tColor.dwColorID > 0 then
            UIHelper.SetColor(img, cc.c3b(tColor.nR, tColor.nG, tColor.nB))
        else
            UIHelper.SetVisible(img, false)
        end
    end

    for i, tbItems in ipairs(self.tbCostItem) do
        for j, item in ipairs(tbItems) do
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutItem)
            scriptItem:SetClickNotSelected(true)
            scriptItem:SetClickCallback(function()
                scriptItem:ShowItemTips()
            end)

            if i == 1 then
                local dwBox = item.dwBox
                local dwX = item.dwX
                scriptItem:OnInit(dwBox, dwX)
                UIHelper.SetVisible(scriptItem.LabelCount, true)
                UIHelper.SetString(scriptItem.LabelCount, 1)
            else
                local dwTabType = item.dwItemType
                local dwIndex = item.dwItemIndex
                scriptItem:OnInitWithTabID(dwTabType, dwIndex, 1)
                UIHelper.SetColor(scriptItem.LabelCount, cc.c3b(255, 0, 0))
            end
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutItem)
end


return UICheckoutHairDyeItem