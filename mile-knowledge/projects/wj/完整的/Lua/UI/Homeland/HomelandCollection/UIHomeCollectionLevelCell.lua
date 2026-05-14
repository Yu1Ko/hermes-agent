-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeCollectionLevelCell
-- Date: 2023-08-14 09:52:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomeCollectionLevelCell = class("UIHomeCollectionLevelCell")

function UIHomeCollectionLevelCell:OnEnter(szLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szLevel = szLevel
    self:UpdateInfo()
end

function UIHomeCollectionLevelCell:OnExit()
    self.bInit = false
end

function UIHomeCollectionLevelCell:BindUIEvent()
    
end

function UIHomeCollectionLevelCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomeCollectionLevelCell:UpdateInfo()
    local tbString = SplitString(self.szLevel, ":     ")
    local szLevel = tbString[1]
    local szPoint = tbString[2]
    -- if szLevel == "周以垣墻" then
    --     UIHelper.SetString(self.LabelIntegral02, "周以垣墙")
    -- else
    UIHelper.SetString(self.LabelIntegral02, szLevel)
    -- end
    UIHelper.SetString(self.LabelIntegral16, szPoint)
end


return UIHomeCollectionLevelCell