FontMgr = FontMgr or {className = "FontMgr"}

FontID = {
    Default = 0,
    BattleInfo = 1,
}

FontType = {
    Default = 1,
    FZHT = 2,
    XMSANS = 3,
    FZJZ = 4,
}

local szDefaultDirectory = "mui/Fonts"
local szDefaultPath = "mui/Fonts/Base/HYJinKaiJ.ttf"
local tConfigs = {
    [FontType.Default] = {
        szName = "汉仪劲楷简",
        szPath = "mui/Fonts/Base/HYJinKaiJ.ttf",
        szFontImg = "UIAtlas2_GameSetting_FontSample_1.png",
        fOffsetY = 0,
    },
    [FontType.FZHT] = {
        szName = "方正黑体",
        szPath = "mui/Fonts/Base/fzht_GBK.ttf",
        szFontImg = "UIAtlas2_GameSetting_FontSample_2.png",
        fOffsetY = 0,
    },
    [FontType.XMSANS] = {
        szName = "小米Sans",
        szPath = "mui/Fonts/Base/MiSans-Medium.ttf",
        szFontImg = "UIAtlas2_GameSetting_FontSample_3.png",
        fOffsetY = 1.5,
    },
    [FontType.FZJZ] = {
        szName = "方正剪纸",
        szPath = "mui/Fonts/Base/fzjz.ttf",
        szFontImg = "UIAtlas2_GameSetting_FontSample_4.png",
        fOffsetY = 0,
    },
}

local tDict = {
    [GameSettingType.FontStyle.Default.szDec] = FontType.Default,
    [GameSettingType.FontStyle.FZHT.szDec] = FontType.FZHT,
    [GameSettingType.FontStyle.XMSANS.szDec] = FontType.XMSANS,
    [GameSettingType.FontStyle.FZJZ.szDec] = FontType.FZJZ,
}

function FontMgr.Init()
    FontMgr.tbFontChanged = {}
    FontMgr.InitFontOffsetY()
    FontMgr.ReloadFont()
end

function FontMgr.UnInit()
    Event.UnRegAll(FontMgr)
end

function FontMgr.InitFontOffsetY()
    for _, tbInfo in pairs(tConfigs) do
        if cc.Label.setFontOffsetY then
            cc.Label:setFontOffsetY(tbInfo.szPath, tbInfo.fOffsetY)
        end
    end
end

function FontMgr.ReloadFont()
    local tStorageData = FontMgr.GetStorageData()
    for nFontID, szPath in pairs(tStorageData.tbFontPath) do
        if SetFontPath then
            SetFontPath(nFontID, szPath)
        end
        
        -- 这里后续可能会因为GameSetting被别的设置项改动，导致升级版本号了，引起Storage.Font和UISettingNewStorageTab的本地存档不一致问题
        -- if nFontID == FontID.Default then
        --     tInfo
        --     GameSettingData.StoreNewValue(UISettingKey.InterfaceFontStyle, FontType.Default)
        --     CustomData.Dirty(CustomDataType.Global)
        -- end
    end

    if KG3DEngine.SetCaptureFontFile then
        local szPath = tStorageData.tbFontPath[FontID.Default]
        if string.is_nil(szPath) then
            szPath = szDefaultPath
        end
        KG3DEngine.SetCaptureFontFile(szPath)
    end
end

function FontMgr.GetCurFont(nFontID)
    if not nFontID then
        LOG.ERROR("FontMgr.GetCurFont Error! nFontID:%s", tostring(nFontID))
        return
    end

    local tStorageData = FontMgr.GetStorageData()
    local szPath = tStorageData.tbFontPath[nFontID]
    for nFontType, tConfig in pairs(tConfigs) do
        if tConfig.szPath == szPath then
            return nFontType, Lib.copyTab(tConfig)
        end
    end

    return FontType.Default, Lib.copyTab(tConfigs[FontType.Default])
end

function FontMgr.ChangeFontWithGameSettingDesc(nFontID, szDesc)
    local nFontType = tDict[szDesc]
    FontMgr.ChangeFont(nFontID, nFontType)
end

function FontMgr.ChangeFont(nFontID, nFontType)
    if not nFontID then
        LOG.ERROR("FontMgr.ChangeFont Error! nFontID:%s", tostring(nFontID))
        return
    end

    local tConfig = tConfigs[nFontType]
    if not tConfig then
        LOG.ERROR("FontMgr.ChangeFont Error! nFontType:%s", tostring(nFontType))
        return
    end

    local tStorageData = FontMgr.GetStorageData()
    if tStorageData.tbFontPath[nFontID] ~= tConfig.szPath then
        tStorageData.tbFontPath[nFontID] = tConfig.szPath
        FontMgr.tbFontChanged[nFontID] = true
        tStorageData.Dirty()
        TipsHelper.ShowNormalTip("字体样式更换后需要重启游戏方可生效")
    end

    -- UIHelper.ShowConfirm(string.format("更换后需要退出游戏重载字体样式，是否确认现在更换字体为【%s】?", tConfig.szName), function ()
    --     FontMgr.DoChangeFont(nFontType)
    -- end)
end

function FontMgr.GetStorageData()
    return Storage.Font
end

function FontMgr.GetFontName(nFontType)
    local tConfig = tConfigs[nFontType]
    if not tConfig then
        LOG.ERROR("FontMgr.ChangeFont Error! nFontType:%s", tostring(nFontType))
        return
    end

    return tConfig.szName
end

function FontMgr.GetFontConfig(nFontType)
    local tConfig = tConfigs[nFontType]
    if not tConfig then
        LOG.ERROR("FontMgr.ChangeFont Error! nFontType:%s", tostring(nFontType))
        return
    end

    return Lib.copyTab(tConfig)
end

function FontMgr.GetFontConfigGameSettingDesc(szDesc)
    local nFontType = tDict[szDesc]
    local tConfig = tConfigs[nFontType]
    if not tConfig then
        LOG.ERROR("FontMgr.ChangeFont Error! nFontType:%s", tostring(nFontType))
        return
    end

    return Lib.copyTab(tConfig)
end

function FontMgr.CheckFontChange(nGameSettingMainCategory)
    local nFontID
    if nGameSettingMainCategory == INTERFACE.FONT then
        nFontID = FontID.Default
    elseif nGameSettingMainCategory == BATTLE_INFO.MAIN then
        nFontID = FontID.BattleInfo
    end

    if not nFontID then
        return
    end

    if FontMgr.tbFontChanged[nFontID] then
        return "字体已更改，重启后生效"
    end
end

function FontMgr.DoChangeFont(nFontType)
    local tConfig = tConfigs[nFontType]
    if not tConfig then
        LOG.ERROR("FontMgr.ChangeFont Error! nFontType:%s", tostring(nFontType))
        return
    end

    local szDefaultFullPath = GetFullPath(szDefaultPath)
    local szFullPath = GetFullPath(tConfig.szPath)

    if Lib.IsFileExist(szDefaultFullPath, false) then
        Lib.RemoveFile(szDefaultFullPath)
    end

    local szDefaultDirectoryPath = GetFullPath(szDefaultDirectory)
    CPath.MakeDir(szDefaultDirectoryPath)

    if Lib.IsFileExist(szFullPath, false) then
        local szContent = Lib.GetStringFromFile(szFullPath)
        Lib.WriteStringToFile(szContent, szDefaultFullPath)
    end

    local scriptView = UIHelper.ShowConfirm("更换字体样式成功，请重启游戏方可生效！", function ()
        -- Game.Exit()
    end)
    scriptView:HideButton("Cancel")
end