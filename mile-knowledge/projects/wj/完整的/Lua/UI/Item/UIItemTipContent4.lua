-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent4
-- Date: 2022-11-15 15:45:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent4 = class("UIItemTipContent4")

function UIItemTipContent4:OnEnter(tbInfo)
    if not tbInfo then return end

    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemTipContent4:OnExit()
    self.bInit = false
end

function UIItemTipContent4:BindUIEvent()

end

function UIItemTipContent4:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent4:UpdateInfo()
    if not self.tbInfo or table.is_empty(self.tbInfo) then
        UIHelper.SetVisible(self._rootNode, false)
    else
        for i = 1, 2 do
            local tbInfo = self.tbInfo[i]
            if i == 1 then
                UIHelper.SetVisible(self.WidgetAttri1, tbInfo ~= nil)
                if tbInfo ~= nil then
                    UIHelper.SetRichText(self.RichTextAttri1, "<div><color=#D7F6FF>" .. tbInfo.szPriceDesc  .."</c></div>")
                    UIHelper.SetString(self.Label_Cost, tbInfo.nDisPrice)
                    UIHelper.SetTextColor(self.Label_Cost, tbInfo.bDis and cc.c3b(255, 118, 118) or cc.c3b(215, 246, 255))
                    UIHelper.SetSpriteFrame(self.Img_Bingjia, tbInfo.szImagePath)
                    UIHelper.SetVisible(self.ImgSaleBg1, tbInfo.bDis)
                    UIHelper.SetVisible(self.LabelOriginalPrice1, tbInfo.bDis)
                    if tbInfo.bDis then
                        UIHelper.SetString(self.LabelOriginalPrice1, tbInfo.nPrice)
                        UIHelper.SetTextColor(self.LabelOriginalPrice1, cc.c3b(215, 246, 255))
                        local szDisCount, szDisTime, nDiscount = CoinShop_GetOneDisInfo(tbInfo, tbInfo.bSecondDis)
                        UIHelper.SetString(self.Label_Cost1, szDisCount .. szDisTime)
                    end
                end
            elseif i == 2 then
                UIHelper.SetVisible(self.WidgetAttri2, tbInfo ~= nil)
                if tbInfo ~= nil then
                    UIHelper.SetRichText(self.RichTextAttri2, "<div><color=#D7F6FF>" .. tbInfo.szPriceDesc  .."</c></div>")
                    UIHelper.SetString(self.Label_Xianjia, tbInfo.nDisPrice)
                    UIHelper.SetTextColor(self.Label_Xianjia, tbInfo.bDis and cc.c3b(255, 118, 118) or cc.c3b(215, 246, 255))
                    UIHelper.SetSpriteFrame(self.Img_TongBao, tbInfo.szImagePath)
                    UIHelper.SetVisible(self.ImgSaleBg2, tbInfo.bDis)
                    UIHelper.SetVisible(self.LabelOriginalPrice2, tbInfo.bDis)
                    if tbInfo.bDis then
                        UIHelper.SetString(self.LabelOriginalPrice2, tbInfo.nPrice)
                        UIHelper.SetTextColor(self.LabelOriginalPrice2, cc.c3b(215, 246, 255))
                        local szDisCount, szDisTime, nDiscount = CoinShop_GetOneDisInfo(tbInfo, tbInfo.bSecondDis)
                        UIHelper.SetString(self.Label_Cost2, szDisCount .. szDisTime)
                    end
                end
            end
        end

        UIHelper.LayoutDoLayout(self.LayoutCost1)
        UIHelper.LayoutDoLayout(self.LayoutCost2)
        UIHelper.WidgetFoceDoAlign(self)
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
        UIHelper.SetVisible(self._rootNode, true)
    end
end

return UIItemTipContent4