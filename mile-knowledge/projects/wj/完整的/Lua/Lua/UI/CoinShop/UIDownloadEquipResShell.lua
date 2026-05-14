-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDownloadEquipResShell
-- Date: 2023-12-18 10:54:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIDownloadEquipResShell = class("UIDownloadEquipResShell")

function UIDownloadEquipResShell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIDownloadEquipResShell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDownloadEquipResShell:BindUIEvent()

end

function UIDownloadEquipResShell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDownloadEquipResShell:UnRegEvent()
    Timer.DelAllTimer(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDownloadEquipResShell:UpdateInfo()
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    if self.nDynamicID then
        scriptDownload:OnInitWithPackID(self.nDynamicID, self.tConfig)
    elseif self.bRemoteNotExist then
        scriptDownload:OnInitWithHint(self.tConfig)
    end
    self:UpdateVisible()
    Timer.DelTimer(self, self.nTimerID)
    if self.nDynamicID or self.bRemoteNotExist then
        self.nTimerID = Timer.AddCycle(self, 0.1, function()
            self:UpdateVisible()
        end)
    end
end

function UIDownloadEquipResShell:SetInfo(nDynamicID, bRemoteNotExist, tConfig)
    self.nDynamicID = nDynamicID
    self.bRemoteNotExist = bRemoteNotExist
    self.tConfig = tConfig
    self:UpdateInfo()
end

function UIDownloadEquipResShell:UpdateVisible()
    local bVisible = false
    if self.nDynamicID then
        local packState = PakDownloadMgr.GetPackViewState(self.nDynamicID)
        if packState == DOWNLOAD_STATE.NONE then
            if self.fnShowCondition then
                bVisible = self.fnShowCondition(self.tConditionParamsParams)
            else
                bVisible = true
            end
        else
            local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
            bVisible = scriptDownload:GetVisible()
        end
    elseif self.bRemoteNotExist then
        if self.fnShowCondition then
            bVisible = self.fnShowCondition(self.tConditionParamsParams)
        else
            bVisible = true
        end
    end
    local bOldVisible = UIHelper.GetVisible(self._rootNode)
    UIHelper.SetVisible(self._rootNode, bVisible)
    UIHelper.LayoutDoLayout(self.LayoutContent)

    if bOldVisible ~= bVisible and self.fnVisibleChanged then
        self.fnVisibleChanged(bVisible, self.nDynamicID)
    end
end

function UIDownloadEquipResShell:SetShowCondition(fnShowCondition)
    self.fnShowCondition = fnShowCondition
end

function UIDownloadEquipResShell:SetVisibleChangedCallback(fnVisibleChanged)
    self.fnVisibleChanged = fnVisibleChanged
end

function UIDownloadEquipResShell:SetConditionParams(tParams)
    self.tConditionParamsParams = tParams
end

return UIDownloadEquipResShell