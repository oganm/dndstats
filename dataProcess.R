library(import5eChar)
library(purrr)
library(readr)
library(glue)
library(digest)
library(XML)
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
               Str = x$abilityMods['Str'],
               Dex = x$abilityMods['Dex'],
               Con = x$abilityMods['Con'],
               Int = x$abilityMods['Int'],
               Wis = x$abilityMods['Wis'],
               Cha = x$abilityMods['Cha'],
               alignment = x$Alignment,
               skills = x$skillProf %>% which %>% names %>% paste(collapse = '|'),
               weapons = x$weapons %>% map_chr('name') %>% gsub("\\|","",.)  %>% paste(collapse = '|'),
               spells = glue('{x$spells$name %>% gsub("*|\\\\|","",.)}*{x$spells$level}') %>% glue::collapse('|') %>% {if(length(.)!=1){return('')}else{return(.)}},
               day = x$date %>%  format('%m %d'),
               stringsAsFactors = FALSE)
}) %>% do.call(rbind,.)





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

