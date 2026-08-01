-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICurrencyMgrView
-- Date: 2022-12-30 15:32:57
-- Desc: 货币管理界面，入口C界面角色
-- ---------------------------------------------------------------------------------

local UICurrencyMgrView = class("UICurrencyMgrView")
-- 暂时先全部统一获取
local tbCurrencyType =
{
    CurrencyType.Coin,
    CurrencyType.Money,
	CurrencyType.Train,
	CurrencyType.Vigor,
    CurrencyType.TitlePoint,
	CurrencyType.Prestige,
	CurrencyType.Justice,
	CurrencyType.Architecture,
    CurrencyType.MentorAward,
    CurrencyType.Contribution,
    --CurrencyType.Crystal,
}

if AppReviewMgr.IsReview() then
    tbCurrencyType =
    {
        CurrencyType.Coin,
        CurrencyType.Money,
        CurrencyType.Train,
        CurrencyType.Vigor,
        CurrencyType.TitlePoint,
        CurrencyType.Prestige,
        CurrencyType.Justice,
        CurrencyType.MentorAward,
        --CurrencyType.Crystal,
    }
end

local MAX_COUNT = 2

function UICurrencyMgrView:OnEnter(bShowSetting)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo()

    if bShowSetting == true then
        UIHelper.SetSelected(self.TogSetting, true)
    end
end

function UICurrencyMgrView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICurrencyMgrView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSetting, EventType.OnSelectChanged, function(tog, bSelected)
        UIHelper.SetString(self.LabelMainTitle, bSelected and "背包货币显示设置" or "货币收集")
        UIHelper.LayoutDoLayout(self.LayoutTittle)

        self:ShowSetting(bSelected)
    end)
    
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)
end

function UICurrencyMgrView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICurrencyMgrView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICurrencyMgrView:UpdateInfo()
    self.tCellScripts = {}
    self.luaMoney = UIHelper.GetBindScript(self.LayoutCurrency)
    self.luaCommonCoin = UIHelper.GetBindScript(self.LayoutCoin)
    self.SelectedCell = nil
    self.nSelectMoneyType = -1
    local CellClickCallback = function(moneyType , cell)
        if self.nSelectMoneyType ~= moneyType then
            self.nSelectMoneyType = moneyType
            if  self.SelectedCell then
                self.SelectedCell:UpdateSelectState(false)
            end

            self.SelectedCell = cell
            self.SelectedCell:UpdateSelectState(true)
        end

        local szCurrencyName = CurrencyData.GetCurrencyName(moneyType)
        UIHelper.SetString(self.LabelTitle , szCurrencyName)
        UIHelper.SetActiveAndCache(self,self.LayoutCurrency , moneyType == CurrencyType.Money)
        UIHelper.SetActiveAndCache(self,self.LayoutCoin , moneyType ~= CurrencyType.Money)
        if moneyType == CurrencyType.Money then
            self.luaMoney:UpdateInfo(moneyType)
            UIHelper.SetSpriteFrame(self.ImgIconMoney, CurrencyData.GetCurCurrencyIconPath())
        else
            self.luaCommonCoin:UpdateInfo(moneyType)
            UIHelper.SetSpriteFrame(self.ImgIconMoney, CurrencyData.tbImageBigIcon[moneyType])
        end

        self.sourceDescCell:UpdateContent(CurrencyData.tbSourceDesc[moneyType])
        self.purposeDescCell:UpdateContent(CurrencyData.tbPurposeDesc[moneyType])
        if CurrencyData.tbGetLimit[moneyType] then
            self.getLimitCell:UpdateContent(string.format(CurrencyData.tbGetLimit[moneyType] , CurrencyData.GetCurCurrencyLimit(moneyType)))
        end
        UIHelper.SetActiveAndCache(self , self.getLimitCell._rootNode ,CurrencyData.tbGetLimit[moneyType] ~= nil)
        UIHelper.ScrollViewDoLayout(self.ScrollViewMoneyDescription)
        UIHelper.ScrollToTop(self.ScrollViewMoneyDescription, 0)

        UIHelper.LayoutDoLayout(self.LayoutCoin)
    end
    self.getLimitCell = UIMgr.AddPrefab(PREFAB_ID.WidgetTipsWithSubtitleContentCell, self.LayoutMoneyDescription)
    self.sourceDescCell = UIMgr.AddPrefab(PREFAB_ID.WidgetTipsWithSubtitleContentCell, self.LayoutMoneyDescription)
    self.purposeDescCell = UIMgr.AddPrefab(PREFAB_ID.WidgetTipsWithSubtitleContentCell, self.LayoutMoneyDescription)
    self.sourceDescCell:UpdateTitle("来源")
    self.purposeDescCell:UpdateTitle("用途")
    self.getLimitCell:UpdateTitle("获取")
    for k, v in pairs(tbCurrencyType) do
        local cell = UIMgr.AddPrefab(PREFAB_ID.WidgetMoneyCell, self.LayoutMoneyList)
        cell:UpdateInfo(v, CellClickCallback)
        if k == 1 then
            CellClickCallback(v, cell)
        end
        table.insert(self.tCellScripts, cell)
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewMoneyList)
    UIHelper.ScrollViewDoLayout(self.ScrollViewMoneyDescription)
    UIHelper.ScrollToTop(self.ScrollViewMoneyList, 0)
	UIHelper.ScrollToTop(self.ScrollViewMoneyDescription, 0)
end

function UICurrencyMgrView:UpdateSettingState()
    local tbSelected = clone(Storage.Bag.tbSelectedCurrencyNew)
    local bMaxLen = table.get_len(tbSelected) >= MAX_COUNT
    for _, script in ipairs(self.tCellScripts) do
        local bInList = tbSelected[script.nMoneyType]
        local fnSelected = function(tog, bSelected)
            if bSelected then
                tbSelected[script.nMoneyType] = true
            else
                tbSelected[script.nMoneyType] = nil
            end

            if table.get_len(tbSelected) > 0 then
                Storage.Bag.tbSelectedCurrencyNew = tbSelected
                Storage.Bag.Flush()
                self:UpdateSettingState()
                Event.Dispatch(EventType.OnCurrencyChange)
            else
                Timer.AddFrame(self, 1, function()
                    TipsHelper.ShowNormalTip("至少需要选择1种货币")
                end)
            end
        end

        local bDisable = not bInList and bMaxLen

        UIHelper.SetVisible(script.ImgForbidden, bDisable)
        UIHelper.SetEnable(script.TogMoneySettingSelected, not bDisable)

        UIHelper.SetSelected(script.TogMoneySettingSelected, bInList, false)
        UIHelper.BindUIEvent(script.TogMoneySettingSelected, EventType.OnSelectChanged, fnSelected)
    end
end

function UICurrencyMgrView:ShowSetting(bSetting)
    UIHelper.SetVisible(self.LabelMoneySettingTip, bSetting)
    for _, script in ipairs(self.tCellScripts) do
        UIHelper.SetVisible(script.TogMoneySettingSelected, bSetting)
    end

    if bSetting then
        self:UpdateSettingState()
    end
end

return UICurrencyMgrView