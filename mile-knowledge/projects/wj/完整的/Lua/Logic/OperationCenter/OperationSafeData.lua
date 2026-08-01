-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: OperationSafeData
-- Date: 2026-03-31
-- Desc: 运营安全相关数据（微信、微博绑定状态等）
-- ---------------------------------------------------------------------------------


OperationSafeData = OperationSafeData or {className = "OperationSafeData"}
local self = OperationSafeData

-- 数据字段
OperationSafeData.m_sns_wait_flag = nil
OperationSafeData.m_sns_start_wtime = 0
OperationSafeData.m_sns_bind_url = nil
OperationSafeData.m_bind_flag = nil


function OperationSafeData.InitOperation()
    self.m_sns_wait_flag = nil
    self.m_sns_start_wtime = 0
    self.m_sns_bind_url = nil
    self.m_bind_flag = nil

    Event.Reg(self, "ON_SYNC_SNS_TOAKEN", function ()
        local sns_type = arg0
        if sns_type == WEIBO_TYPE.SINA then
            self.UpdateSinaState()
        end
    end)

    Event.Reg(self, "ON_SNS_NOTIFY", function ()
        local sns_type = arg0
        local ret = arg1
        if ret == WEIBO_NOTIFY_CODE.UNBIND_SUCCESS then
            if sns_type == WEIBO_TYPE.SINA then
                self.UpdateSinaState()
            end
        end
    end)

    Event.Reg(self, "ON_SYNC_WEIBO_TOKEN", function ()
        local sns_type = arg0
        local token = arg1
        local open_id = arg2
        local open_key = arg3
        local url = arg4
        if token and token ~= "" then
            self.m_bind_flag = true
        else
            self.m_bind_flag = false
        end
        if self.sns_is_waiting_send() then
            self.sns_modify_wait_flag(nil)
        elseif self.sns_is_waiting_openurl() then
            self.sns_modify_wait_flag(nil)
            self.m_sns_bind_url = url
            if url and url ~= "" then
                UIHelper.OpenWebWithDefaultBrowser(self.m_sns_bind_url)
            end
        end
        Event.Dispatch("ON_SYNC_SNS_TOAKEN", sns_type)
    end)

    Event.Reg(self, "ON_WEIBO_NOTIFY", function ()
        local sns_type = arg0
        local ret = arg1
        local msg = FormatString(g_tStrings.tWeiBo[ret], "")
        if ret == WEIBO_NOTIFY_CODE.BIND_SUCCESS then
            self.m_bind_flag = true
            TipsHelper.ShowNormalTip(msg)
            if sns_type == WEIBO_TYPE.SINA then
                self.UpdateSinaState()
            end
        elseif ret == WEIBO_NOTIFY_CODE.UNBIND_SUCCESS then
            self.m_bind_flag = false
            TipsHelper.ShowNormalTip(msg)
            Event.Dispatch("ON_SNS_NOTIFY", sns_type, ret)
        elseif ret == WEIBO_NOTIFY_CODE.BIND_FAILED then
            TipsHelper.ShowNormalTip(msg)
        elseif ret == WEIBO_NOTIFY_CODE.UNBIND_FAILED then
            TipsHelper.ShowNormalTip(msg)
        end
    end)

    Event.Reg(self, "SNS_TOKEN_INVALID", function ()
        local sns_type = arg0
        local hPlayer = GetClientPlayer()
        if hPlayer then
            hPlayer.ApplyWeiboToken(WEIBO_TYPE.SINA)
        end
        if sns_type == WEIBO_TYPE.SINA then
            self.UpdateSinaState()
        end
    end)
end

-- ----------------------------------------------------------
-- Weibo 相关的公共接口
-- ----------------------------------------------------------

function OperationSafeData.IsSinaBind()
    if self.m_bind_flag ~= nil then
        return self.m_bind_flag
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local bBind = hPlayer.GetSNSBindFlag(SNS_BIND_TYPE.BIND_SINA_WEIBO)
    return bBind
end

function OperationSafeData.sns_enter_openurl()
    if not self.sns_is_waiting_send() and not self.sns_is_waiting_openurl() then
        self.sns_modify_wait_flag("url")
        local hPlayer = GetClientPlayer()
        if hPlayer then
            hPlayer.ApplyWeiboToken(WEIBO_TYPE.SINA)
        end
    else
        TipsHelper.ShowNormalTip(FormatString(g_tStrings.tWeiBo.URLOPENING, g_tStrings.WEI_BO_S_NAME))
    end
end

function OperationSafeData.sns_is_waiting_send()
    return (self.m_sns_wait_flag == "send")
end

function OperationSafeData.sns_is_waiting_openurl()
    return (self.m_sns_wait_flag == "url")
end

function OperationSafeData.sns_modify_wait_flag(flag)
    self.m_sns_wait_flag = flag
    local cost_time = 60 * 1000
    if self.m_sns_wait_flag == "send" or self.m_sns_wait_flag == "url" then
        Timer.DelTimer(self, self.sns_timeID)
        self.sns_timeID = Timer.Add(self, cost_time, function ()
            self.sns_modify_wait_flag(nil)
        end)
    end
end

function OperationSafeData.GetBindUrl()
    return self.m_sns_bind_url
end

function OperationSafeData.UpdateSinaState()
end

return OperationSafeData