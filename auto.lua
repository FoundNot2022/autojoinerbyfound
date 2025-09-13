-- 🔎 Script para listar TODO el menu en consola
local CoreGui = game:GetService("CoreGui")

print("=========== ESCANEANDO MENU EN COREGUI ===========")

for _, obj in ipairs(CoreGui:GetDescendants()) do
    local info = "[Class: " .. obj.ClassName .. "] [Name: " .. obj.Name .. "]"
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        info = info .. " [Text: " .. obj.Text .. "]"
    end
    print(info)
end

print("=========== FIN DEL ESCANEO ===========")
