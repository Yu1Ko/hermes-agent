-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopFurnitureColor
-- Date: 2023-08-02 11:15:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopFurnitureColor = class("UICoinShopFurnitureColor")

function UICoinShopFurnitureColor:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    for _, tog in ipairs(self.tTogColor) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, tog)
    end
end

function UICoinShopFurnitureColor:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopFurnitureColor:BindUIEvent()
    for i, tog in ipairs(self.tTogColor) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                local tColor = self.tColorInfos[i]
                self.nColorIndex = tColor[1]
                FireUIEvent("FURNITURE_MODEL_SET_DETAILS", "CoinShop_View", "CoinShop", self.nColorIndex)
            end
        end)
    end
end

function UICoinShopFurnitureColor:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopFurnitureColor:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopFurnitureColor:UpdateInfo(tColorInfos)
    self.tColorInfos = tColorInfos
    self.nColorIndex = 0
    for i, tog in ipairs(self.tTogColor) do
        if i <= #self.tColorInfos then
            UIHelper.SetVisible(tog, true)
            local tColor = self.tColorInfos[i]
            local nColorIndex, nR, nG, nB = tColor[1], tColor[2], tColor[3], tColor[4]
            UIHelper.SetColor(self.tImgColor[i], cc.c3b(nR, nG, nB))
            if self.nColorIndex == nColorIndex then
                UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, tog)
            end
        else
            UIHelper.SetVisible(tog, false)
        end
    end
    UIHelper.LayoutDoLayout(self._rootNode)
end

return UICoinShopFurnitureColor