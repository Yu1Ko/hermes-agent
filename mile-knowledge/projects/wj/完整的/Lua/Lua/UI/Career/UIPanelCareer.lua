--PanelCareer

local UIPanelCareer = class("UIPanelCareer")

local PageIndex2PrefabID = {
    [1] = PREFAB_ID.WidgetCareerMain,       -- 主页
    [2] = PREFAB_ID.WidgetCareerCollect,  --收集
    [3] = PREFAB_ID.WidgetCareerCompete,    --竞技
    [4] = PREFAB_ID.WidgetCareerDungeons,   --秘境
    [5] = PREFAB_ID.WidgetCareerReport,     --大侠密档
    [6] = PREFAB_ID.WidgetMarkOverview,     --江湖无限
}

local szName = "山海源流"

function UIPanelCareer:OnEnter(nSelectedID)
    self.player = GetClientPlayer()
    self.nSelectedID = nSelectedID
    if not self.bInit then
        self:Init()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        CareerData.Init()
    end
    if not self.nSelectedID then
        self.nSelectedID = 5
    else
        UIHelper.SetSelected(self.tbTogTabLeft[5], false)
    end

    local labelName1 = UIHelper.GetChildByName(self.tbTogTabLeft[6], "LabelNavigation06")
    local labelName2 = UIHelper.GetChildByPath(self.tbTogTabLeft[6], "WidgetSelectNavigation06/LabelSelectNavigation03")
    UIHelper.SetString(labelName1, szName)
    UIHelper.SetString(labelName2, szName)
    UIHelper.SetSelected(self.tbTogTabLeft[self.nSelectedID], true)
end

function UIPanelCareer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelCareer:Init()
    self.tbScriptPage = {}
end

function UIPanelCareer:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        CareerData.UnInit()
        UIMgr.Close(VIEW_ID.PanelCareer)
    end)

    for index, tog in ipairs(self.tbTogTabLeft) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function (btn, bSelected)
            if not bSelected then return end
            self.nSelectedID = index
            self:UpdateInfo()
        end)
    end
end

function UIPanelCareer:RegEvent()
    --
end

function UIPanelCareer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelCareer:UpdateInfo()
    if not self.nSelectedID then
        self.nSelectedID = 1
    end

    if self.nSelectedID == self.nPreSelectedID then
        return
    end
    
    if self.nPreSelectedID then
        UIHelper.SetVisible(self.tbWidgetMiddle[self.nPreSelectedID], false)
    end
    self.nPreSelectedID = self.nSelectedID

    UIHelper.SetVisible(self.tbWidgetMiddle[self.nSelectedID], true)

    if self.tbScriptPage[self.nSelectedID] then
        self.tbScriptPage[self.nSelectedID]:OnEnter()
    else
        self.tbScriptPage[self.nSelectedID] = UIHelper.AddPrefab(PageIndex2PrefabID[self.nSelectedID], self.tbWidgetMiddle[self.nSelectedID])
    end
end

return UIPanelCareer