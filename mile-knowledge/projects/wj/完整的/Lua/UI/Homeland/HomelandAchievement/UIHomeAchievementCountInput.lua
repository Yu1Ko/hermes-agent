-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeAchievementCountInput
-- Date: 2023-07-19 20:18:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeAchievementCountInput = class("UIHomeAchievementCountInput")

local CommonFragmentChangeRatio = 0.5 --通用碎片转换成普通碎片实际转换比例
local tFurnitureImageFrame = {21, 14, 15, 17, 16, 19, 18, 20}
local nCostFragment = 0

function UIHomeAchievementCountInput:OnEnter(nIndex, szMoneyNum, nCollected, nMaxCollect)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    self.szMoneyNum = szMoneyNum
    self.nCollected = nCollected
    self.nMaxCollect = nMaxCollect

    self:InitInputNum()
    self:UpdateInfo()
end

function UIHomeAchievementCountInput:OnExit()
    self.bInit = false
    Event.Dispatch(EventType.OnHomeAchievementInput)
end

function UIHomeAchievementCountInput:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelHomeAchievementCountInputPop)
    end)

    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function ()
        local nMaxInputCommonChip = tonumber(self.szMoneyNum)
        self.nTextExpend = tonumber(UIHelper.GetText(self.EditPaginate))
        if self.nTextExpend == 0 then
            OutputMessage("MSG_SYS", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_ZERO)
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_ZERO)
            return
        end
        local nCostFragment = self.nTextExpend / CommonFragmentChangeRatio
        local szMessage = FormatString(g_tStrings.STR_SEASON_FURNITURE_FRAGMENT_CONFIRM, nCostFragment, g_tStrings.tSeasonFurName[self.nIndex])
        szMessage = ParseTextHelper.ParseNormalText(szMessage, false)
        UIHelper.ShowConfirm(szMessage, function ()
            if nCostFragment <= nMaxInputCommonChip and self.nTextExpend <= self.nMaxCollect - self.nCollected then
                RemoteCallToServer("On_HomeLand_RevertSeasonPoints", self.nTextExpend, self.nIndex)
            end
            RemoteCallToServer("On_HomeLand_GetSeasonPoints")
            UIMgr.Close(VIEW_ID.PanelHomeAchievementCountInputPop)
        end, nil, true)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditPaginate, function()
        self.nTextExpend = tonumber(UIHelper.GetText(self.EditPaginate))
        if not self.nTextExpend then
            OutputMessage("MSG_SYS", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_NULL)
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_NULL)
            return
        end
        if self.nTextExpend == 0 then
            OutputMessage("MSG_SYS", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_ZERO)
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_ZERO)
            return
        end
        self:UpdateUnderInfo()
        UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
        UIHelper.LayoutDoLayout(self.LayoutMoney)

    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        local nInput = tonumber(UIHelper.GetText(self.EditPaginate)) or 0
        nInput = nInput+1
        UIHelper.SetString(self.EditPaginate, tostring(nInput))
        self:UpdateUnderInfo()
    end)

    UIHelper.BindUIEvent(self.BtnMinus, EventType.OnClick, function ()
        local nInput = tonumber(UIHelper.GetText(self.EditPaginate)) or 0
        if nInput > 0 then
            nInput = nInput-1
        end
        UIHelper.SetString(self.EditPaginate, tostring(nInput))
        if nInput == 0 then
            OutputMessage("MSG_SYS", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_ZERO)
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_ZERO)
        end
        self:UpdateUnderInfo()
    end)
end

function UIHomeAchievementCountInput:RegEvent()
    Event.Reg(self, "HOME_ON_REVERT_SEASON_POINTS", function ()
        local player = GetClientPlayer()
        local szMessage
        if not arg0 then
            szMessage = g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_FAILED
        else
            szMessage = g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_SECCESS
            --player.ApplySetCollection()
        end
        OutputMessage("MSG_SYS", szMessage)
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMessage)
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then return end

        self.nTextExpend = tonumber(UIHelper.GetText(self.EditPaginate))
        if not self.nTextExpend then
            OutputMessage("MSG_SYS", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_NULL)
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_NULL)
            return
        end
        if self.nTextExpend == 0 then
            OutputMessage("MSG_SYS", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_ZERO)
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SEASON_FURNITURE_INPUT_FRAGMENT_ZERO)
            return
        end
        self:UpdateUnderInfo()
        UIHelper.LayoutDoLayout(self.LayoutMoney)
    end)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
end

function UIHomeAchievementCountInput:InitInputNum()
    local nInput = 0
    local nMoneyNum = tonumber(self.szMoneyNum)
    if not nMoneyNum then
        return
    end

	local nMaxNeedCommonChip = math.ceil((self.nMaxCollect - self.nCollected) / CommonFragmentChangeRatio)
    local nChip = math.ceil(nMaxNeedCommonChip * CommonFragmentChangeRatio)
    if nMoneyNum > nMaxNeedCommonChip then
        nInput = nChip
    else
        nInput = math.floor(nMoneyNum * CommonFragmentChangeRatio)
    end
    UIHelper.SetString(self.EditPaginate, tostring(nInput))
end

function UIHomeAchievementCountInput:UpdateInfo()
    self:UpdateTopInfo()
    self:UpdateUnderInfo()
end

function UIHomeAchievementCountInput:UpdateTopInfo()
    local szLabelNum = self.nCollected .. "/" .. self.nMaxCollect
    local nCollecterProgress = self.nCollected / self.nMaxCollect * 100
    local szImgHomeIcon = HomeLandAchievementCellUnderIconImg[self.nIndex]
    local szImgMoneyIcon = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_JieLu.png"
    UIHelper.SetSpriteFrame(self.ImgCountIcon, szImgHomeIcon)
    UIHelper.SetSpriteFrame(self.ImgCountInputIcon, szImgHomeIcon)
    UIHelper.SetSpriteFrame(self.ImgMoneyIcon, szImgMoneyIcon)
    UIHelper.SetProgressBarPercent(self.ProgressBarCount, nCollecterProgress)
    UIHelper.SetString(self.LabelNum, szLabelNum)
    UIHelper.SetString(self.LabelTitle, g_tStrings.tSeasonFurName[self.nIndex])

    local scriptCurrency = UIHelper.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetMoney)
    scriptCurrency:SetLableCount(self.szMoneyNum)
    scriptCurrency:SetCurrencyType(CurrencyType.NormalFragment)
end

function UIHomeAchievementCountInput:UpdateUnderInfo()
    local szUnderLabel = ""
    local nMoneyNum = tonumber(self.szMoneyNum)
    self.nTextExpend = tonumber(UIHelper.GetText(self.EditPaginate)) or 0
    local nCostFragment = math.ceil(self.nTextExpend / CommonFragmentChangeRatio)
	local nMaxNeedCommonChip = math.ceil((self.nMaxCollect - self.nCollected) / CommonFragmentChangeRatio)
    if nMoneyNum > nMaxNeedCommonChip then
        if not self.nTextExpend then
            szUnderLabel = "<color=#ffffff>".."0".."</color>"
            UIHelper.SetString(self.LabelMoneyNum,szUnderLabel)
        else
            if nMoneyNum < nCostFragment then
                OutputMessage("MSG_SYS", g_tStrings.STR_SEASON_FURNITURE_FRAGMENT_LACK)
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SEASON_FURNITURE_FRAGMENT_LACK)
                self.nTextExpend = math.floor(nMaxNeedCommonChip * CommonFragmentChangeRatio)
                UIHelper.SetString(self.EditPaginate, tostring(self.nTextExpend))
                nCostFragment = math.ceil(self.nTextExpend / CommonFragmentChangeRatio)
                szUnderLabel = "<color=#ffffff>"..tostring(nCostFragment).."</color>"
                UIHelper.SetRichText(self.LabelMoneyNum, szUnderLabel)
            else
                if self.nTextExpend >= self.nMaxCollect - self.nCollected then
                    self.nTextExpend = self.nMaxCollect - self.nCollected
                end
                nCostFragment = math.ceil(self.nTextExpend / CommonFragmentChangeRatio)
                UIHelper.SetString(self.EditPaginate, tonumber(self.nTextExpend))
                szUnderLabel = "<color=#ffffff>"..tostring(nCostFragment).."</color>"
                UIHelper.SetRichText(self.LabelMoneyNum, szUnderLabel)
            end
        end
    else
        if not self.nTextExpend then
            szUnderLabel = "<color=#ffffff>".."0".."</color>"
            UIHelper.SetString(self.LabelMoneyNum,szUnderLabel)
        else
            nCostFragment = math.ceil(self.nTextExpend / CommonFragmentChangeRatio)
            if nMoneyNum < nCostFragment then
                OutputMessage("MSG_SYS", g_tStrings.STR_SEASON_FURNITURE_FRAGMENT_LACK)
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_SEASON_FURNITURE_FRAGMENT_LACK)
                self.nTextExpend = math.floor(nMoneyNum * CommonFragmentChangeRatio)
                UIHelper.SetString(self.EditPaginate, tostring(self.nTextExpend))
                nCostFragment = math.ceil(self.nTextExpend / CommonFragmentChangeRatio)
                szUnderLabel = "<color=#ffffff>"..tostring(nCostFragment).."</color>"
                UIHelper.SetRichText(self.LabelMoneyNum, szUnderLabel)
            else
                nCostFragment = math.ceil(self.nTextExpend / CommonFragmentChangeRatio)
                szUnderLabel = "<color=#ffffff>"..tostring(nCostFragment).."</color>"
                UIHelper.SetRichText(self.LabelMoneyNum, szUnderLabel)
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutMoney)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
end


return UIHomeAchievementCountInput