-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetCharacterAttrib
-- Date: 2024-11-26 10:55:04
-- Desc: WidgetCharacterAttrib 门客培养 属性
-- ---------------------------------------------------------------------------------

local UIWidgetCharacterAttrib = class("UIWidgetCharacterAttrib")

local FRAME_ICON = {
    [7] = "UIAtlas2_Activity_Winter_Character_2", --攻击力
    [8] = "UIAtlas2_Activity_Winter_Character_7", --闪避率
    [9] = "UIAtlas2_Activity_Winter_Character_3", --会心率
    [10] = "UIAtlas2_Activity_Winter_Character_5", --内功防御
    [11] = "UIAtlas2_Activity_Winter_Character_4", --外功防御
    [12] = "UIAtlas2_Activity_Winter_Character_6", --治疗量
    [13] = "UIAtlas2_Activity_Winter_Character_1", --最大气血
}

function UIWidgetCharacterAttrib:OnEnter(szAttrib, szValue, nFrame)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szAttrib = szAttrib
    self.szValue = szValue
    self.nFrame = nFrame
    
    self:UpdateInfo()
end

function UIWidgetCharacterAttrib:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCharacterAttrib:BindUIEvent()
    
end

function UIWidgetCharacterAttrib:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCharacterAttrib:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCharacterAttrib:UpdateInfo()
    UIHelper.SetString(self.LabelDetail, self.szAttrib)
    UIHelper.SetString(self.LabelAttrib, self.szValue)
    UIHelper.SetSpriteFrame(self.ImgIcon, FRAME_ICON[self.nFrame])
end


return UIWidgetCharacterAttrib