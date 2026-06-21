local UIWuWeiJueKungfuCell = class("UIWuWeiJueKungfuCell")

function UIWuWeiJueKungfuCell:OnEnter()
    self:BindUIEvent()
end

function UIWuWeiJueKungfuCell:OnExit()
    
end

function UIWuWeiJueKungfuCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGroup, EventType.OnClick, function(btn)
        if self.fnCallback then
            self.fnCallback()
        end
    end)
end

function UIWuWeiJueKungfuCell:UpdateInfo(szName, szIcon)
    UIHelper.SetLabel(self.szName, szName)
    UIHelper.SetSpriteFrame(self.ImgKungfu, szIcon)
end

function UIWuWeiJueKungfuCell:SetClickCallback(fnCallback)
    self.fnCallback = fnCallback
end

return UIWuWeiJueKungfuCell