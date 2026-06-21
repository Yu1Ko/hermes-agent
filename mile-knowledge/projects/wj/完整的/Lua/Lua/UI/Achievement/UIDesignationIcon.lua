-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIDesignationIcon
-- Date: 2023-02-27 15:38:58
-- Desc: 隐元秘鉴 - 称号前缀/后缀的widget
-- Prefab: WidgetDesignationIcon
-- ---------------------------------------------------------------------------------

local UIDesignationIcon = class("UIDesignationIcon")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIDesignationIcon:_LuaBindList()
    self.BtnShowDesignationTips = self.BtnShowDesignationTips --- 显示称号名称的tips
end

function UIDesignationIcon:OnEnter(dwAchievementID)
    self.dwAchievementID = dwAchievementID

    self.aAchievement    = Table_GetAchievement(dwAchievementID)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIDesignationIcon:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDesignationIcon:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnShowDesignationTips, EventType.OnClick, function()
        self:ShowTips()
    end)
end

function UIDesignationIcon:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDesignationIcon:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDesignationIcon:UpdateInfo()

end

function UIDesignationIcon:ShowTips()
    local _, _, _, nPrefix, nPostfix = Table_GetAchievementInfo(self.dwAchievementID)
    nPrefix, nPostfix                = nPrefix or 0, nPostfix or 0

    local szPrefix                   = ""
    local szPostfix                  = ""

    local aPrefix                    = Table_GetDesignationPrefixByID(nPrefix, UI_GetPlayerForceID())
    if aPrefix and aPrefix.szName and aPrefix.szName ~= "" then
        local info = GetDesignationPrefixInfo(nPrefix)
        if info and info.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
            --世界称号
            szPrefix = FormatString(g_tStrings.STR_ACHIEVEMENT_HR_TITLE_WORLD, UIHelper.GBKToUTF8(aPrefix.szName)) .. ""
        else
            --称号前缀
            szPrefix = FormatString(g_tStrings.STR_ACHIEVEMENT_HR_TITLE_PREFIX, UIHelper.GBKToUTF8(aPrefix.szName)) .. ""
        end
    end

    local aPostfix = g_tTable.Designation_Postfix:Search(nPostfix)
    if aPostfix and aPostfix.szName and aPostfix.szName ~= "" then
        --称号后缀
        szPostfix = FormatString(g_tStrings.STR_ACHIEVEMENT_HR_TITLE_POSTFIX, UIHelper.GBKToUTF8(aPostfix.szName)) .. ""
    end

    local szTips = ""
    if szPrefix ~= "" then
        szTips = szPrefix
    elseif szPostfix ~= "" then
        szTips = szPostfix
    end
    if szTips ~= "" then
        Timer.AddFrame(self, 1, function()
            TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self._rootNode,
                                         szTips
            )
        end)
    end
end

return UIDesignationIcon