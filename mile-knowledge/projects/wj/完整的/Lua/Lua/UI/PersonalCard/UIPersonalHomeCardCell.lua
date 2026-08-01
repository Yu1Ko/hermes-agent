-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPersonalHomeCardCell
-- Date: 2024-03-25 15:14:56
-- Desc: ?
-- ---------------------------------------------------------------------------------
local BIG_SKIN_PATH = "mui/Resource/JYMap/SeparateMapSkinAll"
local HOMELAND_TYPE = {
    Estate = 1,     -- 社区
    Private = 2,    --家园
}
local tHomelandMap2Index = {
    ["广陵邑"] = 0,
    ["九寨沟·镜海"] = 1,
    ["枫叶泊·乐苑"] = 2,
    ["枫叶泊·天苑"] = 2,
    ["浣花水榭"] = 3,
}

local UIPersonalHomeCardCell = class("UIPersonalHomeCardCell")
function UIPersonalHomeCardCell:OnEnter(tbHomeInfo, bCommunityHome, bPeekOtherPlayer)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bCommunityHome = bCommunityHome
    self.bPeekOtherPlayer = bPeekOtherPlayer
    self:Init(tbHomeInfo)
end

function UIPersonalHomeCardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPersonalHomeCardCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function(btn)
        self:OnClickDetail()
        UIMgr.Close(VIEW_ID.PanelSideCharacterHome)
    end)
end

function UIPersonalHomeCardCell:RegEvent()
    Event.Reg(self, "CURL_REQUEST_RESULT", function ()
        local szKey = arg0
		local bSuccess = arg1
		local szValue = arg2
		local uBufSize = arg3
		if self.szPreRequestKey and szKey == self.szPreRequestKey and bSuccess then
			local tInfo, szErrMsg = JsonDecode(szValue)
			if tInfo and tInfo.code then
				Homeland_Log("HomeCard ERROR CODE：", tInfo.code, szErrMsg)
			end
            if tInfo.code == 0 then
				self:UpdateBluePrintInfo(tInfo)
			end
		end
    end)

    Event.Reg(self, "CURL_DOWNLOAD_RESULT", function ()
        local bSuccess = arg1
		local szFileName = arg0
		if not bSuccess then
			UILog("下载图片失败")
			return
		end

        self:DownloadBluePrintFile()
    end)
end

function UIPersonalHomeCardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPersonalHomeCardCell:Init(tbHomeInfo)
    if table.is_empty(tbHomeInfo) or not tbHomeInfo.nMapID or tbHomeInfo.nMapID <=0 then
        local szWarning = self.bCommunityHome and g_tStrings.STR_COMMUNITY_HOME_LOCK or g_tStrings.STR_PRIVATE_HOME_LOCK
        UIHelper.SetString(self.LabelHomeScore, szWarning)
        UIHelper.SetEnable(self.BtnDetail, not self.bPeekOtherPlayer)
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.WidgetContent, false)
        UIHelper.SetVisible(self.WidgetBtnGoto, not self.bPeekOtherPlayer)
        return
    end

    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.SetVisible(self.WidgetContent, true)
    self.tbHomeInfo = tbHomeInfo
    self.bIsPrivate = HomelandData.IsPrivateHome(tbHomeInfo.nMapID)
    self.bIsCheckOtherHomeland = tbHomeInfo and tbHomeInfo.dwPlayerID ~= PlayerData.GetPlayerID()
    self:UpdateInfo()
end

function UIPersonalHomeCardCell:UpdateInfo()
    UIHelper.SetVisible(self.LabelBlueprintName, false)
    UIHelper.SetVisible(self.LabelAuthorName, false)
    if self.bIsPrivate then
        self:UpdatePrivateHomelandInfo()
    else
        self:UpdateCommunutyHomelandInfo()
    end
end

function UIPersonalHomeCardCell:UpdatePrivateHomelandInfo()
    local tbHomeInfo = self.tbHomeInfo
    local nMapID = tbHomeInfo.nMapID
    local nCopyIndex = tbHomeInfo.nCopyIndex
    local dwSkinID = tbHomeInfo.dwSkinID or 0
    local bDigital = Homeland_IsDigitalBlueprint(tbHomeInfo.eMarketType or 0)
    local tUISkinInfo = Table_GetPrivateHomeSkin(nMapID, dwSkinID)
    local szName = FormatString(g_tStrings.STR_LINK_PRIVATE, UIHelper.GBKToUTF8(tUISkinInfo.szSkinName))
    local szBigPath = BIG_SKIN_PATH.."/"..tUISkinInfo.szImgName..".png"

    UIHelper.SetString(self.LabelNeighborhoodName, szName)
    UIHelper.SetTexture(self.ImgHome, szBigPath)
    UIHelper.SetSpriteFrame(self.ImgTypeIcon, HomelandBlueprintTypeIcon[HOMELAND_TYPE.Private])

    if bDigital then
        self:ApplyBluePrintInfo(HOMELAND_TYPE.Private)
    end
end

function UIPersonalHomeCardCell:UpdateCommunutyHomelandInfo()
    local tbHomeInfo = self.tbHomeInfo
    local nMapID = tbHomeInfo.nMapID
    local nCopyIndex = tbHomeInfo.nCopyIndex
    local nLandIndex = tbHomeInfo.nLandIndex
    local bDigital = Homeland_IsDigitalBlueprint(tbHomeInfo.eMarketType or 0)

    local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(nMapID))
    local szCommLandName = szMapName .. tostring(nLandIndex)
    szCommLandName = FormatString(g_tStrings.STR_MESSAGEBOARD_INDEX, szCommLandName)
    UIHelper.SetString(self.LabelNeighborhoodName, szCommLandName)

    local nMapIndex = tHomelandMap2Index[szMapName]
    local szMapPath = HomelandCommunityMapPic[nMapIndex]
    UIHelper.SetTexture(self.ImgHome, szMapPath)
    UIHelper.SetSpriteFrame(self.ImgTypeIcon, HomelandBlueprintTypeIcon[HOMELAND_TYPE.Estate])
    if bDigital then
        self:ApplyBluePrintInfo(HOMELAND_TYPE.Estate)
    end
end

local function GetAPIURL()
	if IsDebugClient() or IsVersionExp() then
		return tUrl.szUrlForGetCreator_Test
	else
		return tUrl.szUrlForGetCreator
	end
end

local function GetPicName(szURL)
	local szFileName = ""
	local tInfo = SplitString(szURL, "/")
	szFileName = tInfo[4]
	return szFileName .. ".jpg"
end

function UIPersonalHomeCardCell:ApplyBluePrintInfo(nMapType)
    local pPlayer = GetPlayer(self.tbHomeInfo.dwPlayerID)
	local tHttpData = {}
	tHttpData["globalRoleId"] = pPlayer.GetGlobalID()
	tHttpData["mapType"] = nMapType
	Homeland_TransformDataEncode(tHttpData)
    local szPreRequestKey = "HomelandGetAuthorAndMapName"
	self.szPreRequestKey = szPreRequestKey .. GetTickCount()
	CURL_HttpPost(self.szPreRequestKey, GetAPIURL(),
		JsonEncode(tHttpData), true, 60, 60, { [1] = "Content-Type:application/json"})
end

function UIPersonalHomeCardCell:UpdateBluePrintInfo(tInfo)
    if tInfo.code ~= 0 then
        UILog("出错", tInfo.code)
		return
    end
    UIHelper.SetVisible(self.LabelAuthorName, true)
    UIHelper.SetVisible(self.LabelBlueprintName, true)
    local tData = tInfo.data
    self.szAuthor = tData.creatorName
    self.szPicName = tData.assetName
    self.szPicUrl = tData.picDownloadUrl
    UIHelper.SetString(self.LabelAuthorName, self.szAuthor)
    UIHelper.SetString(self.LabelBlueprintName, self.szPicName)
    self:DownloadBluePrintFile()
end

function UIPersonalHomeCardCell:DownloadBluePrintFile()
    local szFileName, szPicUrl
    szFileName = self.szPicName
    szPicUrl = self.szPicUrl
    local szLocalFile = Homeland_GetDownloadPath(szFileName)
    local szPicName = GetPicName(szPicUrl)
    local szPath = Homeland_GetDownloadPath(szPicName)
    if not Lib.IsFileExist(szPath) then
        LOG.INFO("DownloadFile:%s", szLocalFile)
        CURL_DownloadFile(szFileName, szPicUrl, szPath, true, 120)
    else
        UIHelper.ClearTexture(self.ImgHome)
        UIHelper.SetTexture(self.ImgHome, szPath, false)
        UIHelper.UpdateMask(self.MaskHomeBg)
    end
end

local function GoPrivateLand (nMapID, nCopyIndex, dwSkinID)
    if CheckPlayerIsRemote(nil, g_tStrings.STR_REMOTE_NOT_TIP) then
        return
    end
    UIMgr.CloseAllInLayer("UIPageLayer")
    UIMgr.CloseAllInLayer("UIPopupLayer")
    RemoteCallToServer("On_HomeLand_GoPrivateLand", nMapID, nCopyIndex, dwSkinID, 3)
end

local function GoCommunityLand (nMapID, nCopyIndex, nLandIndex)
    if CheckPlayerIsRemote(nil, g_tStrings.STR_REMOTE_NOT_TIP) then
        return
    end
    UIMgr.CloseAllInLayer("UIPageLayer")
    UIMgr.CloseAllInLayer("UIPopupLayer")
    RemoteCallToServer("On_HomeLand_BackToLand", nMapID, nCopyIndex, nLandIndex)
end

function UIPersonalHomeCardCell:OnClickDetail()
    local tbHomeInfo    = self.tbHomeInfo
    if not tbHomeInfo then
        if self.bIsPrivate then
            UIMgr.Open(VIEW_ID.PanelHome, 1)
        else
            UIMgr.Open(VIEW_ID.PanelHome, 1, 455, GetCenterID(), 1, PlayerData.GetPlayerID(), true)
        end
    end
    local nMapID        = tbHomeInfo.nMapID
    local nCopyIndex    = tbHomeInfo.nCopyIndex
    local nLandIndex    = tbHomeInfo.nLandIndex
    local dwSkinID      = tbHomeInfo.dwSkinID
    if not self.bIsCheckOtherHomeland then
        if HomelandData.IsPrivateHome(nMapID) then
            -- HomelandData.GoPrivateLand(nMapID, nCopyIndex, dwSkinID, 1)
            UIMgr.Open(VIEW_ID.PanelHome, 1)
        else
            UIMgr.Open(VIEW_ID.PanelHome, 1, nMapID, nCopyIndex, nLandIndex)
        end
        return
    end

    local pPlayer = GetPlayer(tbHomeInfo.dwPlayerID)
    local szContent, szName = "",""
    local fnCallBack
    if self.bIsPrivate then
        local tLine = Table_GetPrivateHomeSkin(nMapID, dwSkinID)
        szName      = FormatString(g_tStrings.STR_LINK_PRIVATE, UIHelper.GBKToUTF8(tLine.szSkinName))
        szContent   = FormatString(g_tStrings.STR_LINK_PRIVATE_CLICK_MSG, UIHelper.GBKToUTF8(pPlayer.szName), szName)
        fnCallBack  = function ()
            GoPrivateLand(nMapID, nCopyIndex, dwSkinID)
        end
    else
        szName      = FormatString(g_tStrings.STR_LINK_COMMUNITY, UIHelper.GBKToUTF8(Table_GetMapName(nMapID)))
        szContent   = FormatString(g_tStrings.STR_LINK_PRIVATE_CLICK_MSG, UIHelper.GBKToUTF8(pPlayer.szName), szName)
        fnCallBack  = function ()
            GoCommunityLand(nMapID, nCopyIndex, nLandIndex)
        end
    end
    UIHelper.ShowConfirm(szContent, fnCallBack)
end

return UIPersonalHomeCardCell