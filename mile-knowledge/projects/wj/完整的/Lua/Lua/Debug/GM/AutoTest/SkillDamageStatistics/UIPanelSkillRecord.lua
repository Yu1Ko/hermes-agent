-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRanelSkillRecord
-- Date: 2023-09-15 16:40:39
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRanelSkillRecord = class("UIRanelSkillRecord")

function UIRanelSkillRecord:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIRanelSkillRecord:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRanelSkillRecord:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnStart, EventType.OnClick, function(btn)
        SkillsRecording:Start()
    end)

    UIHelper.BindUIEvent(self.BtnReStart, EventType.OnClick, function(btn)
        SkillsRecording:ReStart()
    end)

    UIHelper.BindUIEvent(self.BtnStop, EventType.OnClick, function(btn)
        if not UIHelper.GetVisible(self.WidgetSaveConfirm) then
           UIHelper.SetVisible(self.WidgetSaveConfirm, true)
           UIHelper.SetVisible(self.WidgetSkillRecord, false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnQuit, EventType.OnClick, function(btn)
        SkillsRecording:UnInit()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCloseHover, EventType.OnClick, function(btn)
        -- 关闭整个界面
        UIMgr.Close(self)
    end)


    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        UIHelper.SetVisible(self.WidgetSaveConfirm, false)
        UIHelper.SetVisible(self.WidgetSkillRecord, true)
        local szFileName = UIHelper.GetString(self.EditBoxSavefile)
        SkillsRecording:Save(szFileName)
        -- 这里才是报存文件的时候上面的Stop只是打开UI界面
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIHelper.SetVisible(self.WidgetSaveConfirm, false)
        UIHelper.SetVisible(self.WidgetSkillRecord, true)
    end)

    -- if Platform.IsWindows() then
    --     UIHelper.RegisterEditBoxEnded(self.EditBoxSavefile, function()
    --         local szFileName = UIHelper.GetString(self.EditBoxSavefile)
    --         self.tCMD.CMD = szCMD
    --         -- self:UpdateInfo_Left(szSearchkey)
    --     end)
    -- else
    --     UIHelper.RegisterEditBoxReturn(self.EditBoxSavefile, function()
    --         local szCMD = UIHelper.GetString(self.EditBoxSavefile)
    --         self.tCMD.CMD = szCMD
    --         -- self:UpdateInfo_Left(szSearchkey)
    --     end)
    -- end
end

function UIRanelSkillRecord:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRanelSkillRecord:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRanelSkillRecord:UpdateInfo()
    
end


return UIRanelSkillRecord