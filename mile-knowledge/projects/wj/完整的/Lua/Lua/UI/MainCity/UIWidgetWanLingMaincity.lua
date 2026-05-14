-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetWanLingMaincity
-- Date: 2025-08-13 15:13:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetWanLingMaincity = class("UIWidgetWanLingMaincity")

local FIRST_SUMMON_SKILLID = 35695
local MONSTER_CLASS_NUM = 6
local SUMMON_CD = 2694

local tbMonsterImgList = {
    [5] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_zj",
    [6] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_zs",
    [8] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_fx",
    [9] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_rd",
    [7] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_qg",
    [13] = "UIAtlas2_SkillDX_SpecialSkill_WanLing_kz",
}

local function IsFirstSummonBar(arg0)
	return arg0 == FIRST_SUMMON_SKILLID
end

function UIWidgetWanLingMaincity:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateSummonBar()
end

function UIWidgetWanLingMaincity:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetWanLingMaincity:BindUIEvent()
end

function UIWidgetWanLingMaincity:RegEvent()
    Event.Reg(self, "SKILL_UPDATE", function(arg0)
        if IsFirstSummonBar(arg0) then
            self:UpdateSummonBar()
        end
    end)

    Event.Reg(self, "UPDATE_SELECT_BEAST_PET", function ()
        self:UpdateNextMonster()
        self:UpdateNextList(self.tNextMonster)
    end)
end

function UIWidgetWanLingMaincity:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------


function UIWidgetWanLingMaincity:Init()
    local player = GetClientPlayer()
    if not player then
        return
    end
    
    self.tNextMonster = {}
    self.tSelectedMonster = player.GetSelectBeastPet()
    self:UpdateNextMonster()
end

function UIWidgetWanLingMaincity:UpdateNextMonster()
    local player = GetClientPlayer()
    if not player then
        return
    end

    self.tSelectedMonster = player.GetSelectBeastPet()
    --next three
    local tNextMonster = {}
    local nNextIndex = player.nNextBeastPetIndex
    if nNextIndex then
        for i = 0, 2 do
            local tMonster = self.tSelectedMonster[(nNextIndex + i - 1) % MONSTER_CLASS_NUM + 1]
            table.insert(tNextMonster, tMonster)
        end
    end
    self.tNextMonster = tNextMonster
end

function UIWidgetWanLingMaincity:UpdateSummonBar()
    local hPlayer = GetClientPlayer()
	if not hPlayer then 
		return 
	end

    if hPlayer.GetSkillLevel(FIRST_SUMMON_SKILLID) >= 1 then
        self:Init()
        self:UpdateNextList(self.tNextMonster)
    end
end

local function CheckPlayerState()
    if IsInFight() then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_CAN_NOT_OPERATE_IN_FIGHT)
        OutputMessage("MSG_SYS", g_tStrings.STR_CAN_NOT_OPERATE_IN_FIGHT)
        return false
    end
    return true
end

function UIWidgetWanLingMaincity:UpdateNextList(tNextMonster)
    if not tNextMonster or table.is_empty(tNextMonster) or table.get_len(tNextMonster) ~= 3 then
        return
    end

    for i, v in ipairs(self.tbWidgetList) do
        local tNext = tNextMonster[i]
        if tNext then
            local tUIInfo = Table_GetWLBeastClassByID(tNext.dwBeastPetType)
            if tUIInfo then
                local szIconPath = tUIInfo.szPath
                local nFrame = tUIInfo.nFrame
                local dwBeastPetType = tNext.dwBeastPetType
                local tbScript = UIHelper.GetBindScript(v)
                if tbScript then
                    UIHelper.SetSpriteFrame(tbScript.ImgSkill, tbMonsterImgList[nFrame])
                    UIHelper.BindUIEvent(tbScript.BtnSkill, EventType.OnClick, function ()
                        if CheckPlayerState() then
                            local tbScript = UIMgr.GetViewScript(VIEW_ID.PanelWanLingAnimalEditPop)
                            if tbScript then
                                tbScript:OnEnter(dwBeastPetType)
                            else
                                UIMgr.Open(VIEW_ID.PanelWanLingAnimalEditPop, dwBeastPetType)
                            end
                        end
                    end)
                end
            end
        end
    end
end


return UIWidgetWanLingMaincity