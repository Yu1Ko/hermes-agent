-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UILingLongMiBaoView
-- Date: 2023-03-07 11:15:52
-- Desc: 安全锁-玲珑密保锁
-- Prefab: PanelLingLongMiBao
-- ---------------------------------------------------------------------------------

---@class UILingLongMiBaoView
local UILingLongMiBaoView = class("UILingLongMiBaoView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UILingLongMiBaoView:_LuaBindList()
    self.BtnClose                           = self.BtnClose --- 关闭界面

    self.WidgetUnlockByApp                  = self.WidgetUnlockByApp --- 使用app解锁的 widget
    self.BtnUnlockByApp                     = self.BtnUnlockByApp --- 使用app解锁
    self.BtnSwitchToUnlockByDynamicPassword = self.BtnSwitchToUnlockByDynamicPassword --- 切换为输入动态密码解锁
    self.LabelUnlockByAppTips               = self.LabelUnlockByAppTips --- 提示消息

    self.WidgetUnlockByDynamicPassword      = self.WidgetUnlockByDynamicPassword --- 输入动态密码解锁的 widget
    self.EditBoxDynamicPassword             = self.EditBoxDynamicPassword --- 动态密码的 edit box，用于输入动态密码，实际不会展示
    self.tLabelPasswordList                 = self.tLabelPasswordList --- 动态密码的 label列表，用于更美观地展示动态密码

    self.WidgetUnlockSuccess                = self.WidgetUnlockSuccess --- 解锁成功的 widget

    self.BtnSwitchToUnlockByApp             = self.BtnSwitchToUnlockByApp --- 切换为玲珑密保app解锁

    -- 绑定设备相关组件
    self.WidgetBindDeviceNotBind            = self.WidgetBindDeviceNotBind --- 未绑定设备时显示的组件
    self.WidgetBindDeviceBound              = self.WidgetBindDeviceBound --- 已绑定设备时显示的组件
    self.BtnBindDevice                      = self.BtnBindDevice --- 绑定设备按钮
    self.LabelBindDeviceBound               = self.LabelBindDeviceBound --- 已绑定设备时显示的label

    self.AniAll                             = self.AniAll --- 动画节点

    self.ImgLockBag                         = self.ImgLockBag --- 背包锁的状态
    self.ImgLockTrade                       = self.ImgLockTrade --- 交易锁的状态
    self.ImgLockBank                        = self.ImgLockBank --- 仓库锁的状态
    self.ImgLockTalk                        = self.ImgLockTalk --- 聊天锁的状态
end

function UILingLongMiBaoView:OnEnter(nSafeLockType, fnUnLockAction)
    --[[
        可能的取值（以后再考虑借用位运算改成更好看的样子）：
        大于等于0的数值 --> 密保类型枚举值；
        -1 --> 完全解锁；
        -2 --> 解锁仓库锁之外的所有锁（但并不改变仓库锁的解锁状态）；
        -3 --> 解锁聊天锁之外的所有锁（但并不改变聊天锁的解锁状态）；
        -4 --> 解锁仓库锁和聊天锁之外的所有锁（但并不改变仓库锁和聊天锁的解锁状态）
    --]]
    self.nSafeLockType  = nSafeLockType --- -1 对应完全解锁；-2 对应解锁仓库以外的所有锁  --- IMPORTANT  这个要改
    self.fnUnLockAction = fnUnLockAction    --解锁后的回调
    if not self.nSafeLockType then
        self.nSafeLockType = -1
    end

    self.bUnlockByApp = true

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    Global.SetWindowsSizeChangedExtraIgnoreViewIDs({
       VIEW_ID.PanelLingLongMiBao,
       VIEW_ID.PanelSystemMenu,
    })
end

function UILingLongMiBaoView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    
    Global.SetWindowsSizeChangedExtraIgnoreViewIDs({})
end

function UILingLongMiBaoView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnUnlockByApp, EventType.OnClick, function()
        -- 若是移动端，且已绑定设备，则使用绑定设备解锁方式
        local bUnlockByBindDevice = Platform.IsMobile() and self:HasBindDevice()

        if not bUnlockByBindDevice then
            self:UnlockByApp()
        else
            self:UnlockByBindDevice()
        end
    end)

    UIHelper.BindUIEvent(self.BtnSwitchToUnlockByDynamicPassword, EventType.OnClick, function()
        self.bUnlockByApp = false
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSwitchToUnlockByApp, EventType.OnClick, function()
        self.bUnlockByApp = true
        self:UpdateInfo()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxDynamicPassword, function()
        local szDynamicPassword = UIHelper.GetString(self.EditBoxDynamicPassword)

        -- 使用label列表来展现密码
        for idx, uiLabelPasswordDigit in ipairs(self.tLabelPasswordList) do
            local szDigit = string.sub(szDynamicPassword, idx, idx)

            UIHelper.SetString(uiLabelPasswordDigit, szDigit)
            UIHelper.SetVisible(uiLabelPasswordDigit, true)
        end
        UIHelper.SetString(self.EditBoxDynamicPassword, "")

        self:UnlockByDynamicPassword(szDynamicPassword)
    end)

    UIHelper.BindUIEvent(self.BtnBindDevice, EventType.OnClick, function()
        self:BindDevice()
    end)
end

function UILingLongMiBaoView:RegEvent()
    Event.Reg(self, "BANK_LOCK_RESPOND", function(szResult, nCode)
        if szResult == "SECURITY_VERIFY_PASSWORD_SUCCESS" or szResult == "VERIFY_BANK_PASSWORD_SUCCESS" or szResult == "SECURITY_BIND_DEVICE_VERIFY_PASSWORD_SUCCESS" then
            self:UpdateLockStatus()
            
            UIHelper.SetVisible(self.WidgetUnlockSuccess, true)
            
            UIHelper.SetButtonState(self.BtnBindDevice, BTN_STATE.Disable)

            if self.fnUnLockAction then
                self.fnUnLockAction()
            end

            if self.bUnlockByApp then
                UIHelper.PlayAni(self, self.AniAll, "AniJieSuo", function()
                    UIMgr.Close(self)
                end)
            else
                UIHelper.PlayAni(self, self.AniAll, "AniJieSuo_2", function()
                    UIMgr.Close(self)
                end)
            end
        elseif szResult == "SECURITY_VERIFY_PASSWORD_FAILED" or szResult == "VERIFY_BANK_PASSWORD_FAILED" or szResult == "SECURITY_BIND_DEVICE_VERIFY_PASSWORD_FAILED" then
            if self.bUnlockByApp then
                UIHelper.PlayAni(self, self.AniAll, "AniError", function()
                    UIHelper.PlayAni(self, self.AniAll, "AniInput")
                end)
                UIHelper.SetVisible(self.BtnUnlockByApp, true)
                UIHelper.SetVisible(self.LabelUnlockByAppTips, false)

                UIHelper.SetButtonState(self.BtnUnlockByApp, BTN_STATE.Normal)
            else
                UIHelper.PlayAni(self, self.AniAll, "AniError_2", function()
                    UIHelper.PlayAni(self, self.AniAll, "AniInput_2")
                end)
            end

            if szResult == "SECURITY_BIND_DEVICE_VERIFY_PASSWORD_FAILED" then
                -- 0-解锁成功 17-设备id不一致 33-未绑定密保锁或未开启交易保护 58-token已过期
                if nCode == 17 or nCode == 33 or nCode == 58 then
                    -- 特定错误码情况下，将本地保存的当前剑三账号的玲珑密保锁绑定信息清除，避免下次请求仍出错
                    self:ResetBindDeviceInfo()

                    -- 并刷新界面，调整绑定设备相关组件的状态
                    self:UpdateBindDeviceInfo()
                end
            end
        end
    end)

    Event.Reg(self, "XGSDK_OnGetSecurityTokenFinish", function(nCode, szMsg, szJsonData)
        self:OnBindDeviceResult(nCode, szMsg, szJsonData)

        -- 并刷新界面，调整绑定设备相关组件的状态
        self:UpdateBindDeviceInfo()
    end)
end

function UILingLongMiBaoView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILingLongMiBaoView:UpdateInfo()
    UIHelper.SetVisible(self.WidgetUnlockByApp, self.bUnlockByApp)
    UIHelper.SetVisible(self.WidgetUnlockByDynamicPassword, not self.bUnlockByApp)

    UIHelper.StopAni(self, self.AniAll, "AniInput")
    UIHelper.StopAni(self, self.AniAll, "AniInput_2")
    if self.bUnlockByApp then
        UIHelper.PlayAni(self, self.AniAll, "AniInput")
    else
        UIHelper.PlayAni(self, self.AniAll, "AniInput_2")
    end

    UIHelper.SetVisible(self.WidgetUnlockSuccess, false)

    for _, uiLabelPasswordDigit in ipairs(self.tLabelPasswordList) do
        UIHelper.SetVisible(uiLabelPasswordDigit, false)
    end

    self:UpdateBindDeviceInfo()
    
    self:UpdateLockStatus()
end

function UILingLongMiBaoView:UpdateBindDeviceInfo()
    local bBindDevice            = self:HasBindDevice()

    local bShowBindDeviceNotBind = Platform.IsMobile() and not bBindDevice
    local bShowBindDeviceBound   = Platform.IsMobile() and bBindDevice

    UIHelper.SetVisible(self.WidgetBindDeviceNotBind, bShowBindDeviceNotBind)
    UIHelper.SetVisible(self.WidgetBindDeviceBound, bShowBindDeviceBound)

    if bShowBindDeviceBound then
        local nExpiredTime   = Storage.LingLongMiBaoBindDevice.nExpiredTimestamp
        local nCurrentTime   = GetCurrentTime()

        local szRichTextTips = "<color=#AED9E0>已授权自动解锁</color>"
        if nExpiredTime and nExpiredTime ~= 0 then
            local nLeftTime = nExpiredTime - nCurrentTime
            if nLeftTime <= 0 then
                nLeftTime = 0
            end

            local nLeftDays = math.ceil(nLeftTime / 86400)

            szRichTextTips  = string.format("<color=#AED9E0>已授权自动解锁，剩余<color=#FFE26E>%d天</color></color>", nLeftDays)
        end

        UIHelper.SetRichText(self.LabelBindDeviceBound, szRichTextTips)
    end
end

function UILingLongMiBaoView:UnlockByApp()
    self:UnlockPhone()
    LOG.INFO("发起使用app进行解锁")

    local bIsAppInstalled = false
    
    if Platform.IsMobile() or Platform.IsWLColud() then
        if Platform.IsWLColud() then
            LOG.DEBUG("当前是蔚领云游戏客户端")
        end
        
        -- 在移动端，若安装了玲珑密保锁app，则尝试启动玲珑密保锁app进行解锁。未安装则弹提示
        local szAppName = self:GetAppName()
        
        bIsAppInstalled = IsAppInstalled(szAppName)
        LOG.INFO("[玲珑密保锁] szAppName=%s, bIsAppInstalled=%s", szAppName, tostring(bIsAppInstalled))

        if bIsAppInstalled then
            UIHelper.SetVisible(self.BtnUnlockByApp, false)

            LOG.INFO("[玲珑密保锁] 尝试启动app szAppName=%s", szAppName)
            StartApp(szAppName)
        end
    end

    if not bIsAppInstalled then
        UIHelper.SetButtonState(self.BtnUnlockByApp, BTN_STATE.Disable)
    end

    local szTips = "请打开玲珑密保锁APP进行解锁"
    UIHelper.SetVisible(self.LabelUnlockByAppTips, true)
    UIHelper.SetString(self.LabelUnlockByAppTips, szTips)
end

function UILingLongMiBaoView:UnlockPhone()
    local nChoiceType = -1

    if self.nSafeLockType < 0 then
        if self.nSafeLockType == -1 then
            nChoiceType = -1
        elseif self.nSafeLockType == -2 then
            nChoiceType = -2
        elseif self.nSafeLockType == -3 then
            nChoiceType = -3
        else
            --- self.nSafeLockType == -4
            nChoiceType = -4
        end
    else
        if self.nSafeLockType == SAFE_LOCK_EFFECT_TYPE.BANK then
            nChoiceType = -3
        elseif self.nSafeLockType == SAFE_LOCK_EFFECT_TYPE.TALK then
            nChoiceType = -2
        else
            nChoiceType = -4
        end
    end

    LOG.DEBUG("UnlockPhone nSafeLockType=%d nChoiceType=%d", self.nSafeLockType, nChoiceType)
    BankLock.RequestUnlockByPhone(nChoiceType)
end

function UILingLongMiBaoView:GetAppName()
    local szAppName = "com.kingsoft.android.cat"
    if Platform.IsIos() or Platform.WLCloudIsIos() then
        szAppName = "sec://"
    end

    return szAppName
end

function UILingLongMiBaoView:UnlockByDynamicPassword(szDynamicPassword)
    if string.len(szDynamicPassword) ~= 6 then
        return
    end

    UIHelper.RemoteCallToServer(BankLock.tRemoteFun.Verify, szDynamicPassword)
    LOG.INFO("发起使用动态密码进行解锁 szDynamicPassword=%s", szDynamicPassword)
end

function UILingLongMiBaoView:UnlockByBindDevice()
    local szToken    = Storage.LingLongMiBaoBindDevice.szToken
    local szDeviceID = XGSDK_GetDeviceId()

    LOG.INFO("发起使用绑定设备进行解锁 szToken=%s szDeviceID=%s", szToken, szDeviceID)
    UIHelper.RemoteCallToServer(BankLock.tRemoteFun.VerifyByBindDevicePhone, szToken, szDeviceID)
end

function UILingLongMiBaoView:BindDevice()
    if not Platform.IsMobile() then
        -- 仅移动端有该功能
        return
    end

    UIMgr.Open(VIEW_ID.PanelMiBaoBangDingConfirm)
end

function UILingLongMiBaoView:OnBindDeviceResult(nCode, szMsg, szJsonData)
    LOG.DEBUG("OnBindDeviceResult nCode=%d szMsg=%s szJsonData=%s", nCode, szMsg, szJsonData)

    if nCode ~= 0 then
        self:OnBindDeviceFailed(nCode, szMsg)
        return
    end

    --- 绑定设备后，隐藏提示，重新显示解锁按钮
    UIHelper.SetVisible(self.BtnUnlockByApp, true)
    UIHelper.SetVisible(self.LabelUnlockByAppTips, false)
    UIHelper.SetButtonState(self.BtnUnlockByApp, BTN_STATE.Normal)

    self:SaveBindDeviceInfo(szJsonData)
end

function UILingLongMiBaoView:OnBindDeviceFailed(nCode, szMsg)
    local szTips = "授权失败"
    if nCode == 1910 then
        szTips = "请在本设备安装安卓4.2.29或iOS4.8.0及以上版本的【玲珑密保锁】后再尝试。"
    elseif nCode == 1911 then
        szTips = "账号未授权玲珑密保锁"
    elseif nCode == 1912 then
        szTips = "授权玲珑密保锁操作失败"
    elseif nCode == 1913 then
        szTips = "取消授权玲珑密保锁"
    end

    TipsHelper.ShowImportantYellowTip(szTips, false, 1.5)
end

---@class BindDeviceInfo 绑定设备信息
---@field passportAccount string 登录的账号
---@field uid string 登录的账号ID
---@field token string 解锁token（后续游戏内解锁需要用到）
---@field expiredTime number token有效截止时长（时间戳）
---
---参考文档 https://doc.seasungame.com/#/home/details?id=518&version_id=3170&docs_id=3884   39.  绑定玲珑密保锁app

--- 保存绑定设备信息
function UILingLongMiBaoView:SaveBindDeviceInfo(szJsonInfo)
    ---@type BindDeviceInfo
    local tInfo                                       = JsonDecode(szJsonInfo)

    Storage.LingLongMiBaoBindDevice.bBindDevice       = true

    Storage.LingLongMiBaoBindDevice.szAccount         = tInfo.passportAccount
    Storage.LingLongMiBaoBindDevice.szXiGuaUid        = tInfo.uid
    Storage.LingLongMiBaoBindDevice.szToken           = tInfo.token
    Storage.LingLongMiBaoBindDevice.nExpiredTimestamp = tInfo.expiredTime

    Storage.LingLongMiBaoBindDevice.Dirty()
end

--- 重置绑定设备信息（标记为未绑定）
function UILingLongMiBaoView:ResetBindDeviceInfo()
    Storage.LingLongMiBaoBindDevice.bBindDevice = false

    Storage.LingLongMiBaoBindDevice.Dirty()
end

function UILingLongMiBaoView:HasBindDevice()
    if Storage.LingLongMiBaoBindDevice.bBindDevice then
        -- 检查下是否已过期
        local nExpiredTime = Storage.LingLongMiBaoBindDevice.nExpiredTimestamp
        local nCurrentTime = GetCurrentTime()
        if nExpiredTime and nExpiredTime ~= 0 and nExpiredTime <= nCurrentTime then
            LOG.DEBUG("玲珑密保锁已过期，修改为未绑定 nExpiredTime=%d nCurrentTime=%d", nExpiredTime, nCurrentTime)
            self:ResetBindDeviceInfo()
        end
    end

    return Storage.LingLongMiBaoBindDevice.bBindDevice
end

function UILingLongMiBaoView:UpdateLockStatus()
    local fnSetLockImg = function(imgLock, bLocked)
        if bLocked then
            UIHelper.SetSpriteFrame(imgLock, "UIAtlas2_Public_PublicButton_PublicButton1_Btn_suo")
        else
            UIHelper.SetSpriteFrame(imgLock, "UIAtlas2_Public_PublicButton_PublicButton1_Btn_suoOpen2")
        end
    end
    
    local bBagTradeLocked = not BankLock.bBagAndTradeUnlocked
    local bBankLocked     = not g_pClientPlayer.bIsBankPasswordVerified
    local bTalkLocked     = BankLock.Lock_IsChoiceTypeLocked(SAFE_LOCK_EFFECT_TYPE.TALK)

    fnSetLockImg(self.ImgLockBag, bBagTradeLocked)
    fnSetLockImg(self.ImgLockTrade, bBagTradeLocked)
    fnSetLockImg(self.ImgLockBank, bBankLocked)
    fnSetLockImg(self.ImgLockTalk, bTalkLocked)
end

return UILingLongMiBaoView