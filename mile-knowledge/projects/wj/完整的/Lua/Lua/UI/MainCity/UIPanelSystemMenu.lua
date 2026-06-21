
-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIPanelSystemMenu
-- Date: 2022-11-15
-- Desc: 系统菜单
-- Prefab: PanelSystemMenu
-- ---------------------------------------------------------------------------------

---@class UIPanelSystemMenu
local UIPanelSystemMenu = class("UIPanelSystemMenu")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPanelSystemMenu:_LuaBindList()
    self.BtnAccountsUnlock  = self.BtnAccountsUnlock --- 密保锁按钮
    self.imgLock            = self.imgLock --- 锁定
    self.imgLockOpen        = self.imgLockOpen --- 已解锁
    self.WidgetDots         = self.WidgetDots --- 玲珑密保锁的解锁数目的上层节点
    self.tLockStatusDotList = self.tLockStatusDotList --- 玲珑密保锁的解锁数目小点标记列表
end

function UIPanelSystemMenu:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
		self.szGlobalID = g_pClientPlayer.GetGlobalID()
	end

	self:UpdateInfo()
end

function UIPanelSystemMenu:OnExit()
	self.bInit = false
	self:UnRegEvent()
	self:_clearRedPoint()
end

function UIPanelSystemMenu:BindUIEvent()
	--二级菜单(自定义头像 名帖)
	UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, function()
		local tbBtnInfo = {
			{
				["OnClick"] = function ()
					UIMgr.Open(VIEW_ID.PanelWithdrawMoneyPop)
				end,
				["szName"] = "创作者提现"
			},
			{
				["OnClick"] = function ()
					TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
					local tbSelectInfo =
					{
						nSelectIndex = 1,
						tbParams = {}
					}
					UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.FeeBug, tbSelectInfo , 1)
				end,
				["szName"] = "反馈BUG"
			},
			{
				["OnClick"] = function ()
					TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
					UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.EquipmentFound, {} , 1)
				end,
				["szName"] = "装备找回"
			},
			{
				["OnClick"] = function ()
					TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
					UIMgr.Open(VIEW_ID.PanelChangeNamePop)
				end,
				["szName"] = "角色改名"
			},
			{
				["OnClick"] = function ()
					TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
					UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.AccountSafe, {} , 1)
				end,
				["szName"] = "账号安全"
			},
			{
				["OnClick"] = function ()
					TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
					UIMgr.Open(VIEW_ID.PanelKeyExchangePop)
				end,
				["szName"] = "激活码兑换"
			},
            {
                ["OnClick"] = function ()
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
                    UIMgr.Open(VIEW_ID.PanelShieldPop)
                end,
                ["szName"] = "勿扰选项"
            },
			{
				["OnClick"] = function ()
					TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipMoreOper)
					UIMgr.Open(VIEW_ID.PanelPlayerReputationPop, self.tbReputationInfo)
				end,
				["szName"] = "查看信誉"
			},
		}

		local nX,nY = UIHelper.GetWorldPosition(self.BtnHead)
		local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnHead)
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper,nX-nSizeW-266,nY+nSizeH-50*(#tbBtnInfo-3))
        scriptTips:OnEnter(tbBtnInfo)
    end)

	UIHelper.BindUIEvent(self.BtnHead, EventType.OnClick, function()
		if not g_pClientPlayer then
			return
		end

		local uGlobalID = g_pClientPlayer.GetGlobalID()
		local tips, scriptPC = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPersonalCard, self.BtnHead, TipsLayoutDir.LEFT_CENTER, uGlobalID)
        if scriptPC then
			--scriptPC:OnEnter(uGlobalID)
			scriptPC:ShowOwnBtn(true)
			local x, y = UIHelper.GetPosition(scriptPC._rootNode)
			local w, h = UIHelper.GetContentSize(scriptPC._rootNode)
			UIHelper.SetScale(scriptPC._rootNode, 1.2, 1.2)
			UIHelper.SetVisible(scriptPC.ImgPersonalCardNewBg, true)
			UIHelper.SetVisible(scriptPC._rootNode, true)

			UIHelper.SetPosition(scriptPC._rootNode, x - 0.2 * w, y - 0.2 * h)
		end
	end)

	-- 账号解锁
    UIHelper.BindUIEvent(self.BtnAccountsUnlock, EventType.OnClick, function()
        BankLock.OpenCurrentStateView()
    end)


	UIHelper.BindUIEvent(self.BtnBg, EventType.OnClick, function()
		if self.bIsPanelHide then
			return
		end

		if UIMgr.GetView(VIEW_ID.PanelHalfBag) then
			return
		end

		if UIMgr.GetView(VIEW_ID.PanelCustomAvatar) then
			return
		end

		UIMgr.Close(self)
	end)

	-- 背包
	UIHelper.BindUIEvent(self.BtnBag, EventType.OnClick, function()
		ItemData.OpenBag()
	end)

	-- 邮件
	UIHelper.BindUIEvent(self.BtnMail, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelEmail)
	end)

	-- 退出账号
	UIHelper.BindUIEvent(self.BtnQuit, EventType.OnClick, function()
		local dialog = UIHelper.ShowConfirm("可选择返回到角色界面或者登录界面", function()
			--返回角色
			if GetClientPlayer().bFightState then
				OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.OPTION_RETURNCHOOSE_NOT_IN_FIGHT)
			else
				Global.BackToLogin(true)
			end
		end, function()
		end)

		dialog:ShowOtherButton()
		dialog:SetOtherButtonClickedCallback(function()
			--返回登陆
			if GetClientPlayer().bFightState then
				OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.OPTION_RETURNCHOOSE_NOT_IN_FIGHT)
			else
				Global.BackToLogin(false)
			end
		end)

		dialog:SetConfirmButtonContent("返回角色")
		dialog:SetCancelButtonContent("取消")
		dialog:SetOtherButtonContent("返回登录")
	end)

	-- 返回角色列表
	UIHelper.BindUIEvent(self.BtnBackCharacter, EventType.OnClick, function()
		if GetClientPlayer().bFightState then
			OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.OPTION_RETURNCHOOSE_NOT_IN_FIGHT)
		else
			local szContent = g_tStrings.EXIT_RETURN_CHOOSE
			UIHelper.ShowConfirm(szContent, function()
				Global.BackToLogin(true)
			end)
		end
	end)

	-- 设置
	UIHelper.BindUIEvent(self.BtnSet, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelGameSettings)
	end)

	-- 客服
	UIHelper.BindUIEvent(self.BtnService, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelTutorialCollection)
	end)

	-- 公告
	UIHelper.BindUIEvent(self.BtnBulletin, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelUpdateAbroad)
	end)

	-- 推送
	UIHelper.BindUIEvent(self.BtnPush, EventType.OnClick, function()

	end)

	UIHelper.BindUIEvent(self.BtnPhoto, EventType.OnClick, function()
		if IsInLishijie() then
			return OutputMessage("MSG_ANNOUNCE_NORMAL", "当前状态无法拍照")
		end
		UIMgr.Open(VIEW_ID.PanelCamera)
	end)

	UIHelper.BindUIEvent(self.ScrollViewSystem, EventType.OnChangeSliderPercent, function (_, eventType)
		if eventType == ccui.ScrollviewEventType.containerMoved then
			self:UpdateRedPointArrow()
		end
	end)

	UIHelper.BindUIEvent(self.BtnWanBaoLou, EventType.OnClick, function()
		--if Config.bIsCEVer then
		--	TipsHelper.ShowNormalTip(g_tStrings.WAIT_FOR_OPEN_TIPS)
		--	return
		--end
		if SystemOpen.IsSystemOpen(SystemOpenDef.WanBaoLou,	true) then
			local bUseInsideWeb = Channel.IsCloud()
			local bPortrait = Channel.IsCloud()
			WebUrl.OpenByID(WEBURL_ID.WAN_BAO_LOU, bUseInsideWeb, bPortrait)
		end
	end)

	UIHelper.BindUIEvent(self.BtnPersonalCard, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelPersonalCard)
	end)

	UIHelper.BindUIEvent(self.BtnServiceOnline, EventType.OnClick, function()
		ServiceCenterData.OpenServiceWeb()
	end)

	UIHelper.BindUIEvent(self.BtnChangeHead, EventType.OnClick, function()
		-- UIMgr.Open(VIEW_ID.PanelCustomAvatar)
		if UIMgr.IsViewOpened(VIEW_ID.PanelCharacter) then
            UIMgr.Open(VIEW_ID.PanelAccessory, nil,  4)
        else
            UIMgr.Open(VIEW_ID.PanelCharacter)
            UIMgr.Open(VIEW_ID.PanelAccessory, true,  4)
        end
	end)

	UIHelper.BindUIEvent(self.BtnChangeMingtie, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelNameCard)
	end)

	UIHelper.BindUIEvent(self.BtnChongZhi, EventType.OnClick, function()
		UIMgr.Open(VIEW_ID.PanelTopUpMain)
	end)

	UIHelper.BindUIEvent(self.BtnJiaoYi, EventType.OnClick, function()
		TradingData.InitTradingHouse()
	end)
end

function UIPanelSystemMenu:RegEvent()
	Event.Reg(self, EventType.OnSetSystemMenuCloseBtnEnabled, function(bEnabled)
		--UIHelper.SetVisible(self.BtnBg, bEnabled)
	end)

	--头像
	Event.Reg(self, "SET_MINI_AVATAR", function (dwID)
		if dwID == g_pClientPlayer.dwMiniAvatarID then
			local szImage, nImgFrame, szSfx = Table_GetRoleavatar(g_pClientPlayer.dwMiniAvatarID, g_pClientPlayer.nRoleType)
			UIHelper.SetVisible(self.WidegetSFXPlayerIcon, (nImgFrame ~= -1 or (szImage == "" and dwID ~= 0)) and szSfx ~= "" )
			UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon,dwID,self.SFXPlayerIcon, self.AnimatePlayerIcon,g_pClientPlayer.nRoleType, g_pClientPlayer.dwForceID, true)
		end
    end)

	--名帖
	Event.Reg(self,"SET_CARD_SKIN",function ()
		local aCard = FellowshipData.GetRoleEntryInfo(self.szGlobalID)
		local tLine = UINameCardTab[aCard.nSkinID]
		if tLine then
			UIHelper.SetTexture(self.ImgNameCard,tLine.szVisitCardPath, true, function ()
				UIHelper.UpdateMask(self.MaskNameCard)
			end)
			UIHelper.UpdateMask(self.MaskNameCard)
		end
    end)

	--信誉分
	Event.Reg(self, EventType.OnGetPrestigeInfoRespond, function(dwPlayerID, tbInfo)
		if dwPlayerID == g_pClientPlayer.dwID then
			self.tbReputationInfo = tbInfo
		end
    end)

	Event.Reg(self, "BANK_LOCK_RESPOND", function(szResult, nCode)
        if szResult == "SECURITY_VERIFY_PASSWORD_SUCCESS" or szResult == "VERIFY_BANK_PASSWORD_SUCCESS" or szResult == "SECURITY_BIND_DEVICE_VERIFY_PASSWORD_SUCCESS" then
            self:UpdateLockInfo()
        end
    end)

	Event.Reg(self, "UPDATE_MAIL_READ_FLAG", function()
		self:UpdateMailRedPoint()
    end)

	Event.Reg(self, "MAIL_LIST_UPDATE", function()
		self:UpdateMailRedPoint()
	end)

	Event.Reg(self, EventType.OnWindowsSizeChanged, function()
		Timer.AddFrame(self,5,function()
			UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSystem)
			self.bNeedUpdateWidget = true
			self:CalcScrollPosY()
			self:UpdateRedPointArrow()
		end)
    end)

	Event.Reg(self, EventType.OnViewMutexPlayHideAnimFinish, function(nViewID)
		if nViewID == self._nViewID then
			UIHelper.SetVisible(self.BtnHead, false)
		end
	end)

	Event.Reg(self, EventType.OnViewMutexPlayShowAnimBegin, function(nViewID)
		if nViewID == self._nViewID then
			UIHelper.SetVisible(self.BtnHead, true)
		end
	end)

	Event.Reg(self, "SCENE_BEGIN_LOAD", function()
        UIMgr.Close(self)
    end)

	Event.Reg(self, EventType.HideAllHoverTips, function()
		if self.personalCardScript then
			UIHelper.SetVisible(self.personalCardScript._rootNode, false)
		end
    end)
end

function UIPanelSystemMenu:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPanelSystemMenu:Close()
	UIMgr.Close(self)
end

function UIPanelSystemMenu:UpdateInfo()
	RemoteCallToServer("On_XinYu_GetInfo", g_pClientPlayer.dwID)
    TongData.TryGetApplyJoinInList()

	self:UpdatePlayerInfo()
	self:UpdateListNew()

	self:CalcScrollPosY()
	self:UpdateMailRedPoint()
	self:UpdateRedPointArrow()

	UIHelper.SetVisible(self.BtnMore, not AppReviewMgr.IsReview())
end

function UIPanelSystemMenu:UpdatePlayerInfo()
	local szImage, nImgFrame, szSfx = Table_GetRoleavatar(g_pClientPlayer.dwMiniAvatarID, g_pClientPlayer.nRoleType)
	UIHelper.SetVisible(self.WidegetSFXPlayerIcon, (nImgFrame ~= -1 or (szImage == "" and dwID ~= 0)) and szSfx ~= "" )
	UIHelper.RoleChange_UpdateAvatar(self.ImgPlayerIcon, g_pClientPlayer.dwMiniAvatarID, self.SFXPlayerIcon, self.AnimatePlayerIcon, g_pClientPlayer.nRoleType, g_pClientPlayer.dwForceID, true)

	UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(g_pClientPlayer.szName))
	UIHelper.SetSpriteFrame(self.ImgSchool, PlayerForceID2SchoolImg2[g_pClientPlayer.dwForceID])
	UIHelper.SetString(self.LabelLevel, g_pClientPlayer.nLevel)
	CampData.SetUICampImgByPlayer(self.ImgCamp, g_pClientPlayer, true)
	local szTongName = "无"
	if g_pClientPlayer and g_pClientPlayer.dwTongID ~= 0  then
		szTongName = UIHelper.GBKToUTF8(GetTongClient().ApplyGetTongName(g_pClientPlayer.dwTongID)) or "无"
	end
	UIHelper.SetString(self.LabelGroupName, "帮会："..szTongName)

	local aCard = FellowshipData.GetRoleEntryInfo(self.szGlobalID)
	local tLine = aCard and UINameCardTab[aCard.nSkinID]
	if tLine then
		UIHelper.SetTexture(self.ImgNameCard, tLine.szVisitCardPath, true, function ()
			UIHelper.UpdateMask(self.MaskNameCard)
		end)
		UIHelper.UpdateMask(self.MaskNameCard)
	end

    self:UpdateLockInfo()
end



function UIPanelSystemMenu:UpdateListNew()
	local function SortByGroup(tCell)
		local tSortCell = {}
		for _, v in ipairs(tCell) do
			if v.nGroupID ~= 0 then
				if not tSortCell[v.nGroupID] then
					tSortCell[v.nGroupID] = {}
				end
				if v.bIsDisplay then
					table.insert(tSortCell[v.nGroupID], v)
				end
			end
		end

		for _, t in ipairs(tSortCell) do
			table.sort(t, function(a,b)
				if a.nGroupIndex ~= b.nGroupIndex then
					return a.nGroupIndex < b.nGroupIndex
				else
					return a.nID < a.nID
				end
			end)
		end

		return tSortCell
	end

	self:_clearRedPoint()

	local tSortCell = SortByGroup(UISystemMenuTab)
	self.tbScriptMenu = {}
	for i, t in ipairs(tSortCell) do
		local list = self.LayoutGroup[i] assert(list)
		local widget = self.WidgetGroup[i]
		list:removeAllChildren()
		for _, v in ipairs(t) do
			local tOpenCfg = v.nSystemOpenID > 0 and SystemOpen.GetSystemOpenCfg(v.nSystemOpenID) or nil
			if not tOpenCfg or tOpenCfg.bIsDisplay or SystemOpen.IsSystemOpen(v.nSystemOpenID) then
				local tScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSystemMenuBtn, list) assert(tScript)
				self:UpdateCell(tScript, v, tOpenCfg)

				--设置名字，便于新手教学配置
				tScript._rootNode:setName("WidgetSystemMenuBtn_" .. v.nID)
				table.insert(self.tbScriptMenu, tScript)
			end
		end

		UIHelper.LayoutDoLayout(list)
		UIHelper.SetVisible(widget, true)
		if i == 3 then
			UIHelper.CascadeDoLayoutDoWidget(widget, true, true)
		end
	end

	for _, list in ipairs(self.LayoutGroup) do
		local nLastRowChildCount = UIHelper.GetChildrenCount(list) % 4
		if nLastRowChildCount > 0 and nLastRowChildCount < 4 then
			for i = 1, 4 - nLastRowChildCount do
				local tEmptyScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSystemMenuBtn, list)
				UIHelper.SetVisible(tEmptyScript.ImgEmpty, true)
				UIHelper.SetVisible(tEmptyScript.BtnSystem, false)
			end
			UIHelper.LayoutDoLayout(list)
		end
	end

	UIHelper.ScrollViewDoLayout(self.ScrollViewSystem)
	UIHelper.ScrollToTop(self.ScrollViewSystem, 0, false)
end

function UIPanelSystemMenu:UpdateCell(tScritp, tCell, tOpenCfg)
	-- event
	UIHelper.BindUIEvent(tScritp.BtnSystem, EventType.OnClick, function ()
		if tOpenCfg and not SystemOpen.IsSystemOpen(tOpenCfg.nID, true) then
			return
		end

		if not table.is_empty(tCell.tbCheckFunc) then
            for k, szCondition in ipairs(tCell.tbCheckFunc) do
                if not string.is_nil(szCondition) then
                    if not string.execute(szCondition) then
                        return
                    end
                end
            end
        end

		local szAction = tCell.szAction assert(szAction)
		string.execute(szAction)

		--local bCloseSelf = tCell.bCloseSelf
		--local bHideSelf = tCell.bHideSelf
	end)

	-- label
	UIHelper.SetString(tScritp.LabelName, tCell.szTitle)
	if tCell.tbFontColor and #tCell.tbFontColor == 4 then
		UIHelper.SetTextColor(tScritp.LabelName, cc.c4b(unpack(tCell.tbFontColor)))
	end

	-- icon
	UIHelper.SetSpriteFrame(tScritp.ImgBtnIcon, tCell.szIcon)

	-- 开启判断
	if tOpenCfg then
		local bIsSystemOpen = SystemOpen.IsSystemOpen(tOpenCfg.nID)
    	local szTitle = SystemOpen.GetSystemOpenTitle(tOpenCfg.nID)
		UIHelper.SetVisible(tScritp.Locked, not bIsSystemOpen)
		if UIHelper.GetVisible(tScritp.Locked) then
			UIHelper.SetString(tScritp.LabelLevel, szTitle or "")
		end

		-- 未开放就监听消息
		Event.Reg(tScritp, "NEW_ACHIEVEMENT")
        Event.Reg(tScritp, "PLAYER_LEVEL_UP")
        Event.Reg(tScritp, "QUEST_FINISHED")
		if not bIsSystemOpen then
			Event.Reg(tScritp, "NEW_ACHIEVEMENT", function() self:UpdateCell(tScritp, tCell, tOpenCfg) end)
			Event.Reg(tScritp, "PLAYER_LEVEL_UP", function() self:UpdateCell(tScritp, tCell, tOpenCfg) end)
			Event.Reg(tScritp, "QUEST_FINISHED", function() self:UpdateCell(tScritp, tCell, tOpenCfg) end)
		end
	else
		UIHelper.SetVisible(tScritp.Locked, false)
	end

	-- 底图
	if not string.is_nil(tCell.szImgBg) then
		UIHelper.SetSpriteFrame(tScritp.ImgBtnBg, tCell.szImgBg)
	end

	-- 红点
	if not table.is_empty(tCell.tbRedPointID) and SystemOpen.IsSystemOpen(tOpenCfg.nID) then
		local imgRedPoint = tCell.bUseNewRedPoint and tScritp.ImgNew or tScritp.ImgRedPoint
		RedpointMgr.RegisterRedpoint(imgRedPoint, nil, tCell.tbRedPointID)
	end

	UIHelper.SetSwallowTouches(tScritp.BtnSystem, false)
end

function UIPanelSystemMenu:PlayShow(callback)
	local bImmediately = self.bNeedUpdateWidget

	UIHelper.PlayAni(self, self.AniAll, "AniRightShow2", function()
		if IsFunction(callback) then callback() end
		self:WidgetFoceDoAlign()
	end, nil, bImmediately)

	if self._scriptBG then
		UIHelper.SetVisible(self._scriptBG._rootNode, true)
	end
	self.bIsPanelHide = false
end

function UIPanelSystemMenu:PlayHide(callback)
	local bImmediately = self.bNeedUpdateWidget

	UIHelper.PlayAni(self, self.AniAll, "AniRightHide2", function()
		if IsFunction(callback) then callback() end
		self:WidgetFoceDoAlign()
	end, nil, bImmediately)

	if self._scriptBG then
		UIHelper.SetVisible(self._scriptBG._rootNode, false)
	end

	if self.personalCardScript then
		UIHelper.SetVisible(self.personalCardScript._rootNode, false)
	end

	self.bIsPanelHide = true
end

function UIPanelSystemMenu:WidgetFoceDoAlign()
    if self.bNeedUpdateWidget then
        UIHelper.WidgetFoceDoAlign(self)
    end

    self.bNeedUpdateWidget = false
end

function UIPanelSystemMenu:CalcScrollPosY()
	local nWorldX, nWorldY = UIHelper.ConvertToWorldSpace(self.ScrollViewSystem, 0, 0)
	self.nScrollViewY = nWorldY
end

function UIPanelSystemMenu:HasRedPointBelow()
	local bHasRedPointBelow = false

	if not self.nScrollViewY then
		self:CalcScrollPosY()
	end

	for k, v in ipairs(self.tbScriptMenu) do
		if UIHelper.GetVisible(v.ImgRedPoint) then
			local nHeight = UIHelper.GetHeight(v.ImgRedPoint)
			local _nWorldX, _nWorldY = UIHelper.ConvertToWorldSpace(v.ImgRedPoint, 0, nHeight)
			if _nWorldY < self.nScrollViewY then
				bHasRedPointBelow = true
				break
			end
		end
	end
	return bHasRedPointBelow
end

function UIPanelSystemMenu:UpdateMailRedPoint()
	local unReadMail = GetMailClient().GetMailList("unread") or {}
    local nUnReadCount = #(unReadMail) or 0

	local szCount = ""
	if nUnReadCount > 0 then
		szCount = tostring(nUnReadCount)
		if nUnReadCount > 99 then
			szCount = "99"
		end
	end

	UIHelper.SetString(self.LabelRedPointMail, szCount)
	UIHelper.SetVisible(self.imgRedpointPlus, nUnReadCount > 99)
end

function UIPanelSystemMenu:UpdateRedPointArrow()
	local bHasRedPointBelow = self:HasRedPointBelow()
	UIHelper.SetActiveAndCache(self, self.ImgRedPointArrow, bHasRedPointBelow)
end

function UIPanelSystemMenu:_clearRedPoint()
	for k, v in ipairs(self.tbScriptMenu or {}) do
		RedpointMgr.UnRegisterRedpoint(v.ImgRedPoint)
		RedpointMgr.UnRegisterRedpoint(v.ImgNew)
	end
end

function UIPanelSystemMenu:UpdateLockInfo()
    local bLocked = BankLock.Lock_GetState() == "PASSWORD_LOCK"
    local bIsPhoneLock = BankLock.IsPhoneLock()

    UIHelper.SetVisible(self.imgLock, bLocked)
    UIHelper.SetVisible(self.imgLockOpen, not bLocked)

    UIHelper.SetVisible(self.WidgetDots, bIsPhoneLock)
    if bIsPhoneLock then
        local bBagTradeLocked = not BankLock.bBagAndTradeUnlocked
        local bBankLocked     = not g_pClientPlayer.bIsBankPasswordVerified
        local bTalkLocked     = BankLock.Lock_IsChoiceTypeLocked(SAFE_LOCK_EFFECT_TYPE.TALK)

        local nLockedCount = 0
        if bBagTradeLocked then
            nLockedCount = nLockedCount + 2
        end
        if bBankLocked then
            nLockedCount = nLockedCount + 1
        end
        if bTalkLocked then
            nLockedCount = nLockedCount + 1
        end

        for idx, uiLockStatusDot in ipairs(self.tLockStatusDotList) do
            UIHelper.SetVisible(uiLockStatusDot, idx > nLockedCount)
        end
    end
end

return UIPanelSystemMenu