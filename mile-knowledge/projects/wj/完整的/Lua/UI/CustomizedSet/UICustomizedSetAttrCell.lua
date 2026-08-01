-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetAttrCell
-- Date: 2024-07-16 11:34:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetAttrCell = class("UICustomizedSetAttrCell")

function UICustomizedSetAttrCell:OnEnter(szAttriName, szAttriValue, bMainAttr)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bMainAttr = bMainAttr
    self.szAttriName = szAttriName
    self.szAttriValue = szAttriValue
    self:UpdateInfo()
end

function UICustomizedSetAttrCell:OnExit()
    self.bInit = false
end

function UICustomizedSetAttrCell:BindUIEvent()

end

function UICustomizedSetAttrCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICustomizedSetAttrCell:UpdateInfo()
    UIHelper.SetString(self.LabelAttriTitle, self.szAttriName)
    UIHelper.SetString(self.LabelAttriNum, self.szAttriValue)

    if self.tbImgBg then
        UIHelper.SetVisible(self.tbImgBg[1], self.bMainAttr)
        UIHelper.SetVisible(self.tbImgBg[2], not self.bMainAttr)
    end
end


return UICustomizedSetAttrCell