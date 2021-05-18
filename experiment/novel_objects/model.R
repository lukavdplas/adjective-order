library(ordinal)

results = read.csv("results/results_filtered.csv")


test_results = subset(results, item_type == "test")


#all adjectives

m_all <- clmm(response ~ 
                order * confidence_on_semantic * condition + 
                order * adj_target * adj_secondary_type + 
                (1 | participant), 
              test_results)

summary(m_all)

#scalar adjectives

scalar_results = subset(test_results, adj_secondary_type == "scalar")

m_scalar <- clmm(response ~ 
                   order * condition  +
                   order * adj_target +
                   (1 | participant), 
                 data = scalar_results)
summary(m_scalar)

m_scalar_confidence <- clmm(response ~s
                              order * condition * confidence_on_semantic + 
                              order * adj_target +
                              (1 | participant), data = scalar_results)
summary(m_scalar_confidence)

#absolute adjectives

absolute_results = subset(test_results, adj_secondary_type == "absolute")

m_absolute <- clmm(response ~ order * condition  + (1 | participant), data = absolute_results)
summary(m_absolute)

m_absolute_confidence <- clmm(response ~ order * confidence_on_semantic *condition  + (1 | participant), data = absolute_results)
summary(m_absolute_confidence)
