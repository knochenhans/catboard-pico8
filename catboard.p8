pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

game_state = "playing" -- "gameover"

Player = {
    id = 0,
    color = 0,
    color_sprite = 16,
    root_sprite = 0,
    fall_sprite = 0,
    current_sprite = 0,
    map_pos = { x = 0, y = 0 },
    score = 0,
    move_sfx = 0,
    anim_timer = 0,
    anim_wait = 1,
    fall_timer = 0,
    fall_wait = 1.3,
    fall_anim_timer = 0,
    fall_anim_wait = 0.2,
    state = "idle" -- "falling", "dead"
}

function Player:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Player:draw()
    -- printh(self.id .. ": " .. time() .. " - " .. self.anim_timer .. " > " .. self.anim_wait  )
    if self.state == "idle" then
        if time() - self.anim_timer > self.anim_wait then
            if self.current_sprite == self.root_sprite then
                self.current_sprite += flr(rnd(4))
            else
                self.current_sprite = self.root_sprite 
            end
            self.anim_timer = time()
            self.anim_wait = 0.5 + rnd(2.0)
        end
    elseif self.state == "falling" then
        -- printh(self.id .. ": " .. time() .. " - " .. self.fall_anim_timer .. " > " .. self.fall_anim_wait)
        if time() - self.fall_anim_timer > self.fall_anim_wait then
            self.current_sprite += 1
            self.fall_anim_timer = time()

            if self.current_sprite - self.fall_sprite == 2 then
                sfx(7, 3)
            end
        end
    elseif self.state == "dead" then
        self.current_sprite = 49
    end
    spr(self.current_sprite, self.map_pos.x * 8 + x_offset, self.map_pos.y * 8 + y_offset)
end

function Player:move(x, y)
    if self.state != "dead" then  
        self.map_pos.x = x
        self.map_pos.y = y
        set_tile_player_id(x, y, self.id)
        sfx(self.move_sfx, self.id)
    end
end

function Player:print_score()
    pos_x = 0

    if self.id == 1 then
        pos_x = 100
    end
    print("cat "..self.id + 1, pos_x, 0, self.color)
    print(self.score, self.color)
end

function Player:check_tile(tile)
    if tile.alive then
        if self.state == "falling" then
            self.state = "idle"
            self.fall_timer = 0
            self.anim_timer = 0
            sfx(-1, 3)
        end
    else
        if self.state == "idle" then
            if self.fall_timer == 0 then
                self.fall_timer = time()
                self.state = "falling"
                self.current_sprite = self.fall_sprite - 1
            end
        end
        
        if time() - self.fall_timer > self.fall_wait then
            self.state = "dead"
            sfx(8, 3)
            return false
        end
    end
    return true
end

Tile = {
    player_id = -1,
    pos = { x = 0, y = 0 },
    tile_destroy_timer = 0,
    tile_destroy_wait = 2.0,
    alive = true
}

function Tile:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Tile:sprite_from_player_id()
    if self.player_id == -1 then
        return 48
    elseif self.player_id == 0 then
        return 16
    else
        return 32
    end
end

function Tile:draw()
    sprite = self:sprite_from_player_id()
    
    if self.alive then
        spr(sprite, self.pos.x + x_offset, self.pos.y + y_offset)
    end
end

function Tile:update()
    if time() - self.tile_destroy_timer > self.tile_destroy_wait then
        self.tile_destroy_timer = time()
        self.alive = false
        sfx(6)
    end
    return self.alive
end

tiles = {}
players = {}

size = 10
x_offset = (128 - size*8) / 2 -- calculate x offset to center array horizontally
y_offset = (128 - size*8) / 2 -- calculate y offset to center array vertically

tiles_alive = size * size
players_alive = 2

function set_tile_player_id(x, y, player_id)
    tiles[x*size + y + 1].player_id = player_id
end

function get_tile_player_id(x, y)
    return tiles[x*size + y + 1].player_id
end

function get_player_by_id(id)
    for player in all(players) do
        if (player.id == id) return player
    end
end

function get_tile(x, y)
    return tiles[x*size + y + 1]
end

function check_player(x, y)
    for player in all(players) do
        if player.map_pos.x == x and player.map_pos.y == y then
            return true
        end
    end
end

function _init()
    -- Map
    for x=0, size-1 do
        for y=0, size-1 do
            pos = { x = x*8, y = y*8 }
            add(tiles, Tile:new { pos = pos, tile_destroy_wait = 2 + rnd(30.0) })
        end
    end

    -- Players
    map_pos = { x = 0, y = 0 }
    add(players, Player:new { id = 0, color = 9, color_sprite = 16, fall_sprite = 21, map_pos = map_pos, root_sprite = 17, score = 0, move_sfx = 0,})
    
    map_pos = { x = size - 1, y = size - 1 }
    add(players, Player:new { id = 1, color = 1, color_sprite = 32, fall_sprite = 37, map_pos = map_pos, root_sprite = 33, score = 0, move_sfx = 1, })

    for player in all(players) do
        player.current_sprite = player.root_sprite
        player:move(player.map_pos.x, player.map_pos.y)
    end
end

function _draw()
    cls()

    if game_state == "playing" then
        for tile in all(tiles) do
            tile:draw()
        end

        for player in all(players) do
            player:draw()
            player:print_score()
        end
    else
        rectfill(0, 0, 127, 127, 7)
        pal(0, 0) -- set color 0 (black) to palette index 0
        print("Game over!", 40, 40, 0)

        -- winner = 

        -- print("cat "..players[1].id + 1, 5, 55, self.color)
        -- print(self.score, self.color)
    end
end

function _update()
    if game_state == "playing" then
        for player in all(players) do
            if player.state != "dead" then
                old_pos = { x = player.map_pos.x, y = player.map_pos.y }
                move_by = { x = 0, y = 0 }

                if btnp(0, player.id) then -- left
                    move_by.x -= 1
                elseif btnp(1, player.id) then -- right
                    move_by.x += 1
                elseif btnp(2, player.id) then -- up
                    move_by.y -= 1
                elseif btnp(3, player.id) then -- down
                    move_by.y += 1
                end

                if move_by.x != 0 or move_by.y != 0 then
                    new_pos = { x = old_pos.x + move_by.x, y = old_pos.y + move_by.y }

                    -- Check if the other player is in the way
                    if check_player(new_pos.x, new_pos.y) then
                        sfx(2)
                        return
                    end 
                    
                    if new_pos.x >= 0 and new_pos.x < size and new_pos.y >= 0 and new_pos.y < size then
                        old_tile_player_id = get_tile_player_id(new_pos.x, new_pos.y)
                        if old_tile_player_id != -1 then
                            old_player = get_player_by_id(old_tile_player_id)
                            old_player.score -= 1
                        end
                        player:move(new_pos.x, new_pos.y)
                        player.score += 1
                    end
                end

                -- Check if the tile is falling/destroyed and if player died
                if not player:check_tile(get_tile(player.map_pos.x, player.map_pos.y)) then
                    players_alive -= 1

                    if players_alive == 0 then
                        game_state = "gameover"
                    end
                end
            end
        end

        for tile in all(tiles) do
            if tile.alive then
                if not tile:update() then
                    tiles_alive -= 1

                    if tiles_alive == 0 then
                        game_state = "gameover"
                    end
                end
            end
        end
    end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999000404000004040000004000000404000040004000400040000000000000000000000000000000000000000000000000000000000000000000000000
999a99a9000444000004440000004400000444000004440000044400000404000000000000000000000000000000000000000000000000000000000000000000
99a99a99004646400046464000004640004444400404440400064600000545000000400000000000000000000000000000000000000000000000000000000000
9a99a999000757000007570000044450000757000044444004475744004454400004540000000400000000000000000000000000000000000000000000000000
999a99a9004444000044440000444400004444000004440000045400000444000004440000004440000000000000000000000000000000000000000000000000
99a99a99044444000444440004444400044444000004440000044400000444000004440000000400000000000000000000000000000000000000000000000000
9a99a999044404404444044004440440444404400040004004400044004000400000000000000000000000000000000000000000000000000000000000000000
99999999400000000000000040000000000000000400000400000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd001010000010100000010000001010000010001000100010000000000000000000000000000000000000000000000000000000000000000000000000
dddcddcd001110000011100000110000001110000001110000011100000101000000000000000000000000000000000000000000000000000000000000000000
ddcddcdd016161000161610001610000011111000101110100061600000515000000100000000000000000000000000000000000000000000000000000000000
dcddcddd007570000075700005111000007570000011111001175711001151100001510000001000000000000000000000000000000000000000000000000000
dddcddcd001111000011110000111100001111000001110000015100000111000001110000011100000000000000000000000000000000000000000000000000
ddcddcdd001111100011111000111110001111100001110000011100000111000001110000001000000000000000000000000000000000000000000000000000
dcddcddd011011100110111101101110011011110010001001100011001000100000000000000000000000000000000000000000000000000000000000000000
dddddddd000000010000000000000001000000000100000100000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66676676000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66766766000560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67667666005556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66676676005556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66766766005556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67667666005556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000086100e6301264013640106500d6400763002620176001760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000b6100e6200d640106500e640096300562003610176001760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000131301b15021160251602a1602c1502d1502e1402a130211301913015140101500e1600e1600e1600f1601115013150121401214011130121201212012120111201112011110101100f1500f1500f150
000100001d13022140271502a1402b1302b1302813025130231202213020130181401714016150171501413013130151301213012140111401113011120101200f1100f1100e1100d1200d1300d1400c1500c130
000200001313013120141301414015140151401614016130161301613012130101400e1500e1500e150101401213014130181301a1401e1401f1402015020160201601f1601e1601d1401b120191101911016110
000200001113013130141601416013150111400f1300e1100d1100b1300a130091300813007130061300512005120041200412003120031200312002120021200211001110011100011000110001000010000000
000600003f61024600246100060014600096000860004600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
0013000019550185501755016540155401454013530125303850000500005000050000500005000050000500355001c5000050000500005000050000500005000050000500005000050000500005000050000500
000100000030024330283403035034360383603b3703f3703937036370333702d3702a360253501a3400f3200a310023000030000300083000530004300043000330001300013000030000300003000030000300
