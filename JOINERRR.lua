-- AutoJoiner con varios intentos de "pegar" JobID (clipboard, ctrl+v, typing, force events)
-- Pégalo en Delta. Copia la consola completa si sigue fallando.

(function()
    repeat task.wait() until game:IsLoaded()
    local WebSocketURL = "ws://127.0.0.1:51948"
    local ws
    local connected = false

    local function prints(s) print("[AutoJoiner]: " .. tostring(s)) end
    local function warns(s) warn("[AutoJoiner]: " .. tostring(s)) end

    -- obtiene todos los descendants de CoreGui + gethui
    local function getAllDescendants()
        local arr = {}
        for _, v in ipairs(game:GetService("CoreGui"):GetDescendants()) do table.insert(arr, v) end
        if type(gethui) == "function" then
            for _, v in ipairs(gethui():GetDescendants()) do table.insert(arr, v) end
        end
        return arr
    end

    -- Buscar TextBox preferido por nombre InputText, sino heuristica
    local function findJobIDBox()
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextBox") and d.Name == "InputText" then
                prints("✅ Encontrado TextBox por Name InputText")
                return d
            end
        end
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextLabel") and d.Text and string.find(string.lower(d.Text), "job") and string.find(string.lower(d.Text), "id") then
                local p = d.Parent
                if p then
                    for _, c in ipairs(p:GetChildren()) do
                        if c:IsA("TextBox") then
                            prints("✅ Encontrado TextBox por Label parent")
                            return c
                        end
                    end
                end
            end
        end
        -- fallback: primer TextBox
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextBox") then
                prints("⚠️ Fallback: usando TextBox: " .. tostring(d.Name))
                return d
            end
        end
        return nil
    end

    -- Buscar Join Button (por label o por texto 'join')
    local function findJoinButton()
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextLabel") and d.Text and string.find(string.lower(d.Text), "join") then
                local p = d.Parent
                if p then
                    for _, c in ipairs(p:GetChildren()) do
                        if c:IsA("TextButton") then
                            prints("✅ Encontrado Join Button (por label parent)")
                            return c
                        end
                    end
                end
            end
        end
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextButton") and d.Text and string.find(string.lower(d.Text), "join") then
                prints("✅ Encontrado Join Button (por TextButton text)")
                return d
            end
        end
        -- fallback: primer TextButton
        for _, d in ipairs(getAllDescendants()) do
            if d:IsA("TextButton") then
                prints("⚠️ Fallback: usando TextButton: " .. tostring(d.Name))
                return d
            end
        end
        return nil
    end

    -- Método 1: clipboard + intentar pegar con VirtualInputManager Ctrl+V (si setclipboard y VIM existen)
    local function pasteWithClipboard(textBox, jobId)
        local ok = false
        pcall(function()
            if type(setclipboard) == "function" then
                setclipboard(jobId)
                prints("✅ setclipboard ok")
                -- intentar enviar Ctrl+V si VirtualInputManager existe
                if pcall(function() return game:GetService("VirtualInputManager") end) then
                    local VIM = game:GetService("VirtualInputManager")
                    -- intentar enfoque y Ctrl+V simulacion
                    pcall(function() textBox:CaptureFocus() end)
                    task.wait(0.05)
                    -- intento varias combinaciones: Ctrl+V y Shift+Insert (algunos clients)
                    local successCtrlV = pcall(function()
                        VIM:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                        VIM:SendKeyEvent(true, Enum.KeyCode.V, false, game)
                        VIM:SendKeyEvent(false, Enum.KeyCode.V, false, game)
                        VIM:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                    end)
                    task.wait(0.06)
                    pcall(function() textBox:ReleaseFocus() end)
                    if successCtrlV then
                        prints("✅ Intentado Ctrl+V via VIM")
                        ok = true
                    end
                else
                    prints("⚠️ VirtualInputManager no disponible, clipboard seteado de todos modos")
                    ok = true
                end
            end
        end)
        return ok
    end

    -- Método 2: tipo carácter por carácter (más "humano")
    local function typeCharacterByCharacter(textBox, jobId, delay)
        delay = delay or 0.03
        pcall(function() textBox:CaptureFocus() end)
        local partial = ""
        for i = 1, #jobId do
            partial = partial .. jobId:sub(i,i)
            pcall(function() textBox.Text = partial end)
            pcall(function()
                if textBox.TextChanged then textBox.TextChanged:Fire(partial) end
            end)
            task.wait(delay)
        end
        task.wait(0.04)
        pcall(function() textBox:ReleaseFocus() end)
        pcall(function() if textBox.FocusLost then textBox.FocusLost:Fire(true) end end)
    end

    -- Método 3: forzar eventos (FocusLost + TextChanged)
    local function forceEvents(textBox, jobId)
        pcall(function() textBox.Text = jobId end)
        pcall(function() if textBox.TextChanged then textBox.TextChanged:Fire(jobId) end end)
        pcall(function() if textBox.FocusLost then textBox.FocusLost:Fire(true) end end)
    end

    -- Intenta varias estrategias en secuencia (clipboard -> ctrlv -> typing -> force)
    local function writeJobRobust(textBox, jobId)
        if not textBox then return false end

        prints("➡️ Intentando paste via clipboard (si está disponible)")
        local ok = pasteWithClipboard(textBox, jobId)
        task.wait(0.08)
        -- Comprobar si hub detecta (no hay manera universal de comprobar, asi que seguimos)
        -- Intento typing lento si el hub parece bloquear pegados
        prints("➡️ Intentando typing caracter por caracter (vel normal)")
        typeCharacterByCharacter(textBox, jobId, 0.02)
        task.wait(0.06)
        -- Forzar eventos finales
        prints("➡️ Forzando eventos TextChanged/FocusLost")
        forceEvents(textBox, jobId)
        task.wait(0.05)
        return true
    end

    -- Intento avanzado: buscar function Join dentro de getgc y llamar (solo si getgc/islclosure disponible)
    local function tryCallInternalJoin(jobId)
        local ok = false
        pcall(function()
            if type(getgc) == "function" then
                for _, v in ipairs(getgc(true)) do
                    if type(v) == "function" then
                        local info = pcall(function() return debug.getinfo(v).name end)
                        local name = nil
                        if info then
                            name = debug.getinfo(v).name
                        end
                        if name and (string.find(string.lower(name), "join") or string.find(string.lower(name), "teleport")) then
                            pcall(function() v(jobId) end)
                            prints("🧩 Intentada llamada interna a: " .. tostring(name))
                            ok = true
                            break
                        end
                    end
                end
            end
        end)
        return ok
    end

    -- principal que coloca job y presiona join
    local function bypass10M(jobId)
        prints("Bypass pedido -> " .. tostring(jobId))
        local textBox = findJobIDBox()
        local joinBtn = findJoinButton()
        if not textBox then prints("❌ No se encontro TextBox (Input)") end
        if not joinBtn then prints("❌ No se encontro Join Button") end
        if not textBox or not joinBtn then
            prints("Lista candidatos para debug:")
            for _, d in ipairs(getAllDescendants()) do
                if d:IsA("TextBox") or d:IsA("TextButton") then
                    prints(d.ClassName .. " | Name:"..tostring(d.Name).." | Text:"..tostring(d.Text).." | Parent:"..tostring(d.Parent and d.Parent.Name))
                end
            end
            return
        end

        -- 1) Intento robusto
        writeJobRobust(textBox, jobId)
        prints("✅ Hecho: intento de pegado/escritura completado")

        -- 1.5) Si el hub tiene anti-block, espera y reintenta typing mas lento
        task.wait(0.09)
        -- chequeo: desafortunadamente no hay forma fiable de comprobar, asi que un pequeño re-write lento
        typeCharacterByCharacter(textBox, jobId, 0.06)
        pcall(function() if textBox.FocusLost then textBox.FocusLost:Fire(true) end end)

        -- 2) Intentar llamada interna a la funcion de join (si existe)
        local calledInternal = tryCallInternalJoin(jobId)
        if calledInternal then
            prints("🧩 Intento de llamada interna hecho (si existia la funcion).")
        end

        -- 3) Hacer click en Join
        task.wait(0.05)
        local conns = {}
        pcall(function() conns = getconnections(joinBtn.MouseButton1Up) end)
        if conns and #conns > 0 then
            for _, c in ipairs(conns) do pcall(function() c:Fire() end) end
            prints("✅ Join clickeado via connections")
        else
            pcall(function() joinBtn:Activate() end)
            prints("✅ Join activado via Activate()")
        end
    end

    -- justJoin (sin cambios)
    local function justJoin(script)
        local func, err = loadstring(script)
        if func then
            local ok, result = pcall(func)
            if not ok then prints("Error al ejecutar script: "..tostring(result)) end
        else prints("Error loadstring: "..tostring(err)) end
    end

    -- conectar WS (igual que tu original)
    local function connect()
        while not connected do
            prints("Trying to connect to " .. WebSocketURL)
            local success, socket = pcall(WebSocket.connect, WebSocketURL)
            if success and socket then ws = socket connected = true prints("Connected to WebSocket") else prints("Unable to connect, retrying...") task.wait(1) end
        end
    end

    local function startTeleport()
        if not ws then prints("WebSocket not connected!") return end
        ws.OnMessage:Connect(function(msg)
            if not string.find(tostring(msg), "TeleportService") then
                bypass10M(tostring(msg))
            else
                justJoin(msg)
            end
        end)
        ws.OnClose:Connect(function() prints("WebSocket closed.") connected = false end)
        prints("Teleport process started")
    end

    -- UI simple (tu boton)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoJoinerGUI"
    screenGui.Parent = game:GetService("CoreGui")
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,150,0,50)
    btn.Position = UDim2.new(0.5,-75,0.5,-25)
    btn.Text = "Autojoiner by Foundcito1"
    btn.Parent = screenGui
    btn.MouseButton1Click:Connect(function() startTeleport() end)

    connect()
end)()
