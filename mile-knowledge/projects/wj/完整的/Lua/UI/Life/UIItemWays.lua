-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemWays
-- Date: 2022-12-02 14:55:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemWays = class("UIItemWays")

function UIItemWays:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tInfo = tInfo;
    self:UpdateInfo(tInfo)
end

function UIItemWays:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemWays:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function ()
        -- UIMgr.Open(VIEW_ID.PanelMiddleMap, self.dwMapID, 0)
        Event.Dispatch("EVENT_LINK_NOTIFY", self.tInfo.szLinkInfo)
    end)
end

function UIItemWays:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemWays:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIItemWays:UpdateInfo(tInfo)
    UIHelper.SetString(self.LabelPlaceNameTitle01, tInfo.szText)
    UIHelper.SetVisible(self.ImgSpecializationCorner, tInfo.bRecommend)
    -- if tInfo.bRecommend then
    --     UIHelper.SetColor(self.LabelPlaceNameTitle01, cc.c3b(0xff,0xe2,0x6e))        
    -- end
end


return UIItemWays