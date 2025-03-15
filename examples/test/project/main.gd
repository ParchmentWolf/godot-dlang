extends Node

var anotherSignalOk: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	# var t: TestD = TestD.new()
	# t.write_stuff()
	# $Panel/Label.set_text(str(t.writeStuffInt(42)))
	# t.test()
	# t._ready()
	# print("using static method: ", TestD.get_some_number())
	# print("int in variant: ", TestD.get_number_as_variant())
	
	var base = SomeConcreteClass.new() as SomeBaseClass
	
	# 'is' keyword should be able to handle inheritance, 
	# but base.get_class() will actually return SomeConcreteClass here
	# Object.is_class('name of class') will work just like 'is' though
	assert(base.is_class("SomeBaseClass"))
	assert(base is SomeBaseClass) 
	base.do_something()
	assert(base.foo == 42, "do_something expected to set base.foo, did you broke virtual call resolution?")
	
	# since this is an Object it is up to you to release it when you've done with it
	# don't forget to free it when it is no longer in use
	base.free()

	# TestD class extends Label which is attached to panel, weird but ok
	var test_class = $Panel/Label as TestD
	assert(test_class, "TestD object is null: something wrong with node layout or bindings")
	
	# Test typed array (added in 4.2)
	if Engine.get_version_info().hex >= 0x040200:
		var arr = test_class.get_typed_array()
		assert(arr[1] == 7)
	
	# Test typed dictionary (added in 4.4)
	if Engine.get_version_info().hex >= 0x040400:
		var dict = test_class.get_typed_dict()
		assert(dict[42] == "Hello", "TypedDictionary[42] == Hello: failed")
	
	# Virtual functions test for Godot 4.3+
	if Engine.get_version_info().hex >= 0x040300:
		var virt = TestVirtualScript.new()
		virt.test()
		virt.free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_label_send_message(arg0):
	print("send_message received: ", arg0)
	$Panel/Label/One/Looooong/Incredibly/Unbroken/Node/Path/Label2.set_text(arg0)


func _on_label_another_signal(v):
	assert(v == 42)
	print("another signal called with value: ", v)
	anotherSignalOk = true

func _exit_tree():
	assert(anotherSignalOk, "another signal was never called")
