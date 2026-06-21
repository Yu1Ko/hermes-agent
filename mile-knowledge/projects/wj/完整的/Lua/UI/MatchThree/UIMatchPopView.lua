-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMatchPopView
-- Date: 2026-01-07 16:31:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMatchPopView = class("UIMatchPopView")

function UIMatchPopView:OnEnter(bStart)
    self.bStart = bStart
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIMatchPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMatchPopView:BindUIEvent()
end

function UIMatchPopView:RegEvent()
    Event.Reg(self, EventType.OnRichTextOpenUrl, function(szUrl, node)
        szUrl = string.gsub(szUrl, "\\", "/")
        local szLinkEvent, szLinkArg = szUrl:match("(%w+)/(.*)")
        if szLinkEvent == "ItemLinkInfo" then
            local szType, szID = szLinkArg:match("(%d+)/(%d+)")
            local dwType       = tonumber(szType)
            local dwID         = tonumber(szID)

            TipsHelper.ShowItemTips(node, dwType, dwID)
        end
    end)
end

function UIMatchPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMatchPopView:UpdateStartInfo()
    UIHelper.SetVisible(self.BtnAgain, false)
    UIHelper.SetVisible(self.BtnSure, false)
    UIHelper.SetVisible(self.BtnCanel, false)
    UIHelper.SetVisible(self.BtnStart, true)
    UIHelper.SetVisible(self.BtnQuite, true)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.SetVisible(self.LabelStartTip, true)
    UIHelper.SetVisible(self.WidgetOver, false)

    local szItemIconPath = "Resource/icon/System/BookAndLetter/tome03"
    local szFrame = string.format("<img src='%s' width='%d' height='%d' type='0'/>", szItemIconPath, 49, 49)
    local szText = "<color=#744436>快来一局开心的宵宵乐吧！</c>\n<color=#744436>达到30000分可获得</c><color=#744436>称号<href=ItemLinkInfo\\5\\85240><color=#744436>【大神】" .. szFrame .. "</color></href></color>"
    UIHelper.SetRichText(self.LabelStartTip, szText)
    UIHelper.SetString(self.LabelTitle, "元宵宵宵乐")

    UIHelper.BindUIEvent(self.BtnQuite, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelMatch_3)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnStart, EventType.OnClick, function()
        Event.Dispatch("MatchThree_ReStartGame")
        UIMgr.Close(self)
    end)
end

function UIMatchPopView:UpdateAgainInfo()
    UIHelper.SetVisible(self.BtnAgain, false)
    UIHelper.SetVisible(self.BtnSure, true)
    UIHelper.SetVisible(self.BtnCanel, true)
    UIHelper.SetVisible(self.BtnStart, false)
    UIHelper.SetVisible(self.BtnQuite, false)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.SetVisible(self.LabelStartTip, false)
    UIHelper.SetVisible(self.WidgetOver, true)
    UIHelper.SetVisible(self.LabelRefresh, true)

    UIHelper.SetString(self.LabelRefresh, "是否重新开始游戏？")
    local nHistoryScore = MatchThreeData.GetHistoryScore() or 0
    local nCurScore = MatchThreeData.GetScore() or 0
    UIHelper.SetString(self.LabelScore, string.format("本局分数：%d", nCurScore))
    UIHelper.SetString(self.LabelHistoryScore, string.format("历史最高：%d", nHistoryScore))
    UIHelper.SetVisible(self.ImgNew, nCurScore > nHistoryScore)
    UIHelper.SetString(self.LabelTitle, "元宵宵宵乐")

    UIHelper.BindUIEvent(self.BtnCanel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function()
        MatchThreeData.SubmitScore()
        Event.Dispatch("MatchThree_ReStartGame")
        UIMgr.Close(self)
    end)
end

function UIMatchPopView:UpdateFinishInfo()
    UIHelper.SetVisible(self.BtnAgain, true)
    UIHelper.SetVisible(self.BtnSure, false)
    UIHelper.SetVisible(self.BtnCanel, true)
    UIHelper.SetVisible(self.BtnStart, false)
    UIHelper.SetVisible(self.BtnQuite, true)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.SetVisible(self.LabelStartTip, false)
    UIHelper.SetVisible(self.WidgetOver, true)
    UIHelper.SetVisible(self.LabelRefresh, true)

    UIHelper.SetString(self.LabelRefresh, "是否结算分数？")
    local nHistoryScore = MatchThreeData.GetHistoryScore() or 0
    local nCurScore = MatchThreeData.GetScore() or 0
    UIHelper.SetString(self.LabelScore, string.format("本局分数：%d", nCurScore))
    UIHelper.SetString(self.LabelHistoryScore, string.format("历史最高：%d", nHistoryScore))
    UIHelper.SetVisible(self.ImgNew, nCurScore > nHistoryScore)
    UIHelper.SetString(self.LabelTitle, "结算本局")

    UIHelper.BindUIEvent(self.BtnCanel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAgain, EventType.OnClick, function()
        MatchThreeData.SubmitScore()
        Event.Dispatch("MatchThree_ReStartGame")
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnQuite, EventType.OnClick, function()
        MatchThreeData.SubmitScore()
        UIMgr.Close(VIEW_ID.PanelMatch_3)
        UIMgr.Close(self)
    end)
end

function UIMatchPopView:UpdateEndInfo()
    UIHelper.SetVisible(self.BtnAgain, true)
    UIHelper.SetVisible(self.BtnSure, false)
    UIHelper.SetVisible(self.BtnCanel, false)
    UIHelper.SetVisible(self.BtnStart, false)
    UIHelper.SetVisible(self.BtnQuite, true)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
    UIHelper.SetVisible(self.LabelStartTip, false)
    UIHelper.SetVisible(self.WidgetOver, true)
    UIHelper.SetVisible(self.LabelRefresh, true)

    UIHelper.SetString(self.LabelRefresh, "是否重新开始游戏？")
    local nHistoryScore = MatchThreeData.GetHistoryScore() or 0
    local nCurScore = MatchThreeData.GetScore() or 0
    UIHelper.SetString(self.LabelScore, string.format("本局分数：%d", nCurScore))
    UIHelper.SetString(self.LabelHistoryScore, string.format("历史最高：%d", nHistoryScore))
    UIHelper.SetVisible(self.ImgNew, nCurScore > nHistoryScore)
    UIHelper.SetString(self.LabelTitle, "步数耗尽")

    UIHelper.BindUIEvent(self.BtnQuite, EventType.OnClick, function()
        UIMgr.Close(VIEW_ID.PanelMatch_3)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAgain, EventType.OnClick, function()
        Event.Dispatch("MatchThree_ReStartGame")
        UIMgr.Close(self)
    end)
end


return UIMatchPopView