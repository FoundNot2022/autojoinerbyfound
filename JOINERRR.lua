-- AutoJoiner mejorado: intenta varias formas de "pegado" para que el UI lo reconozca
-- Pégalo en Delta. Observa la consola y copia la salida si sigue fallando.

(function()
    repeat wait() until game:IsLoaded()
    local WebSocketURL = "ws://127.0.0.1:51948"

    local ws
    local connected = false

    local function prints(str)
        print("[AutoJoiner]: " .. tostring(str))
    end

    local function getAllDescendants()
        local arr = {}
        for _, v in ipairs(game:GetService("CoreGui"):GetDescendants()) do table.insert(arr, v) end
        if type(gethui) == "function" then
            for _, v in ipairs(gethui():GetDescendants()) do table.insert(arr, v) end
        end
        return arr
    end

    -- Busca InputText o cualquier TextBox candidato (primero InputText)
    local function findJobIDBox()
        -- prioridad InputText por tu dump
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextBox") and d.Name == "InputText" then
                prints("✅ Detectado cuadro de texto (by Name InputText)")
                return d
            end
        end
        -- fallback: buscar TextBox cuyo parent tenga label "Job-ID Input"
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextLabel") and d.Text and string.find(d.Text, "Job%-?ID") then
                local p = d.Parent
                if p then
                    for _, c in ipairs(p:GetChildren()) do
                        if c:IsA("TextBox") then
                            prints("✅ Detectado cuadro de texto (by Label parent)")
                            return c
                        end
                    end
                end
            end
        end
        -- fallback: devolver primer TextBox vacío oculto en menus (ultimo recurso)
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextBox") then
                prints("⚠️ Fallback: usando TextBox encontrado: " .. tostring(d.Name))
                return d
            end
        end
        return nil
    end

    -- Busca el botón Join por label "Join Job" o por TextButton en el mismo frame que label
    local function findJoinButton()
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextLabel") and d.Text and string.find(string.lower(d.Text), "join") then
                local p = d.Parent
                if p then
                    for _, c in ipairs(p:GetChildren()) do
                        if c:IsA("TextButton") then
                            prints("✅ Detectado botón Join Job-ID (por label parent)")
                            return c
                        end
                    end
                end
            end
        end
        -- fallback: primer TextButton que contenga "join" en su Text
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextButton") and d.Text and string.find(string.lower(d.Text), "join") then
                prints("✅ Detectado botón Join Job-ID (por TextButton text)")
                return d
            end
        end
        -- fallback general: primer TextButton (ultimo recurso)
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextButton") then
                prints("⚠️ Fallback: usando TextButton encontrado: " .. tostring(d.Name))
                return d
            end
        end
        return nil
    end

    -- intenta escribir "tipo humano" caracter por caracter
    local function simulateTyping(textBox, jobId)
        if not textBox then return false end
        pcall(function() textBox:CaptureFocus() end)
        local partial = ""
        for i = 1, #jobId do
            partial = partial .. jobId:sub(i,i)
            pcall(function() textBox.Text = partial end)
            -- intentar disparar TextChanged si existe
            pcall(function()
                if textBox.TextChanged then
                    textBox.TextChanged:Fire(partial)
                end
            end)
            task.wait(0.01) -- velocidad rapida pero no instantanea
        end
        task.wait(0.03)
        pcall(function() textBox:ReleaseFocus() end)
        -- forzar FocusLost con true (enter)
        pcall(function() if textBox.FocusLost then textBox.FocusLost:Fire(true) end end)
        -- intentar disparar Changed por Reflection (algunos UIs escuchan .Changed)
        pcall(function()
            if textBox.Changed then
                -- Changed es un event; no se puede Fire desde aqui normalmente, asi que no hacemos mas
            end
        end)
        return true
    end

    -- intento "pegado directo" + forzar eventos
    local function forceSetText(textBox, jobId)
        local ok, _ = pcall(function()
            textBox.Text = jobId
            pcall(function() textBox:CaptureFocus() end)
            task.wait(0.02)
            pcall(function() textBox:ReleaseFocus() end)
            -- TextChanged
            if textBox.TextChanged then
                pcall(function() textBox.TextChanged:Fire(jobId) end)
            end
            -- FocusLost enter
            if textBox.FocusLost then
                pcall(function() textBox.FocusLost:Fire(true) end)
            end
        end)
        return ok
    end

    -- si existe un TextButton "Input" o similar al lado, lo activamos (a veces abre modal donde pegar)
    local function tryActivateInputButtonNearLabel()
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextLabel") and d.Text and string.find(string.lower(d.Text), "job") and string.find(string.lower(d.Text), "id") then
                local p = d.Parent
                if p then
                    for _, c in ipairs(p:GetChildren()) do
                        if c:IsA("TextButton") then
                            prints("🔔 Activando TextButton cercano al label Job-ID -> " .. tostring(c.Name))
                            pcall(function() c:Activate() end)
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
    end

    -- principal: intenta varias tecnicas en orden
    local function writeJobIdRobust(textBox, jobId)
        if not textBox then return false end

        -- 1) intento rapido forzado
        if forceSetText(textBox, jobId) then
            prints("Intento rapido forzado hecho")
            task.wait(0.04)
        end

        -- 2) simulate typing (mas fiable)
        local ok = simulateTyping(textBox, jobId)
        if ok then
            prints("simulateTyping completado")
        end

        -- 3) si aun falla, intentar activar input button cercano y volver a escribir
        tryActivateInputButtonNearLabel()
        task.wait(0.05)
        -- reintentar typing
        simulateTyping(textBox, jobId)

        -- 4) re-fuerzos extra: TextChanged + FocusLost
        pcall(function()
            if textBox.TextChanged then textBox.TextChanged:Fire(jobId) end
            if textBox.FocusLost then textBox.FocusLost:Fire(true) end
        end)

        return true
    end

    -- funcion principal que recibe jobId
    local function bypass10M(jobId)
        prints("Bypassing 10m server: " .. tostring(jobId))
        local inputBox = findJobIDBox()
        local joinBtn = findJoinButton()

        if not inputBox or not joinBtn then
            prints("❌ No se encontró el Input o el Join Job-ID")
            -- log candidatos para debug
            prints("---- Candidatos TextBoxes ----")
            for _, d in ipairs(getAllDescendants()) do
                if d:IsA("TextBox") then
                    prints("TextBox -> Name: " .. tostring(d.Name) .. " | Text: " .. tostring(d.Text) .. " | Parent: " .. tostring(d.Parent and d.Parent.Name))
                end
            end
            prints("---- Candidatos TextButtons ----")
            for _, d in ipairs(getAllDescendants()) do
                if d:IsA("TextButton") then
                    prints("TextButton -> Name: " .. tostring(d.Name) .. " | Text: " .. tostring(d.Text) .. " | Parent: " .. tostring(d.Parent and d.Parent.Name))
                end
            end
            return
        end

        -- intentar escribir de forma robusta
        local ok = writeJobIdRobust(inputBox, jobId)
        prints("✅ JobID colocado (intentos realizados) -> " .. tostring(jobId))

        -- darle click al join (intentar conexiones y activate)
        local conns = {}
        pcall(function() conns = getconnections(joinBtn.MouseButton1Up) end)
        task.defer(function()
            task.wait(0.05)
            if conns and #conns > 0 then
                for _, c in ipairs(conns) do pcall(function() c:Fire() end) end
                prints("✅ Join Job-ID clickeado con conexiones")
            else
                pcall(function() joinBtn:Activate() end)
                prints("✅ Join Job-ID activado directamente")
            end
        end)
    end

    -- justJoin (sin cambios)
    local function justJoin(script)
        local func, err = loadstring(script)
        if func then
            local ok, result = pcall(func)
            if not ok then
                prints("Error while executing script: " .. tostring(result))
            end
        else
            prints("Some unexpected error: " .. tostring(err))
        end
    end

    -- Conectar al websocket
    local function connect()
        while not connected do
            prints("Trying to connect to " .. WebSocketURL)
            local success, socket = pcall(WebSocket.connect, WebSocketURL)
            if success and socket then
                ws = socket
                connected = true
                prints("Connected to WebSocket")
            else
                prints("Unable to connect to websocket, trying again..")
                wait(1)
            end
        end
    end

    local function startTeleport()
        if not ws then
            prints("WebSocket not connected yet!")
            return
        end
        ws.OnMessage:Connect(function(msg)
            if not string.find(msg, "TeleportService") then
                bypass10M(msg)
            else
                justJoin(msg)
            end
        end)
        ws.OnClose:Connect(function()
            prints("WebSocket closed.")
            connected = false
        end)
        prints("Teleport process started!")
    end

    -- UI de control minimo
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoJoinerGUI"
    screenGui.Parent = game:GetService("CoreGui")
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 150, 0, 50)
    button.Position = UDim2.new(0.5, -75, 0.5, -25)
    button.Text = "Autojoiner by Foundcito"
    button.BackgroundColor3 = Color3.fromRGB(0,170,255)
    button.TextScaled = true
    button.Parent = screenGui
    button.MouseButton1Click:Connect(function() startTeleport() end)

    connect()
end)()
