local UIWuWeiJueSave = class("UIWuWeiJueSave")

function UIWuWeiJueSave:OnEnter()
    self:BindUIEvent()
end

function UIWuWeiJueSave:OnExit()
end

function UIWuWeiJueSave:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        if self.fnConfirm then
            local szName = UIHelper.GetText(self.EditBoxName)
            if not szName or szName == "" then
                szName = self.szDefaultName
            end
            local szDesc = UIHelper.GetText(self.EditBoxDesc)
            if not szDesc or szDesc == "" then
                szDesc = self.szDefaultDesc
            end
            self.fnConfirm(szName, szDesc)
        end
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIWuWeiJueSave:SetPlaceHolder(szName, szDesc)
    if szName and szName ~= "" then
        UIHelper.SetLabel(self.LabelName, szName)
    end
    if szDesc and szDesc ~= "" then
        UIHelper.SetLabel(self.LabelDesc, szDesc)
    end
end

function UIWuWeiJueSave:SetDefaultString(szName, szDesc)
    self.szDefaultName = szName
    self.szDefaultDesc = szDesc
end

function UIWuWeiJueSave:SetBtnConfirmFunc(fnConfirm)
    self.fnConfirm = fnConfirm
end

return UIWuWeiJueSave