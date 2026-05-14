-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSchoolStoryLabelTips
-- Date: 2024-05-15 17:44:15
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIWidgetSchoolStoryLabelTips = class("UIWidgetSchoolStoryLabelTips")

function UIWidgetSchoolStoryLabelTips:OnEnter(nForceID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
    self.nForceID = nForceID
    self:UpdateInfo()
end

function UIWidgetSchoolStoryLabelTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSchoolStoryLabelTips:BindUIEvent()
    
end

function UIWidgetSchoolStoryLabelTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSchoolStoryLabelTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSchoolStoryLabelTips:UpdateInfo()

    local szName = PlayerKungfuID2SchoolName[self.nForceID]
    local tbRouteParam = self.moduleRole.GetCreateRoleParam(self.nForceID)
    local szContent = UIHelper.GBKToUTF8(tbRouteParam["szNote"])
    local nLineCount = self:GetLineCount(szContent)
    local bUseScrollView = nLineCount > 13
    szContent = string.gsub(szContent, "\\n", "\n")


    local szImgSchool = PlayerKungfuID2SchoolStoryTip[self.nForceID]
    local szImgPoem = PlayerKungfuID2SchoolImgPoem[self.nForceID]
    UIHelper.SetSpriteFrame(self.ImgSchool, szImgSchool)
    UIHelper.SetSpriteFrame(self.ImgPoem, szImgPoem)

    if bUseScrollView then
        UIHelper.SetRichText(self.LabelTips2, szContent)
        UIHelper.SetRichText(self.LabelTittle2, szName)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
    else
        UIHelper.SetRichText(self.LabelTips, szContent)
        UIHelper.SetRichText(self.LabelTittle, szName)
    end

    UIHelper.SetVisible(self.WidgetSchoolStoryLabelTips_Scroll, bUseScrollView)
    UIHelper.SetVisible(self.WidgetNoScroll, not bUseScrollView)

    UIHelper.SetTouchDownHideTips(self.ScrollView, false)
    UIHelper.SetTouchDownHideTips(self.BtnEmpty, false)

    UIHelper.SetSwallowTouches(self.BtnEmpty, true)
    UIHelper.SetTouchEnabled(self._rootNode , true)
end

function UIWidgetSchoolStoryLabelTips:GetLineCount(szContent)
    local tbText = string.split(szContent, "\\n")
    local nLine = 0
    for nIndex, szText in ipairs(tbText) do
        if szText ~= "" then
            nLine = nLine + math.ceil(UIHelper.GetUtf8Width(szText, 26) / UIHelper.GetWidth(self.LabelTips))
        else
            nLine = nLine + 1
        end
    end
    return nLine
end

return UIWidgetSchoolStoryLabelTips