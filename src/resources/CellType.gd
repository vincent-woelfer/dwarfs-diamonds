extends Resource
class_name CellType

enum Type {
	A,
	B,
	C,
	BUILDING,
	SKY
}

@export var type: Type
@export var mining_cost: float
@export var color: Color
