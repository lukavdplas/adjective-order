library(dplyr)
library(ordinal)

#collect results from all experiments

all_results = read.csv("../results/results_with_disagreement.csv")

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


complex_model = function(data) {
  test_data = subset(data, item_type == "test")
  clmm(response ~ 
          order * condition * confidence_on_semantic + 
          order * adj_secondary_type +
          (1 | participant), 
       test_data)
}

disagreement_model = function(data) {
  test_data = subset(data, item_type == "test")
  clmm(response ~ 
         order * disagreement_on_adj_target +
         order * adj_secondary_type +
         (1 | participant), 
       test_data)
}

m_all_disagreement = disagreement_model(all_results)
summary(m_all_disagreement)

# confidence rationgs

confidence_model = function(data) {
  confidence_data = subset(data, item_type == "confidence")
  clmm(response ~ 
         disagreement_on_adj_target +
         (1|participant),
       confidence_data) 
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