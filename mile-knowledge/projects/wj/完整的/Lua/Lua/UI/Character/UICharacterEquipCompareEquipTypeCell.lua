-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterEquipCompareEquipTypeCell
-- Date: 2024-05-15 17:31:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICharacterEquipCompareEquipTypeCell = class("UICharacterEquipCompareEquipTypeCell")

function UICharacterEquipCompareEquipTypeCell:OnEnter(nType, funcClickCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType
    self.funcClickCallback = funcClickCallback
    self:UpdateInfo()
end

function UICharacterEquipCompareEquipTypeCell:OnExit()
    self.bInit = false
end

function UICharacterEquipCompareEquipTypeCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogItem, EventType.OnClick, function(btn)
        if self.funcClickCallback then
            self.funcClickCallback(self.nType)
        end
    end)

end

function UICharacterEquipCompareEquipTypeCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICharacterEquipCompareEquipTypeCell:UpdateInfo()
    local szImagePath = EquipToDefaultIcon[self.nType] or ""
    local szName = EquipToName[self.nType] or ""
    UIHelper.SetString(self.LabelNormal, szName)
    UIHelper.SetString(self.LabelUp, szName)

    UIHelper.SetSpriteFrame(self.ImgIconNormal, szImagePath)
    UIHelper.SetSpriteFrame(self.ImgIconUp, szImagePath)
end


return UICharacterEquipCompareEquipTypeCell