-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemtQualityBar
-- Date: 2023-10-23 15:01:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemtQualityBar = class("UIItemtQualityBar")

function UIItemtQualityBar:OnEnter(nQuality)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nQuality = nQuality
    self:UpdateInfo()
end

function UIItemtQualityBar:OnExit()
    self.bInit = false
end

function UIItemtQualityBar:BindUIEvent()

end

function UIItemtQualityBar:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemtQualityBar:UpdateInfo()
    local szQualityBarImg = ItemtQualityBarImg[self.nQuality] or ItemtQualityBarImg[1]
    local szQualityBarLeafImg = ItemtQualityBarLeafImg[self.nQuality] or ItemtQualityBarLeafImg[1]
    UIHelper.SetSpriteFrame(self.ImgBg, szQualityBarImg)
    UIHelper.SetSpriteFrame(self.ImgLeaf, szQualityBarLeafImg)
end


return UIItemtQualityBar