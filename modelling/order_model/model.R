library(dplyr)
library(ordinal)

#collect results from all experiments

all_results = read.csv("../results/relative_judgements.csv")
all_results$condition = factor(all_results$condition, levels = c("unimodal", "bimodal", "")) #change level order
all_results$preference_for_first_order = as.factor(all_results$preference_for_first_order) #change to factor

#===============================================================================================
#preference scores

m_secondary_type = clmm(preference_for_first_order ~ 
                                   adj_secondary_type +
                                   (1 | participant),
                                 data = all_results)
summary(m_secondary_type)

filtered_results = subset(all_results, !is.na(all_results$relative_subjectivity))

m_secondary_type_filtered = clmm(preference_for_first_order ~ 
            adj_secondary_type +
            (1 | participant),
          data = filtered_results)
summary(m_secondary_type_filtered)

m_subjectivity = clmm(preference_for_first_order ~ 
         relative_subjectivity + 
         (1 | participant),
    data = filtered_results)
summary(m_subjectivity)

anova(m_secondary_type, m_subjectivity)

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

anova(m3, m_subjectivity)

corpus_model = function(data) {
  clmm(preference_for_first_order ~ 
         corpus_preference +
         (1 | participant),
       data = data)
}

with_corpus_data = subset(all_results, !is.na(all_results$corpus_preference))

m_corpus = corpus_model(with_corpus_data)
summary(m_corpus)

summary(best_model(with_corpus_data))