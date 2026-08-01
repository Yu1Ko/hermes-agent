-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISkillDbmCell
-- Date: 2024-06-25 10:02:33
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISkillDbmCell = class("UISkillDbmCell")

function UISkillDbmCell:OnEnter(nID)
	self.nID = nID
	self.tbDbmInfo = BaiZhanDbmData.GetSingleDbmFromCurDbm(nID)
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:UpdateInfo()
end

function UISkillDbmCell:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UISkillDbmCell:BindUIEvent()

end

function UISkillDbmCell:RegEvent()
	Event.Reg(self, "ON_PAUSE_BAIZHAN_SKILL_CD", function(bPause)	--暂停cd
		local nCountDownTime = self.tbDbmInfo.nCountDownTime
		local bCanPause = true
		if self.tbDbmInfo.nRealCD == self.tbDbmInfo.nStartTime then	--处于starttime状态
			bCanPause = self.tbDbmInfo.bStartTimePause
		end
		if nCountDownTime > 0 and bCanPause then	--当前cd大于0才需要暂停或开启
			BaiZhanDbmData.SetDbmPauseStateByID(self.tbDbmInfo.nID, bPause)
			if bPause then	--暂停
				Timer.DelAllTimer(self)
				self.nCDTimer = nil
				UIHelper.SetVisible(self.CdLabel, true)
				UIHelper.SetVisible(self.ImgSkillCd, true)
				local nPercent = nCountDownTime / self.tbDbmInfo.nRealCD * 100
				UIHelper.SetString(self.CdLabel ,string.format("%d", math.floor(nCountDownTime)))
				UIHelper.SetProgressBarPercent(self.ImgSkillCd, nPercent)
			else	--开启
				self:UpdateCD()
			end
		end
	end)

	Event.Reg(self, "ON_CHANGE_BAIZHAN_DBM_ICONINFO", function (nOldID, nNewID)	--nNewID的icon信息替换nOldID的
		if self.nID == nOldID then
			BaiZhanDbmData.ReplaceDbmSkillInfo(nOldID, nNewID)
			self.tbDbmInfo = BaiZhanDbmData.GetSingleDbmFromCurDbm(nOldID)
			self:UpdateInfo()
		end
    end)

	Event.Reg(self, "ON_CALIBRATE_BAIZHAN_DBM_CD", function (nID, nTime)	--校准nid的cd
		if self.nID == nID then
			local nCountDownTime = self.tbDbmInfo.nCountDownTime
			if math.abs(nCountDownTime - nTime) > 1 then
				BaiZhanDbmData.SetDbmCountDownByID(nID, nTime)
				self.tbDbmInfo = BaiZhanDbmData.GetSingleDbmFromCurDbm(nID)
				self:UpdateInfo()
			end
		end
    end)
end

function UISkillDbmCell:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISkillDbmCell:UpdateInfo()
	self:UpdateSkillIcon()
	--self:UpdateCD()

end

function UISkillDbmCell:UpdateSkillIcon()
	local szSkillName = UIHelper.GBKToUTF8(self.tbDbmInfo.szSkill)
	local iconTab = Table_GetItemIconInfo(self.tbDbmInfo.nSkillIconID)
    local szImagePath = nil
    if iconTab == nil then
        LOG.ERROR("GetSkillIconPath Failed, nSkillID is %d", self.tbDbmInfo.nSkillIconID or -10000000)
    else
        szImagePath = string.format("Resource/icon/%s", iconTab.FileName)
    end
	local szFramePath = MonsterBookData.GetEdgeFramePath(self.tbDbmInfo.nColorID)

	local length = utf8.len(szSkillName)
	if length > 3 then
		szSkillName = utf8.sub(szSkillName, 1, 2)
		szSkillName = string.format("%s...", szSkillName)
	end

	UIHelper.SetString(self.LabelName, szSkillName)
	UIHelper.SetTexture(self.ImgItemIcon, szImagePath, true, function ()
		UIHelper.UpdateMask(self.MaskItem)
	end)
	if szFramePath then
		UIHelper.SetVisible(self.ImgColorFrame, true)
		UIHelper.SetSpriteFrame(self.ImgColorFrame, szFramePath)
	else
		UIHelper.SetVisible(self.ImgColorFrame, false)
	end
	UIHelper.SetString(self.CdLabel, string.format("%d", math.floor(self.tbDbmInfo.nCountDownTime)))

	UIHelper.SetVisible(self.CdLabel, self.tbDbmInfo.nCountDownTime > 0)
	UIHelper.SetVisible(self.ImgSkillCd, self.tbDbmInfo.nCountDownTime > 0)

	local nPercent = self.tbDbmInfo.nCountDownTime / self.tbDbmInfo.nRealCD * 100
	UIHelper.SetProgressBarPercent(self.ImgSkillCd, nPercent)
end

function UISkillDbmCell:UpdateCD()
	if self.nCDTimer then
		Timer.DelAllTimer(self)
		self.nCDTimer = nil
	end
	local nCurTime = Timer.GetPassTime()
	local nCountDownTime = self.tbDbmInfo.nCountDownTime
	local bPause = self.tbDbmInfo.bPause
	if nCountDownTime > 0 and not bPause then
		self.nCDTimer = Timer.AddFrameCycle(self, 3, function()
			local nPassTime = Timer.GetPassTime() - nCurTime	--已经过去的时间
			local nNewCountDown = nCountDownTime - nPassTime	--该dbm当前的倒计时时间
			if nPassTime >= nCountDownTime then
				self:EndTimer()
			else
				self:StartTimer(nNewCountDown)
			end
		end)
	end
end

function UISkillDbmCell:StartTimer(nNewCountDown)
	--设置该dbm的倒计时时间
	UIHelper.SetVisible(self.CdLabel, true)
	UIHelper.SetVisible(self.ImgSkillCd, true)
	self.tbDbmInfo.nCountDownTime = nNewCountDown
	BaiZhanDbmData.SetDbmCountDownByID(self.tbDbmInfo.nID, nNewCountDown)
	local nPercent = nNewCountDown / self.tbDbmInfo.nRealCD * 100
	UIHelper.SetString(self.CdLabel ,string.format("%d", math.floor(nNewCountDown)))
	UIHelper.SetProgressBarPercent(self.ImgSkillCd, nPercent)
end

function UISkillDbmCell:EndTimer()
	UIHelper.SetVisible(self.CdLabel, false)
	UIHelper.SetVisible(self.ImgSkillCd, false)
	self.tbDbmInfo.nCountDownTime = 0
	BaiZhanDbmData.SetDbmCountDownByID(self.tbDbmInfo.nID, 0)
	Timer.DelAllTimer(self)
	self.nCDTimer = nil
end

return UISkillDbmCell