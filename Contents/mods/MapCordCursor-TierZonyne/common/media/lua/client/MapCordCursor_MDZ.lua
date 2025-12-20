-- MapCordCursor_MDZ.lua
-- Integrazione TierZonyne per Map Coordinates Cursor

local ISWorldMap_updateTooltip = ISWorldMap.updateTooltip
local ISWorldMap_render = ISWorldMap.render

-- Override updateTooltip per aggiungere dati zona
function ISWorldMap:updateTooltip(x, y)
    ISWorldMap_updateTooltip(self, x, y)

    if not self.showCoordinates or not self.tooltip:isVisible() then
        return
    end

    local worldX = self.mapAPI:uiToWorldX(x, y)
    local worldY = self.mapAPI:uiToWorldY(x, y)

    -- Ottieni dati zona da TierZonyne
    local tierLevel, zoneName, zx, zy, control, toxic, sprinter, pinpoint, cognition = checkZoneAtXY(worldX, worldY)
    if zoneName == "Unnamed Zone" then zoneName = "Default" end

    self.tooltip.zoneData = {
        tierLevel = tierLevel,
        zoneName = zoneName,
        toxic = toxic,
        sprinter = sprinter
    }
end

-- Override render per formattare descrizione con dati MDZ
function ISWorldMap:render()
    ISWorldMap_render(self)

    if not self.showCoordinates or not self.tooltip.zoneData then
        return
    end

    local zd = self.tooltip.zoneData

    -- Tier e Zone
    if zd.tierLevel and zd.zoneName then
        self.tooltip.description = self.tooltip.description .. string.format(
            " <LINE> <RGB:0,1,0>T: <SPACE><RGB:1,1,1>%d  <SPACE><RGB:0,1,0>Z: <SPACE><RGB:1,1,1>%s",
            zd.tierLevel,
            zd.zoneName
        )
    end

    -- Toxic indicator
    if zd.toxic then
        self.tooltip.description = self.tooltip.description .. " <SPACE><IMAGE:media/ui/biohazardOn.png,16,16>"
    else
        self.tooltip.description = self.tooltip.description .. " <SPACE><IMAGE:media/ui/biohazardOff.png,16,16>"
    end

    -- Sprinter percentage
    if zd.sprinter then
        self.tooltip.description = self.tooltip.description .. string.format(
            " <LINE> <RGB:0,1,0>Sprinter: <SPACE><RGB:1,1,1>%d%%",
            zd.sprinter
        )
    end
end
