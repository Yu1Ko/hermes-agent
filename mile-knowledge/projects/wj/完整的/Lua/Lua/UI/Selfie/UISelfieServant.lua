-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieServant
-- Date: 2023-05-08 11:15:15
-- Desc: 幻境云图 -- 知交动作界面
-- ---------------------------------------------------------------------------------

local UISelfieServant = class("UISelfieServant")
local m_aVisibleServants = {}
local _MAX_SERVANTS_PER_TABLE = 3
local m_nCurServantTable = 1

local function GetServantUILocation(dwServantIndex)
	if dwServantIndex == 0 then
		return 1, 0
	end

	for nIndex, dwThisServantIndex in ipairs(m_aVisibleServants) do
		if dwThisServantIndex == dwServantIndex then
			return math.ceil(nIndex / _MAX_SERVANTS_PER_TABLE), (nIndex - 1) % _MAX_SERVANTS_PER_TABLE + 1
		end
	end
    return 1, 0
end

function UISelfieServant:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UISelfieServant:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieServant:BindUIEvent()
    
end

function UISelfieServant:RegEvent()
    UIHelper.TableView_addCellAtIndexCallback(self.TableView, function(tableView, nIndex, script, node, cell)
        local onClickCallback = function(nNpcIndex , bReceived)
            Event.Dispatch(EventType.OnSelfieServantCellSelect , nNpcIndex) 
            if not bReceived then 
                UIHelper.SetVisible(self.WIdgetRenownFriendAction , false)
                return 
            end
            UIHelper.SetVisible(self.WIdgetRenownFriendAction , true)
            if nNpcIndex ~= Servant_GetCurServantNpcIndex() then
                if nNpcIndex > 0 then
                    if bReceived then
                        Servant_ClearFreezeState()
                        Servant_CallServantByID(nNpcIndex, true)
                        self:UpdateAction()
                    end
                else
                    Servant_DismissServantByID()
                    Servant_ClearFreezeState()
                    UIHelper.SetVisible(self.WIdgetRenownFriendAction , false)
                end
                Event.Dispatch(EventType.OnSelfieServantChange , nNpcIndex)
            end
        end
        local tbDataInfo = {}
        local nStartIndex = math.min((nIndex - 1) * _MAX_SERVANTS_PER_TABLE + 1 ,self.nDataCount)
        for i = nStartIndex, math.min(nStartIndex + _MAX_SERVANTS_PER_TABLE - 1 ,self.nDataCount), 1 do
            table.insert(tbDataInfo , m_aVisibleServants[i])
        end
        if script then
            script:OnEnter(tbDataInfo , onClickCallback)
        end
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function(width, height)
        UIHelper.TableView_scrollToTop(self.TableView)
    end)
   
end

function UISelfieServant:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UISelfieServant:Hide()
    UIHelper.SetVisible(self.WIdgetRenownFriendAction , false)
end

function UISelfieServant:Open()
    if Servant_GetCurServantNpcIndex() > 0 then
		UIHelper.SetVisible(self.WIdgetRenownFriendAction , true)
	else
		UIHelper.SetVisible(self.WIdgetRenownFriendAction , false)
	end
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------


function UISelfieServant:UpdateInfo()
    if UIHelper.GetScreenPortrait() then
        _MAX_SERVANTS_PER_TABLE = 6
    else
        _MAX_SERVANTS_PER_TABLE = 3
    end
    Servant_ReserveServant()
    self:LoadServantData()
    local dwServantIndex = Servant_GetCurServantNpcIndex() 
    local nTable, nIndex = GetServantUILocation(dwServantIndex)
    self:TurnToServantPage(nTable, nIndex)
    UIHelper.LayoutDoLayout(self.Layout)
    if dwServantIndex > 0 then
		Servant_CallServantByID(dwServantIndex, true)
		UIHelper.SetVisible(self.WIdgetRenownFriendAction , true)
		self:UpdateAction()
	else
		Servant_DismissServantByID()
		UIHelper.SetVisible(self.WIdgetRenownFriendAction , false)
	end
end

function UISelfieServant:LoadServantData()
    m_aVisibleServants = {
        {nNpcIndex = -1 , bReceive = true}
    }
    local aReceivedNpcRewards, aUnreceivedNpcRewards = RepuData.GetReceivedNpcRewards()
    for k, dwForceID in ipairs(aReceivedNpcRewards) do
		local dwNpcIndex, bSuccess = RepuData.GetServantInfoByForceID(dwForceID, true)
		if bSuccess then
			table.insert(m_aVisibleServants, {nNpcIndex = dwNpcIndex , bReceive = true})
		end
	end
	for k, dwForceID in ipairs(aUnreceivedNpcRewards) do
		local dwNpcIndex, bSuccess = RepuData.GetServantInfoByForceID(dwForceID, true)
		if bSuccess then
			table.insert(m_aVisibleServants, {nNpcIndex = dwNpcIndex , bReceive = false})
		end
	end
end

function UISelfieServant:TurnToServantPage(nTable , nIndex)
    self.nDataCount = #m_aVisibleServants
	self.nMaxTable = math.max(1, self.nDataCount / _MAX_SERVANTS_PER_TABLE)
    if nTable < 1 or nTable > self.nMaxTable then
		nTable = math.max(1, math.min(nTable, self.nMaxTable))
	end
    m_nCurServantTable = nTable
    if UIHelper.GetScreenPortrait() then
        UIHelper.TableView_init(self.TableView, self.nMaxTable, PREFAB_ID.WidgetCameraRenownFriendTogLong)
    else
        UIHelper.TableView_init(self.TableView, self.nMaxTable, PREFAB_ID.WidgetCameraRenownFriendTog)
    end
    UIHelper.TableView_reloadData(self.TableView)
end

function UISelfieServant:UpdateAction()
    local aActionInfoList = Servant_GetActionInfoList(Servant_GetCurServantNpcIndex())
    UIHelper.RemoveAllChildren(self.WidgetRenownFriendActionList)
    for nIndex, tActionInfo in ipairs(aActionInfoList) do
		local widgetAction = UIHelper.AddPrefab(PREFAB_ID.WidgetRenownFriendAction , self.WidgetRenownFriendActionList)
		widgetAction:OnEnter(tActionInfo)
	end
    UIHelper.LayoutDoLayout(self.WidgetRenownFriendActionList)
end


return UISelfieServant