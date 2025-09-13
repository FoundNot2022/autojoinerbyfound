local function dumpGui(gui, indent)
    indent = indent or ""
    for _, obj in ipairs(gui:GetChildren()) do
        local info = indent .. obj.ClassName .. " | Name: " .. obj.Name
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            info = info .. " | Text: " .. tostring(obj.Text)
        end
        print(info)
        dumpGui(obj, indent .. "   ")
    end
end

if gethui then
    print("=== Explorando gethui() ===")
    for _, obj in ipairs(gethui():GetChildren()) do
        print("ROOT:", obj.Name, obj.ClassName)
        dumpGui(obj, "   ")
    end
else
    warn("Tu executor no soporta gethui()")
end
