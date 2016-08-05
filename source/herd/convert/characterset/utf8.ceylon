import herd.convert {
    Codec,
    ErrorStrategy,
    strict,
    EncodeException,
    ignore,
    reset,
    DecodeException
}
import ceylon.buffer {
    ByteBuffer,
    CharacterBuffer
}

shared object utf8 satisfies Codec<Byte, Character> {
    aliases = ["UTF-8", "UTF8", "UTF_8"];

    averageEncodeSize(Integer inputSize) => inputSize * 2;

    maximumEncodeSize(Integer inputSize) => inputSize * 4;

    averageDecodeSize(Integer inputSize) => inputSize / 2;

    maximumDecodeSize(Integer inputSize) => inputSize;

    shared actual {Byte*} encode({Character*} input, ErrorStrategy error) => object
            satisfies {Byte*} {

        iterator()
            =>  let (pieceEncoder = PieceEncode(error))
                { for (c in input) for (b in pieceEncoder.more(c)) b }
                    .chain(pieceEncoder.done())
                    .iterator();
    };

    shared actual {Character*} decode({Byte*} input, ErrorStrategy error) => object
            satisfies {Character*} {
        iterator()
            =>  let (pieceEncoder = PieceDecode(error))
                { for (c in input) for (b in pieceEncoder.more(c)) b }
                    .chain(pieceEncoder.done())
                    .iterator();
    };

    class PieceDecode(ErrorStrategy error) satisfies PieceConvert<Character, Byte> {
        value outputBuffer = CharacterBuffer.ofSize(1);

        variable Boolean initialOutput = true;

        value intermediate = Array<Integer>.ofSize(3, 0);
        variable Integer intermediateLimit = 0;
        variable Integer intermediateSize = 0;

        void put(Integer i)
            =>  intermediate.set(intermediateSize++, i);

        Integer get(Integer i) {
            assert (exists result = intermediate.getFromFirst(i));
            return result;
        }

        void resetBuffer()
            =>  intermediateLimit = intermediateSize = 0;

        shared actual { Character* } more(Byte input) {
            outputBuffer.clear();

            value unsigned = input.unsigned;

            value initial = initialOutput;
            initialOutput = false;

            //if (is Finished unsigned) {
            //    if (intermediateLimit != 0) {
            //        switch (error)
            //        case (strict) {
            //            throw DecodeException {
            //                "Invalid UTF-8 sequence: missing \
            //                 `` intermediateLimit `` bytes";
            //            };
            //        }
            //        case (ignore | reset) {}
            //    }
            //    resetBuffer();
            //    return unsigned;
            //}

            // UTF-8 is max 4-byte variable length
            if (intermediateLimit == 0) {
                // 0b0000 0000 <= byte < 0b1000 0000
                if (unsigned < $10000000) {
                    // one byte
                    outputBuffer.put(unsigned.character);
                    outputBuffer.flip();
                    return outputBuffer;
                }
                // Select multi-byte limit
                if (unsigned < $11000000) {
                    // invalid range
                    switch (error)
                    case (strict) {
                        throw DecodeException("Invalid UTF-8 first byte value: \
                                               ``input``");
                    }
                    case (ignore) {
                    }
                    case (reset) {
                        resetBuffer();
                    }
                } else if (unsigned < $11100000) {
                    intermediateLimit = 1; // 0 more before final (2 total)
                } else if (unsigned < $11110000) {
                    intermediateLimit = 2; // 1 more before final (3 total)
                } else if (unsigned < $11111000) {
                    // 0b1111 0000 <= byte < 0b1111 1000
                    intermediateLimit = 3; // 2 more before final (4 total)
                } else {
                    // invalid range
                    switch (error)
                    case (strict) {
                        throw DecodeException("Invalid UTF-8 first byte value: \
                                               ``input``");
                    }
                    case (ignore) {
                    }
                    case (reset) {
                        resetBuffer();
                    }
                    return [];
                }
                // keep this byte in any case
                put(unsigned);
                return [];
            }
            // if we got this far, we must have a second byte at least
            if (unsigned<$10000000 || unsigned>=$11000000) {
                switch (error)
                case (strict) {
                    throw DecodeException {
                        "Invalid UTF-8 ``intermediateSize`` \
                         byte value: ``input``";
                    };
                }
                case (ignore) {
                }
                case (reset) {
                    resetBuffer();
                }
                return [];
            }
            if (intermediateSize < intermediateLimit) {
                // not enough bytes
                put(unsigned);
                return [];
            }
            // we have enough bytes! they are all in the bytes buffer except
            // the last one they have all been checked already
            Integer char;
            if (intermediateSize == 1) {
                value part1 = get(0).and($00011111);
                value part2 = unsigned.and($00111111);
                char = part1.leftLogicalShift(6).or(part2);
            } else if (intermediateSize == 2) {
                value part1 = get(0).and($00001111);
                value part2 = get(1).and($00111111);
                value part3 = unsigned.and($00111111);
                char = part1.leftLogicalShift(12)
                        .or(part2.leftLogicalShift(6))
                        .or(part3);
            } else { // intermediateSize == 3
                value part1 = get(0).and($00000111);
                value part2 = get(1).and($00111111);
                value part3 = get(2).and($00111111);
                value part4 = unsigned.and($00111111);
                char = part1.leftLogicalShift(18)
                        .or(part2.leftLogicalShift(12))
                        .or(part3.leftLogicalShift(6))
                        .or(part4);
            }
            resetBuffer();
            if (initial && char==#FEFF) {
                return [];
            }
            outputBuffer.put(char.character);
            outputBuffer.flip();
            return outputBuffer;
        }
    }

    class PieceEncode(ErrorStrategy error) satisfies PieceConvert<Byte, Character> {
        value outputBuffer = ByteBuffer.ofSize(4);
        //value outputBuffer = AnyBuffer.ofSize(4, 0.byte);

        shared actual {Byte*} more(Character input) {
            outputBuffer.clear();
            value cp = input.integer;
            // how many bytes?
            if (cp < #80) {
                // single byte
                outputBuffer.put(cp.byte);
                outputBuffer.flip();
                return outputBuffer;
            }
            else if (cp < #800) {
                // two bytes
                value b1 = cp.and($11111000000).rightLogicalShift(6).or($11000000).byte;
                value b2 = cp.and($111111).or($10000000).byte;
                outputBuffer.put(b1);
                outputBuffer.put(b2);
                outputBuffer.flip();
                return outputBuffer;
            }
            else if (cp < #10000) {
                // three bytes
                value b1 = cp.and($1111000000000000).rightLogicalShift(12).or($11100000).byte;
                value b2 = cp.and($111111000000).rightLogicalShift(6).or($10000000).byte;
                value b3 = cp.and($111111).or($10000000).byte;
                outputBuffer.put(b1);
                outputBuffer.put(b2);
                outputBuffer.put(b3);
                outputBuffer.flip();
                return outputBuffer;
            }
            else if (cp < #110000) {
                // four bytes
                value b1 = cp.and($111000000000000000000).rightLogicalShift(18).or($11110000).byte;
                value b2 = cp.and($111111000000000000).rightLogicalShift(12).or($10000000).byte;
                value b3 = cp.and($111111000000).rightLogicalShift(6).or($10000000).byte;
                value b4 = cp.and($111111).or($10000000).byte;
                outputBuffer.put(b1);
                outputBuffer.put(b2);
                outputBuffer.put(b3);
                outputBuffer.put(b4);
                outputBuffer.flip();
                return outputBuffer;
            }
            else {
                switch (error)
                case (strict) {
                    throw EncodeException("Invalid unicode code point ``cp``");
                }
                case (ignore | reset) {
                    return empty;
                }
            }
        }
    }
}

interface PieceConvert<To, From> {
    shared formal {To*} more(From input);
    shared default {To*} done() => empty;
}
