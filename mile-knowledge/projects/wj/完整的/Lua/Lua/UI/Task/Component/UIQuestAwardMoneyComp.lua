-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuestAwardMoneyComp
-- Date: 2022-11-30 15:39:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local MoneyTypeToImg = {
    ["Bullion"] = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Zhuan.png",
    ["Gold"]    = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin.png",
    ["Silver"]  = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Yin.png",
    ["Copper"]  = "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Tong.png",
}

local UIQuestAwardMoneyComp = class("UIQuestAwardMoneyComp")

function UIQuestAwardMoneyComp:OnEnter(nCount, szMoneyType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if nCount and szMoneyType then
        self.nCount = nCount
        self.szMoneyType = szMoneyType
        self:UpdateInfo()
    end
end

function UIQuestAwardMoneyComp:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIQuestAwardMoneyComp:BindUIEvent()

end

function UIQuestAwardMoneyComp:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIQuestAwardMoneyComp:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuestAwardMoneyComp:UpdateInfo()
    UIHelper.SetString(self.LabelMoney, UIHelper.GBKToUTF8(self.nCount))
    -- LOG.INFO("-------UIQuestAwardMoneyComp  %s---------", tostring(MoneyTypeToImg[self.szMoneyType]))
    UIHelper.SetSpriteFrame(self.ImgMoney, MoneyTypeToImg[self.szMoneyType])
end


return UIQuestAwardMoneyComp