-- 动画管理器，协议动画、视频动画
MovieMgr = MovieMgr or {className = "MovieMgr"}

---- UI常量
-- 播放协议动画需要的最小Gpu分数
local kMiniGupScoreForMovie = 783
-- dummy网络视频，出错或是咸鱼端使用
local kDummyNetworkVideo = "http://jx3.xoyo.com/zt/2018/06/20/v/index.html?video=http://static.jx3.xoyo.com/client/20190529/jingqingqidai-1080p.mp4"
local getBandwidthEstimation, getMovieQualityFromBandwidth
local getGpuScore, isLeisureClient
local informServerOnPlayMovie

-- 视频分辨率顺序, 超清->高清->标清（中画质、高画质、自定义画质这三档画质）
local kVideoResOrder_1 = {"cq=([^&]+)", "gq=([^&]+)", "bq=([^&]+)", "video=([^%s^&]+)"}
-- 视频分辨率顺序, 高清->超清
local kVideoResOrder_2 = {"gq=([^&]+)", "cq=([^&]+)", "bq=([^&]+)", "video=([^%s^&]+)"}

MovieMgr.bPlayMovie = true

-- 播放视频
function MovieMgr.PlayVideo(szUrl, tConfig, tMovie, bIsStory, fnCallback)
    if AppReviewMgr.IsReview() then
        if tMovie then
            informServerOnPlayMovie(3, tMovie)
        end
        return
    end

    if Channel.Is_WLColud() then
        szUrl = string.gsub(szUrl,"MOBILE","PC")
    end

    -- 查看本地视频是否拥有
    if (not tConfig.bNet) and (not IsLocalFileExist(szUrl)) then
        if tMovie then
            informServerOnPlayMovie(3, tMovie)
        end
        return
    end

    -- iOS端的均衡和电影画质，关闭流媒体视频播放
    if tConfig.bNet and Platform.IsIos() then
        local nRecommendQualityType = QualityMgr.GetRecommendQualityType()
        if nRecommendQualityType ~= GameQualityType.EXTREME_HIGH then
            if tMovie then
                informServerOnPlayMovie(3, tMovie)
            end
            if tConfig.bShop then
                TipsHelper.ShowNormalTip("非常抱歉，由于设备性能限制，已跳过动画来确保能够流畅地体验游戏")
            end
            return
        end
    end

    local videoPlayer = UIMgr.GetViewScript(VIEW_ID.PanelVideoPlayer)
    if videoPlayer then
        LOG.ERROR("last movie has not complete, url:%s", tostring(videoPlayer.szUrl))
        UIMgr.Close(videoPlayer)
    end
    if tMovie then
        informServerOnPlayMovie(1, tMovie)
    end

    Event.Reg(MovieMgr , EventType.OnViewOpen, function (nViewID)
        if nViewID == VIEW_ID.PanelVideoPlayer then
            local videoPlayer = UIMgr.GetViewScript(VIEW_ID.PanelVideoPlayer)
            szUrl = string.gsub(szUrl, ".webm", ".mp4")
            videoPlayer:SetStoryState(bIsStory)
            videoPlayer:Play(szUrl, tConfig, function (bNormalEnd)
                if tMovie then
                    if fnCallback then
                        fnCallback()
                    end
                    if bNormalEnd then
                        --教学 流媒体动画结束
                        FireHelpEvent("OnURLMovieStop", tMovie.dwNewMovieID or tMovie.dwStoryID or tMovie.szMoviePath)
                    end
                    -- 通知回服务器
                    informServerOnPlayMovie(bNormalEnd and 2 or 3, tMovie)
                end
            end)
            if tConfig.bHideSkip ~= nil then
                UIHelper.SetVisible(videoPlayer.btnClose, not tConfig.bHideSkip) -- 视频只显示一次 不允许跳过
            end
            Event.UnReg(MovieMgr, EventType.OnViewOpen)
        end
    end)
    UIMgr.Open(VIEW_ID.PanelVideoPlayer)
end

-- 停止视频
function MovieMgr.StopVideo()
    UIMgr.Close(VIEW_ID.PanelVideoPlayer)
end

function MovieMgr.StopStory()
    UIMgr.Close(VIEW_ID.PanelStoryDisplay)
end

-- 播放协议动画
function MovieMgr.PlayStory(nStoryID, tConfig, tMovie, szUrl)
    -- 游戏内协议动画修改为视频播放
    if szUrl ~= "-1" then
        if MovieMgr.IsSkipFubenVideo() then
            TipsHelper.ShowNormalTip("已为侠士在秘境中自动跳过流媒体动画，如需观看请前往游戏设置中关闭自动跳过")
            if tMovie then
                informServerOnPlayMovie(3, tMovie)
            end
            return
        end
        tConfig.bNet = true
        informServerOnPlayMovie(1, tMovie)
        MovieMgr.PlayVideo(szUrl, tConfig, tMovie, true)
    else
        local excuePlayStory = function()
            informServerOnPlayMovie(1, tMovie)
            local storyDisplay = UIMgr.Open(VIEW_ID.PanelStoryDisplay)                    ---@type UIStoryDisplay 协议剧情
            storyDisplay:Play(nStoryID, tConfig, function (bNormalEnd)
                if tMovie then
                    if bNormalEnd then
                        --教学 流媒体动画结束
                        FireHelpEvent("OnURLMovieStop", tMovie.dwNewMovieID or tMovie.dwStoryID or tMovie.szMoviePath)
                    end
                    -- 通知回服务器
                    informServerOnPlayMovie(bNormalEnd and 2 or 3, tMovie)
                end
            end)
        end

        if not MovieMgr.CalculateMovieSize(nStoryID) then
            informServerOnPlayMovie(3, tMovie)
            TipsHelper.ShowNormalTip("内存不足，无法播放实时动画")
            return
        end

        local storyDisplay = UIMgr.GetViewScript(VIEW_ID.PanelStoryDisplay)     ---@type UIStoryDisplay 协议剧情
        if storyDisplay then
            UIMgr.Close(storyDisplay)
            Event.Reg(MovieMgr, "STOP_MOVIES", function ()
                excuePlayStory()
            end,true)
        else
            excuePlayStory()
        end
    end
end

-- 播放协议动画
function MovieMgr.PlayStoryWithoutServer(nStoryID, tConfig, tMovie, szUrl)
    -- 游戏内协议动画修改为视频播放
    if szUrl ~= "-1" then
        if MovieMgr.IsSkipFubenVideo() then
            TipsHelper.ShowNormalTip("已为侠士在秘境中自动跳过流媒体动画，如需观看请前往游戏设置中关闭自动跳过")
            return
        end
        tConfig.bNet = true
        MovieMgr.PlayVideo(szUrl, tConfig, tMovie, true)
    else
        local excuePlayStory = function()
            local storyDisplay = UIMgr.Open(VIEW_ID.PanelStoryDisplay)                    ---@type UIStoryDisplay 协议剧情
            storyDisplay:Play(nStoryID, tConfig, function (bNormalEnd)
                if tMovie then
                    if bNormalEnd then
                        --教学 流媒体动画结束
                        FireHelpEvent("OnURLMovieStop", tMovie.dwNewMovieID or tMovie.dwStoryID or tMovie.szMoviePath)
                    end
                end
            end)
        end

        if not MovieMgr.CalculateMovieSize(nStoryID) then
            TipsHelper.ShowNormalTip("内存不足，无法播放实时动画")
            return
        end

        local storyDisplay = UIMgr.GetViewScript(VIEW_ID.PanelStoryDisplay)     ---@type UIStoryDisplay 协议剧情
        if storyDisplay then
            UIMgr.Close(storyDisplay)
            Event.Reg(MovieMgr, "STOP_MOVIES", function ()
                excuePlayStory()
            end,true)
        else
            excuePlayStory()
        end
    end
end

---@alias PlayType
---|`0 or nil` #表示代码自行决定
---|`1` #表示强制播放协议动画
---|`2` #表示强制播放url视频
---@param dwID number #协议动画ID
---@param bCannotCancel boolean #不能取消（只适用于协议动画）
---@param nPlayType PlayType #播放类型
function MovieMgr.PlayUrlMovieOrProtocolMovie(dwID, bCannotCancel, nPlayType)

    local tInfo = Table_GetNewMovieInfo(dwID)
    local szUrl = tInfo.szUrlAddress
    if tInfo.szMobileURL and tInfo.szMobileURL ~= "" then
        szUrl = tInfo.szMobileURL
    end

    if isLeisureClient() then
        if szUrl == "-1" then
            szUrl = kDummyNetworkVideo
        end
    end

    if tInfo.nMobilePlayType == 1 then --VK强制播放协议动画
        szUrl = "-1"
    end
    if tInfo.nReqiureQuality > 0 then
        local nRecommendQuality = QualityMgr.GetRecommendQualityType()
        if nRecommendQuality < tInfo.nReqiureQuality and szUrl == "-1" then --画质要求不足再切成流媒体
            szUrl = tInfo.szUrlAddress
            if tInfo.szMobileURL and tInfo.szMobileURL ~= "" then
                szUrl = tInfo.szMobileURL
            end
        end
    end

    MovieMgr.PlayStory(tInfo.dwProtocolID,
        {bCanStop = not bCannotCancel , bEnableAdjust = tInfo.bEnableAdjust},
        {dwStoryID = tInfo.dwProtocolID, dwNewMovieID = dwID},
        szUrl)
end

-- 播放协议动画
-- 咸鱼端、Gpu分数不达标播放视频，反之播放协议动画
function MovieMgr.PlayProtocolMovie(dwStoryID, bCannotStop, dwOtherRoleID, bCMYKEffect, fCameraDistance)
    local dwNewMovieID = Table_GetNewMovieIDByProtocolID(dwStoryID)
    local szUrl = "-1"
    local bAdjust = false
    if dwNewMovieID == 0 then
        if isLeisureClient() then
            szUrl = kDummyNetworkVideo
        end
    else
        local tInfo = Table_GetNewMovieInfo(dwNewMovieID)
        szUrl = tInfo.szUrlAddress
        if tInfo.szMobileURL and tInfo.szMobileURL ~= "" then
            szUrl = tInfo.szMobileURL
        end
        if isLeisureClient() then
            if szUrl == "-1" then
                szUrl = kDummyNetworkVideo
            end
        end
        bAdjust = tInfo.bEnableAdjust

        if tInfo.nMobilePlayType == 1 then --VK强制播放协议动画
            szUrl = "-1"
        end
        if tInfo.nReqiureQuality > 0 then
            local nRecommendQuality = QualityMgr.GetRecommendQualityType()
            if nRecommendQuality < tInfo.nReqiureQuality and szUrl == "-1" then --画质要求不足再切成流媒体
                szUrl = tInfo.szUrlAddress
                if tInfo.szMobileURL and tInfo.szMobileURL ~= "" then
                    szUrl = tInfo.szMobileURL
                end
            end
        end
    end

    MovieMgr.PlayStory(dwStoryID,
            {bCanStop = not bCannotStop, bEnableCmyk = bCMYKEffect, nCameraDistance = fCameraDistance, nOtherRoleID = dwOtherRoleID , bEnableAdjust = bAdjust},
            {dwStoryID = dwStoryID, dwOtherRoleID = dwOtherRoleID}
            ,szUrl)
end

-- 强制播放协议动画
function MovieMgr.ForcePlayProtocolMovie(dwStoryID, bCannotStop, dwOtherRoleID, bCMYKEffect, fCameraDistance)
    local dwNewMovieID = Table_GetNewMovieIDByProtocolID(dwStoryID)
    local szUrl = "-1"
    local bAdjust = false
    if dwNewMovieID == 0 then
        if isLeisureClient() then
            szUrl = kDummyNetworkVideo
        end
    else
        local tInfo = Table_GetNewMovieInfo(dwNewMovieID)
        szUrl = tInfo.szUrlAddress
        if tInfo.szMobileURL and tInfo.szMobileURL ~= "" then
            szUrl = tInfo.szMobileURL
        end
        bAdjust = tInfo.bEnableAdjust

        if tInfo.nMobilePlayType == 1 then --VK强制播放协议动画
            szUrl = "-1"
        end
        if tInfo.nReqiureQuality > 0 then
            local nRecommendQuality = QualityMgr.GetRecommendQualityType()
            if nRecommendQuality < tInfo.nReqiureQuality and szUrl == "-1" then --画质要求不足再切成流媒体
                szUrl = tInfo.szUrlAddress
                if tInfo.szMobileURL and tInfo.szMobileURL ~= "" then
                    szUrl = tInfo.szMobileURL
                end
            end
        end
    end

    MovieMgr.PlayStory(dwStoryID,
        {bCanStop = not bCannotStop, bEnableCmyk = bCMYKEffect, nCameraDistance = fCameraDistance, nOtherRoleID = dwOtherRoleID, bEnableAdjust = bAdjust},
        {dwStoryID = dwStoryID, dwOtherRoleID = dwOtherRoleID}
    ,szUrl)

end

--计算协议动画大小
function MovieMgr.CalculateMovieSize(dwStoryID)
    local player = GetClientPlayer()
    if not player then
        return
    end

    --ios跳过判断
    if Platform.IsIos() then
        return true
    end

    local nClientVersionType = player.nClientVersionType
    local fMovieSize = Scene_GetMovieSize(dwStoryID, nClientVersionType)

    local nDeviceMemorySize = Device.GetDeviceAvailableMemorySize(false)
    nDeviceMemorySize = nDeviceMemorySize / 1024 / 1024 --转为MB

    Log("CalculateMovieSize : dwStoryID = " .. dwStoryID ..  " , fMovieSize = " .. fMovieSize .. " , nDeviceMemorySize = " .. nDeviceMemorySize)
    if nDeviceMemorySize > fMovieSize then
        return true
    end
end

function MovieMgr.PreLoadProtocolMovie(dwStoryID)
    --ios跳过判断
    if Platform.IsIos() then
        return
    end

    if not MovieMgr.CalculateMovieSize(dwStoryID) then
        TipsHelper.ShowNormalTip("内存不足，无法播放实时动画")
        return
    end
    rlcmd("pre load scene movie " .. dwStoryID)
end

---comment 获取端游链接中的静态视频地址
---@param szUrl string
---@return string url
function MovieMgr.ParseStaticUrl(szUrl , bSelectGQ)
    local kVideoResOrder = ""
    if QualityMgr.GetBasicQualityType() <= GameQualityType.MID or bSelectGQ then
        kVideoResOrder = kVideoResOrder_2
    else
        kVideoResOrder = kVideoResOrder_1
    end
    for _, s in ipairs(kVideoResOrder) do
        local url = string.match(szUrl, s)
        if url then
            return url
        end
    end
    return szUrl
end


---@param nEventType EventType
---| `1` #开始播放
---| `2` #自然结束播放
---| `3` #玩家主动结束播放
---@param tMovieInfo table
---tMovieInfo {
---  szMoviePath="",    分别代表本地mp4文件路径
---  dwNewMovieID=1,    新/旧视频ui配置表第一列的ID
---  dwOldMovieID=1,
---  dwStoryID=1,
---  dwOtherRoleID=0    协议动画ID和可能存在的协议动画另一个角色的RoleID
---}
---需要注意，对于dwNewMovieID/dwOldMovieID，要提供的是最能够体现策划的远程调用的参数的数值（因此，比如说
---咸鱼端多种情况下播放的同一个网络视频要对应不同的ID）。
---注：这些字段未必同时存在，策划使用的时候按上述顺序从前往后判断存在性。
function MovieMgr.InformServerOnPlayMovie(nEventType, tMovieInfo)
    informServerOnPlayMovie(nEventType, tMovieInfo)
end

function MovieMgr.IsSkipFubenVideo()
    local bSkip = false
    local bStoreValue = GameSettingData.GetNewValue(UISettingKey.AutoSkipDungeonAnimation)
    if DungeonData.IsInDungeon() and bStoreValue ~= nil then
        bSkip = bStoreValue
    end
    return bSkip
end

function MovieMgr.SetPlayMovie(bPlay)
    MovieMgr.bPlayMovie = bPlay
end



function informServerOnPlayMovie(nEventType, tMovieInfo)

    if not tMovieInfo then
        LOG.ERROR("[MovieMgr] informServerOnPlayMovie tMovieInfo is nil")
    elseif type(tMovieInfo) == "table" and table.get_len(tMovieInfo) == 0 then
        LOG.ERROR("[MovieMgr] informServerOnPlayMovie tMovieInfo is {}")
    end

    local szFuncName
    if nEventType == 1 then
        szFuncName = "On_UIMovie_StartEvent"
    elseif nEventType == 2 then
        szFuncName = "On_UIMovie_Event"
    else
        szFuncName = "On_UIMovie_EscEvent"
    end

    RemoteCallToServer(szFuncName, tMovieInfo)
end

--------------------------- 辅助函数 -----------------------------
function getMovieQualityFromBandwidth(nBandWidth) --- 单位：B/s
    if nBandWidth >= 2 * 1024 * 1024 then
        return "cq" --- 超清
    elseif nBandWidth >= 1 * 1024 * 1024 then
        return "gq" --- 高清
    else
        return "bq" --- 标清
    end
end

function getGpuScore()
    --TODO: 由于X3D客户端没有能计算Gpu分数，这里默认都能播放协议动画
    do return kMiniGupScoreForMovie + 1 end

    if GetGPUScore then
        return GetGPUScore()
    else
        LOG.ERROR("ERROR！无法调用函数 GetGPUScore()！")
    end

    --- 直接读取文件中的字段
    local ini
    if cc.FileUtils:getInstance():isFileExist("config/machine_config.ini") then
        ini = Ini.Open("config/machine_config.ini")
    else
        LOG.ERROR("ERROR! Failed to Read ini file: config/machine_config.ini!")
        return 500
    end

    local nGPUScore, bSuccess = ini:ReadInteger("Performance", "GPUScore", 500)
    if not bSuccess then
        LOG.ERROR("ERROR! Failed to Read field \"Performance/GPUScore\" ini file: config/machine_config.ini!")
    end
    return nGPUScore
end

function getBandwidthEstimation()
    local nPackageVersion = Package_GetVersion()
    if nPackageVersion == 4 or nPackageVersion == 3 then
        if GetBandwidthEstimation then
            return GetBandwidthEstimation()
        else
            LOG.ERROR("ERROR！无法调用函数 GetBandwidthEstimation()！")
            if nPackageVersion == 4 then
                return PakV4GetBandwidthEstimation()
            end
        end
    end

    --- 直接读取文件中的字段
    local ini
    if cc.FileUtils:getInstance():isFileExist("config/userconfig.ini") then
        ini = Ini.Open("config/userconfig.ini")
    else
        LOG.ERROR("ERROR! Failed to Read ini file: config/userconfig.ini!")
        return 1000
    end

    local nBandwidthEstimation, bSuccess = ini:ReadInteger("Network_V3", "BandwidthEstimation", 1000)
    if not bSuccess then
        LOG.ERROR("ERROR! Failed to Read field \"Network_V3/BandwidthEstimation\" ini file: config/userconfig.ini!")
    end
    return nBandwidthEstimation
end

--TODO: 判断是否咸鱼端
function isLeisureClient()
    return false
end

function MovieMgr.PlayCoinShopMovie(dwID, tRepresentID)
	rlcmd("begin represent offline")
	Character_SetOfflineRepresentIDs(tRepresentID)
   	MovieMgr.PlayStoryWithoutServer(dwID, {bCanStop = true}, nil, "-1")

    Timer.Add(MovieMgr, 0.2, function ()
        UIMgr.ShowLayer(UILayer.Scene)
    end)
    Event.Reg(MovieMgr, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelStoryDisplay then
            rlcmd("end represent offline")
            local bNeedHideScene = false
            for _, nViewID in pairs(UIMgr.GetAllOpenViewID()) do
                local conf = TabHelper.GetUIViewTab(nViewID)
                if conf and conf.bPauseScene then
                    bNeedHideScene = true
                    break
                end
            end
            if bNeedHideScene then
                UIMgr.HideLayer(UILayer.Scene)
            end
            Event.UnReg(MovieMgr, EventType.OnViewClose)
        end
    end)
end

-- 播放视频
function MovieMgr.PlayCoinShopFadeInVideo()
    if AppReviewMgr.IsReview() then
        return
    end

    local tConfig = {bNet = false}
    local szUrl = "mui\\Video\\PC\\SCKP.mp4"
    if Platform.IsMobile() then
        szUrl = "mui\\Video\\MOBILE\\SCKP.mp4"
    end

    szUrl = UIHelper.ParseVideoPlayerFile(szUrl , VIDEOPLAYER_MODEL.BINK)
    szUrl = GetFullPath(szUrl)

    if Channel.Is_WLColud() then
        szUrl = string.gsub(szUrl,"MOBILE","PC")
    end

    -- 查看本地视频是否拥有
    if (not tConfig.bNet) and (not IsLocalFileExist(szUrl)) then
        return
    end

    -- iOS端的均衡和电影画质，关闭流媒体视频播放
    if tConfig.bNet and Platform.IsIos() then
        local nRecommendQualityType = QualityMgr.GetRecommendQualityType()
        if nRecommendQualityType ~= GameQualityType.EXTREME_HIGH then
            if tConfig.bShop then
                TipsHelper.ShowNormalTip("非常抱歉，由于设备性能限制，已跳过动画来确保能够流畅地体验游戏")
            end
            return
        end
    end

    local videoPlayer = UIMgr.GetViewScript(VIEW_ID.PanelExteriorFadeInVideo)
    if videoPlayer then
        LOG.ERROR("last movie has not complete, url:%s", tostring(videoPlayer.szUrl))
        UIMgr.Close(videoPlayer)
    end

    Event.Reg(MovieMgr , EventType.OnViewOpen, function (nViewID)
        if nViewID == VIEW_ID.PanelExteriorFadeInVideo then
            local videoPlayer = UIMgr.GetViewScript(VIEW_ID.PanelExteriorFadeInVideo)
            szUrl = string.gsub(szUrl, ".webm", ".mp4")
            videoPlayer:SetStoryState(false)
            videoPlayer:Play(szUrl, tConfig, function (bNormalEnd)

            end)
            Event.UnReg(MovieMgr, EventType.OnViewOpen)
        end
    end)
    UIMgr.Open(VIEW_ID.PanelExteriorFadeInVideo)
end
