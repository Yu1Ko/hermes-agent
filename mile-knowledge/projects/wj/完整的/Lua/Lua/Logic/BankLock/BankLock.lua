--- 安全锁与密保锁
---@class BankLock
BankLock                                    = BankLock or {}
local self = BankLock

--- 背包锁和交易锁是否已解锁
BankLock.bBagAndTradeUnlocked = false

function BankLock.Init()
    self.InitData()
    self.RegEvent()
end

function BankLock.UnInit()
    Event.UnRegAll(self)
end

function BankLock.InitData()
    self.bBagAndTradeUnlocked = false
end

function BankLock.RegEvent()
    Event.Reg(self, EventType.OnRoleLogin, function()
        self.InitData()
    end)
end

--- 相关远程lua函数
BankLock.tRemoteFun                         = {}
--- 设置安全锁
BankLock.tRemoteFun.Set                     = "OnSetBankPassword"

--- 忘记密码（回答安全问题从而重新设置密码）
BankLock.tRemoteFun.Modify                  = "OnModifyBankPassword"

--- 重置密码（点击后等待七日后清除安全锁，中间可取消重置）
BankLock.tRemoteFun.Reset                   = "OnResetBankPassword"

--- 取消重置密码
BankLock.tRemoteFun.CancelReset             = "OnCancelResetBankPassword"

--- 解锁安全锁，或者使用app或者实体卡显示的动态密码解锁玲珑密保锁
BankLock.tRemoteFun.Verify                  = "OnVerifyBankPassword"

--- 使用app一键解锁玲珑密保锁
BankLock.tRemoteFun.VerifyByPhone           = "OnVerifyToSecuritySystem"

--- 使用app一键解锁玲珑密保锁
BankLock.tRemoteFun.VerifyByBindDevicePhone = "OnBDVerifyToSecuritySystem"

--- 完整的所有锁定类型的掩码
BankLock._MASK_FOR_ALL_SAFE_LOCKS           = 0

--- 完整的锁定类型列表
BankLock.l_aAllSafeLockEffectTypes          = {
    SAFE_LOCK_EFFECT_TYPE.TRADE, SAFE_LOCK_EFFECT_TYPE.AUCTION, SAFE_LOCK_EFFECT_TYPE.SHOP, SAFE_LOCK_EFFECT_TYPE.MAIL,
    SAFE_LOCK_EFFECT_TYPE.TONG_DONATE, SAFE_LOCK_EFFECT_TYPE.TONG_PAY_SALARY, SAFE_LOCK_EFFECT_TYPE.EQUIP, SAFE_LOCK_EFFECT_TYPE.BANK,
    SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY, SAFE_LOCK_EFFECT_TYPE.COIN, SAFE_LOCK_EFFECT_TYPE.OPERATE_DIAMOND, SAFE_LOCK_EFFECT_TYPE.WANTED,
    SAFE_LOCK_EFFECT_TYPE.EXTERIOR, SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, SAFE_LOCK_EFFECT_TYPE.FELLOWSHIP, SAFE_LOCK_EFFECT_TYPE.ARENA,
    SAFE_LOCK_EFFECT_TYPE.TALK,
}

for _, nSafeLockType in ipairs(BankLock.l_aAllSafeLockEffectTypes) do
    BankLock._MASK_FOR_ALL_SAFE_LOCKS = BankLock._MASK_FOR_ALL_SAFE_LOCKS + 2 ^ nSafeLockType
end

--- 使用手机app来解锁玲珑密保锁
---
---@param nChoiceType number 需要被解锁的密保锁类型所对应的数字（还是正常枚举值+-1、-2、-3、-4的形式）
---
--- 除了正常枚举值 SAFE_LOCK_EFFECT_TYPE以外，分为如下几种情况：
--- 1. 参数为-1，则完全解锁；
--- 2. 参数为-2，则表示要解锁仓库锁之外的所有锁（对应于直接解锁聊天锁；并不关心仓库锁是否解锁）
--- 3. 参数为-3，则表示要解锁聊天锁之外的所有锁（对应于直接解锁仓库锁；并不关心聊天锁是否解锁）
--- 4. 参数为-4，则表示要解锁仓库锁和聊天锁之外的所有锁
function BankLock.RequestUnlockByPhone(nChoiceType)
    local nMask       = BankLock._MASK_FOR_ALL_SAFE_LOCKS
    local player      = GetClientPlayer()
    local bBankLocked = BankLock.Lock_IsChoiceTypeLocked(SAFE_LOCK_EFFECT_TYPE.BANK)
    local bTalkLocked = BankLock.Lock_IsChoiceTypeLocked(SAFE_LOCK_EFFECT_TYPE.TALK)

    if nChoiceType == -1 then
        --- Do nothing
    elseif nChoiceType == -2 then
        if bBankLocked then
            nMask = nMask - 2 ^ SAFE_LOCK_EFFECT_TYPE.BANK
        end
    elseif nChoiceType == -3 then
        if bTalkLocked then
            nMask = nMask - 2 ^ SAFE_LOCK_EFFECT_TYPE.TALK
        end
    else
        --- nChoiceType == -4
        if bBankLocked then
            nMask = nMask - 2 ^ SAFE_LOCK_EFFECT_TYPE.BANK
        end
        if bTalkLocked then
            nMask = nMask - 2 ^ SAFE_LOCK_EFFECT_TYPE.TALK
        end
    end

    UIHelper.RemoteCallToServer(BankLock.tRemoteFun.VerifyByPhone, nMask)
end

function BankLock.IsAccountDanger()
    local player = GetClientPlayer()
    return player.nAccountSecurityState == ACCOUNT_SECURITY_STATE.DANGER
end

--- 是否绑定了玲珑密保锁
function BankLock.IsPhoneLock()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end
    return hPlayer.IsTradingMibaoSwitchOpen()
end

--- 安全锁重置的截止时间
function BankLock.GetLockResetEndTime()
    local player = GetClientPlayer()
    if player then
        return player.nBankPasswordResetEndTime
    else
        return 0
    end
end

--- 是否设置了锁（安全锁或玲珑密保锁）
function BankLock.IsPasswordExist()
    local player = GetClientPlayer()

    if BankLock.IsPhoneLock() then
        return true
    end

    return player.bBankPasswordExist
end

--- 是否处于解锁状态（安全锁或玲珑密保锁）
function BankLock.IsPasswordVerified()
    local player = GetClientPlayer()
    return player and player.bIsBankPasswordVerified
end

--- 当前锁定状态
---
--- @return string, number
---
--- 返回结果含义如下
--- szState          当前的锁定状态，包括 NO_PASSWORD/PASSWORD_LOCK/PASSWORD_UNLOCK
--- nResetEndTime    安全锁重置的截止时间
function BankLock.Lock_GetState()
    local nResetEndTime
    if not BankLock.IsPhoneLock() then
        nResetEndTime   = BankLock.GetLockResetEndTime()
        local nLeftTime = nResetEndTime - GetCurrentTime()
        if nLeftTime <= 0 then
            nResetEndTime = nil
        end
    end

    local bBankPasswordExist      = BankLock.IsPasswordExist()
    local bIsBankPasswordVerified = BankLock.IsPasswordVerified()
    if not bBankPasswordExist then
        return "NO_PASSWORD", nResetEndTime
    end

    local bTalkLocked = BankLock.Lock_IsChoiceTypeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) --- 聊天锁与其他锁不是一套，需要特别处理

    if (not bIsBankPasswordVerified) or bTalkLocked then
        return "PASSWORD_LOCK", nResetEndTime
    else
        return "PASSWORD_UNLOCK", nResetEndTime
    end
end

--- 对应的密保类型的锁定状态
---
---@return string 锁定状态 NO_PASSWORD/CHOICE_LOCK_SELECT/CHOICE_LOCK_UNSELECT
function BankLock.Lock_GetOptionState(nChoiceType)
    local bBankPasswordExist = BankLock.IsPasswordExist()
    if not bBankPasswordExist then
        return "NO_PASSWORD"
    end

    local player  = GetClientPlayer()
    local tInfo   = player.GetSafeLockMaskInfo()
    local bChoice = tInfo[nChoiceType]
    if bChoice then
        --- 被锁住
        return "CHOICE_LOCK_SELECT"
    else
        return "CHOICE_LOCK_UNSELECT"
    end
end

--- 对应的密保类型是否处于锁定状态
function BankLock.Lock_IsChoiceTypeLocked(nChoiceType)
    local szResult = BankLock.Lock_GetOptionState(nChoiceType)
    return szResult == "CHOICE_LOCK_SELECT"
end

--- 玩家若设置密保锁的情况下，若进行了跨服操作，并在期间掉线或重连，后面在跨服或回到原服时，玩家的账号安全状态会被设置为等待检查中，直到玩家在原服重新登录后才会恢复正常
--- 这种情况下，没有密保锁的玩家，也会被认定为是账号处于危险状态，player.CheckSafeLock接口会返回锁定状态，导致使用道具等需要检查密保锁的界面会弹出解锁界面
--- 但因为根本没有设置过，不论输入什么都是错误的。
--- 这种情况下，需要回到原服重新登陆下，才能恢复正常
--- 玩家遇到这种情况会很奇怪，所以通过这个判断这个状态，提示玩家如何操作
---
--- note：自2024.6.17开始，服务器的初始状态将修改为Safe，届时，这种情况下会返回safe，就不会有这个问题了
function BankLock.IsInRemoteReLoginWrongState()
    local bWrongState        = false

    local bBankPasswordExist = BankLock.IsPasswordExist()
    local player             = GetClientPlayer()
    local bWaitCheck         = player.nAccountSecurityState == ACCOUNT_SECURITY_STATE.WAIT_CHECK

    if not bBankPasswordExist and bWaitCheck then
        bWrongState = true
    end

    return bWrongState
end

---@class SAFE_LOCK_EFFECT_TYPE 密保锁类型
---@field TRADE number 交易
---@field AUCTION number 拍卖
---@field SHOP number 商店
---@field MAIL number 邮件
---@field TONG_DONATE number 帮会捐赠
---@field TONG_PAY_SALARY number 帮会支付工资
---@field EQUIP number 装备
---@field BANK number 仓库
---@field TONG_REPERTORY number 帮会仓库
---@field COIN number 通宝
---@field OPERATE_DIAMOND number 五彩石？
---@field WANTED number 悬赏？
---@field EXTERIOR number 外装
---@field TONG_OPERATE number 帮会操作
---@field FELLOWSHIP number 社交
---@field ARENA number 竞技场
---@field TALK number 聊天

--- 判断是否被锁定，若锁定且未设置bDontOpenPanel为true，则将弹出对应类型的解锁页面
---@param nChoiceType number 密保锁类型，参考 SAFE_LOCK_EFFECT_TYPE
---@param szMsg string 背景信息
---@param bDontOpenPanel boolean 是否不打开账户异常界面
function BankLock.CheckHaveLocked(nChoiceType, szMsg, bDontOpenPanel)
    if BankLock.IsAccountDanger() then
        if not bDontOpenPanel then
            -- todo: 这里打开 账号异常，安全保护 的界面，等后续有了再添加
            UIMgr.OpenSingle(false, VIEW_ID.PanelAccountWarning)
        end
        return true
    end

    local player = GetClientPlayer()
    assert(player)

    local bLocked = false
    local bInWrongState = false

    if nChoiceType == SAFE_LOCK_EFFECT_TYPE.TALK then
        --- 对聊天锁的判断方式与众不同
        if BankLock.Lock_IsChoiceTypeLocked(nChoiceType) then
            bLocked = true
        end
    else
        if BankLock.IsInRemoteReLoginWrongState() then
            bInWrongState = true
            bLocked = true

            local szWrongStateTips = ""
            if IsRemotePlayer(player.dwID) then
                szWrongStateTips = "当前因跨服导致密保锁状态异常，请回到原服后重新登录再进行操作"
            else
                szWrongStateTips = "本次登录期间因跨服导致密保锁状态异常，请重新登录再进行操作"
            end
            TipsHelper.ShowImportantRedTip(szWrongStateTips)
        elseif not player.CheckSafeLock(nChoiceType) then
            bLocked = true
        end
    end

    if bLocked and not bDontOpenPanel and not bInWrongState then
        LOG.DEBUG("BankLock.CheckHaveLocked nChoiceType=%d szMsg=%s", nChoiceType, tostring(szMsg))
        if BankLock.IsPhoneLock() then
            UIMgr.OpenSingle(false, VIEW_ID.PanelLingLongMiBao, nChoiceType)
        else
            UIMgr.OpenSingle(false, VIEW_ID.PanelPasswordUnlockPop)
        end
    end
    return bLocked
end

--- 打开当前安全锁/密保锁对应状态的界面
---
--- 具体状态和界面的映射关系可以参考下面的注释
function BankLock.OpenCurrentStateView()
    local szState, nResetEndTime = BankLock.Lock_GetState()

    if szState == "NO_PASSWORD" then
        -- 未设置锁 => 设置安全锁
        UIMgr.OpenSingle(false, VIEW_ID.PanelSetPasswordPop)
    elseif szState == "PASSWORD_UNLOCK" then
        -- 已解锁 =>
        if BankLock.IsPhoneLock() then
            -- 密保锁 => 暂时不知道做啥，先放个提示
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_VERIFY_SUCCESS)
        else
            -- 安全锁 => 修改密码（忘记密码）
            UIMgr.OpenSingle(false, VIEW_ID.PanelForgetPasswoedPop)
        end
    elseif szState == "PASSWORD_LOCK" then
        -- 未解锁 =>
        local bPhone = BankLock.IsPhoneLock()

        if bPhone then
            -- 密保锁
            UIMgr.OpenSingle(false, VIEW_ID.PanelLingLongMiBao, -4)
        else
            -- 安全锁
            if nResetEndTime and nResetEndTime - GetCurrentTime() > 0 then
                -- 重置中
                UIMgr.OpenSingle(false, VIEW_ID.PanelPasswordResetPop)
            else
                -- 正常锁定状态
                UIMgr.OpenSingle(false, VIEW_ID.PanelPasswordUnlockPop)
            end
        end
    end
end

function BankLock.ResetPassword()
    local szMsg = [[密码将在7天后重置，重置期间可取消重置。
再次重置将重新计时，是否确认重置？]]
    UIHelper.ShowConfirm(szMsg, function ()
        UIHelper.RemoteCallToServer(BankLock.tRemoteFun.Reset)
    end)
end
