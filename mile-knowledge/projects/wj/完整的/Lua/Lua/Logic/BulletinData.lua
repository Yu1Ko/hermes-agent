-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: BulletinData
-- Date: 2023-12-21 11:24:31
-- Desc: 公告
-- ---------------------------------------------------------------------------------

BulletinData = BulletinData or {className = "BulletinData"}
local self = BulletinData

local AUTO_UPDATE_INTEVAL = 300
local UPDATE_LIMIT = 15

local DEFAULT_ANNOUNCEMENT = "《剑网3无界》公测现已震撼开启！互通打破时空桎梏，万物互联迈入新进程，macOS端beta版本不限号测试进行中，掌机模式、手柄模式、蓝牙键鼠操作适配均已上线，手机、电脑、商务笔记本都可以接入同一片无界江湖！"

BulletinType = {
    UpdateLog       = "UPDATE_LOG",     --更新日志
    Announcement    = "ANNOUNCEMENT",   --游戏公告
    System          = "SYSTEM",         --系统公告
    Recharge        = "RECHARGE",       --充值返还公告
    SkillUpdate     = "SKILL_UPDATE"    --技改公告
}

local tBulletinUrl = {
    --更新日志
    [BulletinType.UpdateLog] = {
        Review = "https://jx3.xoyo.com/launcher/update/qa.html", --提审服
        Exp_PC = "https://jx3.xoyo.com/launcher/update/latest_exp.html", --体服
        -- Exp = "https://jx3.xoyo.com/launcher/update/ultimate_test.html", --2024.3.1运营需求 保密测试
        Exp = "https://jx3.xoyo.com/launcher/update/latest_exp.html", --2025.10.15 体服 移动端
        Default = "https://jx3.xoyo.com/launcher/update/latest.html", --正式
    },
    --游戏公告（DX启动器）
    [BulletinType.Announcement] = {
        -- Exp_PC = "https://static-support.xoyocdn.com/officialssi/jx3/client_nc.txt", --体服（旧版）
        -- Exp = "https://static-support.xoyocdn.com/officialssi/jx3/wjdemo.txt", --2024.3.7 运营需求 保密测试和二测用
        Exp = "https://static-support.xoyocdn.com/officialssi/jx3/client_nc.txt", --2025.10.15 体服 移动端
        Default = "https://static-support.xoyocdn.com/officialssi/jx3/client.txt", --正式（旧版）

        --2024.10.10 运营需求 https://kdocs.cn/l/cciIHkqFXn3W
        PC = "https://static-support.xoyocdn.com/officialssi/jx3/jisu.txt", --极速端（PC、macOS）正式服-启动器链接
        Exp_PC = "https://static-support.xoyocdn.com/officialssi/jx3/jisu_test.txt", --极速端（PC、macOS）测试服-启动器链接
        Android = "https://static-support.xoyocdn.com/officialssi/jx3/android.txt", --安卓端正式服-启动器链接
        Ios = "https://static-support.xoyocdn.com/officialssi/jx3/ios.txt", --iOS端正式服-启动器链接
    },
    --系统公告（DX登录界面）
    [BulletinType.System] = {
        Exp = "https://static-support.xoyocdn.com/officialssi/jx3/client_nc_ext.txt", --体服（旧版）
        Default = tUrl.Bulletin, --正式（旧版）

        --2024.10.10 运营需求 https://kdocs.cn/l/cciIHkqFXn3W
        PC = "https://static-support.xoyocdn.com/officialssi/jx3/jisu_ext.txt", --极速端（PC、macOS）正式服-登录界面链接
        Exp_PC = "https://static-support.xoyocdn.com/officialssi/jx3/jisu_test_ext.txt", --极速端（PC、macOS）测试服-登录界面链接
        Android = "https://static-support.xoyocdn.com/officialssi/jx3/android_ext.txt", --安卓端正式服-登录界面链接
        Ios = "https://static-support.xoyocdn.com/officialssi/jx3/ios_ext.txt", --iOS端正式服--登录界面链接
    },
    --充值返还公告
    [BulletinType.Recharge] = {
        Default = "https://jx3.xoyo.com/mobile/embed/bulletin.html", --正式
    },
    --技改公告
    [BulletinType.SkillUpdate] = {
        Default = "https://jx3.xoyo.com/mobile/embed/information.html", --正式
    },
}

function BulletinData.Init()
    self.RegEvent()

    self.tBulletin = {}
    self.UpdateAllBulletin(true)

    Timer.AddCycle(self, AUTO_UPDATE_INTEVAL, function()
        self.UpdateAllBulletin()
    end)
end

function BulletinData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function BulletinData.RegEvent()
    Event.Reg(self, "CURL_REQUEST_RESULT", function(szKey, bSuccess, szContent, dwBufferSize)
        self.OnCURLRequestResult(szKey, bSuccess, szContent, dwBufferSize)
    end)
end

function BulletinData.GetBulletin(szBulletinType)
    if self.tBulletin and self.tBulletin[szBulletinType] then
        return self.tBulletin[szBulletinType].bSuccess, self.tBulletin[szBulletinType].szContent
    end
end

function BulletinData.CheckOpenBulletinPanel()
    if UIMgr.IsViewOpened(VIEW_ID.PanelUpdateAbroad) then
        return
    end

    local szBulletinType

    --按以下优先顺序
    if self.HasNewBulletin(BulletinType.System) then
        szBulletinType = BulletinType.System
    elseif self.HasNewBulletin(BulletinType.Announcement) then
        szBulletinType = BulletinType.Announcement
    elseif self.HasNewBulletin(BulletinType.UpdateLog) then
        szBulletinType = BulletinType.UpdateLog
    elseif self.HasNewBulletin(BulletinType.Recharge) then
        szBulletinType = BulletinType.Recharge
    elseif self.HasNewBulletin(BulletinType.SkillUpdate) then
        szBulletinType = BulletinType.SkillUpdate
    end

    if szBulletinType then
        UIMgr.Open(VIEW_ID.PanelUpdateAbroad, szBulletinType)
    end
end

function BulletinData.UpdateBulletinStorage()
    for _, szBulletinType in pairs(BulletinType) do
        local szMD5 = self.GetBulleintMD5(szBulletinType)
        Storage.Bulletin.tbBulletin[szBulletinType] = szMD5
    end
    Storage.Bulletin.Flush()
end

function BulletinData.HasNewBulletin(szBulletinType)
    local _, szBulletin = self.GetBulletin(szBulletinType)
    if string.is_nil(szBulletin) then
        return false
    end

    if not self.IsInShowTime(szBulletinType) then
        return false
    end

    --游戏公告为默认文本时不视为新公告
    if szBulletinType == BulletinType.Announcement and BulletinData.IsDefaultAnnouncement() then
        return false
    end

    local szMD5 = self.GetBulleintMD5(szBulletinType)
    local bResult = Storage.Bulletin.tbBulletin[szBulletinType] ~= szMD5
    return bResult
end

function BulletinData.IsInShowTime(szBulletinType)
    -- 充值返还只在正式版本(versiong_vk.cfg versionex = "mb")才显示
    if BulletinType.Recharge and not Version.IsMB() then
        return false
    end

    local _, szBulletin = self.GetBulletin(szBulletinType)
    if string.is_nil(szBulletin) then
        return false
    end

    local nStartTime = tonumber(string.match(szBulletin, "%[start time%](.*)%[start time%]"))
    local nEndTime = tonumber(string.match(szBulletin, "%[finish time%](.*)%[finish time%]"))

    local nCurTime = Timer.GetTime()
    if nStartTime and nCurTime < nStartTime then
        return false
    end

    if nEndTime and nCurTime > nEndTime then
        return false
    end

    return true
end

--测试用
function BulletinData.ClearBulletinStorage()
    Storage.Bulletin.tbBulletin = {}
    Storage.Bulletin.tbRedPointBulletin = {}
    Storage.Bulletin.Flush()
end

function BulletinData.UpdateAllBulletin(bForce)
    local nTime = GetTickCount()
    if self.nCanUpdateTime and nTime < self.nCanUpdateTime and not bForce then
        return
    end

    --界面打开时也停止自动刷新，防止卡顿
    if UIMgr.IsViewOpened(VIEW_ID.PanelUpdateAbroad) then
        return
    end

    for _, szBulletinType in pairs(BulletinType) do
        self.RequestBulletin(szBulletinType)
    end

    self.nCanUpdateTime = nTime + UPDATE_LIMIT * 1000 --限制每15秒刷新一次
end

function BulletinData.GetBulletinURL(szBulletinType)
    local szUrl
    local _, _, _, szVersionEx, _ = GetVersion()
    local bExp = false--szVersionEx == GetVersionExp() or szVersionEx == "bvt" --体服
    local bReview = AppReviewMgr.IsReview()

    local tUrl = tBulletinUrl[szBulletinType]
    if bReview and tUrl.Review then
        szUrl = tUrl.Review
    elseif bExp and (Platform.IsWindows() or Platform.IsMac()) and tUrl.Exp_PC then
        szUrl = tUrl.Exp_PC
    elseif bExp and tUrl.Exp then
        szUrl = tUrl.Exp
    elseif (Platform.IsWindows() or Platform.IsMac()) and tUrl.PC then
        szUrl = tUrl.PC
    elseif Platform.IsAndroid() and tUrl.Android then
        szUrl = tUrl.Android
    elseif Platform.IsIos() and tUrl.Ios then
        szUrl = tUrl.Ios
    else
        szUrl = tUrl.Default
    end

    return szUrl
end

function BulletinData.GetBulleintMD5(szBulletinType)
    local _, szBulletin = BulletinData.GetBulletin(szBulletinType)
    if string.is_nil(szBulletin) then
        return
    end

    -- if szBulletinType == BulletinType.Announcement then
    --     --系统公告取MD5排除日期
    --     local szText, szDate = string.match(szBulletin, "(.*)\n(.*)$")
    --     if szText and szDate then
    --         szBulletin = szText
    --     end
    -- end
    return UIHelper.MD5(szBulletin)
end

function BulletinData.IsDefaultAnnouncement()
    local _, szBulletin = BulletinData.GetBulletin(BulletinType.Announcement)

    --排除日期
    local szText, szDate = string.match(szBulletin, "(.*)\n(.*)$")
    if szText and szDate then
        szBulletin = szText
    end

    if szBulletin == DEFAULT_ANNOUNCEMENT then
        return true
    end

    return false
end

function BulletinData.RequestBulletin(szBulletinType, bClear)
    local szUrl = self.GetBulletinURL(szBulletinType)

    if szUrl then
        --LOG.INFO("[BulletinData] Request BulletinData: %s", szUrl)

        if self.tBulletin[szBulletinType] then
            self.tBulletin[szBulletinType].bSuccess = nil
        end

        local bSSL = string.starts(szUrl, "https")
        CURL_HttpRqst(szBulletinType, szUrl, bSSL, 10)
    end
end

function BulletinData.OnCURLRequestResult(szKey, bSuccess, szContent, dwBufferSize)
    if not table.contain_value(BulletinType, szKey) then
        return
    end

    local szBulletinType = szKey
    if not self.tBulletin[szBulletinType] then
        self.tBulletin[szBulletinType] = {}
    end

    self.tBulletin[szBulletinType].bSuccess = bSuccess
    if bSuccess then --成功才更新内容

    -- 这两类需要解析Json
        if szBulletinType == BulletinType.Announcement or szBulletinType == BulletinType.System then
            if not string.is_nil(szContent) then
                local tRspData, szErrMsg = JsonDecode(szContent)
                if IsTable(tRspData) and tRspData.success == true then
                    if IsTable(tRspData.data) then
                        local szContent = tRspData.data.content or ""
                        local szPubDate = tRspData.data.pubdate or ""
                        self.tBulletin[szBulletinType].szContent = string.format("%s\n%s", szContent, szPubDate)
                    end
                end
            end
        else
            self.tBulletin[szBulletinType].szContent = szContent
        end
    end

    --print("[BulletinData] OnBulletinUpdate", szBulletinType)
    Event.Dispatch(EventType.OnBulletinUpdate)
    Event.Dispatch(EventType.OnBulletinRedPointUpdate)
end