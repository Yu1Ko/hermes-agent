-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOrderRightTop
-- Date: 2024-01-12 16:52:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandOrderRightTop = class("UIHomelandOrderRightTop")
function UIHomelandOrderRightTop:OnEnter(DataModel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.DataModel = DataModel
    self:UpdateInfo(DataModel.nTypeIndex)
end

function UIHomelandOrderRightTop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandOrderRightTop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnShop, EventType.OnClick, function ()
        ShopData.OpenSystemShopGroup(1, 1230)
    end)

    UIHelper.BindUIEvent(self.BtnTrend, EventType.OnClick, function ()
        RemoteCallToServer("On_HomeLand_OrderPrediction")
    end)
end

function UIHomelandOrderRightTop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandOrderRightTop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIHomelandOrderRightTop:UpdateInfo(nTypeIndex)
    UIHelper.SetVisible(self.ImgRenovate, false)
    UIHelper.SetVisible(self.ImgAssist, false)
    UIHelper.SetVisible(self.ImgDelivery, false)
    UIHelper.SetVisible(self.WidgetCollect, false)
    UIHelper.SetVisible(self.WidgetTrend, false)

    if nTypeIndex == HLORDER_TYPE.FLOWER and self.DataModel.bOwner then
        local tRefreshData = GDAPI_GetRefreshData(nTypeIndex)
        UIHelper.SetVisible(self.ImgRenovate, true)
        UIHelper.SetVisible(self.ImgAssist, true)
        UIHelper.SetVisible(self.WidgetTrend, true)
        UIHelper.SetString(self.LabelAssist, FormatString(g_tStrings.STR_HOMELAND_PUBLISH_ASSIST1, tRefreshData.nCurAssist))
        self:UpdateRenovateInfo(nTypeIndex)
    elseif nTypeIndex == HLORDER_TYPE.COOK then
        UIHelper.SetVisible(self.ImgRenovate, true)
        self:UpdateRenovateInfo(nTypeIndex)
        -- UIHelper.SetVisible(self.ImgDelivery, true)
    end
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIHomelandOrderRightTop:UpdateRenovateInfo(nTypeIndex)
    local tRefreshData = GDAPI_GetRefreshData(nTypeIndex)
    local szContent = ""
    szContent = FormatString(g_tStrings.STR_HOMELAND_PUBLISH_REFRESH, tRefreshData.nCurRefresh)
    szContent = "<color=#AED9E0>"..szContent.."</c>"

    if tRefreshData.nCurRefresh <= 0 then
        local szItemIconPath = "Resource/icon/home/Item/item_23_11_27_8"
        local nImageSize = 44
        local szFrame = string.format("<img src='%s' width='%d' height='%d' type='0'/>", szItemIconPath, nImageSize, nImageSize)
        local nCount = tRefreshData.nItemCount or 0
        local szTip = "<color=#AED9E0>香蕊花神券："..nCount.."</c>"
        szContent = szFrame..szTip
    end
    UIHelper.SetRichText(self.LabelRenovate, szContent)
end

return UIHomelandOrderRightTop