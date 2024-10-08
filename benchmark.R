library(bench)
library(tidyverse)

# Define the number of iterations
iterations <- 5


# Load functions from local scripts
source("f_model.R")
source("f_model_df_conversion.R")
source("f_model_matrix.R")

#### General ####
v_states <- c("Gezond", "Ziek", "Dood") #  vector of model health states
n_states <- length(v_states) # number of health states 
v_treatments <- c("Current_practice", "New_treatment") # vector of strategy names
n_treatments <- length(v_treatments)  # number of treatments
n_t <- 100 # model time horizon 
n_sim <- 5 #0 # number of Monte-carlo simulations for probabilistic analyses
set.seed(12345) # set seed

#### Model inputs #### 
df_input <- data.frame( # open input parameter dataframe
  # transition probabilities 
  p_gezond_ziek = rbeta(n = n_sim, shape1 = 10, shape2 = 20), 
  p_gezond_dood = rbeta(n = n_sim, shape1 = 1, shape2 = 20), 
  p_ziek_gezond = rbeta(n = n_sim, shape1 = 5, shape2 = 20), 
  p_ziek_dood = rbeta(n = n_sim, shape1 = 10, shape2 = 20),
  # relative risk (difference between treatments)
  rr_gezond_ziek_t2_t1 = rlnorm(n = n_sim, meanlog = log(0.8), sdlog = 0.2),
  # health state utility (quality of life)
  u_gezond = rbeta(n = n_sim, shape1 = 75, shape2 = 100), 
  u_ziek = rbeta(n = n_sim, shape1 = 60, shape2 = 100), 
  u_dood = rep(x = 0, times = n_sim),
  # health state costs
  c_gezond = rgamma(n = n_sim, shape = 75, scale = 100), 
  c_ziek = rgamma(n = n_sim, shape = 100, scale = 100), 
  c_dood = rep(x = 0, times = n_sim)
) # close input parameter dataframe

#### Create matrix to store results #### 
m_out_1a <- m_out_2a <- m_out_3a <- m_out_4a <- m_out_1b <- m_out_2b <- m_out_3b <- m_out_4b <- m_out_1c <- m_out_2c <- m_out_3c <- m_out_4c <- matrix( 
  data = NA, 
  nrow = n_sim, 
  ncol = 4,
  dimnames = list(1:n_sim, c(paste0("Cost_", v_treatments), paste0("QALY_", v_treatments))) 
) # end matrix



# Benchmark each approach
benchmark_results <- bench::mark(
  approach1a = source(here::here("approach1a.R")),
  approach1b = source(here::here("approach1b.R")),
  iterations = iterations
)

# qualitative scores

v_qual_scores_rater1 <- c(5, 3)
v_qual_scores_rater2 <- c(4, 3)

v_qual_score_mean <- (v_qual_scores_rater1 + v_qual_scores_rater2) / 2

benchmark_results$qual_mean <- v_qual_score_mean

# weights
w1 <- 0.3
w2 <- 0.3
w3 <- 1-sum(w1, w2)

# overall score

benchmark_results$overall_score <- w1 * as.numeric(benchmark_results$total_time) +
  w2 * as.numeric(benchmark_results$mem_alloc) + w3 * as.numeric(benchmark_results$qual_mean)


