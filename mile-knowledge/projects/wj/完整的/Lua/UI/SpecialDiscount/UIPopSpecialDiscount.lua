-- ---------------------------------------------------------------------------------
-- Author: liu yu min
-- Name: UIPopSpecialDiscount
-- Date: 2023-08-01 15:17:10
-- Desc: PanelSpecialDiscountPop
-- ---------------------------------------------------------------------------------

local UIPopSpecialDiscount = class("UIPopSpecialDiscount")

function UIPopSpecialDiscount:OnEnter(tList, nShowIndex)
	self.tList = tList
	self.nShowIndex = nShowIndex
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIPopSpecialDiscount:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIPopSpecialDiscount:BindUIEvent()
	
end

function UIPopSpecialDiscount:RegEvent()
	Event.Reg(self,"OnCloseSpecialDiscountPop",function()
		UIMgr.Close(VIEW_ID.PanelSpecialDiscountPop)
    end)
end

function UIPopSpecialDiscount:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPopSpecialDiscount:UpdateInfo()
	UIHelper.SetVisible(self.BtnSwitchRight,false)
	UIHelper.SetVisible(self.BtnSwitchLeft,false)
	UIHelper.SetVisible(self.LayoutBannerPage,false)
	UIHelper.SetTouchEnabled(self.PageViewBanner, false)
	local tScript = UIHelper.PageViewAddPage(self.PageViewBanner, PREFAB_ID.WidgetSpecialDiscountZhiSheng)
	tScript:OnEnter(self.tList, self.nShowIndex)
		
end



return UIPopSpecialDiscount