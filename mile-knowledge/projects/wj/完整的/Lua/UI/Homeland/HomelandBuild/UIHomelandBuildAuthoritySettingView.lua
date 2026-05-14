-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildAuthoritySettingView
-- Date: 2023-06-20 17:16:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildAuthoritySettingView = class("UIHomelandBuildAuthoritySettingView")

function UIHomelandBuildAuthoritySettingView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local _, _, nLandIndex = HomelandBuildData.GetMapInfo()
    HomelandBuildData.GetHomelandMgrObj().ApplyHLLandInfo(nLandIndex)
end

function UIHomelandBuildAuthoritySettingView:OnExit()
    self.bInit = false
end

function UIHomelandBuildAuthoritySettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        self.tbData[1].bAllShow = true
        UIHelper.SetSelected(self.tbTogs[1], self.tbData[1].bAllShow)
        UIHelper.SetSelected(self.tbTogs[2], not self.tbData[1].bAllShow)
    end)

    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function ()
        UIMgr.Close(self)
        local _, _, nLandIndex = HomelandBuildData.GetMapInfo()
        local bResult = HomelandBuildData.GetHomelandMgrObj().ApplySetPermission(nLandIndex, 0, self.tbData[1].bAllShow)
        if not bResult then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_HOMELAND_LICENSE_TIP)
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_HOMELAND_LICENSE_SUCCESS)
            HomelandBuildData.GetHomelandMgrObj().ApplyHLLandInfo(nLandIndex)
        end
    end)

    for i, tog in ipairs(self.tbTogs) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            if i == 1 then
                self.tbData[1].bAllShow = true
            elseif i == 2 then
                self.tbData[1].bAllShow = false
            end

            UIHelper.SetSelected(self.tbTogs[1], self.tbData[1].bAllShow)
            UIHelper.SetSelected(self.tbTogs[2], not self.tbData[1].bAllShow)
        end)
    end
end

function UIHomelandBuildAuthoritySettingView:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function()
        local nRetCode = arg0
        if nRetCode == HOMELAND_RESULT_CODE.APPLY_HLLAND_INFO or nRetCode == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then  --申请某块地详情
			self:UpdateInfo()
		end
    end)
end

function UIHomelandBuildAuthoritySettingView:UpdateInfo()
    local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
	local tHLLandInfo = HomelandBuildData.GetHomelandMgrObj().GetHLLandInfo(nLandIndex)
    if not tHLLandInfo then
        LOG.ERROR("UIHomelandBuildAuthoritySettingView:UpdateInfo Error!tHLLandInfo is nil!")
        return
    end

    self.tbData = self:ParseData(tHLLandInfo.uPermission)
    UIHelper.SetSelected(self.tbTogs[1], self.tbData[1].bAllShow)
    UIHelper.SetSelected(self.tbTogs[2], not self.tbData[1].bAllShow)
end

function UIHomelandBuildAuthoritySettingView:ParseData(uPermission)
	--目前只有一组权限写死，以后多了会配表  uPermission 每一位代表组的权限 1 所有人 0 仅自己
	--local nValue = GetValueByBits(uPermission, 0, 1)
	local bAllShow = kmath.is_bit1(uPermission, 1) --nValue > 0 or false
	local tbData = {{szFurnitureName = "", bAllShow = bAllShow},}
	return tbData
end

return UIHomelandBuildAuthoritySettingView