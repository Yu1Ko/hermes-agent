-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFactionMessagePopView
-- Date: 2024-09-04 10:47:17
-- Desc: 帮会群密 - 有权限时展示的界面
-- Prefab: PanelFactionMessagePop
-- ---------------------------------------------------------------------------------

---@class UIFactionMessagePopView
local UIFactionMessagePopView = class("UIFactionMessagePopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFactionMessagePopView:_LuaBindList()
    self.BtnClose                                   = self.BtnClose --- 关闭界面

    self.EditBoxMessage                             = self.EditBoxMessage --- 消息编辑框

    self.TogSendViaWhisperChannel                   = self.TogSendViaWhisperChannel --- 通过密聊消息发送的toggle
    self.ToggleWhisperTypeOnlineMembers             = self.ToggleWhisperTypeOnlineMembers --- 仅发送给在线帮众的toggle
    self.ToggleWhisperTypeMembersInCurrentMap       = self.ToggleWhisperTypeMembersInCurrentMap --- 仅发送给当前地图帮众的toggle
    self.ToggleWhisperTypeMembersInOtherMap         = self.ToggleWhisperTypeMembersInOtherMap --- 仅发送给其他地图帮众的toggle

    self.TogSendViaTongChannel                      = self.TogSendViaTongChannel --- 通过帮会频道发送的toggle
    self.ToggleTongMsgCycle                         = self.ToggleTongMsgCycle --- 每30秒循环发送帮会消息的toggle
    self.ToggleStopTongMsgThenRaidFull              = self.ToggleStopTongMsgThenRaidFull --- 团队满员停止发送帮会消息的toggle

    self.ToggleShieldTongWhisperInThisLoginDuration = self.ToggleShieldTongWhisperInThisLoginDuration --- 本次登录期间屏蔽帮会群里消息的toggle

    self.BtnConfirm                                 = self.BtnConfirm --- 确认发送信息的按钮
    self.LabelConfirm                               = self.LabelConfirm --- 确认发送信息的按钮的label

    self.Layout30SecCounting                        = self.Layout30SecCounting --- 循环发送倒计时的layout
    self.LabelCounting                              = self.LabelCounting --- 循环发送倒计时

    self.LabelHistoryCount                          = self.LabelHistoryCount --- 历史消息数目

    self.BtnHistoryMessage                          = self.BtnHistoryMessage --- 显示/隐藏历史消息列表 的按钮
    self.ImgHistoryMessageDownTypeFilter            = self.ImgHistoryMessageDownTypeFilter --- 历史消息下拉状态的标记图片
    self.WidgetHistoryMessageList                   = self.WidgetHistoryMessageList --- 历史消息列表组件
    self.BtnHideHistoryMessageList                  = self.BtnHideHistoryMessageList --- 隐藏历史消息列表组件的按钮
    self.ScrollViewHistoryMessageList               = self.ScrollViewHistoryMessageList --- 历史消息列表的scroll view
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIFactionMessagePopView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIFactionMessagePopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    Timer.AddCycle(self, 0.1, function()
        self:UpdateTongMsgCycleTime()
    end)
end

function UIFactionMessagePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFactionMessagePopView:BindUIEvent()
    local tTogWhisperTypeList = {
        [JX_TongWhisper.WHISPER_TYPE.OnlineMembers] = self.ToggleWhisperTypeOnlineMembers,
        [JX_TongWhisper.WHISPER_TYPE.MembersInCurrentMap] = self.ToggleWhisperTypeMembersInCurrentMap,
        [JX_TongWhisper.WHISPER_TYPE.MembersInOtherMap] = self.ToggleWhisperTypeMembersInOtherMap,
    }
    for nType, tog in pairs(tTogWhisperTypeList) do
        UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.TongWhisperType)

        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            JX_TongWhisper.nWhisperType = nType
        end)
    end
    for nType, tog in pairs(tTogWhisperTypeList) do
        if nType == JX_TongWhisper.nWhisperType then
            UIHelper.SetSelected(tog, true)
            break
        end
    end

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogSendViaWhisperChannel, EventType.OnSelectChanged, function(_, selected)
        JX_TongWhisper.bWhisperAndWhisper = selected
    end)

    UIHelper.BindUIEvent(self.TogSendViaTongChannel, EventType.OnSelectChanged, function(_, selected)
        JX_TongWhisper.bWhisperAndTong = selected

        self:UpdateTongChannelSubOptions()
    end)

    UIHelper.BindUIEvent(self.ToggleTongMsgCycle, EventType.OnSelectChanged, function(_, selected)
        JX_TongWhisper.bTongMsgCycle = selected

        self:UpdateTongChannelSubOptions()

        --- 取消勾选【30秒循环发送】时，尝试停止循环发送
        if not JX_TongWhisper.bTongMsgCycle then
            JX_TongWhisper.SendTongWhisperCycle(false)
        end
    end)

    UIHelper.BindUIEvent(self.ToggleStopTongMsgThenRaidFull, EventType.OnSelectChanged, function(_, selected)
        JX_TongWhisper.bWhisperTeamFull = selected
    end)

    UIHelper.BindUIEvent(self.ToggleShieldTongWhisperInThisLoginDuration, EventType.OnSelectChanged, function(_, selected)
        JX_TongWhisper.bWhisperQuiet = selected
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        self:SendTongWhisper()
    end)
    
    UIHelper.BindUIEvent(self.BtnHistoryMessage, EventType.OnClick, function()
        if #JX_TongWhisper.GetWhisperHistory() == 0 then
            TipsHelper.ShowNormalTip(UIHelper.GBKToUTF8(JX.LoadLangPack["not find whisper history"]))
            return
        end
        
        local bNewVisible = not UIHelper.GetVisible(self.WidgetHistoryMessageList)
        
        self:SetHistoryMessageListVisible(bNewVisible)
    end)
    
    UIHelper.BindUIEvent(self.BtnHideHistoryMessageList, EventType.OnClick, function()
        self:SetHistoryMessageListVisible(false)
    end)
end

function UIFactionMessagePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "TongWhisperCycleStateChanged", function()
        UIHelper.SetVisible(self.Layout30SecCounting, JX_TongWhisper.IsTongMsgCycleRunning())
    end)

    Event.Reg(self, "TongWhisperHistoryChanged", function()
        self:UpdateHistoryInfo()
    end)
end

function UIFactionMessagePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFactionMessagePopView:UpdateInfo()
    UIHelper.SetSelected(self.TogSendViaWhisperChannel, JX_TongWhisper.bWhisperAndWhisper)

    UIHelper.SetSelected(self.TogSendViaTongChannel, JX_TongWhisper.bWhisperAndTong)
    UIHelper.SetSelected(self.ToggleTongMsgCycle, JX_TongWhisper.bTongMsgCycle)
    UIHelper.SetSelected(self.ToggleStopTongMsgThenRaidFull, JX_TongWhisper.bWhisperTeamFull)

    UIHelper.SetSelected(self.ToggleShieldTongWhisperInThisLoginDuration, JX_TongWhisper.bWhisperQuiet)

    UIHelper.SetVisible(self.Layout30SecCounting, JX_TongWhisper.IsTongMsgCycleRunning())

    if JX_TongWhisper.IsTongMsgCycleRunning() then
        UIHelper.SetString(self.EditBoxMessage, JX_TongWhisper.GetTongMsgCycleMessage())
    end

    self:UpdateHistoryInfo()
end

local function _setToggleEnable(toggle, bEnable)
    UIHelper.SetEnable(toggle, bEnable)
    UIHelper.SetNodeGray(toggle, not bEnable, true)
end

function UIFactionMessagePopView:UpdateTongChannelSubOptions()
    --- 仅当启用帮会频道时，循环发送才可以操作
    local bEnableTongMsgCycle            = JX_TongWhisper.bWhisperAndTong
    --- 仅当启用帮会频道和循环发送时，满员取消才可以操作
    local bEnableStopTongMsgThenRaidFull = JX_TongWhisper.bWhisperAndTong and JX_TongWhisper.bTongMsgCycle

    _setToggleEnable(self.ToggleTongMsgCycle, bEnableTongMsgCycle)
    _setToggleEnable(self.ToggleStopTongMsgThenRaidFull, bEnableStopTongMsgThenRaidFull)
end

function UIFactionMessagePopView:SendTongWhisper()
    local szEditText     = UIHelper.GetString(self.EditBoxMessage)
    local nTongWsType    = JX_TongWhisper.nWhisperType
    local uiBtnSend      = self.BtnConfirm
    local uiLabelBtnSend = self.LabelConfirm

    JX_TongWhisper.SendTongWhisper(szEditText, nTongWsType, uiBtnSend, uiLabelBtnSend)
end

function UIFactionMessagePopView:UpdateTongMsgCycleTime()
    if not JX_TongWhisper.IsTongMsgCycleRunning() then
        return
    end
    
    local nReiningTime = (JX_TongWhisper.nNextTongMsgCycleSendTickCount - GetTickCount()) / 1000
    local nNextSendRemainingTime = math.max(math.ceil(nReiningTime), 0)
    UIHelper.SetString(self.LabelCounting, string.format("%d秒", nNextSendRemainingTime))
end

function UIFactionMessagePopView:UpdateHistoryInfo()
    local nCount = #JX_TongWhisper.GetWhisperHistory()
    UIHelper.SetString(self.LabelHistoryCount, string.format("(%d/20)", nCount))
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelHistoryCount))
    
    UIHelper.RemoveAllChildren(self.ScrollViewHistoryMessageList)
    
    local tHistoryList = JX_TongWhisper.GetWhisperHistory()
    for _, szHistory in ipairs(tHistoryList) do
        ---@see UIHistoryMessageCell
        UIMgr.AddPrefab(PREFAB_ID.WidgetHistoryMessageCell, self.ScrollViewHistoryMessageList, szHistory, self)
    end
    
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHistoryMessageList)
end

function UIFactionMessagePopView:SetHistoryMessageListVisible(bVisible)
    local nImgRotation = bVisible and 0 or -90

    UIHelper.SetVisible(self.WidgetHistoryMessageList, bVisible)
    UIHelper.SetRotation(self.ImgHistoryMessageDownTypeFilter, nImgRotation)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewHistoryMessageList)
end

function UIFactionMessagePopView:UseHistoryMessage(szMessage)
    self:SetHistoryMessageListVisible(false)

    JX_TongWhisper.UseWhisperHistory(self.EditBoxMessage, szMessage)
end

return UIFactionMessagePopView