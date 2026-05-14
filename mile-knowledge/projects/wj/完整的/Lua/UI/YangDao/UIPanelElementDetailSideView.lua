-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIPanelElementDetailSideView
-- Date: 2026-03-05 15:23:56
-- Desc: 扬刀大会-属性详细信息界面 PanelElementDetailSide
-- ---------------------------------------------------------------------------------

local UIPanelElementDetailSideView = class("UIPanelElementDetailSideView")

-- <color=#D7F6FF>一般内容</c><color=#FFE26E>强调内容</color>
local TEXT_COLOR_NORMAL = "#D7F6FF"
local TEXT_COLOR_HIGHLIGHT = "#FFE26E"

local tIconElementPt = {
    [BlessElementType.Jin] = "UIAtlas2_YangDao_BlessCard_Icon_ElementPt_Jin.png",
    [BlessElementType.Mu] = "UIAtlas2_YangDao_BlessCard_Icon_ElementPt_Mu.png",
    [BlessElementType.Shui] = "UIAtlas2_YangDao_BlessCard_Icon_ElementPt_Shui.png",
    [BlessElementType.Huo] = "UIAtlas2_YangDao_BlessCard_Icon_ElementPt_Huo.png",
    [BlessElementType.Tu] = "UIAtlas2_YangDao_BlessCard_Icon_ElementPt_Tu.png",
}

function UIPanelElementDetailSideView:OnEnter(tElementPoint)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        UIHelper.SetTouchDownHideTips(self.ScrollViewContent)
    end

    self.tElementPoint = tElementPoint
    self:UpdateInfo()
end

function UIPanelElementDetailSideView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelElementDetailSideView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        if not self._nViewID then
            -- 作为Widget直接触发HideTips的逻辑让外面的界面处理关闭
            return
        end
        UIMgr.Close(self)
    end)
end

function UIPanelElementDetailSideView:RegEvent()
    Event.Reg(self, EventType.OnArenaTowerDataUpdate, function()
        self:UpdateInfo()
    end)
end

function UIPanelElementDetailSideView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

local function trim_number(n)
    -- 先格式化为足够精度，再去除末尾多余 0 和小数点
    local s = string.format("%.10f", n)     -- 保证精度
    s = s:gsub("(%..-)[0]+$", "%1")         -- 去掉小数末尾的 0
    s = s:gsub("%.$", "")                   -- 若最后是 . ，去掉
    return s
end

function UIPanelElementDetailSideView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutElementDetailList)

    local tElementPoint = self.tElementPoint
    local function addElementDetailPrefab(nIndex, nElementType)
        local tInfo = Table_GetArenaTowerElementInfo(nIndex)
        if not tInfo then
            return
        end
        local szTitle = UIHelper.GBKToUTF8(tInfo.szTitle)
        local szIconPath = tIconElementPt[nElementType]
        local nValue = tElementPoint and tElementPoint[nElementType] or 0
        local szDesc = ""
        local nAttrIndex = 1
        local szAttrName = UIHelper.GBKToUTF8(tInfo["szAttributeName" .. nAttrIndex])

        while not string.is_nil(szAttrName) do
            if szDesc ~= "" then
                szDesc = szDesc .. "，"
            else
                szDesc = "获得"
            end

            local fBaseValue = tInfo["fBaseValue" .. nAttrIndex]
            local szValue = trim_number(nValue * fBaseValue)
            szDesc = szDesc .. string.format("<color=%s>%s%%</color>%s", TEXT_COLOR_HIGHLIGHT, szValue, szAttrName)

            nAttrIndex = nAttrIndex + 1
            szAttrName = UIHelper.GBKToUTF8(tInfo["szAttributeName" .. nAttrIndex])
        end

        szDesc = UIHelper.AttachTextColor(szDesc, TEXT_COLOR_NORMAL)
        UIHelper.AddPrefab(PREFAB_ID.WidgetElementDetailCell, self.LayoutElementDetailList, 
            szTitle, szIconPath, nValue, szDesc)
    end

    -- 这里12345顺序为金水木火土顺序，约定ArenaTowerElementInfo表里的nIndex顺序与GDAPI_GetArenaTowerWuXingInfo返回的tWuXing的顺序一致
    addElementDetailPrefab(1, BlessElementType.Jin)
    addElementDetailPrefab(2, BlessElementType.Shui)
    addElementDetailPrefab(3, BlessElementType.Mu)
    addElementDetailPrefab(4, BlessElementType.Huo)
    addElementDetailPrefab(5, BlessElementType.Tu)

    UIHelper.LayoutDoLayout(self.LayoutElementDetailList)

    -- UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    Timer.AddFrame(self, 1, function()
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent) -- WidgetElementDetailCell会设置尺寸，这里延迟一帧
    end)
end


return UIPanelElementDetailSideView