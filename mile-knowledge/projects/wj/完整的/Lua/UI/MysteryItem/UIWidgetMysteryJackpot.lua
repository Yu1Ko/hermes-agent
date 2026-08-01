-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBookItem
-- Date: 2022-12-09 10:31:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMysteryJackpot = class("WidgetMysteryJackpot")

local SHOW_SFX_QUALITY = 4 --需要显示常驻特效的品质
local ORANGE_PENDANT_QUALITY = 5
local PENDANT_AREA_COUNT = 3
local nNormalFontID = 18
local nRedFontID = 172
local OPEN_ONE_BOX_NEED_MONEY = 10000
local MAX_WORN_LEVEL = 511

local szPositionImgPath = "ui/Image/Collection/Collection.UITex"
local tPositionImgFrame = {
    [MYSTERY_PENDANT_TYPE.BACK] = 11,
    [MYSTERY_PENDANT_TYPE.WAIST] = 12
}
local szPreviewQualityImgPath = "ui/Image/Collection/Collection4.UITex"
local tPreviewQualityImgFrame = {
    [1] = 0, --白
    [2] = 1, --绿
    [3] = 2, --蓝
    [4] = 3, --紫
    [5] = 4, --橙
    [6] = 5, --限量橙
}

local m_tPackageIndex = {
    INVENTORY_INDEX.PACKAGE,
    INVENTORY_INDEX.PACKAGE1,
    INVENTORY_INDEX.PACKAGE2,
    INVENTORY_INDEX.PACKAGE3,
    INVENTORY_INDEX.PACKAGE4,
    INVENTORY_INDEX.PACKAGE_MIBAO,
}

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(nDLCIndex)
    DataModel.nDLCIndex = 1
    DataModel.nSelBoxID = nil
    DataModel.tCounterID = {}
    DataModel.bEnableBoxOpr = true
    DataModel.tOpenPendant = {}
    DataModel.tImageIDList = {}

    DataModel.SetCurrentDLC(nDLCIndex)
end

function DataModel.UnInit()
    DataModel.nDLCIndex = nil
    DataModel.nSelBoxID = nil
    DataModel.tCounterID = nil
    DataModel.bEnableBoxOpr = nil
    DataModel.tOpenPendant = nil
    DataModel.tImageIDList = nil
end

function DataModel.SetCurrentDLC(nDLCIndex)
    local tAllDLCInfo = Table_GetAllCollectionDLCInfo()
    local nLen = #tAllDLCInfo
    if not nDLCIndex then
        nDLCIndex = tAllDLCInfo[nLen].nIndex
    else
        DataModel.nDLCIndex = nDLCIndex
    end
end

function DataModel.GetCurrentDLC()
    return DataModel.nDLCIndex
end

function DataModel.SetSelectBox(dwBoxID)
    DataModel.nSelBoxID = dwBoxID
end

function DataModel.GetSelectBox()
    return DataModel.nSelBoxID
end

function DataModel.SetCurCounterIDList(tIDList)
    DataModel.tCounterID = tIDList
end
function DataModel.GetCounterIDList()
    return DataModel.tCounterID
end

function DataModel.EnableBoxOperation(bEnable)
    DataModel.bEnableBoxOpr = bEnable
end

function DataModel.IsEnableBoxOperation()
    return DataModel.bEnableBoxOpr
end

function DataModel.SetOpenPendantList(tList)
    DataModel.tOpenPendant = tList
end

function DataModel.GetOpenPendantList()
    return DataModel.tOpenPendant
end

function DataModel.AddDrawImageID(hImage)
    local dwImageID = hImage:GetImageID()
    DataModel.tImageIDList[dwImageID] = hImage
end

function DataModel.ClearImageIDList()
    DataModel.tImageIDList = {}
end

function DataModel.IsImageDrawToPendant(dwImageID)
    return DataModel.tImageIDList[dwImageID]
end

-----------------------------View------------------------------

local JACKPOT_DISPLAY_NUM = 3

function UIWidgetMysteryJackpot:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        DataModel.Init(1)

        self.jackpotDisplayScripts = {}
        for i = 1, JACKPOT_DISPLAY_NUM do
            self.jackpotDisplayScripts[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetJackpotDisplay, self.jackpotDisplaySlots[i])
        end

        self.collectionBoxScripts = {
            [1] = UIHelper.GetBindScript(self.TogJackpot01),
            [2] = UIHelper.GetBindScript(self.TogJackpot02)
        }
    end
    self:UpdateInfo()
end

function UIWidgetMysteryJackpot:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMysteryJackpot:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIWidgetMysteryJackpot:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMysteryJackpot:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetMysteryJackpot:UpdateInfo()
    self:UpdateBoxList()
    self:UpdatePreviewList()
end

function UIWidgetMysteryJackpot:UpdateBoxList()
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end
    local dwDLCIndex = DataModel.GetCurrentDLC()
    local tBoxList = Table_GetCollectionBoxList(dwDLCIndex)

    for nIndex, tBox in ipairs(tBoxList) do
        --local hBox = hBoxList:AppendItemFromIni(INI_FILE, "Handle_BoxItem", "Handle_BoxItem" .. tBox.nIndex)
        local nBoxIndex = tBox.nIndex
        local szName = UIHelper.GBKToUTF8(tBox.szName)
        local dwItemIndex = tBox.dwItemIndex

        local nAmount = 10 -- pPlayer.GetItemAmountInPackage(tBox.dwTabType, tBox.dwItemIndex)

        local dwSelBoxID = DataModel.GetSelectBox()
        if not dwSelBoxID then
            DataModel.SetSelectBox(tBox.nIndex)
        end

        self.collectionBoxScripts[nIndex]:SetName(szName)
        self.collectionBoxScripts[nIndex]:SetSelectChangeCallback(function(tog, bSelected)
            if bSelected then
                print(nIndex)
            end
        end)


        --local hImg = hBox:Lookup("Image_Box")  --设置一下开宝箱的金币是否足够的字体颜色
        --View.SetImage(hImg, tBox.szSmallIconPath, tBox.nIconFrame)
    end
    --hBoxList:FormatAllItemPos()
end

function UIWidgetMysteryJackpot:UpdatePreviewList()
    local nBoxIndex = DataModel.GetSelectBox()
    local tBoxInfo = Table_GetCollectionBox(nBoxIndex)
    local tPreviewPendantList = Table_GetCollectionPreviewPendantList(nBoxIndex)
    --local hWndPreview = hFrame:Lookup("Wnd_BoxPreviewList")
    --local hHandle = hWndPreview:Lookup("", "")
    --hHandle:Lookup("Text_PreviewList_Title"):SetText(tBoxInfo.szName)
    --hHandle:Lookup("Handle_Access/Text_Access"):SetText(tBoxInfo.szGainWay)

    for nIndex, tItem in ipairs(tPreviewPendantList) do
        --local script = UIHelper.AddPrefab(PREFAB_ID.WidgetJackpotDisplay, self.jackpotDisplaySlots[nIndex])
        --local hItem = hPreviewList:AppendItemFromIni(INI_FILE, "Handle_PreviewItem")
        --hItem.dwItemIndex = tItem.dwItemIndex
        --hItem.nQuality = tItem.nQuality
        --hItem:Lookup("Handle_limited"):Show(tItem.bLimit)
        --
        --local nFrame = tPreviewQualityImgFrame[tItem.nQuality]
        --local hImgQuality = hItem:Lookup("Image_PreviewBg_Quality")
        --if nFrame then
        --    hImgQuality:FromUITex(szPreviewQualityImgPath, nFrame)
        --end
        --
        --local hImg = hItem:Lookup("Image_Preview")
        --View.SetImage(hImg, tItem.szImagePath, tItem.nFrame)
    end

    --if hPreviewList:GetFirstChild() then
    --    hWndPreview:Lookup("WndScroll_PreviewList"):SetScrollHorStepSize(hPreviewList:GetFirstChild():GetW())
    --end
end

return UIWidgetMysteryJackpot