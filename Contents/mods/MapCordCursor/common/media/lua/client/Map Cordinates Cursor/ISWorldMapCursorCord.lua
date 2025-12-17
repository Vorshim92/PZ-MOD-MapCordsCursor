require "ISUI/ISPanel"
require "ISToolTip"  
-- ISWorldMap_instance (global variable to check if the ISWorldMap is already initialise and visibile with ISWorldMap_instance:isVisible() )

ISToolTipCord = ISToolTip:derive("ISToolTipCord")

local MGRS = false
if getActivatedMods():contains("\\MGRS (FMCCYAYFGLE)") then
    MGRS = true
end

local MDZ = false
if getActivatedMods():contains("\\MoreDifficultZones") or getActivatedMods():contains("\\TierZonyne42") then
    MDZ = true
end

-- local ISWorldMap_render = ISWorldMap.render;
local ISWorldMap_createChildren = ISWorldMap.createChildren;
local ISWorldMap_onMouseMove = ISWorldMap.onMouseMove;
local ISWorldMap_onRightMouseUp = ISWorldMap.onRightMouseUp
ISWorldMap.showCoordinates = true  
-- local ISWorldMap_instance = nil;


function ISWorldMap:createChildren()
    -- Chiama la funzione originale
    ISWorldMap_createChildren(self)

    -- Crea e aggiungi il tooltip come child
        self.tooltip = ISToolTipCord:new()
        self.tooltip:initialise()
        if self.showCoordinates then
            -- self.tooltip:addToUIManager()
            self.tooltip:setVisible(true)
        else
            self.tooltip:setVisible(false)
            -- self.tooltip:removeFromUIManager()
        end 
        self:addChild(self.tooltip)  -- Aggiungi il tooltip come child del pannello della mappa
end

function ISWorldMap:toogleTooltip(flag)
    self.showCoordinates = flag
    if flag then
        -- self.tooltip:addToUIManager()
        self.tooltip:setVisible(true)
    else
        self.tooltip:setVisible(false)
        -- self.tooltip:removeFromUIManager()
    end
end

function ISWorldMap:updateTooltip(x, y)
    if not self.showCoordinates then
        return
    end
    if self.symbolsUI:isMouseOver(x, y) then
        self.tooltip:setVisible(false)
        -- self.tooltip:removeFromUIManager()
        return
    end

    if self.buttonPanel and self.buttonPanel:isMouseOver() then
        self.tooltip:setVisible(false)
        -- self.tooltip:removeFromUIManager()
        return
    end

    if self.optionBtn and self.optionBtn:isMouseOver() then
        self.tooltip:setVisible(false)
        -- self.tooltip:removeFromUIManager()
        return
    end
    
    local worldX = self.mapAPI:uiToWorldX(x, y)
    local worldY = self.mapAPI:uiToWorldY(x, y)
    if getWorld():getMetaGrid():isValidChunk(worldX / 10, worldY / 10) then
        self.tooltip:setVisible(true)
        self.tooltip.coordX = math.floor(worldX)
        self.tooltip.coordY = math.floor(worldY)
        self.tooltip:setX(x + 32)  -- Aggiusta la posizione del tooltip rispetto al cursore
        if MGRS and self.showCellGrid then
            y = y + 50
        end
        self.tooltip:setY(y + 10)
        if MDZ then
            -- Ottieni tierLevel e zoneName attuali
            self.tooltip.currentTierLevel, self.tooltip.currentZoneName, self.x, self.y, self.control, self.toxic, self.sprinter, self.pinpoint, self.cognition = checkZoneAtXY(worldX, worldY)
            if self.tooltip.currentZoneName == "Unnamed Zone" then self.tooltip.currentZoneName = "Default" end
        end
    else
        self.tooltip:setVisible(false)
        -- self.tooltip:removeFromUIManager()
        return
    end
end

local ISWorldMap_render = ISWorldMap.render
function ISWorldMap:render()
    ISWorldMap_render(self)
    if (MGRS and self.showCellGrid) and (self.symbolsUI:isMouseOver() or self.buttonPanel and self.buttonPanel:isMouseOver()) then
        self.currentGridID = nil
    end
    if self.showCoordinates then
        -- Inizializza il testo con coordinate X e Y
        self.tooltip.description = string.format(
            "<RGB:1,1,0>X: <SPACE><RGB:1,1,1>%d <SPACE><RGB:1,1,0>Y: <SPACE><RGB:1,1,1>%d\n",
            self.tooltip.coordX,
            self.tooltip.coordY
        )
    
        -- Se MDZ è definito, aggiungi Tier e Zone
        if MDZ then 
            if self.tooltip.currentTierLevel and self.tooltip.currentZoneName then
                self.tooltip.description = self.tooltip.description .. string.format(
                    " <LINE> <RGB:0,1,0>T: <SPACE><RGB:1,1,1>%d  <SPACE><RGB:0,1,0>Z: <SPACE><RGB:1,1,1>%s",
                    self.tooltip.currentTierLevel,
                    self.tooltip.currentZoneName
                )
            end
            if self.toxic then
                self.tooltip.description = self.tooltip.description .. " <SPACE><IMAGE:media/ui/biohazardOn.png,16,16>"
            else
                self.tooltip.description = self.tooltip.description .. " <SPACE><IMAGE:media/ui/biohazardOff.png,16,16>"
            end
            if self.sprinter then
                self.tooltip.description = self.tooltip.description .. string.format(
                    " <LINE> <RGB:0,1,0>Sprinter: <SPACE><RGB:1,1,1>%d%%",
                    self.sprinter
                )
            end
        end
    end

end
 


function ISWorldMap:onMouseMove(dx, dy)
    ISWorldMap_onMouseMove(self, dx, dy)
    if (MGRS and self.showCellGrid) and (self.symbolsUI:isMouseOver() or self.buttonPanel and self.buttonPanel:isMouseOver()) then
        self.currentGridID = nil
    end
    local x, y = self:getMouseX(), self:getMouseY()
    self:updateTooltip(x, y)
    
    return true
end

-- Funzione unificata onRightMouseUp per gestire sia admin che client
function ISWorldMap:onRightMouseUp(x, y)
    local isAdmin = getDebug() or (isClient() and (getAccessLevel() == "admin"))
    local playerNum = 0
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end -- Debug in main menu

    if self.symbolsUI:onRightMouseUpMap(x, y) then
        return true
    end
    
    -- Ottieni il context menu
    local context = ISContextMenu.get(playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY())
    
    -- Chiama la funzione originale una sola volta
    ISWorldMap_onRightMouseUp(self, x, y)
    
    -- Aggiungi l'opzione per mostrare/nascondere il tooltip delle coordinate (per tutti)
    local optionText = self.showCoordinates and "Hide Coordinates" or "Show Coordinates"
    local option = context:addOptionOnTop(optionText, self, function(self)
         self:toogleTooltip(not self.showCoordinates)
        end)
    context:setOptionChecked(option, self.showCoordinates)
    
    -- Aggiungi l'opzione "Show Cell Grid" solo per i client (non admin)
    if not isAdmin  then
        option = context:addOption("Show Cell Grid", self, function(self)
            self:setShowCellGrid(not self.showCellGrid)
        end)
        context:setOptionChecked(option, self.showCellGrid)
    end

    return true
end





function ISToolTipCord:new()
    local o = ISToolTip.new(self)
    setmetatable(o, self)
    self.__index = self
    o:noBackground()
    o.name = "Coordinates"
    o.description = ""
    o.borderColor = {r = 0.4, g = 0.4, b = 0.4, a = 1}
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0.5}
    o.width = 0
    o.height = 0
    o.coordX = 0
    o.coordY = 0
    o.anchorLeft = false
    o.anchorRight = false
    o.anchorTop = false
    o.anchorBottom = false
    o.owner = nil
    o.followMouse = false --maybe false?
    return o
end



