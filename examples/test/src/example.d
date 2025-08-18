import godot.abi;

import godot;
import godot.api.types;
import godot.string;
import godot.variant;
import godot.vector2;
import godot.array;

import core.runtime;
import std.stdio;
import std.conv;
import std.string : toStringz, fromStringz;
import core.stdc.string;
import std.algorithm.iteration;
import std.meta;

//import godot.control.all;
import godot.colorrect;
import godot.label;
import godot.control;
import godot.resource;
import godot.node;
import godot.refcounted;

// hacky hack due to lack of phobos
version(Emscripten) {
    import core.stdc.stdio;

    void writefln(Args...)(string s, Args args) {
        //printf(s.ptr, args);
    }

    void writefln(Args...)(wstring s, Args args) {
        //printf(s.ptr, args);
    }

    void writef(Args...)(Args args) {
        // noop
    }

    void write(string s) {
        // better not do this, it is unsafe and all
        //puts(s.ptr);
    }
}


@Rename("TestD")
class Test : GodotScript!Label {
    /++
	Simulate OOP inheritance and polymorphism with implicit conversion to Label
	+/
    version (USE_CLASSES) {
        // nothing to do
    }
    else {
        // note that this is done implicitly in GodotScript wrapper, but you can do that explicitly
        alias _godot_base this;
    }

    @Enum enum Flag {
        DEFAULT,
        WITH_VALUE = 5,
        MAX
    }

    @Constant enum ANSWER = 42;
    @Constant enum BAR = -1;

    private String _prop;
    @Property @DefaultValue!"testDefaultValue" String property() const {
        return _prop ~ String(" ~ hello from the getter!");
    }

    @Property
    void property(in String v) {
        _prop = v ~ String(" ~ hello from the setter!");
    }

    private long _num = 5;
    @Property
    long number() const {
        return _num + 1;
    }

    @Property
    void number(long v) {
        _num = v + 1;
    }

    @Property {
        float freal = 1.5;
        double dreal = 0.25;
    }

    @Property void onlySetter(int value) {
        print("onlySetter: ", value);
    }

    @Property int onlyGetter() const {
        return 1234;
    }

    // Some variables demonstrating OnReady, assigned right before _ready():

    // string -> Node: assign the variable to the specified path using get_node
    @OnReady!"ColorRect" ColorRect colorRect;

    // lambda: call it, assign return value to the variable
    @OnReady!(() { print("In OnReady of onReadyInt"); return 99; })
    int onReadyInt;

    //@Property 
    NodePath _longNodePath; // = NodePath("One/Looooong/Incredibly/Unbroken/Node/Path/Label"); // should be set from edtior
    @Property void longNodePath(NodePath value) {
        _longNodePath = value;
        print(value);
    }

    @Property NodePath longNodePath() const {
        return _longNodePath;
    }

    String _myStr;
    @Property void myStr(String value) {
        _myStr = value;
    }

    @Property String myStr() const {
        return _myStr;
    }

    // another variable in this class: use it instead of some compile-time value
    @OnReady!_longNodePath Label longNode;

    this() {
        //_prop = String("testDefaultValue");
        //_longNodePath = NodePath("One/Looooong/Incredibly/Unbroken/Node/Path/Label"); 
    }

    @(godot.Method)  // fully qualified name, in case you have another "Method" in the module
    void writeStuff() {
        writeln("Writing stuff...");
    }

    @Method @Rename("writeStuffInt")
    int writeStuff(int v) {
        writeln(v);
        return 1;
    }

    @Method @Rename("formatNum")  // rename the method
    String formatNumbers(real_t r, long i) {
        import std.format, std.string;

        auto res = format("real r = %f\n int i = %d\n", r, i);
        String ret = String(res);
        return ret;
    }

    @Method
    static int getSomeNumber() { return 42; }

    @Method
    static Variant getNumberAsVariant() { return Variant(42); }
    
    @Signal @Rename("send_message")
    static void function(String message) sendMessage;

    /// Another way to define signal by using regular method, can be useful for cleaner API designs
    @Signal void anotherSignal(int v) {
        emitSignal("another_signal", v);
    }

    // PR 203, can not register signal with multiple arguments
    @Signal
    static void function(int a, float b) signalWithTwoParams;

    @Signal
    static void function(int) signalWithUnnamedParameter;

    // method returning TypedArray (introduced in Godot 4.2)
    static if (godotversion.VERSION_MINOR > 1) {
        @Method TypedArray!(int) getTypedArray() {
            return TypedArray!int.make(42, 7, 1);
        }
    }

    // method returning TypedDictionary (introduced in Godot 4.3)
    static if (godotversion.VERSION_MINOR > 2) {
        @Method TypedDictionary!(int, String) getTypedDict() {
            return TypedDictionary!(int, String).make(42, "Hello");
        }
    }

version(USE_CLASSES) {

    @Method
    override void _ready() {
          runTest();
    }

} else {

    @Method
    void _ready() {
        runTest();
    }

}

    void runTest() {
        // don't do anything in editor
        import godot.engine;

        if (Engine.isEditorHint())
            return;

        // the node variables will have been set by OnReady
        colorRect.setColor(Color(0f, 1f, 0f));
        longNode.setText("This node was set by OnReady");

        emitSignal("send_message", "Some text sent by a signal");
        // alternative syntax using types instead of plain string
        emit!sendMessage("Some text sent by a signal");
        // anotherSignal can be invoked as above, 
        // or as in this case by just calling D function that emits signal
        anotherSignal(42);
        emit!anotherSignal(cast(int) 42.0);

        // internal inheritance test, _godot_base is a struct serving as a base interface.
        // this is an implementation detail, users don't need to use it at all.
        version (USE_CLASSES)
          writefln("base object ptr: %x", cast(void*) super);
        else
          writefln("base object ptr: %x", cast(void*) _godot_base);

        // print() will write into Godot's editor output, unlike writeln
        print("Test._ready()");
        print();
        print("Hello", " Godot", " o/");
        print();

        version(Emscripten) {
            // writeln for emscripten is only partially implemented, skip for now
        }
        else {
            writeln("This as Variant: ", Variant(this));
            writeln("3 as Variant: ", Variant(3));
            writeln("\"asdf\" as Variant: ", Variant(String("asdf")));
        }

        {
            writefln("This (%s) is a normal D method of type %s.",
                __FUNCTION__, typeof(runTest).stringof);
        }

        {
            import std.compiler;

            // name is ambigous here (Node.name vs std.compiler.name),
            // so we have to be more specific as Node.name will have priority
            writefln("This D library was compiled with %s compiler, v%d.%03d",
                std.compiler.name, version_major, version_minor);
        }

        writeln(" ---TEST--- ");
        test();
    }

    void stringLitTest(String str = gs!"asdfTestLit") {
        print(str);
    }

    @Method
    void test() {
        /++
		
		Currently, this is a collection of tests checking that the types and
		methods work as intended.
		
		Once D class registration is finished, it'll be replaced with a proper
		example game.
		
		+/

        Vector2 ab = Vector2(1, 2);
        print(ab.yx);
        print(ab.yn);
        print(ab.yn(3f));
        print(ab.nn);
        print(ab.ynn(4f));
        print(ab.nnn(4f, 5f));
        Vector3 abc = Vector3(1f, 2f, 3f);
        print(abc.zyx);
        print(abc.xnz);

        enum lit = gs!"testEnumLiteral";
        stringLitTest(lit);
        stringLitTest(gs!"testLiteral");
        stringLitTest(gs!"testLiteral");
        stringLitTest();

        Variant vVec2Ctor = Variant(Vector2(21, 6));
        writefln("vVec2Ctor.type: %s", vVec2Ctor.type);
        assert(vVec2Ctor.type == Variant.Type.vector2);
        Vector2 vec2Back = vVec2Ctor.as!Vector2;
        writefln("vec2Back: %f,%f", vec2Back.x, vec2Back.y);

        Variant vVec3 = Variant(Vector3(1, 2, 3));
        Vector3 vec3Back = vVec3.as!Vector3;
        writefln("vec3Back: %f,%f,%f", vec3Back.x, vec3Back.y, vec3Back.z);

        String str = gs!"qwertz";
        Variant vStr = str;
        String strBack = vStr.as!String;
        auto strBackD = strBack.data;
        writefln("strBack.data: %x <%s>", cast(void*) strBackD.ptr, strBackD);

        Variant vDStr = "D string assigned to Variant";
        writefln("vDStr: <%s>", vDStr);

        Variant vLongCtor = Variant(1L);
        writefln("vLongCtor.type: %s", vLongCtor.type);
        assert(vLongCtor.type == Variant.Type.int_);
        auto vLongBack = vLongCtor.as!long;
        writefln("vLongCtor.as!long: %d", vLongBack);
        assert(vLongBack == 1L);

        Variant vUbyteCtor = Variant(ubyte(250));
        writefln("vUbyteCtor.type: %s", vUbyteCtor.type);
        assert(vUbyteCtor.type == Variant.Type.int_);
        long vUbyteBackL = vUbyteCtor.as!long;
        writefln("vUbyteCtor.as!long: %d", vUbyteBackL);
        assert(vUbyteBackL == 250L);
        ubyte vUbyteBack = vUbyteCtor.as!ubyte;
        writefln("vUbyteCtor.as!ubyte: %d", vUbyteBack);
        assert(vUbyteBack == ubyte(250));

        Variant vAssigned = -33;
        writefln("vAssigned.type: %s", vAssigned.type);
        assert(vAssigned.type == Variant.Type.int_);
        auto vAssignedBack = vAssigned.as!int;
        writefln("vAssignedBack.as!int: %d", vAssignedBack);
        assert(vAssignedBack == -33);

        Array arr = Array.make();
        arr ~= vVec2Ctor;
        arr ~= vStr;
        arr ~= vLongCtor;
        arr ~= vUbyteCtor;
        arr ~= vAssigned;
        writefln("arr.length: %d", arr.length);
        assert(arr.length == 5);
        write("Types:");
        foreach (i; 0 .. arr.length) {
            writef(" <%s>", arr[i].type);
        }
        writeln();

        // test null String
        {
            String empty;
            writefln("empty.length: %d", empty.length);
            auto cStr = empty;
            writefln("empty.data: %x <%s>", cast(void*) cStr.ptr, cStr);

            String other = empty;
            auto ocStr = other;
            writefln("other.data: %x <%s>"w, cast(void*) ocStr.ptr, ocStr);

            String cat = empty ~ gs!"cat";
            writefln("cat: <%s>", cat);

            empty = gs!"assigned";
            writefln("assigned: <%s>", empty);
        }

        // test singletons
        {
            import godot.os;
            import std.string;

            String name = OS.getName();
            writefln("OS is %s on device %s", name,
                OS.getModelName());
            String exe = OS.getExecutablePath();
            print("Executable path: ", exe);

            import godot.projectsettings;

            String projectName = ProjectSettings.get("application/config/name").as!String;
            print("ProjectSettings property \"application/config/name\": ", projectName);
        }

        // test extension of Label
        {
            import std.string;

            // Test has no "set_uppercase" or "set/get_text", so they're forwarded to base

            setUppercase(true);

            String oldText = getText();
            writefln("Old Label text: %s", oldText);
            setText("New text set from D Test class");
        }

        // test refcounting (also, run Godot with -v to see leaks)
        {
            Ref!RefTest t = memnew!RefTest;
            print("Created RefTest...");
            assert(t.isValid);
            RefTest v = t;
            assert(t == v);

            Ref!RefTest other1 = t;
            Ref!RefTest other2;
            assert(other2.isNull);
            other2 = t;

            RefTest n = null;
            t = n;
            assert(t.isNull);
            assert(t == n);
        }
        print("Exited RefTest scope");

        // test resource loading
        {
            import godot.resource, godot.resourceloader;
            import std.string;

            string iconPath = "res://icon.png";
            writefln("assert(!ResourceLoader.hasCached(%s))", iconPath);
            assert(!ResourceLoader.hasCached(iconPath));

            Ref!Resource res = ResourceLoader.load(iconPath, "", ResourceLoader
                    .CacheMode.cacheModeReplace);
            writefln("Loaded Resource %s at path %s", res.getName, res.getPath);

            // test upcasts
            import godot.texture2d, godot.mesh;

            Ref!Mesh wrongCast = res.as!Mesh;
            assert(wrongCast.isNull);
            Ref!Texture2D rightCast = res.as!Texture2D;
            assert(rightCast.isValid);
            auto size = rightCast.getSize();
            writefln("Texture size: %f,%f", size.x, size.y);

            writefln("assert(ResourceLoader.hasCached(%s))", iconPath);
            assert(ResourceLoader.hasCached(iconPath));
        }

        // test properties
        // FIXME: D Object has "get" shadowing GodotObject.get
        {
            string pn = "property";
            string someText = "Some text.";
            Variant someTextV = Variant(someText);

            writeln("setting property to \"Some text.\"...");
            this.set(pn, someTextV);
            writefln("Internally, property now contains <%s>.", _prop);
            auto res = this.get(pn).as!String;
            writefln("getting property: <%s>", res);
        }
        {
            string pn = "number";
            long someNum = 42;
            Variant someNumV = Variant(someNum);

            writeln("setting number to 42...");
            set(pn, someNumV);
            writefln("Internally, number now contains <%d>.", _num);
            auto res = this.get(pn).as!long;
            writefln("getting number: <%d>", res);
        }
        set("only_setter", 5678);
        print("onlyGetter: ", this.get("only_getter"));

        // test array slicing and equality
        {
            import std.algorithm : equal;

            Array a = Array.make(1, "two", NodePath("three"), 4.01);
            print("Array a: ", a);
            assert(a[1 .. $].equal(Array.make("two", NodePath("three"), 4.01)[]));
            // it seems slice operator changes, assert here has 2 elements, but since godot 4 slice now returns only one
            Array b = a.slice(1, a.length, 2);
            print("Array b (a.slice(1, a.length, 2)): ", b);
            assert(b[].equal([Variant("two"), Variant(4.01)]));

            Array c = a ~ b;
            print("Array c: ", c);
            assert(c[].equal(Array.make(1, "two", NodePath("three"), 4.01, "two", 4.01)[]));
            Array d = Array.make(5);
            d.appendRange([6, 7]);
            print("Array d: ", d);
            assert(d[].equal(Array.make(5, 6, 7)[]));
        }

        // test object comparison operators
        {
            // super should actually work with both versions, 
            // however here we assert that the _godot_base does works by means of struct inheritance
            version (USE_CLASSES)
              auto _godot_base = super;

            Node n = _godot_base;
            assert(n == this);
            assert(this == n);
            assert(n == _godot_base);
            assert(_godot_base == n);

            Node o = memnew!Node;
            scope (exit)
                memdelete(o);
            assert(n != o);
            assert(this != o);
            assert(o != this);
            assert(_godot_base != o);
            assert(o != _godot_base);

            if (o > n)
                assert(!(o < n));
            if (o < n)
                assert(!(o > n));
            if (o > _godot_base)
                assert(!(o < _godot_base));
            if (o < _godot_base)
                assert(!(o > _godot_base));
            if (o > this)
                assert(!(o < this));
            if (o < this)
                assert(!(o > this));
        }

        // test static method call
        {
            import godot.image;
            auto im = Image.create(256, 256, false, Image.Format.formatRgb8);
            assert(im.isValid());
        }

        // test packed array
        {
            PackedByteArray pb;
            assert(pb.size == 0);

            pb.pushBack(1);
            pb.pushBack(2);
            assert(pb.size == 2);
            assert(pb[1] == 2);

            print("PackedByteArray pb size: (2) = ", pb.size());

            PackedFloat64Array pf;
            pf.pushBack(0.5);
            pf.pushBack(1.0);
            pf.pushBack(0.3);
            import std.math : isClose;
            assert(isClose(pf[2], 0.3));
            print("PackedFloat64Array pf[0]: (0.5) = ", pf[0]);

            // moving
            PackedInt32Array p1;
            {
                PackedInt32Array p2;
                p2.pushBack(42);
                p1 = p2;
            }
            assert(p1.size == 1);
            assert(p1[0] == 42);
        }

    }
}

@Rename("RefTestD")
class RefTest : GodotScript!RefCounted {
    this() {
        print(__PRETTY_FUNCTION__);
    }

    ~this() {
        print(__PRETTY_FUNCTION__);
    }
}

import godotversion = godot.apiinfo;

// we assume this is godot 4 anyways, and we don't want the test to fail in CI
static if (godotversion.VERSION_MINOR > 1) {
    abstract class SomeBaseClass : GodotScript!GodotObject {
        version (USE_CLASSES) {
            // nothing to do
        }
        else {
            // note that this is done implicitly in GodotScript wrapper, but you can do that explicitly
            alias _godot_base this;
        }

        @Property int foo;

        @Method void doSomething() {}
    }
}
else {
    class SomeBaseClass : GodotScript!GodotObject {
        // add fallback for base inheritance
        version (USE_CLASSES) {
            // nothing to do
        }
        else {
            // note that this is done implicitly in GodotScript wrapper, but you can do that explicitly
            alias _godot_base this;
        }

        @Property int foo;

        @Method void doSomething() {}
    }
}

class SomeConcreteClass : SomeBaseClass {
    @Property float bar;

    // FIXME: fix this
    // godot-dlang.lib(types.obj) : warning LNK4255: library contain multiple objects of the same name; linking object as if no debug info
    @Method
    override void doSomething() {
        foo = 42; // test expects it to be 42
        print("i'm concrete class");
    }
}


class TestVirtualMethod : GodotScript!GodotObject {

    import godot.apiinfo;

    static if (VERSION_MINOR >= 3) {
        @Method @Virtual
        String doStuff() {
            return String("This method should be overriden");
        }

        @Method void test() {
            String ret;
            if (vcall!doStuff(_gdextension_handle(), ret))
                print(ret);

            assert(ret == String("I am overriden")); // TODO: comparison operator overload between `string` and `String`
        } 

        void _dummy_() {
            String ret;
            if (vcall!doStuff(this, ret)) {
                // use ret
            }
            static assert( __traits(compiles, vcall!doStuff(_gdextension_handle(), ret)));
            static assert( __traits(compiles, vcall!doStuff(this, ret)));
            static assert(!__traits(compiles, vcall!doStuff(_gdextension_handle(), 0)));

            if (vcallRaw!String(_gdextension_handle(), "do_stuff", ret)) {
                // use ret
            }
        }
    }
}

// register classes, initialize and terminate D runtime
mixin GodotNativeLibrary!(
    "test",
    Test,
    RefTest,

    SomeBaseClass,
    SomeConcreteClass,
    TestVirtualMethod
);
