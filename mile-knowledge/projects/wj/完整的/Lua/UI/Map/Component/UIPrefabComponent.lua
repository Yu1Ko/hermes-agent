local UIPrefabComponent = class("UIPrefabComponent")

function UIPrefabComponent:Init(parent, nPrefabID)
    self.tb = {}
    self.parent = parent
    self.nPrefabID = nPrefabID
end

function UIPrefabComponent:Alloc(nIndex)
    assert(self.tb)
    if #self.tb < nIndex then
        local script = UIHelper.AddPrefab(self.nPrefabID, self.parent)
        table.insert(self.tb, script)
    end
    UIHelper.SetVisible(self.tb[nIndex]._rootNode, true)
    return self.tb[nIndex]
end

function UIPrefabComponent:Clear(nCount)
    assert(self.tb)
    for i = nCount, #self.tb do
        UIHelper.SetVisible(self.tb[i]._rootNode, false)
    end
end

return UIPrefabComponent