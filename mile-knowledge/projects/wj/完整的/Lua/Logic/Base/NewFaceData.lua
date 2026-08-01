NewModule("NewFaceData")
local nVersion = 1
local nOldFaceVersion = 5
local EXPORT_CD_TIME = 5 * 1000
local nMajorVersion = 1 --代表现行版，也有部分老玩家是没有这个变量的，但是怀旧版玩家一定是2

local tRoleName =
{
    [1] = "StandardMale",
    [2] = "StandardFemale",
    [5] = "LittleBoy",
    [6] = "LittleGirl",
}

local tDecalIndex =
{
	[FACE_LIFT_DECAL_TYPE.BASE] 			 = "BASE",
	[FACE_LIFT_DECAL_TYPE.IRIS_LEFT] 		 = "IRIS_LEFT",
	[FACE_LIFT_DECAL_TYPE.IRIS_RIGHT] 		 = "IRIS_RIGHT",
	[FACE_LIFT_DECAL_TYPE.EYE_SHADOW] 		 = "EYE_SHADOW",
	[FACE_LIFT_DECAL_TYPE.EYE_LINE] 		 = "EYE_LINE",
	[FACE_LIFT_DECAL_TYPE.BROW] 			 = "BROW",
	[FACE_LIFT_DECAL_TYPE.BLUSHER_MOUSTACHE] = "BLUSHER_MOUSTACHE",
	[FACE_LIFT_DECAL_TYPE.LIP_GLOSS]		 = "LIP_GLOSS",
	[FACE_LIFT_DECAL_TYPE.EYE_LIGHT]		 = "EYE_LIGHT",
	[FACE_LIFT_DECAL_TYPE.DECAL]			 = "DECAL",
	[FACE_LIFT_DECAL_TYPE.LIP_FLASH]		 = "LIP_FLASH",
	[FACE_LIFT_DECAL_TYPE.LIP_OVERLAP]		 = "LIP_OVERLAP",
	[FACE_LIFT_DECAL_TYPE.LIP_LIGHT]		 = "LIP_LIGHT",

	[FACE_LIFT_DECAL_TYPE.EYE_SHADOW1]		 = "EYE_SHADOW1",
	[FACE_LIFT_DECAL_TYPE.EYE_SHADOW2]		 = "EYE_SHADOW2",
	[FACE_LIFT_DECAL_TYPE.EYE_SHADOW3]		 = "EYE_SHADOW3",
	[FACE_LIFT_DECAL_TYPE.EYE_SHADOW4]		 = "EYE_SHADOW4",
	[FACE_LIFT_DECAL_TYPE.EYE_SHADOW_FLASH1] = "EYE_SHADOW_FLASH1",
	[FACE_LIFT_DECAL_TYPE.EYE_SHADOW_FLASH2] = "EYE_SHADOW_FLASH2",
	[FACE_LIFT_DECAL_TYPE.EYE_SHADOW_FLASH3] = "EYE_SHADOW_FLASH3",
	[FACE_LIFT_DECAL_TYPE.EYE_SHADOW_FLASH4] = "EYE_SHADOW_FLASH4",
}

local tBoneIndex =
{
	[FACE_LIFT_BONE_TYPE.CHEEK_Y] 			= "CHEEK_Y",
	[FACE_LIFT_BONE_TYPE.CHEEK_Z] 			= "CHEEK_Z",
	[FACE_LIFT_BONE_TYPE.FACE_Y] 			= "FACE_Y",
	[FACE_LIFT_BONE_TYPE.FACE_Z] 			= "FACE_Z",
	[FACE_LIFT_BONE_TYPE.UP_FACE] 			= "UP_FACE",
	[FACE_LIFT_BONE_TYPE.LOW_FACE] 			= "LOW_FACE",
	[FACE_LIFT_BONE_TYPE.FACE_SCALE] 		= "FACE_SCALE",
	[FACE_LIFT_BONE_TYPE.JAW_WIDTH] 		= "JAW_WIDTH",
	[FACE_LIFT_BONE_TYPE.JAW_POS] 			= "JAW_POS",
	[FACE_LIFT_BONE_TYPE.JAW_LENGTH] 		= "JAW_LENGTH",
	[FACE_LIFT_BONE_TYPE.JAW_END] 			= "JAW_END",
	[FACE_LIFT_BONE_TYPE.JAW_ROT] 			= "JAW_ROT",
	[FACE_LIFT_BONE_TYPE.NOSE_SIZE] 		= "NOSE_SIZE",
	[FACE_LIFT_BONE_TYPE.NOSE_HEIGHT] 		= "NOSE_HEIGHT",
	[FACE_LIFT_BONE_TYPE.NOSETOP_POS_Z] 	= "NOSETOP_POS_Z",
	[FACE_LIFT_BONE_TYPE.NOSETOP_POS_Y] 	= "NOSETOP_POS_Y",
	[FACE_LIFT_BONE_TYPE.NOSETOP_WIDTH] 	= "NOSETOP_WIDTH",
	[FACE_LIFT_BONE_TYPE.NOSETOP_UP] 		= "NOSETOP_UP",
	[FACE_LIFT_BONE_TYPE.NOSEBOW_WIDTH] 	= "NOSEBOW_WIDTH",
	[FACE_LIFT_BONE_TYPE.NOSEBOW_BEND] 		= "NOSEBOW_BEND",
	[FACE_LIFT_BONE_TYPE.MOUTH_POS] 		= "MOUTH_POS",
	[FACE_LIFT_BONE_TYPE.MOUTH_SIZE] 		= "MOUTH_SIZE",
	[FACE_LIFT_BONE_TYPE.MOUTH_ROT] 		= "MOUTH_ROT",
	[FACE_LIFT_BONE_TYPE.MOUTH_OPEN] 		= "MOUTH_OPEN",
	[FACE_LIFT_BONE_TYPE.MOUTH_OUT] 		= "MOUTH_OUT",
	[FACE_LIFT_BONE_TYPE.MOUTH_END] 		= "MOUTH_END",
	[FACE_LIFT_BONE_TYPE.UP_LIP] 			= "UP_LIP",
	[FACE_LIFT_BONE_TYPE.LOW_LIP] 			= "LOW_LIP",
	[FACE_LIFT_BONE_TYPE.UP_LIP_OUT] 		= "UP_LIP_OUT",
	[FACE_LIFT_BONE_TYPE.LOW_LIP_OUT] 		= "LOW_LIP_OUT",
	[FACE_LIFT_BONE_TYPE.UP_LIP_POS] 		= "UP_LIP_POS",
	[FACE_LIFT_BONE_TYPE.LOW_LIP_POS] 		= "LOW_LIP_POS",
	[FACE_LIFT_BONE_TYPE.MOUTH_END_L] 		= "MOUTH_END_L",
	[FACE_LIFT_BONE_TYPE.MOUTH_END_R] 		= "MOUTH_END_R",
	[FACE_LIFT_BONE_TYPE.OUT] 				= "OUT",
	[FACE_LIFT_BONE_TYPE.EYE_POS] 			= "EYE_POS",
	[FACE_LIFT_BONE_TYPE.EYE_SIZE] 			= "EYE_SIZE",
	[FACE_LIFT_BONE_TYPE.EYE_DIRC] 			= "EYE_DIRC",
	[FACE_LIFT_BONE_TYPE.EYE_DIST] 			= "EYE_DIST",
	[FACE_LIFT_BONE_TYPE.EYE_OPEN] 			= "EYE_OPEN",
	[FACE_LIFT_BONE_TYPE.EYEBOW_OUT] 		= "EYEBOW_OUT",
	[FACE_LIFT_BONE_TYPE.EYEBOW_DIRC] 		= "EYEBOW_DIRC",
	[FACE_LIFT_BONE_TYPE.EYEBOW_POS] 		= "EYEBOW_POS",
	[FACE_LIFT_BONE_TYPE.PUPIL_SIZE] 		= "PUPIL_SIZE",
	[FACE_LIFT_BONE_TYPE.PUPIL_DIRC] 		= "PUPIL_DIRC",
	[FACE_LIFT_BONE_TYPE.UP_LID_POS] 		= "UP_LID_POS",
	[FACE_LIFT_BONE_TYPE.LOW_LID_POS] 		= "LOW_LID_POS",
	[FACE_LIFT_BONE_TYPE.EYECROW_Y] 		= "EYECROW_Y",
	[FACE_LIFT_BONE_TYPE.RIDGE_Y] 			= "RIDGE_Y",
}

local tEmptyData = {fValue1=-1, nColorID=0, fValue2=-1, nShowID=0, fValue3=-1, bUse=false}

local tReDecalIndex = {}
local tReBoneIndex = {}
local InitReIndex = function()
	tReDecalIndex = {}
	for i = 0, FACE_LIFT_DECAL_TYPE.TOTAL - 1 do
		local szKey = tDecalIndex[i]
		tReDecalIndex[szKey] = i
	end

	tReBoneIndex = {}
	for i = 0, FACE_LIFT_BONE_TYPE.TOTAL - 1 do
		local szKey = tBoneIndex[i]
		tReBoneIndex[szKey] = i
	end
end

local function AdjustDataPath(szPath, bCanReName, szSuffix)
	szSuffix = szSuffix or ".ini"
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

function SaveOldFaceData(szFileName, tFace, nRoleType, bLogin)
	if tFace and tFace.tFaceData then
		tFace = tFace.tFaceData
	end
	local tBone = tFace.tBone
	local tDecal = tFace.tDecal
	local nDecorationID = tFace.nDecorationID

	local tDecalData = {}
	for i = 0, FACE_LIFT_DECAL_TYPE.TOTAL - 1 do
		local szKey = tDecalIndex[i]
		tDecalData[szKey] = {}
		tDecalData[szKey] = tDecal[i] or clone(tEmptyData)
	end

	local tBoneData = {}
	for i = 0, FACE_LIFT_BONE_TYPE.TOTAL - 1 do
		local szKey = tBoneIndex[i]
		tBoneData[szKey] = tBone[i]
	end

	local tFaceData = {}

	tFaceData.nVersion = nOldFaceVersion
	tFaceData.nMajorVersion = nMajorVersion
	tFaceData.tBone = tBoneData
	tFaceData.tDecal = tDecalData
	tFaceData.nRoleType = nRoleType
	tFaceData.nDecorationID = nDecorationID
	tFaceData.szFileName = szFileName

	local szFaceDir = GetFullPath("newfacedata")
	-- if SM_IsEnable() then
	-- 	local szRegion, szServer = select(5, GetUserServer())
	-- 	local szAccount = GetUserAccount()
	-- 	szFaceDir = "userdata".."/"..szAccount.."/"..szRegion.."/"..szServer.."/".."FaceDataDir"
	-- end

	CPath.MakeDir(szFaceDir)

	if Platform.IsWindows() then
		szFaceDir = UIHelper.GBKToUTF8(szFaceDir)
	end

	if not szFileName then
		local szSuffix = tRoleName[nRoleType]
		local nTime = GetCurrentTime()

		local time = TimeToDate(nTime)
		local szTime = string.format("%d%02d%02d-%02d%02d%02d", time.year, time.month, time.day, time.hour, time.minute, time.second)
		szFileName = "Face_" .. szSuffix .."_" .. szTime
		if bLogin then
			szFileName = szFileName .. "_Create"
		end
	end

	local szPath = szFaceDir .. "/" .. szFileName
	szPath = AdjustDataPath(szPath, nil, ".dat")
	szPath = string.gsub(szPath, "\\", "/")
	SaveLUAData(szPath, tFaceData)

	return szPath, nVersion
end

function LoadOldFaceData(szFile)
	local tFaceData = LoadLUAData(szFile, false, true, nil, true)
	if not tFaceData or
		not tFaceData.tBone or
		not tFaceData.tDecal or
		not tFaceData.nRoleType
	then
		return
	end

	if not tFaceData.nVersion then
		return
	end

	if tFaceData.bNewFace then
		return nil, g_tStrings.STR_NEW_LOAD_FACEDATA_ERROR_2
	end

	if tFaceData.nMajorVersion and tFaceData.nMajorVersion ~= nMajorVersion then --也有部分老玩家是没有这个变量的，但是怀旧版玩家一定是2
		return nil, g_tStrings.COIN_FACEDATA_ERROR
	end

	if nOldFaceVersion ~= tFaceData.nVersion then
		if tFaceData.nVersion <= 3 then
			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.LIP_FLASH]] = tEmptyData
			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.LIP_OVERLAP]] = tEmptyData
			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.LIP_LIGHT]] = tEmptyData
		end

		if tFaceData.nVersion <= 4 then
			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.EYE_SHADOW1]] = tEmptyData
			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.EYE_SHADOW2]] = tEmptyData
			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.EYE_SHADOW3]] = tEmptyData
			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.EYE_SHADOW4]] = tEmptyData

			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.EYE_SHADOW_FLASH1]] = tEmptyData
			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.EYE_SHADOW_FLASH2]] = tEmptyData
			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.EYE_SHADOW_FLASH3]] = tEmptyData
			tFaceData.tDecal[tDecalIndex[FACE_LIFT_DECAL_TYPE.EYE_SHADOW_FLASH4]] = tEmptyData
		end
		if not tFaceData.nDecorationID then
			tFaceData.nDecorationID = 0
		end
	elseif nOldFaceVersion > 1 then
		if not tFaceData.nDecorationID then
			return
		end
	end

	if table_is_empty(tReDecalIndex) then
		InitReIndex()
	end

	local tFace = {}
	local tDecal = {}
	for szKey, tOneDecal in pairs(tFaceData.tDecal) do
		if not tReDecalIndex[szKey] then
			return
		end
		local i = tReDecalIndex[szKey]
		tDecal[i] = tOneDecal
		if not tDecal[i].nShowID or not tDecal[i].nColorID then
			return
		end
		if tFaceData.nVersion <= 2 and i ~= FACE_LIFT_DECAL_TYPE.LIP_FLASH and i ~= FACE_LIFT_DECAL_TYPE.LIP_OVERLAP and i ~= FACE_LIFT_DECAL_TYPE.LIP_LIGHT then
			tDecal[i].bUse = false
			tDecal[i].fValue1 = -1
			tDecal[i].fValue2 = -1
			tDecal[i].fValue3 = -1
		end
	end
	tFace.tDecal = tDecal

	if table_is_empty(tReBoneIndex) then
		InitReIndex()
	end

	local tBone = {}
	for szKey, nValue in pairs(tFaceData.tBone) do
		if not tReBoneIndex[szKey] then
			return
		end
		local i = tReBoneIndex[szKey]
		tBone[i] = nValue
	end

	tFace.tBone = tBone
	tFace.nRoleType = tFaceData.nRoleType
	tFace.nDecorationID = tFaceData.nDecorationID
	tFace.szFileName = tFaceData.szFileName
	return tFace
end

function SaveFaceData(szFileName, tFace, nRoleType, bLogin)
	local tBone = tFace.tBone
	local tDecal = tFace.tDecal
	local tDecoration = tFace.tDecoration

	local tFaceData = {}
	tFaceData.nVersion = nVersion
	tFaceData.nMajorVersion = nMajorVersion
	tFaceData.tBone = tFace.tBone
	tFaceData.tDecal = tFace.tDecal
	tFaceData.nRoleType = nRoleType
	tFaceData.tDecoration = tDecoration
	tFaceData.szFileName = szFileName
	tFaceData.bNewFace = true
	tFaceData.bShop = not bLogin

	local szFaceDir = GetFullPath("newfacedata")
	-- if SM_IsEnable() then
	-- 	local szRegion, szServer = select(5, GetUserServer())
	-- 	local szAccount = GetUserAccount()
	-- 	szFaceDir = "userdata" .. "/" .. szAccount .. "/" .. szRegion .. "/" .. szServer .. "/" .. "FaceDataDir"
	-- end

	CPath.MakeDir(szFaceDir)

	if Platform.IsWindows() then
		szFaceDir = UIHelper.GBKToUTF8(szFaceDir)
	end

	if not szFileName then
		local szSuffix = tRoleName[nRoleType]
		local nTime = GetCurrentTime()

		local time = TimeToDate(nTime)
		local szTime = string.format("%d%02d%02d-%02d%02d%02d", time.year, time.month, time.day, time.hour, time.minute, time.second)
		szFileName = "New_Face_" .. szSuffix .."_" .. szTime
		if bLogin then
			szFileName = szFileName .. "_Create"
		end
	end

	local szPath = szFaceDir .. "/" .. szFileName
	szPath = AdjustDataPath(szPath)
	szPath = string.gsub(szPath, "\\", "/")
	SaveLUAData(szPath, tFaceData)

	return szPath, nVersion
end

function LoadFaceData(szFile)
	if Platform.IsWindows() and not Lib.IsFileExist(szFile) then
		return
	end

	local tFaceData = LoadLUAData(szFile, false, true, nil, true)
	if not tFaceData or
		not tFaceData.tBone or
		not tFaceData.tDecal or
		not tFaceData.nRoleType
	then
		return
	end

	if not tFaceData.nVersion then
		return
	end

	if tFaceData.nMajorVersion and tFaceData.nMajorVersion ~= nMajorVersion then --客户端不一致
		return nil, g_tStrings.COIN_FACEDATA_ERROR
	end

	if not tFaceData.bNewFace then
		return nil, g_tStrings.STR_NEW_LOAD_FACEDATA_ERROR
	end

	return tFaceData
end

local nLastExportTime = nil
function ExportData(szFileName, tFaceData, nRoleType, bLogin, bUploadData)
	local nTime = GetTickCount()
	if SM_IsEnable() and nLastExportTime and nTime - nLastExportTime < EXPORT_CD_TIME then
		return false, g_tStrings.FACE_DATA_EXPORT_CD
	end
	local szPath = SaveFaceData(szFileName, tFaceData, nRoleType, bLogin)
	nLastExportTime = nTime

	if szPath then
		if not bUploadData then
			if Platform.IsWindows() then
				local dialog = UIHelper.ShowConfirm(g_tStrings.STR_NEW_FACE_DATA_EXPORT, function ()
					local i, folder, file = 0, GetStreamAdaptiveDirPath('newfacedata/')
					CPath.MakeDir(folder)
					OpenFolder(folder)
				end)
				dialog:SetButtonContent("Confirm", g_tStrings.FACE_OPEN_FLODER)
			else
				local scriptView = UIHelper.ShowConfirm(g_tStrings.STR_NEW_FACE_DATA_EXPORT)
				scriptView:HideButton("Cancel")
			end
		end
		return true, szPath
	end

	return false, g_tStrings.FACE_DATA_EXPORT_FAIL
end

function ExportOldData(szFileName, tFaceData, nRoleType, bLogin, bUploadData)
	local nTime = GetTickCount()
	if SM_IsEnable() and nLastExportTime and nTime - nLastExportTime < EXPORT_CD_TIME then
		return false, g_tStrings.FACE_DATA_EXPORT_CD
	end
	local szPath = SaveOldFaceData(szFileName, tFaceData, nRoleType, bLogin)
	nLastExportTime = nTime

	if szPath then
		if not bUploadData then
			if Platform.IsWindows() then
				local dialog = UIHelper.ShowConfirm(g_tStrings.STR_NEW_FACE_DATA_EXPORT, function ()
					local i, folder, file = 0, GetStreamAdaptiveDirPath('newfacedata/')
					CPath.MakeDir(folder)
					OpenFolder(folder)
				end)
				dialog:SetButtonContent("Confirm", g_tStrings.FACE_OPEN_FLODER)
			else
				local scriptView = UIHelper.ShowConfirm(g_tStrings.STR_NEW_FACE_DATA_EXPORT)
				scriptView:HideButton("Cancel")
			end
		end
		return true, szPath
	end

	return false, g_tStrings.FACE_DATA_EXPORT_FAIL
end

function CheckHadCreateRoleFaceCache()
	local szFaceDir = GetFullPath("newfacedata")

	local szAccount = Login_GetAccount()
	local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tbSelectServer = LoginServerList.GetSelectServer()

	local gbkDir = szFaceDir .. "\\" .. szAccount .. "\\" .. UIHelper.UTF8ToGBK(tbSelectServer.szServer)
	local utf8Dir = szFaceDir .. "\\" .. szAccount .. "\\" .. tbSelectServer.szServer
	local szDir = gbkDir
	-- if not Platform.IsWindows() then
	-- 	szDir = utf8Dir
	-- end
	CPath.MakeDir(szDir)

	local szFileName = "create_role_new_face_cache.ini"
	local szPath = szDir .. "\\" .. szFileName

	szPath = string.gsub(szPath, "\\", "/")

	local bHad = false

	local tbData = LoadFaceData(szPath)
	if tbData then
		if not tbData.tBone or
			not tbData.tDecal or
			not tbData.nRoleType
		then
			DelCacheCreateRoleFaceData()
			return bHad
		end

		if not tbData.nVersion then
			DelCacheCreateRoleFaceData()
			return bHad
		end

		if tbData.nMajorVersion and tbData.nMajorVersion ~= nMajorVersion then --客户端不一致
			DelCacheCreateRoleFaceData()
			return bHad
		end

		if not tbData.bNewFace then
			DelCacheCreateRoleFaceData()
			return bHad
		end

		local scriptView = UIHelper.ShowConfirm("上次捏脸过程异常中断，是否选择恢复？", function ()
			local moduleRoleList = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
        	moduleRoleList.CreateRole()
			Event.Dispatch(EventType.OnRestoreBuildFaceCacheData, tbData)
			Event.Reg(NewFaceData, EventType.OnViewOpen, function (nViewID)
				if nViewID == VIEW_ID.PanelBuildFace then
					Event.Dispatch(EventType.OnRestoreBuildFaceCacheDataStep2, tbData)
					Event.UnReg(NewFaceData, EventType.OnViewOpen)
				end
			end)
		end, function ()
			-- del cache
			DelCacheCreateRoleFaceData()
		end)

		bHad = true
	end

	return bHad
end

function AutoCacheCreateRoleFaceData(tFace, nRoleType, nKungfuID)
	local tBone = tFace.tBone
	local tDecal = tFace.tDecal
	local tDecoration = tFace.tDecoration

	local tFaceData = {}
	tFaceData.nVersion = nVersion
	tFaceData.nMajorVersion = nMajorVersion
	tFaceData.tBone = tFace.tBone
	tFaceData.tDecal = tFace.tDecal
	tFaceData.nKungfuID = nKungfuID
	tFaceData.nRoleType = nRoleType
	tFaceData.tDecoration = tDecoration
	tFaceData.bNewFace = true

	local szFaceDir = GetFullPath("newfacedata")
	local szAccount = Login_GetAccount()
	local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tbSelectServer = LoginServerList.GetSelectServer()

	local utf8Dir = szFaceDir .. "\\" .. szAccount .. "\\" .. tbSelectServer.szServer
	local gbkDir = szFaceDir .. "\\" .. szAccount .. "\\" .. UIHelper.UTF8ToGBK(tbSelectServer.szServer)
	local szDir = utf8Dir
	if Platform.IsWindows() then
		szDir = gbkDir
	end
	CPath.MakeDir(szDir)

	if Platform.IsWindows() then
		szDir = UIHelper.GBKToUTF8(szDir)
	end

	local szFileName = "create_role_new_face_cache.ini"
	local szPath = utf8Dir .. "\\" .. szFileName

	szPath = string.gsub(szPath, "\\", "/")
	SaveLUAData(szPath, tFaceData)

	return szPath
end

function DelCacheCreateRoleFaceData()
	local szFaceDir = "newfacedata"

	local szAccount = Login_GetAccount()
	local LoginServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    local tbSelectServer = LoginServerList.GetSelectServer()

	local gbkDir = szFaceDir .. "\\" .. szAccount .. "\\" .. UIHelper.UTF8ToGBK(tbSelectServer.szServer)
	local utf8Dir = szFaceDir .. "\\" .. szAccount .. "\\" .. tbSelectServer.szServer
	local szDir = gbkDir
	if not Platform.IsWindows() then
		szDir = utf8Dir
	end
	CPath.MakeDir(szDir)

	local szFileName = "create_role_new_face_cache.ini"
	local szPath = szDir .. "\\" .. szFileName

	szPath = string.gsub(szPath, "\\", "/")
	Lib.RemoveFile(szPath)
end