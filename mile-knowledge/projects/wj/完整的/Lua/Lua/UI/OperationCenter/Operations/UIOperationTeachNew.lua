-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationTeachNew
-- Date: 2026-04-08 15:43:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationTeachNew = class("UIOperationTeachNew")

local BTN_ID = {
    [1] = 144,
    [2] = 145,
}

function UIOperationTeachNew:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    self.scriptContentScrollWide = self.tComponentContext.tScriptLayoutTop[1]
    if self.scriptContentScrollWide then
        self.scriptContentScrollWide:SetToggleSelectCallback(function(nIndex)
            self:OnTabChanged(nIndex)
        end)
    end

    self:UpdateInfo()
end

function UIOperationTeachNew:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationTeachNew:BindUIEvent()

end

function UIOperationTeachNew:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationTeachNew:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationTeachNew:UpdateInfo()


end

function UIOperationTeachNew:OnTabChanged(nIndex)
    if Platform.IsMobile() then
        self.tComponentContext.scriptCenter:UpdateButton(1, BTN_ID[nIndex])
    end
end


return UIOperationTeachNew