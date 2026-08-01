-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetDbmList
-- Date: 2024-06-27 14:44:20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetDbmList = class("UIWidgetDbmList")
local _nDragThreshold2 = 450
local tbFakeDbmInfo = {
	[1] = {
		szSkill = "技能一",
		nTime = 15,
		nIndex = 1,
		nTotalTime = 15,
		bFake = true
	},
	[2] = {
		szSkill = "技能二",
		nTime = 10,
		nIndex = 2,
		nTotalTime = 15,
		bFake = true
	},
	[3] = {
		szSkill = "技能三",
		nTime = 5,
		nIndex = 3,
		nTotalTime = 15,
		bFake = true
	}
}

function UIWidgetDbmList:OnEnter()
	self.tbScriptList = {}
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	local tbSizeInfo = MainCityCustomData.GetFontSizeInfo()
	if tbSizeInfo then
		UIHelper.SetScale(self._rootNode, tbSizeInfo["nDbm"]  or 1, tbSizeInfo["nDbm"] or 1)
	end

end

function UIWidgetDbmList:OnExit()
	self.bInit = false
	self:UnRegEvent()
	if self.tbDbms and self.tbDbms.cellPrefabPool then
		self.tbDbms.cellPrefabPool:Dispose()
		self.tbDbms.cellPrefabPool = nil
	end
end

function UIWidgetDbmList:BindUIEvent()
	Event.Reg(self, EventType.OnWindowsSizeChanged, function()
		UIHelper.UpdateNodeInsideScreen(self._rootNode)
	end)
	UIHelper.BindFreeDrag(self, self._rootNode)
end

function UIWidgetDbmList:RegEvent()
	Event.Reg(self, "ON_START_BAIZHAN_DBM", function (bAdd, bRemove)
		local bAdd = false
		local bRemove = false
		if self.nCDTimer then
			Timer.DelAllTimer(self)
			self.nCDTimer = nil
		end
		local nCurTime = Timer.GetPassTime()
		self.nCDTimer = Timer.AddFrameCycle(self, 3, function()
			local nPassTime = Timer.GetPassTime() - nCurTime	--3帧时间
			nCurTime = Timer.GetPassTime()
			local nScriptLength = table.get_len(self.tbScriptList)
			local nDbmLenght = table.get_len(BaiZhanDbmData.tbDbmList)
			bAdd = nScriptLength < nDbmLenght
			bRemove = nScriptLength > nDbmLenght
			if bRemove then
				for i = nDbmLenght + 1, nScriptLength, 1 do
					if self.tbScriptList and self.tbScriptList[i] then
						UIHelper.RemoveFromParent(self.tbScriptList[i]._rootNode)
						self.tbScriptList[i] = nil
					end
				end
			end

			for i, dbm in ipairs(BaiZhanDbmData.tbDbmList) do
				local tbScript = self.tbScriptList and self.tbScriptList[i]
				local nNewCountDown = dbm.bPause and dbm.nCountDownTime or dbm.nCountDownTime - nPassTime	--该dbm当前的倒计时时间
				nNewCountDown = nNewCountDown > 0 and nNewCountDown or 0
				if nNewCountDown == 0 and dbm.nSkillCD == -1 then	--约定nSkillCD为-1时默认starttime走完会删除该dbmid
					Event.Dispatch("ON_REMOVE_BAIZHAN_DBM", {dbm.nID})
					break
				end
				BaiZhanDbmData.SetDbmCountDownByID(dbm.nID, nNewCountDown)
				if tbScript then
					tbScript:OnEnter(dbm.nID)
				elseif bAdd then
					local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBaiZhanDbmCell, self.LayoutBaiZhanDbm, dbm.nID)
					table.insert(self.tbScriptList, script)
				end
			end
			UIHelper.LayoutDoLayout(self.LayoutBaiZhanDbm)
		end)
	end)

	Event.Reg(self, "ON_END_BAIZHAN_DBM", function ()
		UIHelper.RemoveAllChildren(self.LayoutBaiZhanDbm)
		self.tbScriptList = {}
		if self.nCDTimer then
			Timer.DelAllTimer(self)
			self.nCDTimer = nil
		end
	end)

	Event.Reg(self, "ON_ENTER_BAIZHAN_DBM", function (bStart, nGroupID)
		self.bBaizhanDbmState = bStart
		UIHelper.SetVisible(self._rootNode, bStart or MainCityCustomData.bSubsidiaryCustomState)
	end)


	Event.Reg(self, "ON_UPDATEBOSSDBM_STATE", function(bShow)
		self.bNormalDbmState = bShow
		UIHelper.SetVisible(self._rootNode, bShow or MainCityCustomData.bSubsidiaryCustomState)
		self:UpdateBossDbmInfo(bShow)
    end)

	Event.Reg(self, EventType.OnSetDragNodeScale, function (tbSizeType)
		if tbSizeType then
			UIHelper.SetScale(self._rootNode, tbSizeType["nDbm"]  or 1, tbSizeType["nDbm"] or 1)
		end

    end)

	Event.Reg(self, EventType.OnUpdateDragNodeCustomState, function (bSubsidiaryCustomState)
		if bSubsidiaryCustomState then
			self:EnterCustomInfo()
		else
			self:ExitCustomInfo()
		end
    end)

	Event.Reg(self, EventType.OnSaveDragNodePosition, function ()
		local size = UIHelper.GetCurResolutionSize()
		local szNodeName = self._rootNode:getName()
		Storage.MainCityNode.tbMaincityNodePos[szNodeName] =
		{
			nX = UIHelper.GetWorldPositionX(self._rootNode),
			nY = UIHelper.GetWorldPositionY(self._rootNode),
			Height = size.height,
			Width = size.width,
		}
		Storage.MainCityNode.Dirty()
    end)

	Event.Reg(self, EventType.OnResetDragNodePosition, function (tbDefaultPositionList, nType)
		if nType ~= DRAGNODE_TYPE.DBM then
			return
		end
        local size = UIHelper.GetCurResolutionSize()
        local tbDefaultPosition = tbDefaultPositionList[DRAGNODE_TYPE.DBM]
        local nX, nY = table.unpack(tbDefaultPosition)
        local nRadioX, nRadioY = size.width / 1600, size.height / 900
        UIHelper.SetWorldPosition(self._rootNode, nX * nRadioX, nY * nRadioY)
		MainCityCustomData.ShowScaleSetTip(self, DRAGNODE_TYPE.DBM)
    end)
end

function UIWidgetDbmList:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetDbmList:UpdateBossDbmInfo(bShow)
	UIHelper.RemoveAllChildren(self.LayoutDbm)
	if bShow then
		self.tbDbms = nil
		self.tbDmbScriptList = {}
		local nIndex = 1
		local tbSkillList = DBMData.SortDbm()
		self.nTime = Timer.GetPassTime()
		for k, v in ipairs(tbSkillList) do
			self:AddNormalDbm(v, k%3)
		end
	else
		if self.tbDbms then
			if self.tbDbms.cellPrefabPool then
				self.tbDbms.cellPrefabPool:Dispose()
				self.tbDbms.cellPrefabPool = nil
			end
		end

	end
end

function UIWidgetDbmList:AddNormalDbm(tbDbm, nIndex)
	if not self:IsInitDbmPrefab() then
		self:InitDbmPrefab(3, PREFAB_ID.WidgetMainCityDbmCell, self.LayoutDbm)
    end


    local tbData = {}
    tbData.szSkill = tbDbm.szSkill
    tbData.nTime = tbDbm.nTime
	tbData.nIndex = nIndex
    self:TryAddDbm(tbData)
end


function UIWidgetDbmList:InitDbmPrefab(nMaxTipNum, nPrefabID, parent)
	if self.tbDbms and self.tbDbms.cellPrefabPool then
		self.tbDbms.cellPrefabPool:Dispose()
		self.tbDbms.cellPrefabPool = nil
	end

	self.tbDbms = {}
    self.tbDbms.nMaxDbmNum = nMaxTipNum
    self.tbDbms.cellPrefabPool = PrefabPool.New(nPrefabID, nMaxTipNum)
    self.tbDbms.parent = parent
    self.tbDbms.cache = {}
    self.tbDbms.tbDbmView = {}
end

function UIWidgetDbmList:TryAddDbm(tbData)

    local tbDbmView = self.tbDbms.tbDbmView
    local nDbmsNum = self.tbDbms.nMaxDbmNum
    local cellPrefabPool = self.tbDbms.cellPrefabPool
    local parent = self.tbDbms.parent
    local cache = self.tbDbms.cache

    if #tbDbmView == nDbmsNum then
        table.insert(cache, tbData)
        return
    end

    self:AddDbm(tbData)
end

function UIWidgetDbmList:IsInitDbmPrefab()
    return self.tbDbms ~= nil
end

function UIWidgetDbmList:AddDbm(tbData)
	local cellPrefabPool = self.tbDbms.cellPrefabPool
    local parent = self.tbDbms.parent
    local tbDbmsView = self.tbDbms.tbDbmView

    tbData.callback = function(node)
        self:RemoveDbm(node, parent)
    end

	tbData.nTime = tbData.nTime - (Timer.GetPassTime() - self.nTime)
    local node, scriptView = cellPrefabPool:Allocate(parent, tbData)
    table.insert(tbDbmsView, scriptView)

    UIHelper.LayoutDoLayout(parent)
end

function UIWidgetDbmList:RemoveDbm(node, parent)

    local tbDbmsView = self.tbDbms.tbDbmView
    local cellPrefabPool = self.tbDbms.cellPrefabPool

    for nIndex, script in ipairs(tbDbmsView) do
        if script._rootNode == node then
            table.remove(tbDbmsView, nIndex)
            break
        end
    end

    cellPrefabPool:Recycle(node)

    UIHelper.LayoutDoLayout(parent)

    self:NextDbm()
end


function UIWidgetDbmList:NextDbm()
    local cache = self.tbDbms.cache
    if #cache >= 1 then
        local tbData = table.remove(cache, 1)
        self:AddDbm(tbData)
    end
end

function UIWidgetDbmList:EnterCustomInfo()
	self.bMoved = false
	local function callback()
		MainCityCustomData.ShowScaleSetTip(self, DRAGNODE_TYPE.DBM)
	end
	UIHelper.BindFreeDrag(self, self._rootNode, 0, callback)
	UIHelper.SetVisible(self.ImgSelectZone, true)
	UIHelper.SetVisible(self._rootNode, true)
	if UIHelper.GetChildrenCount(self.LayoutDbm) == 0 and UIHelper.GetChildrenCount(self.LayoutBaiZhanDbm) == 0 then
		for i, tbData in pairs(tbFakeDbmInfo) do
			UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityDbmCell, self.LayoutDbm, tbData)
		end
		self.bFakeDbm = true
	else
		self.bFakeDbm = false
	end
end

function UIWidgetDbmList:ExitCustomInfo()
	UIHelper.BindFreeDrag(self, self._rootNode)
    UIHelper.SetVisible(self.ImgSelectZone, false)
	if self.bFakeDbm then
		UIHelper.RemoveAllChildren(self.LayoutDbm)
		UIHelper.SetVisible(self._rootNode, false)
	end
	self.bFakeDbm = false
	if UIHelper.GetChildrenCount(self.LayoutDbm) == 0 and UIHelper.GetChildrenCount(self.LayoutBaiZhanDbm) == 0 then
		UIHelper.SetVisible(self._rootNode, false)
	end
end

return UIWidgetDbmList