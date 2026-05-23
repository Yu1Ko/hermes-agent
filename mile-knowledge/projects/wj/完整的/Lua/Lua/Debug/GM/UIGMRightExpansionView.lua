-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGMRightExpansionView
-- Date: 2022-12-14 16:34:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGMRightExpansionView = class("UIGMRightExpansionView")

function UIGMRightExpansionView:OnEnter(tbFunction)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbFunction = tbFunction
    self:UpdateInfo()
end

function UIGMRightExpansionView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIGMRightExpansionView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnGetPosition, EventType.OnClick, function(btn)
        self.tbFunction:BtnGetPosition(self)
    end)

    UIHelper.BindUIEvent(self.BtnClear, EventType.OnClick, function(btn)
        UIHelper.SetString(self.LabelEditBoxUp, "")
        UIHelper.SetString(self.LabelEditBoxDown, "")
        self.tbFunction:BtnClear(self)
    end)

    UIHelper.BindUIEvent(self.BtnSettPosition, EventType.OnClick, function(btn)
        self.tbFunction:BtnSettPosition()
    end)


    self.EditSearchUp:registerScriptEditBoxHandler(function(szType, _editbox)
        if szType == "ended" then
            UIHelper.SetString(self.EditSearchUp, "")
        elseif szType == "began" then
            local szSearchkey = UIHelper.GetString(self.LabelEditBoxUp)
            UIHelper.SetString(self.EditSearchUp, szSearchkey)
        end
    end)

    self.EditSearchDown:registerScriptEditBoxHandler(function(szType, _editbox)
        if szType == "ended" then
            UIHelper.SetString(self.EditSearchDown, "")
        elseif szType == "began" then
            local szSearchkey = UIHelper.GetString(self.LabelEditBoxDown)
            UIHelper.SetString(self.EditSearchDown, szSearchkey)
        end
    end)
end

function UIGMRightExpansionView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIGMRightExpansionView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGMRightExpansionView:UpdateInfo()
    UIHelper.SetString(self.LabelEditBoxUp, self.tbFunction.szLabelEditorUp)
    UIHelper.SetString(self.LabelEditBoxDown, self.tbFunction.szLabelEditorDown)
    UIHelper.SetSelected(self.TogMap,self.tbFunction.IsNeedMAP)
    UIHelper.SetSelected(self.TogFace,self.tbFunction.IsNeedFace)
end


return UIGMRightExpansionView