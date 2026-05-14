-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIJiXinYuView
-- Date: 2024-05-16 15:32:08
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIJiXinYuView = class("UIJiXinYuView")

function UIJiXinYuView:OnEnter(nType, dwIndex, bWrite, szVowText, szVowName)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nType = nType
    self.dwIndex = dwIndex

    UIHelper.SetNodeSwallowTouches(self.BtnEditBoxTheme, false, true)

    if bWrite then
    else
        self:ReadWishes(szVowText, szVowName)
    end
end

function UIJiXinYuView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIJiXinYuView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function ()
        self:SendWriteWishes()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnEditBoxTheme, EventType.OnClick, function ()
        self.EditBoxCentre:openKeyboard()
        UIHelper.SetVisible(self.ScrollViewContent, false)
    end)

    UIHelper.RegisterEditBoxChanged(self.EditBoxTitle, function()
        self:UpdateEditBoxTitle()
    end)

    self.EditBoxCentre:registerScriptEditBoxHandler(function(szType, _editbox)
        if szType == "changed" then
            self:UpdateEditBoxText()
        elseif szType == "ended" then
            self:UpdateEditBoxTextEnd()
        end
    end)
end

function UIJiXinYuView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIJiXinYuView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIJiXinYuView:UpdateEditBoxTitle()
    local szTitle = UIHelper.GetString(self.EditBoxTitle) or ""
    szTitle = string.gsub(szTitle, "\n", "")
    szTitle = string.gsub(szTitle, "\r", "")

    local _, szTitle = GetStringCharCountAndTopChars(szTitle, 6)
    UIHelper.SetString(self.EditBoxTitle, szTitle)
end

function UIJiXinYuView:UpdateEditBoxText()
    local szContent = UIHelper.GetString(self.EditBoxCentre)
    local _, szContent = GetStringCharCountAndTopChars(szContent, 99)
    UIHelper.SetString(self.EditBoxCentre, szContent)
end

function UIJiXinYuView:UpdateEditBoxTextEnd()
    UIHelper.SetVisible(self.EditBoxCentre, false)
    UIHelper.SetVisible(self.ScrollViewContent, true)

    local szContent = UIHelper.GetString(self.EditBoxCentre)
    UIHelper.SetString(self.LabelContent, szContent)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UIJiXinYuView:SendWriteWishes()
    local szContent = UIHelper.GetString(self.EditBoxCentre)
    local szName = UIHelper.GetString(self.EditBoxTitle)
    if szName == "" then
        szName = g_tStrings.STR_WISHES_SIGN
    end

    if szContent == "" then
        TipsHelper.ShowNormalTip(g_tStrings.NO_WISHES_TIP)
    else
        RemoteCallToServer("On_VowTree_Request", self.nType, self.dwIndex, UIHelper.UTF8ToGBK(szContent), UIHelper.UTF8ToGBK(szName))
    end
end

function UIJiXinYuView:ReadWishes(szVowText, szVowName)
    UIHelper.SetVisible(self.BtnAccept, false)

    UIHelper.SetVisible(self.EditBoxCentre, false)
    UIHelper.SetVisible(self.EditBoxTitle, false)
    UIHelper.SetVisible(self.BtnEditBoxTheme, false)

    if szVowText then
        local _, szComment = TextFilterReplace(szVowText)
        UIHelper.SetString(self.LabelContent ,UIHelper.GBKToUTF8(szComment))
    end

    if szVowName then
        local _, szComment = TextFilterReplace(szVowName)
        UIHelper.SetString(self.LabelTitle ,UIHelper.GBKToUTF8(szComment))
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

return UIJiXinYuView