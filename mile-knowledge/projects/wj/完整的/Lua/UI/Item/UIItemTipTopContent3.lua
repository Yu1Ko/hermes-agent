-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipTopContent3
-- Date: 2023-02-21 09:33:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipTopContent3 = class("UIItemTipTopContent3")
local tbShowGetCurrency = {
    [CurrencyType.GangFunds] = true,
    [CurrencyType.Reputation] = true,
    [CurrencyType.FishExp] = true,
    [CurrencyType.FlowerExp] = true,
    [CurrencyType.SellerExp] = true,
}
local function fnShowGetCurrency(szName)
    return tbShowGetCurrency[szName]
end
function UIItemTipTopContent3:OnEnter(szName , nCount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(szName , nCount)
end

function UIItemTipTopContent3:OnExit()
    self.bInit = false
end

function UIItemTipTopContent3:BindUIEvent()

end

function UIItemTipTopContent3:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipTopContent3:UpdateInfo(szName , nCount)
    if szName == CurrencyType.PersonAthScore then
        UIHelper.SetActiveAndCache(self, self.LayoutItemTipTopContent3, false)
        UIHelper.SetActiveAndCache(self, self.LayoutPVPScore, true)


        local nPlayerID = PlayerData.GetPlayerID()
        local tbArenaInfo = ArenaData.GetCorpsRoleInfo(nPlayerID, ARENA_UI_TYPE.ARENA_2V2)
        local nScore = tbArenaInfo.nMatchLevel or 1000
        UIHelper.SetString(self.Label2 , nScore)

        tbArenaInfo = ArenaData.GetCorpsRoleInfo(nPlayerID, ARENA_UI_TYPE.ARENA_3V3)
        nScore = tbArenaInfo.nMatchLevel or 1000
        UIHelper.SetString(self.Label3 , nScore)

        tbArenaInfo = ArenaData.GetCorpsRoleInfo(nPlayerID, ARENA_UI_TYPE.ARENA_5V5)
        nScore = tbArenaInfo.nMatchLevel or 1000
        UIHelper.SetString(self.Label5 , nScore)
    else
        UIHelper.SetActiveAndCache(self, self.LayoutItemTipTopContent3, true)
        UIHelper.SetActiveAndCache(self, self.LayoutPVPScore, false)

        UIHelper.SetActiveAndCache(self, self.LayoutRow1_Coin, szName ~= CurrencyType.Money)
        UIHelper.SetActiveAndCache(self, self.LayoutRow1_Currency, szName == CurrencyType.Money)
        
        UIHelper.SetString(self.LabelMoney_Zhuan , "当前持有数额")
        if szName == CurrencyType.Money then
            UIHelper.GetBindScript(self.LayoutRow1_Currency):UpdateInfo(szName)
        else
            local currencyLua = UIHelper.GetBindScript(self.LayoutRow1_Coin)
            currencyLua:UpdateInfo(szName)
            if nCount and fnShowGetCurrency(szName) then
                UIHelper.SetString(currencyLua.LabelCoin , nCount)
                UIHelper.SetString(self.LabelMoney_Zhuan , string.format("可获得%s",szName))
            end
        end

        UIHelper.LayoutDoLayout(self.LayoutRow1_Coin)
        UIHelper.LayoutDoLayout(self.LayoutRow1_Currency)
    end
end


return UIItemTipTopContent3