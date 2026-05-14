-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMainCityCompassTips
-- Date: 2023-05-08 16:57:24
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIMainCityCompassTips = class("UIMainCityCompassTips")

local richImg = "<img src='UIAtlas2_Public_PublicPanel_PublicPanel1_TitielHintImg' width='14' height='14'/>"
local COMPASS_LEVEL = {
    [0] = "当前0级罗盘，有极低概率触发特殊事件。",
    [1] = "当前1级罗盘，有较低概率触发特殊事件。",
    [2] = "当前2级罗盘，有中等概率触发特殊事件。",
    [3] = "当前3级罗盘，有较高概率可触发特殊事件。",
    [4] = "当前4级罗盘，有非常高概率触发特殊事件。",
    [5] = "当前5级罗盘（最高级），有极高概率触发特殊事件。",
}

local ITEM_ID = 6604
local nLevelBuff = 7923

function UIMainCityCompassTips:OnEnter(nCompassLevel,nDigCount)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetTouchDownHideTips(self.BtnReset, false)

    self.nCompassLevel = nCompassLevel
    local szLabel = richImg..COMPASS_LEVEL[self.nCompassLevel]
    UIHelper.SetRichText(self.LabelLevelInfo,szLabel)
    if self.nCompassLevel > 0 then
        Timer.AddFrameCycle(self, 1, function ()
            local tBuffInfo = Buffer_GetTimeData(nLevelBuff)
            local nLeftFrame = Buffer_GetLeftFrame(tBuffInfo)
            local szTime = self:GetFormatTime(nLeftFrame)
            szLabel = richImg..COMPASS_LEVEL[self.nCompassLevel]..string.format("（重置等级倒计时：%s）", szTime)
            UIHelper.SetRichText(self.LabelLevelInfo,szLabel)
        end)
    end
    

    Timer.AddFrameCycle(self,1,function ()
        local _, nLeft = ItemData.GetItemCDProgressByTab(ITEM_TABLE_TYPE.OTHER, ITEM_ID)
        UIHelper.SetRichText(self.LabelTimeInfo,richImg.."挖宝间隔时间："..math.ceil(nLeft / GLOBAL.GAME_FPS).."秒")
    end)

    local nCount  = nDigCount or 0
    UIHelper.SetRichText(self.LabelRuleTitle3,richImg.."团队累计挖宝次数："..nCount.."次")
end

function UIMainCityCompassTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer()
end

function UIMainCityCompassTips:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReset,EventType.OnClick,function ()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetCompassTips)
        UIHelper.ShowConfirm(ParseTextHelper.ParseNormalText(g_tStrings.STR_WAI_BAO_RESET_SURE),function ()
            RemoteCallToServer("On_Xunbao_DeleteXunbaodian")
        end)
    end)
end

function UIMainCityCompassTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMainCityCompassTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMainCityCompassTips:UpdateInfo()
    
end

function UIMainCityCompassTips:GetFormatTime(nTime)
    nTime = nTime / GLOBAL.GAME_FPS
    local nM = math.floor(nTime / 60)
    local nS = math.floor(nTime % 60)
    local szTimeText = ""

    if nM ~= 0 then
        szTimeText= szTimeText..nM..":"
    end

    if nS < 10 and nM ~= 0 then
        szTimeText = szTimeText.."0"
    end

    szTimeText= szTimeText..nS

    return szTimeText
end

return UIMainCityCompassTips