-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerSettlementView
-- Date: 2023-08-16 17:14:56
-- Desc: 斗地主结算界面
-- ---------------------------------------------------------------------------------

local UIDdzPokerSettlementView = class("UIDdzPokerSettlementView")
function UIDdzPokerSettlementView:OnEnter(tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tData = tData
    self:UpdateInfo()
end

function UIDdzPokerSettlementView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerSettlementView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        UIMgr.Close(self)
    end)
end

function UIDdzPokerSettlementView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerSettlementView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDdzPokerSettlementView:UpdateInfo()
    local tFlagTable = {
        [1] = "bSuperDouble",
        [2] = "bIsSpring",
        [3] = "bIsMingPai",
    }
    local tTimesToFrame = {
        [2] = "UIAtlas2_Ddz_DdzMix_Poker2x",
        [3] = "UIAtlas2_Ddz_DdzMix_Poker3x",
        [4] = "UIAtlas2_Ddz_DdzMix_Poker4x",
    }
    if not self.script_SelfPlayer then
        self.script_SelfPlayer = UIHelper.AddPrefab(PREFAB_ID.WidgetPokerHead , self.WidgetPokerHeadMiddle)
    end
    if not self.script_LeftPlayer then
        self.script_LeftPlayer = UIHelper.AddPrefab(PREFAB_ID.WidgetPokerHead , self.WidgetPokerHeadLeft)
    end
    if not self.script_RightPlayer then
        self.script_RightPlayer = UIHelper.AddPrefab(PREFAB_ID.WidgetPokerHead , self.WidgetPokerHeadRight)
    end
    local tMyInfo = self.tData[DdzPokerData.tPlayerDirection.Down]
    self.script_SelfPlayer:UpdateSettlementHeadInfo(tMyInfo)
    
    for k, v in ipairs(tFlagTable) do
		if v == "bIsMingPai" then
			if tMyInfo.bIsMingPaiReady then
                UIHelper.SetSpriteFrame(self["ImgBgStatus0"..k] , tTimesToFrame[DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TIMES_MINGPAI_STATE_INIT]])
			else
                UIHelper.SetSpriteFrame(self["ImgBgStatus0"..k] , tTimesToFrame[DDZ_CONST_CAERDS_TIMES[DDZ_CONST_TABLE_STATE_SHUFFLE_MINGPAI]])
			end
		end
        UIHelper.SetVisible(self["WidgetFlag0"..k] , tMyInfo[v])
	end

    UIHelper.SetVisible(self.WidgetWinBg , tMyInfo.bIsWiner)
    UIHelper.SetVisible(self.WidgetDefeatBg , not tMyInfo.bIsWiner)
    self.script_LeftPlayer:UpdateSettlementHeadInfo(self.tData[DdzPokerData.tPlayerDirection.Left])
    self.script_RightPlayer:UpdateSettlementHeadInfo(self.tData[DdzPokerData.tPlayerDirection.Right])

    self:UpdateSkin()
end

function UIDdzPokerSettlementView:UpdateSkin()
	local szRootName = UIHelper.GetName(self._rootNode)
	local tbSkin = DdzPokerData.GetSettlementSkinInfo(szRootName, false)
	if tbSkin then
		for nIndex, tbInfo in ipairs(tbSkin) do
			local node = self._rootNode:getChildByName(tbInfo.szMobileNode)
			if safe_check(node) then
				UIHelper.SetSpriteFrame(node, tbInfo.szMobilePath)
			end
		end
	end

    local tbSkinSFX = DdzPokerData.GetSettlementSkinInfo(szRootName, true)
	if tbSkinSFX then
		for nIndex, tbInfo in ipairs(tbSkinSFX) do
			local node = self._rootNode:getChildByName(tbInfo.szMobileNode)
			if safe_check(node) then
				UIHelper.SetSFXPath(node, tbInfo.szMobilePath)
			end
		end
	end
end

return UIDdzPokerSettlementView