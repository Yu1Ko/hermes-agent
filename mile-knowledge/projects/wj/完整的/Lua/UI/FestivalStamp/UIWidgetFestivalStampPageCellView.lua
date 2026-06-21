-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetFestivalStampPageCellView
-- Date: 2025-05-15 11:52:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetFestivalStampPageCellView = class("UIWidgetFestivalStampPageCellView")

function UIWidgetFestivalStampPageCellView:OnEnter(tbItemList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbItemList = tbItemList
    self:UpdateInfo()
end

function UIWidgetFestivalStampPageCellView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetFestivalStampPageCellView:BindUIEvent()
    
end

function UIWidgetFestivalStampPageCellView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetFestivalStampPageCellView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetFestivalStampPageCellView:UpdateInfo()
 
    for nIndex, node in ipairs(self.tbWidgetStamp) do
        local tbItem = self.tbItemList[nIndex]
        if tbItem then
            local script = UIHelper.GetBindScript(node)
            if script then
                script:OnEnter(tbItem)
            end
        else
            UIHelper.SetVisible(node, false)        
        end
    end


end


return UIWidgetFestivalStampPageCellView