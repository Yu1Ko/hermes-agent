-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomePreviewSkinCell
-- Date: 2023-04-10 11:29:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomePreviewSkinCell = class("UIHomelandMyHomePreviewSkinCell")

local Priority2StateImgBG = {
    -- [1] = "UIAtlas2_Public_PublicItem_PublicItem1_img_tab_05",
    [2] = "UIAtlas2_Public_PublicItem_PublicItem1_img_tab_05",
    [3] = "UIAtlas2_Public_PublicItem_PublicItem1_img_tab_07",
    [4] = "UIAtlas2_Public_PublicItem_PublicItem1_img_tab_04",
    [5] = "UIAtlas2_Public_PublicItem_PublicItem1_img_tab_02",
}

local Priority2StateName = {
    -- [1] = "不在出售时间",
    [2] = "在售",
    [3] = "奇遇",
    [4] = "限时",
    [5] = "新品",
}

function UIHomelandMyHomePreviewSkinCell:OnEnter(nMapID, nCopyIndex, tbInfo, tbStateInfo)
    self.nMapID = nMapID
    self.nCopyIndex = nCopyIndex
    self.tbInfo = tbInfo
    self.tbStateInfo = tbStateInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMyHomePreviewSkinCell:OnExit()
    self.bInit = false
end

function UIHomelandMyHomePreviewSkinCell:BindUIEvent()

end

function UIHomelandMyHomePreviewSkinCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandMyHomePreviewSkinCell:UpdateInfo()
    local szSkinName = UIHelper.GBKToUTF8(self.tbInfo.szSkinName)
    UIHelper.SetString(self.LabelHomeSkin, szSkinName)
    UIHelper.SetString(self.LabelHomeSkin_Select, szSkinName)

    local szState = "未获得"
    local color = cc.c3b(255, 118, 118)

    if self.tbStateInfo then
        if self.tbStateInfo.bUsing then
            szState = "使用中"
            color = cc.c3b(149, 255, 149)
        else
            szState = "已拥有"
            color = cc.c3b(149, 255, 149)
        end
        -- UIHelper.SetVisible(self.BtnVisit, false)
        -- UIHelper.SetVisible(self.BtnBuy, false)

        -- local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
        -- UIHelper.SetVisible(self.BtnChange, dwMapID == self.nMapID and nCopyIndex == self.nCopyIndex and not self.tbStateInfo.bUsing)
    end

    if not self.tbStateInfo and self.tbInfo.dwPriority and Priority2StateImgBG[self.tbInfo.dwPriority] then
        UIHelper.SetVisible(self.ImgSellIcon, true)
        UIHelper.SetSpriteFrame(self.ImgSellIcon, Priority2StateImgBG[self.tbInfo.dwPriority])
        UIHelper.SetString(self.LabelSellState, Priority2StateName[self.tbInfo.dwPriority])
    else
        UIHelper.SetVisible(self.ImgSellIcon, false)
    end

    UIHelper.SetString(self.LabelState, szState)
    UIHelper.SetColor(self.LabelState, color)
end

function UIHomelandMyHomePreviewSkinCell:SetSelected(bSelected)
    UIHelper.SetVisible(self.ImgNormal, not bSelected)
    UIHelper.SetVisible(self.ImgSelect, bSelected)
end


return UIHomelandMyHomePreviewSkinCell