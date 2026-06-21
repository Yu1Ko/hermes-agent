-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIGongZhan
-- Date: 2023-06-27 14:25:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIGongZhan = class("UIGongZhan")

local GONGZHAN_BUFF = 3219
--按钮跳转的活动
local tActivityID = {
    29,
    570,
    793,
}
local szImgPath = "Resource/icon/skill/Common/skill_wanhua_qunliao_03.png"

function UIGongZhan:OnEnter(dwOperatActID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tActivity = UIHuaELouActivityTab[nID]
    if not tActivity then
        return
    end

    self.nID = nID
    self:UpdateInfo(tActivity.szbgImgPath)
    self.tBuffTimeData = Buffer_GetTimeData(GONGZHAN_BUFF)
    self:UpdateTitle()
    Timer.AddCycle(self, 1, function ()
        self:UpdateTitle()
    end)

    local tLine = Table_GetOperActyInfo(dwOperatActID)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szTitle))
    end
end

function UIGongZhan:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIGongZhan:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDetailPVE, EventType.OnClick, function ()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelRoadCollection) then
            UIMgr.Open(VIEW_ID.PanelRoadCollection, COLLECTION_PAGE_TYPE.SECRET)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDetailPVP, EventType.OnClick, function ()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelRoadCollection) then
            UIMgr.Open(VIEW_ID.PanelRoadCollection, COLLECTION_PAGE_TYPE.ATHLETICS)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDetailPVX, EventType.OnClick, function ()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelRoadCollection) then
            UIMgr.Open(VIEW_ID.PanelRoadCollection, COLLECTION_PAGE_TYPE.REST)
        end
    end)
end

function UIGongZhan:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        if UIHelper.GetSelected(self.SelectToggle) then
            UIHelper.SetSelected(self.SelectToggle, false)
        end
    end)
end

function UIGongZhan:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIGongZhan:UpdateInfo(szbgImgPath)
    local tbItemScript = {}
    local tShowItem = HuaELouData.GetShowReward(self.nID) or {}
    for k,tItemData in ipairs(tShowItem) do
        local itemScript =  UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, self.LayoutItem)
        if itemScript then
            itemScript:OnInitWithTabID(tItemData[1], tItemData[2], tItemData[3])

            itemScript:SetClickCallback(function (nTabType, nTabID)
                self.SelectToggle = itemScript.ToggleSelect
                for i, v in ipairs(tbItemScript) do
                    if UIHelper.GetSelected(v.ToggleSelect) and k ~= i then
                        UIHelper.SetSelected(v.ToggleSelect,false)
                    end
                end
                TipsHelper.ShowItemTips(itemScript._rootNode, nTabType, nTabID)
            end)

            table.insert(tbItemScript, itemScript)
        end
    end

    UIHelper.SetTexture(self.ImgGongZhanBuff, szImgPath)
    UIHelper.SetTexture(self.BgFriendRecruit, szbgImgPath)
end

function UIGongZhan:UpdateTitle()
    local nTime = self.tBuffTimeData.nEndFrame and BuffMgr.GetLeftFrame(self.tBuffTimeData) or self.tBuffTimeData.nLeftTime
    local szTime = self.tBuffTimeData.nEndFrame and UIHelper.GetHeightestTimeText(nTime, true) or UIHelper.GetTimeHourText(nTime, false)
    UIHelper.SetString(self.LabelTimeLeftNum, szTime)
end

return UIGongZhan