-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMatchSkill
-- Date: 2026-01-08 15:08:51
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMatchSkill = class("UIWidgetMatchSkill")

local MAX_ENERGY   = 20

local tbImgList = {
    blue = "UIAtlas2_Activity_Match_3_Character_Skill_img_YJH",
    red  = "UIAtlas2_Activity_Match_3_Character_Skill_img_BQ",
    purple = "UIAtlas2_Activity_Match_3_Character_Skill_img_JT",
    gold = "UIAtlas2_Activity_Match_3_Character_Skill_img_KYB"
}

local tbCellImgList = {
    gold = "UIAtlas2_Activity_Match_3_Match_3_Icon_Yuanbao",
    purple = "UIAtlas2_Activity_Match_3_Match_3_Icon_Huaban",
    blue = "UIAtlas2_Activity_Match_3_Match_3_Icon_Tangyuan",
    red = "UIAtlas2_Activity_Match_3_Match_3_Icon_Denglong"
}

local tbShoutInfo = {
    ["月嘉禾"] = {
        "呦！你的水平竟在本姑娘之上。", "不愧是我看重的人！"
    },
    ["康宴别"] = {
        "太棒了！你就是宵宵乐之王！", "哇！太厉害了！真的是完美！",
    },
    ["白鹊"] = {
        "你的宵宵乐技术，跟你的武功一样好！", "方才那招，神来之笔！"
    },
    ["姜棠"] = {
        "跟你搭档，赢麻了！", "今日你我运气皆是上佳。"
    }
}

local tbEffList = {
    ["月嘉禾"] = "Eff_YueJiaHe",
    ["康宴别"] =  "Eff_KangYanBie",
    ["白鹊"] =    "Eff_BaiQue",
    ["姜棠"] =    "Eff_JiangTang"
}

local tbProgressColor = {
    blue = cc.c3b(224, 222, 242),
    red  = cc.c3b(255, 161, 119),
    purple = cc.c3b(224, 206, 239),
    gold = cc.c3b(255, 211, 106)
}

function UIWidgetMatchSkill:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nEnergy = 0
end

function UIWidgetMatchSkill:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMatchSkill:BindUIEvent()
    
end

function UIWidgetMatchSkill:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMatchSkill:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMatchSkill:UpdateInfo(szColor, szHero, szSkillName)
    self.szColor = szColor
    self.szHero = szHero
    self.szSkillName = szSkillName

    UIHelper.SetString(self.HeroName, szHero)
    UIHelper.SetString(self.SkillName, szSkillName)
    UIHelper.SetSpriteFrame(self.ImgPlayer, tbImgList[szColor])
    UIHelper.SetSpriteFrame(self.ImgMatchIcon, tbCellImgList[szColor])
    UIHelper.SetColor(self.ProgressBarSkill, tbProgressColor[szColor])
end

function UIWidgetMatchSkill:UpdateEnergy(nEnergy)
    if not nEnergy or self.nEnergy == nEnergy then
        return
    end
    nEnergy = nEnergy or 0
    local nMaxEnergy = MAX_ENERGY
    self.nEnergy = nEnergy

    UIHelper.SetString(self.LabelNum, string.format("%d/%d", nEnergy, nMaxEnergy))
    UIHelper.SetProgressBarPercent(self.ProgressBarSkill, nEnergy / nMaxEnergy * 100)

    if not self.szHero or nEnergy == 0 then
        return
    end

    local Eff = self[tbEffList[self.szHero]]
    if not Eff then
        return
    end

    if not UIHelper.GetVisible(Eff) then
        UIHelper.SetVisible(Eff, true)
    else
        Eff:Play(0)
    end
end

function UIWidgetMatchSkill:ShowAutoShout()
    if not self.szHero then
        return
    end

    local tbShoutList = tbShoutInfo[self.szHero]
    if not tbShoutList then
        return
    end

    local nIndex = math.random(1, #tbShoutList)
    local szShout = tbShoutList[nIndex]
    UIHelper.SetString(self.LabelPop, szShout)
    UIHelper.SetVisible(self.WidgetPop, true)

    Timer.Add(self, 2, function ()
        UIHelper.SetVisible(self.WidgetPop, false)
    end)
end

return UIWidgetMatchSkill