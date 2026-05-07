VisibleCheckHelper = VisibleCheckHelper or {}


function VisibleCheckHelper.DoCheck(node, nCheckID)
    if not safe_check(node) then
        return
    end

    if not IsNumber(nCheckID) then
        return
    end

    if nCheckID <= 0 then
        return
    end

    local tbConf = UIVisibleCheckTab[nCheckID]
    if not tbConf then
        return
    end

    local bResult = false
    for i, v in ipairs(tbConf.tbCheckFunc) do
		if next(v) then
			local bCondition = true
			for i, szCondition in ipairs(v) do
				if not string.execute(szCondition) then
					bCondition = false
					break
				end
			end
			bResult = (bResult or bCondition)
		end

		if i == 1 and not next(v) then
			bResult = true
		end
	end

    UIHelper.SetVisible(node, bResult)
end