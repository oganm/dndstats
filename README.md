
DnD character statistics
========================

This is my experiment on doing some stats on DnD characters.

See [here](https://oganm.github.io/dndstats/) for the document


See [here](https://github.com/oganm/dndstats/blob/master/docs/index.Rmd) for the Rmd source code for the document.

The text of this document is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license

The code blocks within the source code is licensed under [MIT license](https://opensource.org/licenses/MIT).


## Data access

This dataset is present in 2 forms: in its entirety that includes duplicates
of characters and filtered version that only includes unique characters.

Go [here](docs/charTable.tsv) for the complete data and [here](docs/uniqueTable.tsv) for the filtered one. Both have
the same columns as explained below. The code to generate these tables can be found [here](https://github.com/oganm/dndstats/blob/master/dataProcess.R).

Below are the descriptions of the columns in the files. If you think something you'd be interested
in is missing, you can let me know.

**name:** This column has hashes that represent character names. If the hashes are
the same, that means the characters are the same. Real names are removed
to protect character anonymity. Yes D&D characters have rights.

**race:** This is the race field as it come out of the application. It is not really
helpful as subrace and race information all mixed up together and unevenly available.
It also includes some homebrew content. You probably want to use the **processedRace**
column if you are interested in this.

**background:** Background as it comes out of the application.

**date:** Time & date of input. Dates before 2018-04-16 are unreliable as some has accidentally changed
while moving files around.

**class:** Class and level. Different classes are separated by `|` when needed.

**justClass:** Class without level. Different classes are separated by `|` when needed.

**subclass:** Subclasses. Again, separated by `|` when needed.

**level:** Total character level.

**feats:** Feats chosen by character. Separated by `|` when needed.

**HP:** Character HP.

**AC:** Character AC.

**Str, Dex, Con, Int, Wis, Cha:** ability scores

**alignment:** Alignment free text field. It is a mess, don't touch it. See **processedAlignment**,**good** and **lawful** instead.

**skills:** List of skills with proficiency.  Separated by `|`.

**weapons:** List weapons. Separated by `|`. It is somewhat of a mess as it allows free text inputs. See **processedWeapons**.

**spells:** List of spells and their levels. Spells are separated by `|`s. Each spell has its level next to it
separated by `*`s. This is a huge mess as its a free text field and some users included things like damage dice in them. See **processedSpells**.

**day:** A shortened version of **date**. Only includes day information.

**processedAlignment:** Processed version of the **alignment** column. Way people wrote up their alignments are manually sifted through and assigned to the matching aligmment. First character represents lawfulness (L, N, C), second one goodness (G,N,E). An empty string means alignment wasn't written or unclear.

**good, lawful:** Isolated columns for goodness and lawfulness.

**processedRace:** I have gone through the way **race** column is filled by the app and asigned them to correct
races. If empty, indiciates a homebrew race not natively supported by the app.

**processedSpells:** Formatting is same as the **spells** column but it is cleaned up.  Using string similarity I tried
to match the spells to the full list of spells available in the official publications. The spell is removed if the spell I guessed does not have the correct level or doesn't include all words of the original spell and has too many modifications to be recognizable. It may have a few false matches but it should be mostly fine

**processedWeapons:** Similar to **processedSpells**, **weapons** column is matched to the closest official weapon with some restrictions.

**levelGroup:** splits levels into groups as used in the feat percentage plot. Only present in the filtered data
but easy enough to make on your own.