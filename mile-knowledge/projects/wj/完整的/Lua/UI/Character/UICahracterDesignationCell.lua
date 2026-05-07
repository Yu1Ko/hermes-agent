-- ---------------------------------------------------------------------------------
-- Name: UICahracterDesignationCell
-- PanelName: WidgetDecorationCell
-- Decs: 称号特效节点
-- ---------------------------------------------------------------------------------

local UICahracterDesignationCell = class("UICahracterDesignationCell")

function UICahracterDesignationCell:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tInfo)
end

function UICahracterDesignationCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICahracterDesignationCell:BindUIEvent()
   
end

function UICahracterDesignationCell:RegEvent()

end

function UICahracterDesignationCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICahracterDesignationCell:UpdateInfo(tInfo)
    UIHelper.UpdateDesignationDecorationFarme(tInfo, self.ImgFrameNormalBg1, self.SFXFrameBgAll, self.LabelName)
end

function UICahracterDesignationCell:Adjust(widgetNode)
    local nodeWidth = UIHelper.GetWidth(widgetNode)
    UIHelper.SetPositionX(self._rootNode, nodeWidth*0.5)
end


return UICahracterDesignationCell