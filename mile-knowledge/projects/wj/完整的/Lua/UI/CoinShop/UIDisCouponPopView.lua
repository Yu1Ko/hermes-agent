-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDisCouponPopView
-- Date: 2023-07-04 15:36:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local DISCOUPON_TIPS = "提示：\n1、每单最多使用1张优惠券。\n2、过了有效期，优惠券会自动消失。\n3、易容脸型、部分限时\\限量商品、周边、特殊道具，如：“舞石浣色”等均不能使用优惠券。\n4、结算时会优先推荐折扣力度更大的优惠券；若折扣力度相同，则优先推荐角色优惠券，其次为本服通用优惠券。"

local UIDisCouponPopView = class("UIDisCouponPopView")

function UIDisCouponPopView:OnEnter(tbDisCouponList, dwCurDisCouponID, fnSelectCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not tbDisCouponList then
        tbDisCouponList = CoinShopData.GetWelfares()
    end
    self.tbDisCouponList = tbDisCouponList
    self.dwCurDisCouponID = dwCurDisCouponID
    self.fnSelectCallback = fnSelectCallback
    self:UpdateInfo()
end

function UIDisCouponPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    -- 打开优惠券界面自动消除红点
    for _, welfare in ipairs(self.tbDisCouponList) do
        CoinShopData.VisitWelfare(welfare)
    end
end

function UIDisCouponPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnTips, EventType.OnClick, function ()
        local tips, tipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnTips, DISCOUPON_TIPS)
        -- tips:SetDisplayLayoutDir(TipsLayoutDir.TOP_CENTER)
        -- local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        -- tips:SetSize(nTipsWidth, nTipsHeight)
        -- tips:UpdatePosByNode(self.BtnTips)
    end)

    UIHelper.BindUIEvent(self.ScrollViewInfo, EventType.OnScrollingScrollView, function (_, eventType)
		if eventType == ccui.ScrollviewEventType.containerMoved then
			self:UpdateRedPointArrow()
		end
	end)
end

function UIDisCouponPopView:RegEvent()
end

function UIDisCouponPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDisCouponPopView:UpdateInfo()
    local bEmpty = not self.tbDisCouponList or table_is_empty(self.tbDisCouponList)
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.SetVisible(self.ScrollViewInfo, not bEmpty)

    UIHelper.RemoveAllChildren(self.ScrollViewInfo)
    self.tScriptList = {}
    for _, tbDisCoupon in ipairs(self.tbDisCouponList) do
        local bSelected = tbDisCoupon.dwDisCouponID == self.dwCurDisCouponID
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetCouponsCell, self.ScrollViewInfo)
        script:SetTouchEnabled(false)
        script:OnEnter(tbDisCoupon)
        script:SetHasRedPoint(CoinShopData.IsNewWelfare(tbDisCoupon))
        script:SetSelectedCallback(self.fnSelectCallback)
        script:SetSelected(bSelected, false)
        table.insert(self.tScriptList, script)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewInfo)
end

function UIDisCouponPopView:UpdateRedPointArrow()
	local bHasRedPointBelow, nRedPointCount = self:HasRedPointBelow()
    UIHelper.SetVisible(self.WidgetRedPointArrow, bHasRedPointBelow)
    UIHelper.SetString(self.LabelRedPoint, nRedPointCount)
end

function UIDisCouponPopView:HasRedPointBelow()
	local bHasRedPointBelow = false
    local nRedPointCount = 0

    local _, nScrollViewWorldY = UIHelper.ConvertToWorldSpace(self.ScrollViewInfo, 0, 0)

	for k, v in ipairs(self.tScriptList) do
		if UIHelper.GetVisible(v.ImgRedDot) then
			local nHeight = UIHelper.GetHeight(v.ImgRedDot)
			local _nWorldX, _nWorldY = UIHelper.ConvertToWorldSpace(v.ImgRedDot, 0, nHeight)
			if _nWorldY < nScrollViewWorldY then
				bHasRedPointBelow = true
                nRedPointCount = nRedPointCount + 1
                if nRedPointCount == 99 then
                    break
                end
			end
		end
	end
	return bHasRedPointBelow, nRedPointCount
end


return UIDisCouponPopView