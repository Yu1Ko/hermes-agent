-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldBagSetTitle
-- Date: 2023-05-23 10:13:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldBagSetTitle = class("UITreasureBattleFieldBagSetTitle")

function UITreasureBattleFieldBagSetTitle:OnEnter(tConf, bSwallowTouch)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tConf = tConf
    self.bSwallowTouch = true
    if bSwallowTouch ~= nil then
        self.bSwallowTouch = bSwallowTouch
    end
    self:UpdateInfo()
end

function UITreasureBattleFieldBagSetTitle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldBagSetTitle:BindUIEvent()
    
end

function UITreasureBattleFieldBagSetTitle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITreasureBattleFieldBagSetTitle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldBagSetTitle:UpdateInfo()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    UIHelper.SetString(self.LabelOptionTitle, self.tConf.szName)
    for _, tSub in ipairs(self.tConf) do
        local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetSetContentCell, self.LayoutContent, tSub)
        UIHelper.SetSwallowTouches(cell.ToggleSelect, self.bSwallowTouch)
        if tSub.bToggleGroup then
            UIHelper.ToggleGroupAddToggle(self.ToggleGroup, cell.ToggleSelect)
            if tSub.bChecked then
                UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, cell.ToggleSelect)
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutContent)
    UIHelper.LayoutDoLayout(self.WidgetSetContent)
end


return UITreasureBattleFieldBagSetTitle