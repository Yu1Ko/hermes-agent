BuildFaceData = BuildFaceData or {}

local MAX_DECAL_COUNT = 28
local DECORATION_ARENA_ID = 5
local DETAIL_ADJUST_STEP = 0.01
local tDecorationClass = {
	[1] = {
		nDecorationType = FACE_LIFT_DECORATION_TYPE.MOUTH,
		szSubClassName = UIHelper.UTF8ToGBK(g_tStrings.STR_NEW_FACE_LIFT_DECORATION_SUB_MOUTH),
		bLoginShow = false,
	},
	[2] = {
		nDecorationType = FACE_LIFT_DECORATION_TYPE.NOSE,
		szSubClassName = UIHelper.UTF8ToGBK(g_tStrings.STR_NEW_FACE_LIFT_DECORATION_SUB_NOSE),
		bLoginShow = false,
	},
	nLabel = 0,
	bIsDecoration = true,
	szClassName = UIHelper.UTF8ToGBK(g_tStrings.STR_NEW_FACE_LIFT_DECORATION),
}
local tDefaultEmptyFaceData = {
	bNewFace = false,
}
local DECORATION_ADJUST_MIN = 0
local DECORATION_ADJUST_MAX = 2

---↓左右同步↓---
local tMeanwhile =
{
	[1] = {nAreaID = 2, nClassID = 2},
	[2] = {nAreaID = 2, nClassID = 3},
}

local tMeanwhileMapping =
{
	[FACE_LIFT_DECAL_TYPE_V2.IRIS_LEFT] = {dwKey = 1, dwMappingType = FACE_LIFT_DECAL_TYPE_V2.IRIS_RIGHT},
	[FACE_LIFT_DECAL_TYPE_V2.IRIS_RIGHT] = {dwKey = 1, dwMappingType = FACE_LIFT_DECAL_TYPE_V2.IRIS_LEFT},
	[FACE_LIFT_DECAL_TYPE_V2.EYE_WHITE_LEFT] = {dwKey = 2, dwMappingType = FACE_LIFT_DECAL_TYPE_V2.EYE_WHITE_RIGHT},
	[FACE_LIFT_DECAL_TYPE_V2.EYE_WHITE_RIGHT] = {dwKey = 2, dwMappingType = FACE_LIFT_DECAL_TYPE_V2.EYE_WHITE_LEFT},
}
---↑左右同步↑---

local function ParsePointList(szPoint)
	local tList = {}
	for szIndex in string.gmatch(szPoint, "([%d-]+)") do
		local nPoint = tonumber(szIndex)
		table.insert(tList, nPoint)
	end
	return tList
end

--tParams会为以下赋值
--nRoleType
--bPrice
--nMaxDecalCount 妆容里一页最多放多少个
--tMyFaceData
function BuildFaceData.Init(tParams)
	for szKey, Data in pairs(tParams) do
		BuildFaceData[szKey] = Data
	end

	BuildFaceData.LoadFaceDecoration()
	BuildFaceData.GetFaceDefaultList()
	BuildFaceData.InitDefaultData()
	BuildFaceData.GetFaceBoneList()
	BuildFaceData.GetFaceDecalList()
	BuildFaceData.GetOldFaceDecalList()
	if not tParams.bPrice then
		BuildFaceData.tLoginScene 	= Table_GetLoginSceneList()
	end
end

function BuildFaceData.InitDefaultData()
	local tDefaultFaceData 		= {}
	local szFile 				= BuildFaceData.szDefaultFace
	tDefaultFaceData 			= BuildFaceData.GetFaceByFile(szFile)
	BuildFaceData.tDefaultFaceData 	= tDefaultFaceData
	if BuildFaceData.bPrice then
		BuildFaceData.ReInitDefaultData()
	else
		BuildFaceData.bCanOperate 	= true
		BuildFaceData.tMyFaceData 	= clone(BuildFaceData.tDefaultFaceData)
		BuildFaceData.tNowFaceData 	= clone(BuildFaceData.tDefaultFaceData)
	end
	BuildFaceData.tMeanwhileSwitch  = {false, false}
end

function BuildFaceData.UpdateCanOperate()
	BuildFaceData.bCanOperate = ExteriorCharacter.IsNewFace()
end

function BuildFaceData.ReInitNowData()
	local tData = ExteriorCharacter.GetPreviewNewFace() or {}
	BuildFaceData.tNowFaceData = clone(tData)
end

function BuildFaceData.ReInitDefaultData()
	local tData = ExteriorCharacter.GetPreviewNewFace()

	if not tData or table.is_empty(tData) then
		local tData1 = ExteriorCharacter.GetPreviewFace()
		if tData1 then
			tData = tData1.UserData
		end
	end

	if not tData then
		return
	end

	BuildFaceData.tMyFaceData = clone(tData)
	if BuildFaceData.bPrice then
		BuildFaceData.tNowFaceData = clone(tData)
	else
		BuildFaceData.tNowFaceData = clone(BuildFaceData.tDefaultFaceData)
	end
	BuildFaceData.UpdateCanOperate()
end

function BuildFaceData.UnInit()
	BuildFaceData.nRoleType = nil
	BuildFaceData.szWndPath = nil
	BuildFaceData.bPrice = nil
	BuildFaceData.szIniFile = nil
	BuildFaceData.nMaxDecalCount = nil

	BuildFaceData.tAllBoneInfo = nil
	BuildFaceData.tOldAllBoneInfo = nil

	BuildFaceData.nDefaultCount = nil
	BuildFaceData.nDefaultPage = nil
	BuildFaceData.szDefaultFace = nil
	BuildFaceData.tFaceList = nil

	BuildFaceData.nOldDefaultCount = nil
	BuildFaceData.nOldDefaultPage = nil
	BuildFaceData.szOldDefaultFace = nil
	BuildFaceData.tOldFaceList = nil

	BuildFaceData.tDefaultFaceData = nil
	BuildFaceData.tNowFaceData = nil
	BuildFaceData.bCanOperate = nil

	BuildFaceData.tFaceBoneList = nil
	BuildFaceData.tOldFaceBoneList = nil

	BuildFaceData.bInitBone = nil
	BuildFaceData.tBoneAreaDefault = nil
	BuildFaceData.nBoneAreaDefault = nil
	BuildFaceData.nAreaDefaultPage = nil

	BuildFaceData.bInitDecal = nil
	BuildFaceData.tFaceDecalsList = nil
	BuildFaceData.tFaceDecalsMap = nil
	BuildFaceData.nDecorationLabel = nil

	BuildFaceData.tFaceDecoration = nil
	BuildFaceData.tFaceDecMap = nil

	BuildFaceData.tFaceDecorationColorMap = nil
	BuildFaceData.tDecalData = nil

	BuildFaceData.bFaceParamsInit = nil
	BuildFaceData.tDecalClassList = nil
	BuildFaceData.tOldDecalClassList = nil

	BuildFaceData.bChangeSide = nil

	BuildFaceData.bInBuildMode = nil

	Timer.DelAllTimer(BuildFaceData)
end

function BuildFaceData.GetFaceBoneList()
    BuildFaceData.tFaceBoneList = Table_GetFaceBoneV2List()
    BuildFaceData.tOldFaceBoneList = Table_GetFaceBoneList()
end

function BuildFaceData.ResetFaceData()
	if BuildFaceData.bPrice then
		BuildFaceData.tNowFaceData = clone(BuildFaceData.tMyFaceData)
	else
		BuildFaceData.tNowFaceData = clone(BuildFaceData.tDefaultFaceData)
	end

	BuildFaceData.bCanOperate = BuildFaceData.tNowFaceData.bNewFace
end

function BuildFaceData.EmptyNowFaceData()
	if not BuildFaceData.bCanOperate then
		BuildFaceData.tNowFaceData = clone(tDefaultEmptyFaceData)
	end
end

function BuildFaceData.GetFaceDefaultList()
    local tFaceList, tDefault = Table_GetOfficalFaceV2List(BuildFaceData.nRoleType, BuildFaceData.bPrice)
    BuildFaceData.nDefaultCount = #tFaceList
	BuildFaceData.szDefaultFace = tDefault.szFilePath
	BuildFaceData.tFaceList = tFaceList

	tFaceList, tDefault = Table_GetOfficalFaceList(BuildFaceData.nRoleType, BuildFaceData.bPrice)
	BuildFaceData.nOldDefaultCount = #tFaceList
	BuildFaceData.szOldDefaultFace = tDefault.szFilePath
	BuildFaceData.tOldFaceList = tFaceList
end

function BuildFaceData.GetAreaDefault(szAreaDefault)
    BuildFaceData.tBoneAreaDefault	= SplitString(szAreaDefault, ";")
    BuildFaceData.nBoneAreaDefault  = #BuildFaceData.tBoneAreaDefault
end

function BuildFaceData.GetAllBoneInfo()
	if BuildFaceData.tAllBoneInfo then
		return BuildFaceData.tAllBoneInfo
	end

	local hFaceLiftManager = GetFaceLiftManager()
	if not hFaceLiftManager then
		return
	end
	local tBoneInfo = hFaceLiftManager.GetBoneInfoV2(BuildFaceData.nRoleType)
	BuildFaceData.tAllBoneInfo = tBoneInfo

	return tBoneInfo
end

function BuildFaceData.GetOldAllBoneInfo()
	if BuildFaceData.tOldAllBoneInfo then
		return BuildFaceData.tOldAllBoneInfo
	end

	local hFaceLiftManager = GetFaceLiftManager()
	if not hFaceLiftManager then
		return
	end
	local tBoneInfo = hFaceLiftManager.GetBoneInfo(BuildFaceData.nRoleType)
	BuildFaceData.tOldAllBoneInfo = tBoneInfo

	return tBoneInfo
end

function BuildFaceData.GetScrollPos(nValue, nMin, nStep)
	local nPos = math.floor((nValue -  nMin) / nStep + 0.5)
	return nPos
end

function BuildFaceData.IsValueEquial(fValue1, fValue2)
	fValue1 = math.floor(fValue1 * 100 + 0.5) / 100
	fValue2 = math.floor(fValue2 * 100 + 0.5) / 100
	if math.abs(fValue1 - fValue2) < 0.01 then
		return true
	end
	return false
end

function BuildFaceData.IsOneDecalModify(tDecal1, tDecal2)
	if not BuildFaceData.IsValueEquial(tDecal1.fValue1, tDecal2.fValue1) then
		return true
	end

	if not BuildFaceData.IsValueEquial(tDecal1.fValue2, tDecal2.fValue2) then
		return true
	end

	if not BuildFaceData.IsValueEquial(tDecal1.fValue3, tDecal2.fValue3) then
		return true
	end
end

function BuildFaceData.IsEqualFace(tData1, tData2)
	if not tData1 or not tData2 then
		return false
	end

	if not IsTableEqual(tData1.tBone, tData2.tBone) then
		return false
	end

	if not IsTableEqual(tData1.tDecoration, tData2.tDecoration) then
		return false
	end

	for k, v in pairs(tData1.tDecal) do
		local v2 = tData2.tDecal[k]
		if v.nShowID ~= v2.nShowID or v.nColorID ~= v2.nColorID then
			return false
		end
		if v.bUse ~= v2.bUse then
			return false
		end
		if v.bUse and BuildFaceData.IsOneDecalModify(v, v2) then
			return false
		end
	end

	return true
end

function BuildFaceData.IsEqualPartFace(tNowData, tNewData)
	if not tNewData then
		return false
	end
	for k, v in pairs(tNewData) do
		if tNowData[k] ~= v then
			return false
		end
	end
	return true
end

function BuildFaceData.GetFaceByFile(szFile)
	BeginSample("BuildFaceData.GetFaceByFile")
	local tData = {}
	local tBoneParams, tDecals, tDecoration = KG3DEngine.GetFaceDefinitionFromINIFile(szFile, true)
	tData.tBone 		= tBoneParams
	tData.tDecal 		= tDecals
	tData.tDecoration 	= tDecoration
	tData.bNewFace		= true
	EndSample()
	return tData
end

function BuildFaceData.GetFaceByFileAsync(szFile, funcLoadedCallback)
	BuildFaceData.tbGetFaceByFileQueue = BuildFaceData.tbGetFaceByFileQueue or {}

	table.insert(BuildFaceData.tbGetFaceByFileQueue, {
		szFile = szFile,
		funcLoadedCallback = funcLoadedCallback,
	})

	if not BuildFaceData.nGetFaceByFileAsyncTimerID then
		BuildFaceData.nGetFaceByFileAsyncTimerID = Timer.AddFrameCycle(BuildFaceData, 1, function ()
			local nLeftTimes = 1
			for i = 1, nLeftTimes, 1 do
				local tbParams = BuildFaceData.tbGetFaceByFileQueue[1]
				if not tbParams then
					Timer.DelTimer(self, BuildFaceData.nGetFaceByFileAsyncTimerID)
					BuildFaceData.nGetFaceByFileAsyncTimerID = nil
					return
				end

				local tFaceConfig = BuildFaceData.GetFaceByFile(tbParams.szFile)
				if tbParams.funcLoadedCallback then
					tbParams.funcLoadedCallback(tFaceConfig)
				end

				table.remove(BuildFaceData.tbGetFaceByFileQueue, 1)
			end
		end)
	end

end

function BuildFaceData.GetOldFaceByFile(szFile)
	local tData = {}
	local tBoneParams, tDecals, nDecorationID = KG3DEngine.GetFaceDefinitionFromINIFile(szFile)
	tData.tBone 			= tBoneParams
	tData.tDecal 			= tDecals
	tData.nDecorationID 	= nDecorationID
	tData.bNewFace			= false
	return tData
end

function BuildFaceData.GetFacePartByFile(szFile)
	BeginSample("BuildFaceData.GetFacePartByFile")
	local tBoneParams = KG3DEngine.GetFaceBonePartParamsFromFile(szFile)
	EndSample()
	return tBoneParams
end

function BuildFaceData.SetFacePartByFile(tBoneParams)
	local tData = BuildFaceData.tNowFaceData.tBone
	for k, v in pairs(tBoneParams) do
		tData[k] = v
	end
end

function BuildFaceData.NowFaceCloneData(tData, bCanOperate)
	local hManager = GetFaceLiftManager()
	if not hManager then
		return
	end

	if BuildFaceData.bPrice then
		local tRepresentID = ExteriorCharacter.GetRoleRes()
		tRepresentID.bUseLiftedFace = true
	end

	if bCanOperate then
		BuildFaceData.tNowFaceData = clone(tData)
	else
        local bHave, nIndex = hManager.IsAlreadyHave(tData)
		local tData1 = {
			tFaceData = tData,
		}

		if bHave then
			tData1.nIndex = nIndex
		elseif BuildFaceData.tNowFaceData and BuildFaceData.tNowFaceData.nIndex then
			tData1.nIndex = BuildFaceData.tNowFaceData.nIndex
		end
		BuildFaceData.tNowFaceData = clone(tData1)
	end

	if BuildFaceData.bPrice then
		if BuildFaceData.bCanOperate ~= bCanOperate then
			ExteriorCharacter.ChangeFaceType(bCanOperate)
		end
	end
	BuildFaceData.bCanOperate = bCanOperate
end

function BuildFaceData.UpdateNowFaceData(szKey1, szkey2, nValue)
	BuildFaceData.tNowFaceData[szKey1][szkey2] = nValue
end

function BuildFaceData.UpdateNowFaceDecal(nType, nShowID, nColorID)
	local tDecal = BuildFaceData.tNowFaceData.tDecal[nType]
	if not tDecal then
		return
	end

	tDecal = Lib.copyTab(tDecal)

	if nColorID then
		tDecal.nColorID = nColorID
	else
		if tDecal.nShowID ~= nShowID then
			local hFaceLiftManager = GetFaceLiftManager()
			if not hFaceLiftManager then
				return
			end

			if nShowID == 0 then
				tDecal.nColorID = 0
			else
				local tLogicDecal = hFaceLiftManager.GetDecalInfoV2(BuildFaceData.nRoleType, nType)
				local tDecalInfo = tLogicDecal[nShowID]
				tDecal.nColorID = tDecalInfo.tColorID[1] or 0
			end

			tDecal.bChangeValue = false

			-- tDecal.fValue1 = -1
			-- tDecal.fValue2 = -1
			-- tDecal.fValue3 = -1
		end
	end

	tDecal.bUse = true
	tDecal.nShowID = nShowID
	BuildFaceData.tNowFaceData.tDecal[nType] = tDecal

	BuildFaceData.CopyRightType(nType)
end


function BuildFaceData.UpdateNowOldFaceDecal(nType, nShowID, nColorID)
	local tDecal = BuildFaceData.tNowFaceData.tFaceData.tDecal[nType]
	if not tDecal then
		return
	end

	tDecal = Lib.copyTab(tDecal)

	if nColorID then
		tDecal.nColorID = nColorID

		local _, _, _, _, tDetail = KG3DEngine.GetFaceDecalColorInfo(BuildFaceData.nRoleType,
				nType,
				tDecal.nShowID,
				tDecal.nColorID,
				false)

		tDecal.bUse = false
		if tDetail then
			tDecal.bUse = true
		end
	else
		if tDecal.nShowID ~= nShowID then
			local hFaceLiftManager = GetFaceLiftManager()
			if not hFaceLiftManager then
				return
			end

			tDecal.bUse = false
			if nShowID == 0 then
				tDecal.nColorID = 0
			else
				local tLogicDecal = hFaceLiftManager.GetDecalInfo(BuildFaceData.nRoleType, nType)
				local tDecalInfo = tLogicDecal[nShowID]
				tDecal.nColorID = tDecalInfo.tColorID[1] or 0
			end

			local _, _, _, _, tDetail = KG3DEngine.GetFaceDecalColorInfo(BuildFaceData.nRoleType,
				nType,
				nShowID,
				tDecal.nColorID,
				false)

			if tDetail then
				local fValue1, fValue2, fValue3
				if nType == FACE_LIFT_DECAL_TYPE.BASE then
					fValue1 = tDetail.fBaseValue1
					fValue2 = tDetail.fBaseValue2
					fValue3 = tDetail.fBaseValue3
				elseif nType >= FACE_LIFT_DECAL_TYPE.LIP_FLASH then
					fValue1 = tDetail.fNewValue1
					fValue2 = tDetail.fNewValue2
					fValue3 = tDetail.fNewValue3
				else
					fValue1 = tDetail.fValue1
					fValue2 = tDetail.fValue2
					fValue3 = tDetail.fValue3
				end
				tDecal.fValue1 = fValue1
				tDecal.fValue2 = fValue2
				tDecal.fValue3 = fValue3
				tDecal.bUse = true
			end
		else
			return
		end
	end


	tDecal.nShowID = nShowID
	BuildFaceData.tNowFaceData.tFaceData.tDecal[nType] = tDecal
end

function BuildFaceData.UpdateNowOldFaceDecoration(nDecorationID)
	BuildFaceData.tNowFaceData.tFaceData.nDecorationID = nDecorationID
end


function BuildFaceData.CopyRightType(nType)
	-- if BuildFaceData.bPrice then
		local tTable = tMeanwhileMapping[nType]
		if not tTable then
			return
		end
		if not BuildFaceData.tMeanwhileSwitch[tTable.dwKey] then
			return
		end
		local nTypeR = tTable.dwMappingType
		BuildFaceData.tNowFaceData.tDecal[nTypeR] = clone(BuildFaceData.tNowFaceData.tDecal[nType])
		-- return
	-- end
	-- if nType == FACE_LIFT_DECAL_TYPE_V2.IRIS_LEFT then
	-- 	local nTypeR = FACE_LIFT_DECAL_TYPE_V2.IRIS_RIGHT
	-- 	BuildFaceData.tNowFaceData.tDecal[nTypeR] = clone(BuildFaceData.tNowFaceData.tDecal[nType])
	-- end
	-- if nType == FACE_LIFT_DECAL_TYPE_V2.EYE_WHITE_LEFT then
	-- 	local nTypeR = FACE_LIFT_DECAL_TYPE_V2.EYE_WHITE_RIGHT
	-- 	BuildFaceData.tNowFaceData.tDecal[nTypeR] = clone(BuildFaceData.tNowFaceData.tDecal[nType])
	-- end
end

function BuildFaceData.UpdateNowFaceDecorationShow(nDecorationType, nValue)
	BuildFaceData.tNowFaceData.tDecoration[nDecorationType].nShowID = nValue
end

function BuildFaceData.UpdateNowFaceDecorationColor(nDecorationType, nColorID)
	BuildFaceData.tNowFaceData.tDecoration[nDecorationType].nColorID = nColorID
end

function BuildFaceData.GetDefaultFaceData()
	if BuildFaceData.bCanOperate then
		if BuildFaceData.tMyFaceData.bNewFace then
			return BuildFaceData.tMyFaceData
		else
			return BuildFaceData.tDefaultFaceData
		end
	else
		return BuildFaceData.tMyFaceData.tFaceData
	end
end

function BuildFaceData.ResetFaceBone()
	local tData = BuildFaceData.GetDefaultFaceData()
	if BuildFaceData.bCanOperate then
		BuildFaceData.tNowFaceData.tBone = clone(tData.tBone)
	else
		BuildFaceData.tNowFaceData.tFaceData.tBone = clone(tData.tBone)
	end
end

function BuildFaceData.ResetFaceDecal()
	local tData = BuildFaceData.GetDefaultFaceData()
	if BuildFaceData.bCanOperate then
		BuildFaceData.tNowFaceData.tDecal = clone(tData.tDecal)
	else
		BuildFaceData.tNowFaceData.tFaceData.tDecal = clone(tData.tDecal)
	end
end

function BuildFaceData.ResetFaceDecoration()
	local tData = BuildFaceData.GetDefaultFaceData()
	if BuildFaceData.bCanOperate then
		BuildFaceData.tNowFaceData.tDecoration = clone(tData.tDecoration)
	else
		BuildFaceData.tNowFaceData.tFaceData.nDecorationID = tData.nDecorationID
	end
end

function BuildFaceData.GetNowDecorationPage(tTable, nValue)
	for k, v in ipairs(tTable) do
		if v == nValue then
			return math.floor((k + BuildFaceData.nMaxDecalCount - 1) / BuildFaceData.nMaxDecalCount)
		end
	end
	return 1
end

function BuildFaceData.GetNowDecalPage(tDecalList, tLogicDecal, nType)
	for i, nShowID in ipairs(tDecalList) do
		local tDecalInfo = tLogicDecal[nShowID]
		if tDecalInfo.nShowID == BuildFaceData.tNowFaceData.tDecal[nType].nShowID then
			return math.ceil((i + 1) / BuildFaceData.nMaxDecalCount)
		end
	end
	return 1
end

function BuildFaceData.LoadFaceDecals()
	local  nCount = g_tTable.FaceDecalsV2:GetRowCount()
	BuildFaceData.tFaceDecalsList = {}
	BuildFaceData.tFaceDecalsMap = {}
	for i = 2, nCount do
		local tLine = g_tTable.FaceDecalsV2:GetRow(i)
		if not BuildFaceData.tFaceDecalsList[tLine.nRoleType] then
			BuildFaceData.tFaceDecalsList[tLine.nRoleType] = {}
			BuildFaceData.tFaceDecalsMap[tLine.nRoleType] = {}
		end

		local tRoleMap = BuildFaceData.tFaceDecalsList[tLine.nRoleType]
		if not tRoleMap[tLine.nType] then
			tRoleMap[tLine.nType] = {}
			BuildFaceData.tFaceDecalsMap[tLine.nRoleType][tLine.nType] = {}
		end
		table.insert(tRoleMap[tLine.nType], tLine.nShowID)
		BuildFaceData.tFaceDecalsMap[tLine.nRoleType][tLine.nType][tLine.nShowID] = tLine
	end
end

function BuildFaceData.GetTypeDecalList(nRoleType, nType)
	if not BuildFaceData.tFaceDecalsList then
		BuildFaceData.LoadFaceDecals()
	end
	return BuildFaceData.tFaceDecalsList[nRoleType][nType]
end

function BuildFaceData.GetDecal(nRoleType, nType, nShowID)
	if not BuildFaceData.tFaceDecalsMap then
		BuildFaceData.LoadFaceDecals()
	end
	if not BuildFaceData.tFaceDecalsMap[nRoleType][nType] then
		UILog("BuildFaceData.GetDecal not find tFaceDecalsMap[nRoleType][nType] when nRoleType = " .. nRoleType .. ", nType = " .. nType .. ", nShowID = " .. nShowID)
	end
	local tLine = BuildFaceData.tFaceDecalsMap[nRoleType][nType][nShowID]
	if not tLine then
		UILog("BuildFaceData.GetDecal not find tFaceDecalsMap[nRoleType][nType][nShowID] when nRoleType = " .. nRoleType .. ", nType = " .. nType .. ", nShowID = " .. nShowID)
	end

	tLine.tRGBA = ParsePointList(tLine.szDefaultRGBA)
	return tLine
end

function BuildFaceData.OnDecalUpdateDetail(nType, tDecal)
	local tDecals = BuildFaceData.tNowFaceData.tDecal
	tDecals[nType] = clone(tDecal)
	BuildFaceData.CopyRightType(nType)
end

function BuildFaceData.LoadFaceDecoration()
	local  nCount = g_tTable.FaceDecorationV2:GetRowCount()
	BuildFaceData.tFaceDecoration = {}
	BuildFaceData.tFaceDecMap = {}
	for i = 2, nCount do
		local tLine = g_tTable.FaceDecorationV2:GetRow(i)
		if tLine.nRoleType == BuildFaceData.nRoleType then
			if not BuildFaceData.tFaceDecoration[tLine.nDecorationType] then
				BuildFaceData.tFaceDecoration[tLine.nDecorationType] = {}
				BuildFaceData.tFaceDecMap[tLine.nDecorationType] = {}
			end

			local tRoleMap = BuildFaceData.tFaceDecoration[tLine.nDecorationType]
			table.insert(tRoleMap, tLine.nShowID)
			BuildFaceData.tFaceDecMap[tLine.nDecorationType][tLine.nShowID] = tLine
		end
	end
end

function BuildFaceData.GetDecorationSub(nDecorationType)
	if not BuildFaceData.tFaceDecoration then
		BuildFaceData.LoadFaceDecoration()
	end

	local tLine = BuildFaceData.tFaceDecoration[nDecorationType]
	if not tLine then
		UILog("BuildFaceData.GetDecoration not find tFaceDecMap[nDecorationType] when nDecorationType = " .. nDecorationType)
	end

	return tLine
end

function BuildFaceData.GetDecoration(nDecorationType, nLogicID)
	if not BuildFaceData.tFaceDecMap then
		BuildFaceData.LoadFaceDecoration()
	end

	local tLine = BuildFaceData.tFaceDecMap[nDecorationType][nLogicID]
	if not tLine then
		UILog("BuildFaceData.GetDecoration not find tFaceDecMap[nDecorationType][nLogicID] when nDecorationType = " .. nDecorationType .. ", nLogicID = " .. nLogicID)
	end

	return tLine
end

function BuildFaceData.GetDecalList(nRoleType, nType)
	local hManager = GetFaceLiftManager()
	if not hManager then
		return
	end
	local nDecalTypeLabel = 0
	local tDecalList = BuildFaceData.GetTypeDecalList(nRoleType, nType)
	local tLogicDecal = hManager.GetDecalInfoV2(nRoleType, nType)
	local tList = {}
	for _, nShowID in pairs(tDecalList) do
		local tDecalInfo = tLogicDecal[nShowID]
		-- if BuildFaceData.bPrice or (tDecalInfo and tDecalInfo.bCanUseInCreate) then
			local tUIInfo = BuildFaceData.GetDecal(nRoleType, nType, nShowID)
			if BuildFaceData.bPrice then
				local nLabel = tUIInfo.nLabel
				local bDis = CoinShop_IsDis(tDecalInfo)
				if bDis then
					nLabel = math.max(nLabel, EXTERIOR_LABEL.DISCOUNT)
				end
				nDecalTypeLabel = math.max(nDecalTypeLabel, nLabel)
			end
			table.insert(tList, nShowID)
		-- end
	end
	return tList, nDecalTypeLabel
end

function BuildFaceData.GetOldDecalList(nRoleType, nType)
	local nDecalTypeLabel = 0
	local tDecalList = Table_GetTypeDecalList(nRoleType, nType)
	local tLogicDecal = GetFaceLiftManager().GetDecalInfo(nRoleType, nType)
	local tHairShopLabel
	if BuildFaceData.bPrice then
		tHairShopLabel = CoinShopData.GetHairShopLabels()
	end
	local tList = {}
	for _, nShowID in ipairs(tDecalList) do
		local tDecalInfo = tLogicDecal[nShowID]
		-- if BuildFaceData.bPrice or (tDecalInfo and tDecalInfo.bCanUseInCreate) then
			local tUIInfo = Table_GetDecal(nRoleType, nType, nShowID)
			if BuildFaceData.bPrice then
				local nLabel = tUIInfo.nLabel
				local bDis = CoinShop_IsDis(tDecalInfo)
				tHairShopLabel[nLabel] = true
				if bDis then
					nLabel = math.max(nLabel, EXTERIOR_LABEL.DISCOUNT)
					tHairShopLabel[nLabel] = true
				end
				nDecalTypeLabel = math.max(nDecalTypeLabel, nLabel)
			end
			table.insert(tList, nShowID)
		-- end
	end

	return tList, nDecalTypeLabel
end

function BuildFaceData.IsDecalRoleFit(szRoleType)
	if szRoleType == "" then
		return true
	else
		local tRoleType = SplitString(szRoleType, ';')
		for _, v in pairs(tRoleType) do
			if tonumber(v) == BuildFaceData.nRoleType then
				return true
			end
		end
	end
	return false
end

function BuildFaceData.GetOldFaceDecalList()
	if BuildFaceData.tOldDecalClassList then
		return
	end
	local tList = {}
	local nCount = g_tTable.FaceDecalsClass:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.FaceDecalsClass:GetRow(i)
		local nClassID = tLine.nClassID
		if (nClassID ~= FACE_LIFT_DECAL_TYPE.IRIS_RIGHT or BuildFaceData.bPrice) and
			((not BuildFaceData.bPrice and tLine.bLoginShow) or (BuildFaceData.bPrice and tLine.bCoinShopShow)) then
			table.insert(tList, {
				dwClassID = nClassID,
				szName = tLine.szText,
			})
		end
	end
	BuildFaceData.tOldDecalClassList		= tList
end

function BuildFaceData.GetFaceDecalList()
	if BuildFaceData.tDecalClassList then
		return
	end
	local nCount = g_tTable.FaceDecalsClassV2:GetRowCount()
	local tList = {}
	local tArea, tClass, tSub
	local nAllLabel = 0
	for i = 2, nCount do
		local tLine = g_tTable.FaceDecalsClassV2:GetRow(i)
		if BuildFaceData.IsDecalRoleFit(tLine.szRoleType) then
			tArea = tList[tLine.nAreaID]
			if not tArea then
				tList[tLine.nAreaID]  	= {}
				tArea 					= tList[tLine.nAreaID]
				tArea.szAreaName 		= tLine.szAreaName
				tArea.szAreaDefault 	= tLine.szAreaDefault
				tArea.szAreaPath 		= tLine.szAreaPath
				tArea.szAreaAni 		= tLine.szAreaAni
				tArea.szDefaultName 	= tLine.szDefaultName
				tArea.nLabel 			= 0
				tArea.nAreaID 			= tLine.nAreaID
			end

			tClass = tArea[tLine.nClassID]
			local szClassName = tLine.szClassName
			if not BuildFaceData.bPrice then
				if tLine.nDecalsType == FACE_LIFT_DECAL_TYPE_V2.IRIS_LEFT then
					szClassName = UIHelper.UTF8ToGBK(g_tStrings.FACE_LIFT_IRIS)
				end

				if tLine.nDecalsType == FACE_LIFT_DECAL_TYPE_V2.EYE_WHITE_LEFT then
					szClassName = UIHelper.UTF8ToGBK(g_tStrings.EYE_WHITE_LEFT)
				end
			end
			if not tClass then
				tArea[tLine.nClassID]  	= {}
				tClass 					= tArea[tLine.nClassID]
				tClass.szClassName 		= szClassName
				tClass.nLabel 			= 0
				tClass.dwClassID		= tLine.nClassID
			end

			local _, nLabel = BuildFaceData.GetDecalList(BuildFaceData.nRoleType, tLine.nDecalsType)
			tSub = {
				nDecalsType 	= tLine.nDecalsType,
				bLoginShow 		= tLine.bLoginShow,
				nLabel			= nLabel,
				szSubClassName 	= tLine.szSubClassName
			}

			table.insert(tClass, tSub)
			tClass.nLabel 				= math.max(nLabel, tClass.nLabel)
			tArea.nLabel 				= math.max(nLabel, tArea.nLabel)
			nAllLabel 					= math.max(nAllLabel, nLabel)
		end
	end

	if tList[DECORATION_ARENA_ID] and IsTable(tList[DECORATION_ARENA_ID]) then
		local bEmpty = true
		for _, tClass in ipairs(tDecorationClass) do
			local tDecalList = BuildFaceData.GetDecorationSub(tClass.nDecorationType)
			tDecorationClass.nLabel = math.max(tDecorationClass.nLabel, BuildFaceData.GetDecorationLabel())
			for _, nShowID in ipairs(tDecalList) do
				if not bEmpty or nShowID ~= 0 then
					bEmpty = false
					break
				end
			end
		end
		if not bEmpty then
			table.insert(tList[DECORATION_ARENA_ID], tDecorationClass)
		end
	end
	BuildFaceData.nDecalsAllLabel 		= nAllLabel
	BuildFaceData.tDecalClassList		= tList
end

function BuildFaceData.GetDecorationDis()
	local hFaceLiftManager = GetFaceLiftManager()
	if not hFaceLiftManager then
		return
	end
	for nType = 0, FACE_LIFT_DECORATION_TYPE.TOTAL - 1 do
		local nDecoration = BuildFaceData.tNowFaceData.tDecoration[nType].nShowID
		if nDecoration ~= 0 then
			local tLogicDecal = hFaceLiftManager.GetDecorationInfoV2(BuildFaceData.nRoleType, nType)
			local tDecalInfo = tLogicDecal[nDecoration]
			local bDis = CoinShop_IsDis(tDecalInfo)
			local szDisCount = CoinShop_GetOneDisInfo(tDecalInfo)
			return bDis, szDisCount
		end
	end
end

function BuildFaceData.GetDecalDis()
	local tDecals = BuildFaceData.tNowFaceData.tDecal
	local hFaceLiftManager = GetFaceLiftManager()
	if not hFaceLiftManager then
		return
	end
	for nType = 0, FACE_LIFT_DECAL_TYPE_V2.TOTAL - 1 do
		local tDecal = tDecals[nType]
		local nShowID = tDecal.nShowID
		local tLogicDecal = hFaceLiftManager.GetDecalInfoV2(BuildFaceData.nRoleType, nType)
		if nShowID ~= 0 then
			local tDecalInfo = tLogicDecal[nShowID]
			local bOneDis = CoinShop_IsDis(tDecalInfo)
			if bOneDis then
				local szDisCount = CoinShop_GetOneDisInfo(tDecalInfo)
				return bOneDis, szDisCount
			end
		end
	end
end

function BuildFaceData.GetOldDecorationDis()
	local hFaceLiftManager = GetFaceLiftManager()
	if not hFaceLiftManager then
		return
	end
	local nDecoration = BuildFaceData.tNowFaceData.tFaceData.nDecorationID
	if nDecoration ~= 0 then
		local tLogicDecal = hFaceLiftManager.GetDecorationInfo(BuildFaceData.nRoleType)
		local tDecalInfo = tLogicDecal[nDecoration]
		local bDis = CoinShop_IsDis(tDecalInfo)
		local szDisCount = CoinShop_GetOneDisInfo(tDecalInfo)
		return bDis, szDisCount
	end
end

function BuildFaceData.GetOldDecalDis()
	local tDecals = BuildFaceData.tNowFaceData.tFaceData.tDecal
	local hFaceLiftManager = GetFaceLiftManager()
	if not hFaceLiftManager then
		return
	end
	for nType = 0, FACE_LIFT_DECAL_TYPE.TOTAL - 1 do
		local tDecal = tDecals[nType]
		local nShowID = tDecal.nShowID
		local tLogicDecal = hFaceLiftManager.GetDecalInfo(BuildFaceData.nRoleType, nType)
		if nShowID ~= 0 then
			local tDecalInfo = tLogicDecal[nShowID]
			local bOneDis = CoinShop_IsDis(tDecalInfo)
			if bOneDis then
				local szDisCount = CoinShop_GetOneDisInfo(tDecalInfo)
				return bOneDis, szDisCount
			end
		end
	end
end

function BuildFaceData.GetDecorationLabel()
	if not BuildFaceData.bPrice then
		return 0
	end
	local hManager = GetFaceLiftManager()
	if not hManager then
		return
	end
	if BuildFaceData.nDecorationLabel then
		return BuildFaceData.nDecorationLabel
	end
	local nRoleType = BuildFaceData.nRoleType
	local nDecorationLabel = 0
	for nDecorationType, tTable in pairs(BuildFaceData.tFaceDecoration) do
		local tLogicDecal = hManager.GetDecorationInfoV2(nRoleType, nDecorationType)
		local nSubLabel = 0
		for _, nDecoration in pairs(tTable) do
			local tDecalInfo = tLogicDecal[nDecoration]
			local tUIInfo = BuildFaceData.GetDecoration(nDecorationType, nDecoration)
			local nLabel = tUIInfo.nLabel
			local bDis = CoinShop_IsDis(tDecalInfo)
			if nLabel == 0 and bDis then
				nLabel = EXTERIOR_LABEL.DISCOUNT
			end

			if nLabel == EXTERIOR_LABEL.FACELIFT_NEW then
				nLabel = EXTERIOR_LABEL.NEW
			end

			if nLabel == EXTERIOR_LABEL.NEW then
				nDecorationLabel = EXTERIOR_LABEL.NEW
			end

			if nDecorationLabel ~= EXTERIOR_LABEL.NEW then
				nDecorationLabel = math.max(nDecorationLabel, nLabel)
			end
			nSubLabel = kmath.orOperator(nSubLabel, nLabel)
		end
		for _, t in ipairs(tDecorationClass) do
			if nDecorationType == t.nDecorationType then
				t.nLabel = nSubLabel
			end
		end
	end
	BuildFaceData.nDecorationLabel = nDecorationLabel
	return nDecorationLabel
end

function BuildFaceData.GetOldDecorationLabel(tDecalList)
	if not BuildFaceData.bPrice then
		return 0
	end
	local nRoleType = BuildFaceData.nRoleType
	local nDecorationLabel = 0
	local tLogicDecal = GetFaceLiftManager().GetDecorationInfo(nRoleType)
	for _, nDecoration in ipairs(tDecalList) do
		local tDecalInfo = tLogicDecal[nDecoration]
		local tUIInfo = Table_GettDecoration(nRoleType, nDecoration)
		local nLabel = 0
		if tUIInfo then
			nLabel = tUIInfo.nLabel
		else
			return 0
		end
		local bDis = CoinShop_IsDis(tDecalInfo)
		if nLabel == 0 and bDis then
			nLabel = EXTERIOR_LABEL.DISCOUNT
		end

		if nLabel == EXTERIOR_LABEL.FACELIFT_NEW then
			nLabel = EXTERIOR_LABEL.NEW
		end

		if nLabel == EXTERIOR_LABEL.NEW then
			nDecorationLabel = EXTERIOR_LABEL.NEW
		end

		if nDecorationLabel ~= EXTERIOR_LABEL.NEW then
			nDecorationLabel = math.max(nDecorationLabel, nLabel)
		end

		if bDis then
			nLabel = math.max(nLabel, EXTERIOR_LABEL.DISCOUNT)
		end
	end

	return nDecorationLabel
end

function BuildFaceData.GetBoneLabel()
	if not BuildFaceData.bPrice then
		return 0
	end
	local hManager = GetFaceLiftManager()
	if not hManager then
		return
	end
	local tPriceInfo = hManager.GetBasePriceInfo()
	local bDis = CoinShop_IsDis(tPriceInfo)
	local nLabel = 0
	if bDis then
		nLabel = math.max(nLabel, EXTERIOR_LABEL.DISCOUNT)
	end
	return nLabel
end

function BuildFaceData.InitBoneClass(tClass)
	local tData = BuildFaceData.GetDefaultFaceData()
	for k, v in ipairs(tClass) do
		local nValue = tData.tBone[v.nBoneType]
		BuildFaceData.tNowFaceData.tBone[v.nBoneType] = nValue
	end
end

function BuildFaceData.UpdateDecalSubData(bDecoration, tSub, nSubID)
	BuildFaceData.tDecalData = {
		bDecoration = bDecoration,
		tSub = tSub,
		nSubID = nSubID,
	}
end

function BuildFaceData.LoadFaceDecorationColorInfo()
	local  nCount = g_tTable.FaceDecorationColorInfo:GetRowCount()
	BuildFaceData.tFaceDecorationColorMap = {}
	for i = 2, nCount do
		local tLine = g_tTable.FaceDecorationColorInfo:GetRow(i)
		if not BuildFaceData.tFaceDecorationColorMap[tLine.nRoleType] then
			BuildFaceData.tFaceDecorationColorMap[tLine.nRoleType] = {}
		end

		if not BuildFaceData.tFaceDecorationColorMap[tLine.nRoleType][tLine.nType] then
			BuildFaceData.tFaceDecorationColorMap[tLine.nRoleType][tLine.nType] = {}
		end

		if not BuildFaceData.tFaceDecorationColorMap[tLine.nRoleType][tLine.nType][tLine.nShowID] then
			BuildFaceData.tFaceDecorationColorMap[tLine.nRoleType][tLine.nType][tLine.nShowID] = {}
		end
		table.insert(BuildFaceData.tFaceDecorationColorMap[tLine.nRoleType][tLine.nType][tLine.nShowID], tLine)
	end
end

function BuildFaceData.GetDecorationColorInfo(nRoleType, nType, nShowID)
	if not BuildFaceData.tFaceDecorationColorMap then
		BuildFaceData.LoadFaceDecorationColorInfo()
	end
	return BuildFaceData.tFaceDecorationColorMap[nRoleType][nType][nShowID]
end

function BuildFaceData.GetAndDealDatailValue(tValue, tDetail, i)
	local szString = table.concat({"fValue", i})
	local szNewString = table.concat({"fNewValue", i})
	local nValue = (tValue and tValue[szString]) or tDetail[szNewString]
	if tValue  and not tValue[szString] then
		tValue[szString] = nValue
	end
	return nValue
end

function BuildFaceData.UpdateMeanwhile(nAreaID, dwClassID)
	for k, v in pairs(tMeanwhile) do
		if v.nAreaID == nAreaID and v.nClassID == dwClassID then
			return true, k
		end
	end
	return false
end

function BuildFaceData.SetMeanwhileSwitch(nMeanwhile, bCheck)
	BuildFaceData.tMeanwhileSwitch[nMeanwhile] = bCheck
end

function BuildFaceData.SetChangeSide(bChangeSide)
	BuildFaceData.bChangeSide = bChangeSide
end

function BuildFaceData.GetChangeSide()
	return not not BuildFaceData.bChangeSide
end

function BuildFaceData.SetInBuildMode(bInBuildMode)
	if bInBuildMode then
		local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
		moduleCamera.SetCameraStatus(LoginCameraStatus.BUILD_FACE_STEP1, BuildFaceData.nRoleType)
	end

	BuildFaceData.bInBuildMode = bInBuildMode
end

function BuildFaceData.GetInBuildMode()
	return BuildFaceData.bInBuildMode
end

function BuildFaceData.GetLastDetail(nType)
	local tDecals = BuildFaceData.tNowFaceData.tDecal
	local tDecal = tDecals[nType]
	local tNewDetail = {}
	if tDecal.bUse then
		for i = 1, 3 do
			if tDecal["fValue" .. i] ~= -1 then
				tNewDetail["fNewValue" .. i] = tDecal["fValue" .. i]
			end
		end
	end
	return tNewDetail
end

function BuildFaceData.IsFit(nColorID, nType)
	return nColorID ~= 0 or nType == FACE_LIFT_DECAL_TYPE_V2.IRIS_LEFT or nType == FACE_LIFT_DECAL_TYPE_V2.IRIS_RIGHT
end

function BuildFaceData.ImportData(tFaceData)
	local hManager = GetFaceLiftManager()
	local bForCreate = not BuildFaceData.bPrice
	local nRetCode = hManager.CheckValid(BuildFaceData.nRoleType, tFaceData)
	if nRetCode ~= FACE_LIFT_ERROR_CODE.SUCCESS then
		Timer.Add(BuildFaceData, 0.1, function ()
			local szMsg = g_tStrings.tNewFaceLiftNotify[nRetCode]
			TipsHelper.ShowNormalTip(szMsg)
		end)
		return
	end

	BuildFaceData.NowFaceCloneData(tFaceData, true)
	return true
end

function BuildFaceData.ImportOldData(tFaceData)
	local hManager = GetFaceLiftManager()
	local bForCreate = not BuildFaceData.bPrice
	local nRetCode = hManager.CheckValid(BuildFaceData.nRoleType, tFaceData)
	if nRetCode ~= FACE_LIFT_ERROR_CODE.SUCCESS then
		local szMsg = g_tStrings.tFaceLiftNotify[nRetCode]
		TipsHelper.ShowNormalTip(szMsg)
		return
	end

	BuildFaceData.NowFaceCloneData(tFaceData, false)
	return true
end

function BuildFaceData.ExportedFolder()
	if Platform.IsAndroid() then
		return "newfacedata"
	end
	return UIHelper.GBKToUTF8(GetStreamAdaptiveDirPath(GetFullPath("newfacedata") .. "/"))
end

function BuildFaceData.SetStartBuildFaceTime()
	BuildFaceData.nStartBuildFaceTime = Timer.RealMStimeSinceStartup()
end

function BuildFaceData.GetBuildFaceTime()
	if BuildFaceData.nStartBuildFaceTime then
		local nBuildFaceTime = Timer.RealMStimeSinceStartup() - BuildFaceData.nStartBuildFaceTime
		BuildFaceData.nStartBuildFaceTime = nil
		return nBuildFaceTime
	end
end