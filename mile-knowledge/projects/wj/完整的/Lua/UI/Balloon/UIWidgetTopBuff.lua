-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetTopBuff
-- Date: 2025-03-11 11:20:19
-- Desc: DX的JJC头顶Buff 接入
-- ---------------------------------------------------------------------------------

local UIWidgetTopBuff = class("UIWidgetTopBuff")

local BALLOON_VISIBLE_DISTANCE = 50 * 64
local NORMAL_SCALE_DISTANCE = 10 * 64
local DistancelScaleMin = 0.75
local szImagePath = "UIAtlas2_MainCity_MainCitySkill1_BuffWenzi"
-- local dwIconFrame = { -- 放到setting里加三列去维护了，数字本质是szImagePath资源的num后缀
--    1, --增益-爆
--    2, --增益-减(减伤)
--    3, --增益-免封
--    4, --增益-免控
--    5, --减益-倒
--    6, --减益-定
--    7, --减益-封
--    8, --减益-锁
--    9, --减益-晕
--    10, -- 减益-损
-- }

-- 设置模式预览数据
local szSettingModePreviewTime = "59'59''"
local tSettingModePreviewBuff = {
    [6] = {
        buff = {
            nEndFrame = 0,
        },
        dwIconFrame = 6,
        bIsPowerUp = false,
        nStrength = 0,
        dwStrengthFrame = 0,
    }
}

function UIWidgetTopBuff:OnInit()
    self.tBuffBox = {}
    for i, v in ipairs(self.tBuffCellScrips) do
        UIHelper.SetVisible(v._rootNode, false)
    end

    self.nIconSize = Storage.TopBuffSetting.nIconSize
    self.nIconPosition = Storage.TopBuffSetting.nIconPosition

    self.tBuff, self.nBuffCount = self:GetPlayerBuffList()
    self:UpdateInfo()
    self:InitPosSetting()
end

function UIWidgetTopBuff:OnEnter(dwPlayerID, parentNode)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.tBuffCellScrips = {}
        for nIndex = 1, 3 do
            self.tBuffCellScrips[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityHeadBuff, self.LayoutHeadBuff2)
            UIHelper.SetVisible(self.tBuffCellScrips[nIndex]._rootNode, false)
        end

        Timer.AddFrameCycle(self, 1, function()
            self:OnUpdate()
        end)
    end

    if dwPlayerID and parentNode then
        self.dwPlayerID = dwPlayerID
        self.parentNode = parentNode
        self:OnInit()
    end
end

function UIWidgetTopBuff:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTopBuff:BindUIEvent()
    
end

function UIWidgetTopBuff:RegEvent()
    Event.Reg(self, "BUFF_UPDATE", function()
        if self.dwPlayerID ~= arg0 then return end
        self:OnBuffUpdate()
    end)
    Event.Reg(self, EventType.OnChangeTopBuffSetting, function()
        self:OnInit()
    end)
    Event.Reg(self, EventType.OnTopBuffSetting, function(nIconSize, nIconPosition)
        self.nIconSize = nIconSize
        self.nIconPosition = nIconPosition
        self:InitPosSetting()
    end)
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:InitPosSetting(true)
    end)
end

function UIWidgetTopBuff:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetTopBuff:InitPosSetting(bReUpdate)
    if not self.parentNode then return end

    local arrawW, arrawH = UIHelper.GetContentSize(self.LayoutHeadBuff2)
    if not bReUpdate then
        local layoutWidth, layoutHeight = UIHelper.GetContentSize(self.parentNode)
        UIHelper.SetPosition(self.LayoutHeadBuff2, layoutWidth * 0.5, 0)
    end

    local screenSize = UIHelper.GetSafeAreaRect()
    local pw, ph = screenSize.width, screenSize.height
    local scaleX, scaleY = UIHelper.GetScreenToResolutionScale()
    local width, height = UIHelper.GetContentSize(self.parentNode)

    scaleX = 1 / scaleX
    scaleY = 1 / scaleY
    local baseOffsetY = ph * 0.5 + height * 0.5
    local baseOffsetX = -pw * 0.5 - width * 0.5

    baseOffsetX = baseOffsetX + 0 -- 偏移量在此处修改
    baseOffsetY = baseOffsetY + self.nIconPosition -- 偏移量在此处修改

    Timer.DelTimer(self, self.nCycleTimeID)
    self:UpdatePos(width, height, scaleX, scaleY, baseOffsetX, baseOffsetY)
    self.nCycleTimeID = Timer.AddFrameCycle(self, 1, function()
        self:UpdatePos(width, height, scaleX, scaleY, baseOffsetX, baseOffsetY)
    end)
end

function UIWidgetTopBuff:UpdatePos(width, height, scaleX, scaley, baseOffsetX, baseOffsetY)
    local player = GetClientPlayer()
    if not player then
        return
    end

    local nX, nY = Scene_GetCharacterTopScreenPosX3D(self.dwPlayerID)
    if not nX or not nY then
        return
    end

    local position = GetCharacterTopScreenXYZ(self.dwPlayerID)
    if position.z < 0 then
        UIHelper.SetVisible(self.parentNode, false)
        return
    end

    local contentScale = 1
    if Platform.IsWindows() then
        contentScale = 0.82
    end

    local nSizeScale = self.nIconSize / TopBuffDefaultInfo.nIconSize.nDefault
    contentScale = contentScale * nSizeScale

    if self.dwPlayerID ~= player.dwID then
        local nDistance = GetCharacterDistance(self.dwPlayerID, player.dwID)
        if nDistance > NORMAL_SCALE_DISTANCE then
            local nCoefficient = (BALLOON_VISIBLE_DISTANCE - (nDistance - NORMAL_SCALE_DISTANCE) * 2) / BALLOON_VISIBLE_DISTANCE
            contentScale = contentScale * math.max(DistancelScaleMin, nCoefficient)
        end
        if nDistance > BALLOON_VISIBLE_DISTANCE or contentScale < 0 then
            UIHelper.SetVisible(self.parentNode, false)
            return
        end
    end

    UIHelper.SetVisible(self.parentNode, true)

    local scaleOffsetX = width * 0.5
    local scaleOffsetY = height * 0.5 * scaley
    local offsetX = baseOffsetX + (1 - contentScale) * scaleOffsetX
    local offsetY = baseOffsetY - (1 - contentScale) * scaleOffsetY
    local position = { x = nX, y = nY }

    UIHelper.SetPosition(self.parentNode, position.x * scaleX + offsetX, -position.y * scaley + offsetY)
    UIHelper.SetScale(self.parentNode, contentScale, contentScale)
end

function UIWidgetTopBuff:OnUpdate()
    if not self.tBuffBox then return end
    if TopBuffData.IsSettingMode() then return end
    for _, box in pairs(self.tBuffBox) do
        local buff          = box.buff
        local nLeftFrame    = Buffer_GetLeftFrame(box)
        local szTime, nFont, nLeft, r, g, b = TimeLib.Time_GetTextData(nLeftFrame, true)
        local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nLeft, true) --策划需求 超过1小时也不显示
        if Table_BuffNeedShowTime(buff.dwID, buff.nLevel) and nH < 1 then
            if box.szTime ~= szTime then
                box:SetTime(szTime)
                box.szTime = szTime
            end
        else
            box:SetTime(" ")
        end
    end
end

function UIWidgetTopBuff:OnBuffUpdate()
    if TopBuffData.IsSettingMode() then
        return
    end

    local tBuff = self:GetPlayerBuffList()
    if not tBuff then
        return
    end

    -- 70192, --定身
    -- 70193, --眩晕
    -- 70196, --锁足
    -- 70199, --内功沉默
    -- 70200, --外功沉默
    -- 70201, --轻功沉默
    -- 70202, --缴械
    -- 70205, --禁疗
    -- 70884, --倒地

    local bNeedInit = false
    for dwIconFrame, tInfo in pairs(tBuff) do
        local buff = tInfo.buff
        local box = self.tBuffBox[dwIconFrame]
        if box and box.nStrength == tInfo.nStrength then
            box.nEndFrame = buff.nEndFrame
            box.buff = buff
        else
            bNeedInit = true
            break
        end
    end
    
    if not bNeedInit then
        for dwIconFrame, box in pairs(self.tBuffBox) do
            local tInfo = tBuff[dwIconFrame]
            if tInfo and box.nStrength == tInfo.nStrength then
                local buff = tInfo.buff
                box.nEndFrame = buff.nEndFrame
                box.buff = buff
            else
                bNeedInit = true
                break
            end
        end
    end
    
    if not bNeedInit then return end
    self:OnInit()
end

function UIWidgetTopBuff:UpdateInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end

    if not self.tBuff or IsTableEmpty(self.tBuff) then
        UIHelper.SetVisible(self.parentNode, false)
        return
    end

    --取优先级高的3个：
    --自己和友军优先取减益
    --敌方优先取增益
    --同增减益类型之间剩余时间短的在前面
    local tBuffList = {}
    local bShowPowerUp = player.dwID ~= self.dwPlayerID and IsEnemy(player.dwID, self.dwPlayerID) or false
    for dwIconFrame, tInfo in pairs(self.tBuff) do
        table.insert(tBuffList, tInfo)
    end
    table.sort(tBuffList, function(a, b)
        if a.bIsPowerUp ~= b.bIsPowerUp then
            if bShowPowerUp then
                return a.bIsPowerUp
            else
                return not a.bIsPowerUp
            end
        else
            return a.buff.nEndFrame < b.buff.nEndFrame
        end
    end)

    UIHelper.SetVisible(self.parentNode, true)

    local nIndex = 1
    while nIndex <= #tBuffList and nIndex <= 3 do
        local tInfo = tBuffList[nIndex]
        local dwIconFrame = tInfo.dwIconFrame
        self.tBuffBox[dwIconFrame] = self.tBuffBox[dwIconFrame] or self:AddBuffIcon(dwIconFrame, tInfo)
        nIndex = nIndex + 1
    end

    -- for dwIconFrame, tInfo in pairs(self.tBuff) do
    --     self.tBuffBox[dwIconFrame] = self.tBuffBox[dwIconFrame] or self:AddBuffIcon(dwIconFrame, tInfo)
    -- end

    UIHelper.CascadeDoLayoutDoWidget(self.parentNode, true, true)
end

function UIWidgetTopBuff:AddBuffIcon(dwIconFrame, tInfo)
    local buff = tInfo.buff
    local nStrength = tInfo.nStrength
    local dwStrengthFrame = tInfo.dwStrengthFrame

    local script
    for i, v in ipairs(self.tBuffCellScrips) do
        if not UIHelper.GetVisible(v._rootNode) then
            script = v
        end
    end

    if not script then
        return
    end

    UIHelper.SetVisible(script._rootNode, true)
    
    script.nEndFrame    = buff.nEndFrame
    script.nStrength    = tInfo.nStrength
    script.buff         = buff

    if TopBuffData.IsSettingMode() then
        local szPath = szImagePath .. dwIconFrame
        script:UpdateTopBuff(szPath, szSettingModePreviewTime)
        return script
    end

    local nLeftFrame    = Buffer_GetLeftFrame(script)
    local szTime, nFont, nLeft, r, g, b = TimeLib.Time_GetTextData(nLeftFrame, true)
    local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nLeft, true) --策划需求 超过1小时也不显示
    if not Table_BuffNeedShowTime(buff.dwID, buff.nLevel) or nH >= 1 then
        szTime = " "
    end

    local szPath = szImagePath .. dwIconFrame
    script:UpdateTopBuff(szPath, szTime)

    return script
end

function UIWidgetTopBuff:GetPlayerBuffList()
    local player = GetClientPlayer()
    if not player then return end
    
    local pPlayer 
    if self.dwPlayerID then
        pPlayer = GetPlayer(self.dwPlayerID)
    else
        local dwType, dwID = player.GetTarget()
        pPlayer = GetTargetHandle(dwType, dwID)
    end
    if not pPlayer then return end
    
    local tBuff = {}
    local nBuffCount = 0
    for i = 1, pPlayer.GetBuffCount() do
        local buff = {}
        Buffer_Get(pPlayer, i - 1, buff)
        if buff.dwID then --当buff被标记客户端删除的时候，逻辑不会返回该buff
            local tIconList, tTopBuff = self:GetBuffIconList(buff.dwID, buff.nLevel)
            for dwIconFrame, tIcon in pairs(tIconList) do
                local tCurInfo = tBuff[dwIconFrame]
                tIcon.buff = buff
                tIcon.dwIconFrame = dwIconFrame
                tIcon.bIsPowerUp = buff.bCanCancel  -- 增益buff的定义就是可被删除的buff
                if tCurInfo and tCurInfo.buff then
                    local curBuff = tCurInfo.buff
                    if tIcon.nStrength > tCurInfo.nStrength then -- 优先显示等级强的，次之同一强度下显示时间长的
                        tBuff[dwIconFrame] = tIcon
                    elseif tCurInfo.nStrength == tIcon.nStrength and buff.nEndFrame > curBuff.nEndFrame then
                        tBuff[dwIconFrame] = tIcon
                    end
                else
                    tBuff[dwIconFrame] = tIcon
                    nBuffCount = nBuffCount + 1
                end
            end
        end
    end

    -- 设置预览模式
    if TopBuffData.IsSettingMode() then
        tBuff = tSettingModePreviewBuff or {}
        nBuffCount = table.get_len(tBuff)
    end

    return tBuff, nBuffCount
end

function UIWidgetTopBuff:GetBuffIconList(dwID, nLevel)  -- 返回的tIconFrame是定位了Buff和Level的
    local tIconFrame = {}
    
    local tTopBuff = IsHaveTopBuff(dwID, nLevel) and GetTopBuffInfo(dwID, nLevel)
    if not tTopBuff or IsTableEmpty(tTopBuff) then 
        tTopBuff = IsHaveTopBuff(dwID, 0) and GetTopBuffInfo(dwID, 0)
    end
    if not tTopBuff or IsTableEmpty(tTopBuff) then
        return tIconFrame, {}
    end

    for i = 1, 3 do
        local dwIconFrame = tTopBuff["nVKPathNum" .. i]
        local nStrength = tTopBuff["StrengthLevel" .. i]
        local dwStrengthFrame = tTopBuff["LevelFrame" .. i]
        if dwIconFrame > 0 then
            tIconFrame[dwIconFrame] = {nStrength = nStrength, dwStrengthFrame = dwStrengthFrame, }
        end
    end
    return tIconFrame
end

return UIWidgetTopBuff