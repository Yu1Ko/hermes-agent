-- WidgetMainCityBuffList
local UIWidgetMainCityRaidSimpleBuffList = class("UIWidgetMainCityRaidSimpleBuffList")

local maxBuffNum = 4

function UIWidgetMainCityRaidSimpleBuffList:OnEnter()
    if not self.bInit then
        local PrefabComponent = require("Lua/UI/Map/Component/UIPrefabComponent")
        self.tScript = PrefabComponent:CreateInstance()
        self.tScript:Init(self.WidgetListParent, PREFAB_ID.WidgetMainCityBuffSimple)
        self.nTotalLength = UIHelper.GetWidth(self.WidgetListParent)

        self.bInit = true
    end
end

function UIWidgetMainCityRaidSimpleBuffList:OnExit()

end

function UIWidgetMainCityRaidSimpleBuffList:UpdateRaidSimpleBuff(tBuff, bLeftToRight)
    self:OnEnter()

    local nCellWidth
    local nCount = math.min(maxBuffNum, #tBuff)
    if nCount > 0 then
        for i = 1, nCount do
            local script = self.tScript:Alloc(i)
            nCellWidth = nCellWidth or UIHelper.GetWidth(script._rootNode)
            script:UpdateBuffImage(tBuff[i].dwID, tBuff[i].nLevel, self.character, tBuff)
            script:ShowBuffLevel(tBuff[i].nStackNum)        

            local nCalX = (nCellWidth / 2 + nCellWidth * (i - 1))
            nCalX = not bLeftToRight and self.nTotalLength - nCalX or nCalX
            UIHelper.SetPositionX(script._rootNode, nCalX) -- 手动计算位置 减少性能消耗
        end
        self.tScript:Clear(nCount + 1)
    else
        self.tScript:Clear(1)
    end
end

return UIWidgetMainCityRaidSimpleBuffList