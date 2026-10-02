function love.load()
    love.window.setTitle("Endless Running Game")
    love.window.setMode(0, 0, {
        fullscreen = true,
        resizable = false,
        vsync = true
    })

    screenWidth  = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()

    math.randomseed(os.time())
    love.math.setRandomSeed(os.time())

    bgImage  = love.graphics.newImage("Background.png")
    fgImage  = love.graphics.newImage("Foreground.png")

    bgScaleX = screenWidth  / bgImage:getWidth()
    bgScaleY = screenHeight / bgImage:getHeight()
    fgScaleX = screenWidth  / fgImage:getWidth()
    fgScaleY = screenHeight / fgImage:getHeight()

    obstacleImages = {
        love.graphics.newImage("Obstacle_1.png"),
        love.graphics.newImage("Obstacle_2.png"),
        love.graphics.newImage("Obstacle_3.png")
    }
    

    runSheet  = love.graphics.newImage("Run.png")
    jumpSheet = love.graphics.newImage("Jump.png")
    deathImg  = love.graphics.newImage("Death.png")

    local runCols = 3
    runFrameW = runSheet:getWidth() / runCols
    runFrameH = runSheet:getHeight()
    runFrames = {}
    for i = 0, runCols - 1 do
        table.insert(runFrames, love.graphics.newQuad(
            i * runFrameW, 0, runFrameW, runFrameH,
            runSheet:getWidth(), runSheet:getHeight()
        ))
    end

    local jumpCols = 1
    jumpFrameW = jumpSheet:getWidth() / jumpCols
    jumpFrameH = jumpSheet:getHeight()
    jumpFrames = {}
    for i = 0, jumpCols - 1 do
        table.insert(jumpFrames, love.graphics.newQuad(
            i * jumpFrameW, 0, jumpFrameW, jumpFrameH,
            jumpSheet:getWidth(), jumpSheet:getHeight()
        ))
    end

    bgMusic = love.audio.newSource("BGMusic.wav", "stream")
    jumpSound = love.audio.newSource("Jump.wav", "static")
    gameOverSnd = love.audio.newSource("GameOver.wav",  "static")

    bgMusic:setLooping(true)
    bgMusic:setVolume(0.5)

    highScore = 0
    if love.filesystem.getInfo("highscore.txt") then
        highScore = tonumber(love.filesystem.read("highscore.txt")) or 0
    end

    fontSmall = love.graphics.newFont(22)
    fontMed = love.graphics.newFont(32)
    fontLarge = love.graphics.newFont(56)

    resetGame()
    love.audio.play(bgMusic)
end


function resetGame()
    fgY = screenHeight - fgImage:getHeight() * fgScaleY
    ground = fgY + fgImage:getHeight() * fgScaleY * 0.85

    bgScrollX = 0
    fgScrollX = 0

    local pScale  = 2.5
    local pWidth  = runFrameW * pScale
    local pHeight = runFrameH * pScale

    player = {
        x = 140,
        y = ground - pHeight,
        width = pWidth,
        height = pHeight,
        scale  = pScale,
        velocityY = 0,
        jumpForce = -700,
        gravity = 1700,
        grounded = true,
        state = "run"
    }

    animTimer = 0
    animSpeed = 0.10
    currentFrame = 1
    jumpFrame = 1
    jumpTimer = 0

    obstacles = {}
    obstacleTimer = 0
    obstacleIntervalMin = 1.2
    obstacleIntervalMax = 2.2
    nextObstacleTime = randomObstacleTime()

    gameSpeed = 420
    score = 0
    gameOver = false
    confirmQuit = false
    gameOverPlayed = false
end


function randomObstacleTime()
    return love.math.random() *
           (obstacleIntervalMax - obstacleIntervalMin)
           + obstacleIntervalMin
end


function spawnObstacle()
    local roll = love.math.random(1, 3)
    local img

    img = obstacleImages[roll]

    local scale = love.math.random(28, 40) / 10
    local w = img:getWidth()  * scale
    local h = img:getHeight() * scale

    table.insert(obstacles, {
        x = screenWidth + 60,
        y = ground - h,
        width  = w,
        height = h,
        img = img,
        scale  = scale
    })
end


function checkCollision(a, b)
    local pad = 10
    return a.x + pad < b.x + b.width  - pad and
           b.x + pad < a.x + a.width  - pad and
           a.y + pad < b.y + b.height - pad and
           b.y + pad < a.y + a.height - pad
end


function love.update(dt)
    if confirmQuit then return end
    if gameOver then return end

    score = score + dt * 10
    gameSpeed = gameSpeed + dt * 4

    bgScrollX = bgScrollX - gameSpeed * 0.15 * dt
    fgScrollX = fgScrollX - gameSpeed * dt

    if bgScrollX <= -screenWidth then bgScrollX = 0 end
    if fgScrollX <= -screenWidth then fgScrollX = 0 end

    if player.grounded then
        player.state = "run"
        animTimer = animTimer + dt
        if animTimer >= animSpeed then
            animTimer = 0
            currentFrame = (currentFrame % #runFrames) + 1
        end
    else
        player.state = "jump"
        jumpTimer = jumpTimer + dt
        if jumpTimer >= animSpeed then
            jumpTimer = 0
            jumpFrame = (jumpFrame % #jumpFrames) + 1
        end
    end

    player.velocityY = player.velocityY + player.gravity * dt
    player.y = player.y + player.velocityY * dt

    if player.y >= ground - player.height then
        player.y= ground - player.height
        player.velocityY = 0
        player.grounded  = true
    end

    obstacleTimer = obstacleTimer + dt
    if obstacleTimer >= nextObstacleTime then
        spawnObstacle()
        obstacleTimer = 0
        nextObstacleTime = randomObstacleTime()
    end

    for i = #obstacles, 1, -1 do
        local obs = obstacles[i]
        obs.x = obs.x - gameSpeed * dt

        if obs.x + obs.width < 0 then
            table.remove(obstacles, i)
        elseif checkCollision(player, obs) then
            gameOver = true
            player.state = "death"
            if score > highScore then
                highScore = score
                love.filesystem.write("highscore.txt", tostring(highScore))
            end
        end
    end

    if gameOver and not gameOverPlayed then
        bgMusic:stop()
        love.audio.play(gameOverSnd)
        gameOverPlayed = true
    end
end


function love.keypressed(key)
    if key == "space"
    and player.grounded
    and not gameOver
    and not confirmQuit then
        player.velocityY = player.jumpForce
        player.grounded  = false
        jumpFrame = 1
        jumpTimer = 0
        love.audio.stop(jumpSound)
        love.audio.play(jumpSound)
    end

    if key == "r" and gameOver then
        resetGame()
        bgMusic:stop()
        love.audio.play(bgMusic)
    end

    if key == "escape" then
        if confirmQuit then
            love.event.quit()
        else
            confirmQuit = true
        end
    end

    if key == "n" and confirmQuit then
        confirmQuit = false
    end
end


function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(bgImage, bgScrollX, 0, 0, bgScaleX, bgScaleY)
    love.graphics.draw(bgImage, bgScrollX + screenWidth, 0, 0, bgScaleX, bgScaleY)

    love.graphics.draw(fgImage, fgScrollX, fgY, 0, fgScaleX, fgScaleY)
    love.graphics.draw(fgImage, fgScrollX + screenWidth, fgY, 0, fgScaleX, fgScaleY)

    for _, obs in ipairs(obstacles) do
        love.graphics.draw(obs.img, obs.x, obs.y, 0, obs.scale, obs.scale)
    end

    if player.state == "run" then
        love.graphics.setColor(0.3, 1, 0.4)
        love.graphics.draw(
            runSheet, runFrames[currentFrame],
            player.x, player.y, 0,
            player.scale, player.scale
        )
    elseif player.state == "jump" then
        love.graphics.setColor(0.3, 1, 0.4)
        love.graphics.draw(
            jumpSheet, jumpFrames[jumpFrame],
            player.x, player.y, 0,
            player.scale, player.scale
        )
    elseif player.state == "death" then
        love.graphics.setColor(0.3, 1, 0.4)
        love.graphics.draw(
            deathImg,
            player.x, player.y, 0,
            player.scale, player.scale
        )
    end

    love.graphics.setFont(fontMed)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. math.floor(score), 20, 20)
    love.graphics.print("Best:  " .. math.floor(highScore), 20, 58)

    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

        love.graphics.setColor(1, 0.80, 0.2)
        love.graphics.setFont(fontLarge)
        love.graphics.printf("GAME OVER", 0, screenHeight / 2 - 90, screenWidth, "center")

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontMed)
        love.graphics.printf(
            "Score: " .. math.floor(score) ..   "\n Best: ".. math.floor(highScore),
            0, screenHeight / 2, screenWidth, "center"
        )

        love.graphics.setFont(fontSmall)
        love.graphics.printf(
            "Press R to Restart    ESC to Quit",
            0, screenHeight / 2 + 90, screenWidth, "center"
        )
    end

    if confirmQuit then
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontLarge)
        love.graphics.printf("Quit Game?", 0, screenHeight / 2 - 70, screenWidth, "center")

        love.graphics.setFont(fontMed)
        love.graphics.printf(
            "Press ESC again to quit\nPress N to cancel",
            0, screenHeight / 2 + 10, screenWidth, "center"
        )
    end
end
