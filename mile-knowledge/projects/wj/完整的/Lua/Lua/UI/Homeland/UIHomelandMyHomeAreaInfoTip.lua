-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeAreaInfoTip
-- Date: 2023-03-30 19:23:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeAreaInfoTip = class("UIHomelandMyHomeAreaInfoTip")
function UIHomelandMyHomeAreaInfoTip:OnEnter(nMapID, nCopyIndex, dwSkinID, nLandIndex, nAreaIndex)
    self.nMapID = nMapID
    self.nCopyIndex = nCopyIndex
    self.dwSkinID = dwSkinID
    self.nLandIndex = nLandIndex
    self.nAreaIndex = nAreaIndex

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandMyHomeAreaInfoTip:OnExit()
    self.bInit = false
end

function UIHomelandMyHomeAreaInfoTip:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnUnLock, EventType.OnClick, function ()
        local tbAreaInfo = Table_GetPrivateHomeArea(self.nMapID, self.nLandIndex, self.nAreaIndex)
        if not tbAreaInfo then
            return
        end

        local fnUnlock = function ()
            local pHLMgr = GetHomelandMgr()
            if not pHLMgr then
                return
            end
            local nEventID = 2
            local nLandID = self.nLandIndex
            local nSubLand = self.nAreaIndex
            pHLMgr.SendCustomEvent(nEventID, nLandID, nSubLand)
        end

        if tbAreaInfo["nMoney"] == 0 or GDAPI_Homeland_FreeUnlockArea() then
            fnUnlock()
        else
            if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
                return
            end
            local szMoneyText = UIHelper.GetFundText(tbAreaInfo["nMoney"], 26, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin")
            local szTip = string.format(g_tStrings.STR_PRIVATE_HOME_AREA_UNLOCK, szMoneyText, self.nAreaIndex)
            UIHelper.ShowConfirm(szTip, fnUnlock, nil, true)
        end
    end)

    UIHelper.BindUIEvent(self.BtnHome, EventType.OnClick, function ()
        local nMapID = self.nMapID
        local nCopyIndex = self.nCopyIndex
        local dwSkinID = self.dwSkinID

        local function _goPrivateLand()
            HomelandData.GoPrivateLand(nMapID, nCopyIndex, dwSkinID, 1)
            UIMgr.Close(VIEW_ID.PanelHome)
            UIMgr.Close(VIEW_ID.PanelSystemMenu)
        end
        if PakDownloadMgr.UserCheckDownloadHomelandRes(nMapID, dwSkinID, _goPrivateLand) then
            _goPrivateLand()
        end
    end)

    UIHelper.BindUIEvent(self.BtnTeleport, EventType.OnClick, function ()
        local nMapID = self.nMapID
        local nCopyIndex = self.nCopyIndex
        local dwSkinID = self.dwSkinID
        local nLandIndex = self.nLandIndex
        local nAreaIndex = self.nAreaIndex

        local function _goPrivateLand()
            HomelandData.GoPrivateLand(nMapID, nCopyIndex, dwSkinID, 1, nLandIndex, nAreaIndex)
            UIMgr.Close(VIEW_ID.PanelHome)
            UIMgr.Close(VIEW_ID.PanelSystemMenu)
        end
        if PakDownloadMgr.UserCheckDownloadHomelandRes(nMapID, dwSkinID, _goPrivateLand) then
            _goPrivateLand()
        end
    end)

    UIHelper.SetTouchDownHideTips(self.BtnHome, false)
    UIHelper.SetTouchDownHideTips(self.BtnTeleport, false)

end

function UIHomelandMyHomeAreaInfoTip:RegEvent()
    Event.Reg(self, "Home_OnGetPSubLandCons", function(tConditions, dwMapID)
        if self.nAreaIndex then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function()
        local nRetCode = arg0
        if nRetCode == HOMELAND_RESULT_CODE.APPLY_HLLAND_INFO or nRetCode == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then  --申请某块地详情
			local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
			if self.nMapID == dwMapID and self.nCopyIndex == nCopyIndex and self.nLandIndex == nLandIndex then
				self:UpdateInfo()
			end
		elseif nRetCode == HOMELAND_RESULT_CODE.SET_SUB_LAND_UNLOCK_SUCCEED then
			local pHLMgr = GetHomelandMgr()
			if not pHLMgr then
				return
			end
			pHLMgr.ApplyHLLandInfo(self.nLandIndex)
            TipsHelper.ShowNormalTip("分区解锁成功")
		end
    end)
end

function UIHomelandMyHomeAreaInfoTip:UpdateInfo()
    local tbAreaInfo = Table_GetPrivateHomeArea(self.nMapID, self.nLandIndex, self.nAreaIndex)
    local tbSkinInfo = Table_GetPrivateHomeSkin(self.nMapID, self.dwSkinID)

	local player = GetClientPlayer()
    local uUnlockSubLand = 0
	local uDemolishSubLand = 0
	local tbDecorateValue = {0,0,0,0,0}
    local bNotOwn = true

    local tbLandInfo = GetHomelandMgr().GetLandInfo(self.nMapID, self.nCopyIndex, self.nLandIndex)
    if tbLandInfo then
        uUnlockSubLand = tbLandInfo.uUnlockSubLand or 0
        uDemolishSubLand = tbLandInfo.uDemolishSubLand or 0

        for i = 1, 5 do
            tbDecorateValue[i] = tbLandInfo["dwDecorateInfo"..i] or 0
        end
    end

    local tbPrivateInfo = GetHomelandMgr().GetPrivateHomeInfo(self.nMapID, self.nCopyIndex)
    if tbPrivateInfo then
        bNotOwn = false
    end

    local bNotDemolish = not kmath.is_bit1(uDemolishSubLand, self.nAreaIndex)
    local bLocked = not kmath.is_bit1(uUnlockSubLand, self.nAreaIndex)

    UIHelper.SetString(self.LabelMyHomeTitle, string.format("%s·%d区", UIHelper.GBKToUTF8(tbSkinInfo.szLandName), self.nAreaIndex))
    UIHelper.SetRichText(self.LabelTextInfo, string.format("<color=#AED9E0>面积：</c><color=#ffffff>%d平米</color>", tbAreaInfo.nArea))

    UIHelper.SetVisible(self.RichTextCondition, false)
    UIHelper.SetVisible(self.WidgetUnLock, false)
    UIHelper.SetVisible(self.BtnTeleport, false)
    UIHelper.SetVisible(self.BtnHome, false)
    if bNotOwn then
        UIHelper.SetRichText(self.RichTextInfo, "<color=#AED9E0>状态：</c><color=#ff9393>未拥有</c>")
    elseif bLocked then
        UIHelper.SetVisible(self.WidgetUnLock, true)
        UIHelper.SetVisible(self.RichTextCondition, true)
        UIHelper.SetRichText(self.RichTextInfo, "<color=#AED9E0>状态：</c><color=#ff9393>未解锁</c>")
        local bCanUnlock = true
        local szMsg
        local szTip = g_tStrings.STR_PRIVATEHOUSE_UNLOCKTIP

        local pPlayer = GetClientPlayer()
        local nRecord = pPlayer.GetHomelandRecord()
        if nRecord >= tbAreaInfo["nLockScore"] then
            szTip = szTip .. string.format("<color=#6dbf98>%s</c>", FormatString(g_tStrings.STR_PRIVATEHOUSE_UNLOCK_SCORE, nRecord, tbAreaInfo["nLockScore"]))
        else
            szTip = szTip .. string.format("<color=#ff9393>%s</c>", FormatString(g_tStrings.STR_PRIVATEHOUSE_UNLOCK_SCORE, nRecord, tbAreaInfo["nLockScore"]))
            bCanUnlock = false
            szMsg = "解锁条件未达成"
        end

        local tbConditions = PrivateHomeData.GetPSubLandCondition(self.nMapID)
        if tbConditions then
            local tCons = tbConditions[self.nLandIndex][self.nAreaIndex]
            if tCons then
                for i, tCon in ipairs(tCons) do
                    if tCon.bCan then
                        szTip = szTip .. string.format("<color=#6dbf98>%s</c>\n", g_tStrings.STR_HOMELAND_UNLOCK_CONDITION[tCon.nStrIndex])
                    else
                        szTip = szTip .. string.format("<color=#ff9393>%s</c>\n", g_tStrings.STR_HOMELAND_UNLOCK_CONDITION[tCon.nStrIndex])
                        bCanUnlock = false
                        szMsg = "解锁条件未达成"
                    end
                end
            end
        end

        local bShowMoney = true
        if tbAreaInfo["nMoney"] == 0 or GDAPI_Homeland_FreeUnlockArea() then
            bShowMoney = false
        end

        if bShowMoney then
            local tbMyMoney = ItemData.GetMoney()
            local nMyMoney = UIHelper.BullionGoldSilverAndCopperToMoney(tbMyMoney.nBullion, tbMyMoney.nGold, tbMyMoney.nSilver, tbMyMoney.nCopper)
            local szMoney = UIHelper.GetFundText(tbAreaInfo["nMoney"], 26, "UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin")
            if tbAreaInfo["nMoney"] * 10000 > nMyMoney then
                szTip = szTip .. string.format("<color=#ff9393>%s</c>\n", g_tStrings.STR_HOMELAND_UNLOCK_MONEY..szMoney)
                bCanUnlock = false
                szMsg = "解锁条件未达成"
            else
                szTip = szTip .. string.format("<color=#6dbf98>%s</c>\n", g_tStrings.STR_HOMELAND_UNLOCK_MONEY..szMoney)
            end
        else
            szTip = szTip .. string.format("<color=#6dbf98>%s</c>\n", g_tStrings.STR_HOMELAND_UNLOCK_MONEY..g_tStrings.STR_MENTOR_TRANSFORM)
        end

        UIHelper.SetRichText(self.RichTextCondition, szTip)

        local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
        if dwMapID ~= self.nMapID or nCopyIndex ~= self.nCopyIndex then
            bCanUnlock = false
            szMsg = "请位于家园内进行解锁"
        end

        if bCanUnlock then
            UIHelper.SetButtonState(self.BtnUnLock, BTN_STATE.Normal)
        else
            UIHelper.SetButtonState(self.BtnUnLock, BTN_STATE.Disable, szMsg)
        end

    elseif bNotDemolish then
        UIHelper.SetRichText(self.RichTextInfo, "<color=#AED9E0>状态：</c><color=#eebf58>未铲平（铲平后方可建造）</c>")
    else
        UIHelper.SetRichText(self.RichTextInfo, "<color=#AED9E0>状态：</c><color=#6dbf98>建造中</c>")
    end

    if not bNotOwn then
        local dwMapID, nCopyIndex, nLandIndex = HomelandBuildData.GetMapInfo()
        if dwMapID ~= self.nMapID or nCopyIndex ~= self.nCopyIndex then
            UIHelper.SetVisible(self.BtnHome, true)
        else
            UIHelper.SetVisible(self.BtnTeleport, true)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutHomeBtn)
end


return UIHomelandMyHomeAreaInfoTip