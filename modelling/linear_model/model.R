library(dplyr)
library(ordinal)

#collect results from all experiments

all_results = read.csv("../results/results_with_disagreement.csv")

#===============================================================================================
#acceptability judgements

simple_model = function(data) {
  test_data = subset(data, item_type == "test")
  clmm(response ~ 
         order * condition + 
         order * adj_secondary_type + 
         (1 | participant), 
       test_data)
}

m_all = simple_model(all_results)
summary(m_all)

confidence_model = function(data) {
  test_data = subset(data, item_type == "test")
  clmm(response ~ 
          order * confidence_on_semantic + 
          (1 | participant), 
       test_data)
}

m_all_confidence = confidence_model(subset(all_results, adj_secondary_type == "scalar" & experiment == 2))
summary(m_all_confidence)


disagreement_model = function(data) {
  test_data = subset(data, item_type == "test")
  clmm(response ~ 
         order * disagreement_on_adj_target +
         (1 | participant), 
       test_data)
}

m_all_disagreement = disagreement_model(subset(all_results, adj_secondary_type == "scalar" & experiment == 3))
summary(m_all_disagreement)

#===============================================================================================
# confidence ratings

confidence_model = function(data) {
  confidence_data = subset(data, item_type == "confidence")
  clmm(response ~ 
         disagreement_on_adj_target +
         (1|participant),
       data = confidence_data) 
}

m_confidence_2 = confidence_model(subset(all_results, experiment == 2))
summary(m_confidence_2)

m_confidence_3 = confidence_model(subset(all_results, experiment == 3))
summary(m_confidence_3)

confidence_condition_model = function(data) {
  confidence_data = subset(data, item_type == "confidence" & adj_target == "expensive")
  clmm(response ~ 
         condition +
         (1|participant),
       confidence_data) 
}

m_confidence_condition_2 = confidence_condition_model(subset(all_results, experiment == 2))
summary(m_confidence_condition_2)

m_confidence_condition_3 = confidence_condition_model(subset(all_results, experiment == 3))
summary(m_confidence_condition_3)