-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIWidgetOutfitGroup
-- Date: 2024-04-03 15:52:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOutfitGroup = class("UIWidgetOutfitGroup")

function UIWidgetOutfitGroup:OnEnter(tbItemList, nType)
	self.tbItemList = tbItemList
	self.nType = nType
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UIWidgetOutfitGroup:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIWidgetOutfitGroup:BindUIEvent()
	
end

function UIWidgetOutfitGroup:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UIWidgetOutfitGroup:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOutfitGroup:UpdateInfo()
	self.tbScriptItem = self.tbScriptItem or {}
	if self.nType == OutFitPreviewData.PreviewType.Pandent then
		self:UpdatePandentCell()
	elseif self.nType == OutFitPreviewData.PreviewType.ExteriorEquip then
		self:UpdateExteriorCell()
	elseif self.nType == OutFitPreviewData.PreviewType.Equip then
		self:UdpateEquipCell()
	end
	UIHelper.LayoutDoLayout(self.LayoutHanging)
end

function UIWidgetOutfitGroup:UpdatePandentCell()
	UIHelper.SetString(self.Label01, "挂")
	UIHelper.SetString(self.Label02, "件")
	for i, item in pairs(self.tbItemList) do
		self.tbScriptItem[i] = self.tbScriptItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitGroupBagCell, self.LayoutHanging, item)
	end
end

function UIWidgetOutfitGroup:UpdateExteriorCell()
	UIHelper.SetString(self.Label01, "外")
	UIHelper.SetString(self.Label02, "观")
	for i, item in pairs(self.tbItemList) do
		self.tbScriptItem[i] = self.tbScriptItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitGroupBagCell, self.LayoutHanging, item)
	end
end

function UIWidgetOutfitGroup:UdpateEquipCell()
	UIHelper.SetString(self.Label01, "装")
	UIHelper.SetString(self.Label02, "备")
	for i, item in pairs(self.tbItemList) do
		self.tbScriptItem[i] = self.tbScriptItem[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetOutfitGroupBagCell, self.LayoutHanging, item)
	end
end

return UIWidgetOutfitGroup