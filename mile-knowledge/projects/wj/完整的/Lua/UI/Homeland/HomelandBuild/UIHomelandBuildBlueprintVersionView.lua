-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildBlueprintVersionView
-- Date: 2023-11-28 15:36:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildBlueprintVersionView = class("UIHomelandBuildBlueprintVersionView")

local m_nLastFreshTime = 0
local REOPEN_CD = 2

local szKeyForGetList = "HomelandGetSNList"
local szUrlForGetList = "https://gdca-blueprint-api.xoyo.com/gamegw/home-blueprint/get-digital-asset-use-list-by-issue"
local szUrlForGetList_Test = "http://120.92.151.103/gamegw/home-blueprint/get-digital-asset-use-list-by-issue"
local szWebDataSign = "REQUEST_FOR_GET_BLUEPRINT_SN_LIST"
local IN_USE = 2
local IN_FREE = 1

local USE_MAP = {
	COMMUNITY = 1,
	PRIVATE = 2,
	BOTH = 3,
}

function UIHomelandBuildBlueprintVersionView:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.m_szCipher = nil
    self.m_szPreRequestKey = nil
    self.m_szCode = tbInfo.szCode
    self.m_szURL = tbInfo.szDetailUrl
    self.m_bExistReplica = tbInfo.bExistReplica

    self.tbInfo = tbInfo
    self:ApplySign()
end

function UIHomelandBuildBlueprintVersionView:OnExit()
    self.bInit = false
end

function UIHomelandBuildBlueprintVersionView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function(btn)
        Homeland_OpenHomelandURL(self.m_szURL, true, "BlueprintDetail")
    end)

    UIHelper.BindUIEvent(self.BtnUnload, EventType.OnClick, function(btn)
        if not self.szCode then
            TipsHelper.ShowNormalTip("暂无可卸载蓝图")
            return
        end

        HLBOp_Save.DoApplyUninstall(self.szCode)
        UIMgr.Close(self)
    end)

end

function UIHomelandBuildBlueprintVersionView:RegEvent()
    Event.Reg(self, "ON_WEB_DATA_SIGN_NOTIFY", function ()
		local szOrderSN                 = arg6
		local dwType 					= arg1
		if not (dwType == WEB_DATA_SIGN_RQST.LOGIN and szOrderSN == szWebDataSign) then
			return
		end
		self:OnApplySign()
		self:PostGetSNList(self.m_szCode)
	end)

	Event.Reg(self, "CURL_REQUEST_RESULT", function ()
		local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3
		if szKey == self.m_szPreRequestKey and bSuccess then
			local tInfo, szErrMsg = JsonDecode(szValue)
			Homeland_Log("Blueprint_SerialNum", tInfo, szErrMsg)
			self:OnPostGetSNList(tInfo)
		end
	end)

	Event.Reg(self, "HOMELANDBUILDING_ON_CLOSE", function ()
		UIMgr.Close(self)
	end)
end

function UIHomelandBuildBlueprintVersionView:UpdateInfo(tCodeList, tDLCList)
	UILog("tCodeList", tCodeList)
	UILog("tDLCList", tDLCList)
    local tInfo = tCodeList[1]
    self.szCode = tInfo.szCode
    UIHelper.SetString(self.LabelCode, tInfo.szCode)

	local bUse = false
	local nMode = HLBOp_Main.GetBuildMode()
	if tInfo.nStatus == IN_USE and nMode == BUILD_MODE.COMMUNITY and (tInfo.eUseMap == USE_MAP.COMMUNITY or tInfo.eUseMap == USE_MAP.BOTH)  then
		bUse = true
	end
	if tInfo.nStatus == IN_USE and nMode == BUILD_MODE.PRIVATE and (tInfo.eUseMap == USE_MAP.PRIVATE or tInfo.eUseMap == USE_MAP.BOTH) then
		bUse = true
	end

	local bDigitalInLand = HLBOp_Enter.IsDigitalBlueprintInLand()
	local bThisCodeInLand = bUse
	local bEnableUseDefault = true
	local bEnableUseReplica = self.m_bExistReplica
	local bEnableUnload = bDigitalInLand and bThisCodeInLand
	local bNeedUnloadOther = false

    UIHelper.SetVisible(self.ImgInUse, bUse)
    UIHelper.SetVisible(self.BtnUnload, bEnableUnload)
    UIHelper.LayoutDoLayout(self.LayoutBtns)

    local tbList = {}
    table.insert(tbList, {
        szName = self.tbInfo.szTitle or "默认版本",
        szCode = tInfo.szCode,
        bDefault = true,
        bForbidden = not bEnableUseDefault,
		bNeedUnloadOther = bNeedUnloadOther,
    })

    table.insert(tbList, {
        szName = "我的副本",
        szCode = tInfo.szCode,
        bDefault = false,
        bForbidden = not bEnableUseReplica,
		bNeedUnloadOther = bNeedUnloadOther,
		bNotExistReplica = not self.m_bExistReplica,
    })

    for i, tbInfo in ipairs(tDLCList) do
        table.insert(tbList, {
            szName = tbInfo.szDLCName,
            szCode = tInfo.szCode,
            szDLCCode = tbInfo.szDLCCode,
            bDefault = false,
            bForbidden = bNeedUnloadOther,
			bNeedUnloadOther = bNeedUnloadOther,
		})
    end

    UIHelper.HideAllChildren(self.ScrollViewVerSionChoose)
    self.tbCells = self.tbCells or {}
    for i, tbInfo in ipairs(tbList) do
        if not self.tbCells[i] then
            self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetBlueprintVersionCell, self.ScrollViewVerSionChoose)
        end

        UIHelper.SetVisible(self.tbCells[i]._rootNode, true)
        self.tbCells[i]:OnEnter(tbInfo)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewVerSionChoose)
	UIHelper.ScrollViewSetupArrow(self.ScrollViewVerSionChoose, self.WidgetArrow)
end

function UIHomelandBuildBlueprintVersionView:ApplySign()
	local pPlayer = GetClientPlayer()
	if not pPlayer then
		return
	end
	Log("ApplySign")
	pPlayer.ApplyWebDataSign(WEB_DATA_SIGN_RQST.LOGIN, szWebDataSign)
end

function UIHomelandBuildBlueprintVersionView:OnApplySign()
	local uSign                     = arg0
	local dwType 					= arg1
	local nTime                     = arg2
	local nZoneID                   = arg3
	local dwCenterID                = arg4
	local bIsFirstWebPhoneVerified  = arg5
	local szOrderSN                 = arg6

	if not (dwType == WEB_DATA_SIGN_RQST.LOGIN and szOrderSN == szWebDataSign) then
		return
	end

	local szCipher = Homeland_GenerateCipher(uSign, dwType, nTime, nZoneID, dwCenterID)
	Log("==== Blueprint szCipher === " .. tostring(szCipher))
	self.m_szCipher = szCipher
end

function UIHomelandBuildBlueprintVersionView:PostGetSNList(szCode)
	local tHttpData = {}
	tHttpData["cipher"] = self.m_szCipher
	tHttpData["globalRoleId"] = GetClientPlayer().GetGlobalID()
	tHttpData["issueAssetCode"] = szCode
	UILog("PostGetSNList", tHttpData)
	-- Homeland_TransformDataEncode(tHttpData)
	self.m_szPreRequestKey = szKeyForGetList .. GetTickCount()
	CURL_HttpPost(self.m_szPreRequestKey, self:GetAPIURL(),
		JsonEncode(tHttpData), true, 60, 60, { [1] = "Content-Type:application/json"})
end

function UIHomelandBuildBlueprintVersionView:OnPostGetSNList(tInfo)
	local tCodeList, tDLCList = {}, {}
    if tInfo.code == 0 then
        tCodeList, tDLCList = self:HandleResponse(tInfo)
    end

	self:UpdateInfo(tCodeList, tDLCList)
end

function UIHomelandBuildBlueprintVersionView:HandleResponse(tInfo)
	local tCodeList = {}
	local tDLCList = {}
	local tTemp = tInfo.data.useAssetList
	if tTemp then
        for i = 1, #tTemp do
            local tTable = {szCode = tTemp[i].useAssetCode, nStatus = tTemp[i].status, eUseMap = tTemp[i].useMap}
            table.insert(tCodeList, tTable)
        end
    end
	tTemp = tInfo.data.dlcList
	if tTemp then
		for i = 1, #tTemp do
			local tTable = {szDLCCode = tTemp[i].dlcId, szDLCName = tTemp[i].dlcName}
			table.insert(tDLCList, tTable)
		end
	end
	return tCodeList, tDLCList
end

function UIHomelandBuildBlueprintVersionView:GetAPIURL()
	if IsDebugClient() or IsVersionExp() then
		return szUrlForGetList_Test
	else
		return szUrlForGetList
	end
end

return UIHomelandBuildBlueprintVersionView