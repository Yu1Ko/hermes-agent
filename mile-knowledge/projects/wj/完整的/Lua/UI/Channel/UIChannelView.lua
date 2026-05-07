-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UIChannelView
-- Date: 2024-07-08 16:01:04
-- Desc: PanelQiXuePop
-- ---------------------------------------------------------------------------------
local UIChannelView = class("UIChannelView")

local QIXUE_SUM = 10
local QIXUE_CLICK_CD = 1000
local nFireAnimtionID = 10000
local nBlueLightAnimtionID = 10001

function UIChannelView:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	UIHelper.PlaySpriteFrameAnimtion(self.ImgQiXueFire, nFireAnimtionID)
	RemoteCallToServer("On_Channel_GetInfo")
end

function UIChannelView:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIChannelView:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
		UIMgr.Close(self)
	end)

	for i, btn in ipairs(self.tbRightBtnList) do
		UIHelper.BindUIEvent(btn, EventType.OnClick, function ()
			self.nLastClickTime = self.nLastClickTime or 0
			local nTime = GetTickCount() - self.nLastClickTime
			if nTime > QIXUE_CLICK_CD then
				self:ClickBtn(i)
			end
		end)

		UIHelper.BindUIEvent(btn, EventType.OnLongPress, function(_, x, y)
			self:OutputChannelTip(i)
		end)
	
	end
end

function UIChannelView:RegEvent()
	Event.Reg(self, "ON_CHANNEL_GETINFO", function(tInfo, nItemNum)
		self:ApplyInfo(tInfo, nItemNum)
	end)
end

function UIChannelView:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChannelView:UpdateInfo()
	
end

function UIChannelView:ApplyInfo(tLevel, nLingDanNum)
	self.tLevel = tLevel
	local nMaxNum = 0
	for i, btn in ipairs(self.tbRightBtnList) do
		local tbScript = UIHelper.GetBindScript(btn)
		UIHelper.SetString(tbScript.LabelNum, tLevel[i])
		if tLevel[i] == QIXUE_SUM then
			UIHelper.SetTextColor(tbScript.LabelNum, cc.c4b(255, 255, 187, 255))
			UIHelper.SetVisible(tbScript.ImgLight, true)
			nMaxNum = nMaxNum + 1
		end
	end
	UIHelper.SetString(self.LabelNum, nMaxNum .. "/" .. QIXUE_SUM)
	UIHelper.SetString(self.LabelLDNum, nLingDanNum)
end

function UIChannelView:ClickBtn(nIndex)
	if self.tLevel and self.tLevel[nIndex] ~= 10 then
		local tbScript = UIHelper.GetBindScript(self.tbRightBtnList[nIndex])
		UIHelper.SetVisible(tbScript.ImgAniLight, true)
		UIHelper.PlaySpriteFrameAnimtion(tbScript.ImgAniLight, nBlueLightAnimtionID)
		self.nLastClickTime = GetTickCount()
		RemoteCallToServer("On_Channel_ClickOnce", nIndex)
	end
end

function UIChannelView:OutputChannelTip(nIndex)
	local tChannelInfo = Table_GetChannelInfo(nIndex, self.tLevel[nIndex])
	local tList = SplitString(tChannelInfo.szDescription, "\n")
	local szTip = ""
	for i, v in ipairs(tList) do
		local szDes
        if i == 1 or i == 3 then
            szDes = GetFormatText( UIHelper.GBKToUTF8(v) .. "\n", nil, 255, 255, 255 )
        elseif i == 2 then
            szDes = GetFormatText( UIHelper.GBKToUTF8(v) .. "\n", nil, 215, 246, 255 )
        end
        szTip = szTip .. szDes
	end
	local tips, tipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.tbRightBtnList[nIndex], szTip)
end

return UIChannelView