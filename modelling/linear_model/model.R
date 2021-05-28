library(dplyr)
library(ordinal)

#collect results from all experiments

all_results = read.csv("../results/results_with_disagreement.csv")

#model

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

#subset by adjective


m_1 = simple_model(subset(all_results, experiment == 1))
summary(m_1)

m_2 = simple_model(subset(all_results, experiment == 2))
summary(m_2)

m_3 = simple_model(subset(all_results, experiment == 3))
summary(m_3)