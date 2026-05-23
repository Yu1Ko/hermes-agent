-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: BaiZhanDbmData
-- Date: 2024-06-20 09:38:13
-- Desc: ?
-- ---------------------------------------------------------------------------------

BaiZhanDbmData = BaiZhanDbmData or {className = "BaiZhanDbmData"}
local self = BaiZhanDbmData


local DBM_TYPE = {
	BUFF = 1,
	SKILL = 2,
	NPC = 3
}

local DBM_ACTION_TYPE = {
	BUFF = {
		GET = 1,
		LOST = 2
	},
	SKILL = {
		START = 1,
		END = 2
	},
	NPC = {
		STARTFIGHT = 1,
		LIFEPERCENT = 2,
		MANAPERCENT = 3,
		DEAD = 4,
		ALLDEAD = 5,
		APPEAR = 6
	}
}

function BaiZhanDbmData.Init()
	if not self.bInit then
		self.InitData()
		self.RegEvent()
		self.bInit = true
	end
end

function BaiZhanDbmData.UnInit()
	Event.UnRegAll(self)
	self.bInit = false
end


-------------------做法二-------------------------
function BaiZhanDbmData.InitData()
	self.bStart = false
	self.nGroupID = nil
	self.tbCurDbmInfo = {}	--某场战斗的对应所有dbm
	self.tbDbmList = {}	--当前需要显示的dbm列表
end

function BaiZhanDbmData.RegEvent()
	Event.Reg(self, "ON_ENTER_BAIZHAN_DBM", function (bStart, nGroupID)
		self.InitData()
		if bStart then	--开启dbm
			self.UpdateInfoBeforeFight(nGroupID)
			if self.nCDTimer then
				Timer.DelAllTimer(self)
				self.nCDTimer = nil
			end
			self.nCDTimer = Timer.AddCycle(self, 1, function()
				if not table.is_empty(self.tbDbmList) and self.bStart then
					self.SortDbmList()
				end
			end)
		else	--关闭dbm
			self.StopDbm()
		end
	end)

	Event.Reg(self, "ON_PAUSE_BAIZHAN_DBM", function (bPause)
		if not table.is_empty(self.tbDbmList) and self.bStart then
			for k, dbm in pairs(self.tbDbmList) do
				self.tbDbmList[k].bPause = bPause
				if dbm.bInStartTime then	--处于starttime状态
					self.tbDbmList[k].bPause = false
				else
					if bPause and dbm.bTimeCeil then
						self.tbDbmList[k].nCountDownTime = math.floor(dbm.nCountDownTime + 1)
					end
				end
			end
			self.SortDbmList()
			self.TriggerDbm(false, false)
		end
	end)


	Event.Reg(self, "ON_BAIZHAN_DBMCHANGE", function (nID)	--设置nID技能直接进入cd
		if not table.is_empty(self.tbDbmList) and self.bStart then
			for k, dbm in pairs(self.tbDbmList) do
				if nID == dbm.nID then
					local nNewDbm = self.SetDbmCdState(dbm, false)	--重置cd
					nNewDbm = self.SetDbmCountDown(dbm, nNewDbm.nRealCD)	--重置倒计时
					nNewDbm.nAbsolutePriority = 0
					nNewDbm.bPause = false
					nNewDbm.bInStartTime = false
					self.tbDbmList[k] = nNewDbm
					self.SortDbmList()
					self.TriggerDbm(false, false)
					break
				end
			end
		end
	end)

	Event.Reg(self, "ON_ADD_BAIZHAN_DBM", function (tbIDList)	--添加一部分技能,Event.Dispatch("ON_ADD_BAIZHAN_DBM", {1,2,3})
		if self.bStart then
			local bAddResult = self.AddCurDbmList(tbIDList)
			if bAddResult then
				self.SortDbmList()
				self.TriggerDbm(true, false)
			end
		end
	end)

	Event.Reg(self, "ON_REMOVE_BAIZHAN_DBM", function (tbIDList)	--删除一部分技能
		if self.bStart then
			local bRemoveResult = self.RemoveCurDbmList(tbIDList)
			if bRemoveResult then
				self.SortDbmList()
				self.TriggerDbm(false, true)
			end
		end
	end)

	Event.Reg(self, "ON_CHANGE_BAIZHAN_DBM_CD", function (nID, nTime)	--为当前某个技能的cd加上nTime
		if self.bStart then
			for k, dbm in pairs(self.tbDbmList) do
				if dbm.nID == nID then
					local nCountDownTime = self.tbDbmList[k].nCountDownTime
					local nNewCountDownTime = nCountDownTime + nTime
					self.tbDbmList[k].nCountDownTime = nNewCountDownTime
					self.tbDbmList[k].nRealCD = nNewCountDownTime > dbm.nRealCD and nNewCountDownTime or dbm.nRealCD
					self.SortDbmList()
					self.TriggerDbm(false, false)
					break
				end
			end
		end
	end)

	Event.Reg(self, "ON_PAUSE_BAIZHAN_DBM_ByID", function (bPause, tbIDList)
		if not table.is_empty(self.tbDbmList) and self.bStart then
			for k, dbm in pairs(self.tbDbmList) do
				if table.contain_value(tbIDList, dbm.nID) then
					self.tbDbmList[k].bPause = bPause
					if dbm.bInStartTime then	--处于starttime状态
						self.tbDbmList[k].bPause = false
					else
						if bPause and dbm.bTimeCeil then
							self.tbDbmList[k].nCountDownTime = math.floor(dbm.nCountDownTime + 1)
						end
					end
				end
			end
			self.SortDbmList()
			self.TriggerDbm(false, false)
		end
    end)

	Event.Reg(self, EventType.OnAccountLogout, function ()
        self.InitData()
		self.StopDbm()
    end)
end

function BaiZhanDbmData.UpdateInfoBeforeFight(nGroupID)
	self.bStart = true
	self.nGroupID = nGroupID
	self.GetCurDbmInfoFromTab()	--获取本场战斗所有dbm
end

function BaiZhanDbmData.GetCurDbmInfoFromTab()	--获取本场战斗所有dbm
	if table.is_empty(self.tbCurDbmInfo) then
		self.tbCurDbmInfo = TabHelper.GetBaiZhanDbmInfo(self.nGroupID)
	end
end

function BaiZhanDbmData.GetSingleDbmBynID(nID)	--通过nid获取指定单条dbm
	local tbSkillInfo = nil
	if table.is_empty(self.tbCurDbmInfo) then
		self.tbCurDbmInfo = TabHelper.GetBaiZhanDbmInfo(self.nGroupID)
	end

	for k, tbInfo in pairs(self.tbCurDbmInfo) do
		if tbInfo.nID == nID then
			tbSkillInfo = tbInfo
			return tbSkillInfo
		end
	end

	return tbSkillInfo
end

function BaiZhanDbmData.SetDbmCdState(dbm, bStartTime)
	dbm.nRealCD = bStartTime and dbm.nStartTime or dbm.nSkillCD
	return dbm
end

function BaiZhanDbmData.GetDbmCd(nID)
	local dbm = self.tbDbmList[nID]
	local nCD = nil
	if dbm then
		nCD = dbm.nRealCD
	end

	return nCD
end

function BaiZhanDbmData.SetDbmCountDown(dbm, nCountTime)
	dbm.nCountDownTime = dbm and nCountTime or 0
	return dbm
end

function BaiZhanDbmData.SetDbmCountDownByID(nID, nCountTime)
	for k, dbm in pairs(self.tbDbmList) do
		if dbm.nID == nID then
			self.tbDbmList[k].nCountDownTime = nCountTime
			self.tbDbmList[k].nRealCD = nCountTime > dbm.nRealCD and nCountTime or dbm.nRealCD
			break
		end
	end
end

function BaiZhanDbmData.SetDbmPauseStateByID(nID, bPause)
	for k, dbm in pairs(self.tbDbmList) do
		if dbm.nID == nID then
			self.tbDbmList[k].bPause = bPause
			break
		end
	end
end

function BaiZhanDbmData.GetSingleDbmFromCurDbm(nID)
	local result = nil
	for k, dbm in pairs(self.tbDbmList) do
		if dbm.nID == nID then
			result = dbm
			break
		end
	end
	return result
end

function BaiZhanDbmData.AddCurDbmList(tbIDList)
	local bAddResult = false
	for k, nID in pairs(tbIDList) do
		local dbm = self.GetSingleDbmBynID(nID)
		if not dbm then
			break
		end
		bAddResult = true
		--设置该dbm的cd为nStartTime
		local tbNewDbm = self.SetDbmCdState(dbm, true)
		--设置该dbm的倒计时时间
		tbNewDbm = self.SetDbmCountDown(dbm, dbm.nRealCD)
		--设置该dbm的暂停状态
		tbNewDbm.bPause = false
		tbNewDbm.bInStartTime = true
		table.insert(self.tbDbmList, tbNewDbm)
	end

	return bAddResult
end

function BaiZhanDbmData.RemoveCurDbmList(tbIDList)
	local bRemoveResult = false
	 for _, nID in pairs(tbIDList) do
	 	for k, dbm in pairs(self.tbDbmList) do
	 		if dbm.nID == nID then
				--self.tbDbmList[k] = nil
				table.remove(self.tbDbmList, k)
				bRemoveResult = true
	 		end
	 	end
	 end

	 return bRemoveResult
end

function BaiZhanDbmData.ReplaceDbmSkillInfo(nOldID, nNewID)
	local nNewInfo = TabHelper.GetBaiZhanDbmInfoBynID(nNewID)
	for k, dbm in pairs(self.tbDbmList) do
		if dbm.nID == nOldID then
			self.tbDbmList[k].nColorID = nNewInfo.nColorID
			self.tbDbmList[k].szSkill = nNewInfo.szSkill
			self.tbDbmList[k].nSkillIconID = nNewInfo.nSkillIconID
			break
		end
	end
end

function BaiZhanDbmData.SortDbmList()
	table.sort(self.tbDbmList, function (a, b)
		if not table.is_empty(a) and not table.is_empty(b) then
			--local nFirstSortTime = math.ceil(a.nCountDownTime)
			--local nSecondSortTime = math.ceil(b.nCountDownTime)
			if a.nAbsolutePriority ~= b.nAbsolutePriority then
				return a.nAbsolutePriority > b.nAbsolutePriority
			elseif a.nNormalPriority ~= b.nNormalPriority and a.nCountDownTime == b.nCountDownTime then
				return a.nNormalPriority > b.nNormalPriority
			elseif a.nCountDownTime ~= b.nCountDownTime then
				return a.nCountDownTime < b.nCountDownTime
			else
				return a.nID > b.nID
			end
		end
	end)
end

function BaiZhanDbmData.TriggerDbm(bAdd, bRemove)
	if table.is_empty(self.tbDbmList) then
		return
	end
	Event.Dispatch("ON_START_BAIZHAN_DBM", bAdd, bRemove)
end

function BaiZhanDbmData.StopDbm()	--停止dbm
	if self.nCDTimer then
		Timer.DelAllTimer(self)
		self.nCDTimer = nil
	end
	Event.Dispatch("ON_END_BAIZHAN_DBM")
end