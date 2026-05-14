-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldBagSetItem
-- Date: 2023-05-23 10:47:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldBagSetItem = class("UITreasureBattleFieldBagSetItem")

function UITreasureBattleFieldBagSetItem:OnEnter(tConf)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tConf = tConf
    self:UpdateInfo()
end

function UITreasureBattleFieldBagSetItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldBagSetItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if IsFunction(self.tConf.fnAction) then
            self.tConf.fnAction(bSelected)
        end
    end)
end

function UITreasureBattleFieldBagSetItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBattleFieldBagSetItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldBagSetItem:UpdateInfo()
    UIHelper.SetString(self.LabelOption, self.tConf.szName)
    if not self.tConf.bToggleGroup then
        UIHelper.SetSelected(self.ToggleSelect, self.tConf.bChecked, false)
    end
end


return UITreasureBattleFieldBagSetItem