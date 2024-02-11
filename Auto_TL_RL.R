options(max.print = .Machine$integer.max) # Allow displaying more information (e.g., more cells of the matrix)

dir_SOP <- "data/dataSOP/"
dir_ATSP <- "data/dataATSP/"
dir_matrices <- "data/matrices/"
final_data_dir <- "data/finalDataWithLearning/"
root_dir <- "" # Path to the current directory
control_file_path <- paste(root_dir,"control.txt",sep = "")

setwd(paste(root_dir,dir_SOP,sep = ""))
print(dir())

file_sop <- readline("Choose a file from the SOP to read (no need for .txt): ")
sop_data_file <- paste(file_sop, ".txt", sep = "") # Concatenate the file name with the .txt extension

D_SOP <- read.table(sop_data_file, sep = "", header = F) # Reads the SOP instance 
N_SOP <- length(D_SOP)        # Number of nodes in the instance
R_SOP <- -D_SOP               # Reward function

already_exists_matrix <- FALSE
generated_matrix <- FALSE
error <- FALSE

option <- 1
line <- 0

e <- 0.01 # Greedy policy
num_ep <- 1000 # Number of episodes

# Option 1: Instance registered in the control file, but the Q matrix does not exist yet.
# Option 2: There are no instances of this size in the control file yet.
# Option 3: Empty or non-existent file.

if (file.exists(control_file_path) & file.size(control_file_path) > 0) {
  control <- read.table(control_file_path, header = F)
  if ((N_SOP-1) %in% control[,2]) {
    line <- match((N_SOP-1), control[,2])
    
    if (control[line, 3] == 1 && file.exists(paste(root_dir,dir_matrices,control[line, 4], sep = ""))) {
      setwd(paste(root_dir,dir_matrices,sep = ""))
      Q_TSP <- read.table(control[line, 4], sep = " ", header = F)
      already_exists_matrix <- TRUE
    } else if (control[line, 3] == 0) {
      option <- 1
    } else {
      print("Some information is incorrect, please check the control file and try again!")
      error <- TRUE
    }
  } else {
    option <- 2
    }
} else if (file.exists(control_file_path) & !(file.size(control_file_path) > 0)) {
  print("Empty file.")
  option <- 3
} else {
  file.create(control_file_path)
  option <- 3
}

# Part 1 - TSP
if (!already_exists_matrix && !error) {
  setwd(paste(root_dir,dir_ATSP,sep = ""))
  print(dir())
  
  tsp_file <- readline("Escolha um arquivo do ATSP para ler (não precisa do .txt): ")
  atsp_data_file <- paste(tsp_file, ".txt", sep = "") # Concatenate the file name with the .txt extension
  
  start_time <- Sys.time()

  D <- read.table(atsp_data_file, header = FALSE) # Reads the ATSP instance
  N <- length(D)        # Number of nodes in the instance
  R <- -D   # Reward function
  
  #------------------------------------------------------
  # Setting the Parameters
  alphas <- c(0.01, 0.15, 0.30, 0.45, 0.60, 0.75, 0.90, 0.99) # Learning rates
  gammas <- c(0.01, 0.15, 0.30, 0.45, 0.60, 0.75, 0.90, 0.99) # Discount factors

  epochs <- 5 
  final_data <- matrix(0, nrow = ((length(alphas)) * (length(gammas)) * (epochs)), ncol = 3)
  #------------------------------------------------------
  
  matrices_q <- array(dim=c(N, N, ((length(alphas)) * (length(gammas)) * (epochs))))
  
  sarsa <- function(alpha = 0.75, gamma = 0.15, q, num_ep = 1000) {
    count <- 1 # Episode counter
    So <- 1  # Initial State
    Ao <- 3 # Initial Action
    S <- So
    A <- Ao
    distance <- rep(0,num_ep) # Initializing the distance vector
    
    while (count<=(num_ep)) {
      distance[count] <- 0 # Initial distance is zero
      bag <- 1:N           # Available cities 
      bag[So] <- 0        # The initial city is accessed and marked as unavailable (assigned 0)
      for (i in 1:N) {      # Controls the visit to all cities
        bag[A] <- 0      # The destination city is accessed and marked as unavailable (assigned 0)
        remainder <- which(bag != 0) # Returns the index of the unvisited cities
        if (length(remainder) == 0) { # Checks if there are still cities to visit
          remainder <- So          # If there are none left: then return to the starting city
        }
        
        #--------------------------SARSA
        
        SS <- A     # The new state corresponds to the selected action
        remainder_Q <- q[SS,remainder] # remainder_Q receives values only from the Q matrix of the available cities
        biggest_Q <- which(remainder_Q == max(remainder_Q)) # Checks the index of the largest value in the Q Table - available cities
        AA <-remainder[biggest_Q[1]]   # The new action is the highest value in the Q Table - Available cities
        
        # Greedy Policy %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        remainder_size <- length(remainder)  # Size of the remainder: how many cities are available
        greedy <- runif(1,0,1)      # Generate a random number: [0, 1]
        if (greedy < e) {               
          index <- round(runif(1,1,remainder_size))  # Generate a random index according to the size of the remainder
          AA <- remainder[index]                    # New random action - only among the available (remainder)
        }
        
        #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        # SARSA Update
        q[S,A] <- q[S,A]+alpha*(R[S,A]+gamma*q[SS,AA]-q[S,A])
        
        #--------------
        S <- SS  # State Update
        A <- AA  # Action Update
        distance[count] <- distance[count]+D[S,A] # Update of the distance in the route for the episodes
      }
      count <- count +1 # Update of the episode counter
    }
    return(list("distances"=distance, "Q_matrix" = q))
  }
  
  overall_count <- 1
  for (alpha in alphas) { # Traverses the alpha vector
    for (gamma in gammas) { # Traverses the gamma vector
      for (ep in 1:epochs) { # Runs the defined number of epochs
        
        q <- matrix(0, N, N, T) # Learning matrix
        
        data <- sarsa(alpha, gamma, q, num_ep)
        distances <- data$distances
        matrices_q[,,overall_count] <- data$Q_matrix
        
        # Displays the smallest distance found in each combination
        cat('\nMenor custo: ', min(distances),"\n")
        
        final_data[overall_count, 1] <- alpha
        final_data[overall_count, 2] <- gamma
        final_data[overall_count, 3] <- min(distances)
        overall_count <- overall_count + 1
      }
    }
  }
  
  final_minimum_data <- which.min(final_data[, 3])
  
  write.table(data.frame(matrices_q[,,final_minimum_data]), paste(root_dir,dir_matrices,atsp_data_file, sep = ""), sep = " ", quote = F, row.names = F, col.names = F)
  
  if (option == 1) {
    control[line, 3] <- 1
    control[line, 4] <- atsp_data_file
    write.table(data.frame(control), control_file_path, sep = " ", quote = F, row.names = F, col.names = F)
  } 
  if (option == 2) {
    write.table(paste(tsp_file, N, 1, atsp_data_file, sep = " "), control_file_path, sep = " ", quote = F, append = T, row.names = F, col.names = F)
  } 
  if (option == 3) {
    write.table(paste(tsp_file, N, 1, atsp_data_file, sep = " "), control_file_path, sep = " ", quote = F, row.names = F, col.names = F)
  }
  Q_TSP <- matrices_q[,,final_minimum_data]
  generated_matrix <- TRUE
}

# Part 2 - SOP
if (already_exists_matrix || generated_matrix) {
  
  file_name <- paste(root_dir,final_data_dir,"dadosFinais_",file_sop,"_Q0",".txt",sep = "")
  if (already_exists_matrix) {
    start_time <- Sys.time()
    file_name <- paste(root_dir,final_data_dir,"dadosFinais_",file_sop,"_QATSP",".txt",sep = "")
  }
  
  write.table(paste('Instância:',file_sop,'\n',sep = ' '), file = file_name,quote = F, row.names = F,col.names = F)
  write.table(paste('--------------------------------------------------\n'), file = file_name,quote = F, append = T, row.names = F,col.names = F)
  if (already_exists_matrix) {
    write.table(paste('Já existia a matriz? Sim\n',sep = ' '), file = file_name,quote = F, row.names = F,col.names = F, append = T)
  } else {
    write.table(paste('Já existia a matriz? Não\n',sep = ' '), file = file_name,quote = F, row.names = F,col.names = F, append = T)
  }
  write.table(paste('--------------------------------------------------\n'), file = file_name,quote = F, append = T, row.names = F,col.names = F)

  final_alpha <- 0.75
  final_gamma <- 0.15
  epochs <- 10
  shortest_distances <- rep(0, epochs)
  
  # Action Selection - RLSOP - Function
  SOPAA <- function(Q,SS,AA,R,e,greedy,bag,D) {
    
    bag2 <- bag
    bag2[AA] <- 0 # bag2 stores the indices of the cities already visited and also cities that cannot be visited at the moment
    remainder2 <- which(bag2 != 0) # The variable remainder2 stores the cities that can still be selected
    
    ok <- 0 # Loop control
    while (ok == 0) { # It will only exit the loop when it verifies that AA can be visited or until it finds a location with no restrictions
      ok <- 1 # ok = 1 is the exit control
      t <- length(remainder2) # Size of remainder2
      if (t>0){           
        for (i in 1:t) { # Checks for the remaining set of cities if there are still precedence constraints for AA
          j <- remainder2[i]
          if (D[AA,j] == -1){ # If there is a precedence constraint, then ok = 0
            ok <- 0
          }
        }
      }
      if (ok == 0){ # There is a precedence constraint for the selected action
        t <- length(remainder2)  
        if(greedy < e){ # Selects a new action randomly
          index <- round(runif(1,1,t))
          AA <- remainder2[index]
        } else { # Selects the best estimated action in state SS
          
          remainder2_Q <- Q[SS,remainder2] # remainder2_Q receives values only from the Q matrix of the cities available in remainder2
          biggest2_Q <- which(remainder2_Q == max(remainder2_Q)) # Checks the index of the largest value in the Q Table - available cities
          AA <- remainder2[biggest2_Q[1]]   # The new action is the highest value in the Q Table - Available cities
        }
        bag2[AA] <- 0 # Removes action AA from the list
        remainder2 <- which(bag2 != 0) # Updates remainder2 only with the available cities
      }
    }
    
    return(AA) # Returns the Action Selected by SOPAA
  }# End Function - SOPAA
  
  sarsa_SOP <- function(alpha = 0.75, gamma = 0.15, q, num_ep = 1000) {
    count <- 1 # Episode counter
    So <- 1  # Initial State
    Ao <- 17 # Initial Action
    S <- So
    A <- Ao
    distance<-rep(0,num_ep) # Initializing the distance vector
    time_SOP_SEC<-rep(0,num_ep) # Initializing the time in seconds vector
    time_SOP_MIN<-rep(0,num_ep) # Initializing the time in minutes vector
    
    while (count <= (num_ep)) {
      time_SOP_SEC[count] <- 0
      time_SOP_MIN[count] <- 0
      distance[count] <- 0 # The initial distance is zero
      bag <- 1:N_SOP           # Available cities
      bag[So] <- 0            # The initial city is accessed and marked as unavailable (assigned 0)
      for (i in 1:N_SOP) {      # Controls the visit to all cities
        bag[A] <- 0      # The destination city is accessed and marked as unavailable (assigned 0)
        remainder <- which(bag != 0) # Returns the index of the unvisited cities
        if (length(remainder) == 0) { # Checks if there are still cities to visit
          remainder <- So          # If there are none left: then return to the starting city
        }
        
        #--------------------------SARSA
        
        SS <- A     # The new state corresponds to the selected action
        remainder_Q <- q[SS,remainder] # remainder_Q receives values only from the Q matrix of the available cities
        biggest_Q <- which(remainder_Q == max(remainder_Q)) # Checks the index of the largest value in the Q Table - available cities
        AA <- remainder[biggest_Q[1]]   # The new action is the highest value in the Q Table - Available cities
        
        # Greedy Policy %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        remainder_size <- length(remainder)  # Size of the remainder: how many cities are available
        greedy <- runif(1,0,1)      # Generate a random number: [0, 1]
        if(greedy < e){               
          index <- round(runif(1,1,remainder_size))  # Generate a random index according to the size of the remainder
          AA <- remainder[index]                    # New random action - only among the available (remainder)
        }
        
        #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        # Action Selection - RLSOP
        AA <- SOPAA(q,SS,AA,R_SOP,e,greedy,bag,D_SOP)
        
        # SARSA Update
        q[S,A] <- q[S,A]+alpha*(R_SOP[S,A]+gamma*q[SS,AA]-q[S,A])
        
        #--------------
        S <- SS  # State Update
        A <- AA  # Action Update
        
        if (D_SOP[S,A] == -1) { # Updates the distance only if it is not a precedence constraint
          distance[count] <- distance[count]
        } else {
          distance[count] <- distance[count]+D_SOP[S,A]
        }
      }
      time_SOP_SEC[count] <- difftime(Sys.time(), start_time, units = "secs")
      time_SOP_MIN[count] <- difftime(Sys.time(), start_time, units = "mins")
      count <- count +1 # Update of the episode counter
    }
    return(list("distances"=distance, "time_SOP_SEC" = time_SOP_SEC, "time_SOP_MIN" = time_SOP_MIN))
  }
  
  distances_SOP <- matrix(0, nrow = epochs, ncol = num_ep)
  times_SOP_SEC <- matrix(0, nrow = epochs, ncol = num_ep)
  times_SOP_MIN <- matrix(0, nrow = epochs, ncol = num_ep)
  q_sop_base <- matrix(0, N_SOP, N_SOP, T) # Base learning matrix
  
  for (i in 1:(N_SOP-1)) {
    for (j in 1:(N_SOP-1)) {
      q_sop_base[i,j] <- Q_TSP[i,j]
    }
  }
  
  for (ep in 1:epochs) { # Runs the defined number of epochs
    q_sop <- matrix(0, N_SOP, N_SOP, T) # Learning matrix
    q_sop <- q_sop_base
    
    data <- sarsa_SOP(final_alpha, final_gamma, q_sop, num_ep)
    distances_SOP[ep, ] <- data$distances
    times_SOP_SEC[ep, ] <- data$time_SOP_SEC
    times_SOP_MIN[ep, ] <- data$time_SOP_MIN
    shortest_distances[ep] <- min(distances_SOP[ep, ])
    cat("Época:", ep, "- Menor distância da época: ", min(distances_SOP[ep, ]), "\n")
    write.table(paste('Época: ',ep,' - Menor distância da época: ', min(distances_SOP[ep, ]),'\n',sep = ''), file = file_name,quote = F, append = T, row.names = F,col.names = F)
  }
  write.table(paste('--------------------------------------------------\n'), file = file_name,quote = F, append = T, row.names = F,col.names = F)
  index <- which.min(shortest_distances)
  distances <- distances_SOP[index,]

  end_time <- Sys.time()

  write.table(paste('Distância mínima: ', min(shortest_distances),'\n' , sep = ' '), file = file_name,quote = F, row.names = F,col.names = F, append = T)
  write.table(paste('Época com a menor distância:', index,'\n' , sep = ' '), file = file_name,quote = F, row.names = F,col.names = F, append = T)
  write.table(paste('Episódio da ',index,'° época com a menor distância: ', which.min(distances_SOP[index,]),'\n' , sep = ''), file = file_name,quote = F, row.names = F,col.names = F, append = T)
  write.table(paste('Tempo (em s) até atingir a menor distância:', times_SOP_SEC[index, which.min(distances_SOP[index, ])],'\n' , sep = ' '), file = file_name,quote = F, row.names = F,col.names = F, append = T)
  write.table(paste('Tempo (em min) até atingir a menor distância:', times_SOP_MIN[index, which.min(distances_SOP[index, ])],'\n' , sep = ' '), file = file_name,quote = F, row.names = F,col.names = F, append = T)
  write.table(paste('--------------------------------------------------\n'), file = file_name,quote = F, append = T, row.names = F,col.names = F)
  aux <- difftime(end_time, start_time, units = "secs")
  write.table(paste('Tempo de execução em segundos:',aux,'\n', sep = ' '), file = file_name,quote = F, append = T, row.names = F,col.names = F)
  aux <- difftime(end_time, start_time, units = "mins")
  write.table(paste('Tempo de execução em minutos:',aux,'\n', sep = ' '), file = file_name,quote = F, append = T, row.names = F,col.names = F)
  
  file_name <- paste(root_dir,final_data_dir,"grafico_",file_sop,"_Q0",'.pdf',sep = "")
  if(already_exists_matrix){
    file_name <- paste(root_dir,final_data_dir,"grafico_",file_sop,"_QATSP",'.pdf',sep = "")
  }
  pdf(file = file_name )

  # Plot the graph of Distance x Episode
  title <- paste("Distância x Episódio de", file_sop)
  subtitle <- paste("Menor distância: ", min(shortest_distances))
  plot(1:num_ep, distances,type = "l", sub = subtitle, xlab = "Episódio", ylab = "Distância", main = title , col="blue")

  dev.off()
}