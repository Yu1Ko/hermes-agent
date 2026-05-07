-- ---------------------------------------------------------------------------------
-- Name: UIWidgetPersonalCardSelectLeftPop
-- Desc: 名片形象 - 数据选择 - 弃用
-- ---------------------------------------------------------------------------------
local UIWidgetPersonalCardSelectLeftPop = class("UIWidgetPersonalCardSelectLeftPop")
-- ---------------------------------------------------------------------------------
-- Data
-- ---------------------------------------------------------------------------------
local nKillBosskey = 10

local SHOWCARDDATA_KEY = {
    JueJingZhanChang = 1,
    JiangHuZiLi = 2,
    MingJianDaHui2V2 = 3,
    MingJianDaHui3V3 = 4,
    MingJianDaHui5V5 = 5,
    ShangDiRenShu = 6,
    ZuiJiaZhuGong = 7,
    ZhanJieDengJi = 8,
    ChongWuFenShu = 9,
    ShengWangDian = 10,
    JueShiQiYu = 11,
    PuTongQiYu = 12,
    ChengYi = 13,
    FaXing = 14,
    PiFeng = 15,
    GuaShiMiJian = 16,
    JiaYuanShouCangFen = 17,
    SiZhaiPiFu = 18,
    ShiLianZhiDi = 19,
    ZongShiTuZhi = 20,
    JiShangMiJingShouLing = 21,
    QianDaoCiShu = 22,
}

local SHOWCARDDATA_TYPE = {
    COOPERATION = 1, --协作
    AGAINST = 2, --对抗
    RELAX = 3, --休闲
    EXTERIOR = 4, --外观
    OTHER = 5, --其他
}

local DataModel = {}

function DataModel.Init()
    DataModel.tTriggerList = {}
end

function DataModel.GetTriggerAdv()
    if not g_pClientPlayer then return end
    local tAdventureList = Table_GetAdventure()
    DataModel.tTriggerList = {}
	for k, v in pairs(tAdventureList) do
        if v.dwStartID ~= 0 then
            local bTriFlag = g_pClientPlayer.GetAdventureFlag(v.dwStartID)
            if bTriFlag then
                DataModel.tTriggerList[v.dwID] = true
            end
        elseif v.nStartQuestID ~= 0 then
            local nAccQuest = g_pClientPlayer.GetQuestPhase(v.nStartQuestID)
            if nAccQuest > 0 then
                DataModel.tTriggerList[v.dwID] = true
            end
        end
	end
end

function DataModel.UnInit()
    DataModel.tTriggerList = {}
end

local DataGetModel = {
    [SHOWCARDDATA_KEY.JueJingZhanChang] = {
        szName = "绝境战场",
        fnApply = function()
            CareerData.ApplyBattleDataOfBattle()
        end,
    },
    [SHOWCARDDATA_KEY.JiangHuZiLi] = {
        szName = "江湖资历",
        fnGet = function() 
            if not g_pClientPlayer then return end
            return g_pClientPlayer.GetAchievementRecord()
        end,
    },
    [SHOWCARDDATA_KEY.MingJianDaHui2V2] = {
        szName = "名剑大会2V2",
        fnGet = function()
            if not g_pClientPlayer then return 0 end
            local tbArenaInfo = ArenaData.GetCorpsRoleInfo(g_pClientPlayer.dwID, ARENA_UI_TYPE.ARENA_2V2)
            return tbArenaInfo.nMatchLevel or 0
        end,
    },
    [SHOWCARDDATA_KEY.MingJianDaHui3V3] = {
        szName = "名剑大会3V3",
        fnGet = function()
            if not g_pClientPlayer then return 0 end
            local tbArenaInfo = ArenaData.GetCorpsRoleInfo(g_pClientPlayer.dwID, ARENA_UI_TYPE.ARENA_3V3)
            return tbArenaInfo.nMatchLevel or 0
        end,
    },
    [SHOWCARDDATA_KEY.MingJianDaHui5V5] = {
        szName = "名剑大会5V5",
        fnGet = function()
            if not g_pClientPlayer then return 0 end
            local tbArenaInfo = ArenaData.GetCorpsRoleInfo(g_pClientPlayer.dwID, ARENA_UI_TYPE.ARENA_5V5)
            return tbArenaInfo.nMatchLevel or 0
        end,
    },
    [SHOWCARDDATA_KEY.ShangDiRenShu] = {
        szName = "伤敌人数",
        fnGet = function() 
            if not g_pClientPlayer then return 0 end
            return g_pClientPlayer.dwKillCount
        end,
    },
    [SHOWCARDDATA_KEY.ZuiJiaZhuGong] = {
        szName = "最佳助攻",
        fnGet = function()
            if not g_pClientPlayer then return 0 end
            return g_pClientPlayer.dwBestAssistKilledCount
        end,
    },
    [SHOWCARDDATA_KEY.ZhanJieDengJi] = {
        szName = "战阶等级",
        fnGet = function()
            local szText = "无"
            local nWorldTitleLevel = On_CampGetWorldTitleLv() --"scripts/Include/UIscript/UIscript_Camp.lua"
            if nWorldTitleLevel then
                local szText = FormatString(g_tStrings.CAMP_TITLE_LEVEL, nWorldTitleLevel)
            end
            return szText
        end,
    },
    [SHOWCARDDATA_KEY.ChongWuFenShu] = {
        szName = "宠物分数",
        fnGet = function() 
            if not g_pClientPlayer then return 0 end
            local nPetScore = g_pClientPlayer.GetAcquiredFellowPetScore() or 0
            local nMedalScore = g_pClientPlayer.GetAcquiredFellowPetMedalScore() or 0
            local nNum = nPetScore + nMedalScore
            return nNum
        end,
    },
    [SHOWCARDDATA_KEY.ShengWangDian] = {
        szName = "声望点",
        fnGet = function()
            if not g_pClientPlayer then return 0 end
            return g_pClientPlayer.GetTotalReputation()
        end,
    },
    [SHOWCARDDATA_KEY.JueShiQiYu] = {
        szName = "绝世奇遇",
        fnGet = function()
            local tAdventureList = Table_GetAdventure()
            local nNum = 0
            for k, v in pairs(tAdventureList) do
                if v.nClassify == 2 then
                    if DataModel.tTriggerList[v.dwID] or (v.nRelation ~= 0 and DataModel.tTriggerList[v.nRelation]) then
                        if v.bPerfect then
                            nNum = nNum + 1
                        end
                    end
                end
            end
            return nNum
        end,
    },
    [SHOWCARDDATA_KEY.PuTongQiYu] = {
        szName = "普通奇遇",
        fnGet = function()
            local tAdventureList = Table_GetAdventure()
            local nNum = 0
            for k, v in pairs(tAdventureList) do
                if v.nClassify == 2 then
                    if DataModel.tTriggerList[v.dwID] or (v.nRelation ~= 0 and DataModel.tTriggerList[v.nRelation]) then
                        if not v.bPerfect then
                            nNum = nNum + 1
                        end
                    end
                end
            end
            return nNum
        end,
    },
    [SHOWCARDDATA_KEY.ChengYi] = {
        szName = "成衣",
        fnGet = function()
            if not g_pClientPlayer then return 0 end
            local tAllExterior = g_pClientPlayer.GetAllExterior()
            local hExteriorClient = GetExterior()
            local nHave = 0
            for _, tExterior in ipairs(tAllExterior) do
                local dwID = tExterior.dwExteriorID
                local tInfo = hExteriorClient.GetExteriorInfo(dwID)
                local tLine = Table_GetExteriorSet(tInfo.nSet)
                if tLine.nClass == 1 then
                    nHave = nHave + 1
                end
            end
            return nHave
        end,
    },
    [SHOWCARDDATA_KEY.FaXing] = {
        szName = "发型",
        fnGet = function()
            if not g_pClientPlayer then return 0 end
            return g_pClientPlayer.GetHairCount()
        end,
    },
    [SHOWCARDDATA_KEY.PiFeng] = {
        szName = "披风",
        fnGet = function()
            if not g_pClientPlayer then return 0 end
            local tList = g_pClientPlayer.GetAllPendent(5)
            return #tList
        end,
    },
    [SHOWCARDDATA_KEY.GuaShiMiJian] = {
        szName = "挂饰秘鉴",
        fnGet = function()
            CharacterPendantData.Init(1)
            return CharacterPendantData.tDLCInfo and  CharacterPendantData.tDLCInfo[0] and CharacterPendantData.tDLCInfo[0].dwHave or 0
        end,
    },
    [SHOWCARDDATA_KEY.JiaYuanShouCangFen] = {
        szName = "家园收藏分",
        fnGet = function()
            local nCollectScore = CollectionData.GetCollectScore()
            return FormatString(g_tStrings.MPNEY_TENTHOUSAND, nCollectScore)
        end,
    },
    [SHOWCARDDATA_KEY.SiZhaiPiFu] = {
        szName = "私宅皮肤",
        fnGet = function() 
            local pHomeMgr = GetHomelandMgr()
            if pHomeMgr then
                local tRetSkin = pHomeMgr.GetAllPrivateHomeSkin()
                return #tRetSkin
            else
                return 0
            end
        end,
    },
    [SHOWCARDDATA_KEY.ShiLianZhiDi] = {
        szName = "试炼之地",
        fnApply = function ()
            RemoteCallToServer("On_Get_Career_Trial_Maxlevel")
        end,
    },
    [SHOWCARDDATA_KEY.ZongShiTuZhi] = {
        szName = "总师徒值",
        fnGet = function() 
            if not g_pClientPlayer then return 0 end
            return g_pClientPlayer.nAcquiredMentorValue or 0
        end,
    },
    [SHOWCARDDATA_KEY.JiShangMiJingShouLing] = {
        szName = "击伤秘境首领",
        fnApply = function()
            if g_pClientPlayer then
                local sGlobalID = g_pClientPlayer.GetGlobalID()
                GetFellowshipRankClient().RequestFellowshipRankData(nKillBosskey, {sGlobalID})
            end
        end,
    },
    [SHOWCARDDATA_KEY.QianDaoCiShu] = {
        szName = "签到次数",
        fnGet = function() 
            if not g_pClientPlayer then return 0 end
            local EX_POINT_SIGN_DAY = 259
            return g_pClientPlayer.GetExtPoint(EX_POINT_SIGN_DAY) or 0
        end,
    }
}
-- ---------------------------------------------------------------------------------
-- UI
-- ---------------------------------------------------------------------------------

function UIWidgetPersonalCardSelectLeftPop:OnEnter(fnCallBack, dwKey)
    if not self.bInit then
        self:InitData()
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self.fnCallBack = fnCallBack
    self.dwChoiceKey = dwKey
    self.nType = 1
    self:UpdateData()
    self:RefreshData()
    self:UpdateInfo(self.nType)
end

function UIWidgetPersonalCardSelectLeftPop:OnExit()
    self.tShowCardList = nil
    self.tScript = nil
    self.bInit = false
    self:UnRegEvent()
    DataModel.UnInit()
end

function UIWidgetPersonalCardSelectLeftPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick , function()
        self:ChangeCurrentShowData()
        UIHelper.RemoveFromParent(self._rootNode)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeft, EventType.OnClick , function()
        self:ChangeCurrentShowData()
        UIHelper.RemoveFromParent(self._rootNode)
    end)

    UIHelper.BindUIEvent(self.TogQuality, EventType.OnClick , function()
        self.bShowFlitter = not self.bShowFlitter
        UIHelper.SetVisible(self.WidgetAnchorRepeatedTips, self.bShowFlitter)
    end)

    for index, tog in ipairs(self.tbTogSelect) do
        UIHelper.ToggleGroupAddToggle(self.TogGroupQuality, tog)
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(btn, bSelected)
            if not bSelected then return end
            self.nType = index
            self:UpdateInfo(self.nType)
        end)
    end
end

function UIWidgetPersonalCardSelectLeftPop:RegEvent()
    -- 绝境战场
    Event.Reg(self, "ON_SYNC_BF_ROLE_DATA", function(dwPlayerID, dwMapID, bUpdate, eType)
        local tInfo = GetBFRoleData(dwPlayerID, dwMapID, eType)
        if self.tShowCardList[SHOWCARDDATA_KEY.JueJingZhanChang] then
            self.tShowCardList[SHOWCARDDATA_KEY.JueJingZhanChang].nValue = tInfo[BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL]
        else
            local tData = {}
            tData.dwKey = SHOWCARDDATA_KEY.JueJingZhanChang
            tData.szName = DataGetModel[SHOWCARDDATA_KEY.JueJingZhanChang].szName
            tData.nValue = tInfo[BF_MAP_ROLE_INFO_TYPE.MATCH_LEVEL]
            self.tShowCardList[SHOWCARDDATA_KEY.JueJingZhanChang] = tData
        end
    end)

    -- 试炼之地
    Event.Reg(self, "Get_Career_Trial_Maxlevel", function(nlevel)
        if self.tShowCardList[SHOWCARDDATA_KEY.ShiLianZhiDi] then
            self.tShowCardList[SHOWCARDDATA_KEY.ShiLianZhiDi].nValue = nlevel
        else
            local tData = {}
            tData.dwKey = SHOWCARDDATA_KEY.ShiLianZhiDi
            tData.szName = DataGetModel[SHOWCARDDATA_KEY.ShiLianZhiDi].szName
            tData.nValue = nlevel
            self.tShowCardList[SHOWCARDDATA_KEY.ShiLianZhiDi] = tData
        end
    end)

    -- 击伤首领数量
    Event.Reg(self, "UpdateFellowshipRankData", function(arg0, arg1, arg2, arg3)
        if arg0 == nKillBosskey then
            if not g_pClientPlayer then
                return
            end
            local sGlobalID = g_pClientPlayer.GetGlobalID()
            local nTmpIndex, nKillBossNum = GetFellowshipRankClient().GetFellowshipRankDataValue(self.sGlobalID, nKillBosskey)
            if self.tShowCardList[SHOWCARDDATA_KEY.JiShangMiJingShouLing] then
                self.tShowCardList[SHOWCARDDATA_KEY.JiShangMiJingShouLing].nValue = nKillBossNum
            else
                local tData = {}
                tData.dwKey = SHOWCARDDATA_KEY.JiShangMiJingShouLing
                tData.szName = DataGetModel[SHOWCARDDATA_KEY.JiShangMiJingShouLing].szName
                tData.nValue = nKillBossNum
                self.tShowCardList[SHOWCARDDATA_KEY.JiShangMiJingShouLing] = tData
            end
        end
    end)
end

function UIWidgetPersonalCardSelectLeftPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓ 弃用 弃用
-- ----------------------------------------------------------
function UIWidgetPersonalCardSelectLeftPop:InitData()
    DataModel.Init()
    DataModel.GetTriggerAdv()
    for _, t in pairs (DataGetModel) do
        if t.fnApply then
            t.fnApply()
        end
    end
    self.tShowCardList = {}     -- 数据
    self.tScript = {}           -- cell的script
    self.nShowCardTime = nil    -- 加载cell的定时器
    self.dwChoiceKey = nil      -- 当前选中的数据的key
    self.nType = nil            -- 当前选中的类型
end

function UIWidgetPersonalCardSelectLeftPop:UpdateData()
    for key, tLine in pairs (DataGetModel) do
        local tData = {}
        tData.dwKey = key
        tData.szName = tLine.szName
        if tLine.fnGet then
            tData.nValue = tLine.fnGet()
        else
            tData.nValue = 0
        end
        self.tShowCardList[key] = tData
    end
end

function UIWidgetPersonalCardSelectLeftPop:RefreshData()
    for key, _ in pairs (self.tShowCardList) do
        if key == self.dwChoiceKey then
            self.tShowCardList[key].bChoice = true
        else
            self.tShowCardList[key].bChoice = false
        end
    end
end

function UIWidgetPersonalCardSelectLeftPop:UpdateInfo(nType)
    UIHelper.RemoveAllChildren(self.ScrollViewContentSelect)
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupEquip)

    self:UpdateInfoOfEmpty()
    self:UpdateInfoOfSingle(nType)
end

function UIWidgetPersonalCardSelectLeftPop:UpdateInfoOfEmpty()
    local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetContentSelectCell, self.ScrollViewContentSelect) assert(scriptCell)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, scriptCell.TogSkill)
    scriptCell:ShowEmpty()
    scriptCell:SetSelectedCallback(function(nKey) 
        self:UpdateSelected(nKey)
    end)
end

function UIWidgetPersonalCardSelectLeftPop:UpdateInfoOfSingle(nType)
    if self.nShowCardTime then
        Timer.DelTimer(self, self.nShowCardTime)
    end

    local loadIndex = 0
    local scriptIndex = 0
    local loadCount = #self.tShowCardList
    self.nShowCardTime = Timer.AddFrameCycle(self, 1, function ()
        for i = 1, 2, 1 do
            loadIndex = loadIndex + 1
            if nType == 1 or (nType ~= 1 or self.tShowCardList[loadIndex].nType == nType) then
                scriptIndex = scriptIndex + 1
                local scriptCell = self:Alloc(scriptIndex) assert(scriptCell)
                scriptCell:UpdateInfo(self.tShowCardList[loadIndex])
                scriptCell:SetSelectedCallback(function(nKey) 
                    self:UpdateSelected(nKey)
                end)
            end
            if loadIndex == loadCount then
                self:Clear(scriptIndex + 1)
                Timer.DelTimer(self, self.nShowCardTime)
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContentSelect)
                break
            end
        end
    end)
end

function UIWidgetPersonalCardSelectLeftPop:UpdateSelected(nKey)
    if not nKey or not self.tShowCardList then return end
    self.dwChoiceKey = nKey
    self:RefreshData()
    self:UpdateInfoOfSingle(self.nType)
    if self.fnCallBack then
        self.fnCallBack(self.tShowCardList[nKey])
    end
end

function UIWidgetPersonalCardSelectLeftPop:ChangeCurrentShowData()
    
end

-- ----------------------------------------------------------
-- cell alloc
-- ----------------------------------------------------------

function UIWidgetPersonalCardSelectLeftPop:Alloc(nIndex)
    if #self.tScript < nIndex then
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetContentSelectCell, self.ScrollViewContentSelect) assert(script)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, script.TogSkill)
        table.insert(self.tScript, script)
    end
    UIHelper.SetVisible(self.tScript[nIndex]._rootNode, true)
    return self.tScript[nIndex]
end

function UIWidgetPersonalCardSelectLeftPop:Clear(nIndex)
    assert(self.tScript)
    for i = nIndex, #self.tScript do
        UIHelper.SetVisible(self.tScript[i]._rootNode, false)
    end
end

return UIWidgetPersonalCardSelectLeftPop