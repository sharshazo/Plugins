-- LOTRO_Quest_Assistant/Data/QuestDatabase.lua
import "Turbine"

_G.QuestDatabase = {
    -- DATOS DE MUESTRA PARA LA PRIMERA PRUEBA OBLIGATORIA
    ["Intro: Los lobos de las ruinas"] = {
        name = "Intro: Los lobos de las ruinas",
        did = "MOCK_DID_001",
        objectives = {
            ["Lobos derrotados"] = {
                type = "DEFEAT",
                target = "Lobo",
                total = 4,
                loc = "15.0S, 75.0W" -- Coordenada de prueba
            }
        }
    }
}

