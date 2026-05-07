-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopExteriorColor
-- Date: 2023-10-27 11:30:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICoinShopExteriorColor = class("UICoinShopExteriorColor")

function UICoinShopExteriorColor:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICoinShopExteriorColor:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopExteriorColor:BindUIEvent()
    for i, tog in ipairs(self.tTogAcceptNum) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (bSelected)
            if bSelected then
                if i <= #self.tSubGenre then
                    local tSet = self.tSubGenre[i]
                    Event.Dispatch("PREVIEW_SET", tSet.tSub, tSet.nSet)
                end
                UIHelper.SetString(self.LabelSelectAccept, i)
            end
            -- UIHelper.SetSelected(self._rootNode, false)
        end)
    end
end

function UICoinShopExteriorColor:RegEvent()
    Event.Reg(self, "COINSHOPVIEW_ROLE_DATA_UPDATE", function()
        self:UpdateInfo()
    end)
end

function UICoinShopExteriorColor:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopExteriorColor:Show(tSubGenre)
    self.tSubGenre = tSubGenre
    self:SetVisible(true)

    self:UpdateInfo()
end

function UICoinShopExteriorColor:UpdateInfo()
    if not self.tSubGenre then
        self:SetVisible(false)
        return
    end
    local bValid = false
    for i, tog in ipairs(self.tTogAcceptNum) do
        if i <= #self.tSubGenre then
            local bPreview = ExteriorCharacter.IsSetPreview(self.tSubGenre[i].tSub)
            if bPreview then
                bValid = true
            end
            UIHelper.SetVisible(tog, true)
            UIHelper.SetSelected(tog, bPreview, false)
        else
            UIHelper.SetVisible(tog, false)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutAccept)
    if not bValid then
        self:SetVisible(false)
        return
    end
end

function UICoinShopExteriorColor:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
    Event.Dispatch(EventType.OnCoinShopLayoutPetUpdate)
end


return UICoinShopExteriorColor