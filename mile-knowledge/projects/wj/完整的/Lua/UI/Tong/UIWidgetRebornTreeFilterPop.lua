-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetRebornTreeFilterPop
-- Date: 2023-03-16
-- Desc: 帮会天工树过滤菜单
-- Prefab: PREFAB_ID.WidgetRebornTreeFilterPop
-- ---------------------------------------------------------------------------------

local UIWidgetRebornTreeFilterPop = class("UIWidgetRebornTreeFilterPop")

local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK
local get = TableGet
local set = TableSet

function UIWidgetRebornTreeFilterPop:Init(nBranchType, nFilterType, fnClose)
	self.m = {}	
	self.m.nBranchType = nBranchType
	self.m.nFilterType = nFilterType
	self.m.fnClose = fnClose

	self:RegEvent()
	self:BindUIEvent()
	
	self:UpdateUI(true)
end

function UIWidgetRebornTreeFilterPop:UnInit()
	self:UnRegEvent()	
	self.m = nil
end

function UIWidgetRebornTreeFilterPop:BindUIEvent()
	-- UIHelper.BindUIEvent(tNodes.BtnOpen, EventType.OnClick, function()
	-- 	self:OnOpenClicked()
	-- end)	

end

function UIWidgetRebornTreeFilterPop:RegEvent()	
	-- Event.Reg(self, "SET_TONG_TECH_TREE_RESPOND", function (...)		
	-- 	self:OnSetTongTechTreeRespond(...)
	-- end)	

end

function UIWidgetRebornTreeFilterPop:UnRegEvent()
	Event.UnRegAll(self)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local _tFilterMenuTitle = {
	{"全部", "已升级", "可升级", "功能分支", "福利分支"},
	{"全部", "已升级", "可升级", "涅槃分支", "问鼎分支"},
}
function UIWidgetRebornTreeFilterPop:UpdateUI(bInit)	
	local root = self._rootNode
	if bInit then			
		local parent = UIHelper.FindChildByName(root, "LayoutStyleFilterMain")
		local children = UIHelper.GetChildren(parent)
		local tTitleArr = _tFilterMenuTitle[self.m.nBranchType]
		for i, child in pairs(children) do 
			UIHelper.SetTouchDownHideTips(child, false)
			UIHelper.SetSelected(child, i == self.m.nFilterType)
			UIHelper.SetString(UIHelper.FindChildByName(child, "LabelStyleFilterMain"), tTitleArr[i])
			UIHelper.SetString(UIHelper.FindChildByName(child, "LabelStyleFilterMainUp"), tTitleArr[i])
			local nType = i
			UIHelper.BindUIEvent(child, EventType.OnClick, function()				
				self.m.nFilterType = nType
				self:Close()
			end)			
		end
	end
end

function UIWidgetRebornTreeFilterPop:Close()
	local fnClose = self.m.fnClose
	local nFilterType = self.m.nFilterType

	TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetRebornTreeFilterPop)

	if fnClose then
		fnClose(nFilterType)
	end
end

return UIWidgetRebornTreeFilterPop
