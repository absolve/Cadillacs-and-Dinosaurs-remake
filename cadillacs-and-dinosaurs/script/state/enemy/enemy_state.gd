extends FightState
class_name EnemyState
## 敌人状态基类：把宿主转成 [Enemy]，AI 决策只读它的查询接口。


func foe() -> Enemy:
	return obj as Enemy
