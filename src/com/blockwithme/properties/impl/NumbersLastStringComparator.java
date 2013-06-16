/*
 * Copyright (C) 2013 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.properties.impl;

import java.math.BigDecimal;
import java.util.Comparator;

/**
 * Comparator that compare integers as numbers, and all non-integers as smaller then integers.
 *
 * @author monster
 */
public class NumbersLastStringComparator implements Comparator<String> {

    /** Singleton instance. */
    public static final Comparator<String> CMP = new NumbersLastStringComparator();

    /** To correctly compare both doubles and longs, we need something bigger then both */
    private BigDecimal toNumber(final String str) {
        try {
            return new BigDecimal(str);
        } catch (final NumberFormatException e) {
            return null;
        }
    }

    @Override
    public int compare(final String o1, final String o2) {
        final BigDecimal n1 = toNumber(o1);
        final BigDecimal n2 = toNumber(o2);
        if (n1 == null) {
            if (n2 == null) {
                return o1.compareTo(o2);
            }
            return -1;
        }
        if (n2 != null) {
            return n1.compareTo(n2);
        }
        return -1;
    }
}
