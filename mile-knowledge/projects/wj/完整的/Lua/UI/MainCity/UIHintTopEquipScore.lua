-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIHintTopEquipScore
-- Date: 2023-05-31 10:32:49
-- Desc: 攻击 治疗 防御 变化提示
-- ---------------------------------------------------------------------------------

local UIHintTopEquipScore = class("UIHintTopEquipScore")

function UIHintTopEquipScore:OnEnter(tbData, callback)
    if not tbData then
        return
    end

    self.tbData = tbData
    self.callback = callback

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHintTopEquipScore:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHintTopEquipScore:BindUIEvent()
    
end

function UIHintTopEquipScore:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHintTopEquipScore:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHintTopEquipScore:UpdateInfo()
    Timer.DelTimer(self, self.nTimerID)
    self.nTimerID = Timer.Add(self, 5, function()
        if IsFunction(self.callback) then
            self.callback()
        end
    end)
    
    for i = 1, 3 do
        local widget = self.tbWidgetList[i]
        local tbOneData = self.tbData[i]
        UIHelper.SetVisible(widget, false)

        if widget and tbOneData then
            UIHelper.SetVisible(widget, true)
            local labelValue = self.tbLabelValueList[i]
            local labelIncrease = self.tbLabelIncreaseList[i]
            local labelReduce = self.tbLabelReduceList[i]

            local bIncrease = tbOneData.delta > 0 

            UIHelper.SetString(labelValue, tbOneData.value)
            UIHelper.SetString(labelIncrease, math.abs(tbOneData.delta))
            UIHelper.SetVisible(labelIncrease, bIncrease)
            UIHelper.SetVisible(labelReduce, not bIncrease)
            UIHelper.SetString(labelReduce, math.abs(tbOneData.delta))
        end
    end

    UIHelper.LayoutDoLayout(self.Layout)
end


return UIHintTopEquipScore