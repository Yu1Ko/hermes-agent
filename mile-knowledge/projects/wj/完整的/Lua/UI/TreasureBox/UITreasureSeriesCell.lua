-- ---------------------------------------------------------------------------------
-- 宝箱奖励系列cell
-- WidgetTreasureSeries
-- ---------------------------------------------------------------------------------

local UITreasureSeriesCell = class("UITreasureSeriesCell")

function UITreasureSeriesCell:_LuaBindList()
    self.ToggleTreasureSeries   = self.ToggleTreasureSeries --- toggle
    self.LabelNomal             = self.LabelNomal --- 像韵·不知系列（0/4)
    self.LabelSelected          = self.LabelSelected --- 像韵·不知系列（0/4)
end

function UITreasureSeriesCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITreasureSeriesCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureSeriesCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleTreasureSeries, EventType.OnSelectChanged, function(_,bSelected)
        if bSelected and self.fnCallBack then
            self.fnCallBack()
        end
	end)
end

function UITreasureSeriesCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureSeriesCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureSeriesCell:UpdateInfo(tInfo, nHave)
    local nAll = #tInfo
    -- local nHave = 0
    -- for _, tAward in ipairs(tInfo) do
    --     local bHave = TreasureBoxData.IsHaveItem(tAward)
    --     if bHave then
    --         nHave = nHave + 1
    --     end
    -- end
    local szName = UIHelper.GBKToUTF8(tInfo[1].szContentType)
    local szShow = szName .. "(" .. nHave .. "/" .. nAll .. ")"
    UIHelper.SetRichText(self.LabelNomal, "<color=#AED9E0>" .. szShow)
    UIHelper.SetRichText(self.LabelSelected, szShow)
end

function UITreasureSeriesCell:SetCallBack(func)
    self.fnCallBack = func
end


return UITreasureSeriesCell