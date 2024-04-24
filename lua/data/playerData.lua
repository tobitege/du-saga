function getPlayerData()
    return {
        playerPosition = vec3(player.getWorldPosition()),
        playerFrozen = player.isFrozen(),
        playerSeated = player.isSeated(),
        playerVelocity = vec3(player.getWorldVelocity())
    }
end