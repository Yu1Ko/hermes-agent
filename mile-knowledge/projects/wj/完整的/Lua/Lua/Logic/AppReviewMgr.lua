-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: AppReviewMgr
-- Date: 2023-05-08 22:36:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

AppReviewMgr = AppReviewMgr or {className = "AppReviewMgr"}
local self = AppReviewMgr


function AppReviewMgr.Init()
    if AppReviewMgr.IsReview() then
        g_tStrings.WAIT_FOR_OPEN_TIPS = ""
        return
    end

    if Platform.IsMac() then
        local szDesc = "macOS端beta版本，非最终品质"--"继承互通共研版本，非最终品质" --Platform.IsWindows() and "继承互通共研版本，非最终品质" or "手机上玩剑网3"
        UIMgr.Open(VIEW_ID.PanelCeAnnouncement, szDesc)
    end
end

function AppReviewMgr.UnInit()

end

function AppReviewMgr.OnLogin()

end

function AppReviewMgr.OnFirstLoadEnd()

end

local tbForbidViewID = {
    -- VIEW_ID.PanelActivityBanner,
}

if Platform.IsIos() then
    tbForbidViewID = {
        -- VIEW_ID.PanelBenefits,
        -- VIEW_ID.PanelBenefitBPRewardDetail,
        -- VIEW_ID.PanelTopUpMain,
        -- VIEW_ID.PanelActivityBanner,
    }
end



function AppReviewMgr.CheckForbidView(nViewID, bShowTip, ...)
    local bForbid = false

    if not Config.bIsCEVer then
        return bForbid
    end

    if table.contain_value(tbForbidViewID, nViewID) then
        bForbid = true
    else
        -- 中地图特殊处理
        if not AppReviewMgr.IsReview() then
            if nViewID == VIEW_ID.PanelMiddleMap then
                local tArgs = {...}
                local nMapID = tArgs and tArgs[1]
                if IsNumber(nMapID) and nMapID > 0 then
                    if not MapHelper.IsMapOpen(nMapID) then
                        bForbid = true
                    end
                end
            end
        end
    end

    if bForbid and bShowTip then
        TipsHelper.ShowNormalTip(g_tStrings.WAIT_FOR_OPEN_TIPS)
    end

    return bForbid
end

-- 特殊屏蔽
function AppReviewMgr.SpecialCheck(nViewID, ...)
    -- 副本入口
    if nViewID == VIEW_ID.PanelDungeonEntrance then
		if not DungeonData.CheckDungeonCondition(...) then
			TipsHelper.ShowNormalTip(g_tStrings.WAIT_FOR_OPEN_TIPS)
			return false
		end
	end

    -- 外观商城
	if nViewID == VIEW_ID.PanelExteriorMain then
		if not WG_IsEnable() and IsVersionExp() and not CommonDef.COINSHOP_CAN_OPEN_EXP then
			TipsHelper.ShowNormalTip(g_tStrings.WAIT_FOR_OPEN_TIPS)
			return false
		end

        -- 主干临时关闭
        if DEF_COINSHOP_DISABLE and not AppReviewMgr.IsReview() then
            return false
        end
	end

    if Channel.Is_WLColud() then
        -- 蔚领云游戏不让打开资源界面
        if nViewID == VIEW_ID.PanelResourcesDownload then
            LOG.INFO("WL Cloud Channel can not open PanelResourcesDownload.")
            return false
        end
    end

    if nViewID == VIEW_ID.PanelPlayStore then
        local args = {...}
        local nFullScreen = args[3]
        if nFullScreen and nFullScreen ~= 0 then
            UIMgr.Open(VIEW_ID.PanelActivityStoreNew, ...)
            return false
        end
    end

    if nViewID == VIEW_ID.PanelOperationCenter then
        if IsVersionExp() then
            TipsHelper.ShowNormalTip(g_tStrings.WAIT_FOR_OPEN_TIPS)
            return false
        end
    end

    -- 充值
    -- if nViewID == VIEW_ID.PanelTopUpMain then
    --     if Channel.Is_Tapyun() then
    --         WebUrl.OpenByID(55)
    --         return false
    --     end
    -- end

	return true
end

-- 是否是提审包
function AppReviewMgr.IsReview()
    return Config.bIsIosReview or Version.IsDouyin() or Version.IsWLCloud()
end

-- 是否开启静音
function AppReviewMgr.IsOpenGlobalAudioMute()
    return true
end

function AppReviewMgr.IsShowCameraShareChannel(szChannel)
    local tbDisableChannel = {
        --"qqimage"
        "weichatfriend",
        "weichatzone",
        "wechatfriend",
        "wechatzone"
        --"weibo",
        --"xhsnote",
        --"taptappublish",
        --"douyinpublish"
    }
    if not Channel.Is_dylianyunyun() then
        tbDisableChannel = {}
    end
    return not table.contain_value(tbDisableChannel , szChannel)
end

-- 是否开启分享页中的二维码
function AppReviewMgr.IsOpenShaderCode()
    return not AppReviewMgr.IsReview()
end

function AppReviewMgr.GetShaderCodeImage()
    if Channel.Is_DouYin() then
        return "UIAtlas2_NieLian_LoginFace_SharePage_6.png"
    end
    return "UIAtlas2_NieLian_LoginFace_SharePage_4.png"
end