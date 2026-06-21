-- ---------------------------------------------------------------------------------
-- Author: yuminqian
-- Name: UIPanelPop_BirthdaySetting
-- Date: 2025-12-14 22:51:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelPop_BirthdaySetting = class("UIPanelPop_BirthdaySetting")
local BIRTH_SET_ITEM = {
    dwTabType = 5, 
    dwIndex   = 81787, 
}
local INTERCALARY_MONTH_DAY = {
    nMonth = 2, 
    nDay = 29,
}
local MODIFY_BIRTH_ITEM_COUNT = 1 -- 修改生日所需道具数量

function UIPanelPop_BirthdaySetting:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if Storage.Birthday.bShowRedPoint then
        Storage.Birthday.bShowRedPoint = false
        Storage.Birthday.Dirty()
        Event.Dispatch(EventType.OnUpdateBirthdaySetRedPoint)
    end
    self.nMonth = 1 
    self.nDay = 1
    self.bAlreadySet = false
    self:UpdateInfo()
end

function UIPanelPop_BirthdaySetting:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelPop_BirthdaySetting:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function(btn)
        self:DoSetBirthday()
    end)

    UIHelper.BindUIEvent(self.BtnModify, EventType.OnClick, function(btn)
        self:UpdateBirthdayText(true)
        self:UpdateBtnState(true)
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnDetail,
        g_tStrings.STR_BIRTHDAY_RULE)
    end)

    UIHelper.BindUIEvent(self.TogMonthFilter, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:UpdateMonthList()
        end
    end)

    UIHelper.BindUIEvent(self.TogDateFilter, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:UpdateDayList()
        end
    end)
end

function UIPanelPop_BirthdaySetting:RegEvent()
    Event.Reg(self , "ON_BIRTHDAY_SET_SUCCESS" , function()
        self:OnBirthdaySetSuccess()
    end)
end

function UIPanelPop_BirthdaySetting:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelPop_BirthdaySetting:UpdateInfo()
    self:UpdatePlayerBirthData()
    if not self.nMonth or not self.nDay then
        return
    end
    self:UpdateBirthdayText()
    -- self:UpdateItemMsgBox()
    self:UpdateBtnState()
end

function UIPanelPop_BirthdaySetting:UpdatePlayerBirthData()
    local tData = GDAPI_GetBirthDayData()
    self.tData = tData
    self.tStorageData = clone(tData)
    if tData and tData.nMonth and tData.nDay then
        self.nMonth = tData.nMonth > 0 and tData.nMonth or 1
        self.nDay   = tData.nDay > 0 and tData.nDay or 1
        self.bAlreadySet = (tData.nMonth > 0 and tData.nDay > 0) or false
    end
    self.bCanModify = tData.bChangeFree
end

function UIPanelPop_BirthdaySetting:UpdateBirthdayText(bModifing)
    if self.bAlreadySet and not bModifing then
        local szMsg = string.format(g_tStrings.STR_BIRTHDAY_DATE, self.nMonth, self.nDay)
        UIHelper.SetString(self.LabelBirthdayDate, szMsg)
        local nChange = self.bCanModify and 1 or 0
        local szTip = string.format(g_tStrings.STR_BIRTHDAY_REMAIN_CHANGE, nChange)
        UIHelper.SetString(self.LabelSetTips, szTip)
        UIHelper.LayoutDoLayout(self.LayoutMonthFilter)
    else
        local szMonth = self.nMonth .. "月"
        local szDay   = self.nDay .. "日"
        UIHelper.SetString(self.LabelMonthFilter, szMonth)
        UIHelper.SetString(self.LabelDateFilter, szDay)
    end
    UIHelper.SetVisible(self.LayoutMyBirthday, self.bAlreadySet and not bModifing)
    UIHelper.SetVisible(self.WidgetMainContent, not self.bAlreadySet or bModifing)
    UIHelper.LayoutDoLayout(self.LayoutMyBirthday)
end

-- function UIPanelPop_BirthdaySetting:UpdateItemMsgBox()
--     local pPlayer = GetClientPlayer()
--     if not pPlayer then
--         return
--     end
--     UIHelper.SetVisible(self.LayoutContent, self.bAlreadySet)
--     local dwTabType, dwIndex = BIRTH_SET_ITEM.dwTabType, BIRTH_SET_ITEM.dwIndex
--     local nItemCount = pPlayer.GetItemAmountInPackage(dwTabType, dwIndex)
--     self.nItemCount = nItemCount or 0
--     local szCount = self.nItemCount .. "/" .. MODIFY_BIRTH_ITEM_COUNT
--     -- hTextHave:SetText(nItemCount)
--     -- hTextNeed:SetText("/" .. MODIFY_BIRTH_ITEM_COUNT)
--     -- if nItemCount < MODIFY_BIRTH_ITEM_COUNT then
--     --     hTextHave:SetFontColor(240, 0 ,0)
--     --     hTextNeed:SetFontColor(240, 0 ,0)
--     -- end
--     self.ItemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)
--     self.ItemScript:SetClickNotSelected(true)
--     self.ItemScript:OnInitWithTabID(dwTabType, dwIndex)
--     self.ItemScript:SetLabelCountString(szCount)
--     if nItemCount < MODIFY_BIRTH_ITEM_COUNT then
--         local colorRed = cc.c3b(255, 133, 125)
--         UIHelper.SetTextColor(self.ItemScript.LabelCount, colorRed)
--     end
--     self.ItemScript:SetClickCallback(function(nItemType, nItemIndex)
--         Timer.AddFrame(self, 1, function()
--             TipsHelper.ShowItemTips(self.ItemScript._rootNode, dwTabType, dwIndex, false)
--         end)
--     end)
-- end

function UIPanelPop_BirthdaySetting:UpdateBtnState(bModifing)
    local bSet = self.bAlreadySet
    local bModifing = bModifing or false
    local bNormal = bSet and not bModifing
    local bCanModify = self.bCanModify -- self.nItemCount and self.nItemCount >= MODIFY_BIRTH_ITEM_COUNT
    UIHelper.SetVisible(self.BtnAccept, not bNormal)
    UIHelper.SetVisible(self.BtnCancel, not bNormal)
    UIHelper.SetVisible(self.ImgMonthBtn, not bNormal)
    UIHelper.SetVisible(self.ImgDateBtn, not bNormal)
    UIHelper.SetCanSelect(self.TogMonthFilter, not bNormal)
    UIHelper.SetCanSelect(self.TogDateFilter, not bNormal)
    UIHelper.SetVisible(self.BtnModify, bNormal)
    UIHelper.SetButtonState(self.BtnModify, bCanModify and BTN_STATE.Normal or BTN_STATE.Disable)
    -- UIHelper.SetString(self.LabelTitle, bNormal and g_tStrings.STR_BIRTHDAY_SHOW or g_tStrings.STR_BIRTHDAY_SET)
    UIHelper.SetString(self.LabelContent, bNormal and g_tStrings.STR_BIRTHDAY_SHOW or g_tStrings.STR_BIRTHDAY_SET)
    
    if bModifing then
        local bDiffDay = not self.tStorageData or (self.nMonth ~= self.tStorageData.nMonth) or (self.nDay ~= self.tStorageData.nDay)
        UIHelper.SetButtonState(self.BtnAccept, bDiffDay and BTN_STATE.Normal or BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnAccept, BTN_STATE.Normal)
    end
    UIHelper.LayoutDoLayout(self.LayoutBtns)
    
end

function UIPanelPop_BirthdaySetting:OnBirthdaySetSuccess()
    self:UpdatePlayerBirthData()
    self:UpdateBirthdayText()
    -- self:UpdateItemMsgBox()
    self:UpdateBtnState()
end

function UIPanelPop_BirthdaySetting:DoSetBirthday()
    local nMonth, nDay = self.nMonth, self.nDay
    local szMsg = string.format(g_tStrings.STR_BIRTHDAY_SET_MESSAGE, self.nMonth, self.nDay)
    if self.bAlreadySet then
        -- local tItemInfo = GetItemInfo(BIRTH_SET_ITEM.dwTabType, BIRTH_SET_ITEM.dwIndex)
        -- local szItemName = UIHelper.GBKToUTF8(ItemData.GetItemNameByItemInfo(tItemInfo))
        szMsg = string.format(g_tStrings.STR_BIRTHDAY_CHANGE_MESSAGE, self.nMonth, self.nDay)
    end  

    UIHelper.ShowConfirm(szMsg, function ()
        RemoteCallToServer("On_ShowCard_SetBirthDayDate", nMonth, nDay)
    end)
end

function UIPanelPop_BirthdaySetting:AdjustTipCellSize(cell)
    local w, h = UIHelper.GetContentSize(cell._rootNode)
    UIHelper.SetContentSize(cell.TogType, w, h)
    UIHelper.CascadeDoLayoutDoWidget(cell._rootNode, true, true)
end

function UIPanelPop_BirthdaySetting:UpdateMonthList()
    local nDefultMonth = 1
    local nMaxMonth = 12
    UIHelper.RemoveAllChildren(self.LayoutMonthFilter)
    for nMonth = 1, nMaxMonth do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleFilterTipCell, self.LayoutMonthFilter)
        UIHelper.SetString(cell.LabelContentText, nMonth .. "月")
        UIHelper.SetSwallowTouches(cell.TogType, false)
        UIHelper.SetSelected(cell.TogType, nMonth == nDefultMonth, false)
        UIHelper.BindUIEvent(cell.TogType, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self.nMonth = nMonth
                if self.nDay > g_tStrings.STR_BIRTHDAY_DAY[self.nMonth] then
                    self.nDay = g_tStrings.STR_BIRTHDAY_DAY[self.nMonth]
                end
                self:UpdateBirthdayText(true)
                self:UpdateBtnState(true)
                UIHelper.SetSelected(self.TogType, false)
                UIHelper.SetSelected(self.TogMonthFilter, false)
                UIHelper.SetSelected(self.TogDateFilter, false)
                self:AdjustTipCellSize(cell)
                -- UIHelper.SetVisible(self.WidgetMonthFilter, false)
                self:CheckIntercalaryMonthDay()
            end
        end)
    end
    -- UIHelper.SetVisible(self.WidgetMonthFilter, true)
    UIHelper.LayoutDoLayout(self.LayoutMonthFilter)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMonth)
end

function UIPanelPop_BirthdaySetting:UpdateDayList()
    local nDefultDay = 1
    local nMaxDay = g_tStrings.STR_BIRTHDAY_DAY[self.nMonth]
    UIHelper.RemoveAllChildren(self.LayoutDateFilter)
    for nDay = 1, nMaxDay do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleFilterTipCell, self.LayoutDateFilter)
        UIHelper.SetString(cell.LabelContentText, nDay .. "日")
        UIHelper.SetSwallowTouches(cell.TogType, false)
        UIHelper.SetSelected(cell.TogType, nDay == nDefultDay, false)
        UIHelper.BindUIEvent(cell.TogType, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self.nDay = nDay
                self:UpdateBirthdayText(true)
                self:UpdateBtnState(true)
                UIHelper.SetSelected(self.TogType, false)
                UIHelper.SetSelected(self.TogMonthFilter, false)
                UIHelper.SetSelected(self.TogDateFilter, false)
                self:AdjustTipCellSize(cell)
                -- UIHelper.SetVisible(self.WidgetDateFilter, false)
                self:CheckIntercalaryMonthDay()
            end
        end)
    end
    UIHelper.LayoutDoLayout(self.LayoutDateFilter)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDay)
end

function UIPanelPop_BirthdaySetting:CheckIntercalaryMonthDay() -- 选择2月29日时需要弹出特殊提示
    if self.nMonth == INTERCALARY_MONTH_DAY.nMonth and self.nDay == INTERCALARY_MONTH_DAY.nDay then
        local szMsg = g_tStrings.STR_BIRTHDAY_SET_SPECIAL_MESSAGE
        UIHelper.ShowConfirm(szMsg)
    end
end

return UIPanelPop_BirthdaySetting