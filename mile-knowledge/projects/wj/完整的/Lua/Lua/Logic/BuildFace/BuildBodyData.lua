BuildBodyData = BuildBodyData or {}

local nVersion = 1
local EXPORT_CD_TIME = 5 * 1000
local nMajorVersion = 1 --代表现行版，预设怀旧版玩家是2

local tRoleName =
{
    [1] = "standardmale",
    [2] = "standardfemale",
    [5] = "littleboy",
    [6] = "littlegirl",
}

local tViewClear =
{
	EQUIPMENT_REPRESENT.FACE_EXTEND,
    EQUIPMENT_REPRESENT.BACK_EXTEND,
    EQUIPMENT_REPRESENT.WAIST_EXTEND,
    EQUIPMENT_REPRESENT.WEAPON_STYLE,
    EQUIPMENT_REPRESENT.BIG_SWORD_STYLE,
    EQUIPMENT_REPRESENT.GLASSES_EXTEND,
    EQUIPMENT_REPRESENT.L_GLOVE_EXTEND,
    EQUIPMENT_REPRESENT.R_GLOVE_EXTEND,
}

--create里tParams会为以下赋值
--nRoleType
--bPrice
--aRepresent
function BuildBodyData.Init(tParams)
	for szKey, Data in pairs(tParams) do
		BuildBodyData[szKey] = Data
	end

	local tBodyList, tDefault 	= Table_GetOfficalBodyList(BuildBodyData.nRoleType, BuildBodyData.bPrice)
	BuildBodyData.nBodyCount 		= #tBodyList
	BuildBodyData.tBodyList 		= tBodyList
	BuildBodyData.szDefaultBody 	= tDefault.szFilePath
	BuildBodyData.GetCameraData()

	-- local hWndBody = hFrame:Lookup(BuildBodyData.szWndPath)
	-- BuildBodyData.hWnd = hWndBody

	for _, nRepresentSub in ipairs(tViewClear) do
        BuildBodyData.aRepresent[nRepresentSub] = 0
    end

	if tParams.bPrice then
		BuildBodyData.GetNowBodyData()
		BuildBodyData.GetBodyFreeChance()
		BuildBodyData.UpdateMybodyData()
		local hPlayer = GetClientPlayer()
		if not hPlayer then
			return
		end
		local tFaceData = hPlayer.GetEquipLiftedFaceData()
		local bUseLiftedFace = hPlayer.bEquipLiftedFace
		BuildBodyData.aRepresent.bUseLiftedFace = bUseLiftedFace
		BuildBodyData.aRepresent.tFaceData = tFaceData
	else
		local tBodyParams 		= KG3DEngine.GetBodyDefinitionFromINIFile(BuildBodyData.szDefaultBody)
        if not tBodyParams or table.is_empty(tBodyParams) then
            tBodyParams = {}
            for i = 0, 29, 1 do
                tBodyParams[i] = 0
            end
        end

		BuildBodyData.tNowBodyData 	= tBodyParams
		BuildBodyData.tMyBodyData 	= clone(tBodyParams)
		BuildBodyData.tBodyCloth 	= clone(Table_GetBodyClothList(BuildBodyData.nRoleType))
		BuildBodyData.tNowCloth 	= nil

		-- table.insert(BuildBodyData.tBodyCloth, 1, {
		-- 	nRoleType = BuildBodyData.nRoleType,
		-- 	szRepresent = "",
		-- 	dwIconID = 18989,
		-- })

		-- BuildBodyData.hWndCloth 	= hWndBody:GetParent():GetParent():Lookup("WndContainer_Cloth")
		return
	end
end

function BuildBodyData.UpdateMybodyData()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	BuildBodyData.tMyBodyData = hPlayer.GetEquippedBodyBoneData()
end

function BuildBodyData.UnInit()
	-- View.FreeViewScene()
	BuildBodyData.nRoleType 	= nil
	BuildBodyData.szWndPath 	= nil
	BuildBodyData.bPrice 		= nil
	BuildBodyData.fnGetModel 	= nil
	BuildBodyData.aRepresent 	= nil
	-- BuildBodyData.hWnd 			= nil

	BuildBodyData.nBodyCount 	= nil
	BuildBodyData.tBodyList 	= nil
	BuildBodyData.szDefaultBody = nil
	BuildBodyData.tNowBodyData 	= nil
	BuildBodyData.tMyBodyData 	= nil
	BuildBodyData.aCameraData 	= nil
	BuildBodyData.nFreeChance 	= nil

	BuildBodyData.tBodyCloth 	= nil
	BuildBodyData.tNowCloth 	= nil
	BuildBodyData.tAllBoneInfo 	= nil
	-- BuildBodyData.hWndCloth     = nil

	BuildBodyData.nTimeLimitFreeChance = nil
	BuildBodyData.nTimeLimitFreeChanceEndTime = nil
end

function BuildBodyData.UpdateCloth(szRepresent , tPresetInfo)
	BuildBodyData.tNowCloth = tPresetInfo or {}
	local tInfo = SplitString(szRepresent, ";")
	for _, szString in pairs(tInfo) do
		local tInfo = SplitString(szString, "|")
		local nIndex = tonumber(tInfo[1])
		local nRepresent = tonumber(tInfo[2])
		BuildBodyData.tNowCloth[nIndex] = nRepresent
	end
end

function BuildBodyData.GetNowBodyData()
	BuildBodyData.tNowBodyData = ExteriorCharacter.GetPreviewBody()
end

function BuildBodyData.GetBodyFreeChance()
    local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	BuildBodyData.nFreeChance, BuildBodyData.nTimeLimitFreeChance, BuildBodyData.nTimeLimitFreeChanceEndTime = hPlayer.GetBodyReshapingFreeChance()
end

function BuildBodyData.ResetBodyData()
	BuildBodyData.tNowBodyData = clone(BuildBodyData.tMyBodyData)
end

function BuildBodyData.UpdateNowBodyData(tData)
	for nBodyType, nValue in pairs(tData) do
		BuildBodyData.tNowBodyData[nBodyType] = nValue
	end
end

function BuildBodyData.NowBodyCloneData(tData)
	BuildBodyData.tNowBodyData = clone(tData)
end

function BuildBodyData.GetCameraData()
	if BuildBodyData.aCameraData then
		return BuildBodyData.aCameraData
	end
	BuildBodyData.aCameraData = g_tRoleBodyView
end

function BuildBodyData.GetModelView(w, h, bFirst)
	local ModelView
	if BuildBodyData.bPrice then
		ModelView = CoinShop.GetModelView(bFirst, "BodyShop")
	else
		ModelView = PlayerModelView.new()
		ModelView:InitBy({bModLod = true, szName = "LoginBody"})
	end
	return ModelView
end

function BuildBodyData.GetAllBoneInfo()
	if BuildBodyData.tAllBoneInfo then
		return BuildBodyData.tAllBoneInfo
	end

	local hBodyLiftManager = GetBodyReshapingManager()
	if not hBodyLiftManager then
		return
	end
	local tBodyInfo = hBodyLiftManager.GetAllBoneInfo(BuildBodyData.nRoleType)
	BuildBodyData.tAllBoneInfo = tBodyInfo
	return tBodyInfo
end

function BuildBodyData.GetScrollPos(nValue, nMin, nStep)
	local nPos = math.floor((nValue -  nMin) / nStep + 0.5)
	return nPos
end

function BuildBodyData.IsTableEqual(t1, t2)
	if type(t1) ~= "table" or type(t2) ~= "table" then
		return false
	end
	local tKeyList = {}
	for k, v in ipairs(t1) do
		local szType = type(v)
		if (szType == "table" and not BuildBodyData.IsTableEqual(v, t2[k]))
				or (szType ~= "table" and v ~= t2[k]) then
			return false
		end
		tKeyList[k] = true
	end

	for k, _ in ipairs(t2) do
		if not tKeyList[k] then
			return false
		end
	end
	return true
end

function BuildBodyData.ImportData(tBodyData)
	local hManager = GetBodyReshapingManager()
	local nRetCode = hManager.CheckValid(BuildBodyData.nRoleType, tBodyData.tBody)
	if nRetCode ~= BODY_RESHAPING_ERROR_CODE.SUCCESS then
		local szMsg = g_tStrings.tBodyCheckNotify[nRetCode]
		TipsHelper.ShowNormalTip(szMsg)
		return
	end
	BuildBodyData.NowBodyCloneData(tBodyData.tBody)
	return true
end

function BuildBodyData.ExportedFolder()
	return UIHelper.GBKToUTF8(GetStreamAdaptiveDirPath(GetFullPath("bodydata") .. "/"))
end

local function AdjustDataPath(szPath, bCanReName)
	local szSuffix = ".dat"
	local szAdjust = szPath .. szSuffix
    if Platform.IsWindows() then
        if not Lib.IsFileExist(UIHelper.UTF8ToGBK(szAdjust), false) then
            return szAdjust
        end
    else
        if not Lib.IsFileExist(szAdjust, false) then
            return szAdjust
        end
	end

	if bCanReName == nil or bCanReName then
		for i = 1, 100 do
			local szAdjust = szPath .. "(" .. i.. ")" .. szSuffix
			if not Lib.IsFileExist(szAdjust) then
				return szAdjust
			end
		end

		local nTickCount = GetTickCount()
		szAdjust = szPath .. "(" .. nTickCount.. ")" .. szSuffix
	end

	return szAdjust
end

function BuildBodyData.SaveBodyData(tBody, nRoleType, bLogin, szFileName)
	local tBodyData = {}

	tBodyData.nVersion = nVersion
	tBodyData.nMajorVersion = nMajorVersion
	tBodyData.tBody = clone(tBody)
	tBodyData.nRoleType = nRoleType
	tBodyData.szFileName = szFileName

	local szBodyDir = GetFullPath("bodydatadir")
	CPath.MakeDir(szBodyDir)

	if Platform.IsWindows() then
		szBodyDir = UIHelper.GBKToUTF8(szBodyDir)
	end

	-- if SM_IsEnable() then
	-- 	local szRegion, szServer = select(5, GetUserServer())
	-- 	local szAccount = GetUserAccount()
	-- 	szBodyDir = "userdata".."/"..szAccount.."/"..szRegion.."/"..szServer.."/".."bodydatadir"
	-- end
	local szSuffix = tRoleName[nRoleType]
	local nTime = GetCurrentTime()

	if not szFileName then
		local time = TimeToDate(nTime)
		local szTime = string.format("%d%02d%02d-%02d%02d%02d", time.year, time.month, time.day, time.hour, time.minute, time.second)
		szFileName = "body_" .. szSuffix .."_" .. szTime
		if bLogin then
			szFileName = szFileName .. "_create"
		end
	end

	local szPath = szBodyDir .. "/" .. szFileName
	szPath = AdjustDataPath(szPath)
	szPath = string.gsub(szPath, "\\", "/")
	SaveLUAData(szPath, tBodyData)

	return szPath, nVersion
end

function BuildBodyData.LoadBodyData(szFile)
	local tBodyData = LoadLUAData(szFile, false, true, nil, true)
	if not tBodyData or
		not tBodyData.tBody
	then
		return
	end

	if not tBodyData.nVersion then
		return
	end

	if tBodyData.nVersion and tBodyData.nVersion == 1 then
		tBodyData.tBody[BODY_BONE_TYPE.MUSCLE_MASS] = 0
	end

	if tBodyData.nMajorVersion and tBodyData.nMajorVersion ~= nMajorVersion then
		return nil, g_tStrings.STR_BODYDATA_ERROR
	end

	return tBodyData
end

local nLastExportTime = nil
function BuildBodyData.ExportData(szFileName, tBodyData, nRoleType, bLogin, bUploadData)
	local nTime = GetTickCount()
	-- if SM_IsEnable() and nLastExportTime and nTime - nLastExportTime < EXPORT_CD_TIME then
	-- 	return g_tStrings.STR_BODY_DATA_EXPORT_CD, "MSG_ANNOUNCE_RED"
	-- end

	local szPath = BuildBodyData.SaveBodyData(tBodyData, nRoleType, bLogin, szFileName)
	nLastExportTime = nTime
    local szMsg = FormatString( g_tStrings.STR_BODY_DATA_EXPORT, szPath)

	if szPath then
		if not bUploadData then
			if Platform.IsWindows() then
				local dialog = UIHelper.ShowConfirm(szMsg, function ()
					local i, folder, file = 0, GetStreamAdaptiveDirPath('bodydatadir/')
					CPath.MakeDir(folder)
					OpenFolder(folder)
				end)
				dialog:SetButtonContent("Confirm", g_tStrings.FACE_OPEN_FLODER)
			else
				local scriptView = UIHelper.ShowConfirm(szMsg)
				scriptView:HideButton("Cancel")
			end
		end
		return true, szPath
	end

	return false, g_tStrings.FACE_DATA_EXPORT_FAIL
end