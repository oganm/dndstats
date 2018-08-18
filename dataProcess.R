library(import5eChar)
library(purrr)
library(readr)
library(glue)
library(digest)
library(dplyr)
library(XML)
library(ogbox) # github.com/oganm/ogbox
library(wizaRd)
library(stringr)


# get all char files saved everywhere
charFiles = c(list.files('/srv/shiny-server/printSheetApp/chars/',full.names = TRUE),
              list.files('/srv/shiny-server/interactiveSheet/chars/',full.names = TRUE),
              list.files('/srv/shiny-server/chars',full.names = TRUE),
              list.files('/srv/shiny-server/chars2', full.names = TRUE),
              list.files('/srv/shiny-server/chars3', full.names = TRUE),
              list.files('/srv/shiny-server/chars4', full.names = TRUE))
print('reading char files')
# use import5eChar to read the all of them
chars = charFiles %>% lapply(function(x){
    importCharacter(file = x)
})

# get date information. dates before 2018-04-16 are not reliable 
fileInfo = file.info(charFiles) 
# get user fingerprint and IP
fileData = charFiles %>% basename %>% strsplit('_')

# add file and user info to the characters
print('constructing char table')
chars = lapply(1:length(chars),function(i){
    char = chars[[i]]
    char$date = fileInfo$mtime[i]
    if(length(fileData[[i]]) == 1){
        char$ip = 'NULL'
        char$finger = 'NULL'
        char$hash = fileData[[i]]
    } else{
        char$finger = fileData[[i]][1]
        char$ip = fileData[[i]][2]
        char$hash = fileData[[i]][3]
    }
    char
})

# setting the names to character name and class. this won't be exposed to others
names(chars) = chars %>% map_chr(function(x){
    paste(x$Name,x$ClassField)
})

# create the table 
charTable = chars %>% map(function(x){
    data.frame(ip = x$ip,
               finger = x$finger,
               hash = x$hash,
               name = x$Name,
               race = x$Race,
               background = x$Background,
               date = x$date,
               class = paste(x$classInfo[,1],x$classInfo[,3],collapse='|'),
               justClass =  x$classInfo[,'Class'] %>% paste(collapse ='|'),
               subclass = x$classInfo[,'Archetype'] %>% paste(collapse ='|'),
               level = x$classInfo[,'Level'] %>% as.integer() %>% sum,
               feats = x$feats[x$feats !=''] %>% paste(collapse = '|'),
               HP = x$currentHealth,
               AC = AC(x),
               Str = x$abilityScores['Str'],
               Dex = x$abilityScores['Dex'],
               Con = x$abilityScores['Con'],
               Int = x$abilityScores['Int'],
               Wis = x$abilityScores['Wis'],
               Cha = x$abilityScores['Cha'],
               alignment = x$Alignment,
               skills = x$skillProf %>% which %>% names %>% paste(collapse = '|'),
               weapons = x$weapons %>% map_chr('name') %>% gsub("\\|","",.)  %>% paste(collapse = '|'),
               spells = glue('{x$spells$name %>% gsub("\\\\*|\\\\|","",.)}*{x$spells$level}') %>% glue::collapse('|') %>% {if(length(.)!=1){return('')}else{return(.)}},
               day = x$date %>%  format('%m %d %y'),
               stringsAsFactors = FALSE)
}) %>% do.call(rbind,.)



# post processing -----
# the way races are encoded in the app is a little silly. sub-races are 
# not recorded separately. essentially race information is lost other
# than a text field after it's effects are applied during creation.
# The text field is also not too consistent. For instance if you are a 
# variant it'll simply say "Variant" but if you are a variant human
# it'll only say human
# here, I define regex that matches races.
# kind of an overkill as only few races actually required special care
races = c(Aarakocra = 'Aarakocra',
          Aasimar = 'Aasimar',
          Bugbear= 'Bugbear',
          Dragonborn = 'Dragonborn',
          Dwarf = 'Dwarf',
          Elf = '(?<!Half-)Elf',
          Firbolg = 'Firbolg',
          Genasi= 'Genasi',
          Gith = 'Geth',
          Gnome = 'Gnome',
          Goblin='Goblin',
          Goliath = 'Goliath',
          'Half-Elf' = '(Half-Elf)|(^Variant)',
          'Half-Orc' = 'Half-Orc',
          Halfling = 'Halfling',
          Hobgoblin = 'Hobgoblin',
          Human = 'Human',
          Kenku = 'Kenku',
          Kobold = 'Kobold',
          Lizardfolk = 'Lizardfolk',
          Orc = '(?<!Half-)Orc',
          'Yaun-Ti' = 'Serpentblood',
          Tabaxi = 'Tabaxi',
          Tiefling ='Tiefling|Lineage',
          Triton = 'Triton',
          Turtle = 'Turtle|Tortle')

align = list(NG = c('NG',
                    '"Good"',
                    "Neuteral Good",
                    "Neutral Good",
                    "Nuetral Goodt",
                    "Neutral/Good",
                    "Neutral good",
                    'neutral good',
                    'neutral-good',
                    'Neutral Good ',
                    'Nuetral Good',
                    'N/G'),
             CG = c('Chaotic Good',
                    'CG',
                    'Chacotic Good',
                    'Chaotic good',
                    'Good Chaotic',
                    'chaotic good',
                    'Chaotic Good '),
             LG = c('Lawful Good',
                    'Lawful Good ',
                    'L-G',
                    'LG',
                    'lawful good',
                    'Lawful good'),
             NN = c('Neutral',
                    'neutral ',
                    'Neutral ',
                    'n',
                    'N',
                    'True Neutral',
                    'True Neutral ',
                    'neutral',
                    'TN',
                    'Neutral Neutral',
                    'true neutral',
                    'Neutral neutral'),
             CN = c('Chaotic Neutral',
                    'CN',
                    'chaotic neutral',
                    'Chaotic neutral',
                    'chaotic nuetral',
                    'Chaotic Nuetral',
                    'cn',
                    'Chaotic Neutral ',
                    'neutral chaotic ',
                    'neutral chaotic'),
             LN = c('Lawful Neutral',
                    'lawful neutral ',
                    'Leal e Neutro',
                    'lawful - neutral',
                    'LN',
                    'Lawful Neutral (good-ish)',
                    'lawful neutral',
                    'lawful neutral'),
             NE = c('Neutral Evil'),
             LE = c('Lawful Evil','LE'),
             CE = c('CE','Chaotic Evil'))

goodEvil = list(`E` = c('NE','LE','CE'),
                `N` = c('LN','CN','NN'),
                `G` = c('NG','LG','CG'))

lawfulChaotic = list(`C` = c('CN','CG','CE'),
                     `N` = c('NG','NE','NN'),
                     `L` = c('LG','LE','LN'))

# lists any alignment text I'm not processing
charTable$alignment  %>% {.[!. %in% unlist(align)]} %>% table %>% sort %>% names

checkAlignment = function(x,legend){
    x = names(legend)[findInList(x,legend)]
    if(length(x) == 0){
        return('')
    } else{
        return(x)
    }
}


charTable %<>% mutate(processedAlignment = alignment %>% purrr::map_chr(checkAlignment,align),
                        good = processedAlignment %>% purrr::map_chr(checkAlignment,goodEvil) %>% 
                            factor(levels = c('E','N','G')),
                        lawful = processedAlignment %>% 
                            purrr::map_chr(checkAlignment,lawfulChaotic) %>% factor(levels = c('C','N','L'))) 

charTable %<>% mutate(processedRace = race %>% sapply(function(x){
    out = races %>% sapply(function(y){
        grepl(pattern = y, x,perl = TRUE,ignore.case = TRUE)
    }) %>% which %>% names
    
    if(length(out) == 0 | length(out)>1){
        out = ''
    }
    
    return(out)
}))

# remove personal info

shortestDigest = function(vector){
    digested  = vector %>% map_chr(digest,'sha1')
    uniqueDigested =  digested %>% unique 
    
    collusionLimit = 1:40 %>% sapply(function(i){
        substr(uniqueDigested,40-i,40)%>% unique %>% length
    }) %>% which.max %>% {.+1}
    
    digested %<>%  substr(40-collusionLimit,40)
}


charTable$name %<>% shortestDigest
charTable$ip %<>% shortestDigest
charTable$finger %<>% shortestDigest
charTable$hash %<>% shortestDigest

spells = wizaRd::spells

spells = c(spells, list('.' = list(level = as.integer(99))))
class(spells) = 'list'

legitSpells =spells %>% names


processedSpells = charTable$spells %>% sapply(function(x){
    if(x==''){
        return('')
    }
    spellNames = x %>% str_split('\\|') %>% {.[[1]]} %>% str_split('\\*') %>% map_chr(1)
    spellLevels =  x %>% str_split('\\|') %>% {.[[1]]} %>% str_split('\\*') %>% map_chr(2)
    
    distanceMatrix = adist(tolower(spellNames), tolower(legitSpells),costs = list(ins=2, del=2, sub=3), counts = TRUE)
    
    rownames(distanceMatrix) = spellNames
    colnames(distanceMatrix) = legitSpells
    
    predictedSpell = distanceMatrix %>% apply(1,which.min) %>% {legitSpells[.]}
    distanceScores =  distanceMatrix %>% apply(1,min) 
    predictedSpellLevel = spells[predictedSpell] %>% purrr::map_int('level')
    
    ins = attributes(distanceMatrix)$counts[,distanceMatrix %>% apply(1,which.min),'ins'] %>% as.matrix  %>% diag
    del = attributes(distanceMatrix)$counts[,distanceMatrix %>% apply(1,which.min),'del'] %>% as.matrix %>% diag
    sub = attributes(distanceMatrix)$counts[,distanceMatrix %>% apply(1,which.min),'sub'] %>% as.matrix %>% diag
    isItIn = predictedSpell %>% str_split(' |/') %>% map(function(x){
        x[!x %in% c('and','or','of','to','the')]
    }) %>% 
    {sapply(1:length(.),function(i){
        all(sapply(.[[i]],grepl,x =spellNames[i],ignore.case=TRUE))
    })}
    
    spellFrame = data.frame(spellNames,predictedSpell,spellLevels,predictedSpellLevel,distanceScores,ins,del,sub,isItIn,stringsAsFactors = FALSE)
    
    spellFrame %<>% filter(as.integer(spellLevels)==predictedSpellLevel &( isItIn | (sub < 5 & del < 5 & ins < 5)))
    
    paste0(spellFrame$predictedSpell,'*',spellFrame$predictedSpellLevel,collapse ='|')
})
charTable$processedSpells = processedSpells

# x = 1:nrow(charTable) %>% sapply(function(i){adist(charTable$spells[i],charTable$processedSpells[i])}) %>% {.>20} %>% {charTable$spells[.]} %>% {.[43]}
# x = 1:nrow(charTable) %>% sapply(function(i){adist(charTable$spells[i],charTable$processedSpells[i])}) %>% {.>20} %>% {charTable$spells[.]} %>% {.[70]}
# x = 1:nrow(charTable) %>% sapply(function(i){adist(charTable$spells[i],charTable$processedSpells[i])}) %>% {.>20} %>% {charTable$spells[.]} %>% {.[88]}

# download.file('https://www.dropbox.com/s/4f7zdx09nkfa9as/Core.xml?dl=1',destfile = 'Core.xml')
# allRules = xmlParse('Core.xml') %>% xmlToList()
# fightClubItems = allRules[names(allRules) == 'item']
# saveRDS(fightClubItems,'fightClubItems.rds')

# fightClubItems =  readRDS('fightClubItems.rds')
# names(fightClubItems) = allRules %>% map('name') %>% as.character
# 
# fightClubItems %>% map_chr('type') %>% {. %in% 'M'} %>% {fightClubItems[.]} %>% map_chr('name')
# fightClubItems %>% map_chr('type') %>% {. %in% 'R'} %>% {fightClubItems[.]} %>% map_chr('name')

legitWeapons = c(# fightClubItems %>% map_chr('type') %>% {. %in% 'M'} %>% {fightClubItems[.]} %>% map_chr('name'),
                 # fightClubItems %>% map_chr('type') %>% {. %in% 'R'} %>% {fightClubItems[.]} %>% map_chr('name'),
                 'Crossbow, Light', 'Dart', 'Shortbow', 'Sling',
                 'Blowgun', 'Crossbow, hand', 'Crossbow, Heavy', 'Longbow', 'Net',
                 'Club','Dagger','Greatclub','Handaxe','Javelin','Light hammer','Mace','Quarterstaff','Sickle','Spear','Unarmed Strike',
                 'Battleaxe','Flail','Glaive','Greataxe','Greatsword','Halberd','Lance','Longsword','Maul','Morningstar','Pike','Rapier','Scimitar','Shortsword','Trident','War pick','Warhammer','Whip')

processedWeapons = charTable$weapons %>% sapply(function(x){
    if(x==''){
        return('')
    }
    weaponNames = x %>% str_split('\\|') %>% {.[[1]]} 

    distanceMatrix = adist(tolower(weaponNames), tolower(legitWeapons),costs = list(ins=2, del=2, sub=3), counts = TRUE)
    
    rownames(distanceMatrix) = weaponNames
    colnames(distanceMatrix) = legitWeapons
    
    predictedWeapon = distanceMatrix %>% apply(1,which.min) %>% {legitWeapons[.]}
    distanceScores =  distanceMatrix %>% apply(1,min) 
    
    ins = attributes(distanceMatrix)$counts[,distanceMatrix %>% apply(1,which.min),'ins'] %>% as.matrix  %>% diag
    del = attributes(distanceMatrix)$counts[,distanceMatrix %>% apply(1,which.min),'del'] %>% as.matrix %>% diag
    sub = attributes(distanceMatrix)$counts[,distanceMatrix %>% apply(1,which.min),'sub'] %>% as.matrix %>% diag
    isItIn = predictedWeapon %>% str_split(' |/') %>% map(function(x){
        x[!x %in% c('and','or','of','to','the')]
    }) %>% 
    {sapply(1:length(.),function(i){
        all(sapply(.[[i]],grepl,x =weaponNames[i],ignore.case=TRUE))
    })}
    
    weaponFrame = data.frame(weaponNames,predictedWeapon,distanceScores,ins,del,sub,isItIn,stringsAsFactors = FALSE)
    
    weaponFrame %<>% filter(isItIn|  (sub < 2 & del < 2 & ins < 2))
    
    paste0(weaponFrame$predictedWeapon %>% unique,collapse ='|')
})

charTable$processedWeapons = processedWeapons

# x = 1:nrow(charTable) %>% sapply(function(i){adist(charTable$weapons[i],charTable$processedWeapons[i])}) %>% {.>20} %>% {charTable$weapons[.]} %>% {.[10]}

    
unsecureFields = c('ip','finger','hash')

charTable = charTable[!names(charTable) %in% unsecureFields]

# user id ------
# userID = c()
# pb = txtProgressBar(min = 0, max = nrow(charTable), initial = 0) 
# 
# for(i in 1:nrow(charTable)){
#     setTxtProgressBar(pb,i)
#     for (id in unique(userID)){
#         userChars = charTable[which(userID == id),]
#         ip = charTable$ip[i] %>% {if(is.na(.) || . =='NULL' || .==''){return("NANA")}else{.}}
#         finger = charTable$finger[i] %>% {if(is.na(.) || . =='NULL' ||. == ''){return("NANA")}else{.}}
#         hash = charTable$hash[i] %>% {if(is.na(.) || . =='NULL' || . == ''){return("NANA")}else{.}}
#         
#         ipInUser = ip %in% userChars$ip
#         fingerInUser = finger %in% userChars$finger
#         hashInUser = hash %in% userChars$hash
#         if(ipInUser | fingerInUser | hashInUser){
#             
#             userID = c(userID,id)
#             break
#         }
#         
#     }
#     
#     if(length(userID)!=i){
#         userID = c(userID, max(c(userID,0))+1)
#     }
# }
# 
# charTable$userID = userID
# 
# 
# userID = c()
# pb = txtProgressBar(min = 0, max = nrow(charTable), initial = 0) 
# 
# for(i in 1:nrow(charTable)){
#     setTxtProgressBar(pb,i)
#     for (id in unique(userID)){
#         userChars = charTable[which(userID == id),]
#         ip = charTable$ip[i] %>% {if(is.na(.) || . =='NULL' || .==''){return("NANA")}else{.}}
#         finger = charTable$finger[i] %>% {if(is.na(.) || . =='NULL' ||. == ''){return("NANA")}else{.}}
#         hash = charTable$hash[i] %>% {if(is.na(.) || . =='NULL' || . == ''){return("NANA")}else{.}}
#         
#         ipInUser = ip %in% userChars$ip
#         fingerInUser = finger %in% userChars$finger
#         hashInUser = hash %in% userChars$hash
#         if(fingerInUser | hashInUser){
#             
#             userID = c(userID,id)
#             break
#         }
#         
#     }
#     
#     if(length(userID)!=i){
#         userID = c(userID, max(c(userID,0))+1)
#     }
# }
# 
# charTable$userIDNoIP = userID
# 
write_tsv(charTable,path = 'docs/charTable.tsv')
# 
# # secure table -----
# 
# # not sure about the legality of this but I may be able to share 
# # the data in an anonymized form.
# 
# secureTable = charTable
# secureTable$ip %<>% sapply(function(x){
#     if(x %in% c('','NULL')){
#         return('')
#     } else{
#         digest(x,'sha1')
#     }
# })
# secureTable$finger %<>% sapply(function(x){
#     if(x %in% c('','NULL')){
#         return('')
#     } else{
#         digest(x,'sha1')
#     }
# })
# 
# secureTable$name %<>% sapply(digest,'sha1')
# write_tsv(secureTable,path = 'docs/hashedTable.tsv')

