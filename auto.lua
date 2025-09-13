local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("===== Explorando lugares posibles =====")

-- CoreGui
print("\n--- CoreGui ---")
for _, obj in ipairs(game:GetService("CoreGui"):GetChildren()) do
    print(obj.Name, obj.ClassName)
end

-- PlayerGui
print("\n--- PlayerGui ---")
for _, obj in ipairs(player:WaitForChild("PlayerGui"):GetChildren()) do
    print(obj.Name, obj.ClassName)
end

-- gethui (si existe)
if gethui then
    print("\n--- gethui() ---")
    for _, obj in ipairs(gethui():GetChildren()) do
        print(obj.Name, obj.ClassName)
    end
else
    print("\nNo existe gethui() en tu executor.")
end
