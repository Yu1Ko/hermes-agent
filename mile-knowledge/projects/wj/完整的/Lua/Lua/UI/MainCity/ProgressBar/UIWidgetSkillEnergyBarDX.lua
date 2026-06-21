-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UIWidgetSkillEnergyBarDX
-- Date: 2025-08-11 16:40:08
-- Desc: 技能能量条 
-- ---------------------------------------------------------------------------------

local nCycleTime = 1 / 16

local ENERGY_FUNC_DICT = {
    [KUNGFU_TYPE.CHUN_YANG] = "CY",
    [KUNGFU_TYPE.SHAO_LIN] = "SL",
    [KUNGFU_TYPE.TANG_MEN] = "TM",
    [KUNGFU_TYPE.QI_XIU] = "QX",
    [KUNGFU_TYPE.MING_JIAO] = "MJ",
    [KUNGFU_TYPE.CANG_JIAN] = "CJ",
    [KUNGFU_TYPE.CANG_YUN] = "CangYun",
    [KUNGFU_TYPE.CHANG_GE] = "CG",
    [KUNGFU_TYPE.BA_DAO] = "BaDao",
    [KUNGFU_TYPE.TIAN_CE] = "TC",
    [KUNGFU_TYPE.YAN_TIAN] = "YT",
    [KUNGFU_TYPE.YAO_ZONG] = "YZ",
    [KUNGFU_TYPE.DAO_ZONG] = "DZ",
    [KUNGFU_TYPE.WAN_HUA] = "WH",
    [KUNGFU_TYPE.WAN_LING] = "WL",
    [KUNGFU_TYPE.DUAN_SHI] = "DS",
    [KUNGFU_TYPE.GAI_BANG] = "GB",
    [KUNGFU_TYPE.WU_DU] = "WD",
    [KUNGFU_TYPE.WU_XIANG] = "WX",
}

local tPetNPCID2Icon = {
    [9997] = "UIAtlas2_SkillDX_EnergyBar_WuDu_zhizhu",
    [9956] = "UIAtlas2_SkillDX_EnergyBar_WuDu_xiezi",
    [9996] = "UIAtlas2_SkillDX_EnergyBar_WuDu_wugong",
    [9998] = "UIAtlas2_SkillDX_EnergyBar_WuDu_she",
    [9999] = "UIAtlas2_SkillDX_EnergyBar_WuDu_chanchu",
    [12944] = "UIAtlas2_SkillDX_EnergyBar_WuDu_hudie",
    [111963] = "UIAtlas2_SkillDX_EnergyBar_WuDu_kongque",
}

local function fnGetPercent(nNumUp, nNumDown)
    local fPer = 1
    if nNumDown and nNumDown ~= 0 then
        fPer = nNumUp / nNumDown
    end
    return fPer
end

local function QX_IsInJIanWu(player)
    return Buff_Have(player, 409, 21)
end

local function QX_IsInQuZhong(player)
    return Buff_Have(player, 30661, 1)
end

local function GetDZStateType(nPoseState)
    if nPoseState == POSE_TYPE.SINGLEKNIFE or nPoseState == POSE_TYPE.SINGLEKNIFEIN then
        return 1
    elseif nPoseState == POSE_TYPE.DOUBLEKNIFE or nPoseState == POSE_TYPE.DOUBLEKNIFEIN then
        return 2
    end
end

local function IsShowSelfStateValueByPercentage()
    return false
end

local tbYTShortFrameList = {
    [2] = "UIAtlas2_SkillDX_EnergyBar_YanTian_bar_short_gold",
    [1] = "UIAtlas2_SkillDX_EnergyBar_YanTian_bar_short_purple"
}

local tBuffIDtoGuaXiang = {
    [17588] = "Water",
    [17801] = "Mountain",
    [17802] = "Fire",
}

local tbYTSfxList = {
    ["Water"] = "data\\source\\other\\HD特效\\其他\\Pss\\ui_衍天宗能量水01.pss",
    ["Fire"] = "data\\source\\other\\HD特效\\其他\\Pss\\ui_衍天宗能量火01.pss",
    ["Mountain"] = "data\\source\\other\\HD特效\\其他\\Pss\\ui_衍天宗能量山01.pss",
}

local tbYTDivinationSfxList = {
    ["DWater"] = {
        [1] = "data\\source\\other\\HD特效\\其他\\Pss\\ui_衍天宗能量旋转水01.pss",
        [2] = "data\\source\\other\\HD特效\\其他\\Pss\\ui_衍天宗能量旋转水02.pss",
    },
    ["DMountain"] = {
        [1] = "data\\source\\other\\HD特效\\其他\\Pss\\ui_衍天宗能量旋转山01.pss",
        [2] = "data\\source\\other\\HD特效\\其他\\Pss\\ui_衍天宗能量旋转山02.pss",
    },
    ["DFire"] = {
        [1] = "data\\source\\other\\HD特效\\其他\\Pss\\ui_衍天宗能量旋转火01.pss",
        [2] = "data\\source\\other\\HD特效\\其他\\Pss\\ui_衍天宗能量旋转火02.pss",
    }
}

local tBuffLeveltoDivition = {
    [1] = "DFire",
    [2] = "DWater",
    [3] = "DMountain",
}

local YT_DIVITION_BUFF_ID = 21027

local UIWidgetSkillEnergyBarDX = class("UIWidgetSkillEnergyBarDX")

function UIWidgetSkillEnergyBarDX:OnEnter(bCustom)
    self.mainWidget = {
        [KUNGFU_TYPE.CHUN_YANG] = self.WidgetChunYang,
        [KUNGFU_TYPE.SHAO_LIN] = self.WidgetShaoLin,
        [KUNGFU_TYPE.TIAN_CE] = self.WidgetTianCe,
        [KUNGFU_TYPE.CANG_YUN] = self.WidgetCangYun,
        [KUNGFU_TYPE.CANG_JIAN] = self.WidgetCangJian,
        [KUNGFU_TYPE.BA_DAO] = self.WidgetBaDao,
        [KUNGFU_TYPE.WAN_HUA] = self.WidgetWanHua,
        [KUNGFU_TYPE.QI_XIU] = self.WidgetQiXiu,
        [KUNGFU_TYPE.DUAN_SHI] = self.WidgetDuanShi,
        [KUNGFU_TYPE.DAO_ZONG] = self.WidgetDaoZong,
        [KUNGFU_TYPE.GAI_BANG] = self.WidgetGaiBang,
        [KUNGFU_TYPE.TANG_MEN] = self.WidgetTangMen,
        [KUNGFU_TYPE.WU_DU] = self.WidgetWuDu,
        [KUNGFU_TYPE.MING_JIAO] = self.WidgetMingJiao,
        [KUNGFU_TYPE.WAN_LING] = self.WidgetWanLing,
        [KUNGFU_TYPE.YAO_ZONG] = self.WidgetYaoZong,
        [KUNGFU_TYPE.CHANG_GE] = self.WidgetChangGe,
        [KUNGFU_TYPE.YAN_TIAN] = self.WidgetYanTian,
        [KUNGFU_TYPE.WU_XIANG] = self.WidgetWuXiangLou,
    }
    if bCustom then
        self:UpdateCustomInfo()
    else
        if not self.bInit then
            self.bInit = true
            self:RegEvent()
            self:BindUIEvent()
        end
        self:UpdateInfo()
    end

end

function UIWidgetSkillEnergyBarDX:OnExit()
    Event.UnRegAll(self)
end

function UIWidgetSkillEnergyBarDX:BindUIEvent()
end

function UIWidgetSkillEnergyBarDX:RegEvent()
end

function UIWidgetSkillEnergyBarDX:UnRegEvent()
end

function UIWidgetSkillEnergyBarDX:UpdateInfo()
    Event.UnRegAll(self)

    local player = g_pClientPlayer
    if SkillData.IsEnergyShow(player) then
        local skill = player.GetKungfuMount()
        local parent = self.mainWidget[skill.dwMountType]
        if parent then
            self.dwKungFuID = skill.dwSkillID
            UIHelper.SetVisible(parent, true)
            for i = 1, #self.tAllEnergyBars do
                if parent ~= self.tAllEnergyBars[i] then
                    UIHelper.RemoveFromParent(self.tAllEnergyBars[i], true)
                end
            end

            local szType = ENERGY_FUNC_DICT[skill.dwMountType]
            local updateFunc = self[szType]
            if updateFunc then
                updateFunc(self, player)
            end

            local script = UIHelper.GetBindScript(parent)
            Event.Reg(self, "Move", function(name, x, y)
                if script[name] then
                    UIHelper.SetPosition(script[name], x, y)
                end
            end)
            return
        end
    end

    for i = 1, #self.tAllEnergyBars do
        UIHelper.RemoveFromParent(self.tAllEnergyBars[i], true)
    end

end

function UIWidgetSkillEnergyBarDX:QX(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetQiXiu)

    local fnUpdate = function(player)
        local nMaxCount = 5
        local nValue = player.nAccumulateValue
        nValue = math.max(nValue, 0)
        nValue = math.min(nValue, nMaxCount)

        for i = 1, nMaxCount, 1 do
            UIHelper.SetActiveAndCache(self, script.tActivated[i], i <= nValue)
        end

        local bInJianWu = QX_IsInJIanWu(player)
        local bInQuZhong = QX_IsInQuZhong(player)
        if bInJianWu then
            UIHelper.SetLabel(script.LabelNumQiXiu, nValue)
        end

        UIHelper.SetActiveAndCache(self, script.LabelNumQiXiu, bInJianWu)
        UIHelper.SetActiveAndCache(self, script.JianWuSFX, bInJianWu and not bInQuZhong)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:CY(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetChunYang)
    local dwKungFuID = player.GetActualKungfuMountID()
    local bIsQiChun = dwKungFuID == 10014
    local sliderBar = bIsQiChun and script.barQiChun or script.barJianChun
    local parent = bIsQiChun and script.WidgetQiChun or script.WidgetJianChun
    local Width = UIHelper.GetWidth(sliderBar)
    UIHelper.SetActiveAndCache(self, script.WidgetQiChun, false)
    UIHelper.SetActiveAndCache(self, script.WidgetJianChun, false)
    UIHelper.SetActiveAndCache(self, script.LabelNumChunYang, false)

    local fnUpdate = function(player)
        local nMaxCount = 16
        local nValue = player.nAccumulateValue

        nValue = math.max(nValue, 0)
        nValue = math.min(nValue, nMaxCount)

        if nValue > 16 then
            nValue = 16
        end

        local k = math.floor((nValue + 1) / 2)
        local bHalf = nValue % 2 ~= 0
        local bFullCount = bHalf and k - 1 or k
        for i = 1, 8 do
            UIHelper.SetActiveAndCache(self, script.tDouChunYang[i], bFullCount >= i)
        end
        UIHelper.SetActiveAndCache(self, script.tDouChunYang[9], k <= 5 and nValue % 2 ~= 0)
        UIHelper.SetActiveAndCache(self, script.tDouChunYang[10], k > 5 and nValue % 2 ~= 0)
        UIHelper.LayoutDoLayout(script.WidgetDouChunYang)

        local nRage = player.nCurrentRage
        local nMaxRage = player.nMaxRage

        UIHelper.SetActiveAndCache(self, parent, not bIsQiChun)
        UIHelper.SetActiveAndCache(self, script.LabelNumChunYang, not bIsQiChun)
        if not bIsQiChun then
            local bInRJHY = Player_IsBuffExist(29204, player, 1)
            local bEnter = nRage == nMaxRage
            UIHelper.SetLabel(script.LabelNumChunYang, nRage)

            if nMaxRage == 0 then
                return
            end

            local bShowAdd = not bEnter and not bInRJHY
            if bShowAdd and nRage ~= 0 then
                UIHelper.SetPositionX(script.DotParent, nRage / nMaxRage * Width)
            end
            UIHelper.SetProgressBarPercent(sliderBar, nRage / nMaxRage * 100)
            
            local bShowReduce = not bEnter and bInRJHY
            UIHelper.SetActiveAndCache(self, script.SFX_Reduce, bShowReduce and nRage ~= 0)
            UIHelper.SetActiveAndCache(self, script.DotParent, bShowAdd and nRage ~= 0)
            
            if bEnter then
                if not script.bPlayFillUpNotice then
                    UIHelper.SetActiveAndCache(self, script.SFX_Full, true)
                    UIHelper.PlaySFX(script.SFX_Full)
                    script.bPlayFillUpNotice = true
                end
            else
                UIHelper.SetActiveAndCache(self, script.SFX_Full, false)
                script.bPlayFillUpNotice = false
            end
        end
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:SL(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetShaoLin)
    local actualNodeScript3 = UIHelper.GetBindScript(script.Widget3)
    local actualNodeScript6 = UIHelper.GetBindScript(script.Widget6)
    local fnUpdate = function(player)
        local bExpand = Player_IsBuffExist(33074, player, 1)
        local actualNodeScript = bExpand and actualNodeScript6 or actualNodeScript3
        local nValue = player.nAccumulateValue
        nValue = math.max(nValue, 0)

        for i = 1, 6 do
            if bExpand then
                nValue = math.min(nValue, 6)
                UIHelper.SetActiveAndCache(self, actualNodeScript.tBase[i], i <= 6)
                UIHelper.SetActiveAndCache(self, actualNodeScript.tActivated[i], i <= nValue)
            else
                nValue = math.min(nValue, 3)
                UIHelper.SetActiveAndCache(self, actualNodeScript.tBase[i], i <= 3)
                UIHelper.SetActiveAndCache(self, actualNodeScript.tActivated[i], i <= nValue)
            end
        end

        if nValue ~= self.nShaoLinValue then
            self.nShaoLinValue = nValue
            UIHelper.LayoutDoLayout(actualNodeScript.WidgetDouShaoLin)
            UIHelper.LayoutDoLayout(actualNodeScript.WidgetDouShaoLinOn)
        end

        UIHelper.SetActiveAndCache(self, script.Widget3, not bExpand)
        UIHelper.SetActiveAndCache(self, script.Widget6, bExpand)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:TC(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetTianCe)
    local fnUpdate = function(player)
        local fRage
        if player.nMaxRage == 0 then
            fRage = 100
        else
            fRage = player.nCurrentRage / player.nMaxRage * 100
        end

        UIHelper.SetLabel(script.LabelNumTianCe, player.nCurrentRage .. "/" .. player.nMaxRage)
        UIHelper.SetProgressBarPercent(script.barTianCe, fRage)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:CangYun(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetCangYun)
    local fnUpdate = function(player)
        if player.nMaxRage > 0 then
            local fRage = player.nCurrentRage / player.nMaxRage * 100
            --if player.nCurrentRage == player.nMaxRage then
            --    hList:Lookup("Image_Rang"):SetFrame(2)
            --else
            --    hList:Lookup("Image_Rang"):SetFrame(1)
            --end

            UIHelper.SetLabel(script.LabelSliderNumCY, player.nCurrentRage .. "/" .. player.nMaxRage)
            UIHelper.SetProgressBarPercent(script.barCangYun, fRage)
        else
            UIHelper.SetLabel(script.LabelSliderNumCY, "")
            UIHelper.SetProgressBarPercent(script.barCangYun, 0)
        end

        UIHelper.SetActiveAndCache(self, script.ImgShield, player.nPoseState == POSE_TYPE.SHIELD)
        UIHelper.SetActiveAndCache(self, script.ImgSword, player.nPoseState == POSE_TYPE.SWORD)

        if player.nLevel >= 40 then
            local nEnergy = player.nCurrentEnergy

            UIHelper.SetLabel(script.LabelShieldNumCangYun, nEnergy)
            UIHelper.SetActiveAndCache(self, script.ImgNor, nEnergy > 0)
            UIHelper.SetActiveAndCache(self, script.ImgRed, nEnergy == 0)
            UIHelper.SetActiveAndCache(self, script.ImgPro, true)

            if player.nMaxEnergy > 0 then
                local fPer = (nEnergy / player.nMaxEnergy) * 80 + 10
                UIHelper.SetProgressBarPercent(script.ImgPro, fPer)
            else
                UIHelper.SetProgressBarPercent(script.ImgPro, 0)
            end
        end

        UIHelper.SetActiveAndCache(self, script.WidgetShield, player.nLevel >= 40)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:CJ(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetCangJian)
    local fnUpdate = function(player)
        local bShort = player.nMaxRage <= 100
        local sliderBar = bShort and script.barQing or script.barZhong
        if player.nMaxRage > 0 then
            local fRage = player.nCurrentRage / player.nMaxRage * 100
            UIHelper.SetProgressBarPercent(sliderBar, fRage)
            UIHelper.SetLabel(script.LabelNumCangJian, player.nCurrentRage .. "/" .. player.nMaxRage)
            --if IsShowSelfStateValueByPercentage() then
            --    hList:Lookup("Text_"..szShow):SetText(string.format("%d%%", 100 * fRage))
            --else
            --    hList:Lookup("Text_"..szShow):SetText()
            --end
        else
            UIHelper.SetProgressBarPercent(sliderBar, 0)
            UIHelper.SetLabel(script.LabelNumCangJian, "")
        end

        UIHelper.SetActiveAndCache(self, script.WidgetQing, bShort)
        UIHelper.SetActiveAndCache(self, script.WidgetZhong, not bShort)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:BaDao(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetBaDao)
    local tNodeList = {
        [POSE_TYPE.BROADSWORD] = {
            Red = script.ImgBarBgDadaoRed,
            Yellow = script.ImgBarBgDadaoYellow,
            SliderBar = script.barDadao
        },
        [POSE_TYPE.SHEATH_KNIFE] = {
            Red = script.ImgBarBgQiaodaoRed,
            Yellow = script.ImgBarBgQiaodaoYellow,
            SliderBar = script.barQiaodao
        },
        [POSE_TYPE.DOUBLE_BLADE] = {
            Red = script.ImgBarBgShuangdaoRed,
            Yellow = script.ImgBarBgShuangdaoYellow,
            SliderBar = script.barShuangdao
        }
    }
    local fnUpdate = function(player)
        local nPoseState = player.nPoseState
        UIHelper.SetActiveAndCache(self, script.WidgetDadao, nPoseState == POSE_TYPE.BROADSWORD)
        UIHelper.SetActiveAndCache(self, script.WidgetQiaodao, nPoseState == POSE_TYPE.SHEATH_KNIFE)
        UIHelper.SetActiveAndCache(self, script.WidgetShuangdao, nPoseState == POSE_TYPE.DOUBLE_BLADE)

        local nCurrentNumber, nMaxNumber
        if player.nPoseState == POSE_TYPE.BROADSWORD then
            nCurrentNumber = player.nCurrentRage
            nMaxNumber = player.nMaxRage
        elseif player.nPoseState == POSE_TYPE.DOUBLE_BLADE then
            nCurrentNumber = player.nCurrentEnergy
            nMaxNumber = player.nMaxEnergy
        elseif player.nPoseState == POSE_TYPE.SHEATH_KNIFE then
            nCurrentNumber = player.nCurrentSunEnergy
            nMaxNumber = player.nMaxSunEnergy
        end
        local nRedAlpha = 255 - math.floor((nCurrentNumber / (nMaxNumber / 1.5)) * 255)
        if nRedAlpha < 0 then
            nRedAlpha = 0
        end
        local nPercent = fnGetPercent(nCurrentNumber, nMaxNumber) * 100
        local nYellowAlpha = 255 - math.floor(math.abs(nCurrentNumber - (nMaxNumber / 2)) / (nMaxNumber / 2) * 255)
        UIHelper.SetProgressBarPercent(tNodeList[nPoseState].SliderBar, nPercent)
        UIHelper.SetOpacity(tNodeList[nPoseState].Red, nRedAlpha)
        UIHelper.SetOpacity(tNodeList[nPoseState].Yellow, nYellowAlpha)
        UIHelper.SetLabel(script.LabelNumBaDao, nCurrentNumber .. "/" .. nMaxNumber)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:WH(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetWanHua)

    local fnUpdate = function(player)
        local nEnergy = player.nCurrentEnergy
        if nEnergy >= 1 then
            local nTrueEnergy = nEnergy - 1
            for i, node in ipairs(script.tWanHuaDou) do
                UIHelper.SetActiveAndCache(self, node, i <= nTrueEnergy)
            end
            UIHelper.SetActiveAndCache(self, script.WidgetDouWanHua, true)

            local tBuff = {}
            Buffer_GetByID(player, 28107, 1, tBuff)
            local nStackNum = tBuff.nStackNum or 0
            UIHelper.SetLabel(script.LabelWanHuaDou, nStackNum)

            UIHelper.SetActiveAndCache(self, script.WidgetDouWanHua, true)
        else
            UIHelper.SetActiveAndCache(self, script.WidgetDouWanHua, false)
        end

        local nCurRage = player.nCurrentRage
        local nMaxRage = player.nMaxRage
        local nMaxCount = player.nMaxRage / 20 -- 花花数量
        local nStep = 20
        UIHelper.SetActiveAndCache(self, script.Widget5Hua, nMaxCount == 5)
        UIHelper.SetActiveAndCache(self, script.Widget3Hua, nMaxCount == 3)
        UIHelper.SetLabel(script.LabelWanHuaEnergy, nCurRage .. "/" .. nMaxRage)
        -- UIHelper.SetProgressBarPercent(script.LabelNumWanHuaDou, player.nCurrentRage .. "/" .. player.nMaxRage)

        local bar = nMaxCount == 5 and script.barHua5 or script.barHua3
        local tFlowerList = nMaxCount == 5 and script.t5Flower or script.t3Flower
        for i = 1, nMaxCount do
            local bShow = player.nCurrentRage >= nStep * i
            UIHelper.SetActiveAndCache(self, tFlowerList[i], bShow)
        end
        UIHelper.SetProgressBarPercent(bar, fnGetPercent(nCurRage, nMaxRage) * 100)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:DS(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetDuanShi)

    local fnUpdate = function(player)
        local fSunPer, fMoonPer = 0, 0
        local bSunFull, bMoonFull = false, false
        if player.nMaxSunEnergy ~= 0 then
            fSunPer = player.nCurrentSunEnergy / player.nMaxSunEnergy
            bSunFull = player.nCurrentSunEnergy == player.nMaxSunEnergy
        end
        if player.nMaxMoonEnergy ~= 0 then
            fMoonPer = player.nCurrentMoonEnergy / player.nMaxMoonEnergy
            bMoonFull = player.nCurrentMoonEnergy == player.nMaxMoonEnergy
        end

        UIHelper.SetLabel(script.LabelNumRen, player.nCurrentSunEnergy .. "/" .. player.nMaxSunEnergy)
        UIHelper.SetLabel(script.LabelNumDu, player.nCurrentMoonEnergy .. "/" .. player.nMaxMoonEnergy)
        UIHelper.SetProgressBarPercent(script.barRen, fSunPer * 100)
        UIHelper.SetProgressBarPercent(script.barDu, fMoonPer * 100)

        UIHelper.SetActiveAndCache(self, script.ImgDotRen, fSunPer >= 0.5)
        UIHelper.SetActiveAndCache(self, script.ImgDotDu, fMoonPer >= 0.5)

        UIHelper.SetActiveAndCache(self, script.SFX_RM_Half, fSunPer >= 0.5)
        UIHelper.SetActiveAndCache(self, script.SFX_DM_Half, fMoonPer >= 0.5)

        UIHelper.SetActiveAndCache(self, script.SFX_RenDuFull, bSunFull and bMoonFull)
        UIHelper.SetActiveAndCache(self, script.SFX_RM_FullBin, bSunFull and not bMoonFull)
        UIHelper.SetActiveAndCache(self, script.SFX_DM_FullBin, not bSunFull and bMoonFull)

        local bFlower = Buff_Have(player, 28968, 1)
        local bSnow = Buff_Have(player, 29212, 2)
        if bSnow then
            local tBuffInfo, nLeftTime = {}, 0
            Buffer_GetByID(player, 29212, 2, tBuffInfo)
            if tBuffInfo.dwID and tBuffInfo.dwID == 29212 then
                local nLeftFrame = Buffer_GetLeftFrame(tBuffInfo)
                local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)
                nLeftTime = nHour * 3600 + nMinute * 60 + nSecond
            end
            UIHelper.SetLabel(script.LabelNumHua, nLeftTime)
        elseif bFlower then
            local tBuffInfo, nLeftTime = {}, 0
            Buffer_GetByID(player, 28968, 1, tBuffInfo)
            if tBuffInfo.dwID and tBuffInfo.dwID == 28968 then
                local nLeftFrame = Buffer_GetLeftFrame(tBuffInfo)
                local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)
                nLeftTime = nHour * 3600 + nMinute * 60 + nSecond
            end
            UIHelper.SetLabel(script.LabelNumHua, nLeftTime)
        end

        UIHelper.SetActiveAndCache(self, script.ImgFlower, bFlower)
        UIHelper.SetActiveAndCache(self, script.ImgSnow, bSnow)
        UIHelper.SetActiveAndCache(self, script.LabelNumHua, bSnow or bFlower)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:DZ(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetDaoZong)

    local fnUpdate = function(player)
        local nNowType = GetDZStateType(player.nPoseState)
        --if self.nPoseState ~= nNowType then
        --    if hList.nPoseState then
        --        local hHandle = hList:Lookup("Handle_Switch_DZ")
        --        local nCount = hHandle:GetItemCount()
        --        hHandle:Show()
        --        for i = 0, nCount - 1 do
        --            local hSFX = hHandle:Lookup(i)
        --            if hSFX and hSFX:GetType() == "SFX" then
        --                hSFX:Play()
        --            end
        --        end
        --    end
        --    hList.nPoseState = nNowType
        --end

        local fPercent = fnGetPercent(player.nCurrentEnergy, player.nMaxEnergy)
        UIHelper.SetProgressBarPercent(script.barDaoZong, fPercent * 100)
        UIHelper.SetLabel(script.LabelNumDaoZong, player.nCurrentEnergy .. "/" .. player.nMaxEnergy)

        UIHelper.SetActiveAndCache(self, script.ImgDanshou, nNowType == 1)
        UIHelper.SetActiveAndCache(self, script.ImgShuangShou, nNowType == 2)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:GB(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetGaiBang)
    local nAllW = UIHelper.GetWidth(script.barBlue)
    local nLineWidth = 2

    local fnUpdate = function(player)
        local nMaxMana = player.nMaxMana or 0
        local nCurrentMana = player.nCurrentMana or 0
        local fPercent = 0
        if nMaxMana > 0 and nMaxMana ~= 1 then
            fPercent = nCurrentMana / nMaxMana
        end

        if fPercent > 0 and fPercent < 1 then
            UIHelper.SetPositionX(script.ImgLine, nAllW * fPercent - nLineWidth / 2)
        end
        UIHelper.SetProgressBarPercent(script.barBlue, fPercent * 100)
        UIHelper.SetActiveAndCache(self, script.ImgLine, fPercent > 0 and fPercent < 1)
        UIHelper.SetLabel(script.LabelNumGaiBang1, string.format("%.0f", fPercent * 100) .. "%")

        local nRage = player.nCurrentRage
        local nMaxRage = player.nMaxRage
        local tBuff = {}
        Buffer_GetByID(player, 30334, 0, tBuff)

        local nRageType = 1
        if nRage > 0 then
            nRageType = 2
        end

        if tBuff.nEndFrame then
            nRageType = 3   --醉逍遥状态3
        end

        local nLastRage = self.nLastRage or 0
        for i = 1, 3 do
            local hDrunk = script.tDrunkSfxList[i]
            if hDrunk then
                UIHelper.SetActiveAndCache(self, hDrunk, i <= nRage)
                if i <= nRage and i > nLastRage then
                    UIHelper.PlaySFX(hDrunk, false)
                end
            end
        end
        
        if tBuff.nEndFrame then
            local nLeftFrame = Buffer_GetLeftFrame(tBuff)
            local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)
            local fSecond = nSecond / 30
            UIHelper.SetLabel(script.LabelNumGaiBang2, nSecond)

            --if fSecond > 0 and fSecond < 1 then
            --    UIHelper.SetPositionX(script.ImgLine, nAllW * fSecond - nLineWidth / 2)
            --end
            --UIHelper.SetActiveAndCache(self, script.ImgLine, fSecond > 0 and fSecond < 1)
            --UIHelper.SetProgressBarPercent(script.barOrange, nSecond / 30 * 100)
        end

        for i = 1, 3 do
            UIHelper.SetActiveAndCache(self, script["ImgXiaoRen" .. i], nRageType == i)
        end
        UIHelper.SetActiveAndCache(self, script.barOrange, tBuff.nEndFrame ~= nil)
        UIHelper.SetActiveAndCache(self, script.LabelNumGaiBang2, tBuff.nEndFrame ~= nil)

        self.nLastRage = nRage
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:TM(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetTangMen)
    local tBombMsg = {}
    local nBombTotalTime = 60
    local nMountID = player.GetKungfuMountID()
    local nBombMaxDis = 3686400 --(30尺 * 64) ^ 2

    local fnUpdate = function(player)
        if not player.nMaxEnergy then
            return --每帧刷新
        end

        local fPer = 0
        local szText = ""
        if player.nMaxEnergy > 0 then
            fPer = player.nCurrentEnergy / player.nMaxEnergy
            szText = IsShowSelfStateValueByPercentage() and string.format("%d%%", 100 * fPer)
                    or player.nCurrentEnergy .. "/" .. player.nMaxEnergy
        end
        UIHelper.SetLabel(script.LabelNumShenJiZhi, szText)
        UIHelper.SetProgressBarPercent(script.barShenJiZhi, fPer * 100)

        local ACSJ_SKILL_BUFF_LIST_ID = 2 --唐门暗藏杀机BUFF列表
        local tBuffList, nBombID = Table_GetCustomBuffList(ACSJ_SKILL_BUFF_LIST_ID), nil
        for i, nBuffID in ipairs(tBuffList) do
            local bExist = player.IsHaveBuff(nBuffID, 1)
            if bExist then
                local tBuffInfo, nLeftTime = {}
                Buffer_GetByID(player, nBuffID, 0, tBuffInfo)
                if tBuffInfo.dwID and tBuffInfo.dwID == nBuffID then
                    local nLeftFrame = Buffer_GetLeftFrame(tBuffInfo)
                    local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)
                    nLeftTime = nHour * 3600 + nMinute * 60 + nSecond
                end
                if nLeftTime then
                    if tBombMsg[i] and tBombMsg[i].nTime >= nLeftTime then
                        tBombMsg[i].nTime = nLeftTime
                    else
                        tBombMsg[i] = { nID = nBuffID, nTime = nLeftTime }
                    end
                else
                    tBombMsg[i] = nil
                end
            else
                tBombMsg[i] = nil
            end
        end

        for i, nBuffID in ipairs(tBuffList) do
            local pBomb, bFound = player.GetBomb(i - 1), false
            if pBomb then
                for _, tBomb in pairs(tBombMsg) do
                    if tBomb.nBombNpcID == pBomb.dwID then
                        bFound = true
                        break
                    end
                end
                if not bFound then
                    nBombID = pBomb.dwID
                end
            end
        end
        if nBombID then
            for _, tBomb in pairs(tBombMsg) do
                if not tBomb.nBombNpcID then
                    tBomb.nBombNpcID = nBombID
                    break
                end
            end
        end

        for i, nBuffID in ipairs(tBuffList) do
            if tBombMsg[i] then
                UIHelper.SetProgressBarPercent(script.tBombCD[i], tBombMsg[i].nTime / nBombTotalTime * 100)
                UIHelper.SetLabel(script.tBombLabel[i], tostring(tBombMsg[i].nTime))
                if tBombMsg[i].nBombNpcID then
                    local nDistance = CalHorizontalDistance(tBombMsg[i].nBombNpcID)
                    UIHelper.SetOpacity(script.tBombList[i], nDistance and nDistance <= nBombMaxDis and 255 or 100)
                end
            end
            UIHelper.SetActiveAndCache(self, script.tBombList[i], tBombMsg[i] ~= nil)
        end

        if nMountID == 10224 then
            local tBuff = {}
            Buffer_GetByID(player, 3399, 1, tBuff)
            local nStackNum = tBuff.nStackNum or 0
            local nPercent = nStackNum * 33
            --for i = 1, 2 do
            --    hWuSheng:Lookup("SFX_Ws" .. i):Show(i == nStackNum)
            --end

            local bZMWS = Buff_Have(player, 3276, 1)
            nPercent = bZMWS and 100 or nPercent
            UIHelper.SetProgressBarPercent(script.barZhuiMing, nPercent)
        end
        UIHelper.SetActiveAndCache(self, script.WidgetZhuiMing, nMountID == 10224)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:WD(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetWuDu)
    local tPetIndex = { "Xie", "She", "WuGong", "Zhizhu", "HaMa" }
    local dwKungfuID = player.GetActualKungfuMountID()
    
    --Event.Reg(self, "OpenPetActionBar", function(dwNpcTemplateID)
    --    Timer.AddFrame(self, 5, function()
    --        local hPlayer = GetControlPlayer()
    --        if hPlayer then
    --            self.hPet = hPlayer.GetPet()
    --            local szPath = tPetNPCID2Icon[dwNpcTemplateID]
    --            if szPath then
    --                UIHelper.SetSpriteFrame(script.ImgPet, szPath)
    --            end
    --        else
    --            self.hPet = nil
    --        end
    --    end)
    --end)

    --Event.Reg(self, "REMOVE_PET_TEMPLATEID", function()
    --    self.hPet = nil
    --end)

    UIHelper.BindUIEvent(script.WidgetPet, EventType.OnClick, function()
        if self.hPet then
            SelectTarget(TARGET.NPC, self.hPet.dwID)
        end
    end)

    local fnUpdate = function(player)
        local nMaxCount = 5
        local nEnergy = player.nCurrentEnergy
        local nTrueEnergy = nEnergy - 1
        if nEnergy > 0 then
            for i = 1, nMaxCount do
                UIHelper.SetActiveAndCache(self, script.tWuduDou[i], i <= nTrueEnergy)
            end

            local nLastEnergy = self.nLastEnergy or 0
            if nTrueEnergy == nMaxCount and nLastEnergy ~= nTrueEnergy then
                UIHelper.PlaySFX(script.MergeSfx)
            end
            if nTrueEnergy < nLastEnergy then
                UIHelper.PlaySFX(script.SpreadSfx)
            end

            self.nLastEnergy = nTrueEnergy
        end
        UIHelper.SetActiveAndCache(self, script.WidgetWSS, nEnergy > 0 and nTrueEnergy ~= nMaxCount)
        UIHelper.SetActiveAndCache(self, script.MergeSfx, nEnergy > 0 and nTrueEnergy == nMaxCount)

        self.hPet = player.GetPet()
        local hPet = self.hPet
        UIHelper.SetActiveAndCache(self, script.WidgetPet, hPet ~= nil)
        if hPet then
            local fHealth = 0
            if hPet.nMaxLife > 0 then
                fHealth = math.floor(hPet.nCurrentLife / hPet.nMaxLife * 100)
            end
            local szShow = UIHelper.GetStateString(hPet.nCurrentLife, hPet.nMaxLife, false)
            UIHelper.SetProgressBarPercent(script.barPet, fHealth)
            UIHelper.SetLabel(script.LabelPetBlood, szShow)
        end

        if not script.nNowPlayFrame then
            script.nNowPlayFrame = 0
        end

        local nMoonEnergy = player.nCurrentMoonEnergy or 0
        local nLastMoonEnergy = script.nLastMoonEnergy or 0
        local szKungfuName = PlayerKungfuName[dwKungfuID] or ""
        if szKungfuName == "dujing" then
            local bChongPo = Buff_Have(player, 32058, 1)
            if bChongPo then
                UIHelper.SetActiveAndCache(self, script.WidgetSkill, false)
                UIHelper.SetActiveAndCache(self, script.Animate_ChongPo, true)
                if not script.bPlaySfx then
                    UIHelper.PlaySFX(script.Animate_ChongPo)
                    script.bPlaySfx = true
                end
            else
                UIHelper.SetActiveAndCache(self, script.WidgetSkill, true)
                UIHelper.SetActiveAndCache(self, script.Animate_ChongPo, false)
                for nIndex, szPetName in ipairs(tPetIndex) do
                    local hPet = script["Img" .. szPetName]
                    local hPetSFX = script["SFX_" .. szPetName]
                    local bPetEnergy = GetNumberBit(nMoonEnergy, nIndex)
                    local bLastPetEnergy = GetNumberBit(nLastMoonEnergy, nIndex)
                    UIHelper.SetActiveAndCache(self, hPetSFX, bPetEnergy)
                    UIHelper.SetActiveAndCache(self, hPet, not bPetEnergy)
                    if bPetEnergy and not bLastPetEnergy then
                        UIHelper.PlaySFX(hPetSFX)
                    end
                end
                script.bPlaySfx = false
            end
        end

        UIHelper.SetActiveAndCache(self, script.WidgetDuJing, szKungfuName == "dujing")
        script.nLastMoonEnergy = nMoonEnergy
    end
    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:MJ(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetMingJiao)

    UIHelper.BindUIEvent(script.BtnHat, EventType.OnClick, function()
        if APIHelper.IsHaveSecondRepresent() then
            local bInHat = APIHelper.IsInSecondRepresent()
            if bInHat then
                DoAction(g_pClientPlayer.dwID, 11471)
            else
                DoAction(g_pClientPlayer.dwID, 11470)
            end

            RemoteCallToServer("OnSwitchRepresent", INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.CHEST)
        end
    end)

    local function fnUpdate()
        local bInHat = APIHelper.IsInSecondRepresent()
        UIHelper.SetVisible(script.ImgHatOff, not bInHat)
        UIHelper.SetVisible(script.ImgHatOn, bInHat)
    end

    fnUpdate()
    Event.Reg(self, "PLAYER_DISPLAY_DATA_UPDATE", function()
        if g_pClientPlayer and arg0 == g_pClientPlayer.dwID then
            fnUpdate()
        end
    end)

    local fnUpdate = function(player)
        local bShowSunEnergy = (player.nCurrentSunEnergy > 0 or player.nCurrentMoonEnergy > 0)
                and player.nCurrentSunEnergy < 10000
        local bShowMoonEnergy = (player.nCurrentSunEnergy > 0 or player.nCurrentMoonEnergy > 0)
                and player.nCurrentMoonEnergy < 10000
        local sunPer, moonPer = 0, 0
        if player.nMaxSunEnergy ~= 0 then
            sunPer = player.nCurrentSunEnergy / player.nMaxSunEnergy
        end

        if player.nMaxMoonEnergy ~= 0 then
            moonPer = player.nCurrentMoonEnergy / player.nMaxMoonEnergy
        end

        UIHelper.SetProgressBarPercent(script.barSun, sunPer * 100)
        UIHelper.SetProgressBarPercent(script.barMoon, moonPer * 100)

        UIHelper.SetActiveAndCache(self, script.LabelNumRi, player.nSunPowerValue == 0 and player.nCurrentSunEnergy ~= player.nMaxSunEnergy and player.nCurrentSunEnergy ~= 0)
        UIHelper.SetActiveAndCache(self, script.LabelNumYue, player.nMoonPowerValue == 0 and player.nCurrentMoonEnergy ~= player.nMaxMoonEnergy and player.nCurrentMoonEnergy ~= 0)

        local nInteger = math.modf(sunPer * 100)
        nInteger = math.min(100, nInteger)
        UIHelper.SetLabel(script.LabelNumRi, nInteger)

        nInteger = math.modf(moonPer * 100)
        nInteger = math.min(100, nInteger)
        UIHelper.SetLabel(script.LabelNumYue, nInteger)

        UIHelper.SetActiveAndCache(self, script.ImgFullSun, player.nSunPowerValue > 0)
        UIHelper.SetActiveAndCache(self, script.ImgFullMoon, player.nMoonPowerValue > 0)
        UIHelper.SetActiveAndCache(self, script.ImgManYue_empty, player.nMoonPowerValue > 0)

        local bShowSpecialBg = player.nMoonPowerValue <= 0 and player.nSunPowerValue <= 0 and
                player.nCurrentSunEnergy <= 0 and player.nCurrentMoonEnergy <= 0

        UIHelper.SetActiveAndCache(self, script.SliderRi, player.nSunPowerValue <= 0 and not bShowSpecialBg)
        UIHelper.SetActiveAndCache(self, script.SliderYue, player.nMoonPowerValue <= 0 and not bShowSpecialBg)
        UIHelper.SetActiveAndCache(self, script.ImgManRi_empty, player.nSunPowerValue > 0 or bShowSpecialBg)
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:YZ(player)
    player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetYaoZong)

    local fnUpdate = function(player)
        local nValue = player.nNaturePowerValue
        local nOrigin = 100
        local nBarLength = UIHelper.GetHeight(script.ImgProgressDot)
        local nMax = player.nMaxNaturePowerGrid
        nValue = math.max(nValue, nOrigin - nMax)
        nValue = math.min(nValue, nOrigin + nMax)

        if not self.nLastNaturePower then
            self.nLastNaturePower = nOrigin
        end

        if nValue > self.nLastNaturePower then
            if self.nLastNaturePower < nOrigin then
                local nDest = math.min(nValue, nOrigin) - 1
                for i = self.nLastNaturePower, nDest, 1 do
                    local nIndex = nOrigin - i
                    UIHelper.SetActiveAndCache(self, script.tCold[nIndex], false)
                end
            end

            if nValue > nOrigin then
                local nStartIndex = math.max(nOrigin, self.nLastNaturePower)
                for i = nStartIndex + 1, nValue, 1 do
                    local nIndex = i - nOrigin
                    UIHelper.SetActiveAndCache(self, script.tHot[nIndex], true)
                end
            end
        end

        if nValue < self.nLastNaturePower then
            if self.nLastNaturePower > nOrigin then
                local nDest = math.max(nValue, nOrigin) + 1
                for i = self.nLastNaturePower, nDest, -1 do
                    local nIndex = i - nOrigin
                    UIHelper.SetActiveAndCache(self, script.tHot[nIndex], false)
                end
            end

            if nValue < nOrigin then
                local nStartIndex = math.min(nOrigin, self.nLastNaturePower)
                for i = nStartIndex - 1, nValue, -1 do
                    local nIndex = nOrigin - i
                    UIHelper.SetActiveAndCache(self, script.tCold[nIndex], true)
                end
            end
        end

        local nNeutralizationTime = 0
        if nValue > self.nLastNaturePower and self.nLastNaturePower < nOrigin then
            nNeutralizationTime = math.min(nOrigin - self.nLastNaturePower, nValue - self.nLastNaturePower)
        end

        if nValue < self.nLastNaturePower and self.nLastNaturePower > nOrigin then
            nNeutralizationTime = math.min(self.nLastNaturePower - nOrigin, self.nLastNaturePower - nValue)
        end

        if nNeutralizationTime > 0 then
            UIHelper.PlaySFX(script.ZhongHeSFX)
        end

        self.nLastNaturePower = nValue

        -- 蓝条
        local nMaxMana = player.nMaxMana or 0
        local nCurrentMana = player.nCurrentMana or 0
        local fPercent = 0

        if nMaxMana > 0 and nMaxMana ~= 1 then
            fPercent = nCurrentMana / nMaxMana
        end
        UIHelper.SetString(script.LabelYZEnergy, string.format("%.0f", fPercent * 100) .. "%")

        local bZhanRu = Buff_Have(player, 20075, 1)
        UIHelper.SetActiveAndCache(self, script.SliderYaoZong, not bZhanRu)
        UIHelper.SetActiveAndCache(self, script.SliderYaoZongFlower, bZhanRu)

        local bar = bZhanRu and script.ImgBarYaoZongProgressFlower or script.ImgBarYaoZongProgress
        local line = bZhanRu and script.ImgWenFlower or script.ImgWen
        UIHelper.SetProgressBarPercent(bar, fPercent * 100)

        if fPercent > 0 and fPercent < 1 then
            UIHelper.SetVisible(line, true)
            UIHelper.SetPositionY(line, fPercent * nBarLength)
        else
            UIHelper.SetVisible(line, false)
        end

        --self.nLastPercent = fPercent
    end

    self:StartUpdate(fnUpdate)
end

local m_tAccumulateStyle = {
    [FORCE_TYPE.CHANG_GE] = {
        [1] = "GaoShan",
        [2] = "YangChun",
        [3] = "MeiHua",
        [4] = "PingSha",
    },
}

local m_tStyleInfo = {
    [10447] = {
        [1] = {
            szBgImg = "UIAtlas2_SkillDX_EnergyBar_ChangGe_gsls.png",
            szBgSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_常态水.pss",
            szFullSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_爆发水.pss",
            szNormalEnterSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_蓝点出场.pss",
            szNormalExitSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_蓝点退场.pss",
            szSpecialEnterSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_水出场.pss",
            szSpecialExitSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_水退场.pss",
        },
        [2] = {
            szBgImg = "UIAtlas2_SkillDX_EnergyBar_ChangGe_ycbx.png",
            szBgSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_常态雪.pss",
            szFullSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_爆发雪.pss",
            szNormalEnterSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_绿点出场.pss",
            szNormalExitSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_绿点退场.pss",
            szSpecialEnterSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_雪出场.pss",
            szSpecialExitSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_雪退场.pss",
        },
        [4] = {
            szBgImg = "UIAtlas2_SkillDX_EnergyBar_ChangGe_psly.png",
            szBgSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_常态羽.pss",
            szFullSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_爆发羽.pss",
            szNormalEnterSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_紫点出场.pss",
            szNormalExitSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_紫点退场.pss",
            szSpecialEnterSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_羽出场.pss",
            szSpecialExitSFX = "data/source/other/HD特效/其他/Pss/UI_长歌技能_羽退场.pss",
        }
    },
    [10448] = {
        [1] = {
            szBgImg = "UIAtlas2_SkillDX_EnergyBar_ChangGe_03.png",
            szBgSFX = "data/source/other/HD特效/其他/Pss/C_长歌技能条UI_高山.pss"
        },
        [2] = {
            szBgImg = "UIAtlas2_SkillDX_EnergyBar_ChangGe_01.png",
            szBgSFX = "data/source/other/HD特效/其他/Pss/C_长歌技能条UI_白雪.pss"
        },
        [3] = {
            szBgImg = "UIAtlas2_SkillDX_EnergyBar_ChangGe_mhsn.png",
            szBgSFX = "data/source/other/HD特效/其他/Pss/C_长歌技能条UI_梅花.pss"
        }
    }
}

local nStyleToBuffID = {
    [1] = 9319,
    [2] = 9320,
    [3] = 9321,
    [4] = 9322,
}

local DOU_BUFF_ID = 31444
local NUM_BUFF_ID = 31441
local SFX_BUFF_ID = 31445
local function UpdateCGQuFengBuff(script, player, nStyle, dwKungFuID)
    local szNowSytle = m_tAccumulateStyle[FORCE_TYPE.CHANG_GE][nStyle]
    if not szNowSytle then
        return
    end

    local bSfxBuff = Buff_Have(player, SFX_BUFF_ID, 1)
    local hSfxFull = script.FullSFX
    if hSfxFull then
        if bSfxBuff then
            if not script.m_bIsPlayFull then
                -- UIHelper.PlaySFX(hSfxFull)
                script.m_bIsPlayFull = true
            end
        else
            script.m_bIsPlayFull = false
        end
        UIHelper.SetActiveAndCache(script, hSfxFull, bSfxBuff)
    end

    local tDouBuff = {}
    Buffer_GetByID(player, DOU_BUFF_ID, 1, tDouBuff)
    local nDouBuffNum = tDouBuff.nStackNum or 0
    if script.tDouScripts then
        UIHelper.SetActiveAndCache(script, script.WidgetDou, dwKungFuID == 10447)
        for i, douScript in ipairs(script.tDouScripts) do
            local hOnSfx = douScript.OnSfx
            local hOffSfx = douScript.OffSfx
            if i <= nDouBuffNum then
                if script.m_nLastStackNum and i > script.m_nLastStackNum then
                    --UIHelper.PlaySFX(hOnSfx, 0)
                end
            end
            UIHelper.SetActiveAndCache(script, hOnSfx, i <= nDouBuffNum)

            if script.m_nLastStackNum and i <= script.m_nLastStackNum and i > nDouBuffNum then
                UIHelper.SetActiveAndCache(script, hOffSfx, true)
                UIHelper.PlaySFX(hOffSfx, 0)
            end
        end
    end
    script.m_nLastStackNum = tDouBuff.nStackNum or 0

    local tNumBuff = {}
    Buffer_GetByID(player, NUM_BUFF_ID, 1, tNumBuff)
    local bLearnSkill = player.GetSkillLevel(14870) == 1
    local hTextNum = script.LabelTime
    if tNumBuff.dwID and tNumBuff.dwID == NUM_BUFF_ID and bLearnSkill then
        local nLeftFrame = Buffer_GetLeftFrame(tNumBuff)
        local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)
        UIHelper.SetActiveAndCache(script, hTextNum, true)
        UIHelper.SetLabel(hTextNum, nSecond)
    else
        UIHelper.SetActiveAndCache(script, hTextNum, false)
    end
end

function UIWidgetSkillEnergyBarDX:CG(player)
    local script = UIHelper.GetBindScript(self.WidgetChangGe)
    script.m_nAccumulateStyle = 0
    script.tDouScripts = {}

    for _, node in ipairs(script.tDous) do
        table.insert(script.tDouScripts, UIHelper.GetBindScript(node))
    end

    Event.Reg(self, "CHANGE_ACCUMULATE_STYLE", function(arg0)
        print("CHANGE_ACCUMULATE_STYLE", arg0)
        script.m_nAccumulateStyle = arg0
    end)

    local fnUpdate = function(player)
        local nStyle = script.m_nAccumulateStyle

        local tKungfu = player.GetKungfuMount()
        if not tKungfu then
            return
        end

        local dwKungFuID = tKungfu.dwSkillID
        local bIsMowen = dwKungFuID == 10447
        if self.bCustom then
            nStyle = 2
        end
        UIHelper.SetActiveAndCache(self, script._rootNode, nStyle ~= 0)
        if nStyle ~= 0 then
            local tStyleInfo = m_tStyleInfo[dwKungFuID][nStyle]
            if tStyleInfo then
                if not script.m_nLastShowFrame or tStyleInfo ~= script.m_nLastShowFrame then
                    local nBgScale = (not bIsMowen and (nStyle == 1 or nStyle == 2)) and 5 or 1 -- 相知的高山白雪特效有特殊处理
                    if nBgScale == 5 then
                        UIHelper.SetSFXPath(script.BgSpecialSFX, UIHelper.UTF8ToGBK(tStyleInfo.szBgSFX), 1)
                        UIHelper.SetScale(script.BgSpecialSFX, nBgScale, nBgScale)
                        if nStyle == 1 then
                            UIHelper.SetPosition(script.BgSpecialSFX, 750, -155) -- DX高山流水特效和阳春特效位置不同
                        else
                            UIHelper.SetPosition(script.BgSpecialSFX, 745, -147)
                        end
                    else
                        UIHelper.SetSFXPath(script.BgSFX, UIHelper.UTF8ToGBK(tStyleInfo.szBgSFX), 1)
                        UIHelper.SetScale(script.BgSFX, nBgScale, nBgScale)
                    end
                    UIHelper.SetActiveAndCache(script, script.BgSpecialSFX, nBgScale == 5)
                    UIHelper.SetActiveAndCache(script, script.BgSFX, nBgScale == 1)

                    UIHelper.SetSpriteFrame(script.ImgAccumulateBg, tStyleInfo.szBgImg)
                    UIHelper.BindUIEvent(script.WidgetStyle_1_mw, EventType.OnClick, function()
                        local nBuffID = nStyleToBuffID[nStyle]
                        local nBuffCount = player.GetBuffCount()
                        local buff = {}
                        for i = 1, nBuffCount, 1 do
                            Buffer_Get(player, i - 1, buff)
                            if buff.dwID == nBuffID then
                                local szText = BuffMgr.GetBuffDesc(nBuffID, buff.nLevel)
                                TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, script.WidgetStyle_1_mw, TipsLayoutDir.BOTTOM_CENTER, szText)
                            end
                        end
                    end)

                    if bIsMowen then
                        UIHelper.SetSFXPath(script.FullSFX, UIHelper.UTF8ToGBK(tStyleInfo.szFullSFX))
                        for nIndex, douScript in ipairs(script.tDouScripts) do
                            local szOn = nIndex % 3 == 0 and tStyleInfo.szSpecialEnterSFX or tStyleInfo.szNormalEnterSFX
                            local szOff = nIndex % 3 == 0 and tStyleInfo.szSpecialExitSFX or tStyleInfo.szNormalExitSFX
                            UIHelper.SetSFXPath(douScript.OnSfx, UIHelper.UTF8ToGBK(szOn))
                            UIHelper.SetSFXPath(douScript.OffSfx, UIHelper.UTF8ToGBK(szOff))
                            UIHelper.SetActiveAndCache(script, douScript.OnSfx, false)
                            UIHelper.SetActiveAndCache(script, douScript.OffSfx, false)
                        end
                    end
                    script.m_nLastShowFrame = tStyleInfo
                end
            end
            UpdateCGQuFengBuff(script, player, nStyle, dwKungFuID)
        end
    end
    self:StartUpdate(fnUpdate)
end

local tStateToString = {
    [ARROW_ENERGY_STATE.NONE] = "N",
    [ARROW_ENERGY_STATE.DAMAGE] = "A",
    [ARROW_ENERGY_STATE.CONTROL] = "C",
    [ARROW_ENERGY_STATE.DAMAGE_AND_CONTROL] = "M",
}
local WL_ARROW_MAXNUM = 8
local WL_BEAST_TYPE = 6
local WL_CH_NEED_NUM = 4
local function UpdateArrowState(hArrow, nState)
    for k, v in pairs(tStateToString) do
        UIHelper.SetActiveAndCache(hArrow, hArrow["ImgArrow" .. v], nState == k)
        UIHelper.SetActiveAndCache(hArrow, hArrow.ImgArrowBG, nState == ARROW_ENERGY_STATE.INVALID)
    end
    hArrow.nLastState = nState
end

function UIWidgetSkillEnergyBarDX:WL(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetWanLing)
    local tArrowScripts = {}
    for _, node in ipairs(script.tArrow) do
        table.insert(tArrowScripts, UIHelper.GetBindScript(node))
    end

    local fnUpdate = function(player)
        local nNowArrow = player.nArrowNum or 0
        local nLastArrow = self.nLastArrow or 0
        if nNowArrow < nLastArrow then
            local nUseArrow = nLastArrow - nNowArrow

        end

        for i = 1, WL_ARROW_MAXNUM do
            local hArrow = tArrowScripts[i]
            if i <= nNowArrow then
                local nNowState = player.GetArrowState(i - 1)
                if nNowState ~= hArrow.nLastState then
                    UpdateArrowState(hArrow, nNowState)
                end
            else
                UpdateArrowState(hArrow, ARROW_ENERGY_STATE.INVALID)
            end
        end

        --坟场
        local nBeastCast = player.nCurrentMoonEnergy or 0
        for i = 1, WL_BEAST_TYPE do
            UIHelper.SetActiveAndCache(self, script.tDou[i], i <= nBeastCast)
        end

        -- 乘黄变身
        local bChange = Player_IsBuffExist(26944, player, 1) --合神buff
        if bChange then
            if not self.bLastChange then

            end
        else
            --hCH:Lookup("Image_Mature"):Hide()
            --hCH:Lookup("SFX_Mature"):Hide()
            --hCH:Lookup("Image_Child"):Show()
            --if not hList.nBeastCast or hList.nBeastCast ~= nBeastCast then
            --    if nBeastCast < WL_CH_NEED_NUM then
            --        hCH:Lookup("SFX_Child"):Hide()
            --    else
            --        hCH:Lookup("SFX_Child"):Show()
            --        hCH:Lookup("SFX_Child"):Play()
            --    end
            --end

        end
        UIHelper.SetActiveAndCache(self, script.ImgChengHuangBig, bChange)
        UIHelper.SetActiveAndCache(self, script.ImgChengHuangSmall, not bChange)
        self.bLastChange = bChange
        self.nBeastCast = nBeastCast
    end

    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:YT(player)
    local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetYanTian)

    local function ChangeDivination(nLevel)
        local nMaxXingYun = player.nMaxRage
        if not nMaxXingYun then
            return
        end

        local szDivition = tBuffLeveltoDivition[nLevel]
        if not szDivition then
            return
        end

        if player.IsHaveBuff(YT_DIVITION_BUFF_ID, nLevel) and self.nLastDivitionBuffLayer ~= nLevel then
            UIHelper.SetSFXPath(script.SfxDivination1, UIHelper.UTF8ToGBK(tbYTDivinationSfxList[szDivition][1]))
            UIHelper.SetVisible(script.SfxDivination1, true)
            UIHelper.PlaySFX(script.SfxDivination1)
            UIHelper.SetSFXPath(script.SfxDivination2, UIHelper.UTF8ToGBK(tbYTDivinationSfxList[szDivition][2]))
            UIHelper.SetVisible(script.SfxDivination2, false)
            self.nLastDivitionBuffLayer = nLevel
        else
            self.nLastDivitionBuffLayer = nil
            UIHelper.SetVisible(script.SfxDivination1, false)
            UIHelper.SetVisible(script.SfxDivination2, false)
        end
    end

    local function ChangeGuaXiang(nBuffID)
        local nMaxXingYun = player.nMaxRage
        if not nMaxXingYun then
            return
        end

        local szGuaXiang = tBuffIDtoGuaXiang[nBuffID]
        if not szGuaXiang then
            return
        end

        if player.IsHaveBuff(nBuffID, 1) then
            UIHelper.SetVisible(script.SfxGuaXiang, true)
            UIHelper.SetSFXPath(script.SfxGuaXiang, UIHelper.UTF8ToGBK(tbYTSfxList[szGuaXiang]))
            UIHelper.PlaySFX(script.SfxGuaXiang, 1)
            local szType = tBuffLeveltoDivition[self.nLastDivitionBuffLayer]
            if szType and string.sub(tBuffLeveltoDivition[self.nLastDivitionBuffLayer], 2) == tBuffIDtoGuaXiang[nBuffID] and not self.nGuaXiangBuffID then
                UIHelper.SetVisible(script.SfxDivination2, true)
                UIHelper.PlaySFX(script.SfxDivination2)
                UIHelper.SetVisible(script.SfxDivination1, false)
            end
            self.nGuaXiangBuffID = nBuffID
        else
            UIHelper.SetVisible(script.SfxGuaXiang, false)
            UIHelper.SetVisible(script.SfxDivination1, false)
            UIHelper.SetVisible(script.SfxDivination2, false)
            self.nGuaXiangBuffID = nil
        end
    end

    Event.Reg(self, "BUFF_UPDATE", function()
        ChangeGuaXiang(arg4)
        if arg4 == YT_DIVITION_BUFF_ID then
            ChangeDivination(arg8)
        end
    end)

    Event.Reg(self, "LOADING_END", function ()
        player = GetClientPlayer()
    end)

    local fnUpdate = function(player)
        local nCurrentXingYun = player.nCurrentRage
        if not nCurrentXingYun then
            return
        end
        local nMaxXingYun = player.nMaxRage
        if not nMaxXingYun then
            return
        end

        local nPoseState = player.nPoseState
        local tbStarList = self.tbStarList
        local bTherapy = nPoseState == POSE_TYPE.TIANRENHEYI
        UIHelper.SetSpriteFrame(script.barShort, tbYTShortFrameList[nPoseState])
        UIHelper.SetString(script.LabelYanTianEnergy, string.format("%d/%d", nCurrentXingYun, nMaxXingYun))
        local fPer = nCurrentXingYun / nMaxXingYun
        local tbShortStarList = script.tbShortStarList or {}
        for i = 1, #tbShortStarList do
            local threshold = i * 0.2
            UIHelper.SetVisible(tbShortStarList[i], fPer >= threshold)
        end
        UIHelper.SetProgressBarPercent(script.barShort, fPer * 100)

    end
    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:WX(player)
    --local player = player or g_pClientPlayer
    local script = UIHelper.GetBindScript(self.WidgetWuXiangLou)

    local summonScript = UIHelper.GetBindScript(script.SliderZ)
    local morphScript = UIHelper.GetBindScript(script.SliderQ)

    summonScript.hNormal = UIHelper.GetBindScript(summonScript.barNormal)
    summonScript.hStNum = UIHelper.GetBindScript(summonScript.barSkill)
    summonScript.hStTime = UIHelper.GetBindScript(summonScript.barTimer)

    morphScript.hNormal = UIHelper.GetBindScript(morphScript.barNormal)
    morphScript.hStNum = UIHelper.GetBindScript(morphScript.barSkill)
    morphScript.hStTime = UIHelper.GetBindScript(morphScript.barTimer)

    local fnUpdate = function(player)
        player = player or GetControlPlayer()

        local nBarLen = 152
        local nEnergy = player.nCurrentEnergy
        local nMaxEnergy = player.nMaxEnergy
        local fPer = 0
        if nMaxEnergy ~= 0 then
            fPer = nEnergy / nMaxEnergy
        end

        local bSummon = player.IsHaveBuff(31374, 1) --召唤傀儡
        local bMorph = player.IsHaveBuff(31213, 1) --附身傀儡

        UIHelper.SetActiveAndCache(self, script.SliderZ, not bMorph)
        UIHelper.SetActiveAndCache(self, script.SliderQ, bMorph)
        UIHelper.SetActiveAndCache(self, script.ImgKuiLeiZ, bSummon)

        local hWxl = bMorph and morphScript or summonScript
        local hNormal = hWxl.hNormal
        local hStNum = hWxl.hStNum
        local hStTime = hWxl.hStTime

        local bFull = nEnergy == nMaxEnergy
        local bStrongN = player.IsHaveBuff(31372, 1) --扣能量强化
        local bStrongT = player.IsHaveBuff(31373, 1) --带倒计时强化

        UIHelper.SetActiveAndCache(self, hNormal._rootNode, not bStrongN and not bStrongT)
        UIHelper.SetActiveAndCache(self, hStNum._rootNode, bStrongN)
        UIHelper.SetActiveAndCache(self, hStTime._rootNode, bStrongT)

        local hFinal = (bStrongT and hStTime) or (bStrongN and hStNum) or hNormal
        if hFinal.ImgEnd then
            UIHelper.SetActiveAndCache(self, hFinal.ImgEnd, bFull)
        end
        UIHelper.SetActiveAndCache(self, hFinal.ImgStart, fPer > 0)
        UIHelper.SetActiveAndCache(self, hFinal.ImgProgressLine, fPer > 0 and fPer < 1)
        UIHelper.SetActiveAndCache(self, script.LabelTime, bStrongT)

        UIHelper.SetPositionX(hFinal.ImgProgressLine, 2 + fPer * nBarLen)
        UIHelper.SetProgressBarPercent(hFinal._rootNode, fPer * 100)

        if bStrongT then
            local tBuffInfo, nLeftTime = {}, 0
            Buffer_GetByID(player, 31373, 1, tBuffInfo)
            if tBuffInfo.dwID and tBuffInfo.dwID == 31373 then
                local nLeftFrame = Buffer_GetLeftFrame(tBuffInfo)
                local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecond(nLeftFrame, true)
                nLeftTime = nHour * 3600 + nMinute * 60 + nSecond
            end
            UIHelper.SetLabel(script.LabelTime, nLeftTime)
        end

        UIHelper.SetLabel(script.LabelNum, nEnergy .. "/" .. nMaxEnergy)
    end
    self:StartUpdate(fnUpdate)
end

function UIWidgetSkillEnergyBarDX:StartUpdate(fnFunc)
    Timer.DelAllTimer(self)
    Timer.AddCycle(self, nCycleTime, function()
        local currentPlayer = g_pClientPlayer
        if currentPlayer then
            fnFunc(currentPlayer)
        end
    end)
end

function UIWidgetSkillEnergyBarDX:UpdateCustomState()
    if SkillData.IsEnergyShow() then
        self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
    end
end

function UIWidgetSkillEnergyBarDX:UpdatePrepareState(nMode, bStart)
    if SkillData.IsEnergyShow() then
        self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
        self.nMode = nMode
    end
end

function UIWidgetSkillEnergyBarDX:UpdateCustomNodeState(nState)
    if not SkillData.IsEnergyShow() then
        return
    end
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState
end

function UIWidgetSkillEnergyBarDX:UpdateCustomInfo()
    local player = g_pClientPlayer
    if not SkillData.IsEnergyShow(player) then
        return
    end
    self.bCustom = true
    local skill = player.GetKungfuMount()
    local parent = self.mainWidget[skill.dwMountType]
    if parent then
        UIHelper.SetVisible(parent, true)
        for i = 1, #self.tAllEnergyBars do
            if parent ~= self.tAllEnergyBars[i] then
                UIHelper.RemoveFromParent(self.tAllEnergyBars[i], true)
            end
        end
    end

    local szType = ENERGY_FUNC_DICT[skill.dwMountType]
    local updateFunc = self[szType]
    if updateFunc then
        updateFunc(self, player)
    end

    UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()
        --进入黑框,maincity加载新的
        Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.FULL, CUSTOM_TYPE.ENERGYBAR, self.nMode)
    end)
end

return UIWidgetSkillEnergyBarDX