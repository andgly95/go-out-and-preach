extends Resource
class_name Habit
## One node of the habits tree (docs/design/v01-loop.md § Habits). A habit
## forms from practice, the days spent doing the thing, never from points.
## Step 1 of a track forms by itself; step 2 is a fork: two habits share
## the track and step, the player keeps one, and the other closes for the
## run. Habits on the "lately" track form from doubt instead of practice and
## stay out of sight until doubt first reaches 40.
## Authored as .tres in data/habits/ and read by the Habits autoload.

@export var id: StringName
## &"ministry", &"study", &"congregation", &"home", or &"lately".
@export var track: StringName
## 1 = forms by itself; 2 = one side of the track's fork.
@export var step: int = 1
## Position within the fork (0 left, 1 right) or among the lately habits.
@export var order: int = 0
@export var title: String = ""
## The quiet line: who you are becoming. {tokens} are filled by GameState.fill.
@export var flavor: String = ""
## What it does, plainly. Shown under the flavor.
@export var effect_text: String = ""
## Practice on the track needed before it forms (or before the fork is offered).
@export var practice: int = 0
## Lately habits only: forms once doubt reaches this.
@export var min_doubt: int = 0
## Named adjustments read by the systems through Habits.modifier(key). Keys:
##   energy:<activity or meeting id>   added to that energy cost
##   service_morning_energy, service_extension_energy
##   return_visit_stops, study_stops    added to a stop's cost
##   conviction:<activity id>, relief:<activity id>
##   conviction_wear                    added to DoubtMeter's wear per exposure
##   gate_offset                        added to doubt for greyed-out choices
##   family_loss                        taken off each family standing loss
##   comment_elders                     added to a prepared comment's elders standing
##   skip_energy                        energy restored by staying home from a meeting
@export var modifiers: Dictionary = {}
