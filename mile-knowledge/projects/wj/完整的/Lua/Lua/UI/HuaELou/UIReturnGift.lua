-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIReturnGift
-- Date: 2023-06-16 16:21:06
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIReturnGift = class("UIReturnGift")

local TOTAL_DAYS = 7
local MAX_BOX_COUNT = 6
local STATE =
{
    DISABLE = 1,
    CAN_GET = 2,
    DONE    = 3
}

local tWidgetIndex = {
    [1] = {1, 2},
    [2] = {3},
    [3] = {4, 5},
    [4] = {6},
    [5] = {7, 8},
    [6] = {9, 10},
    [7] = {11, 12, 13, 14, 15, 16},
}

function UIReturnGift:OnEnter(dwOperatActID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end

    self.nID = nID
    UIHelper.SetVisible(self.WidgetContentVK, Platform.IsWindows())
    UIHelper.SetVisible(self.WidgetContentMobile, not Platform.IsWindows())

    self:InitReward()
    self:UpdateLetter()
    self:UpdateRewardData()
    self:UpdateRewardState()
    self:UpdateBtnState()
end

function UIReturnGift:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIReturnGift:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGetReward, EventType.OnClick, function ()
        for nDayIndex, _ in ipairs(self.tRegressionData) do
            self:GetOneReward(nDayIndex)
        end
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)
end

function UIReturnGift:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "SYNC_REGRESSION_PLAYER_DATA", function ()
        self:UpdateRewardData()
        self:UpdateRewardState()
        self:UpdateBtnState()
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)
end

function UIReturnGift:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIReturnGift:GetOneReward(nDayIndex)
    local hPlayer = GetClientPlayer()
    if not hPlayer then return end

    local tData = self.tRegressionData[nDayIndex]
    if not tData then return end

    local tItemList = tData.tItemTab

    for nIndex, tItem in ipairs(tItemList) do
        if tItem.dwItemType ~= 0 then
            if not tItem.bUsed and tItem.bCanHave then
                hPlayer.AddRegressionReward(nDayIndex, nIndex, nil)
            end
        end
    end
end

function UIReturnGift:UpdateLetter()
    local hPlayer     = PlayerData.GetClientPlayer()
    local nOldTime    = hPlayer.GetExtPoint(403)
    local nCreateTime = hPlayer.GetCreateTime()
    local t           = TimeToDate(nCreateTime)

    UIHelper.SetString(self.LabelTitle04, UIHelper.GBKToUTF8(hPlayer.szName))
    local szLeaveTime     = tostring(math.floor(nOldTime / (24 * 60 * 60)))
    local szCreateTime    = FormatString(g_tStrings.STR_TIME_1, t.year, string.format("%02d", t.month), string.format("%02d", t.day))

    UIHelper.SetRichText(self.RichTextInfo1, FormatString(g_tStrings.STR_RETURN_GIFT_LETTER1, szLeaveTime))
    UIHelper.SetRichText(self.RichTextInfo2, FormatString(g_tStrings.STR_RETURN_GIFT_LETTER2, szCreateTime))
end

function UIReturnGift:InitReward()
    local tbItemScript = {}

    local tReward = HuaELouData.GetShowReward(self.nID) or {}
    for k,tItemData in ipairs(tReward) do
        local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.tbWidgetItem[k])
        if itemScript then
            itemScript:OnInitWithTabID(tItemData[1], tItemData[2], tItemData[3])

            itemScript:SetClickCallback(function (nTabType, nTabID)
                self.SelectToggle = itemScript.ToggleSelect
                for i, v in ipairs(tbItemScript) do
                    if UIHelper.GetSelected(v.ToggleSelect) and i ~= k then
                        UIHelper.SetSelected(v.ToggleSelect,false)
                    end
                end
                if k > TOTAL_DAYS then k = TOTAL_DAYS end
                self:GetOneReward(k)
                TipsHelper.ShowItemTips(itemScript._rootNode, nTabType, nTabID)
            end)

            if k == 14 then
                itemScript:SetLabelCount("15天")
            end

            table.insert(tbItemScript, itemScript)
        end
    end
end

function UIReturnGift:UpdateRewardData()
    self.tRegressionData = g_pClientPlayer.GetRegressionData()
    self.tReturnData = {}
    for k,tData in ipairs(self.tRegressionData) do
        if tData.bAllUsed then
            table.insert(self.tReturnData, STATE.DONE)
        elseif tData.bCanHave then
            table.insert(self.tReturnData, STATE.CAN_GET)
        else
            table.insert(self.tReturnData, STATE.DISABLE)
        end
    end
end

function UIReturnGift:UpdateRewardState()
    for k = 1, TOTAL_DAYS do
        for i = 1, #tWidgetIndex[k] do
            local nIndex = tWidgetIndex[k][i]
            UIHelper.SetVisible(self.tbWidgetGet[nIndex], self.tReturnData[k] == STATE.DONE)
            UIHelper.SetVisible(self.tbImgChoose[nIndex], self.tReturnData[k] == STATE.CAN_GET)
            if k ~= TOTAL_DAYS then
                UIHelper.SetVisible(self.tbWidgetSelcet[k], self.tReturnData[k+1] == STATE.CAN_GET)
            end
        end

    end
end

function UIReturnGift:UpdateBtnState()
    for k, v in ipairs(self.tReturnData) do
        if v == STATE.CAN_GET then
            UIHelper.SetButtonState(self.BtnGetReward, BTN_STATE.Normal)
            return
        end
    end
    UIHelper.SetButtonState(self.BtnGetReward, BTN_STATE.Disable)
end

return UIReturnGift