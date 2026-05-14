local UIWidgetMapEntrance = class("UIWidgetMapEntrance")

local tCastleTips = {}
function UIWidgetMapEntrance:OnEnter(tMapInfo, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(tMapInfo, fCallBack)
end

function UIWidgetMapEntrance:OnExit()
    self.bInit = false
end

function UIWidgetMapEntrance:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMapEntrance, EventType.OnClick, function()
		self.fCallBack(self.tMapInfo)
	end)
end

function UIWidgetMapEntrance:RegEvent()
    Event.Reg(self, "ON_CASTLE_GETTIPS_RESPOND", function (arg0)
        self:OnCastleGetTipsRespond(arg0)
    end)
end

function UIWidgetMapEntrance:UpdateInfo(tMapInfo, fCallBack)
    self.fCallBack = fCallBack
    local dwMapID = tMapInfo.tMapIDList[1]
    self.dwMapID = dwMapID
    self.tMapInfo = tMapInfo
    UIHelper.SetString(self.LabelName, tMapInfo.szMapName)
    UIHelper.SetTexture(self.ImgBg, tMapInfo.szImagePath)

    local nCamp
    local t = Table_GetCastleByMapID(dwMapID)
    for k, v in ipairs(t) do
        if tCastleTips[v] and not nCamp then
            nCamp = tCastleTips[v].nCamp
        
        elseif tCastleTips[v] and nCamp ~= tCastleTips[v].nCamp then
            nCamp = 0
        end
    end
    nCamp = nCamp or 0
    UIHelper.SetVisible(self.WidgetHaoQi, nCamp == 1)
    UIHelper.SetVisible(self.WidgetERen, nCamp == 2)
    UIHelper.SetVisible(self.WidgetDungeon, tMapInfo.nMapType == 1)
    UIHelper.SetVisible(self.WidgetReign, nCamp ~= 0 or tMapInfo.nMapType == 1)
    
    UIHelper.LayoutDoLayout(self.WidgetReign)

    --资源下载Widget
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    local nPackID = PakDownloadMgr.GetMapResPackID(dwMapID)
    scriptDownload:OnInitWithPackID(nPackID)
end

function UIWidgetMapEntrance:OnCastleGetTipsRespond(arg0)
	tCastleTips = arg0
	
	self:UpdateInfo(self.tMapInfo, self.fCallBack)
end
return UIWidgetMapEntrance