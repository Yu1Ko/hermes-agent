-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetFillFeed
-- Date: 2025-11-20 10:42:41
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetFillFeed = class("UIWidgetFillFeed")

local MAX_COUNT = 3
local LIVE_TIME = 5000
local QUEUE_LIVE_TIME = 4000

function UIWidgetFillFeed:OnEnter(bCustom)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tList = {}
    self:UpdateAll(bCustom)
    self.nTimer = Timer.AddCycle(self, 0.1, function()
        self:RefreshList()
    end)
end

function UIWidgetFillFeed:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetFillFeed:BindUIEvent()
    
end

function UIWidgetFillFeed:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_BROADCAST_KILL_INFO", function(szKiller, szTarget, dwEffectID, dwType)
        -- 扬刀大会特殊处理，机器人名字强制显示为武意残影
        if ArenaTowerData.IsInArenaTowerMap() then
            if ArenaTowerData.IsRobotByName(szKiller) then
                szKiller = UIHelper.UTF8ToGBK(g_tStrings.ARENA_TOWER_ROBOT_NAME)
            end
            if ArenaTowerData.IsRobotByName(szTarget) then
                szTarget = UIHelper.UTF8ToGBK(g_tStrings.ARENA_TOWER_ROBOT_NAME)
            end
        end

        self:AppendMessage(szKiller, szTarget, dwEffectID, dwType)
        self:UpdateAll()
    end)
end

function UIWidgetFillFeed:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetFillFeed:RefreshData()
    local tNewList = {}
    for _, v in pairs(self.tList) do
        if not v.bHasAppend then
            table.insert(tNewList, v)
        end
    end
    self.tList = tNewList
end

function UIWidgetFillFeed:RefreshList()
    local nCount   = UIHelper.GetChildrenCount(self.LayoutMainCityInfo)
    local nNow     = GetTickCount()
    local bInQueue = self.tList and #self.tList > 0 or false
    local childrens = UIHelper.GetChildren(self.LayoutMainCityInfo)
    for _, children in ipairs(childrens) do
        local script = UIHelper.GetBindScript(children)
        if script and script.bRemove then
            break
        end
        if script and script.nTime and not script.bRemove then
            local nLiveTime = bInQueue and QUEUE_LIVE_TIME or LIVE_TIME
            if nNow - script.nTime > nLiveTime then
                -- UIHelper.RemoveFromParent(children)
                script.bRemove = true
                UIHelper.PlayAni(script, children, "AniKillFeedModHide", function()
                    UIHelper.RemoveFromParent(children)
                end)
                break
            end
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutMainCityInfo)
    self:UpdateInfo()
end

function UIWidgetFillFeed:AppendMessage(szKiller, szTarget, dwEffectID, dwType)
    local tInfo = {
        szKiller   = szKiller,
        szTarget   = szTarget,
        dwEffectID = dwEffectID,
        dwType     = dwType,
    }
    table.insert(self.tList, tInfo)
end

function UIWidgetFillFeed:UpdateInfo()
    local tList  = self.tList or {}
    local nCount = UIHelper.GetChildrenCount(self.LayoutMainCityInfo)
    for _, tInfo in pairs(tList) do
        if not tInfo.bHasAppend and nCount < MAX_COUNT then
            tInfo.bHasAppend = true
            local tCellInfo  = clone(tInfo)
            local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetKillFeedMod, self.LayoutMainCityInfo)
            scriptCell:OnEnter(tCellInfo)
            scriptCell.tInfo = tInfo
            scriptCell.nTime = GetTickCount()
            nCount = nCount + 1
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutMainCityInfo)
    self:RefreshData()
end

function UIWidgetFillFeed:UpdateAll(bCustom)
    UIHelper.SetVisible(self.WidgetKillFeedMod, false)
    self:UpdateInfo()
    if bCustom then
        UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()
            Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.FULL, CUSTOM_TYPE.KILL_FEED, self.nMode)
        end)
    end
end

function UIWidgetFillFeed:UpdatePrepareState(nMode, bStart)
    self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
    self.nMode = nMode
end

function UIWidgetFillFeed:UpdateCustomState()
    self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)

end

function UIWidgetFillFeed:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    UIHelper.SetVisible(self.WidgetKillFeedMod, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER or nState == CUSTOM_BTNSTATE.EDIT)
    self.nState = nState
end

return UIWidgetFillFeed