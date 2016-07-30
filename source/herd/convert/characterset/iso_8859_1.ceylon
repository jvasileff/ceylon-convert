import herd.convert {
    Codec,
    ErrorStrategy,
    strict,
    EncodeException
}

"The ISO 8859-1 character set, as defined by [its specification]
 (http://www.iso.org/iso/catalogue_detail?csnumber=28245)."
shared object iso_8859_1 satisfies Codec<Byte, Character> {
    aliases = [
        "ISO-8859-1",
        "ISO_8859-1:1987", // official name
        "iso-ir-100",
        "ISO_8859-1",
        "latin1",
        "l1",
        "IBM819",
        "CP819",
        "csISOLatin1",
        // idiot-proof aliases
        "iso-8859_1",
        "iso_8859_1",
        "iso8859-1",
        "iso8859_1",
        "latin-1",
        "latin_1"
    ];

    averageEncodeSize(Integer inputSize) => inputSize;

    maximumEncodeSize(Integer inputSize) => inputSize;

    averageDecodeSize(Integer inputSize) => inputSize;

    maximumDecodeSize(Integer inputSize) => inputSize;

    function toCharacter(Byte input)
        =>  input.unsigned.character;

    function toByte(ErrorStrategy error)(Character input) {
        value output = input.integer;
        if (output > 255) {
            if (error == strict) {
                throw EncodeException("Invalid ISO_8859-1 character value: ``input``");
            }
            return null;
        }
        return output.byte;
    }

    decode({Byte*} input, ErrorStrategy error)
        =>  input.map(toCharacter);

    encode({Character*} input, ErrorStrategy error)
        =>  input.map(toByte(error)).coalesced;
}
