package com.latexonline.util;

public final class TextUtils {

    private TextUtils() {}

    public static boolean isCJK(char c) {
        return (c >= 0x4E00 && c <= 0x9FFF)
            || (c >= 0x3000 && c <= 0x303F)
            || (c >= 0xFF00 && c <= 0xFFEF);
    }

    /** Count display-width units: CJK = 2, ASCII = 1, other = 2. */
    public static int charWidth(char c) {
        if (isCJK(c)) return 2;
        if (c <= 0x7F) return 1;
        return 2;
    }

    /** Visual length in display-width units. */
    public static int visualLength(String s) {
        int len = 0;
        for (int i = 0; i < s.length(); i++) {
            len += charWidth(s.charAt(i));
        }
        return len;
    }

    /** Null-safe blank check. */
    public static boolean isSet(String s) {
        return s != null && !s.isBlank();
    }
}
