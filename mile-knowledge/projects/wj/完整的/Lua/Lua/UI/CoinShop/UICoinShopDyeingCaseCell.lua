-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopDyeingCaseCell
-- Date: 2023-11-21 20:09:49
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_NAME_STRING_LEN = 8
local DEL_COUNT_DOWN = 5

local INDEX_TO_COST_TYPE = {
    [1] = HAIR_CUSTOM_DYEING_TYPE.BASE_COLOR,
    [2] = HAIR_CUSTOM_DYEING_TYPE.HAIR_COLOR,
    [3] = HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR,
}

local DEFAULT_DATA          = {
    [HAIR_CUSTOM_DYEING_TYPE.BASE_ROUGHNESS]    = 20,
    [HAIR_CUSTOM_DYEING_TYPE.BASE_HIGHLIGHT]    = 0,
    [HAIR_CUSTOM_DYEING_TYPE.BASE_ABLEDO_COLORA]    = 120,
    [HAIR_CUSTOM_DYEING_TYPE.BASE_SPECULAR_COLORA]    = 120,

    [HAIR_CUSTOM_DYEING_TYPE.HAIR_ROUGHNESS]    = 20,
    [HAIR_CUSTOM_DYEING_TYPE.HAIR_HIGHLIGHT]    = 0,
    [HAIR_CUSTOM_DYEING_TYPE.HAIR_ABLEDO_COLORA]    = 120,
    [HAIR_CUSTOM_DYEING_TYPE.HAIR_SPECULAR_COLORA]    = 120,

    [HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLORA]    = 127,
    [HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR_STRENGTH]    = 127,
}

local UICoinShopDyeingCaseCell = class("UICoinShopDyeingCaseCell")

function UICoinShopDyeingCaseCell:OnEnter(nHairID, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nHairID = nHairID
    self.nIndex = nIndex
    self:UpdateInfo()
end

function UICoinShopDyeingCaseCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICoinShopDyeingCaseCell:BindUIEvent()
    UIHelper.SetTouchDownHideTips(self.TogHair, false)
    UIHelper.SetTouchDownHideTips(self.BtnEditName, false)
    UIHelper.SetTouchDownHideTips(self.BtnModifyDyeing, false)
    UIHelper.SetTouchDownHideTips(self.BtnDelete, false)
    UIHelper.SetSwallowTouches(self.BtnEditName, true)
    UIHelper.SetSwallowTouches(self.BtnModifyDyeing, true)
    UIHelper.SetSwallowTouches(self.BtnDelete, true)

    UIHelper.BindUIEvent(self.TogHair, EventType.OnSelectChanged, function (tog, bSelected)
        if self.tbData and bSelected then
            FireUIEvent("SET_HAIR_DYEING_DATA", self.nHairID, self.tbData)
        end

        if self.fnOnSelectChanged then
            self.fnOnSelectChanged(self.nIndex, bSelected)
        end
    end)

    UIHelper.BindUIEvent(self.BtnEditName, EventType.OnClick, function ()
        local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, self:GetName(), g_tStrings.STR_FRIEND_INPUT_MARK, function (szText)
            if not szText or szText == "" or not Storage.tHairDyeingName then
                return
            end

            if not Storage.tHairDyeingName[self.nHairID] then
                Storage.tHairDyeingName[self.nHairID] = {}
            end

            Storage.tHairDyeingName[self.nHairID][self.nIndex] = szText
            Storage.tHairDyeingName.Flush()
            self:UpdateInfo()
        end)
        
        editBox:SetTitle("修改备注")
        editBox:SetMaxLength(8)
    end)

    UIHelper.BindUIEvent(self.BtnModifyDyeing, EventType.OnClick, function ()
        local nCode = self:EquipCase()
        if nCode == HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS then
            Timer.Add(HairDyeingData, 0.1, function ()
                Event.Dispatch(EventType.OnCoinShopStartBuildHairDye, self.nHairID)
            end)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
            return
        end

        local szName        = CoinShopHair.GetHairText(self.nHairID)
        local szDyeingName  = self:GetName(self.nHairID, self.nIndex)
        local szMsg         = FormatString(g_tStrings.STR_HAIR_DYEING_DELETE, szName, szDyeingName)

        szMsg = ParseTextHelper.ParseNormalText(szMsg, false)
        local script = UIHelper.ShowConfirm(szMsg, function ()
            RemoteCallToServer("On_HairDyeing_Delete", self.nHairID, self.nIndex)
        end, nil, true)
        script:SetButtonCountDown(DEL_COUNT_DOWN)
    end)
end

function UICoinShopDyeingCaseCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICoinShopDyeingCaseCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------


function UICoinShopDyeingCaseCell:UpdateInfo()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if self.nIndex == 0 then
        local tbData = {}
        for i = 0, HAIR_CUSTOM_DYEING_TYPE.TOTAL - 1 do
            tbData[i] = 0
        end
        for k, v in pairs(DEFAULT_DATA) do
            tbData[k] = v
        end

        local szName = CoinShopHair.GetHairText(self.nHairID)
        szName = UIHelper.GBKToUTF8(szName)
        self.tbData = clone(tbData)
        UIHelper.SetString(self.LabelHairName, szName, MAX_NAME_STRING_LEN)
        UIHelper.SetString(self.LabelNameSelected, szName, MAX_NAME_STRING_LEN)
        UIHelper.SetVisible(self.BtnEditName, false)
        UIHelper.SetVisible(self.BtnDelete, false)
        for i, img in ipairs(self.tbColorImg) do
            UIHelper.SetVisible(img, false)
        end
        return
    end

    local tList = hPlayer.GetHairCustomDyeingList(self.nHairID)
    if not tList then
        return
    end

    local nFreeEndTime = hPlayer.GetHairCustomDyeingFreeEndTime(self.nHairID, self.nIndex)
    local bIsFree = nFreeEndTime > 0 and nFreeEndTime > GetCurrentTime()
    UIHelper.SetVisible(self.ImgLimitedFree, false)
    UIHelper.SetVisible(self.RichTextCountDown, false)
    if bIsFree then
        self:UpdateFreeTimer(nFreeEndTime)
    end
    -- UIHelper.SetVisible(self.BtnModifyDyeing, bIsFree)

    local nNowDyeingIndex = hPlayer.GetEquippedHairCustomDyeingIndex(self.nHairID) --玩家当前装备的方案
    UIHelper.SetVisible(self.BtnDelete, self.nIndex ~= nNowDyeingIndex)

    local szName = self:GetName()
    UIHelper.SetString(self.LabelHairName, szName, MAX_NAME_STRING_LEN)
    UIHelper.SetString(self.LabelNameSelected, szName, MAX_NAME_STRING_LEN)

    local tData = tList[self.nIndex]
    self.tbData = tData

    for i, nColorType in ipairs(INDEX_TO_COST_TYPE) do
        local nColorID = tData[nColorType]
        local bDecoration = nColorType == HAIR_CUSTOM_DYEING_TYPE.DECORATION_COLOR
        local bHave  = nColorID and nColorID ~= 0
        local ImgColor = self.tbColorImg[i]
        UIHelper.SetVisible(ImgColor, bHave)
        if bHave then
            local tColorInfo = bDecoration and Table_GetDyeingDecorationColorInfo(nColorID) or Table_GetDyeingHairColorInfo(nColorID)
            UIHelper.SetColor(ImgColor, cc.c3b(tColorInfo.nR, tColorInfo.nG, tColorInfo.nB))
        end
    end
end

function UICoinShopDyeingCaseCell:GetName()
    if not self.nHairID or not self.nIndex then
        return ""
    end

    local szName = g_tStrings.STR_HAIR_DYEING_DEFAULT_NAME .. self.nIndex
    if Storage.tHairDyeingName[self.nHairID] and Storage.tHairDyeingName[self.nHairID][self.nIndex] then
        szName = Storage.tHairDyeingName[self.nHairID][self.nIndex]
    end
    return szName
end

function UICoinShopDyeingCaseCell:EquipCase()
    if not self.nHairID or not self.nIndex then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local hHairCustomDyeingManager = GetHairCustomDyeingManager()
    if not hHairCustomDyeingManager then
        return
    end
    local nCode = hHairCustomDyeingManager.Equip(self.nHairID, self.nIndex)
    if nCode ~= HAIR_CUSTOM_DYEING_ERROR_CODE.SUCCESS then
        local szMsg = g_tStrings.tHairDyeingEquipNotify[nCode]
        TipsHelper.ShowNormalTip(szMsg)
    end
    return nCode
end

function UICoinShopDyeingCaseCell:UpdateFreeTimer(nFreeEndTime)
    if self.nFreeEndTimer then
        UIHelper.SetVisible(self.ImgLimitedFree, false)
        UIHelper.SetVisible(self.RichTextCountDown, false)
        Timer.DelTimer(self, self.nFreeEndTimer)
        self.nFreeEndTimer = nil
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local nFreeEndTime = hPlayer.GetHairCustomDyeingFreeEndTime(self.nHairID, self.nIndex)
    local fnUpdateTimer = function()
        nFreeEndTime = hPlayer.GetHairCustomDyeingFreeEndTime(self.nHairID, self.nIndex)
        local nLeftTime = nFreeEndTime - GetCurrentTime()
        if nLeftTime <= 0 then
            UIHelper.SetVisible(self.ImgLimitedFree, false)
            UIHelper.SetVisible(self.RichTextCountDown, false)
            Timer.DelTimer(self, self.nFreeEndTimer)
            self.nFreeEndTimer = nil
            return
        end

        local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecond(nLeftTime)
        local szTime = string.format(g_tStrings.STR_TIME_14, nHour, nMinute, nSecond)
        UIHelper.SetVisible(self.ImgLimitedFree, true)
        UIHelper.SetVisible(self.RichTextCountDown, true)
        UIHelper.SetRichText(self.RichTextCountDown, "<color=#FF9696>" .. szTime.."</color>")
    end

    local nLeftTime = nFreeEndTime - GetCurrentTime()
    if nLeftTime <= 0 then
        return
    end

    self.nFreeEndTimer = Timer.AddFrameCycle(self, 5, function()
        fnUpdateTimer()
    end)
end

function UICoinShopDyeingCaseCell:SetOnSelectChanged(fnOnSelectChanged)
    self.fnOnSelectChanged = fnOnSelectChanged
end

return UICoinShopDyeingCaseCell