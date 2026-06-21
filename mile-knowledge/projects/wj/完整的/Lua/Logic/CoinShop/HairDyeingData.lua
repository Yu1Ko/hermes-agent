-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: HairDyeingData
-- Date: 2025-10-17 22:04:02
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nVersion = 2
--1升到2的是因为加了一个参数
local EXPORT_CD_TIME = 5 * 1000
local nMajorVersion = 1 --代表现行版，留位置给预设怀旧版玩家是2

local tRoleName =
{
    [1] = "StandardMale",
    [2] = "StandardFemale",
    [5] = "LittleBoy",
    [6] = "LittleGirl",
}

local function AdjustDataPath(szPath)
	local szAdjust = szPath .. ".dat"
	if not Lib.IsFileExist(szAdjust) then
		return szAdjust
	end

	for i = 1, 100 do
		local szAdjust = szPath .. "(" .. i.. ")" .. ".dat"
		if not Lib.IsFileExist(szAdjust) then
			return szAdjust
		end
	end
	local nTickCount = GetTickCount()
	local szAdjust = szPath .. "(" .. nTickCount.. ")" .. ".dat"
	return szAdjust
end

HairDyeingData = HairDyeingData or {className = "HairDyeingData"}
local self = HairDyeingData

function HairDyeingData.SaveHairDyeingData(tData, nHair, nRoleType)
	local tHairData = {}

	tHairData.nVersion = nVersion
	tHairData.nMajorVersion = nMajorVersion
	tHairData.tHairDyeing = clone(tData)
	tHairData.nRoleType = nRoleType
	tHairData.nHair = nHair

    local szDyeingDir = GetFullPath("hairdyeingdatadir")
    CPath.MakeDir(szDyeingDir)

	if Platform.IsWindows() then
		szDyeingDir = UIHelper.GBKToUTF8(szDyeingDir)
	end

	local szSuffix = tRoleName[nRoleType]
	local nTime = GetCurrentTime()
	local time = TimeToDate(nTime)
	local szTime = string.format("%d%02d%02d-%02d%02d%02d", time.year, time.month, time.day, time.hour, time.minute, time.second)
	local szHairName = CoinShopHair.GetHairText(nHair)
    szHairName = UIHelper.GBKToUTF8(szHairName)

	local szFileName = szHairName ..  "_HairDyeingData_" .. szSuffix .."_" .. szTime
	local szPath = szDyeingDir .. "/" .. szFileName
	szPath = AdjustDataPath(szPath)
	szPath = string.gsub(szPath, "\\", "/")
	SaveLUAData(szPath, tHairData)

	return szPath, nVersion
end

function HairDyeingData.LoadHairDyeingData(szFile)
   	local tHairDyeingData = LoadLUAData(szFile, false, true, nil, false)
	if not tHairDyeingData or
		not tHairDyeingData.tHairDyeing
	then
		return
	end

	if not tHairDyeingData.nVersion then
		return
	end

	if tHairDyeingData.nMajorVersion and tHairDyeingData.nMajorVersion ~= nMajorVersion then
		return nil, g_tStrings.STR_HAIR_DYEING_ERROR
	end

	if tHairDyeingData.nVersion and tHairDyeingData.nVersion == 1 then
		tHairDyeingData.tHairDyeing[HAIR_CUSTOM_DYEING_TYPE.HAIR_ALPHA_ENHANCE] = 0
	end

	return tHairDyeingData
end

local nLastExportTime = nil
function HairDyeingData.ExportData(tData, nHair, nRoleType)
	local nTime = GetTickCount()
	if SM_IsEnable() and nLastExportTime and nTime - nLastExportTime < EXPORT_CD_TIME then
		return g_tStrings.STR_HAIR_DYEING_DATA_EXPORT_CD, "MSG_ANNOUNCE_RED"
	end

	local szPath = HairDyeingData.SaveHairDyeingData(tData, nHair, nRoleType)
	nLastExportTime = nTime
    local szMsg = FormatString(g_tStrings.STR_HAIR_DYEING_DATA_EXPORT, szPath)
    local fnOpenFolder = function()
        OpenFolder(HairDyeingData.ExportedFolder())
    end

    if Platform.IsWindows() then
        local dialog = UIHelper.ShowConfirm(szMsg, function ()
            fnOpenFolder()
        end)
        dialog:SetButtonContent("Confirm", g_tStrings.FACE_OPEN_FLODER)
    else
        local scriptView = UIHelper.ShowConfirm(szMsg)
        scriptView:HideButton("Cancel")
    end
end

function HairDyeingData.ExportedFolder()
	return UIHelper.GBKToUTF8(GetStreamAdaptiveDirPath(GetFullPath("hairdyeingdatadir") .. "/"))
end