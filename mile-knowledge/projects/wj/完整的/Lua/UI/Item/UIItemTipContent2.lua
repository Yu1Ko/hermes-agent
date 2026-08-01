-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent2
-- Date: 2022-11-15 15:45:32
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MaxScaleNum = 350 -- 图片最大值

local UIItemTipContent2 = class("UIItemTipContent2")

function UIItemTipContent2:OnEnter(tbInfo)
    if not tbInfo then return end

    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemTipContent2:OnExit()
    self.bInit = false
end

function UIItemTipContent2:BindUIEvent()

end

function UIItemTipContent2:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent2:UpdateInfo()
    if not self.tbInfo or table.is_empty(self.tbInfo) then
        UIHelper.SetVisible(self._rootNode, false)
        UIHelper.SetVisible(self.ImgLine, false)
    else
        local bShow = false
        if self.tbInfo[1] and self.tbInfo[1] ~= "" and self["RichTextAttri"..1] then
            UIHelper.SetVisible(self["RichTextAttri"..1], true)
            UIHelper.SetRichText(self["RichTextAttri"..1], self.tbInfo[1])
            bShow = true
        else
            UIHelper.SetVisible(self["RichTextAttri"..1], false)
        end
        if self.tbInfo[2] and self.tbInfo[2] ~= "" then
            UIHelper.RemoveAllChildren(self.WidgetHeadFrameShell)
            local line = g_tTable.RoleAvatar:Search(self.tbInfo[2])
            UIHelper.SetVisible(self.WidgetHeadFrameShell, true)
            local itemicon = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomAvatarContent,self.WidgetHeadFrameShell,self.tbInfo[2],line,false)
            UIHelper.SetNodeSwallowTouches(itemicon._rootNode, false, true)
            itemicon:OnlyShow()
            UIHelper.SetVisible(self.RichTextAttri1, false)
        end

        if self.tbInfo[3] and self.tbInfo[3] ~= "" then
            UIHelper.SetVisible(self.ImgEmotionPose, true)
            self:SetTexture(self.ImgEmotionPose, self.tbInfo[3])
            -- self.ImgEmotionPose:setTexture(self.tbInfo[3], false)
            bShow = true
        else
            UIHelper.SetVisible(self.ImgEmotionPose, false)
        end

        UIHelper.ClearTexture(self.ImgOrangeWeapon)
        if self.tbInfo[4] and self.tbInfo[4] ~= "" then
            UIHelper.SetVisible(self.ImgOrangeWeapon, true)
            UIHelper.ClearTexture(self.ImgOrangeWeapon)
            self:SetTexture(self.ImgOrangeWeapon, self.tbInfo[4])
            -- self.ImgOrangeWeapon:setTexture(self.tbInfo[4], false)
            bShow = true
        else
            UIHelper.SetVisible(self.ImgOrangeWeapon, false)
        end

        UIHelper.SetVisible(self._rootNode, bShow)
        UIHelper.SetVisible(self.ImgLine, bShow)

        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end
end

-- 出现图素大小是1024*1024的情况，这边限制一下
function UIItemTipContent2:SetTexture(img, szTexture)
    if string.is_nil(szTexture) then
        return
    end
    img:setTexture(szTexture, false)
    local w, h = UIHelper.GetContentSize(img)
    if w > MaxScaleNum or h > MaxScaleNum then
        local fRatio = MaxScaleNum / math.max(w,h)
        w = w * fRatio
        h = h * fRatio
    end
    UIHelper.SetContentSize(img, w, h)
end

return UIItemTipContent2