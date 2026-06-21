-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMLeftCell
-- Date: 2022-11-08 11:33:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGMLeftCell = class("UIGMLeftCell")

function UIGMLeftCell:OnEnter(tbGMView, tCMD)
    if not tCMD then return end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbGMView = tbGMView
    self.tCMD = tCMD
    self:UpdateInfo()
end

function UIGMLeftCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGMLeftCell:BindUIEvent()
    UIHelper.BindUIEvent(self.Btnltem, EventType.OnClick, function(btn)
        UIMgr.Close(VIEW_ID.PanelCMDEditor)
        if self.tCMD then
            if self.tCMD.NeedParam then
                UIMgr.Open(VIEW_ID.PanelCMDEditor, self.tbGMView, self.tCMD)
            else
                GMMgr.ExecuteGMCommand(self.tCMD.text, self.tCMD.CMD, self.tCMD.CMDType)
            end
        end
    end)
    
end

function UIGMLeftCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGMLeftCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGMLeftCell:UpdateInfo()
    if not self.tCMD then return end
    
    UIHelper.SetString(self.LabelItem, tostring(self.tCMD.text))
end


return UIGMLeftCell