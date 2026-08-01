-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildErrorItemListCell
-- Date: 2023-05-29 10:39:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildErrorItemListCell = class("UIHomelandBuildErrorItemListCell")
function UIHomelandBuildErrorItemListCell:OnEnter(DataModel, tbInfo)
    self.DataModel = DataModel
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildErrorItemListCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildErrorItemListCell:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnItem, true)

    UIHelper.BindUIEvent(self.TogItemCell, EventType.OnClick, function ()
        local bSelected = UIHelper.GetSelected(self.TogItemCell)
        Event.Dispatch(EventType.OnSelectedHomelandBuildErrorListCell)
    end)

    UIHelper.BindUIEvent(self.BtnItem, EventType.OnClick, function ()
        local tips, scriptTips = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, self.BtnItem, TipsLayoutDir.TOP_RIGHT)
        scriptTips:OnInitFurniture(self.tbInfo.nFurnitureType, self.tbInfo.dwFurnitureID)
        scriptTips:SetBtnState({})
        tips:SetOffset(0, -600)
    end)

    UIHelper.BindUIEvent(self.BtnQuickTaYin, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelInviteZhiJiaoPop, self.tbInfo.dwFurnitureID)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function ()
        if self.tbInfo.nCoinMoney and self.tbInfo.nCoinMoney > 0 then
            UIMgr.Open(VIEW_ID.PanelTongBaoPurchasePop, true, {{dwFurnitureID = self.tbInfo.dwFurnitureID, nNum = self.tbInfo.nNum or self.tbInfo.nTotalNum or 1}})
        else
            UIMgr.Open(VIEW_ID.PanelItemPurchasePop, {{dwFurnitureID = self.tbInfo.dwFurnitureID, nNum = self.tbInfo.nNum or self.tbInfo.nTotalNum or 1}})
        end
    end)
end

function UIHomelandBuildErrorItemListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildErrorItemListCell:UpdateInfo()
    UIHelper.SetRichText(self.RichTextItemName, GetFormatText(UIHelper.GBKToUTF8(self.tbInfo.szName), nil, self.tbInfo.tRGB[1], self.tbInfo.tRGB[2], self.tbInfo.tRGB[3]))
    local szPath = string.gsub(self.tbInfo.szImgPath, "ui/Image/", "Resource/")
    szPath = string.gsub(szPath, ".tga", ".png")
    UIHelper.SetTexture(self.ImgItem, szPath)

    UIHelper.SetString(self.LabelMissingNum, self.tbInfo.nNum or self.tbInfo.nTotalNum or 1)
    UIHelper.LayoutDoLayout(self.LayoutMissingNum)
    UIHelper.SetVisible(self.BtnBuy, false)
    UIHelper.SetVisible(self.BtnQuickTaYin, false)
    UIHelper.SetVisible(self.RichTextDesc, true)

    if self.tbInfo.szErrorType == "PendantShort" then
        local bCanIsotype, szCantType = Homeland_CanIsotypePendant(self.tbInfo.dwFurnitureID)
        if not bCanIsotype then
            UIHelper.SetRichText(self.RichTextDesc, self.tbInfo.szInfo)
        else
            UIHelper.SetVisible(self.RichTextDesc, false)
            UIHelper.SetVisible(self.BtnQuickTaYin, true)
        end
    elseif self.tbInfo.szInfo and self.tbInfo.szInfo ~= nil then
        UIHelper.SetRichText(self.RichTextDesc, self.tbInfo.szInfo)
    elseif self.tbInfo.szErrorType == "ItemShort" then
        local bCanBuy = false
        if self.tbInfo.nArchMoney and self.tbInfo.nArchMoney > 0 then
            UIHelper.SetRichText(self.RichTextDesc, string.format("总价：%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuanZhaiBi' width='32' height='32' />", self.tbInfo.nArchMoney))
            bCanBuy = true
        elseif self.tbInfo.nCoinMoney and self.tbInfo.nCoinMoney > 0 then
            UIHelper.SetRichText(self.RichTextDesc, string.format("总价：%d<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_TongBao' width='32' height='32' />", self.tbInfo.nCoinMoney))
            bCanBuy = true
        end
        UIHelper.SetVisible(self.BtnBuy, bCanBuy)
    elseif self.tbInfo.szErrorType == "Level" then
        local szDesc = "所需宅邸等级:"
        if self.tbInfo.nLevelLimit and self.tbInfo.nLevelLimit > 0 then
            szDesc = szDesc .. self.tbInfo.nLevelLimit
        else
            local tConfig = GetHomelandMgr().GetFurnitureConfig(self.tInfo.dwFurnitureID)
            szDesc = szDesc .. tConfig.nLevelLimit
        end
        UIHelper.SetRichText(self.RichTextDesc, szDesc)
    end
end

function UIHomelandBuildErrorItemListCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogItemCell, bSelected)
end

function UIHomelandBuildErrorItemListCell:GetItemInfo()
    local nArchMoney = 0
	local nCoinMoney = 0
	local nGold = 0
    local bSelected = UIHelper.GetSelected(self.TogItemCell)
    local dwModelID = -1

    if self.tbInfo.dwModelID then
        dwModelID = self.tbInfo.dwModelID
    end
    if self.tbInfo.nArchMoney then
        nArchMoney = self.tbInfo.nArchMoney
    elseif self.tbInfo.nCoinMoney then
        nCoinMoney = self.tbInfo.nCoinMoney
    elseif self.tbInfo.nGold then
        nGold = self.tbInfo.nGold
    end

    return bSelected, dwModelID, nArchMoney, nCoinMoney, nGold
end

function UIHomelandBuildErrorItemListCell:GetItemFurnitureInfo()
    local bSelected = UIHelper.GetSelected(self.TogItemCell)
    local dwFurnitureID = self.tbInfo.dwFurnitureID
    local nNum = self.tbInfo.nNum

    return bSelected, dwFurnitureID, nNum
end


return UIHomelandBuildErrorItemListCell