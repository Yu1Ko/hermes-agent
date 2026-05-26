BuildPresetData = BuildPresetData or {}
local self = BuildPresetData

BuildPresetData.tSelectOriginalRepresent = nil
BuildPresetData.nCreateRoleType = 0
BuildPresetData.nCreateForceID = 0
BuildPresetData.nCurSelectHairIndex = 0
BuildPresetData.PageType = 
{
    DEFAULT = 1,
    FACE = 2,
    BODY = 3,
    Clothes = 4,
    Weather = 5,
    Action = 6,
}
BuildPresetData.PageTypeName = 
{
    [BuildPresetData.PageType.DEFAULT] = "整体",
    [BuildPresetData.PageType.FACE] = "面部",
    [BuildPresetData.PageType.BODY] = "身体",
}

BuildPresetData.nCurSelectClothesIndex = 0
BuildPresetData.tRoleDefalutRepresentList = nil
BuildPresetData.nSelectActionId = 0
BuildPresetData.szSelectRoleAni = nil
BuildPresetData.szFisrtStanderAnimation= ""

BuildPresetData.bOpenShareAndH5 = false

function BuildPresetData.Init()
    BuildPresetData.nCurSelectClothesIndex = 0
    BuildPresetData.tRoleDefalutRepresentList = nil
    BuildPresetData.tSelectOriginalRepresent = nil
    BuildPresetData.nCreateRoleType = 0
    BuildPresetData.nCreateForceID = 0
    BuildPresetData.tbDefaultReprent = nil
end

function BuildPresetData:RestInfo()
    BuildPresetData.nCurSelectClothesIndex = 0
    BuildPresetData.nSelectActionId = 0
    BuildPresetData.szSelectRoleAni = nil
end


function BuildPresetData.GetPresetData(nRoleType, nKungfuID)
    return Table_GetLoginPresetList(nRoleType, nKungfuID)
end

function BuildPresetData.GetActionData(nRoleType, nKungfuID)
    return Table_GetLoginAnimationList(nRoleType, nKungfuID)
end

BuildPresetData.szLastAnimationName = nil
function BuildPresetData.ResetPlayAnimation(szAnimatonName)
   local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
   if szAnimatonName then
        moduleRole:PlayRoleAnimation("loop", szAnimatonName) 
    else
        moduleRole:PlayAniID(60211 , "loop")  -- 角色捏脸最原始动作ID
    end
end

function BuildPresetData.PausePlayAnimation(bPause)
    Timer.Add(BuildPresetData , 0.5 , function ()
        local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_SCENE).GetModel(LoginModel.FORCE_ROLE)
        moduleRole:PauseAnimation(bPause)
    end)
 end

BuildPresetData.tUpdateDownloadModleInfo = 
{
    nSelectPageType = BuildPresetData.PageType.DEFAULT,
    nSelectIndex = 0,
}

BuildPresetData.nPresetRoleType = 1
BuildPresetData.tDownloadDynamicID = {}
function BuildPresetData.ResetDownloadDynamic()
    for pageType, tDownloadDynamicID in pairs(self.tDownloadDynamicID) do
        for k, nDownloadDynamicID in pairs(tDownloadDynamicID) do
            PakDownloadMgr.ReleaseDynamicPakInfo(nDownloadDynamicID)
        end
        self.tDownloadDynamicID[pageType] = {}
    end
 end

 function BuildPresetData.GetDownloadDynamicID(nPageType , nIndex )
    self.tDownloadDynamicID[nPageType] = self.tDownloadDynamicID[nPageType] or {}
    return self.tDownloadDynamicID[nPageType][nIndex]
 end

 function BuildPresetData.SetDownloadDynamic(nPageType , nIndex , nDownloadDynamicID)
    self.tDownloadDynamicID[nPageType] = self.tDownloadDynamicID[nPageType] or {}
    self.tDownloadDynamicID[nPageType][nIndex] = nDownloadDynamicID
 end

 function BuildPresetData.EnablePakResourceDownloadEvent(bEnable)
    Event.UnReg(BuildPresetData , EventType.OnEquipPakResourceDownload)
    if bEnable then
        Event.Reg(BuildPresetData , EventType.OnEquipPakResourceDownload , function (nDownloadDynamicID)
            --LOG.ERROR("OnEquipPakResourceDownload %s",tostring(nDownloadDynamicID))
            local pageInfo = self.tDownloadDynamicID[self.tUpdateDownloadModleInfo.nSelectPageType]
            if pageInfo then
                if pageInfo[self.tUpdateDownloadModleInfo.nSelectIndex] == nDownloadDynamicID then
                    local moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
                    if moduleRole then
                        local tRepresent = BuildPresetData.DynamicID_To_CacheReprentInfo[nDownloadDynamicID] 
                        local szAniName 
                        if tRepresent then
                            BuildBodyData.UpdateCloth("" , Lib.copyTab(tRepresent[1]))
                            szAniName = tRepresent[2]
                            BuildPresetData.DynamicID_To_CacheReprentInfo[nDownloadDynamicID] = nil
                        end
                        moduleRole.UpdateRoleModel()
                        BuildPresetData.ResetPlayAnimation(szAniName)
                    end
                end
            end

            for pageType, tDownloadDynamicID in pairs(self.tDownloadDynamicID) do
                for k, nDynamicID in pairs(tDownloadDynamicID) do
                    if nDynamicID == nDownloadDynamicID then
                        self.tDownloadDynamicID[pageType][k] = nil
                    end
                end
            end
        end)
    end
 end

 BuildPresetData.tbDefaultReprent = nil
 function BuildPresetData.SetDefaultReprent(tRepresentList)
    local tOriginalRepresent_tmp = {}
    if IsTable(tRepresentList) then
        for k, v in pairs(tRepresentList) do
            if not IsTable(v) then
                tOriginalRepresent_tmp[k] = v
            end
        end
    else
        local tbRepresent_tmp = string.split(tRepresentList, ";")
        for k, v in pairs(tbRepresent_tmp) do
            local tPart = string.split(v, "|")
            tOriginalRepresent_tmp[tonumber(tPart[1])] = tonumber(tPart[2])
        end
    end

    BuildPresetData.tbDefaultReprent = tOriginalRepresent_tmp
 end

 function BuildPresetData.GetDefaultReprent(tRepresentList)
    if not BuildPresetData.tbDefaultReprent then
        BuildPresetData.SetDefaultReprent(tRepresentList)
    end
    return BuildPresetData.tbDefaultReprent
 end

 BuildPresetData.DynamicID_To_CacheReprentInfo = {}
 function BuildPresetData.CheckDownloadRes(nPageType , nIndex ,tRepresentID , cellScript , szAnimation)
    self.tUpdateDownloadModleInfo.nSelectIndex = nIndex
    self.tUpdateDownloadModleInfo.nSelectPageType = nPageType
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(BuildPresetData.nPresetRoleType, 1, tRepresentID) 
    local nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(BuildPresetData.nPresetRoleType, tEquipList, tEquipSfxList, BuildPresetData.GetDownloadDynamicID(nPageType , nIndex ))  
    BuildPresetData.SetDownloadDynamic(nPageType , nIndex , nDownloadDynamicID)
    local result = true
    if nDownloadDynamicID and cellScript then
        --LOG.ERROR("BuildPresetData.CheckDownloadRes %d,%d, %s",nPageType , nIndex,tostring(nDownloadDynamicID))
        local scriptDownload = UIHelper.GetBindScript(cellScript.WidgetDownloadShell)
        scriptDownload:SetShowCondition(function (tParams)
            if tParams then
                local nPageType = tParams[1]
                local nIndex = tParams[2]
                local cellScript = tParams[3]
                if self.tDownloadDynamicID[nPageType] and self.tDownloadDynamicID[nPageType][nIndex] then
                    return cellScript.bSelected
                else
                    return false
                end
            end
        end)
        scriptDownload:SetConditionParams({
            [1] = nPageType ,
            [2] = nIndex,
            [3] = cellScript,
        })
        BuildPresetData.DynamicID_To_CacheReprentInfo[nDownloadDynamicID] =
        {
            [1] = tRepresentID,
            [2] = szAnimation
        } 
        scriptDownload:SetInfo(nDownloadDynamicID, bRemoteNotExist, {bTopMost = true})

        scriptDownload:SetVisibleChangedCallback(function (bVisible, nDynamicID)
            if bVisible then
                local packState = PakDownloadMgr.GetPackViewState(nDynamicID)
                if packState == DOWNLOAD_STATE.COMPLETE then
                    local _child = UIHelper.GetBindScript(scriptDownload.WidgetDownload)
                    _child:SetVisible(false)
                    UIHelper.SetVisible(scriptDownload._rootNode, false)
                end
            end
        end)
    else
        result = false
    end  
    return result
end
local m_szFreezeUrl = "https://jx3.xoyo.com/p/zt/2024/05/27/public-testing/index.html?"
function BuildPresetData.OpenFreeUrl(szRoleName ,dwPlayerID , dwForceID , dwCreateTime , szGlobalID)
    Event.Reg(BuildPresetData, "WEB_SIGN_NOTIFY", function()
        if arg2 == "ROLE_FREEZE_APPEAL" then
            local uSign = arg0
            local nTime = arg1
            local szDefaultParam = "param=%s/%s/%d/%d/%s/%s/%s/%s/%d/%s/%d/%d"
            
            local szUserRegion, szUserSever = WebUrl.GetServerName()
            szDefaultParam = string.format(
                szDefaultParam, uSign, Login_GetAccount(),dwPlayerID, nTime, "", "", 
                UrlEncode(szUserRegion), UrlEncode(szUserSever),
                dwForceID,UrlEncode(szRoleName), dwCreateTime ,GetAccountType()
            )
            if Platform.IsMobile() then
                m_szFreezeUrl = "https://jx3.xoyo.com/p/m/2024/05/27/public-testing/index.html?"
            end
            szDefaultParam = string.format("%s&game=jx3&tid=%d&role_id=%s&is_login_page=1&%s",m_szFreezeUrl , 1, szGlobalID or "", szDefaultParam)
            UIHelper.OpenWebWithDefaultBrowser(szDefaultParam , false , true)
            Event.UnReg(BuildPresetData, "WEB_SIGN_NOTIFY")
        end
    end)
    Login_WebSignRequest(1, "ROLE_FREEZE_APPEAL")
end
