"Thrown by failed conversion operations"
shared class ConvertException(description = null, cause = null)
        extends Exception(description, cause) {
    String? description;
    Throwable? cause;
}

"Thrown by failed encode operations"
shared class EncodeException(description = null, cause = null)
        extends ConvertException(description, cause) {
    String? description;
    Throwable? cause;
}

"Thrown by failed decode operations"
shared class DecodeException(description = null, cause = null)
        extends ConvertException(description, cause) {
    String? description;
    Throwable? cause;
}

"Action to take when an error is encountered during encoding or decoding."
shared abstract class ErrorStrategy() of strict | ignore | reset {}

"Throw a [[ConvertException]]"
shared object strict extends ErrorStrategy() {}

"Continue without throwing an exception"
shared object ignore extends ErrorStrategy() {}

"Reset the internal state, then continue without throwing an exception"
shared object reset extends ErrorStrategy() {}
