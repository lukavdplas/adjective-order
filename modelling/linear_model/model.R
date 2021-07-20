library(dplyr)
library(ordinal)
i

#collect results from all experiments

all_results = read.csv("../results/results_with_disagreement.csv")
all_results$condition = factor(all_results$condition, levels = c("unimodal", "bimodal", "")) #change level order

#===============================================================================================
#acceptability judgements

condition_model = function(data) {
  #select test items
  test_data = subset(data, item_type == "test")
  
  #filter on scalar data
  #test_data = subset(test_data, adj_secondary_type == "scalar")
  
  #exclude big from experiment 3 based on semantic judgement results
  #test_data = subset(test_data, experiment == 2 | (experiment == 3 & adj_target == "long"))
  
  #model
  clmm(response ~ 
         order * condition + 
         order * adj_secondary_type + 
         (1 | participant), 
       test_data)
}

m_all = condition_model(all_results)
summary(m_all)


m_1 = condition_model(subset(all_results, experiment == 1))
summary(m_1)
m_2 = condition_model(subset(all_results, experiment == 2))
summary(m_2)
m_3 = condition_model(subset(all_results, experiment == 3))
summary(m_3)

confidence_model = function(data) {
  test_data = subset(data, item_type == "test" )
  clmm(response ~ 
          order * confidence_on_semantic +
          order * adj_secondary_type +
          (1 | participant), 
       test_data)
}

m_23 = confidence_model(subset(all_results, experiment == 2 | experiment == 3))
summary(m_23)

m_2 = confidence_model(subset(all_results, experiment == 2))
summary(m_2)

m_3 = confidence_model(subset(all_results, experiment == 3))
summary(m_3)

disagreement_model = function(data) {
  test_data = subset(data, item_type == "test")
  clmm(response ~ 
         order * disagreement_on_adj_target +
         order * adj_secondary_type +
         (1 | participant), 
       test_data)
}

m_23 = disagreement_model(subset(all_results, experiment == 2 | experiment == 3))
summary(m_23)

m_2 = disagreement_model(subset(all_results, experiment == 2))
summary(m_2)
m_3 = disagreement_model(subset(all_results, experiment == 3))
summary(m_3)


complex_model = function(data) {
  test_data = subset(data, item_type == "test" )
  clmm(response ~ 
         order * condition +
         order * confidence_on_semantic +
         (1 | participant), 
       test_data)
}

m_complex = complex_model(subset(all_results, experiment == 2 | experiment == 3))
summary(m_complex)

misc_model = function(data) {
  test_data = subset(data, item_type == "test" )
  clmm(response ~ 
         order * adj_secondary +
         (1 | participant), 
       test_data)
}

m_all = misc_model(all_results)
summary(m_all)


#===============================================================================================
# confidence ratings

confidence_model = function(data) {
  confidence_data = subset(data, item_type == "confidence")
  clmm(response ~ 
         disagreement_on_adj_target +
         (1 | participant),
       data = confidence_data) 
}

subdata = subset(all_results, experiment == 3)
for (p in unique(subdata$participant)) {
  participant_data = subset(subdata, participant == p & item_type == "confidence")
  if (length(unique(participant_data$response)) > 1) {

    model = confidence_model(participant_data)
    print(p)
    print(coef(model))
  }
}

bad_participants = c(303, 324, 310)
filtered_results = subset(all_results, !(participant %in% bad_participants))
m_confidence_all = confidence_model(subset(filtered_results, experiment ==3))
summary(m_confidence_all)


m_confidence_all = confidence_model(all_results)
summary(m_confidence_all)

m_confidence_2 = confidence_model(subset(all_results, experiment == 2))
summary(m_confidence_2)

m_confidence_3 = confidence_model(subset(all_results, experiment == 3))
summary(m_confidence_3)

ranef(m_confidence_3)


confidence_condition_model = function(data) {
  confidence_data = subset(data, item_type == "confidence" & adj_target != "expensive")
  clmm(response ~ 
         condition + (1|participant),
       data = confidence_data) 
}

m_confidence_condition_all = confidence_condition_model(all_results)
summary(m_confidence_condition_all)

m_confidence_condition_2 = confidence_condition_model(subset(all_results, experiment == 2))
summary(m_confidence_condition_2)

m_confidence_condition_3 = confidence_condition_model(subset(all_results, experiment == 3))
summary(m_confidence_condition_3)
