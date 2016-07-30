import ceylon.buffer.charset {
    utf8SDK=utf8,
    asciiSDK=ascii
}
import ceylon.test {
    assertEquals,
    test,
    assertThatException
}

import com.vasileff.ceylon.util.benchmark {
    benchmark
}

import herd.convert.characterset {
    utf8,
    ascii,
    iso_8859_1
}
import herd.convert {
    Codec,
    ignore,
    DecodeException,
    EncodeException
}

shared void testConvert() {
    value chars = "Español ᚻᛚᛇᛏᚪᚾ᛬".sequence().repeat(10M);
    //value bytes = utf8.encode(chars).sequence();

    benchmark {
        "sdk round-trip" -> (() => utf8SDK.decode(utf8.encode(chars)).size),
        "herd round-trip" -> (() => utf8.decode(utf8.encode(chars)).size)
    };

//    benchmark {
//        "sdk encode" -> (() => utf8SDK.encode(chars).size),
//        "herd encode" -> (() => utf8.encode(chars).size)
//    };
//
//    benchmark {
//        "sdk decode" -> (() => utf8SDK.decode(bytes).size),
//        "herd decode" -> (() => utf8.decode(bytes).size)
//    };
//
//    benchmark {
//        "sdk to String" -> (() => utf8SDK.decode(bytes)),
//        "herd to String" -> (() => String(utf8.decode(bytes)))
//    };
//
//    benchmark {
//        "sdk to Ascii" -> (() => asciiSDK.decode(ascii.encode(utf8SDK.decode(bytes), ignore))),
//        "herd to Ascii" -> (() => String(ascii.decode(ascii.encode(utf8.decode(bytes), ignore))))
//    };

    print(utf8.encode("Español"));
}

shared class Utf8Tests() extends CharsetTests(utf8) {
    test
    shared void decodeUnicode() {
        assertEquals {
            String(utf8.decode(
                {
                    #e1, #9a, #bb, #e1, #9b, #9a, #e1, #9b, #87, #e1,
                    #9b, #8f, #e1, #9a, #aa, #e1, #9a, #be, #e1, #9b,
                    #ac
                }*.byte
            ));
            "ᚻᛚᛇᛏᚪᚾ᛬";
        };
    }

    test
    shared void encodeUnicode() {
        assertEquals {
            utf8.encode("ᚻᛚᛇᛏᚪᚾ᛬").sequence();
            {
                #e1, #9a, #bb, #e1, #9b, #9a, #e1, #9b, #87, #e1,
                #9b, #8f, #e1, #9a, #aa, #e1, #9a, #be, #e1, #9b,
                #ac
            }*.byte;
        };
    }

    test
    shared void lowRangeEncodeDecode() {
        assertEquals {
            utf8.encode("Español").sequence();
            { 69, 115, 112, 97, 195, 177, 111, 108 }*.byte;
        };
        assertEquals {
            String(utf8.decode({ 69, 115, 112, 97, 195, 177, 111, 108 }*.byte));
            "Español";
        };
    }

    test
    shared void lastCodePoint() {
        assertEquals("\{#10FFFF}", String(utf8.decode(utf8.encode("\{#10FFFF}"))));
    }
}

shared abstract class CharsetTests(Codec<Byte, Character> charset) {
    test
    shared void decodeZero() {
        assertEquals {
            String(charset.decode({}));
            "";
        };
    }

    test
    shared void decodeOne() {
        assertEquals {
            String(charset.decode({ '!'.integer.byte }));
            "!";
        };
    }

    test
    shared void decodeTwo() {
        assertEquals {
            String(charset.decode({ '!', 'a' }*.integer*.byte));
            "!a";
        };
    }

    test
    shared void encodeZero() {
        assertEquals {
            charset.encode("").sequence();
            {};
        };
    }

    test
    shared void encodeOne() {
        assertEquals {
            charset.encode("!").sequence();
            Array { '!'.integer.byte };
        };
    }

    test
    shared void encodeTwo() {
        assertEquals {
            charset.encode("!a").sequence();
            Array { '!', 'a' }*.integer*.byte;
        };
    }
}

shared class AsciiTests()
        extends CharsetTests(ascii) {
    test
    shared void encodeError() {
        assertThatException(() => ascii.encode("Aᛗ").sequence())
                .hasType(`EncodeException`)
                .hasMessage("Invalid ASCII character value: ᛗ");
    }

    test
    shared void encodeErrorIgnore() {
        assertEquals {
            ascii.encode("Aᛗ", ignore).sequence();
            Array { 'A'.integer.byte };
        };
    }

    test
    shared void decodeError() {
        assertThatException(() => ascii.decode({ $11111111.byte }).sequence())
                .hasType(`DecodeException`)
                .hasMessage((String m) => m.startsWith("Invalid ASCII byte value:"));
    }

    test
    shared void decodeErrorIgnore() {
        assertEquals {
            String(ascii.decode({ 'A'.integer.byte, $11111111.byte }, ignore));
            "A";
        };
    }
}

shared class Iso_8859_1Tests()
        extends CharsetTests(iso_8859_1) {
    test
    shared void encodeError() {
        assertThatException(() => iso_8859_1.encode("Aᛗ").sequence())
                .hasType(`EncodeException`)
                .hasMessage("Invalid ISO_8859-1 character value: ᛗ");
    }

    test
    shared void encodeErrorIgnore() {
        assertEquals {
            iso_8859_1.encode("Aᛗ", ignore).sequence();
            Array { 'A'.integer.byte };
        };
    }

    test
    shared void lowRangeEncodeDecode() {
        assertEquals {
            String(iso_8859_1.decode({
                97, 108, 105, 116, 233, 115, 60, 47, 97, 62,
                32, 60, 97, 32, 99, 108
            }*.byte));
            "alités</a> <a cl";
        };
        assertEquals {
            iso_8859_1.encode("alités</a> <a cl").sequence();
            { 97, 108, 105, 116, 233, 115, 60, 47, 97, 62, 32, 60, 97, 32, 99, 108 }*.byte;
        };
    }
}
