-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandInteractFoodPriceCell
-- Date: 2023-08-24 17:14:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandInteractFoodPriceCell = class("UIHomelandInteractFoodPriceCell")

function UIHomelandInteractFoodPriceCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetEditboxTextHorizontalAlign(self.EditBoxNum, TextHAlignment.CENTER)
    end

    self:UpdateInfo()
end

function UIHomelandInteractFoodPriceCell:OnExit()
    self.bInit = false
end

function UIHomelandInteractFoodPriceCell:BindUIEvent()
    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBoxNum, function()
            self:OnEditBoxEnded()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBoxNum, function()
            self:OnEditBoxEnded()
        end)
    end
end

function UIHomelandInteractFoodPriceCell:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardConfirmed, function (editBox, nCurNum)
        if editBox == self.EditBoxNum then
            self:OnEditBoxEnded()
        end
    end)
end

function UIHomelandInteractFoodPriceCell:UpdateInfo()
    local nCost = HomelandMiniGameData.GetMiniGameCost()
    UIHelper.SetString(self.EditBoxNum, tostring(nCost))
end


function UIHomelandInteractFoodPriceCell:OnEditBoxEnded()
    local szCount = UIHelper.GetString(self.EditBoxNum)
    local nCount = tonumber(szCount) or 0

    UIHelper.SetString(self.EditBoxNum, tostring(nCount))

    HomelandMiniGameData.nCost = nCount
    HomelandMiniGameData.GameProtocol(30, 1, true)
end


return UIHomelandInteractFoodPriceCell