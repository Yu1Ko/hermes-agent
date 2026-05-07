-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeAttributeGamePlayTipCell
-- Date: 2023-08-02 20:26:28
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeAttributeGamePlayTipCell = class("UIHomelandMyHomeAttributeGamePlayTipCell")

function UIHomelandMyHomeAttributeGamePlayTipCell:OnEnter(nIndex, bGray)
    self.nIndex = nIndex
    self.bGray = bGray

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMyHomeAttributeGamePlayTipCell:OnExit()
    self.bInit = false
end

function UIHomelandMyHomeAttributeGamePlayTipCell:BindUIEvent()

end

function UIHomelandMyHomeAttributeGamePlayTipCell:RegEvent()
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

function UIHomelandMyHomeAttributeGamePlayTipCell:UpdateInfo()
    local aHomelandGameplayList = Table_GetHomelandGameplayInfo()
    local tInfo = aHomelandGameplayList[self.nIndex + 1]
    local tbTips = string.split(UIHelper.GBKToUTF8(tInfo.szTip), "\n")

    UIHelper.SetString(self.LableTilte, tbTips[1] or "")
    UIHelper.SetString(self.LableComment, tbTips[2] or "")

    UIHelper.SetVisible(self.LableComment, not not tbTips[2])

    UIHelper.LayoutDoLayout(self.LayoutTilte)

    UIHelper.SetSpriteFrame(self.ImgIconDark, tbIndex2Path[self.nIndex])
    UIHelper.SetNodeGray(self.ImgIconDark, self.bGray, false)

    UIHelper.LayoutDoLayout(self.WidgetAttributeTipsCell)
    UIHelper.WidgetFoceDoAlign(self)
end


return UIHomelandMyHomeAttributeGamePlayTipCell