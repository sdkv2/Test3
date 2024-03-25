local json = require 'libraries/JSON'
local chat = {}

local invert = false
chat.CurrentChar = 1
chat.CurrentDialogue = nil
chat.TimeElapsed = 0 -- New variable to keep track of time

chat.line = 1

chat.keys = {} -- Make keys a member of the chat table

function chat:loadJson(filePath)
    local f = io.open(filePath, "r")
    local content = f:read("*all")
    f:close()
    return json:decode(content)
end

function chat:chat(npc, subtable)
    invert = false
    self.index = 1
    dialogue = chat:loadJson('npcs/dialogue.json')
    self.npc = npc
    self.subtable = subtable
    chatting = true
    if dialogue and dialogue[npc] and dialogue[npc][subtable] then
        self.CurrentDialogue = dialogue[npc]['1']
        -- Get the keys
        self.keys = {} -- Reset keys for each new dialogue
        for k in pairs(self.CurrentDialogue) do
            table.insert(self.keys, k)
        end

        table.sort(self.keys)

        self.CurrentLine = self.CurrentDialogue[self.keys[self.line]]
        print(self.CurrentLine)
    end
    print("NPC: ", npc)
    print("Subtable: ", subtable)
    print("CurrentDialogue: ", self.CurrentLine)
end

function chat:nextLine()
    if self.CurrentDialogue then
        if self.CurrentChar <= #self.CurrentLine then
            self.CurrentChar = #self.CurrentLine
        else
            self.line = self.line + 1
            if self.keys[self.line] then
                self.CurrentLine = self.CurrentDialogue[self.keys[self.line]]
                self.CurrentChar = 1
            else
                chat:endChat()
            end
        end
    end
end

function chat:endChat()
    chatting = false
    invert = true
    self.CurrentDialogue = nil
    self.CurrentLine = nil
    self.line = 1
end

function chat:playSound()
    local length = 0.1 -- The length of the sound in seconds
    local rate = 44100 -- The sample rate of the sound
    local frequency = 100
    local soundData = love.sound.newSoundData(math.floor(length*rate), rate, 16, 1)
    local unisonCount = 6 -- The number of unison voices
    local detuneAmount = 0.1 -- The amount of detuning for the unison voices
    local phase = {} -- Initialize phase for each unison voice
    for j=1, unisonCount do
        phase[j] = 0
    end

    local fadeTime = 0.01 -- The length of the fade in and fade out in seconds
    local fadeSamples = fadeTime * rate -- The number of samples over which to fade in and out

    for i=0, soundData:getSampleCount() - 1 do
        local t = i / rate -- The time of the sample
        local volume = 0.5 * (1 + math.sin(0.1 * t)) / unisonCount -- Vary the volume over time and divide by the number of unison voices

        -- Apply a fade in and fade out to the volume
        if i < fadeSamples then
            volume = volume * (i / fadeSamples)
        elseif i > soundData:getSampleCount() - fadeSamples then
            volume = volume * ((soundData:getSampleCount() - i) / fadeSamples)
        end

        local sample = 0
        -- Generate a triangle wave for each unison voice
        for j=1, unisonCount do
            local detune = 1 + (j - 1) * detuneAmount -- Calculate the detuning for this voice
            phase[j] = phase[j] + (frequency * detune / rate) -- Increment the phase
            phase[j] = phase[j] % 1 -- Wrap the phase to the range [0, 1]
            local triangle = 2 * math.abs(2 * phase[j] - 1) - 1
            sample = sample + volume * triangle
        end
        soundData:setSample(i, sample)
    end
    local sound = love.audio.newSource(soundData)

    local filterSettings = {
        type = 'lowpass',
        volume = 1,
        highgain = 0.5
    }
    sound:setFilter(filterSettings)

    -- Play the sound
    love.audio.play(sound)
end

function chat:progressChat(dt)
    self.TimeElapsed = self.TimeElapsed + dt
    if self.CurrentLine and self.CurrentChar <= #self.CurrentLine and self.TimeElapsed >= 0.07 then
        self.CurrentChar = self.CurrentChar + 1
        self.TimeElapsed = 0 -- Reset the timer after updating the character

        -- Call the playSound function
        self:playSound()
    end
    -- Check if the next character is available before updating self.CurrentLine
    if self.CurrentDialogue and self.keys[self.line] then
        self.CurrentLine = self.CurrentDialogue[self.keys[self.line]]
    end
end

function chat:update(dt)
    self:progressChat(dt)
    rectangles, complete = border(dt, rectangles, target, invert, true)

end

function chat:draw()

    love.graphics.setColor(0,0,0)
    for num, rect in ipairs(rectangles) do
        love.graphics.rectangle('fill', rect.x, rect.y, rect.width, rect.height)
        if num == 1 then
            love.graphics.setColor(1,1,1)
            love.graphics.draw(love.graphics.newImage('sprites/butler_neutral.png'), rect.x, h - rect.height, 0, 2, 2)
            if self.CurrentLine then
                love.graphics.print(string.sub(self.CurrentLine, 1, self.CurrentChar), rect.x + 300, h - rect.height + 30, 0, 4, 4)
            end
        end
    end
end

return chat