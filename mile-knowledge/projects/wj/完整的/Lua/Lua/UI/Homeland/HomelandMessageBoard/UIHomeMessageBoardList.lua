-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomeMessageBoardList
-- Date: 2024-01-09 14:31:44
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MAX_MESSAGE_NUM = 32
local UIHomeMessageBoardList = class("UIHomeMessageBoardList")

function UIHomeMessageBoardList:OnEnter(bIsHouseOwner)
    if not self.bInit then
        self.bIshouseOwner = bIsHouseOwner
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tMessage = {}
    self.scriptMessages = {}
end

function UIHomeMessageBoardList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomeMessageBoardList:BindUIEvent()
    UIHelper.SetVisible(self.BtnDelete, self.bIshouseOwner)
    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnHomeMessageBoardDeleteMsg, true)
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function ()
        for _, script in ipairs(self.scriptMessages) do
            script:SetSelected(false)
        end
        Event.Dispatch(EventType.OnHomeMessageBoardDeleteMsg, false)
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function ()
        local tips, tipsScript = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips
        , self.BtnHelp, TipsLayoutDir.BOTTOM_RIGHT, g_tStrings.STR_MESSAGEBOARD_TIPS)

        local x, y = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetOffset(-10, -10)
        tips:SetSize(x, y)
        tips:Update()
    end)
end

function UIHomeMessageBoardList:RegEvent()
    Event.Reg(self, EventType.OnHomeMessageBoardDeleteMsg, function (bEnterDeleteMode)
        UIHelper.SetVisible(self.BtnBack, bEnterDeleteMode)
        UIHelper.SetVisible(self.BtnDelete, not bEnterDeleteMode)
    end)
end

function UIHomeMessageBoardList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomeMessageBoardList:UpdateMessageList(tMessage)
    assert(tMessage)
    self.tMessage = tMessage
    self.scriptMessages = {}

    local bEmpty = true
    UIHelper.RemoveAllChildren(self.ScrollViewMessageList)
    for index, tbInfo in ipairs(self.tMessage) do
        local scriptMessage = UIHelper.AddPrefab(PREFAB_ID.WidgetMessageListItem, self.ScrollViewMessageList)
        scriptMessage:OnEnter(tbInfo, self.bIshouseOwner)
        table.insert(self.scriptMessages, scriptMessage)
        bEmpty = false
    end

    local szMsgNum = string.format(g_tStrings.STR_HOMELAND_MESSAGENUM, #self.tMessage, MAX_MESSAGE_NUM)
    UIHelper.SetString(self.LabelTItle, szMsgNum)
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMessageList)
end

function UIHomeMessageBoardList:GetAllSelectedMsg()
    local tbSelectedMsg = {}
    for _, script in ipairs(self.scriptMessages) do
        if script:GetSelected() and script.tbMessageInfo then
            table.insert(tbSelectedMsg, script.tbMessageInfo)
        end
    end
    return tbSelectedMsg
end

function UIHomeMessageBoardList:UpdateMessageLike(uLikeCount)
    UIHelper.SetString(self.LabelNum, self.GetPraiseNum(uLikeCount))
end

return UIHomeMessageBoardList