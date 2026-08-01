-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeIdentityCartCell
-- Date: 2024-01-24 10:46:59
-- Desc: ?
-- ---------------------------------------------------------------------------------
local FRAME_MODE =
{
    SELL = 1,
    BUY  = 2,
}
local UIHomeIdentityCartCell = class("UIHomeIdentityCartCell")

function UIHomeIdentityCartCell:OnEnter(nIndex, tFoodInfo, tFoodData, nFrameMode)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex     = nIndex
    self.tInfo      = tFoodInfo
    self.tData      = tFoodData
    self.nFrameMode = nFrameMode
    self:UpdateInfo()
end

function UIHomeIdentityCartCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeIdentityCartCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCell, EventType.OnClick, function ()
        local tData = Lib.copyTab(self.tData)
        if not tData or table.is_empty(tData) or tData.dwID == 0 then
            Event.Dispatch(EventType.OnFoodCartSelectEmptyFood, self.nIndex, tData)
            return
        end
        Event.Dispatch(EventType.OnFoodCartOpenDetailPop, self.nIndex, tData)
    end)
end

function UIHomeIdentityCartCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeIdentityCartCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeIdentityCartCell:UpdateInfo()
    local nFrameMode    = self.nFrameMode
    local tInfo         = self.tInfo
    local tData         = self.tData

    UIHelper.SetVisible(self.WidgetAdd, false)
    UIHelper.SetVisible(self.WidgetRollPointItemNormal, false)
    UIHelper.SetVisible(self.WidgetLock, false)
    if not tData or table.is_empty(tData) or tData.dwID == 0 then
        UIHelper.SetVisible(self.WidgetAdd, true)
        return
    elseif tData and tData.nLevel and nFrameMode == FRAME_MODE.SELL then
        local szLock = FormatString(g_tStrings.STR_HOMELAND_UNLOCK_LEVEL, tData.nLevel)
        UIHelper.SetString(self.LabelLock, szLock)
        UIHelper.SetVisible(self.WidgetLock, true)
        return
    end
    if not tInfo then
        return
    end
    local nCount     = tData.nCount
    local nMoney     = tData.nMoney
    local dwTabType = tInfo.dwItemType
    local dwIndex   = tInfo.dwIndex
    local tItemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)
    if not tItemInfo then
        return
    end
    local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
    scriptItem:OnInitWithTabID(dwTabType, dwIndex, nCount)
    scriptItem:SetEnable(false)
    UIHelper.SetRichText(self.RichTextItemName, UIHelper.GBKToUTF8(tItemInfo.szName))
    UIHelper.SetString(self.LabelMoney_Jin, nMoney)
    UIHelper.SetVisible(self.WidgetRollPointItemNormal, true)
    UIHelper.SetVisible(self.BtnDisboard, false)
end

return UIHomeIdentityCartCell