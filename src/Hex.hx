
abstract Hex(Int) from Int to Int {
    public inline function toString() {
        var h = StringTools.hex(this);
        var s = "0x";
        for(i in 0...4-h.length){
            s += "0";
        }
        s += h;
        return s;
    }
}