-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractSettleStaticDataCell
-- Date: 2025-04-01 11:40:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIExtractSettleStaticDataCell = class("UIExtractSettleStaticDataCell")

function UIExtractSettleStaticDataCell:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbData = tbData
    self:UpdateInfo()
end

function UIExtractSettleStaticDataCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractSettleStaticDataCell:BindUIEvent()
    
end

function UIExtractSettleStaticDataCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIExtractSettleStaticDataCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractSettleStaticDataCell:UpdateInfo()
    local szTitle = self.tbData.szTitle
    local szValue = self.tbData.szValue

    UIHelper.SetString(self.LabelInfoName, szTitle)
    UIHelper.SetString(self.LabelInfo, szValue)
end


return UIExtractSettleStaticDataCell