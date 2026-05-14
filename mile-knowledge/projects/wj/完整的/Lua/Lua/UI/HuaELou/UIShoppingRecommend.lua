-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShoppingRecommend
-- Date: 2023-08-11 17:30:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShoppingRecommend = class("UIShoppingRecommend")

function UIShoppingRecommend:OnEnter(dwOperatActID, szbgImgPath)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwOperatActID = dwOperatActID

    local tLine = Table_GetOperActyInfo(self.dwOperatActID)
    if tLine and tLine.szTitle then
        UIHelper.SetString(self.LabelNormalName1, UIHelper.GBKToUTF8(tLine.szName))
    end

    self:InitActivtyList()
    self:UpdateInfo(tLine.tStartTime, tLine.tEndTime)
end

function UIShoppingRecommend:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShoppingRecommend:BindUIEvent()
end

function UIShoppingRecommend:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShoppingRecommend:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIShoppingRecommend:InitActivtyList()
    self.tActivtyList = {}
    for _, v in ipairs(UIHuaELouOperatActTab) do
        if v.nOperatActID == self.dwOperatActID then
            table.insert(self.tActivtyList, v)
        end
    end

    self.nDefaultX, self.nDefaultY = UIHelper.GetPosition(self.BtnGoToShopping)
end

function UIShoppingRecommend:UpdateInfo(tStartTime, tEndTime)
    self:UpdateTime(tStartTime, tEndTime)

    UIHelper.RemoveAllChildren(self.ScrollViewReward)
    local tbShoppingCellScript = {}
    local nTime = GetCurrentTime()

    for _, v in ipairs(self.tActivtyList) do
        if nTime >= tonumber(v.szStartTime) and nTime <= tonumber(v.szEndTime) then
            local ShoppingCellScript = UIHelper.AddPrefab(PREFAB_ID.WidgetShoppingRecommendCell, self.ScrollViewReward)
            if ShoppingCellScript then
                for k = 1, 2 do
                    UIHelper.SetString(ShoppingCellScript.tbLabelName[k], v.szTitle)
                    if v.szCustomTime and v.szCustomTime ~= "" then
                        UIHelper.SetString(ShoppingCellScript.tbLabelTime[k], v.szCustomTime)
                    else
                        local szText = HuaELouData.GetTimeShowText(v.szStartTime, v.szEndTime)
                        UIHelper.SetString(ShoppingCellScript.tbLabelTime[k], szText)
                    end

                    UIHelper.SetSpriteFrame(ShoppingCellScript.tbImgIcon[k], v.szIconPath)

                    UIHelper.BindUIEvent(ShoppingCellScript.TogRecommendCell, EventType.OnSelectChanged, function (_, bSelected)
                        if bSelected then
                            UIHelper.SetTexture(self.ImgBanner, v.szImgPath)
                            UIHelper.SetVisible(self.BtnGoToShopping, v.nBtnID ~= 0)

                            if v.nBtnID ~= 0 then
                                local scriptBtn = UIHelper.GetBindScript(self.BtnGoToShopping)
                                if scriptBtn then
                                    scriptBtn:OnEnter(v.nBtnID)
                                end
                            end

                            -- if v.tbBtnPosXY[1] ~= 0 or v.tbBtnPosXY[2] ~= 0 then
                            --     UIHelper.SetPosition(self.BtnGoToShopping, v.tbBtnPosXY[1], v.tbBtnPosXY[2])
                            -- else
                            --     UIHelper.SetPosition(self.BtnGoToShopping, self.nDefaultX, self.nDefaultY)
                            -- end
                        end
                    end)

                    table.insert(tbShoppingCellScript, ShoppingCellScript)
                end
            end
        end
    end

    UIHelper.SetSelected(tbShoppingCellScript[1].TogRecommendCell, true)

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReward)
end

function UIShoppingRecommend:UpdateTime(tStartTime, tEndTime)
    local nStart = tStartTime[1]
	local nEnd = tEndTime and tEndTime[1]
    local szText = HuaELouData.GetTimeShowText(nStart, nEnd)

    UIHelper.SetString(self.LabelMiddle, szText)
end

return UIShoppingRecommend