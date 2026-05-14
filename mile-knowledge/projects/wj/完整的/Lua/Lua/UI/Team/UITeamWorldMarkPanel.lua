-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamWorldMarkPanel
-- Date: 2023-08-22 16:51:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeamWorldMarkPanel = class("UITeamWorldMarkPanel")

function UITeamWorldMarkPanel:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    RemoteCallToServer("On_Mobile_GetSceneMarkNum")

    for _, btn in ipairs(self.tBtnMark) do
        UIHelper.SetVisible(btn, false)
    end
end

function UITeamWorldMarkPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamWorldMarkPanel:BindUIEvent()
    for i, btn in ipairs(self.tBtnMark) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
           TeamData.CancelWorldMarkID(i)
        end)

    end

    UIHelper.BindUIEvent(self.BtnCleanUp, EventType.OnClick, function()
        TeamData.CancelWorldMarkAll()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UITeamWorldMarkPanel:RegEvent()
    Event.Reg(self, EventType.OnGetWorldMarkInfo, function ()
        Timer.AddFrame(self, 1, function ()
            self:UpdateInfo()
        end)
    end)
end

function UITeamWorldMarkPanel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamWorldMarkPanel:UpdateInfo()
    local bEmpty = true
    for i, btn in ipairs(self.tBtnMark) do
        local bFound = TeamData.CheckWorldMarkID(i)
        UIHelper.SetVisible(btn, bFound)
        if bFound then
            bEmpty = false
        end
    end
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.SetVisible(self.WidgetMarkList, not bEmpty)
    UIHelper.LayoutDoLayout(self.LayoutMarkList)
end


return UITeamWorldMarkPanel