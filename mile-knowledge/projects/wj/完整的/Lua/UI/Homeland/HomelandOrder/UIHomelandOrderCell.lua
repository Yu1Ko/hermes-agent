-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOrderCell
-- Date: 2024-01-15 17:06:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandOrderCell = class("UIHomelandOrderCell")

function UIHomelandOrderCell:OnEnter(tbOrderInfo, tInfo, nIndex, dwPackItemIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tbOrderInfo
    self.tInfo = tInfo
    self.nIndex = nIndex
    self.dwPackItemIndex = dwPackItemIndex
    self:UpdateInfo()
end

function UIHomelandOrderCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandOrderCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleQuality, EventType.OnSelectChanged, function (tog, bSelected)
        local tInfo = self.tInfo
        if not bSelected or not tInfo then
            UIHelper.SetOpacity(self.ImgNormalFrame, 153)
            return
        end
        Event.Dispatch(EventType.OnHomeOrderSelectedCell, tInfo.dwID, tInfo.nType, self.nIndex)
        UIHelper.SetOpacity(self.ImgNormalFrame, 255)
    end)
end

function UIHomelandOrderCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandOrderCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandOrderCell:UpdateInfo()
    local bCanSubmit = true
    local tData = self.tData
    local tInfo = self.tInfo
    local bWeekly = tData.bWeekly and not tData.nLevel
    UIHelper.SetVisible(self.ImgFriend, tData.bAssist and not tData.bFinish and tData.bOwner)
    if bWeekly then
        UIHelper.SetSpriteFrame(self.ImgWeek, "UIAtlas2_HomeIdentify_HomeOrder_img_Week.png")
    end

    if not not tData.nLevel then
        UIHelper.SetVisible(self.ToggleQuality, false)
        UIHelper.SetVisible(self.WidgetLock, true)
        UIHelper.SetString(self.LabelLock, FormatString(g_tStrings.STR_HOMELAND_UNLOCK_LEVEL, tData.nLevel or 0))
        UIHelper.SetEnable(self.ToggleQuality, not tData.nLevel)
    end
    if not tInfo then
        return
    end
    if tInfo and tInfo.szImagePath ~= "" then
        local szBgPath = UIHelper.FixDXUIImagePath(tInfo.szImagePath)
        UIHelper.SetTexture(self.ImgNormalFrame, szBgPath)
    end
    for _, v in ipairs(tInfo.tItemList) do
        local dwTabType   = v.dwTabType
        local dwIndex     = v.dwIndex
        local nCount      = v.nCount
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem80)
        script:OnInitWithTabID(dwTabType, dwIndex, nCount)
        script:SetEnable(false)

        local dwPackItemIndex   = HomelandIdentity.GetPackItem(dwIndex)
        local nInBagCount       = ItemData.GetItemAmountInPackage(dwTabType, dwIndex)
        local nInLockerCount    = GDAPI_GetLockerItemCount(tInfo.nType, dwTabType, dwIndex)
        local nPackCount        = 0

        if dwPackItemIndex then
            nPackCount = ItemData.GetItemAmountInPackage(dwTabType, dwPackItemIndex)
        end
        local nAllCount    = nInBagCount + nInLockerCount + nPackCount
        local tItemInfo   = ItemData.GetItemInfo(dwTabType, dwIndex)
        if tItemInfo then
            if not tData.bFinish then
                local szNum = string.format("%s/%s", nAllCount, nCount)
                if nAllCount < nCount then
                    bCanSubmit = false
                    szNum = string.format("<color=#ff7575>%s</c>/%s", nAllCount, nCount)
                end
                UIHelper.SetRichText(self.RichTextNum, "<color=#245460>"..szNum.."</c>")
            else
                UIHelper.SetVisible(self.WidgetWin, true)
                UIHelper.SetVisible(self.RichTextNum, false)
            end
            UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(tItemInfo)))
        end
    end
    UIHelper.SetVisible(self.WidgetCanGet, not tData.bFinish and bCanSubmit)
    UIHelper.SetVisible(self.WidgetWin, tData.bFinish and tData.bOwner)
end

function UIHomelandOrderCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.ToggleQuality, bSelected)
end

return UIHomelandOrderCell