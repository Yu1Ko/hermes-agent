local UIDungeonSkillDetail = class("UIDungeonSkillDetail")

local ImageBossSkillIcons = {
    "UIAtlas2_Dungeon_Dungeon01_img_bossskillIcon_TANK.png",
    "UIAtlas2_Dungeon_Dungeon01_img_bossskillIcon_Heal.png",
    "UIAtlas2_Dungeon_Dungeon01_img_bossskillIcon_Interrupt.png",
    "UIAtlas2_Dungeon_Dungeon01_img_bossskillIcon_DriveAway.png",
    "UIAtlas2_Dungeon_Dungeon01_img_bossskillIcon_AOE.png",
    "UIAtlas2_Dungeon_Dungeon01_img_bossskillIcon_CallName.png",
    "UIAtlas2_Dungeon_Dungeon01_img_bossskillIcon_TargetSwitch.png",
    "UIAtlas2_Dungeon_Dungeon01_img_bossskillIcon_Move.png",
    "UIAtlas2_Dungeon_Dungeon01_img_bossskillIcon_SpecialRule.png",
    "UIAtlas2_Dungeon_Dungeon01_img_bossskillIcon_QTE.png",
}

function UIDungeonSkillDetail:OnEnter(tSkill)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(tSkill)
end

function UIDungeonSkillDetail:OnExit()
    self.bInit = false
end

function UIDungeonSkillDetail:BindUIEvent()
end

function UIDungeonSkillDetail:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDungeonSkillDetail:UpdateInfo(tSkill)
    local colorIcon = cc.c3b(0xb6, 0xd4, 0xdc)
    local nIconType = tSkill.nIconType
    local tIcon = ImageBossSkillIcons[nIconType]
    UIHelper.SetSpriteFrame(self.ImageSkillIcon, tIcon)
    UIHelper.SetSpriteColor(self.ImageSkillIcon, colorIcon)
    local szSkillName = tSkill.szSkillName
    szSkillName = UIHelper.GBKToUTF8(szSkillName)
    local szDesc = tSkill.szDesc
    szDesc = UIHelper.GBKToUTF8(szDesc)
    szDesc = string.gsub(szDesc, " ", "")

    local szRichTextDetail = string.format(g_tStrings.Dungeon.RICHTEXT_SKILL_DETAIL, szSkillName, szDesc)
    UIHelper.SetRichText(self.RichTextState, szRichTextDetail)
    UIHelper.LayoutDoLayout(self.LayoutRoot)
end

return UIDungeonSkillDetail