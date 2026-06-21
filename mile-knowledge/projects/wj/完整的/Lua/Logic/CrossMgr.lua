-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: CrossMgr
-- Date: 2024-01-08 17:28:56
-- Desc: 跨服相关
-- ---------------------------------------------------------------------------------

CrossMgr = CrossMgr or {}
local self = CrossMgr

local tbForbidViewID =
{
    [VIEW_ID.PanelHuaELou] = true,
    [VIEW_ID.PanelOperationCenter] = true,
    [VIEW_ID.PanelExteriorMain] = true,
    [VIEW_ID.PanelReleaseRecruitPop] = true,
    [VIEW_ID.PanelWorldAuction] = true,
    -- [VIEW_ID.PanelAccessGoods] = true,
    [VIEW_ID.PanelTradingHouse] = true,
    [VIEW_ID.PanelChangeNamePop] = true,
    [VIEW_ID.PanelWuDou] = true,
    [VIEW_ID.PanelEmail] = true,
    [VIEW_ID.PanelActivityCalendar] = true,
    [VIEW_ID.PanelHome] = true,
    [VIEW_ID.PanelPvPCampJoin] = true,
    [VIEW_ID.PanelRoadCollection] = true,
    [VIEW_ID.PanelJiangHuBaiTai] = true,
    [VIEW_ID.PanelFactionManagement] = true,
    [VIEW_ID.PanelFactionList] = true,
    [VIEW_ID.PanelFengYunLu] = true,
    [VIEW_ID.PanelNameCard] = true,
    [VIEW_ID.PanelPlayerReputationPop] = true,
    [VIEW_ID.PanelCareer] = true,
    [VIEW_ID.PanelReleaseRewardPop] = true,
    [VIEW_ID.PanelPetMap] = true,
    [VIEW_ID.PanelShenBingUpgrade] = true,
    [VIEW_ID.PanelApprenticeNew] = true,
    [VIEW_ID.PanelWelfareReturnPop] = true,
}


function CrossMgr.IsCrossing(dwPlayerID, bWithTips)
    local bResult = false

    if not IsNumber(dwPlayerID) then
        dwPlayerID = g_pClientPlayer and g_pClientPlayer.dwID or 0
    end

    bResult = IsRemotePlayer(dwPlayerID)

    if bResult then
        if bWithTips then
            TipsHelper.ShowNormalTip(g_tStrings.STR_REMOTE_NOT_TIP)
        end
    end

    return bResult
end

function CrossMgr.IsViewCanOpen(nViewID, bWithTips)
    if tbForbidViewID[nViewID] then
        if CrossMgr.IsCrossing(nil, bWithTips) then
            return false
        end
    end

    return true
end
