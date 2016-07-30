import herd.convert {
    Codec,
    ErrorStrategy,
    strict,
    EncodeException,
    DecodeException
}

shared object ascii satisfies Codec<Byte, Character> {
    aliases = [
        "US-ASCII",
        "ANSI_X3.4-1968",
        "iso-ir-6",
        "ANSI_X3.4-1986",
        "ISO_646.irv:1991",
        "ISO646-US",
        "ASCII",
        "us",
        "IBM367",
        "cp367"
    ];

    averageEncodeSize(Integer inputSize) => inputSize;

    maximumEncodeSize(Integer inputSize) => inputSize;

    averageDecodeSize(Integer inputSize) => inputSize;

    maximumDecodeSize(Integer inputSize) => inputSize;

    function toByte(ErrorStrategy error)(Character input) {
        value output = input.integer;
        if (output > 127) {
            if (error == strict) {
                throw EncodeException("Invalid ASCII character value: ``input``");
            }
            return null;
        }
        return output.byte;
    }

    function toCharacter(ErrorStrategy error)(Byte input) {
        if (input.signed < 0) {
            if (error == strict) {
                throw DecodeException("Invalid ASCII byte value: ``input``");
            }
            return null;
        }
        return input.signed.character;
    }

    encode({Character*} input, ErrorStrategy error)
        =>  input.map(toByte(error)).coalesced;

    decode({Byte*} input, ErrorStrategy error)
        =>  input.map(toCharacter(error)).coalesced;
}
