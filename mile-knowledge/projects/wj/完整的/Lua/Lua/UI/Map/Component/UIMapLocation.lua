local UIMapLocation = class("UIMapLocation")

function UIMapLocation:OnEnter()
end

function UIMapLocation:Enable(bEnable)
    UIHelper.SetVisible(self._rootNode, bEnable)

    if bEnable then
        local nPlayerID = PlayerData.GetPlayerID()
        UIHelper.RemoveAllChildren(self.WidgetHead)
        local headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, nPlayerID)
        UIHelper.SetTouchEnabled(headScript.BtnHead, false)
    end
end

return UIMapLocation