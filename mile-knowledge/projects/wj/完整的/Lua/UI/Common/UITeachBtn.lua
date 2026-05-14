-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeachBtn
-- Date: 2023-02-23 09:34:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeachBtn = class("UITeachBtn")

function UITeachBtn:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
end

function UITeachBtn:OnExit()
    self.bInit = false
end

function UITeachBtn:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        if not self.szTeachID or self.szTeachID == "" then
            return
        end
        TeachBoxData.OpenTutorialPanel(tonumber(self.szTeachID))
    end)
end

return UITeachBtn