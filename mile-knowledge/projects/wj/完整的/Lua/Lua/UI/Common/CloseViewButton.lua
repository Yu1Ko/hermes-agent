-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CloseViewButton
-- Date: 2023-09-12 15:26:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local CloseViewButton = class("CloseViewButton")

function CloseViewButton:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function CloseViewButton:OnExit()
    self.bInit = false
end

function CloseViewButton:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        if self.szViewID and VIEW_ID[self.szViewID] then
            UIMgr.Close(VIEW_ID[self.szViewID])
            return
        end

        Event.Dispatch("ON_WORLD_MAP_CITY_SELECT", nil, false)
        Event.Dispatch("ON_WORLD_MAP_CITY_HIGHLIGHT", nil, false)
        if self.HideNode then
            UIHelper.SetVisible(self.HideNode, false)
            return
        end

        if not self.RootNode then
            LOG.ERROR("[CloseViewButton]Close view error!This BtnClose not bind RootNode!")
            return
        end

        local scriptView = UIHelper.GetBindScript(self.RootNode)
        if not scriptView then
            LOG.ERROR("[CloseViewButton]Close view error!RootNode does not have any !")
            return
        end

        UIMgr.Close(scriptView)
    end)
end

function CloseViewButton:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

return CloseViewButton