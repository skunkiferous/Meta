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
package com.blockwithme.meta.annotations.impl;

import java.util.HashMap;
import java.util.Map;

import com.blockwithme.meta.annotations.AnnotatedType;
import com.blockwithme.meta.annotations.Converter;

/**
 * Instantiates objects from a class or a class name.
 *
 * @author monster
 */
public class Instantiator<VALUE, ANNOTATION, OUTPUT> implements
        Converter<VALUE, ANNOTATION, OUTPUT> {

    /** Cache of created instances. */
    private final Map<Class<?>, Object> cache = new HashMap<>();

    /** Creates a new instance of the given type. */
    @SuppressWarnings("unchecked")
    private OUTPUT create(final Class<?> type) {
        if (type == null) {
            return null;
        }
        final Object result = cache.get(type);
        if (result != null) {
            return (OUTPUT) result;
        }
        try {
            final OUTPUT output = (OUTPUT) type.newInstance();
            cache.put(type, output);
            return output;
        } catch (InstantiationException | IllegalAccessException e) {
            throw new IllegalStateException("Could not instantiate " + type, e);
        }
    }

    /** Creates a new instance of the given type. */
    private OUTPUT create(final String type) {
        if ((type == null) || type.isEmpty()) {
            return null;
        }
        try {
            return create(Class.forName(type));
        } catch (final ClassNotFoundException e) {
            throw new IllegalStateException("Could not instantiate " + type, e);
        }
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.Converter#convert(java.util.Map, com.blockwithme.meta.annotations.AnnotatedType, java.lang.Object, java.lang.String, java.lang.Object)
     */
    @SuppressWarnings("unchecked")
    @Override
    public OUTPUT convert(final Map<String, Object> context,
            final AnnotatedType annotatedType,
            final ANNOTATION annotatedTypeAnnotation, final String property,
            final VALUE value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Class) {
            return create((Class<?>) value);
        }
        if (value instanceof String) {
            return create((String) value);
        }
        if (value instanceof Class[]) {
            final Class<?>[] types = (Class<?>[]) value;
            final Object[] array = new Object[types.length];
            for (int i = 0; i < array.length; i++) {
                array[i] = create(types[i]);
            }
            return (OUTPUT) array;
        }
        if (value instanceof String[]) {
            final String[] types = (String[]) value;
            final Object[] array = new Object[types.length];
            for (int i = 0; i < array.length; i++) {
                array[i] = create(types[i]);
            }
            return (OUTPUT) array;
        }
        throw new IllegalArgumentException(
                "Dont know how to instantiate from a " + value.getClass());
    }
}
