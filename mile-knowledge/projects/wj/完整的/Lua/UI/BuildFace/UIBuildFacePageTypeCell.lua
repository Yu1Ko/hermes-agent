-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIBuildFacePageTypeCell
-- Date: 2024-04-10 16:31:35
-- Desc: 创角预设左边的类型Cell
-- ---------------------------------------------------------------------------------

local UIBuildFacePageTypeCell = class("UIBuildFacePageTypeCell")

function UIBuildFacePageTypeCell:OnEnter(nIndex , szPageName , fnSelectCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    self.szPageName = szPageName
    self.fnSelectCallback = fnSelectCallback
    self:UpdateInfo()
end

function UIBuildFacePageTypeCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBuildFacePageTypeCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogAll , EventType.OnSelectChanged , function (_,bSelect)
        if self.fnSelectCallback and bSelect then
            self.fnSelectCallback(self.nIndex)
        end
    end)
end

function UIBuildFacePageTypeCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIBuildFacePageTypeCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBuildFacePageTypeCell:UpdateInfo()
    UIHelper.SetString(self.LabelAllSelect , self.szPageName)
    UIHelper.SetString(self.LabelAllNormal , self.szPageName)
end

function UIBuildFacePageTypeCell:OnInvokeSelect()
    if self.fnSelectCallback then
        self.fnSelectCallback(self.nIndex)
    end
end


return UIBuildFacePageTypeCell