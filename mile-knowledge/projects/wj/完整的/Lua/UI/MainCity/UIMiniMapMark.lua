local UIMiniMapMark = class("UIMiniMapMark")

function UIMiniMapMark:OnEnter(szFrame)
    UIHelper.SetSpriteFrame(self.ImgIcon, szFrame)
    self.szFram = szFrame
end

function UIMiniMapMark:OnExit()

end

function UIMiniMapMark:SetPosition(x, y)
    self._rootNode:setPosition(x, y)
end

function UIMiniMapMark:SetFrame(szFrame)
    if self.szFram ~= szFrame then
        UIHelper.SetSpriteFrame(self.ImgIcon, szFrame)
        self.szFram = szFrame
    end
end

function UIMiniMapMark:SetYaoLing(bEnable)
    UIHelper.SetVisible(self.Eff_YaoLing, bEnable)
    if bEnable then
        UIHelper.PlayAni(self, self.Eff_YaoLing, "AniYaoLingLoop")
    end
end

return UIMiniMapMark