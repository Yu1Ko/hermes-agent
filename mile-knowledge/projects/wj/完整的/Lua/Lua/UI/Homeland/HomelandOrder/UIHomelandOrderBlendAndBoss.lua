-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOrderBlendAndBoss
-- Date: 2024-01-15 15:49:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandOrderBlendAndBoss = class("UIHomelandOrderBlendAndBoss")

function UIHomelandOrderBlendAndBoss:OnEnter(DataModel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.DataModel = DataModel
end

function UIHomelandOrderBlendAndBoss:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandOrderBlendAndBoss:BindUIEvent()

end

function UIHomelandOrderBlendAndBoss:RegEvent()
    Event.Reg(self, EventType.OnHomeOrderSelectedCell, function (dwID, nType, nIndex)
        self.nSelectIndex = nIndex
    end)

    Event.Reg(self, EventType.OnHomeOrderSelectedCellIndex, function (nIndex)
        self.nSelectIndex = nIndex
        self:UpdateInfo(self.nTypeIndex)
    end)
end

function UIHomelandOrderBlendAndBoss:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIHomelandOrderBlendAndBoss:UpdateInfo(nTypeIndex)
    self.nTypeIndex = nTypeIndex
    self.nSelectIndex = self.nSelectIndex or 1
    self.tbScriptCell = {}
    UIHelper.RemoveAllChildren(self.ScrollViewBlendAndBoss)
    if nTypeIndex == HLORDER_TYPE.TONG then
        return
    end
    local bEmpty = true
    local tOrderList = self.DataModel.GetOrderDataList(nTypeIndex)
    for index, tbOrderInfo in ipairs(tOrderList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBlendAndBossCell, self.ScrollViewBlendAndBoss)
        local tInfo = self.DataModel.GetOrderInfo(tbOrderInfo.dwID, nTypeIndex)
        local tData = self.DataModel.GetOrderData(nTypeIndex, index)
        tData.bOwner = self.DataModel.bOwner
        script:OnEnter(tbOrderInfo, tInfo, index)
        UIHelper.SetToggleGroupIndex(script.ToggleQuality, ToggleGroupIndex.HomelandOrderItem)
        table.insert(self.tbScriptCell, script)
        bEmpty = false
    end
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewBlendAndBoss)
    if self.tbScriptCell[self.nSelectIndex] then
        self.tbScriptCell[self.nSelectIndex]:SetSelected(true)
    end
end

return UIHomelandOrderBlendAndBoss