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

import java.lang.reflect.Constructor;

import com.blockwithme.properties.Generator;
import com.blockwithme.properties.Properties;
import com.blockwithme.properties.StatefulGenerator;

/**
 * Lazy generator. Delegates to another generator on demand, once only, then
 * caches the result.
 *
 * @author monster
 */
public class LazyGen implements StatefulGenerator {

    /** Marker for Null actual value. */
    private static final Object NULL = new Object();

    /** The class name of the generator to create. */
    private final String genType;

    /** The parameter the generator to create. */
    private final String genParam;

    /**
     * Creates a LazyGen with a parameter in the form:
     * full-class-name-of-real-generator(parameter-to-real-generator)
     */
    public LazyGen(final String param) {
        final int openIndex = param.indexOf('(');
        final int closeIndex = param.lastIndexOf(')');
        if ((openIndex <= 0) || (closeIndex < param.length() - 1)) {
            throw new IllegalArgumentException(param);
        }
        genType = param.substring(0, openIndex);
        genParam = param.substring(openIndex + 1, closeIndex);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.properties.Generator#generate(com.blockwithme.properties.Properties, java.lang.String, java.lang.Class)
     */
    @SuppressWarnings("unchecked")
    @Override
    public <E> E generate(final Properties<?> prop, final String name,
            final Class<E> expectedType) {
        final Class<Generator> type;
        try {
            type = (Class<Generator>) Class.forName(genType);
        } catch (final ClassNotFoundException e) {
            throw new IllegalStateException(
                    "Cannot find/load class " + genType, e);
        }
        final Constructor<Generator> ctr;
        try {
            ctr = type.getConstructor(new Class[] { String.class });
        } catch (final Exception e) {
            throw new IllegalStateException(
                    "Cannot find String constructor for class " + genType, e);
        }
        final Generator realGen;
        try {
            realGen = ctr.newInstance(genParam);
        } catch (final Exception e) {
            throw new IllegalStateException("Cannot create class instance of "
                    + genType + " with '" + genParam + "'", e);
        }
        final E value = realGen.generate(prop, name, expectedType);
        // Replace self in Properties!
        prop.set(name, value, null);
        return value;
    }
}
