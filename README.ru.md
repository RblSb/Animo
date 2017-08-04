## Animo 0.1

Animo - редактор для создания скелетных анимаций. Генерирует формат файла, который содержит в себе скелет (массивы линий и точек), а также массив кадров анимации, содержащий в себе углы линий скелета.

[Онлайн-версия](http://mssite.org/projects/Animo/)

Редактор разделен на 2 режима - редактирование и анимация.
### Управление в режиме редактирования:
* ЛКМ клик - создать точку
* ЛКМ нажатие + перетаскивание - создать линию (+2 точки, если нужны)
* ПКМ клик - удалить точку
* ПКМ нажатие на точку + перетаскивание - переместить линию

### Управление в режиме анимации:
* ЛКМ нажатие на точку + перетаскивание - изменяет угол наклона линии

### Общие клавиши:
* Ctrl-Z - шаг назад (отмена действия)
* Shift-Ctrl-Z / Ctrl-Y - шаг вперед (возврат)
* Ctrl-S - сохранить файл
* O / HTML5 Drag&Drop - открыть файл
* N - создать новый скелет
* G - вкл/выкл сетку
* T - сменить цветовую тему редактора

* Ctrl-Вверх - создать кадр
* Ctrl-Вниз - удалить кадр
* Ctrl-Влево - пред. кадр
* Ctrl-Вправо - след. кадр
* Enter/Space - вкл/выкл проигрывание кадров
* Shift-Enter - проиграть один раз
* Alt-Enter - записать Gif
* 1 - масштаб 1x
* 2 - масштаб 2x
* 0 - ориг. масштаб (10x)
* \- / NUM- - Уменьшить
* \+ / NUM+ - Увеличить
* Shift-(- / +) - быстрое масштабирование

### Формат скелета:

```haxe
typedef Basis = { //Скелет
	v:Int, //версия
	?width:Int, //размеры холста
	?height:Int,
	?name:String, //название cкелета
	?delay:Int, //задержка в кадрах между фреймами анимаций
	points:Array<Point>, //точки скелета
	edges:Array<Edge>, //линии скелета
	?frames:Array<Frame> //кадры анимации
}

typedef Point = { //Точка
	?x:Float,
	?y:Float,
	?edges: Array<Int>, //иды прикрепленных линий
	?d: Int //глубина (для анимирования)
}

typedef Edge = { //Линия
	?ang:Float, //угол наклона (для анимирования)
	?min:Float, //минимальный угол (для анимирования)
	?max:Float, //максимальный угол (для анимирования)
	?p1:Int, //точка 1
	?p2:Int //точка 2
}

typedef Frame = { //Точка
	?edges:Array<Edge> //модифицированные линии
}
```