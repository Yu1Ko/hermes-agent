-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIReadMailView
-- Date: 2024-10-16 10:30:16
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIReadMailView = class("UIReadMailView")

function UIReadMailView:OnEnter(nMailID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nMailID = nMailID
    ReadMailData.Init(nMailID)
    self:UpdateInfo()
end

function UIReadMailView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIReadMailView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMain, EventType.OnClick, function()
        if self.nMailID then
            RemoteCallToServer("On_UIQuest_Accept", "CustomMail", self.nMailID)
        else
            RemoteCallToServer("On_UIQuest_Accept", "MasterLetter")
        end
        UIMgr.Close(self)
    end)
end

function UIReadMailView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIReadMailView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIReadMailView:UpdateInfo()
    local tbInfo = ReadMailData.GetMailInfo()
    if tbInfo then
        local szImgPath = string.format("UIAtlas2_Task_MasterMail02_ReadMailPanel_Logo1_%s", tbInfo.nLogoFrame)
        local szTitle = ReadMailData.EncodeString(UIHelper.GBKToUTF8(tbInfo.szTitle))
        local szName = ReadMailData.EncodeString(UIHelper.GBKToUTF8(tbInfo.szSignature))
        local szText = ReadMailData.EncodeString(UIHelper.GBKToUTF8(tbInfo.szText))
        UIHelper.SetSpriteFrame(self.ImgLogo, szImgPath)
        UIHelper.SetVisible(self.ImgLogo, tbInfo.nLogoFrame ~= -1)
        UIHelper.SetString(self.LabelTitle, szTitle)
        UIHelper.SetString(self.LabelName, szName)
        UIHelper.SetRichText(self.RichTextContent, "<color=#000000>"..szText.."</color>")
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    end
end


return UIReadMailView