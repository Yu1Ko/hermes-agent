-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent9
-- Date: 2023-05-23 11:23:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent9 = class("UIItemTipContent9")

function UIItemTipContent9:OnEnter(szName, nStar)
    self.szName = szName
    self.nStar = nStar

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemTipContent9:OnExit()
    self.bInit = false
end

function UIItemTipContent9:BindUIEvent()

end

function UIItemTipContent9:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent9:UpdateInfo()
    if not self.szName or not self.nStar then
        UIHelper.SetVisible(self._rootNode, false)
        return
    end

    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetString(self.LabelAttri1, self.szName)
    for i, img in ipairs(self.tbImgStarEmpty) do
        UIHelper.SetVisible(img, i <= self.nStar)
    end
end


return UIItemTipContent9