-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetCharacterSkill
-- Date: 2024-11-26 11:05:53
-- Desc: WidgetCharacterSkill 门客培养 技能
-- ---------------------------------------------------------------------------------

local UIWidgetCharacterSkill = class("UIWidgetCharacterSkill")

function UIWidgetCharacterSkill:OnEnter(tSkillInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.tScriptSkill = {}
        for _, cell in ipairs(self.tWidgetSkill or {}) do
            local script = UIHelper.GetBindScript(cell)
            table.insert(self.tScriptSkill, script)
        end
    end

    self.tSkillInfo = tSkillInfo
    self:UpdateInfo()
end

function UIWidgetCharacterSkill:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCharacterSkill:BindUIEvent()
    
end

function UIWidgetCharacterSkill:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCharacterSkill:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetCharacterSkill:UpdateInfo()
    for nIndex, tInfo in ipairs(self.tSkillInfo or {}) do 
        if tInfo.nSkillLevel < 0 then
            UIHelper.SetVisible(self.tWidgetSkill[nIndex], false)
        else
            UIHelper.SetVisible(self.tWidgetSkill[nIndex], true)
            self.tScriptSkill[nIndex]:OnInit(tInfo.nSkillID, tInfo.nSkillLevel, tInfo.szSkillTip)
        end
    end
end

return UIWidgetCharacterSkill