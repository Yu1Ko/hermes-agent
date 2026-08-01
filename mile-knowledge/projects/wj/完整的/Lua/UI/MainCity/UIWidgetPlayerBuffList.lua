-- WidgetMainCityBuffList
local UIWidgetPlayerBuffList =  class("UIWidgetPlayerBuffList")

local maxBuffNum = 6
local tbFakeBuffInfo = {
    [1] = "skill/Common/Buffliuxue1.png",
    [2] = "skill/Common/Buffyisu1.png",
    [3] = "skill/Common/Buffbaofa1.png",
    [4] = "skill/Common/Buffshengcun1.png",
    [5] = "skill/Common/Buffhuifu1.png",
    [6] = "skill/Common/Bufffantan1.png",
}
function UIWidgetPlayerBuffList:OnEnter(bCustom, bSingle)
    if bCustom then
       for i, szPath in ipairs(tbFakeBuffInfo) do
           local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityBuff, self.LayoutBuffAndSkill)
           tbScript:UpdateFakeBuffInfo(tbFakeBuffInfo[i])
       end
       self:BindUIEvent()
    else
        local PrefabComponent = require("Lua/UI/Map/Component/UIPrefabComponent")
        self.tScript = PrefabComponent:CreateInstance()
        self.tScript:Init(self.LayoutBuffList, PREFAB_ID.WidgetMainCityBuff)

        UIHelper.SetVisible(self.BtnBuff, bSingle or false)
        if bSingle then
            UIHelper.BindUIEvent(self.BtnBuff, EventType.OnClick, function()
                local now = GetCurrentTime()
                local bNeedUpdateBuffTips = true
                if now - (self.nLastBuffClickTime or 0) < 1 then
                    bNeedUpdateBuffTips = false
                end
                self.nLastBuffClickTime = now

                local nX = UIHelper.GetWorldPositionX(self.BtnBuff)
                local nY = UIHelper.GetWorldPositionY(self.BtnBuff)
                if not g_pClientPlayer then
                    return
                end
                local tBuff = BuffMgr.GetSortedBuff(g_pClientPlayer, true, true)
                if TreasureBattleFieldSkillData.InSkillMap() then
                    local tSkillBuffs = TreasureBattleFieldSkillData.GetSkillBuffList(g_pClientPlayer)
                    table.insert_tab(tBuff, tSkillBuffs)
                end
                if #tBuff > 0 then
                    local tip, script = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetMainCityBuffContentTip, nX, nY)
                    script:UpdatePlayerInfo(g_pClientPlayer.dwID, tBuff, true, bNeedUpdateBuffTips)
                end
            end)
        end
    end
end

function UIWidgetPlayerBuffList:OnExit()
end

function UIWidgetPlayerBuffList:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()  --进入黑框,maincity加载新的
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.FULL, CUSTOM_TYPE.BUFF, self.nMode)
    end)
end


function UIWidgetPlayerBuffList:UpdateBuff()
    local now = Timer.RealMStimeSinceStartup()
    if now - (self.nLastUpdateTime or 0) < 100 then -- 100ms 左右刷一次
        return
    end

    self.nLastUpdateTime = now

    local tBuff = BuffMgr.GetSortedBuff(self.character, nil, true)
    local tSkillBuffs = {}
    if TreasureBattleFieldSkillData.InSkillMap() then
        tSkillBuffs = TreasureBattleFieldSkillData.GetSkillBuffList(self.character)
        if #tSkillBuffs >= maxBuffNum then
            for i = #tBuff, 1, -1 do
                if BuffMgr.GetBuffCatalog(tBuff[i].dwID, tBuff[i].nLevel) and BuffMgr.GetBuffCatalog(tBuff[i].dwID, tBuff[i].nLevel).nType == 0 then
                    table.remove(tBuff, i)
                end
            end
        end
    end
    local nCount = math.min(maxBuffNum, #tBuff)
    if nCount > 0 then
        for i = 1, nCount do
            local script = self.tScript:Alloc(i)
            script:UpdateBuffImage(tBuff[i].dwID, tBuff[i].nLevel, self.character, tBuff)
        end
        self.tScript:Clear(nCount + 1)
    else
        self.tScript:Clear(1)
    end

    local nSkillIndex = 1
    self.tSkillScripts = self.tSkillScripts or {}
    if TreasureBattleFieldSkillData.InSkillMap() then
        local nMaxSkillCount = 6 - nCount
        for _, tBuff in ipairs(tSkillBuffs) do
            if nSkillIndex > nMaxSkillCount then
                break
            end
            self.tSkillScripts[nSkillIndex] = self.tSkillScripts[nSkillIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.LayoutSkillList)
            local script = self.tSkillScripts[nSkillIndex]
            local nSkillID = TreasureBattleFieldSkillData.GetBuffSkillID(tBuff.dwID)
            script:UpdateInfo(nSkillID)
            script:SetSelectEnable(false)
            UIHelper.SetAnchorPoint(script._rootNode, 0.5, 0.5)
            UIHelper.SetVisible(script._rootNode, true)
            nSkillIndex = nSkillIndex + 1
        end
    end
    for i = nSkillIndex, #self.tSkillScripts do
        local script = self.tSkillScripts[i]
        UIHelper.SetVisible(script._rootNode, false)
    end
    UIHelper.DelayFrameLayoutDoLayout(self, self.LayoutBuffList)
    UIHelper.DelayFrameLayoutDoLayout(self, self.LayoutSkillList)
    UIHelper.DelayFrameLayoutDoLayout(self, self.LayoutBuffAndSkill)
end

function UIWidgetPlayerBuffList:UpdateBuffCycle(character)
    if not character then
        self.tScript:Clear(1)
        return
    end
    self.character = character
    self:UpdateBuff()
end

function UIWidgetPlayerBuffList:UpdatePrepareState(nMode, bStart)
    self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
	self.nMode = nMode
end

function UIWidgetPlayerBuffList:UpdateCustomState()
    self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
end


function UIWidgetPlayerBuffList:UpdateCustomNodeState(nState)
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState
end

return UIWidgetPlayerBuffList