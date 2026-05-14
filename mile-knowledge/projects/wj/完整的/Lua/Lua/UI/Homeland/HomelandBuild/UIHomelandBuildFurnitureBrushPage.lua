-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureBrushPage
-- Date: 2023-10-24 14:55:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureBrushPage = class("UIHomelandBuildFurnitureBrushPage")

local BrushMode = {
	Normal 	= 1,
	Flower 	= 2,
	Floor 	= 3,
}
function UIHomelandBuildFurnitureBrushPage:OnEnter(nMode)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

	-- self.nCurDepth = 1
	-- HLBOp_Bottom.SetBottomDepth(self.nCurDepth)

	self.nMode = nMode or BrushMode.Normal
    self:UpdateInfo()
end

function UIHomelandBuildFurnitureBrushPage:OnExit()
    self.bInit = false
end

function UIHomelandBuildFurnitureBrushPage:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
		HLBOp_Select.ClearSelect()
		HLBOp_Place.CancelPlace()

		HLBOp_Brush.CancelBrush()
		HLBOp_Bottom.CancelBottom()
		HLBOp_MultiItemOp.CancelPlace()
		HLBOp_CustomBrush.CancelCustomBrush()
		HLBOp_Blueprint.CancelMoveBlueprint()

		HomelandCustomBrushData.EnterFloorEdit()
	end)

    UIHelper.BindUIEvent(self.BtnCameraNext, EventType.OnClick, function ()
		HLBOp_Other.NextCameraMode()
		self:UpdateCameraMode()
	end)

	UIHelper.BindUIEvent(self.BtnCameraPrevious, EventType.OnClick, function ()
		HLBOp_Other.PrevCameraMode()
		self:UpdateCameraMode()
	end)

	-- UIHelper.BindUIEvent(self.BtnMinus, EventType.OnClick, function ()
	-- 	self.nCurDepth = math.max(1, self.nCurDepth - 1)
	-- 	HLBOp_Bottom.SetBottomDepth(self.nCurDepth)
	-- 	UIHelper.SetText(self.EditPaginate, self.nCurDepth)
	-- end)

	-- UIHelper.BindUIEvent(self.BtnPlus, EventType.OnClick, function ()
	-- 	self.nCurDepth = math.min(10, self.nCurDepth + 1)
	-- 	HLBOp_Bottom.SetBottomDepth(self.nCurDepth)
	-- 	UIHelper.SetText(self.EditPaginate, self.nCurDepth)
	-- end)

	-- if Platform.IsWindows() or Platform.IsMac() then
    --     UIHelper.RegisterEditBoxEnded(self.EditPaginate, function()
    --         local szDepth = UIHelper.GetText(self.EditPaginate)
	-- 		local nDepth = tonumber(szDepth)
	-- 		if nDepth then
    --             self.nCurDepth = math.min(10, nDepth)
    --             self.nCurDepth = math.max(1, self.nCurDepth)
    --         else
    --             UIHelper.SetText(self.EditPaginate, self.nCurDepth)
    --             return
    --         end
	-- 		HLBOp_Bottom.SetBottomDepth(self.nCurDepth)
    --     end)
    -- else
    --     UIHelper.RegisterEditBoxReturn(self.EditPaginate, function()
    --         local szDepth = UIHelper.GetText(self.EditPaginate)
	-- 		local nDepth = tonumber(szDepth)
	-- 		if nDepth then
    --             self.nCurDepth = math.min(10, nDepth)
    --             self.nCurDepth = math.max(1, self.nCurDepth)
    --         else
    --             UIHelper.SetText(self.EditPaginate, self.nCurDepth)
    --             return
    --         end
	-- 		HLBOp_Bottom.SetBottomDepth(self.nCurDepth)
    --     end)
    -- end

	-- UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)
end

function UIHomelandBuildFurnitureBrushPage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildFurnitureBrushPage:UpdateInfo()
	if self.nMode == BrushMode.Normal then
		self:UpdateBaseInfo()
	elseif self.nMode == BrushMode.Flower then
		self:UpdateFlowerInfo()
	elseif self.nMode == BrushMode.Floor then
		self:UpdateFloorInfo()
	end
    self:UpdateCameraMode()
end

function UIHomelandBuildFurnitureBrushPage:UpdateBaseInfo()
	UIHelper.SetVisible(self.LayoutItemInfo, true)
	UIHelper.SetVisible(self.WidgetVegetationBrush, false)
	UIHelper.SetVisible(self.WidgetGroundBrush, false)

    local tbInfo = HomelandBuildData.GetCurSelectedInfo()

    local szNum = "MAX"
	local szPublic = ""

	local nMode = HLBOp_Main.GetBuildMode()
	if tbInfo.nFurnitureType == HS_FURNITURE_TYPE.APPLIQUE_BRUSH then
		szNum = g_tStrings.STR_HOMELAND_BUILDING_FLOOR_BRUSH
	elseif tbInfo.nFurnitureType == HS_FURNITURE_TYPE.FOLIAGE_BRUSH then
		szNum = g_tStrings.STR_HOMELAND_BUILDING_FLOWER_BRUSH
	elseif tbInfo.bShowNumberAsBrush then
		szNum = g_tStrings.STR_HOMELAND_BUILDING_FURNITURE_BRUSH
	elseif nMode ~= BUILD_MODE.TEST and tbInfo.tNumInfo then
		local tNumInfo = tbInfo.tNumInfo
		if nMode == BUILD_MODE.COMMUNITY or nMode == BUILD_MODE.PRIVATE then
			szNum = tostring(tNumInfo.nLeftAmount - tNumInfo.nWarehouseLeftAmount)
			if tNumInfo.nWarehouseLeftAmount > 0 then
				szPublic = ("+" .. tostring(tNumInfo.nWarehouseLeftAmount))
			end
		end
	end

	local dwFurnitureUiId = GetHomelandMgr().MakeFurnitureUIID(tbInfo.nFurnitureType, tbInfo.dwFurnitureID)
	local tAddInfo = FurnitureData.GetFurnAddInfo(dwFurnitureUiId)
	if tAddInfo then
		local szPath = string.gsub(tAddInfo.szPath, "ui/Image/", "Resource/")
		szPath = string.gsub(szPath, ".tga", ".png")
		UIHelper.SetTexture(self.ImgFurnitureIcon, szPath)
	end

	local szName = UIHelper.GBKToUTF8(tbInfo.szName)
    UIHelper.SetString(self.LabelItemName, szName)
    UIHelper.SetString(self.LabelItemNum, szNum)

	local szTips = string.format("在地面上涂抹即可批量放置【%s】", szName)
	if FurnitureData.IsAutoBottomBrush(tbInfo.dwModelID) then
		szTips = string.format("在地面上长按可批量放置【%s】", szName)
	end
	UIHelper.SetString(self.LabelBrushTips, szTips)
	TipsHelper.ShowNormalTip(szTips)

	UIHelper.SetVisible(self.WidgetBasementDepth, false)
	UIHelper.CascadeDoLayoutDoWidget(self.WidgetAnchorTips, true, true)
end

function UIHomelandBuildFurnitureBrushPage:UpdateFlowerInfo()
	UIHelper.SetVisible(self.LayoutItemInfo, false)
	UIHelper.SetVisible(self.WidgetVegetationBrush, true)
	UIHelper.SetVisible(self.WidgetGroundBrush, false)

	if not self.scriptFlowerPage then
		self.scriptFlowerPage = UIHelper.GetBindScript(self.WidgetVegetationBrush)
	end
	self.scriptFlowerPage:OnEnter()

	local szTips = "在地面上涂抹即可放置"
	UIHelper.SetString(self.LabelBrushTips, szTips)
	UIHelper.CascadeDoLayoutDoWidget(self.WidgetAnchorTips, true, true)
end

function UIHomelandBuildFurnitureBrushPage:UpdateFloorInfo()
	UIHelper.SetVisible(self.LayoutItemInfo, false)
	UIHelper.SetVisible(self.WidgetVegetationBrush, false)
	UIHelper.SetVisible(self.WidgetGroundBrush, true)

	if not self.scriptFloorPage then
		self.scriptFloorPage = UIHelper.GetBindScript(self.WidgetGroundBrush)
	end
	self.scriptFloorPage:OnEnter()

	local szTips = "在地面上涂抹即可放置"
	UIHelper.SetString(self.LabelBrushTips, szTips)
	UIHelper.CascadeDoLayoutDoWidget(self.WidgetAnchorTips, true, true)
end

function UIHomelandBuildFurnitureBrushPage:UpdateCameraMode()
	local szMode = string.format("镜头 - %s", HLBOp_Other.GetCameraModeDesc())
	UIHelper.SetString(self.LabelCameraModeName, szMode)
end

return UIHomelandBuildFurnitureBrushPage