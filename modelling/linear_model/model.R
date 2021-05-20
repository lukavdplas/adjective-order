library(dplyr)
library(ordinal)

#collect results from all experiments

result_paths = c("../../experiment/acceptability/results/results_filtered.csv",
                      "../../experiment/acceptability_with_semantic/results/results_filtered.csv",
                      "../../experiment/novel_objects/results/results_filtered.csv")

get_results = function(exp) {
  results = read.csv(result_paths[exp])
  
  #update participant to 101, 201, etc to distinguish experiments
  results$participant = sapply(results$participant, function(x){exp * 100 + x})
  
  #add experiment column
  results$experiment = rep(exp, nrow(results))
  
  results
}

all_results = full_join(full_join(get_results(1), get_results(2)), get_results(3))

#model

fit_model = function(data) {
  test_data = subset(data, item_type == "test")
  clmm(response ~ 
          order * condition + 
          order * adj_secondary_type + 
          (1 | participant), 
       test_data)
}

m_all = fit_model(all_results)
summary(m_all)

m_1 = fit_model(subset(all_results, experiment == 1))
summary(m_1)

m_2 = fit_model(subset(all_results, experiment == 2))
summary(m_2)

m_3 = fit_model(subset(all_results, experiment == 3))
summary(m_3)