-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIBuildFaceDefaultCell
-- Date: 2024-04-10 17:31:18
-- Desc: 创角预设选择类型后的预设节点
-- ---------------------------------------------------------------------------------

local UIBuildFaceDefaultCell = class("UIBuildFaceDefaultCell")

function UIBuildFaceDefaultCell:OnEnter(nIndex , tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIBuildFaceDefaultCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBuildFaceDefaultCell:BindUIEvent()
    
end

function UIBuildFaceDefaultCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBuildFaceDefaultCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBuildFaceDefaultCell:UpdateInfo()
    
end


function UIBuildFaceDefaultCell:OnInvokeSelect()
    if self.fnSelectCallback then
        self.fnSelectCallback(self.nIndex)
    end
end

return UIBuildFaceDefaultCell