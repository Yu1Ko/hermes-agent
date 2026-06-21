-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildErrorItemListCategoryCell
-- Date: 2023-05-29 10:39:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildErrorItemListCategoryCell = class("UIHomelandBuildErrorItemListCategoryCell")

local Key2Name = {
    ["CanArchBuy"] = "园宅币购买",
    ["CanCoinBuy"] = "通宝购买",
    ["SpecialArchBuy"] = "园宅币复购-已收集",
    ["GetSpecial"] = "特定来源",
    ["LevelOverflow"] = "超出当前等级",
    ["CatgOverflow"] = "超出分类最大摆放数量",
}
function UIHomelandBuildErrorItemListCategoryCell:OnEnter(DataModel, szKey)
    self.DataModel = DataModel
    self.szKey = szKey

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildErrorItemListCategoryCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildErrorItemListCategoryCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSelect, EventType.OnClick, function ()
        self.DataModel.szChoose = self.szKey
        Event.Dispatch("LUA_HOMELAND_FRESH_ITEM_LIST")
    end)
end

function UIHomelandBuildErrorItemListCategoryCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildErrorItemListCategoryCell:UpdateInfo()
    UIHelper.SetString(self.LabelCategoryName, Key2Name[self.szKey])
    UIHelper.SetString(self.LabelCategoryNameSelect, Key2Name[self.szKey])

    UIHelper.SetString(self.LabelCategoryNum, tostring(#self.DataModel.tErrorList["t"..self.szKey]))
    UIHelper.SetString(self.LabelCategoryNumSelect, tostring(#self.DataModel.tErrorList["t"..self.szKey]))

end


return UIHomelandBuildErrorItemListCategoryCell