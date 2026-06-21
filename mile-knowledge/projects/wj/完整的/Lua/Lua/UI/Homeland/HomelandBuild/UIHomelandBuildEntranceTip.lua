-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildEntranceTip
-- Date: 2023-04-19 15:09:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildEntranceTip = class("UIHomelandBuildEntranceTip")
local MAX_LAND_LEVEL = 16

local BtnType = {
    -- 总览
    Overview = 1,
    -- 家园建造
    StartBuild = 2,
    -- 交互
    Interact = 3,
    -- 管家召唤
    CallHousekeep = 4,
    -- 家园升级
    UpgradeHome = 5,
    -- 私邸换肤
    ChangeSkin = 6,
    -- 分区解锁
    UnlockArea = 7,
    -- 家园订单
    HomelandOrder = 8,
    -- 留言板
    MessageBoard = 9,
    -- 花价
    FlowerPrice = 10,
    -- -- 参与会赛
    -- JoinMatch = 8,
    -- -- 权限设置
    -- PermissionSetting = 9,
    -- -- 家具保管
    -- StorageFurniture = 10,
}

local tbBtnShowMode = {
    [HOMELAND_CONSTRUCT_TYPE.HOLDER] = {
        BtnType.Overview,
        BtnType.StartBuild,
        BtnType.Interact,
        BtnType.CallHousekeep,
        BtnType.UpgradeHome,
        BtnType.HomelandOrder,
        BtnType.FlowerPrice,
    },
    [HOMELAND_CONSTRUCT_TYPE.VISTOR] = {
        BtnType.Overview,
        BtnType.Interact,
        BtnType.HomelandOrder,
        BtnType.MessageBoard,
        BtnType.FlowerPrice,
    },
    [HOMELAND_CONSTRUCT_TYPE.WANDER] = {
        BtnType.Overview,
        BtnType.HomelandOrder,
        BtnType.FlowerPrice,
    },
    [HOMELAND_CONSTRUCT_TYPE.COHABIT] = {
        BtnType.Overview,
        BtnType.StartBuild,
        BtnType.Interact,
        BtnType.HomelandOrder,
        BtnType.FlowerPrice,
    },
}

local LOADING_END_CD = 3

function UIHomelandBuildEntranceTip:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbBtnShowFliter = tbBtnShowMode[1]
    self:Init()
    self:UpdateInfo()
end

function UIHomelandBuildEntranceTip:OnExit()
    self.bInit = false
end

function UIHomelandBuildEntranceTip:BindUIEvent()
    for i, btn in ipairs(self.tbBtns) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
            if i == BtnType.Overview then
                self:OnClickOverviewBtn()
            elseif i == BtnType.StartBuild then
                self:OnClickStartBuildBtn()
            elseif i == BtnType.Interact then
                self:OnClickInteractBtn()
            elseif i == BtnType.CallHousekeep then
                self:OnClickCallHousekeepBtn()
            elseif i == BtnType.UpgradeHome then
                self:OnClickUpgradeHomeBtn()
            elseif i == BtnType.ChangeSkin then
                self:OnClickChangeSkinBtn()
            elseif i == BtnType.UnlockArea then
                self:OnClickUnlockAreaBtn()
            elseif i == BtnType.HomelandOrder then
                self:OnClickHomeOrderBtn()
            elseif i == BtnType.MessageBoard then
                self:OnClickMessageBoardBtn()
            elseif i == BtnType.FlowerPrice then
                self:OnClickFlowerPriceBtn()
            -- elseif i == BtnType.JoinMatch then
            --     self:OnClickJoinMatchBtn()
            -- elseif i == BtnType.PermissionSetting then
            --     self:OnClickPermissionSettingBtn()
            -- elseif i == BtnType.StorageFurniture then
            --     self:OnClickStorageFurnitureBtn()
            end

            -- TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetConstructOperTip)
            -- Event.Dispatch(EventType.HideAllHoverTips)
        end)

        -- UIHelper.SetTouchDownHideTips(btn, false)
    end
end

function UIHomelandBuildEntranceTip:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function(nRetCode)
        if nRetCode == HOMELAND_RESULT_CODE.APPLY_HLLAND_INFO then
            local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
            local dwCurrMapID, nCurrCopyIndex, nCurrLandIndex = HomelandBuildData.GetMapInfo()
            if dwCurrMapID == dwMapID and nCurrCopyIndex == nCopyIndex and nCurrLandIndex == nLandIndex then
                self:UpdateInfo()
            end
        end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE", function()
		local nRetCode = arg0
		if nRetCode == HOMELAND_RESULT_CODE.APPLY_ESTATE_SUCCEED then
			local hPlayer = GetClientPlayer()
			local hScene = hPlayer.GetScene()
			if hScene.nType == MAP_TYPE.HOMELAND then
                self:Init()
			end
		end
    end)

    Event.Reg(self, "LOADING_END", function ()
        self:CreatBuildCD(LOADING_END_CD)
    end)

    Event.Reg(self, EventType.OnHomelandAddBuildCD, function()
        self:CreatBuildCD()
    end)
end

function UIHomelandBuildEntranceTip:Init()
    local pHLMgr = GetHomelandMgr()
    if not pHLMgr then
        return
    end

    local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()

    if nLandIndex then
        pHLMgr.ApplyHLLandInfo(nLandIndex)

        if dwMapID and nCopyIndex then
	        pHLMgr.ApplyLandInfo(dwMapID, nCopyIndex, nLandIndex)
        end

        pHLMgr.ApplyMyLandInfo(nLandIndex)
        LOG.INFO("-----------------------pHLMgr.ApplyMyLandInfo-----------------------nLandIndex:%d", nLandIndex)
    end
end

function UIHomelandBuildEntranceTip:UpdateInfo()
    self:UpdateBtnState()
end

function UIHomelandBuildEntranceTip:UpdateBtnState()
    self:UpdateVistorMode()
    -- UIHelper.SetVisible(self.tbBtns[BtnType.JoinMatch], false)
    UIHelper.LayoutDoLayout(self.LayoutMoreOper)
end

function UIHomelandBuildEntranceTip:UpdateHomelandInfo()
    local nLevel, bShowLevel
    local _, _, nCurrLandIndex = HomelandBuildData.GetMapInfo()

    if nCurrLandIndex and GetHomelandMgr then
        local tHLLandInfo = GetHomelandMgr().GetHLLandInfo(nCurrLandIndex)
        if tHLLandInfo and tHLLandInfo.dwOwnerID > 0 then
            nLevel = tHLLandInfo.nLevel
            bShowLevel = true
        end
    end

    local szContent = ""
    if nLevel then
        szContent = nLevel.."级"
    end
    UIHelper.SetString(self.LabelLevel, szContent)
    UIHelper.SetVisible(self.ImgLevel, bShowLevel)
    if table.contain_value(self.tbBtnShowFliter, BtnType.UpgradeHome) then
        UIHelper.SetVisible(self.tbBtns[BtnType.UpgradeHome], nLevel and nLevel < MAX_LAND_LEVEL)
        UIHelper.SetVisible(self.tbBtns[BtnType.FlowerPrice], not UIHelper.GetVisible(self.tbBtns[BtnType.UpgradeHome]))
        UIHelper.LayoutDoLayout(self.LayoutMoreOper)
    end
end

function UIHomelandBuildEntranceTip:OnClickOverviewBtn()
    UIMgr.CloseAllInLayer("UIPageLayer")
    UIMgr.CloseAllInLayer("UIPopupLayer")

    UIMgr.Open(VIEW_ID.PanelHomeOverview)
end

function UIHomelandBuildEntranceTip:OnClickStartBuildBtn()
    if UIMgr.GetView(VIEW_ID.PanelCamera) then
        return
    end

    local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
    local bMyLand = HomelandBuildData.CheckIsMyLand(dwMapID, nCopyIndex, nLandIndex)
    local bUnLock = HomelandBuildData.CheckMyLandIsUnLock(dwMapID, nCopyIndex, nLandIndex)
    if bMyLand and bUnLock then
        if HomelandData.IsPrivateHome(dwMapID) then
            HLBOp_Main.Enter(BUILD_MODE.PRIVATE)
        else
            if not GetHomelandMgr().IsHLLandHaveHouse(nLandIndex) then
                local szMsg = g_tStrings.tHomelandBuildingFailureNotify[HOMELAND_RESULT_CODE.NO_HOUSE]
                OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
                OutputMessage("MSG_SYS", szMsg .. "\n")
                return
            end
            HLBOp_Main.Enter(BUILD_MODE.COMMUNITY)
        end
    end
end

function UIHomelandBuildEntranceTip:OnClickInteractBtn()
    local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
    local bMaster = HomelandData.CheckIsMyPriviteHome() or HomelandData.CheckIsMyCommunityHome()
    UIMgr.Open(VIEW_ID.PanelItemInteractionList, nLandIndex, not bMaster, HomelandData.IsPrivateHome(dwMapID))
end

function UIHomelandBuildEntranceTip:OnClickCallHousekeepBtn()
    if not self.bSummon then
        self.bSummon = true
        RemoteCallToServer("On_NPCServant_CallServant")

        Timer.Add(self, 1, function ()
            self.bSummon = false
        end)
    end
end

function UIHomelandBuildEntranceTip:OnClickJoinMatchBtn()
    UIMgr.Open(VIEW_ID.PanelHomeContestJoinPop)
end

function UIHomelandBuildEntranceTip:OnClickPermissionSettingBtn()
    UIMgr.Open(VIEW_ID.PanelHomeAuthoritySettingPop)
end

function UIHomelandBuildEntranceTip:OnClickUpgradeHomeBtn()
    UIMgr.Open(VIEW_ID.PanelHomeUpgradePop)
end

function UIHomelandBuildEntranceTip:OnClickStorageFurnitureBtn()
    UIMgr.Open(VIEW_ID.PanelFurnitureStoragePop)
end

function UIHomelandBuildEntranceTip:OnClickUnlockAreaBtn()
    UIMgr.Open(VIEW_ID.PanelZoneUnlock)
end

function UIHomelandBuildEntranceTip:OnClickChangeSkinBtn()
    UIMgr.Open(VIEW_ID.PanelPreviewHome)
end

function UIHomelandBuildEntranceTip:OnClickFlowerPriceBtn()
    UIMgr.Open(VIEW_ID.PanelFlowerPrice)
end

function UIHomelandBuildEntranceTip:OnClickHomeOrderBtn()
    local dwOwnerID = PlayerData.GetPlayerID()
    local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
    if nLandIndex > 0 then
        local tLandInfo = GetHomelandMgr().GetHLLandInfo(nLandIndex)
        if tLandInfo then
            dwOwnerID = tLandInfo.dwOwnerID
        end
    end
    HomelandIdentity.OpenPanelHomeOrder(dwOwnerID)
end

function UIHomelandBuildEntranceTip:OnClickMessageBoardBtn()
    local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
    UIMgr.Open(VIEW_ID.PanelMessageBoard, dwMapID, nCopyIndex, nLandIndex)
end

function UIHomelandBuildEntranceTip:CreatBuildCD(nCDTime)
    UIHelper.SetVisible(self.WidgetCD, true)
    nCDTime = nCDTime or HLBOp_Save.GetReEnterCD()
    if self.nBulidCDTimerID then
        Timer.DelTimer(self, self.nBulidCDTimerID)  --多次接受cd的事件时重新计算
        self.nBulidCDTimerID = nil
    end

    self.bInBulidCD = true
    UIHelper.SetButtonState(self.tbBtns[BtnType.StartBuild], BTN_STATE.Disable)
    UIHelper.SetButtonState(self.tbBtns[BtnType.Interact], BTN_STATE.Disable)

    UIHelper.SetString(self.LabelCD, "冷却"..tostring(nCDTime).."秒")
    self.nBulidCDTimerID = Timer.AddCycle(self, 1, function ()
        nCDTime = nCDTime - 1
        UIHelper.SetString(self.LabelCD, "冷却"..tostring(nCDTime).."秒")
        if nCDTime < 0 then
            self.bInBulidCD = false

            UIHelper.SetButtonState(self.tbBtns[BtnType.StartBuild], BTN_STATE.Normal)
            UIHelper.SetButtonState(self.tbBtns[BtnType.Interact], BTN_STATE.Normal)

            UIHelper.SetVisible(self.WidgetCD, false)
            Timer.DelTimer(self, self.nBulidCDTimerID)
            self.nBulidCDTimerID = nil
        end
    end)
end

function UIHomelandBuildEntranceTip:UpdateVistorMode()
    local pHlMgr = GetHomelandMgr()
    local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
	local tLandInfo = pHlMgr.GetHLLandInfo(nLandIndex) or {}

    local nShowType = HOMELAND_CONSTRUCT_TYPE.HOLDER
	local bIsHouseOwner = tLandInfo.dwOwnerID == GetClientPlayer().dwID
    local bIsMyLand = pHlMgr.IsMyLand(dwMapID, nCopyIndex, nLandIndex)

    if bIsHouseOwner and bIsMyLand then
        nShowType = HOMELAND_CONSTRUCT_TYPE.HOLDER
    elseif not bIsHouseOwner and bIsMyLand then
        nShowType = HOMELAND_CONSTRUCT_TYPE.COHABIT
    elseif nLandIndex > 0 and tLandInfo.dwOwnerID and tLandInfo.dwOwnerID > 0 then
        nShowType = HOMELAND_CONSTRUCT_TYPE.VISTOR
    else
        nShowType = HOMELAND_CONSTRUCT_TYPE.WANDER
    end

    self.tbBtnShowFliter = tbBtnShowMode[nShowType]
    for index, btn in ipairs(self.tbBtns) do
        UIHelper.SetVisible(btn, table.contain_value(self.tbBtnShowFliter, index))
    end
    self:UpdateHomelandInfo()
    self:UpdateOverviewBtnState(nShowType)
    self:UpdatePrivateHomeState(nShowType)
end

function UIHomelandBuildEntranceTip:UpdateOverviewBtnState(nShowType)
    UIHelper.SetVisible(self.WidgetSumUp, false)
    UIHelper.SetVisible(self.WidgetGuestCoLive, false)
    if nShowType == HOMELAND_CONSTRUCT_TYPE.WANDER or nShowType == HOMELAND_CONSTRUCT_TYPE.HOLDER then
        UIHelper.SetEnable(self.tbBtns[BtnType.Overview], true)
        UIHelper.SetVisible(self.WidgetSumUp, true)
        return
    end

    UIHelper.SetEnable(self.tbBtns[BtnType.Overview], false)
    UIHelper.SetVisible(self.WidgetGuestCoLive, true)
    if nShowType == HOMELAND_CONSTRUCT_TYPE.COHABIT then
        UIHelper.SetString(self.LabelGuestCoLive, "共居")
    elseif nShowType == HOMELAND_CONSTRUCT_TYPE.VISTOR then
        UIHelper.SetString(self.LabelGuestCoLive, "访客")
    end
end

function UIHomelandBuildEntranceTip:UpdatePrivateHomeState(nShowType)
	local scene = GetClientScene()
    local dwMapID = scene.dwMapID

    if HomelandData.IsPrivateHome(dwMapID) and nShowType == HOMELAND_CONSTRUCT_TYPE.HOLDER then
        UIHelper.SetVisible(self.tbBtns[BtnType.UnlockArea], true)
        UIHelper.SetVisible(self.tbBtns[BtnType.ChangeSkin], true)
    else
        UIHelper.SetVisible(self.tbBtns[BtnType.UnlockArea], false)
        UIHelper.SetVisible(self.tbBtns[BtnType.ChangeSkin], false)
    end
end

return UIHomelandBuildEntranceTip