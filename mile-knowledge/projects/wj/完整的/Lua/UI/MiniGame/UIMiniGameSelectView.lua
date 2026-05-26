-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMiniGameSelectView
-- Date: 2025-09-30 10:57:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMiniGameSelectView = class("UIMiniGameSelectView")

function UIMiniGameSelectView:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self:UpdateInfo()
end

function UIMiniGameSelectView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMiniGameSelectView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIMiniGameSelectView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMiniGameSelectView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiniGameSelectView:UpdateInfo()
    local tList = self.tInfo.tLevelList
    self.tbScriptList = {}
    for k, v in pairs(tList) do
        local callback = function()
            -- RemoteCallToServer("Onxxx")
            UIMgr.Close(self)
        end
        v.callback = callback
        local szContent = string.format("第%d关", v.nIndex)
        if v.bLock then
            szContent = szContent .. "（未解锁）"
        end
        v.szContent = szContent
        local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetOldDialogueContent2, self.WidgetNormal, v)
        UIHelper.SetVisible(tbScript.ImgContentIcon, false)
        self:UpdateLevelState(tbScript, v)
        table.insert(self.tbScriptList, k, tbScript)
    end
    self:LayoutDoLayout()
end

function UIMiniGameSelectView:UpdateLevelState(script, v)
    if v.bLock then
        UIHelper.SetEnable(script.BtnContent_1, false)
        UIHelper.SetNodeGray(script._rootNode, true, true)
    else
        UIHelper.SetEnable(script.BtnContent_1, true)
        UIHelper.SetNodeGray(script._rootNode, false, true)
    end
end

function UIMiniGameSelectView:LayoutDoLayout()
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutContent, true, true)

    if self.nArrowTimer then
        Timer.DelTimer(self, self.nArrowTimer)
        self.nArrowTimer = nil
    end

    self.nArrowTimer = Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewSetupArrow(self.ScrollViewContent, self.WidgetArrow)
    end)
end


return UIMiniGameSelectView