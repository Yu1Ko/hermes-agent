-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWuLinTongJianCell
-- Date: 2024-04-28 09:53:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWuLinTongJianCell = class("UIWuLinTongJianCell")

function UIWuLinTongJianCell:OnEnter(bVisible)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if bVisible then
        for k, v in ipairs(self.tbCellbg) do
            UIHelper.SetVisible(v, false)
        end
    end
end

function UIWuLinTongJianCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWuLinTongJianCell:BindUIEvent()

end

function UIWuLinTongJianCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWuLinTongJianCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWuLinTongJianCell:UpdateInfo()

end


return UIWuLinTongJianCell