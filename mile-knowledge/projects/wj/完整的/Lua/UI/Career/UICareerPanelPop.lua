-- PanelCareerOpenPop

local UICareerPanelPop = class("UICareerPanelPop")

function UICareerPanelPop:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UICareerPanelPop:OnExit()
    self.bInit = false
end

function UICareerPanelPop:BindUIEvent()
    UIHelper.BindUIEvent(self.ButtonOpen, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelCareer, 6)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UICareerPanelPop:RegEvent()
    -- Event.Reg(self, EventType.HideAllHoverTips, function()
    --     UIMgr.Close(self)
    -- end)
end

function UICareerPanelPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerPanelPop:UpdateInfo()
    local szImgPath = "UIAtlas2_Career_CareerTitle_QunXiaWanBian"
    UIHelper.SetSpriteFrame(self.ImgLogo, szImgPath)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(g_pClientPlayer.szName))
end

return UICareerPanelPop