-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetJingBianTuTitleView
-- Date: 2024-11-21 17:53:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetJingBianTuTitleView = class("UIWidgetJingBianTuTitleView")

function UIWidgetJingBianTuTitleView:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIWidgetJingBianTuTitleView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetJingBianTuTitleView:BindUIEvent()
    
end

function UIWidgetJingBianTuTitleView:RegEvent()
    
end

function UIWidgetJingBianTuTitleView:UnRegEvent()
    
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetJingBianTuTitleView:UpdateInfo()
    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(self.tbInfo.szName))
end


return UIWidgetJingBianTuTitleView