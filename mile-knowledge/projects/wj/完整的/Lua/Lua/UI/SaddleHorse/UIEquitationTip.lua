-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIEquitationTip
-- Date: 2022-12-08 20:52:36
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIEquitationTip = class("UIEquitationTip")

function UIEquitationTip:OnInit(nIndex, nLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.nLevel = nLevel
    self:UpdateInfo()
end

function UIEquitationTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIEquitationTip:BindUIEvent()

end

function UIEquitationTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIEquitationTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIEquitationTip:UpdateInfo()
    self.tAllBasic, self.tAllMagic = Table_GetHorseAttrs()
    UIHelper.RemoveAllChildren(self.ScrollViewContent)
    local szName = ""
    if self.tAllMagic[self.nIndex] then
        for i = 1,9 do
            local line = Table_GetHorseTuJianAttr(self.nIndex,i)
            if not line then break end
            szName = UIHelper.GBKToUTF8(line.szName)
            local szChildTip = UIHelper.GBKToUTF8(line.szTip) or ""
            szChildTip = string.match(szChildTip,'\".-\"')
            szChildTip = string.gsub(szChildTip,'\"',"")
            if self.nLevel and self.nLevel == line.nLevel then
                UIHelper.AddPrefab(PREFAB_ID.WidgetGradeContent,self.ScrollViewContent,line.nLevel.."级（当前）",szChildTip)
            else
                UIHelper.AddPrefab(PREFAB_ID.WidgetGradeContent,self.ScrollViewContent,line.nLevel.."级",szChildTip)
            end

        end
    end
    UIHelper.ScrollViewDoLayout(self.ScrollViewContent)
    UIHelper.ScrollToTop(self.ScrollViewContent,0)
    UIHelper.SetString(self.LabelTitle,szName)
    self.ScrollViewContent:setTouchDownHideTips(false)
end


return UIEquitationTip