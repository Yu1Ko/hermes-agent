-- ---------------------------------------------------------------------------------
-- Name: UIWidgetAllotMaterialsListCell
-- Desc: 分配装置弹出框cell
-- Prefab:WidgettAllotPlayerListCell
-- ---------------------------------------------------------------------------------

local UIWidgetAllotMaterialsListCell = class("UIWidgetAllotMaterialsListCell")

function UIWidgetAllotMaterialsListCell:_LuaBindList()
    self.LabelPlayerName          = self.LabelPlayerName -- 玩家名称

    self.LabelStatus              = self.LabelStatus -- 副指挥 权限
    self.LabelFaction             = self.LabelFaction -- 帮会名称

    self.BtnSubtract              = self.BtnSubtract -- 减
    self.BtnPlus                  = self.BtnPlus -- 加
    self.WidgetEdit               = self.WidgetEdit -- 输入框编辑
end

function UIWidgetAllotMaterialsListCell:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
end

function UIWidgetAllotMaterialsListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAllotMaterialsListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPlus, EventType.OnClick, function()
        self:AddChangeHandle()
    end)

    UIHelper.BindUIEvent(self.BtnSubtract, EventType.OnClick, function()
        self:SubtractChangeHandle()
    end)
end

function UIWidgetAllotMaterialsListCell:RegEvent()

end

function UIWidgetAllotMaterialsListCell:UnRegEvent()

end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAllotMaterialsListCell:UpdateInfo(tInfo)
    self.dwID = tInfo.tNumberInfo.dwDeputyID
    self.szName = tInfo.tStringInfo.szName

    UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(self.szName))

    if tInfo.tNumberInfo.DeputyInfo[5] == 1 then
        if Platform.IsWindows() or Platform.IsMac() then
            UIHelper.RegisterEditBoxEnded(self.WidgetEdit, function()
                self:EditChangeHandle()
            end)
        else
            UIHelper.RegisterEditBoxReturn(self.WidgetEdit, function()
                self:EditChangeHandle()
            end)
        end
	else
        UIHelper.SetVisible(self.BtnSubtract, false)
        UIHelper.SetVisible(self.BtnPlus, false)
        UIHelper.SetTouchEnabled(self.WidgetEdit, false)
	end
end

function UIWidgetAllotMaterialsListCell:SetEditBox()
    UIHelper.SetEditboxTextHorizontalAlign(self.WidgetEdit, TextHAlignment.CENTER)
    UIHelper.SetText(self.WidgetEdit, 0)
end

function UIWidgetAllotMaterialsListCell:EditChangeHandle()
    local nIndex = CommandBaseData.GetGoodsIndex()
    local nCanAllot = CommandBaseData.tGoodsSetting[nIndex].nBuy - CommandBaseData.tGoodsSetting[nIndex].nAllot

    local szNum = UIHelper.GetText(self.WidgetEdit)
    local nNum = 0
    local tInfo = {
        dwPlayerID = self.dwID,
        szName = self.szName,
        nAddCount = 0
    }
    if szNum ~= nil and szNum ~= "" then
        nNum = tonumber(szNum)
        tInfo.nAddCount = nNum
        CommandBaseData.SetGoodsAllotInfo(self.dwID, tInfo)
        local nAccount = CommandBaseData.GetGoodsAllotCount()
        if nAccount > nCanAllot then
            nNum = nNum - (nAccount - nCanAllot)
            nNum = math.max(nNum, 0)
            tInfo.nAddCount = nNum
            CommandBaseData.SetGoodsAllotInfo(self.dwID, tInfo)
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.WidgetEdit, TipsLayoutDir.RIGHT_CENTER, "不能超过最大可分配数量")
        end
    end
    UIHelper.SetText(self.WidgetEdit, nNum)
end

function UIWidgetAllotMaterialsListCell:SubtractChangeHandle()
    local szNum = UIHelper.GetText(self.WidgetEdit)
    if szNum ~= nil and szNum ~= "" then
        local nNum = tonumber(szNum)
        nNum = nNum - 1
        nNum = math.max(nNum, 0)
        UIHelper.SetText(self.WidgetEdit, nNum)
        self:EditChangeHandle()
    end
end

function UIWidgetAllotMaterialsListCell:AddChangeHandle()
    local szNum = UIHelper.GetText(self.WidgetEdit)
    if szNum ~= nil and szNum ~= "" then
        local nNum = tonumber(szNum)
        nNum = nNum + 1
        nNum = math.max(nNum, 0)
        UIHelper.SetText(self.WidgetEdit, nNum)
        self:EditChangeHandle()
    end
end

return UIWidgetAllotMaterialsListCell