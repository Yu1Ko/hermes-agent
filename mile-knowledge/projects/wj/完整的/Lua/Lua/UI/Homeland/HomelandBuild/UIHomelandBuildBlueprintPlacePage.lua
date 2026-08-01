-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintPlacePage
-- Date: 2023-10-24 14:55:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintPlacePage = class("UIHomelandBuildBlueprintPlacePage")

function UIHomelandBuildBlueprintPlacePage:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildBlueprintPlacePage:OnExit()
    self.bInit = false
end

function UIHomelandBuildBlueprintPlacePage:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
		HLBOp_Blueprint.CancelMoveBlueprint()
	end)

	UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function ()
		HLBOp_Main.SetMoveObjEnabled(false)
        HLBOp_Blueprint.ConfirmMoveBlueprintPos()
	end)

    UIHelper.BindUIEvent(self.BtnCameraNext, EventType.OnClick, function ()
		HLBOp_Other.NextCameraMode()
		self:UpdateCameraMode()
	end)

	UIHelper.BindUIEvent(self.BtnCameraPrevious, EventType.OnClick, function ()
		HLBOp_Other.PrevCameraMode()
		self:UpdateCameraMode()
	end)

	UIHelper.BindUIEvent(self.BtnRotate, EventType.OnClick, function ()
		HLBOp_Blueprint.RotationBlueprint()
	end)
end

function UIHomelandBuildBlueprintPlacePage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end
function UIHomelandBuildBlueprintPlacePage:UpdateInfo()
	self:UpdateCameraMode()
end

function UIHomelandBuildBlueprintPlacePage:UpdateCameraMode()
	local szMode = string.format("镜头 - %s", HLBOp_Other.GetCameraModeDesc())
	UIHelper.SetString(self.LabelCameraModeName, szMode)
end

return UIHomelandBuildBlueprintPlacePage