-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWdigetSchool
-- Date: 2023-05-10 17:06:18
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWdigetSchool = class("UIWdigetSchool")


function UIWdigetSchool:OnEnter(tbKungfuID, toggleGroup, scriptViewCreateRole, tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbKungfuID = tbKungfuID
    self.toggleGroup = toggleGroup
    self.scriptViewCreateRole = scriptViewCreateRole
    self.tbData = tbData or {}
    self:UpdateInfo()
end

function UIWdigetSchool:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWdigetSchool:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSchoolL, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.scriptViewCreateRole:SelectSchool(self.tbKungfuID[1],toggle)
            if not self.scriptViewCreateRole.bIsStartPlayVideo then
                self:ScrollToPercent(self.TogSchoolL)
            end
        end
    end)

    UIHelper.BindUIEvent(self.TogSchoolR, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.scriptViewCreateRole:SelectSchool(self.tbKungfuID[2],toggle)
            if not self.scriptViewCreateRole.bIsStartPlayVideo then
                self:ScrollToPercent(self.TogSchoolR)
            end
        end
    end)
end

function UIWdigetSchool:ScrollToPercent(node)
    if not UIHelper.IsPreviewItemInView(self.scriptViewCreateRole.ScrollViewSchoolSelect, node) then
        UIHelper.ScrollLocateToPreviewItem(self.scriptViewCreateRole.ScrollViewSchoolSelect, node, Locate.TO_BOTTOM, 0)
    end

end

function UIWdigetSchool:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWdigetSchool:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWdigetSchool:SelectSchool(nKungFuID)
    self:UpdateSchoolState(nKungFuID)
    UIHelper.ScrollLocateToPreviewItem(self.scriptViewCreateRole.ScrollViewSchoolSelect, self._rootNode, Locate.TO_TOP, 0)
end

function UIWdigetSchool:UpdateSchoolState(nKungFuID)
    if self.tbKungfuID[1] == nKungFuID then
        UIHelper.SetToggleGroupSelectedToggle(self.toggleGroup, self.TogSchoolL)
        self.scriptViewCreateRole:SelectSchool(self.tbKungfuID[1])
    elseif self.tbKungfuID[2] == nKungFuID then
        UIHelper.SetToggleGroupSelectedToggle(self.toggleGroup, self.TogSchoolR)
        self.scriptViewCreateRole:SelectSchool(self.tbKungfuID[2])
    end
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWdigetSchool:UpdateInfo()
    UIHelper.ToggleGroupAddToggle(self.toggleGroup, self.TogSchoolL)
    UIHelper.ToggleGroupAddToggle(self.toggleGroup, self.TogSchoolR)
    UIHelper.SetVisible(self.TogSchoolL, #self.tbKungfuID >= 1)
    UIHelper.SetVisible(self.TogSchoolR, #self.tbKungfuID >= 2)

    local LoginRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
    UIHelper.SetSpriteFrame(self.ImgNormalFu, PlayerKungfuID2SchoolImg[self.tbKungfuID[1]])
    UIHelper.SetVisible(self.ImgHot, LoginRole.IsHotSchool(self.tbKungfuID[1]))
    UIHelper.SetSpriteFrame(self.ImgSelectSchoolFu, PlayerKungfuID2SchoolImg_Select[self.tbKungfuID[1]])
    UIHelper.SetSpriteFrame(self.ImgNormal, PlayerKungfuID2SchoolImg[self.tbKungfuID[2]])
    UIHelper.SetVisible(self.ImgHotR, LoginRole.IsHotSchool(self.tbKungfuID[2]))
    UIHelper.SetSpriteFrame(self.ImgSelectSchool, PlayerKungfuID2SchoolImg_Select[self.tbKungfuID[2]])

    UIHelper.SetString(self.LabelName, PlayerKungfuID2SchoolName[self.tbKungfuID[1]])
    UIHelper.SetString(self.LabelNameR, PlayerKungfuID2SchoolName[self.tbKungfuID[2]])

    self:UpdateState() --初始化
end

function UIWdigetSchool:UpdateState()
    self:UpdateSigleTogState(self.ImgHighlightL, self.tbData[1])
    if #self.tbKungfuID >= 2 then
        self:UpdateSigleTogState(self.ImgHighlightR, self.tbData[2])
    end
end

function UIWdigetSchool:UpdateSigleTogState(ImgHighlight, tData)
    UIHelper.SetVisible(ImgHighlight, tData.bHighLight)
end


return UIWdigetSchool