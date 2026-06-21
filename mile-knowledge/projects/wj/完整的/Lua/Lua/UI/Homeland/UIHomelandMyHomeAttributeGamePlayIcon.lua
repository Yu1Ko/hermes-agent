-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeAttributeGamePlayIcon
-- Date: 2023-03-29 20:30:00
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeAttributeGamePlayIcon = class("UIHomelandMyHomeAttributeGamePlayIcon")

function UIHomelandMyHomeAttributeGamePlayIcon:OnEnter(nIndex, bGray)
    self.nIndex = nIndex
    self.bGray = bGray

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMyHomeAttributeGamePlayIcon:OnExit()
    self.bInit = false
end

function UIHomelandMyHomeAttributeGamePlayIcon:BindUIEvent()

end

function UIHomelandMyHomeAttributeGamePlayIcon:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

local tbIndex2Path = {
    [-1] = "UIAtlas2_Home_HomeLand_HomeIcon_icon_sign.png",
    [0] = "UIAtlas2_Home_HomeLand_HomeIcon_icon_TingJu.png",
    [1] = "UIAtlas2_Home_HomeLand_HomeIcon_icon_BoShi.png",
    [2] = "UIAtlas2_Home_HomeLand_HomeIcon_icon_CaiMing.png",
    [3] = "UIAtlas2_Home_HomeLand_HomeIcon_icon_FengYuan.png",
    [4] = "UIAtlas2_Home_HomeLand_HomeIcon_icon_DouXi.png",
    [5] = "UIAtlas2_Home_HomeLand_HomeIcon_icon_LiJi.png",
    [6] = "UIAtlas2_Home_HomeLand_HomeIcon_icon_JingYing.png",
    [7] = "UIAtlas2_Home_HomeLand_HomeIcon_icon_QiYuan.png",
}

function UIHomelandMyHomeAttributeGamePlayIcon:UpdateInfo()
	UIHelper.SetSpriteFrame(self.ImgIcon, tbIndex2Path[self.nIndex])
    UIHelper.SetNodeGray(self.ImgIcon, self.bGray, false)
end


return UIHomelandMyHomeAttributeGamePlayIcon