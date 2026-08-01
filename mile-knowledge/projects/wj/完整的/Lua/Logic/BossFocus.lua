BossFocus = BossFocus or {className = "BossFocus"}

BossFocus.tFocusPlayerList = {}
BossFocus.tFocusBuffMap = nil

function BossFocus.MakeKey(nBuffID, nLevel)
	return string.format("%d_%d", nBuffID, nLevel)
end

function BossFocus.GetFocusBuffMap()
	if not BossFocus.tFocusBuffMap then
		BossFocus.tFocusBuffMap = {}
		local tab = g_tTable.BossFocusBuff
		for i = 2, tab:GetRowCount() do
			local tRow = tab:GetRow(i)
			local szKey = BossFocus.MakeKey(tRow.nBuffID , tRow.nBuffLevel)
			BossFocus.tFocusBuffMap[szKey] = tRow.nBuffStack
		end
	end
	return BossFocus.tFocusBuffMap
end

function BossFocus.IsBeFocused(dwPlayerID)
	if BossFocus.tFocusPlayerList[dwPlayerID] then
		return true
	end

	local player = GetPlayer(dwPlayerID)
	if not player then
		return false
	end

	local tFocusMap = BossFocus.GetFocusBuffMap()
	local nCount = player.GetBuffCount()
	local buff = {}
	for i = 1, nCount do
		BuffMgr.Get(player, i - 1, buff)
		if buff.dwID then
			local szKey = BossFocus.MakeKey(buff.dwID, buff.nLevel)
			local nStackNum = tFocusMap[szKey]
			if nStackNum and buff.nStackNum >= nStackNum then
				return true
			end
		end
	end
	return false
end

Event.Reg(BossFocus, "ON_BOSS_FUCUS", function()
    BossFocus.tFocusPlayerList[arg0] = arg1
end)


