# Table of results

This directory contains the results for the second experiment. `results.csv` lists results for all participants, `results_filtered.csv` excludes participants with low scores on filler questions.

Columns in table:

* **participant:** unique index of the participant.
* **id:** unique indentifier of the item in the experiment.
* **response:** response given by participant for that item. For acceptability items, this is the value on a 5-point likert scale. (1 is "definitely sounds bad", 5 is "definitely sounds good".) Idem for confidence items. (1 is "very doubtful", 5 is "very confident".) For semantic items, the response is a boolean value: `true` means that that item was selected for the target adjective. Note that time items don't have a response, only a time.
* **time:** response time in seconds. Semantic and meta items don't have a recorded time as there were multiple items per page.
* **group:** experimental group that the participant was assigned to. Groups were assigned randomly, and determine the condition.
* **condition:** condition that the participant was assigned for this scenario. Values are `bimodal` or `unimodal`. (Empty if this did not apply, like the meta items.)
* **adjectivestring:** For acceptability test items. The string of the adjective phrase. This is a combination of two adjectives, in the order in which they appeared.
* **filler_acceptability:** For acceptability filler items. Filler items were classified as `acceptable` (expecting positive responses), `unacceptable` (expecting negative responses) or `questionable` (expecting mixed responses).
* **item_type:** general grouping of experiment items. Values are `test` (acceptability judgements, test items), `filler` (acceptability judgements, filler items), `semantic` (semantic judgements), `confidence` (confidence rating on semantic judgements), `meta` (demographic questions), and `time` (time measurements that are not tied to single item).
* **scenario:** scenario tied to that item, if applicable. Values are `tv` and `couch`.
* **adj_target:** target adjective, if applicable. Values are `big` (only in the TV scenario), `long` (only in the couch scenario), and `expensive`.
* **adj_secondary:** the other adjective in the acceptability items.
* **adj_secondary_type:** classification of the secondary adjective, if applicable. Values are `scalar` and `absolute`.
* **order:** left-to-right order of adjectives in the acceptability items. `first` means the target adjective came first, `second` means the target came second.
* **stimulus_size:** for semantic items, gives the size (in inches) of that stimulus. For TVs, this is the size (corresponds to "big"); for couches, this is the length (corresponds to "long").
* **stimulus_price:** for semantic items, gives the price (in dollars) of that stimulus (corresponds to "expensive").