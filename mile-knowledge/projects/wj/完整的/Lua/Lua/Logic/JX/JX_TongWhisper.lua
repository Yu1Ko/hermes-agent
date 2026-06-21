-- ---------------------------------------------------------------------------------
-- Author: chenji
-- Name: JX_TongWhisper
-- Date: 2024-08-29 16:00:00
-- Desc: 帮会通知/群密 插件功能搬运自dx的脚本，基于它适配到vk端 interface/JX/JX_Battle/JX_TongWhisper.lua
-- ---------------------------------------------------------------------------------


JX_TongWhisper         = JX_TongWhisper or { className = "JX_TongWhisper" }
local self = JX_TongWhisper

---@class WHISPER_TYPE
JX_TongWhisper.WHISPER_TYPE = {
    --- 1：在线帮众
    OnlineMembers = 1,
    --- 2：当前地图
    MembersInCurrentMap = 2,
    --- 3：其他地图
    MembersInOtherMap = 3,
}

JX_TongWhisper.bWhisperAndWhisper = true --- 信息发布到群密
JX_TongWhisper.nWhisperType = JX_TongWhisper.WHISPER_TYPE.OnlineMembers --- 群密发送的类别

JX_TongWhisper.bWhisperAndTong = true --- 信息发布到帮会频道
JX_TongWhisper.bTongMsgCycle = false --- 帮会信息循环发送
JX_TongWhisper.bWhisperTeamFull = false --- 队伍满员取消循环发布

JX_TongWhisper.bWhisperQuiet = false --- 勿扰模式

--JX.RegisterCustomData("JX_TongWhisper")

local _JXLangPack = JX.LoadLangPack
local _L = {}
--- 加载的语言包是GBK编码的，这里重载下[]接口，转换成utf8
setmetatable(_L, {
    __index = function(t, k)
        return UIHelper.GBKToUTF8(_JXLangPack[k])
    end
})

local szTongMsgCycle = nil --- 循环发送的内容

JX_TongWhisper.nNextTongMsgCycleSendTickCount = 0 --- 下次循环发送时间点（毫秒）

function JX_TongWhisper.IsTongMsgCycleRunning()
    return szTongMsgCycle ~= nil
end

function JX_TongWhisper.GetTongMsgCycleMessage()
    return szTongMsgCycle
end

-- 帮会密聊权限检查：TongOperation.tab
function JX_TongWhisper.GetTongAuthority()
    -- TongClient.GetMemberInfo(dwID) -- 获取帮会成员信息
    -- TongClient.CheckBaseOperationGroup(nGroup, nOperationIndex) -- 检查分组的基本操作权限
    local tong = GetTongClient()
    if not tong then
        return false
    end
    local me = GetClientPlayer()
    if not me or me.dwTongID == 0 then
        return false
    end
    local tTongInfo = tong.GetMemberInfo(me.dwID)
    return tong.CheckBaseOperationGroup(tTongInfo.nGroupID, 4) -- 管理活动
    --GetTongClient().GetMemberInfo(UI_GetClientPlayerID())
    --Output(GetTongClient().CheckBaseOperationGroup(GetTongClient().GetMemberInfo(UI_GetClientPlayerID()).nGroupID,2))
end

function JX_TongWhisper.OpenTongWhisper()
    if self.GetTongAuthority() then
        ---@see UIFactionMessagePopView
        UIMgr.Open(VIEW_ID.PanelFactionMessagePop)
    else
        ---@see UIReceiveFactionMessagePopView
        UIMgr.Open(VIEW_ID.PanelReceiveFactionMessagePop)
    end
end

-- 发送帮会密聊的背景通信
---@param szEditText string 消息内容
---@param nTongWsType number 发送到密聊频道的类型 @see WHISPER_TYPE
---@param uiBtnSend table 发送信息按钮的btn按键
---@param uiLabelBtnSend table 发送信息按钮的label组件
function JX_TongWhisper.SendTongWhisper(szEditText, nTongWsType, uiBtnSend, uiLabelBtnSend)
    if not self.GetTongAuthority() then
        JX.Sysmsg(_L["no authority to send tong whisper"])
        JX.SysAnnounce(_L["no authority to send tong whisper"])
        return
    end
    local me = GetClientPlayer()
    if IsRemotePlayer(me.dwID) then
        JX.Sysmsg(_L["remoteplayer can not use this module"])
        JX.SysAnnounce(_L["remoteplayer can not use this module"])
        return
    end
    if not szEditText or szEditText == "" then
        JX.Sysmsg(_L["can not send null string"])
        JX.SysAnnounce(_L["can not send null string"])
        return
    end
    if not self.bWhisperAndWhisper and not self.bWhisperAndTong then
        JX.Sysmsg(_L["The send channel is not checked"])
        JX.SysAnnounce(_L["The send channel is not checked"])
        return
    end
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TALK, "player talk") then
        return TipsHelper.ShowNormalTip(UIHelper.GBKToUTF8(_L['chat safe locked, send failed']))
    end


    -- 帮会频道
    if self.bWhisperAndTong then
        JX.Talk(PLAYER_TALK_CHANNEL.TONG, UIHelper.UTF8ToGBK(szEditText))
        if self.bTongMsgCycle then
            self.SendTongWhisperCycle(true, szEditText, true)
        end
    end
    -- 群密频道
    if self.bWhisperAndWhisper then
        --local _TongWsType = 1 -- 1：在线帮众，2：当前地图；3：其他地图
        --for i = 1, 3 do
        --    if JX.GetRegWnd("CheckBox_TongWs" .. i):IsCheckBoxChecked() then
        --        _TongWsType = i
        --        break
        --    end
        --end

        local _TongWsType = nTongWsType --- @see WHISPER_TYPE
        
        --- 通过背景通信来传递帮会密聊的数据
        JX.BgTalk(PLAYER_TALK_CHANNEL.TONG, "ACQUIRE_TONG_WHISPER", {_TongWsType, me.GetMapID(), me.szName, UIHelper.UTF8ToGBK(szEditText)})
    end

    -- 通知发成功了并改变按钮状态
    JX.Sysmsg(_L["send tong whisper successful"])
    JX.SysAnnounce(_L["send tong whisper successful"], nil, "yellow")
    
    --- 发送后自动保存到历史记录中
    self.SaveWhisperHistory(szEditText)
    
    local szLabelText = UIHelper.GetString(uiLabelBtnSend)
    local fnCDCountDown = function(nRemain)
        if nRemain ~= 0 then
            UIHelper.SetButtonState(uiBtnSend, BTN_STATE.Disable)
            UIHelper.SetString(uiLabelBtnSend, szLabelText .. "(" .. nRemain .. "s)")
        else
            UIHelper.SetButtonState(uiBtnSend, BTN_STATE.Normal)
            UIHelper.SetString(uiLabelBtnSend, szLabelText)
        end
    end
    
    local nCD = 4
    local nTimerID
    
    fnCDCountDown(nCD)
    nTimerID = Timer.AddCountDown(self, nCD, function (nRemain)
        fnCDCountDown(nRemain)
    end, function()
        fnCDCountDown(0)
        nTimerID = nil
    end)
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelFactionMessagePop then
            if nTimerID then
                Timer.DelTimer(self, nTimerID)
                nTimerID = nil
            end
        end
    end)
end

-- 帮会频道循环播报
function JX_TongWhisper.SendTongWhisperCycle(bSend, szSend, bUseBubble)
    if bSend then
        --- 开始新的循环之前，先尝试将之前的循环停止
        if self.nTimer_JX_TongWhisperCycle then
            Timer.DelTimer(self, self.nTimer_JX_TongWhisperCycle)
            self.nTimer_JX_TongWhisperCycle = nil
        end
        
        szTongMsgCycle = szSend

        local nCycleTime = 30

        JX_TongWhisper.nNextTongMsgCycleSendTickCount = GetTickCount() + nCycleTime * 1000
        self.nTimer_JX_TongWhisperCycle = Timer.AddCycle(self, nCycleTime, function()
            JX_TongWhisper.nNextTongMsgCycleSendTickCount = GetTickCount() + nCycleTime * 1000

            --- 启用团队满员取消循环发送功能的情况下，检查下
            local player = GetClientPlayer()
            if self.bWhisperTeamFull and player and player.IsInParty() then
                local hTeam = GetClientTeam()
                local tMemberInfo = hTeam.GetTeamMemberList()
                if #tMemberInfo == 25 then
                    LOG.DEBUG("团队满员，停止循环发送")
                    self.SendTongWhisperCycle(false)
                    return
                end
            end
            
            JX.Talk(PLAYER_TALK_CHANNEL.TONG, UIHelper.UTF8ToGBK(szTongMsgCycle))
        end)
        if bUseBubble then
            BubbleMsgData.PushMsgWithType("TongWhisper", {
                szAction = function()
                    JX_TongWhisper.OpenTongWhisper()
                end }
            )
        end
    else
        if self.nTimer_JX_TongWhisperCycle then
            -- 通知发成功了并改变按钮状态
            JX.Sysmsg(_L['send tong message circulation ending'])
            JX.SysAnnounce(_L['send tong message circulation ending'], nil, "yellow")
            
            Timer.DelTimer(self, self.nTimer_JX_TongWhisperCycle)
            self.nTimer_JX_TongWhisperCycle = nil
            
            szTongMsgCycle = nil

            BubbleMsgData.RemoveMsg("TongWhisper")
        end
    end
    
    
    Event.Dispatch("TongWhisperCycleStateChanged")
end

-- 接收帮会群密事件后处理
function JX_TongWhisper.GetTongWhisper(dwTalkerID, tTongMsg)
    if self.bWhisperQuiet then
        LOG.TABLE({
                      "帮会群密 勿扰模式已开启，不显示消息",
                      dwTalkerID, tTongMsg
                  })
        return
    end
    local type, talkermapid, talkername, text = unpack(tTongMsg)
    local me = GetClientPlayer()
    if type == JX_TongWhisper.WHISPER_TYPE.OnlineMembers 
            or (type == JX_TongWhisper.WHISPER_TYPE.MembersInCurrentMap and talkermapid == me.GetMapID()) 
            or (type == JX_TongWhisper.WHISPER_TYPE.MembersInOtherMap and talkermapid ~= me.GetMapID()) then
        
        local fnWriteWhisper = function(tTongMemberInfo)
            JX.WriteWhisper(dwTalkerID, tTongMemberInfo, UIHelper.GBKToUTF8(text), UIHelper.GBKToUTF8(talkername), _L["**tong whisper**:"])
        end

        local tData = TongData.GetMemberInfo(dwTalkerID)
        if tData then
            --- 可以获取到帮会成员数据，则使用其门派展示头像
            fnWriteWhisper(tData)
        else
            --- 否则请求一下
            TongData.ApplyTongRoster()
            Event.Reg(self, "UPDATE_TONG_ROSTER_FINISH", function()
                Event.UnReg(self, "UPDATE_TONG_ROSTER_FINISH")
                
                --- 这里不管拿不拿得到，都直接展示了
                local tNewData = TongData.GetMemberInfo(dwTalkerID)
                fnWriteWhisper(tNewData)
            end)
        end
        
        
        -- fixme: 要展示头像等级等信息的话，需要这部分字段，需要玩家在附近来获取玩家对象获取，或者在发送群密事件的时候，额外传递这些信息
        --local dwTitleID = 0
        --local szAvatar = 0
        --local dwForceID = 0
        --local nLevel = 120
        --local nCamp = 0
        --local nRoleType = 0
        --local szGlobalID = nil
        --local szID = nil
    end
end

-- 群密消息历史保存列表
function JX_TongWhisper.GetWhisperHistory()
    return Storage.TongWhisperHistory
end

-- 保存群密消息
function JX_TongWhisper.SaveWhisperHistory(szEditText)
    local tStorage = Storage.TongWhisperHistory
    
    -- note: 与端游不同，vk是自动保存，当超出时，将末尾超过20的移除
    --if JX.GetTableCount(tStorage) >= 20 then
    --    JX.Sysmsg(_L["save faild, Over 20!"])
    --    JX.SysAnnounce(_L["save faild, Over 20!"])
    --    return
    --end

    if not szEditText or szEditText == "" then
        JX.Sysmsg(_L['save faild!'])
        JX.SysAnnounce(_L['save faild!'])
        return
    end
    
    --- 若已存在，则将旧的移除
    if table.contain_value(tStorage, szEditText) then
        table.remove_value(tStorage, szEditText)
    end
    
    --- 新的记录自动插入到第一个位置
    table.insert(tStorage, 1, szEditText)
    
    --- 数目超过指定数目时，移除末尾，直到符合条件
    if #tStorage > 20 then
        for i = 1, #tStorage - 20 do
            table.remove(tStorage, #tStorage)
        end
    end
    
    Storage.Helper.Dirty(tStorage)

    JX.Sysmsg(_L['save successful!'])
    JX.SysAnnounce(_L['save successful!'], nil, "yellow")
    
    Event.Dispatch("TongWhisperHistoryChanged")
end

function JX_TongWhisper.DeleteWhisperHistory(szHistoryMessage)
    local tStorage = Storage.TongWhisperHistory
    
    table.remove_value(tStorage, szHistoryMessage)

    Storage.Helper.Dirty(tStorage)

    JX.Sysmsg(_L['delete successful!'])
    JX.SysAnnounce(_L['delete successful!'], nil, "yellow")

    Event.Dispatch("TongWhisperHistoryChanged")
end

function JX_TongWhisper.UseWhisperHistory(editBoxMessage, szMessage)
    UIHelper.SetString(editBoxMessage, szMessage)

    JX.Sysmsg(_L["load whisper history success!"])
    JX.SysAnnounce(_L["load whisper history success!"], nil, "yellow")
end

function JX_TongWhisper.LoadingEnd()
    if szTongMsgCycle ~= nil then
        self.SendTongWhisperCycle(true, szTongMsgCycle, false)
    end
end

--RegisterEvent("LOADING_END", JX_TongWhisper.LoadingEnd)
Event.Reg(self, "LOADING_END", JX_TongWhisper.LoadingEnd)


--- 解析通过背景通信传递过来的帮会密聊的数据，并以密聊的形式展示到密聊界面中
JX.RegisterBgEvent("ACQUIRE_TONG_WHISPER", function(szEvent, dwTalkerID, szTalkerName, nChannel, tTongMsg)
    self.GetTongWhisper(dwTalkerID, tTongMsg)
end)
