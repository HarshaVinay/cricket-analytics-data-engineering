# Feed Specification

Teams: team master records.
Players: player master records.
Matches: match-level records.
Deliveries: ball-level records.

Expected landing paths: teams/, players/, matches/, deliveries/.

Bad files are quarantined. Schema drift is rejected/quarantined and handled through a versioned feed contract.
