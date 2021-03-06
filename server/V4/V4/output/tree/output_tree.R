output_tree <- new.env()

### addTree : ajouter l'ui (tree) à l'interface
## boolprevious : si NULL l'element est placé en tout dernier (append)
# si pas null (n'importe quoi, meme False attention !) alors l'element est placé en tout premier (prepend)
# div : le div 
output_tree$addTree <- function(event){
  div_treeboutton <- fonctions_tree$new_treeboutton(event) ## création de l'UI
  output$creationPool_tree <- renderUI({div_treeboutton})
  ## création de l'UI mais pas de bouton display pour les bouttons suivants : 
  # boutton remove de l'event 0
  # bouttons previous ou bouttons next pour les events suivants et précédents respectivement :
  # ce display est retiré par une fonction JS appelé avec moveTree
}

## ploter le tree dans un treeboutton : ajout du contenu du tree
output_tree$make_tree_in_treeboutton <- function(event,hierarchy){
  output[[event$get_treeid()]] <- renderTree({
    fonctions_tree$get_hierarchylistN(hierarchyliste = hierarchy, lowestlevel_vector =  event$get_type())
  })
}

#### tous les évènements possibles avec treeboutton
output_tree$add_observers_treeboutton <- function(event, jslink){
  
  ### lorsque l'utilisateur clique sur validate
  observeEvent(input[[event$get_validateid()]],{
    cat("Le boutton", event$get_validateid(), "a été cliqué \n")
    treenumber <- event$get_treeid()
    selection <- unlist(get_selected(input[[treenumber]]))
    if (is.null(selection)){
      cat("\t",treenumber , " : aucun élément sélectionné pour valider.")
      return(NULL)
    }

    if (length(selection) > 1){
      cat("\t",treenumber , " : plus de 2 éléments sélectionnés")
      return(NULL)
    }
    
    #### On n'a pas le droit de sélectionner s'il y a aucun event : 0 ou pas de parenthèse()
    Nselection <- sapply(selection, function(x) str_extract(x, pattern="[(][0-9]+[)]"))
    Nselection <- gsub("[()]","",Nselection)
    boolNselection <- sapply(Nselection, function(x) {is.na(x) || as.numeric(x)==0})
    if (all(boolNselection)){
      cat("\t",treenumber , " : tous les events sélectionnés ont 0 instances. \n")
      return(NULL)
    }
    
    ## retire tous les treeboutton avant ou après
    
    cat("\t values : ", get_event_numbers(values),"\n")
    removeEvents(values, event$get_event_number())
    cat("\t values : ", get_event_numbers(values),"\n")
    
    #remove_treebutton(treebouttonvalue = event$get_event_number, boolitself = NULL)
    #remove ### retirer les values aussi
    
    choix <- sapply(selection, function(x) gsub("[(][0-9]+[)]", "",x)) ### retirer les nombres entre parenthèses
    
    
    df_type_selected <- fonctions_tree$get_df_type_selected(hierarchy, choix)
    
    ## séparément le cas où un filtre (et donc un tabset) existe déjà : il faut updater
    # ou le cas où le filtre n'existe pas encore : il faut créer (tabset ...)
    bool <- length(event$filtres) > 0
    
    #print (df_type_selected)
    event$filtres <- list()
    event$set_df_type_selected(df_type_selected) ## création du filtre à cette étape
    cat ("\t création d'un filtre pour l'event ", event$get_event_number(), "\n")
    
    if (!bool){
      for (i in 1:length(event$filtres)){
        # cat(length(event$filtres))
        tabpanel <- list(fonctions_tabpanel$new_tabpanel(event$filtres[[i]]))
        fonctions_tabpanel$addTabToTabset(tabpanel)
        jslink$moveTabpanel(event_number = event$filtres[[i]]$tabsetid, tabsetName = "mainTabset") ## modif de place
        fonctions_tabpanel$make_tableau(event$filtres[[i]])
        fonctions_tabpanel$addplots_tabpanel(event$filtres[[i]])
        fonctions_tabpanel$make_plots_in_tabpanel(event$filtres[[i]])
        fonctions_tabpanel$add_observers_tabpanel(event$filtres[[i]])
      }
    } else {
      for (i in 1:length(event$filtres)){
        updateCheckboxGroupInput(session, event$filtres[[i]]$get_checkboxid(), 
                                 choices = event$filtres[[i]]$metadf$colonnes_tableau,
                                 selected = NULL, inline=T)
        fonctions_tabpanel$make_tableau(event$filtres[[i]])
        fonctions_tabpanel$addplots_tabpanel(event$filtres[[i]])
        fonctions_tabpanel$make_plots_in_tabpanel(event$filtres[[i]])
        fonctions_tabpanel$add_observers_tabpanel(event$filtres[[i]])
      }
    }
    
  }) ## fin observe event validate
  
  ### Ce qui se passe quand l'utilisateur clique sur remove :
  observeEvent(input[[event$get_removeid()]],{
    ## l'event 0 ne peut être cliqué car j'ai retiré le boutton !
    cat("Le boutton", event$get_removeid(), "a été cliqué \n")
    cat("\t values : ", get_event_numbers(values),"\n")
    removeEvents(values, event$get_event_number(),boolitself = T)
    cat("\t values : ", get_event_numbers(values),"\n")
  })
  #### quand je clic sur previous 
  ## 1) vérifier que l'utilisateur a réalisé une sélection
  ## 2) vérifier qu'un event previous n'existe pas déjà 
  ## 3) créer un event previous si les conditions plus haut sont réunis
  observeEvent(input[[event$get_addpreviousid()]], {
    cat("Le boutton", event$get_addpreviousid(), "a été cliqué \n")
    
    ## 1) 
    if (is.null(event$get_type_selected())){
      cat ("\t event", event$get_event_number(), "Aucun évènement sélectionné/validé \n")
      return(NULL)
    }
    
    ## 2) 
    event_numbers <- get_event_numbers(values)
    bool <- event$get_event_number() <= event_numbers ## il n'existe pas d'event plus petit que lui
    if (!all(bool)){
      cat ("\t event", event$get_event_number(), " : un event précédent existe déjà \n ")
      return(NULL)
    }
    
    ## 3) 
    id_treebutton <<- id_treebutton + 1 ## on incrémente
    n <- - id_treebutton ## signe négatif car previous

    ## calculer le previous : 
    event$set_df_nextprevious_events(boolnext=F) ## calcule les events précédents
    
    previousevent <- new("Event",df_events = event$df_previous_events,event_number=n)
    
    values[[paste0("selection",n)]]$event <<- previousevent
    cat("\t values : ", get_event_numbers(values),"\n")
    
    output_tree$addTree(previousevent)
    jslink$moveTree (previousevent$get_treebouttonid(), boolprevious=T)
    output_tree$make_tree_in_treeboutton(previousevent, hierarchy)
    output_tree$add_observers_treeboutton(previousevent,jslink)
    jslink$hide_boutton(previousevent)
    cat ("\t event",previousevent$get_event_number(), " créé ! \n ")
  }) ### fin ObserveEvent addprevious
  
  ## meme chose pour next event : voir algo pour previous
  observeEvent(input[[event$get_addnextid()]], {
    cat("Le boutton", event$get_addnextid(), "a été cliqué \n")
    
    ## 1) 
    if (is.null(event$get_type_selected())){
      cat ("\t event", event$get_event_number(), "Aucun évènement sélectionné/validé \n")
      return(NULL)
    }
    
    ## 2) 
    event_numbers <- get_event_numbers(values)
    bool <- event$get_event_number() >= event_numbers ## il n'existe pas d'event plus grand que lui
    if (!all(bool)){
      cat ("\t event", event$get_event_number(), " : un event suivant existe déjà \n ")
      return(NULL)
    }
    
    ## 3) 
    id_treebutton <<- id_treebutton + 1 ## on incrémente
    n <- id_treebutton ## signe négatif car previous
    boolprevious <- F
    ##  nextevent : 
    event$set_df_nextprevious_events(!boolprevious) ## calcule les events suivants
    
    nextevent <- new("Event",df_events = event$df_next_events,event_number=n)
    
    values[[paste0("selection",n)]]$event <<- nextevent
    cat("\t values : ", get_event_numbers(values),"\n")
    
    output_tree$addTree(nextevent)
    jslink$moveTree (nextevent$get_treebouttonid(), boolprevious=NULL)
    output_tree$make_tree_in_treeboutton(nextevent, hierarchy)
    output_tree$add_observers_treeboutton(nextevent,jslink)
    jslink$hide_boutton(nextevent)
    cat ("\t event",nextevent$get_event_number(), " créé ! \n ")
  }) ### fin ObserveEvent next
  
} # fin add_observers_treeboutton
