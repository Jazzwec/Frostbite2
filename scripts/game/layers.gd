class_name Layers
extends RefCounted
## Physics layer bits.

## The snowfield the navmesh is baked from.
const GROUND := 1
## Building footprints: block walking and are cut out of the navmesh.
const OBSTACLE := 2
## Things you can tap: plots, buildings, resource spots, frozen Jans.
const TAPPABLE := 4
