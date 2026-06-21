-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSkillTable
-- Date: 2024-01-01 19:34:49
-- Desc: 八荒主界面技能列表
-- ---------------------------------------------------------------------------------
local Skill_Table_Type = {
    Occult_Arts = 1,--秘术
    Arcane_Skill = 2,--秘技
    Lost_Knowledge = 3,--绝学
}

local GetTypeDataFunc = {
    [Skill_Table_Type.Occult_Arts] = function() return BahuangData.GetPassiveSkillRemoteData() end,
    [Skill_Table_Type.Arcane_Skill] = function() return BahuangData.GetActiveSkillRemoteData() end,
    [Skill_Table_Type.Lost_Knowledge] = function() return BahuangData.GetUltimateSkillRemoteData() end,
} 

local Skill_Table_Sort_Type = {
    GetTime_AscendingOrder = 1,--获取次数升序
    GetTime_DescendingOrder = 2,--获取次数降序
    ClearanceTime_AscendingOrder = 3,--通关次数升序
    ClearanceTime_DescendingOrder = 4,--通关次数降序
}

local SortFunc = {
    [Skill_Table_Sort_Type.GetTime_AscendingOrder] = function(l, r) return l.nGet < r.nGet end,
    [Skill_Table_Sort_Type.GetTime_DescendingOrder] = function(l, r) return l.nGet > r.nGet end,
    [Skill_Table_Sort_Type.ClearanceTime_AscendingOrder] = function(l, r) return l.nClear < r.nClear end,
    [Skill_Table_Sort_Type.ClearanceTime_DescendingOrder] = function(l, r) return l.nClear > r.nClear end,
} 

local UIWidgetSkillTable = class("UIWidgetSkillTable")

function UIWidgetSkillTable:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init()
end

function UIWidgetSkillTable:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.cellPrefabPool then self.cellPrefabPool:Dispose() end
    self.cellPrefabPool = nil
end

function UIWidgetSkillTable:BindUIEvent()
    UIHelper.BindUIEvent(self.Tog01, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:SetType(Skill_Table_Type.Occult_Arts)
        end
    end)

    UIHelper.BindUIEvent(self.Tog02, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:SetType(Skill_Table_Type.Arcane_Skill)
        end
    end)

    UIHelper.BindUIEvent(self.Tog03, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:SetType(Skill_Table_Type.Lost_Knowledge)
        end
    end)

    UIHelper.BindUIEvent(self.BtnObtainNum, EventType.OnClick, function()

        self.bGetTimeAscendingOrder = not self.bGetTimeAscendingOrder

        local nType = self.bGetTimeAscendingOrder and Skill_Table_Sort_Type.GetTime_AscendingOrder 
        or Skill_Table_Sort_Type.GetTime_DescendingOrder
        self:SetSortType(nType)
    end)

    UIHelper.BindUIEvent(self.BtnSuccessNum, EventType.OnClick, function()

        self.bClearanceTimeAscendingOrder = not self.bClearanceTimeAscendingOrder

        local nType = self.bClearanceTimeAscendingOrder and Skill_Table_Sort_Type.ClearanceTime_AscendingOrder 
        or Skill_Table_Sort_Type.ClearanceTime_DescendingOrder
        self:SetSortType(nType)
    end)
end

function UIWidgetSkillTable:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSkillTable:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetSkillTable:Init()
    self.bClearanceTimeAscendingOrder = false
    self.bGetTimeAscendingOrder = false
    self.cellPrefabPool = self.cellPrefabPool or PrefabPool.New(PREFAB_ID.WidgetBahungSkillTableCell, 40)

    UIHelper.SetSelected(self.Tog01, true)
    self:SetSortType(Skill_Table_Sort_Type.GetTime_DescendingOrder)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetSkillTable:RemoveAllChildren()

    if self.tbCellNode then
        for nIndex, node in ipairs(self.tbCellNode) do
            self.cellPrefabPool:Recycle(node)
        end
    end
    self.tbCellNode = {}
end

--1、秘术 2、秘技 3、绝学
function UIWidgetSkillTable:UpdateSkillList()
    if not self.nType or not self.nSortType then return end
    local tbData = GetTypeDataFunc[self.nType]()
    local func = SortFunc[self.nSortType]
    table.sort(tbData.tSkillList, function(l, r)
        return func(l, r)
    end)

    -- local bGetTimeAscendingOrder = self.bGetTimeAscendingOrder
    local tbSKillList = tbData.tSkillList
    self:RemoveAllChildren()
    for nIndex, tbSKillInfo in ipairs(tbSKillList) do
        -- UIHelper.AddPrefab(PREFAB_ID.WidgetBahungSkillTableCell, self.ScrollViewSkillTable, tbSKillInfo)
        local node = self.cellPrefabPool:Allocate(self.ScrollViewSkillTable, tbSKillInfo)
        table.insert(self.tbCellNode, node)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillTable)

    UIHelper.SetString(self.LabelCollectNum, tbData.nCollet.."/"..tbData.nTotal)

    UIHelper.SetOpacity(self.ImgUp, self.nSortType == Skill_Table_Sort_Type.GetTime_AscendingOrder and 255 or 70)
    UIHelper.SetOpacity(self.ImgDown, self.nSortType == Skill_Table_Sort_Type.GetTime_DescendingOrder and 255 or 70)
    UIHelper.SetOpacity(self.ImgUp1, self.nSortType == Skill_Table_Sort_Type.ClearanceTime_AscendingOrder and 255 or 70)
    UIHelper.SetOpacity(self.ImgDown1, self.nSortType == Skill_Table_Sort_Type.ClearanceTime_DescendingOrder and 255 or 70)
end


function UIWidgetSkillTable:SetSortType(nSortType)
    self.nSortType = nSortType
    self:UpdateSkillList()
end

function UIWidgetSkillTable:SetType(nType)
    if self.nType == nType then return end
    self.nType = nType
    self:UpdateSkillList()
end


return UIWidgetSkillTable