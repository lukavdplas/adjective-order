# Materials data

Overview of some properties of experimental items that are useful in analysis.

## Stimuli items

Overview of the samples of TVs and couches that are presented to participants.

Columns:
* **index:** unique identifier of the item. The numerical index is identical to the one used in the results, but the string is shorter.
* **scenario:** which scenario this item belongs to, i.e. the object class of the item. Values are `tv` or `couch`.
* **size:** size in inches. For TVs this is described as the "size", and corresponds to the diagonal of the screen. For couches this is described as the "length", and corresponds to the length of the seat. (Couch sizes were given in feet + inches, but are converted to inches here.)
* **price:** price in dollars.
* **bimodal:** if the stimulus was included in the bimodal condition.
* **unimodal:** if the stimulus was included in the unimodal condition.

## Acceptability items

Overview of the acceptability judgement items.

Columns:
* **id:** unique identifier of the item. The same id string is used in the results.
* **adjectivestring:** the string of the adjective phrase for test items. This is a combination of two adjectives, in the order in which they appeared.
* **filler_acceptability:** filler items were classified as `acceptable` (expecting positive responses), `unacceptable` (expecting negative responses) or `questionable` (expecting mixed responses).
* **item_type:** if the items is a `test` or a `filler` item.
* **scenario:** scenario tied to that item. Values are `tv` and `couch`.
* **adj_target:** target adjective for test items. Values are `big` (only in the TV scenario), `long` (only in the couch scenario), and `expensive`.
* **adj_secondary:** the other adjective for test items.
* **adj_secondary_type:** classification of the secondary adjective for test items. Values are `scalar` and `absolute`.
* **order:** left-to-right order of adjectives in the test items. `first` means the target adjective came first, `second` means the target came second.