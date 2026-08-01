-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIMainCityAim
-- Date: 2026-01-25 10:43:08
-- Desc: 通用准星
-- ---------------------------------------------------------------------------------

local tbMapImg =
{
    [1] = "UIAtlas2_Public_PublicHint_PublicHint_img_Fish_Crosshair.png", -- 年年有鱼活动
}

local tbMapOffset =
{
    [1] = {0, 100}, -- 年年有鱼活动
}

local UIMainCityAim = class("UIMainCityAim")

function UIMainCityAim:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIMainCityAim:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMainCityAim:BindUIEvent()

end

function UIMainCityAim:RegEvent()
    Event.Reg(self, EventType.ON_QTEPANEL_SHOW, function()
        self:UpdateInfo()
    end)

end

function UIMainCityAim:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIMainCityAim:Show(tParam)
    self.dwID = tParam.dwID
    self:UpdateInfo()

    UIHelper.SetVisible(self._rootNode, true)
end

function UIMainCityAim:Hide()
    UIHelper.SetVisible(self._rootNode, false)
end

function UIMainCityAim:UpdateInfo()
    local szImg = tbMapImg[self.dwID]
    if szImg then
        UIHelper.SetSpriteFrame(self.ImgBg, szImg)
    end

    -- 因为是基于原点，所以这里直接设置位置即可
    local nX = tbMapOffset[self.dwID] and tbMapOffset[self.dwID][1] or 0
    local nY = tbMapOffset[self.dwID] and tbMapOffset[self.dwID][2] or 0
    UIHelper.SetPosition(self._rootNode, nX, nY)
end



return UIMainCityAim