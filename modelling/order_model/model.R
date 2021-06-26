library(dplyr)
library(ordinal)

#collect results from all experiments

all_results = read.csv("../results/relative_judgements.csv")
all_results$condition = factor(all_results$condition, levels = c("unimodal", "bimodal", "")) #change level order
all_results$preference_for_first_order = as.factor(all_results$preference_for_first_order) #change to factor

#===============================================================================================
#acceptability judgements

model = function(data) {
  clmm(preference_for_first_order ~ 
         adj_secondary_type +
         (1 | participant),
       data = data)
}

model_subjectivity = function(data) {
  clmm(preference_for_first_order ~ 
         relative_subjectivity + 
         (1 | participant),
       data = data)
}


filtered_results = subset(all_results, !is.na(all_results$relative_subjectivity))

m1 = model(filtered_results)
m2 = model_subjectivity(filtered_results)

summary(m1)
summary(m2)

anova(m1, m2)


best_model = function(data) {
  clmm(preference_for_first_order ~ 
         adj_target + 
         adj_secondary +
         (1 | participant),
       data = data)
}

m3 = best_model(filtered_results)
summary(m3)
summary(best_model(all_results))

anova(m1, m3)
